import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/passenger_trust_metrics.dart';
import 'risk_scoring.dart';
import 'trust_scoring_service.dart';

/// Service for managing passenger reports and trust metrics
class PassengerReportingService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  PassengerReportingService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  /// Submit a passenger report with location data.
  ///
  /// [tripSensorRisk] is the current sensor-based risk score (0–1) for the
  /// active trip at the time of reporting. Passing this enables the trust
  /// module to compare the report severity against real sensor measurements
  /// (RQ 2.2 – sensor alignment).
  ///
  /// [tripEventCount] is the number of unsafe driving events detected by
  /// sensors within the trip up to this point.
  Future<String> submitReport({
    required String category,
    required int severity,
    required double? latitude,
    required double? longitude,
    required int? tripId,
    String? description,
    double tripSensorRisk = 0.5, // R_sens at time of report; default = neutral
    int tripEventCount = 0, // N_sensor events detected so far in the trip
  }) async {
    try {
      final user = _auth.currentUser;
      final passengerId = user?.uid ?? 'guest_user';

      final reportData = {
        'passengerId': passengerId,
        'category': category,
        'severity': severity,
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'tripId': tripId,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': DateTime.now().toIso8601String(),
        'isVerified': false,
        'isFlagged': false,
        'verificationCount': 0,
        'flagCount': 0,
        // Store the sensor context at submission time for audit / alignment scoring
        'sensorRiskAtSubmission': tripSensorRisk,
        'sensorEventCountAtSubmission': tripEventCount,
      };

      final docRef = await _firestore
          .collection('passenger_reports')
          .add(reportData)
          .timeout(const Duration(seconds: 3));

      // Update passenger trust metrics with real sensor context (RQ 2.2)
      await _updatePassengerTrustMetrics(
        passengerId,
        latestSensorRisk: tripSensorRisk,
        latestEventCount: tripEventCount,
      ).timeout(const Duration(seconds: 3)).catchError((_) {});

      return docRef.id;
    } catch (e) {
      return 'local_report_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Get trust metrics for a specific passenger
  Future<PassengerTrustMetrics?> getPassengerTrustMetrics(
    String passengerId,
  ) async {
    try {
      final doc = await _firestore
          .collection('passenger_trust_metrics')
          .doc(passengerId)
          .get();

      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>;
      return PassengerTrustMetrics(
        passengerId: passengerId,
        totalReports: data['totalReports'] ?? 0,
        consistencyScore: (data['consistencyScore'] ?? 0.5).toDouble(),
        anomalyScore: (data['anomalyScore'] ?? 0.0).toDouble(),
        sensorAlignmentScore: (data['sensorAlignmentScore'] ?? 0.5).toDouble(),
        overallTrust: (data['overallTrust'] ?? 0.5).toDouble(),
        lastUpdated: data['lastUpdated'] != null
            ? (data['lastUpdated'] as Timestamp).toDate()
            : DateTime.now(),
        verifiedCount: data['verifiedCount'] ?? 0,
        flaggedCount: data['flaggedCount'] ?? 0,
      );
    } catch (e) {
      throw Exception('Failed to fetch trust metrics: $e');
    }
  }

  /// Stream trust metrics for a specific passenger in real-time
  Stream<PassengerTrustMetrics?> streamPassengerTrustMetrics(String passengerId) {
    return _firestore
        .collection('passenger_trust_metrics')
        .doc(passengerId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      final data = doc.data() as Map<String, dynamic>;
      return PassengerTrustMetrics(
        passengerId: passengerId,
        totalReports: data['totalReports'] ?? 0,
        consistencyScore: (data['consistencyScore'] ?? 0.5).toDouble(),
        anomalyScore: (data['anomalyScore'] ?? 0.0).toDouble(),
        sensorAlignmentScore: (data['sensorAlignmentScore'] ?? 0.5).toDouble(),
        overallTrust: (data['overallTrust'] ?? 0.5).toDouble(),
        lastUpdated: data['lastUpdated'] != null
            ? (data['lastUpdated'] as Timestamp).toDate()
            : DateTime.now(),
        verifiedCount: data['verifiedCount'] ?? 0,
        flaggedCount: data['flaggedCount'] ?? 0,
      );
    });
  }

  /// Get reports for a specific trip with trust scores
  Stream<List<ReportWithTrust>> getReportsForTrip(int tripId) {
    return _firestore
        .collection('passenger_reports')
        .where('tripId', isEqualTo: tripId)
        .snapshots()
        .asyncMap((snapshot) async {
          final trustCache = <String, double>{};
          final fetchTasks = <Future<void>>[];

          for (final doc in snapshot.docs) {
            final passengerId = doc.data()['passengerId'] as String;
            if (!trustCache.containsKey(passengerId)) {
              trustCache[passengerId] = 0.5;
              fetchTasks.add(
                getPassengerTrustMetrics(passengerId).then((metrics) {
                  if (metrics != null) {
                    trustCache[passengerId] = metrics.overallTrust;
                  }
                }).catchError((_) {}),
              );
            }
          }

          await Future.wait(fetchTasks);

          final parsedList = snapshot.docs.map((doc) {
            final data = doc.data();
            final passengerId = data['passengerId'] as String;
            final passengerTrust = trustCache[passengerId] ?? 0.5;

            return ReportWithTrust(
              reportId: doc.id.hashCode,
              firestoreId: doc.id,
              passengerId: passengerId,
              category: data['category'] as String,
              severity: data['severity'] as int,
              description: data['description'] as String?,
              latitude: (data['latitude'] as num?)?.toDouble(),
              longitude: (data['longitude'] as num?)?.toDouble(),
              timestamp: data['timestamp'] != null
                  ? (data['timestamp'] as Timestamp).toDate()
                  : DateTime.parse(data['createdAt'] as String),
              passengerTrust: passengerTrust,
              isVerified: data['isVerified'] as bool? ?? false,
              isFlagged: data['isFlagged'] as bool? ?? false,
            );
          }).toList();
          
          parsedList.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          
          return parsedList;
        });
  }

  /// Get recent reports in a geographic area
  Stream<List<ReportWithTrust>> getReportsInArea({
    required double centerLat,
    required double centerLng,
    required double radiusKm,
  }) {
    // Note: Firestore doesn't support geospatial queries directly
    // This filters client-side; for production, use GeoHash or geofirestore
    return _firestore
        .collection('passenger_reports')
        .where(
          'timestamp',
          isGreaterThan: Timestamp.fromDate(
            DateTime.now().subtract(Duration(hours: 24)),
          ),
        )
        .snapshots()
        .asyncMap((snapshot) async {
          final reports = <ReportWithTrust>[];

          for (final doc in snapshot.docs) {
            final data = doc.data();
            final lat = (data['latitude'] as num?)?.toDouble();
            final lng = (data['longitude'] as num?)?.toDouble();

            if (lat == null || lng == null) continue;

            // Calculate distance using haversine formula
            final distance = _calculateDistance(centerLat, centerLng, lat, lng);
            if (distance > radiusKm) continue;

            final passengerId = data['passengerId'] as String;
            final trustMetrics = await getPassengerTrustMetrics(passengerId);
            final passengerTrust = trustMetrics?.overallTrust ?? 0.5;

            reports.add(
              ReportWithTrust(
                reportId: doc.id.hashCode,
                firestoreId: doc.id,
                passengerId: passengerId,
                category: data['category'] as String,
                severity: data['severity'] as int,
                description: data['description'] as String?,
                latitude: lat,
                longitude: lng,
                timestamp: data['timestamp'] != null
                    ? (data['timestamp'] as Timestamp).toDate()
                    : DateTime.parse(data['createdAt'] as String),
                passengerTrust: passengerTrust,
                isVerified: data['isVerified'] as bool? ?? false,
                isFlagged: data['isFlagged'] as bool? ?? false,
              ),
            );
          }

          return reports;
        });
  }

  /// Verify a report (another passenger confirms it)
  Future<void> verifyReport(String reportId) async {
    try {
      final docRef = _firestore.collection('passenger_reports').doc(reportId);
      await docRef.update({'verificationCount': FieldValue.increment(1)});

      // Refresh trust metrics; re-read sensor context stored on the document
      final doc = await docRef.get();
      final data = doc.data() as Map<String, dynamic>;
      final passengerId = data['passengerId'] as String;
      final sensorRisk =
          (data['sensorRiskAtSubmission'] as num?)?.toDouble() ?? 0.5;
      final eventCount =
          (data['sensorEventCountAtSubmission'] as num?)?.toInt() ?? 0;
      await _updatePassengerTrustMetrics(
        passengerId,
        latestSensorRisk: sensorRisk,
        latestEventCount: eventCount,
      );
    } catch (e) {
      throw Exception('Failed to verify report: $e');
    }
  }

  /// Flag a report as suspicious/inaccurate
  Future<void> flagReport(String reportId, String reason) async {
    try {
      final docRef = _firestore.collection('passenger_reports').doc(reportId);
      await docRef.update({
        'flagCount': FieldValue.increment(1),
        'isFlagged': true,
        'flagReason': reason,
        'flaggedAt': FieldValue.serverTimestamp(),
      });

      // Refresh trust metrics; re-read sensor context stored on the document
      final doc = await docRef.get();
      final data = doc.data() as Map<String, dynamic>;
      final passengerId = data['passengerId'] as String;
      final sensorRisk =
          (data['sensorRiskAtSubmission'] as num?)?.toDouble() ?? 0.5;
      final eventCount =
          (data['sensorEventCountAtSubmission'] as num?)?.toInt() ?? 0;
      await _updatePassengerTrustMetrics(
        passengerId,
        latestSensorRisk: sensorRisk,
        latestEventCount: eventCount,
      );
    } catch (e) {
      throw Exception('Failed to flag report: $e');
    }
  }

  /// Update passenger trust metrics based on all their reports.
  ///
  /// [latestSensorRisk]  – the sensor-based risk score (R_sens, 0–1) from the
  ///   trip at the moment the most-recent report was submitted. Used by the
  ///   sensor alignment formula (RQ 2.2).
  ///
  /// [latestEventCount]  – number of unsafe driving events detected by sensors
  ///   in that trip window. Feeds `detectedEventCount` in the alignment score.
  Future<void> _updatePassengerTrustMetrics(
    String passengerId, {
    double latestSensorRisk = 0.5,
    int latestEventCount = 0,
  }) async {
    try {
      // Fetch all reports from this passenger
      final snapshot = await _firestore
          .collection('passenger_reports')
          .where('passengerId', isEqualTo: passengerId)
          .get();

      if (snapshot.docs.isEmpty) {
        // Initialize with default trust for new passenger
        await _firestore
            .collection('passenger_trust_metrics')
            .doc(passengerId)
            .set({
              'passengerId': passengerId,
              'totalReports': 0,
              'consistencyScore': 0.5,
              'anomalyScore': 0.0,
              'sensorAlignmentScore': 0.5,
              'overallTrust': 0.5,
              'lastUpdated': FieldValue.serverTimestamp(),
              'verifiedCount': 0,
              'flaggedCount': 0,
            }, SetOptions(merge: true));
        return;
      }

      // Extract severity history and verification/flag counts
      final severities = <int>[];
      int totalVerified = 0;
      int totalFlagged = 0;

      // Also compute a weighted average sensor risk from stored context across
      // all reports so alignment is informed by the full history, not just the
      // latest call-site value.
      double sensorRiskSum = 0.0;
      int sensorRiskCount = 0;
      int totalStoredEventCount = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        severities.add(data['severity'] as int);
        totalVerified += (data['verificationCount'] as num?)?.toInt() ?? 0;
        totalFlagged += (data['flagCount'] as num?)?.toInt() ?? 0;

        // Accumulate stored sensor context from each report document
        final storedRisk =
            (data['sensorRiskAtSubmission'] as num?)?.toDouble();
        final storedEvents =
            (data['sensorEventCountAtSubmission'] as num?)?.toInt();
        if (storedRisk != null) {
          sensorRiskSum += storedRisk;
          sensorRiskCount++;
        }
        if (storedEvents != null) {
          totalStoredEventCount += storedEvents;
        }
      }

      // Use the mean historical sensor risk. Fall back to the value passed in
      // from the current submission when no stored values exist yet.
      final averageSensorRisk = sensorRiskCount > 0
          ? (sensorRiskSum / sensorRiskCount)
          : latestSensorRisk;

      // Total event count across all stored reports; use the latest trip value
      // as a floor so a brand-new reporter still gets a fair comparison.
      final effectiveEventCount =
          totalStoredEventCount > 0 ? totalStoredEventCount : latestEventCount;

      // ── Consistency score: low variance across historical severities ──────
      final consistencyScore = TrustScoringService.calculateConsistencyScore(
        historicalSeverities: severities,
        currentSeverity: severities.last,
      );

      // ── Anomaly score: z-score outlier detection ──────────────────────────
      final anomalyScore = TrustScoringService.calculateAnomalyScore(
        historicalSeverities: severities.length > 1
            ? severities.sublist(0, severities.length - 1)
            : [],
        currentSeverity: severities.last,
      );

      // ── Sensor alignment score: RQ 2.2 ───────────────────────────────────
      // Now uses real sensor data persisted on each report document rather than
      // a hardcoded proxy.
      final sensorAlignmentScore =
          TrustScoringService.calculateSensorAlignmentScore(
            reportSeverity: severities.last,
            detectedEventCount: effectiveEventCount,
            averageSensorRisk: averageSensorRisk,
          );

      // ── Overall trust: weighted sum of all components (RQ 2.1 + RQ 2.2) ──
      final overallTrust = TrustScoringService.calculateOverallTrust(
        consistencyScore: consistencyScore,
        anomalyScore: anomalyScore,
        sensorAlignmentScore: sensorAlignmentScore,
        verifiedCount: totalVerified,
        flaggedCount: totalFlagged,
        totalReports: snapshot.docs.length, // RQ 2.1: reporting frequency
      );

      // Persist updated metrics to Firestore
      await _firestore
          .collection('passenger_trust_metrics')
          .doc(passengerId)
          .set({
            'passengerId': passengerId,
            'totalReports': snapshot.docs.length,
            'consistencyScore': consistencyScore,
            'anomalyScore': anomalyScore,
            'sensorAlignmentScore': sensorAlignmentScore,
            'overallTrust': overallTrust,
            'lastUpdated': FieldValue.serverTimestamp(),
            'verifiedCount': totalVerified,
            'flaggedCount': totalFlagged,
          }, SetOptions(merge: true));
    } catch (e) {
      // Silently handle error – trust metrics update is non-critical
    }
  }

  /// Calculate distance between two coordinates (in km)
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final sinDLat = sin(dLat);
    final sinDLon = sin(dLon);
    final a =
        sinDLat * sinDLat +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sinDLon * sinDLon;
    final c = 2 * asin(sqrt(a));
    return earthRadiusKm * c;
  }

  double _toRad(double degrees) => degrees * pi / 180.0;

  /// Get aggregate statistics for reports in a timeframe
  Future<Map<String, dynamic>> getReportStatistics({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('passenger_reports')
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startTime),
          )
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endTime))
          .get();

      final categories = <String, int>{};
      final severities = <int>[];
      int totalVerified = 0;
      int totalFlagged = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final category = data['category'] as String;
        categories[category] = (categories[category] ?? 0) + 1;
        severities.add(data['severity'] as int);
        totalVerified += data['verificationCount'] as int? ?? 0;
        totalFlagged += data['flagCount'] as int? ?? 0;
      }

      final avgSeverity = severities.isEmpty
          ? 0.0
          : severities.fold(0, (a, b) => a + b) / severities.length;

      return {
        'totalReports': snapshot.docs.length,
        'categories': categories,
        'averageSeverity': avgSeverity,
        'totalVerifications': totalVerified,
        'totalFlags': totalFlagged,
      };
    } catch (e) {
      throw Exception('Failed to get report statistics: $e');
    }
  }

  /// Validates a report against actual sensor events.
  /// Checks for overlapping sensor events within a ±2 minute window.
  /// Updates the sensorAlignmentScore of the passenger accordingly.
  Future<void> validateReportWithSensors(
    String passengerId,
    DateTime reportTime,
    List<UnsafeEvent> recentEvents,
  ) async {
    final windowStart = reportTime.subtract(const Duration(minutes: 2));
    final windowEnd = reportTime.add(const Duration(minutes: 2));

    bool hasMatchingEvent = false;
    for (final event in recentEvents) {
      if (event.timestamp.isAfter(windowStart) && event.timestamp.isBefore(windowEnd)) {
        hasMatchingEvent = true;
        break;
      }
    }

    try {
      final docRef = _firestore.collection('passenger_trust_metrics').doc(passengerId);
      final doc = await docRef.get();
      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;
      double currentAlignment = (data['sensorAlignmentScore'] as num?)?.toDouble() ?? 0.5;

      if (hasMatchingEvent) {
        currentAlignment = min(1.0, currentAlignment + 0.1);
      } else {
        currentAlignment = max(0.0, currentAlignment - 0.05);
      }

      await docRef.update({
        'sensorAlignmentScore': currentAlignment,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      // We should ideally recalculate the overall trust as well,
      // but the overall trust is typically refreshed on next report submission.
      // We will leave the overall trust recalculation to _updatePassengerTrustMetrics.
    } catch (e) {
      throw Exception('Failed to validate report with sensors: $e');
    }
  }
}

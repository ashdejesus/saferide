import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/passenger_trust_metrics.dart';
import 'trust_scoring_service.dart';

/// Service for managing passenger reports and trust metrics
class PassengerReportingService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  PassengerReportingService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  /// Submit a passenger report with location data
  Future<String> submitReport({
    required String category,
    required int severity,
    required double? latitude,
    required double? longitude,
    required int? tripId,
    String? description,
  }) async {
    try {
      final user = _auth.currentUser;
      final passengerId =
          user?.uid ?? 'anonymous_${DateTime.now().millisecondsSinceEpoch}';

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
      };

      final docRef = await _firestore
          .collection('passenger_reports')
          .add(reportData);

      // Update passenger trust metrics after report submission
      await _updatePassengerTrustMetrics(passengerId);

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to submit report: $e');
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

  /// Get reports for a specific trip with trust scores
  Stream<List<ReportWithTrust>> getReportsForTrip(int tripId) {
    return _firestore
        .collection('passenger_reports')
        .where('tripId', isEqualTo: tripId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final reports = <ReportWithTrust>[];

          for (final doc in snapshot.docs) {
            final data = doc.data();
            final passengerId = data['passengerId'] as String;

            // Get passenger trust metrics
            final trustMetrics = await getPassengerTrustMetrics(passengerId);
            final passengerTrust = trustMetrics?.overallTrust ?? 0.5;

            reports.add(
              ReportWithTrust(
                reportId: doc.id.hashCode,
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
              ),
            );
          }

          return reports;
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

      // Update trust metrics
      final doc = await docRef.get();
      final passengerId = doc.get('passengerId') as String;
      await _updatePassengerTrustMetrics(passengerId);
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

      // Update trust metrics
      final doc = await docRef.get();
      final passengerId = doc.get('passengerId') as String;
      await _updatePassengerTrustMetrics(passengerId);
    } catch (e) {
      throw Exception('Failed to flag report: $e');
    }
  }

  /// Update passenger trust metrics based on all their reports
  Future<void> _updatePassengerTrustMetrics(String passengerId) async {
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

      // Extract severity history
      final severities = <int>[];
      int totalVerified = 0;
      int totalFlagged = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        severities.add((data['severity'] as int));
        totalVerified += (data['verificationCount'] as int?) ?? 0;
        totalFlagged += (data['flagCount'] as int?) ?? 0;
      }

      // Calculate consistency score from variance
      final consistencyScore = TrustScoringService.calculateConsistencyScore(
        historicalSeverities: severities,
        currentSeverity: severities.last,
      );

      // Calculate anomaly score for latest report
      final anomalyScore = TrustScoringService.calculateAnomalyScore(
        historicalSeverities: severities.length > 1
            ? severities.sublist(0, severities.length - 1)
            : [],
        currentSeverity: severities.last,
      );

      // For sensor alignment, we'd need actual sensor data
      // For now, use a proxy based on report distribution
      final sensorAlignmentScore =
          TrustScoringService.calculateSensorAlignmentScore(
            reportSeverity: severities.last,
            detectedEventCount: totalVerified > 0 ? 3 : 0,
            averageSensorRisk: 0.5,
          );

      // Calculate overall trust
      final overallTrust = TrustScoringService.calculateOverallTrust(
        consistencyScore: consistencyScore,
        anomalyScore: anomalyScore,
        sensorAlignmentScore: sensorAlignmentScore,
        verifiedCount: totalVerified,
        flaggedCount: totalFlagged,
      );

      // Update Firestore
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
      // Silently handle error - trust metrics update is non-critical
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
}

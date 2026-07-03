import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip.dart';
import 'risk_scoring.dart' as risk_scoring;

class RemoteReport {
  RemoteReport({
    required this.id,
    required this.tripId,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.trust,
    required this.category,
    required this.createdAt,
  });

  final String id;
  final int? tripId;
  final double? latitude;
  final double? longitude;
  final int rating;
  final double trust;
  final String? category;
  final DateTime createdAt;
}

class FirestoreService {
  final FirebaseFirestore _db;

  FirestoreService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  /// Stream reports optionally filtered by tripId
  Stream<List<RemoteReport>> reportsStream({int? tripId}) {
    Query collection = _db
        .collection('reports')
        .orderBy('createdAt', descending: true);
    if (tripId != null) {
      collection = collection.where('tripId', isEqualTo: tripId);
    }

    return collection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final dataRaw = doc.data();
        final Map<String, dynamic> data = (dataRaw is Map<String, dynamic>)
            ? dataRaw
            : <String, dynamic>{};

        final ratingVal = data['rating'] ?? data['severity'] ?? 1;
        final rating = (ratingVal is int)
            ? ratingVal
            : int.tryParse('$ratingVal') ?? 1;

        final trustVal = data['trust'];
        final trust = (trustVal is num) ? trustVal.toDouble() : 1.0;

        final lat = (data['lat'] is num)
            ? (data['lat'] as num).toDouble()
            : null;
        final lng = (data['lng'] is num)
            ? (data['lng'] as num).toDouble()
            : null;

        DateTime createdAt;
        final createdRaw = data['createdAt'];
        if (createdRaw is Timestamp) {
          createdAt = createdRaw.toDate();
        } else if (createdRaw is String) {
          createdAt = DateTime.tryParse(createdRaw) ?? DateTime.now();
        } else {
          createdAt = DateTime.now();
        }

        final tripIdVal = data['tripId'];
        final tripId = (tripIdVal is int) ? tripIdVal : null;

        return RemoteReport(
          id: doc.id,
          tripId: tripId,
          latitude: lat,
          longitude: lng,
          rating: rating.clamp(1, 5),
          trust: trust.clamp(0.0, 1.0),
          category: data['category'] as String?,
          createdAt: createdAt,
        );
      }).toList();
    });
  }

  /// Convenience: convert to risk_scoring.PassengerReport
  static risk_scoring.PassengerReport toRiskReport(RemoteReport r) {
    return risk_scoring.PassengerReport(
      riskRating: r.rating,
      trust: r.trust,
      timestamp: r.createdAt,
    );
  }

  /// Fetch all trips from the community, excluding the current user's trips.
  /// Uses a collectionGroup query on 'items' and filters out incidents 
  /// by checking for the 'startedAt' field.
  Future<List<Trip>> getCommunityTrips(String currentUserId) async {
    try {
      final snapshot = await _db.collectionGroup('items')
          // Since both trips and incidents are in 'items' subcollections, 
          // we filter by 'startedAt' to only get trips.
          .orderBy('startedAt', descending: true)
          // Limit to a reasonable number to prevent massive reads
          .limit(100)
          .get();

      final trips = <Trip>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        
        // Skip current user's trips since they are already loaded locally
        final userId = data['userId'] as String?;
        if (userId == null || userId == currentUserId) continue;

        // Ensure it's actually a trip (it should have startedAt because of the orderBy, but good to be safe)
        if (!data.containsKey('startedAt')) continue;

        final metadata = data['metadata'] as Map<String, dynamic>? ?? {};
        
        final startedAtTs = data['startedAt'] as Timestamp?;
        final endedAtTs = data['endedAt'] as Timestamp?;
        if (startedAtTs == null) continue;

        // Parse routePoints
        final List<Map<String, double>> routePoints = [];
        if (metadata['routePoints'] is List) {
          for (final point in metadata['routePoints']) {
            if (point is Map) {
              routePoints.add({
                'lat': (point['lat'] as num).toDouble(),
                'lng': (point['lng'] as num).toDouble(),
              });
            }
          }
        }

        trips.add(
          Trip(
            id: null, // Remote trips don't need a local SQLite ID
            startTime: startedAtTs.toDate(),
            endTime: endedAtTs?.toDate(),
            startLat: (metadata['startLat'] as num?)?.toDouble(),
            startLng: (metadata['startLng'] as num?)?.toDouble(),
            endLat: (metadata['endLat'] as num?)?.toDouble(),
            endLng: (metadata['endLng'] as num?)?.toDouble(),
            routeName: data['routeName'] as String?,
            riskScore: (metadata['riskScore'] as num?)?.toDouble() ?? 0.0,
            speedingCount: (metadata['speedingCount'] as num?)?.toInt() ?? 0,
            brakingCount: (metadata['brakingCount'] as num?)?.toInt() ?? 0,
            turningCount: (metadata['turningCount'] as num?)?.toInt() ?? 0,
            routePoints: routePoints,
          ),
        );
      }
      return trips;
    } catch (e) {
      // If collectionGroup index is missing, this will fail. We return empty list.
      return [];
    }
  }
}

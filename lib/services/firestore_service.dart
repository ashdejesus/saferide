import 'package:cloud_firestore/cloud_firestore.dart';
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
}

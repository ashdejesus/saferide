import 'sync_status.dart';

/// Trust metrics for a passenger based on historical consistency,
/// anomaly detection, and alignment with sensor outputs
class PassengerTrustMetrics {
  PassengerTrustMetrics({
    this.id,
    required this.passengerId,
    required this.totalReports,
    required this.consistencyScore, // 0-1: how consistent are reports over time
    required this.anomalyScore, // 0-1: deviation from normal pattern (lower is better)
    required this.sensorAlignmentScore, // 0-1: how well reports align with sensor data
    required this.overallTrust, // 0-1: final computed trust score
    required this.lastUpdated,
    required this.verifiedCount, // Number of reports confirmed by other passengers
    required this.flaggedCount, // Number of reports flagged as suspicious
    this.syncStatus = SyncStatus.pending,
  });

  final int? id;
  final String passengerId; // User ID or anonymous identifier
  final int totalReports;
  final double consistencyScore;
  final double anomalyScore;
  final double sensorAlignmentScore;
  final double overallTrust;
  final DateTime lastUpdated;
  final int verifiedCount;
  final int flaggedCount;
  final SyncStatus syncStatus;

  PassengerTrustMetrics copyWith({
    int? id,
    String? passengerId,
    int? totalReports,
    double? consistencyScore,
    double? anomalyScore,
    double? sensorAlignmentScore,
    double? overallTrust,
    DateTime? lastUpdated,
    int? verifiedCount,
    int? flaggedCount,
    SyncStatus? syncStatus,
  }) {
    return PassengerTrustMetrics(
      id: id ?? this.id,
      passengerId: passengerId ?? this.passengerId,
      totalReports: totalReports ?? this.totalReports,
      consistencyScore: consistencyScore ?? this.consistencyScore,
      anomalyScore: anomalyScore ?? this.anomalyScore,
      sensorAlignmentScore: sensorAlignmentScore ?? this.sensorAlignmentScore,
      overallTrust: overallTrust ?? this.overallTrust,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      verifiedCount: verifiedCount ?? this.verifiedCount,
      flaggedCount: flaggedCount ?? this.flaggedCount,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'passenger_id': passengerId,
      'total_reports': totalReports,
      'consistency_score': consistencyScore,
      'anomaly_score': anomalyScore,
      'sensor_alignment_score': sensorAlignmentScore,
      'overall_trust': overallTrust,
      'last_updated': lastUpdated.toIso8601String(),
      'verified_count': verifiedCount,
      'flagged_count': flaggedCount,
      'sync_status': syncStatus.label,
    };
  }

  static PassengerTrustMetrics fromMap(Map<String, Object?> map) {
    return PassengerTrustMetrics(
      id: map['id'] as int?,
      passengerId: map['passenger_id'] as String,
      totalReports: map['total_reports'] as int,
      consistencyScore: (map['consistency_score'] as num).toDouble(),
      anomalyScore: (map['anomaly_score'] as num).toDouble(),
      sensorAlignmentScore: (map['sensor_alignment_score'] as num).toDouble(),
      overallTrust: (map['overall_trust'] as num).toDouble(),
      lastUpdated: DateTime.parse(map['last_updated'] as String),
      verifiedCount: map['verified_count'] as int,
      flaggedCount: map['flagged_count'] as int,
      syncStatus: SyncStatus.fromString(map['sync_status'] as String?),
    );
  }
}

/// Extended report with trust metadata
class ReportWithTrust {
  ReportWithTrust({
    required this.reportId,
    required this.passengerId,
    required this.category,
    required this.severity,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.passengerTrust,
    this.isVerified = false,
    this.isFlagged = false,
  });

  final int reportId;
  final String passengerId;
  final String category;
  final int severity;
  final String? description;
  final double? latitude;
  final double? longitude;
  final DateTime timestamp;
  final double passengerTrust;
  final bool isVerified;
  final bool isFlagged;

  /// Trust-weighted severity: actual severity * passenger trust
  int get weightedSeverity => (severity * passengerTrust).round().clamp(1, 5);

  Map<String, Object?> toMap() {
    return {
      'report_id': reportId,
      'passenger_id': passengerId,
      'category': category,
      'severity': severity,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'passenger_trust': passengerTrust,
      'is_verified': isVerified ? 1 : 0,
      'is_flagged': isFlagged ? 1 : 0,
    };
  }

  static ReportWithTrust fromMap(Map<String, Object?> map) {
    return ReportWithTrust(
      reportId: map['report_id'] as int,
      passengerId: map['passenger_id'] as String,
      category: map['category'] as String,
      severity: map['severity'] as int,
      description: map['description'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      timestamp: DateTime.parse(map['timestamp'] as String),
      passengerTrust: (map['passenger_trust'] as num).toDouble(),
      isVerified: (map['is_verified'] as int) == 1,
      isFlagged: (map['is_flagged'] as int) == 1,
    );
  }
}

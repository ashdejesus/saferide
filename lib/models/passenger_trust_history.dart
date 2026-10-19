import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single chronological audit log entry for passenger trust changes.
/// Records the report-by-report calculation trace, component contributions,
/// and sensor concordance without invalidating sensor-silent submissions.
class PassengerTrustHistory {
  PassengerTrustHistory({
    this.id,
    required this.passengerId,
    required this.reportId,
    required this.reportNumber,
    required this.timestamp,
    required this.priorTrust,
    required this.newTrust,
    required this.trustDelta,
    required this.frequencyScore,
    required this.consistencyScore,
    required this.anomalyScore,
    required this.sensorAlignmentScore,
    required this.reportedSeverity,
    required this.sensorEventCount,
    required this.sensorRisk,
    required this.concordanceStatus,
    required this.validationNote,
  });

  final int? id;
  final String passengerId;
  final String reportId;
  final int reportNumber;
  final DateTime timestamp;
  final double priorTrust;
  final double newTrust;
  final double trustDelta;
  final double frequencyScore;
  final double consistencyScore;
  final double anomalyScore;
  final double sensorAlignmentScore;
  final int reportedSeverity;
  final int sensorEventCount;
  final double sensorRisk;
  final String concordanceStatus;
  final String validationNote;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'passenger_id': passengerId,
      'report_id': reportId,
      'report_number': reportNumber,
      'timestamp': timestamp.toIso8601String(),
      'prior_trust': priorTrust,
      'new_trust': newTrust,
      'trust_delta': trustDelta,
      'frequency_score': frequencyScore,
      'consistency_score': consistencyScore,
      'anomaly_score': anomalyScore,
      'sensor_alignment_score': sensorAlignmentScore,
      'reported_severity': reportedSeverity,
      'sensor_event_count': sensorEventCount,
      'sensor_risk': sensorRisk,
      'concordance_status': concordanceStatus,
      'validation_note': validationNote,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'passengerId': passengerId,
      'reportId': reportId,
      'reportNumber': reportNumber,
      'timestamp': Timestamp.fromDate(timestamp),
      'priorTrust': priorTrust,
      'newTrust': newTrust,
      'trustDelta': trustDelta,
      'frequencyScore': frequencyScore,
      'consistencyScore': consistencyScore,
      'anomalyScore': anomalyScore,
      'sensorAlignmentScore': sensorAlignmentScore,
      'reportedSeverity': reportedSeverity,
      'sensorEventCount': sensorEventCount,
      'sensorRisk': sensorRisk,
      'concordanceStatus': concordanceStatus,
      'validationNote': validationNote,
    };
  }

  static PassengerTrustHistory fromMap(Map<String, Object?> map) {
    return PassengerTrustHistory(
      id: map['id'] as int?,
      passengerId: map['passenger_id'] as String,
      reportId: (map['report_id'] ?? '') as String,
      reportNumber: (map['report_number'] as num).toInt(),
      timestamp: DateTime.parse(map['timestamp'] as String),
      priorTrust: (map['prior_trust'] as num).toDouble(),
      newTrust: (map['new_trust'] as num).toDouble(),
      trustDelta: (map['trust_delta'] as num).toDouble(),
      frequencyScore: (map['frequency_score'] as num).toDouble(),
      consistencyScore: (map['consistency_score'] as num).toDouble(),
      anomalyScore: (map['anomaly_score'] as num).toDouble(),
      sensorAlignmentScore: (map['sensor_alignment_score'] as num).toDouble(),
      reportedSeverity: ((map['reported_severity'] ?? 3) as num).toInt(),
      sensorEventCount: ((map['sensor_event_count'] ?? 0) as num).toInt(),
      sensorRisk: ((map['sensor_risk'] ?? 0.0) as num).toDouble(),
      concordanceStatus: (map['concordance_status'] ?? 'Unknown') as String,
      validationNote: (map['validation_note'] ?? '') as String,
    );
  }
}

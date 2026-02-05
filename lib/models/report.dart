import 'sync_status.dart';

class PassengerReport {
  PassengerReport({
    this.id,
    required this.tripId,
    required this.category,
    required this.severity,
    this.description,
    required this.createdAt,
    this.syncStatus = SyncStatus.pending,
  });

  final int? id;
  final int tripId;
  final String category;
  final int severity;
  final String? description;
  final DateTime createdAt;
  final SyncStatus syncStatus;

  PassengerReport copyWith({
    int? id,
    int? tripId,
    String? category,
    int? severity,
    String? description,
    DateTime? createdAt,
    SyncStatus? syncStatus,
  }) {
    return PassengerReport(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      category: category ?? this.category,
      severity: severity ?? this.severity,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'trip_id': tripId,
      'category': category,
      'severity': severity,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'sync_status': syncStatus.label,
    };
  }

  static PassengerReport fromMap(Map<String, Object?> map) {
    return PassengerReport(
      id: map['id'] as int?,
      tripId: map['trip_id'] as int,
      category: map['category'] as String,
      severity: map['severity'] as int,
      description: map['description'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      syncStatus: SyncStatus.fromString(map['sync_status'] as String?),
    );
  }
}

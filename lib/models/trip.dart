import 'dart:convert';

import 'sync_status.dart';

class Trip {
  Trip({
    this.id,
    required this.startTime,
    this.endTime,
    this.startLat,
    this.startLng,
    this.endLat,
    this.endLng,
    this.routeName,
    this.riskScore = 0,
    this.speedingCount = 0,
    this.brakingCount = 0,
    this.turningCount = 0,
    this.routePoints = const [],
    this.syncStatus = SyncStatus.pending,
  });

  final int? id;
  final DateTime startTime;
  final DateTime? endTime;
  final double? startLat;
  final double? startLng;
  final double? endLat;
  final double? endLng;
  final String? routeName;
  final double riskScore;
  final int speedingCount;
  final int brakingCount;
  final int turningCount;
  final List<Map<String, double>> routePoints;
  final SyncStatus syncStatus;

  Trip copyWith({
    int? id,
    DateTime? startTime,
    DateTime? endTime,
    double? startLat,
    double? startLng,
    double? endLat,
    double? endLng,
    String? routeName,
    double? riskScore,
    int? speedingCount,
    int? brakingCount,
    int? turningCount,
    List<Map<String, double>>? routePoints,
    SyncStatus? syncStatus,
  }) {
    return Trip(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      startLat: startLat ?? this.startLat,
      startLng: startLng ?? this.startLng,
      endLat: endLat ?? this.endLat,
      endLng: endLng ?? this.endLng,
      routeName: routeName ?? this.routeName,
      riskScore: riskScore ?? this.riskScore,
      speedingCount: speedingCount ?? this.speedingCount,
      brakingCount: brakingCount ?? this.brakingCount,
      turningCount: turningCount ?? this.turningCount,
      routePoints: routePoints ?? this.routePoints,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'start_lat': startLat,
      'start_lng': startLng,
      'end_lat': endLat,
      'end_lng': endLng,
      'route_name': routeName,
      'risk_score': riskScore,
      'speeding_count': speedingCount,
      'braking_count': brakingCount,
      'turning_count': turningCount,
      'route_points': jsonEncode(routePoints),
      'sync_status': syncStatus.label,
    };
  }

  static Trip fromMap(Map<String, Object?> map) {
    final pointsJson = map['route_points'] as String?;
    final points = pointsJson == null
        ? <Map<String, double>>[]
        : (jsonDecode(pointsJson) as List)
              .map(
                (point) => {
                  'lat': (point['lat'] as num).toDouble(),
                  'lng': (point['lng'] as num).toDouble(),
                },
              )
              .toList();

    return Trip(
      id: map['id'] as int?,
      startTime: DateTime.parse(map['start_time'] as String),
      endTime: map['end_time'] == null
          ? null
          : DateTime.parse(map['end_time'] as String),
      startLat: (map['start_lat'] as num?)?.toDouble(),
      startLng: (map['start_lng'] as num?)?.toDouble(),
      endLat: (map['end_lat'] as num?)?.toDouble(),
      endLng: (map['end_lng'] as num?)?.toDouble(),
      routeName: map['route_name'] as String?,
      riskScore: (map['risk_score'] as num?)?.toDouble() ?? 0,
      speedingCount: (map['speeding_count'] as int?) ?? 0,
      brakingCount: (map['braking_count'] as int?) ?? 0,
      turningCount: (map['turning_count'] as int?) ?? 0,
      routePoints: points,
      syncStatus: SyncStatus.fromString(map['sync_status'] as String?),
    );
  }
}

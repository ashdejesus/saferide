import 'dart:io';
import 'dart:convert';

void main() async {
  // Trip 9 in this DB is actually local ID 20 (Calamba to Los Baños)
  // saferide.db has no trip_events, but saferide_user_5y0AF7w36FZVByZOXNepMIwPQ7D3.db 
  // has the same trip as local id 20
  
  final dbPath = r'export data\SR\saferide_user_5y0AF7w36FZVByZOXNepMIwPQ7D3.db';
  
  final r = await Process.run('sqlite3', [
    dbPath, 'SELECT route_points FROM trips WHERE id = 20;'
  ]);
  
  if (r.exitCode != 0 || r.stdout.toString().trim().isEmpty) {
    print('No route_points for trip 20');
    // Try the original saferide.db trip 9
    final r2 = await Process.run('sqlite3', [
      r'export data\SR\saferide.db', 'SELECT route_points FROM trips WHERE id = 9;'
    ]);
    print('saferide.db trip 9 route_points (first 500 chars):');
    print(r2.stdout.toString().substring(0, r2.stdout.toString().length.clamp(0, 500)));
    return;
  }
  
  try {
    final json = jsonDecode(r.stdout.toString().trim());
    final points = (json as List).cast<Map<String, dynamic>>();
    
    // Sort by speed descending
    points.sort((a, b) {
      final sa = (a['speed'] as num?)?.toDouble() ?? 0.0;
      final sb = (b['speed'] as num?)?.toDouble() ?? 0.0;
      return sb.compareTo(sa);
    });
    
    print('=== TOP 15 FASTEST GPS POINTS (Trip CMC→Los Baños) ===');
    print('Timestamp | Speed (km/h) | Lat | Lng');
    for (final pt in points.take(15)) {
      final spd = (pt['speed'] as num?)?.toDouble() ?? 0.0;
      final spdKmh = spd * 3.6; // m/s to km/h
      print('${pt['timestamp']} | ${spdKmh.toStringAsFixed(1)} km/h | ${pt['lat']} | ${pt['lng']}');
    }
    
    print('\n=== ALL POINTS ABOVE 60 km/h ===');
    final fast = points.where((p) {
      final spd = ((p['speed'] as num?)?.toDouble() ?? 0.0) * 3.6;
      return spd > 60.0;
    }).toList();
    
    if (fast.isEmpty) {
      print('No points above 60 km/h in route_points');
      print('\n=== SPEED DISTRIBUTION ===');
      final allSpeeds = points.map((p) => ((p['speed'] as num?)?.toDouble() ?? 0.0) * 3.6).toList();
      allSpeeds.sort((a, b) => b.compareTo(a));
      print('Max speed: ${allSpeeds.first.toStringAsFixed(1)} km/h');
      print('Top 5: ${allSpeeds.take(5).map((s) => s.toStringAsFixed(1)).join(', ')} km/h');
      print('Total GPS points: ${points.length}');
    } else {
      for (final pt in fast) {
        final spdKmh = ((pt['speed'] as num?)?.toDouble() ?? 0.0) * 3.6;
        print('${pt['timestamp']} | ${spdKmh.toStringAsFixed(1)} km/h | ${pt['lat']} | ${pt['lng']}');
      }
    }
  } catch (e) {
    print('Parse error: $e');
    print('Raw (first 300 chars): ${r.stdout.toString().substring(0, r.stdout.toString().length.clamp(0, 300))}');
  }
}

import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  sqfliteFfiInit();
  var dbFactory = databaseFactoryFfi;
  final dir = Directory(r'c:\Users\nicho\Documents\GitHub\saferide\export data\SR');
  final dbs = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.db'));

  int totalTripsCount = 0;
  Map<String, int> routeCounts = {};
  List<Map<String, dynamic>> allTrips = [];

  for (var f in dbs) {
    try {
      var db = await dbFactory.openDatabase(f.path);
      var master = await db.query('sqlite_master', where: 'name = ?', whereArgs: ['trips']);
      if (master.isNotEmpty) {
        var trips = await db.query('trips');
        for (var t in trips) {
          totalTripsCount++;
          String route = (t['route_name'] as String?) ?? 'Unknown';
          routeCounts[route] = (routeCounts[route] ?? 0) + 1;
          allTrips.add({
            'db': f.uri.pathSegments.last,
            'id': t['id'],
            'route': route,
            'vehicle': t['vehicle_type'],
            'start': t['start_time'],
            'end': t['end_time'],
            'risk_score': t['risk_score'],
            'speeding': t['speeding_count'],
            'braking': t['braking_count'],
            'turning': t['turning_count'],
          });
        }
      }
      await db.close();
    } catch (e) {
      print('Error on ${f.path}: $e');
    }
  }

  print('Total Trips across all DBs: $totalTripsCount');
  print('\nTrips per route:');
  routeCounts.forEach((k, v) {
    print('  $k: $v');
  });

  print('\nRe-testing Trips (PL-DZ, DZ-PL, BNY-SALA, SALA-BNY, BNY-PNC, PNC-BNY):');
  for (var t in allTrips) {
    if (['PL-DZ-01', 'DZ-PL-02', 'BNY-SALA-03', 'SALA-BNY-04', 'BNY-PNC-05', 'PNC-BNY-06'].contains(t['route'])) {
      print('  ${t['db']} | Trip ${t['id']} | ${t['route']} | ${t['vehicle']} | start: ${t['start']} | end: ${t['end']} | risk: ${t['risk_score']} | S:${t['speeding']} B:${t['braking']} T:${t['turning']}');
    }
  }
}

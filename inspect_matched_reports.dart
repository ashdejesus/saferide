import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  sqfliteFfiInit();
  var dbFactory = databaseFactoryFfi;
  final dir = Directory(r'c:\Users\nicho\Documents\GitHub\saferide\export data\SR');

  // Let's inspect the two DBs with reports
  for (var dbName in ['saferide_user_59C62FDg1QPkulakJIkf6ZpsAiD2.db', 'saferide_user_XpnGgiP9MzMNTqWGAbpgdnYAaMG3.db']) {
    var dbPath = '${dir.path}\\$dbName';
    var db = await dbFactory.openDatabase(dbPath);
    print('\n=== DATABASE: $dbName ===');
    var reports = await db.query('reports');
    print('Reports count: ${reports.length}');
    for (var r in reports) {
      print('  Report: ID ${r['id']} | tripId: ${r['trip_id']} | cat: ${r['category']} | sev: ${r['severity']} | time: ${r['created_at']}');
      if (r['trip_id'] != null) {
        var trip = await db.query('trips', where: 'id = ?', whereArgs: [r['trip_id']]);
        if (trip.isNotEmpty) {
          var t = trip.first;
          print('    Matched Trip ${t['id']}: route=${t['route_name']} | vehicle=${t['vehicle_type']} | risk=${t['risk_score']} | S=${t['speeding_count']} B=${t['braking_count']} T=${t['turning_count']}');
          var evs = await db.query('trip_events', where: 'trip_id = ?', whereArgs: [t['id']]);
          print('    Trip Events: ${evs.length}');
          for (var e in evs) {
            print('      - ${e['event_type']} at ${e['timestamp']}');
          }
        }
      }
    }
    await db.close();
  }
}

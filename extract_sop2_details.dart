import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  sqfliteFfiInit();
  var dbFactory = databaseFactoryFfi;
  final srDir = r'c:\Users\nicho\Documents\GitHub\saferide\export data\SR';

  final databases = {
    'User1_59C62F': '$srDir\\saferide_user_59C62FDg1QPkulakJIkf6ZpsAiD2.db',
    'User2_XpnGgi': '$srDir\\saferide_user_XpnGgiP9MzMNTqWGAbpgdnYAaMG3.db',
  };

  final user1Trips = [1, 13, 16, 18, 20, 22, 25, 26];
  final user2Trips = [2];

  for (var entry in databases.entries) {
    var label = entry.key;
    var dbPath = entry.value;
    var db = await dbFactory.openDatabase(dbPath);

    print('=' * 80);
    print('DATABASE: $label');
    print('=' * 80);

    var tables = await db.query('sqlite_master',
        where: "type = 'table'", columns: ['name']);
    print('Tables: ${tables.map((t) => t['name']).toList()}');
    print('');

    var tripIds = label.startsWith('User1') ? user1Trips : user2Trips;

    for (var tripId in tripIds) {
      print('-' * 60);
      print('TRIP ID: $tripId');
      print('-' * 60);

      var trips = await db.query('trips', where: 'id = ?', whereArgs: [tripId]);
      if (trips.isEmpty) {
        print('  *** TRIP NOT FOUND ***');
        continue;
      }
      var t = trips.first;
      print('  Start:    ${t['start_time']}');
      print('  End:      ${t['end_time']}');
      print('  Route:    ${t['route_name']}');
      print('  Vehicle:  ${t['vehicle_type']}');
      print('  Risk:     ${t['risk_score']}');
      print('  Speeding: ${t['speeding_count']}');
      print('  Braking:  ${t['braking_count']}');
      print('  Turning:  ${t['turning_count']}');
      print('  [ALL COLUMNS]: $t');

      var eventTables = await db.query('sqlite_master',
          where: "type = 'table' AND name = 'trip_events'");
      if (eventTables.isNotEmpty) {
        var events = await db.query('trip_events',
            where: 'trip_id = ?', whereArgs: [tripId]);
        print('  Events (${events.length}):');
        for (var e in events) {
          print('    - Type: ${e['event_type']} | Time: ${e['timestamp']} | '
              'Lat: ${e['latitude']} | Lng: ${e['longitude']} | '
              'Value: ${e['value']}');
        }
      }

      var reportTables = await db.query('sqlite_master',
          where: "type = 'table' AND name = 'reports'");
      if (reportTables.isNotEmpty) {
        var reports = await db.query('reports',
            where: 'trip_id = ?', whereArgs: [tripId]);
        print('  Reports (${reports.length}):');
        for (var r in reports) {
          print('    - ID: ${r['id']} | Cat: ${r['category']} | '
              'Sev: ${r['severity']} | Time: ${r['created_at']}');
        }
      }
      print('');
    }

    var trustTables = await db.query('sqlite_master',
        where: "type = 'table' AND name = 'passenger_trust_metrics'");
    if (trustTables.isNotEmpty) {
      var trust = await db.query('passenger_trust_metrics');
      print('Trust metrics: $trust');
    }

    await db.close();
  }
}

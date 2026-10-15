import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  sqfliteFfiInit();
  var dbFactory = databaseFactoryFfi;
  final dbPath = r'c:\Users\nicho\Documents\GitHub\saferide\export data\SR\saferide_user_5y0AF7w36FZVByZOXNepMIwPQ7D3.db';
  var db = await dbFactory.openDatabase(dbPath);
  
  print('Tables:');
  var tables = await db.query('sqlite_master', where: 'type = ?', whereArgs: ['table']);
  for (var t in tables) {
    print('- ${t['name']}');
  }

  for (var id in [186, 203, 207, 220]) {
    print('\n=== TRIP ID $id ===');
    var trip = await db.query('trips', where: 'id = ?', whereArgs: [id]);
    if (trip.isNotEmpty) {
      print('Trip: ${trip.first['route_name']} | vehicle: ${trip.first['vehicle_type']} | risk: ${trip.first['risk_score']} | speeding: ${trip.first['speeding_count']} | braking: ${trip.first['braking_count']} | turning: ${trip.first['turning_count']}');
    }
    
    var hasEvents = tables.any((t) => t['name'] == 'trip_events');
    if (hasEvents) {
      var events = await db.query('trip_events', where: 'trip_id = ?', whereArgs: [id]);
      print('Events count: ${events.length}');
      for (var e in events) {
        print('  Event: $e');
      }
    }
    
    var hasSensor = tables.any((t) => t['name'] == 'sensor_readings');
    if (hasSensor) {
      var count = await db.rawQuery('SELECT count(*) as cnt FROM sensor_readings WHERE trip_id = ?', [id]);
      print('Sensor readings count: ${count.first['cnt']}');
    }
  }

  await db.close();
}

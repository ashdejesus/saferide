import 'dart:io';
import 'dart:math';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  sqfliteFfiInit();
  var dbFactory = databaseFactoryFfi;
  final dir = Directory(r'c:\Users\nicho\Documents\GitHub\saferide\export data\SR');

  // Let's inspect the exact R_sens and R_trip for trips with reports
  // Trip 1, 13, 16, 18, 20, 22, 25, 26 from saferide_user_59C62FDg1QPkulakJIkf6ZpsAiD2.db
  // Trip 2 from saferide_user_XpnGgiP9MzMNTqWGAbpgdnYAaMG3.db

  var db1 = await dbFactory.openDatabase('${dir.path}\\saferide_user_59C62FDg1QPkulakJIkf6ZpsAiD2.db');
  var db2 = await dbFactory.openDatabase('${dir.path}\\saferide_user_XpnGgiP9MzMNTqWGAbpgdnYAaMG3.db');

  print('=== PAIRED R_SENS VS R_TRIP FOR TRIPS WITH REPORTS ===');
  List<Map<String, dynamic>> pairedTrips = [];

  for (var id in [1, 13, 16, 18, 20, 22, 25, 26]) {
    var t = (await db1.query('trips', where: 'id = ?', whereArgs: [id])).first;
    var reps = await db1.query('reports', where: 'trip_id = ?', whereArgs: [id]);
    double riskScore = (t['risk_score'] as num).toDouble(); // RS_trip = 100 * R_trip
    double tripRisk = riskScore / 100.0; // R_trip
    int s = t['speeding_count'] as int;
    int b = t['braking_count'] as int;
    int turn = t['turning_count'] as int;
    
    // In the app, totalWindows = max(1, duration ~/ 2)
    // If end_time is null, let's see start and end
    print('Trip $id: RiskScore=$riskScore (R_trip=${tripRisk.toStringAsFixed(4)}) | Events: S=$s, B=$b, T=$turn | Reports: ${reps.length}');
    for (var r in reps) {
      print('   Report: cat=${r['category']}, sev=${r['severity']}');
    }
  }

  var t2 = (await db2.query('trips', where: 'id = ?', whereArgs: [2])).first;
  var reps2 = await db2.query('reports', where: 'trip_id = ?', whereArgs: [2]);
  double riskScore2 = (t2['risk_score'] as num).toDouble();
  print('Trip 2 (User 2): RiskScore=$riskScore2 (R_trip=${(riskScore2/100).toStringAsFixed(4)}) | Reports: ${reps2.length}');

  await db1.close();
  await db2.close();
}

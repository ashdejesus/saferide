import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;

void main() async {
  sqfliteFfiInit();
  var databaseFactory = databaseFactoryFfi;
  final exportDir = Directory(r'c:\Users\nicho\Documents\GitHub\saferide\export data\SR');
  final files = exportDir.listSync().whereType<File>().where((f) => f.path.endsWith('.db'));

  final sop2File = File(r'c:\Users\nicho\Documents\GitHub\saferide\export data\sop2_dataset.csv');
  final sop3File = File(r'c:\Users\nicho\Documents\GitHub\saferide\export data\sop3_dataset.csv');

  final sop2Buffer = StringBuffer();
  sop2Buffer.writeln('User,Reporting Frequency (Total Reports),Credibility (Overall Trust),Conforming Reports (Verified Count)');

  final sop3Buffer = StringBuffer();
  sop3Buffer.writeln('Trip ID,Route,Vehicle,Risk Score,Speeding,Braking,Turning,Pothole');

  for (var file in files) {
    try {
      var db = await databaseFactory.openDatabase(file.path);
      
      var tables = await db.query('sqlite_master', where: 'type = ? AND name = ?', whereArgs: ['table', 'passenger_trust_metrics']);
      if (tables.isNotEmpty) {
        var metrics = await db.query('passenger_trust_metrics');
        for (var m in metrics) {
          sop2Buffer.writeln('${m['passenger_id']},${m['total_reports']},${m['overall_trust']},${m['verified_count']}');
        }
      }

      tables = await db.query('sqlite_master', where: 'type = ? AND name = ?', whereArgs: ['table', 'trips']);
      if (tables.isNotEmpty) {
        var trips = await db.query('trips');
        for (var t in trips) {
          if (['PL-DZ-01', 'DZ-PL-02', 'BNY-SALA-03', 'SALA-BNY-04', 'BNY-PNC-05', 'PNC-BNY-06'].contains(t['route_name'])) {
            int potholeCount = 0;
            var eventTables = await db.query('sqlite_master', where: 'type = ? AND name = ?', whereArgs: ['table', 'trip_events']);
            if (eventTables.isNotEmpty) {
               var events = await db.query('trip_events', where: 'trip_id = ? AND event_type = ?', whereArgs: [t['id'], 'Pothole']);
               potholeCount = events.length;
            }
            sop3Buffer.writeln('${t['route_name']},${t['route_name']},${t['vehicle_type']},${t['risk_score']},${t['speeding_count']},${t['braking_count']},${t['turning_count']},$potholeCount');
          }
        }
      }
      await db.close();
    } catch (e) {
      print('Error reading ${file.path}: $e');
    }
  }

  await sop2File.writeAsString(sop2Buffer.toString());
  await sop3File.writeAsString(sop3Buffer.toString());
  print('Done exporting SOP2 and SOP3');
}

import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;

void main() async {
  sqfliteFfiInit();
  var databaseFactory = databaseFactoryFfi;

  final exportDir = Directory('export data/SR');
  final csvFile = File('export data/extracted_trips.csv');
  
  if (!exportDir.existsSync()) {
    print('Export dir not found');
    return;
  }

  final files = exportDir.listSync().whereType<File>().where((f) => f.path.endsWith('.db'));
  
  final buffer = StringBuffer();
  buffer.writeln('User DB,Trip ID,Start Time,End Time,Route,Vehicle,Risk Score,Speeding Count,Braking Count,Turning Count');

  for (var file in files) {
    try {
      var db = await databaseFactory.openDatabase(file.path);
      
      // Check if trips table exists
      var tables = await db.query('sqlite_master', where: 'type = ? AND name = ?', whereArgs: ['table', 'trips']);
      if (tables.isNotEmpty) {
        var trips = await db.query('trips');
        for (var t in trips) {
          buffer.writeln('${p.basename(file.path)},${t['id']},${t['start_time']},${t['end_time']},${t['route_name']},${t['vehicle_type']},${t['risk_score']},${t['speeding_count']},${t['braking_count']},${t['turning_count']}');
        }
      }
      
      await db.close();
    } catch (e) {
      print('Error reading ${file.path}: $e');
    }
  }

  await csvFile.writeAsString(buffer.toString());
  print('Successfully extracted trips to export data/extracted_trips.csv');
}

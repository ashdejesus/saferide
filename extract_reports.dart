import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;

void main() async {
  sqfliteFfiInit();
  var databaseFactory = databaseFactoryFfi;

  final exportDir = Directory(r'c:\Users\nicho\Documents\GitHub\saferide\export data\SR');
  final csvFile = File(r'c:\Users\nicho\Documents\GitHub\saferide\export data\extracted_reports.csv');
  
  if (!exportDir.existsSync()) {
    return;
  }

  final files = exportDir.listSync().whereType<File>().where((f) => f.path.endsWith('.db'));
  
  final buffer = StringBuffer();
  buffer.writeln('User DB,Report ID,Trip ID,Category,Severity,Created At');

  for (var file in files) {
    try {
      var db = await databaseFactory.openDatabase(file.path);
      var tables = await db.query('sqlite_master', where: 'type = ? AND name = ?', whereArgs: ['table', 'reports']);
      if (tables.isNotEmpty) {
        var reports = await db.query('reports');
        for (var r in reports) {
          buffer.writeln('${p.basename(file.path)},${r['id']},${r['trip_id']},${r['category']},${r['severity']},${r['created_at']}');
        }
      }
      await db.close();
    } catch (e) {}
  }

  await csvFile.writeAsString(buffer.toString());
  print('Successfully extracted reports to export data/extracted_reports.csv');
}

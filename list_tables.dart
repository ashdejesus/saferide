import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  sqfliteFfiInit();
  var databaseFactory = databaseFactoryFfi;

  final dbPath = r'c:\Users\nicho\Documents\GitHub\saferide\export data\SR\saferide.db';
  var db = await databaseFactory.openDatabase(dbPath);
  
  var tables = await db.query('sqlite_master', where: 'type = ?', whereArgs: ['table']);
  for (var t in tables) {
    print('Table: ${t['name']}');
    var columns = await db.rawQuery('PRAGMA table_info(${t['name']})');
    for (var c in columns) {
      print('  - ${c['name']}');
    }
  }
  
  await db.close();
}

import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  sqfliteFfiInit();
  var dbFactory = databaseFactoryFfi;
  final dir = Directory(r'c:\Users\nicho\Documents\GitHub\saferide\export data\SR');
  final dbs = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.db'));

  for (var f in dbs) {
    var db = await dbFactory.openDatabase(f.path);
    var master = await db.query('sqlite_master', where: 'name = ?', whereArgs: ['passenger_trust_metrics']);
    if (master.isNotEmpty) {
      var metrics = await db.query('passenger_trust_metrics');
      if (metrics.isNotEmpty) {
        print('DB: ${f.uri.pathSegments.last}');
        for (var m in metrics) {
          print(m);
        }
      }
    }
    await db.close();
  }
}

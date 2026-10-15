import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  sqfliteFfiInit();
  var dbFactory = databaseFactoryFfi;
  final dir = Directory('export data/SR');
  for (var f in dir.listSync().whereType<File>().where((x) => x.path.endsWith('.db'))) {
    var db = await dbFactory.openDatabase(f.path);
    var master = await db.query('sqlite_master', where: 'name = ?', whereArgs: ['trips']);
    if (master.isNotEmpty) {
      var res = await db.rawQuery("SELECT id, route_name, vehicle_type, start_time, end_time, risk_score, speeding_count, braking_count, turning_count FROM trips WHERE route_name IN ('PL-DZ-01', 'DZ-PL-02', 'BNY-SALA-03', 'SALA-BNY-04')");
      if (res.isNotEmpty) {
        print('=== DB: ${f.path} ===');
        for (var r in res) {
          print(r);
        }
      }
    }
    await db.close();
  }
}

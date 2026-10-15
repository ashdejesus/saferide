import 'dart:convert';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  sqfliteFfiInit();
  var dbFactory = databaseFactoryFfi;
  final dbPath = r'c:\Users\nicho\Documents\GitHub\saferide\export data\SR\saferide_user_5y0AF7w36FZVByZOXNepMIwPQ7D3.db';
  var db = await dbFactory.openDatabase(dbPath);

  for (var id in [186, 203, 207, 220]) {
    var trip = (await db.query('trips', where: 'id = ?', whereArgs: [id])).first;
    var raw = trip['route_points'] as String?;
    if (raw != null) {
      var pts = jsonDecode(raw) as List;
      print('Trip $id (${trip['route_name']}): ${pts.length} route points');
      if (pts.isNotEmpty) {
        print('  First point: ${pts.first}');
        print('  Last point: ${pts.last}');
      }
    }
  }

  await db.close();
}

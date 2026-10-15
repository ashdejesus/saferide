import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  sqfliteFfiInit();
  var dbFactory = databaseFactoryFfi;
  final dir = Directory(r'c:\Users\nicho\Documents\GitHub\saferide\export data\SR');
  final dbs = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.db'));

  int totalTrips = 0;
  int tripsWithReports = 0;

  for (var f in dbs) {
    var db = await dbFactory.openDatabase(f.path);
    var master = await db.query('sqlite_master', where: 'name = ?', whereArgs: ['reports']);
    int reportCount = 0;
    if (master.isNotEmpty) {
      var reps = await db.query('reports');
      reportCount = reps.length;
    }
    var tripMaster = await db.query('sqlite_master', where: 'name = ?', whereArgs: ['trips']);
    if (tripMaster.isNotEmpty) {
      var trips = await db.query('trips');
      totalTrips += trips.length;
      if (reportCount > 0) {
        tripsWithReports += trips.length;
        print('${f.uri.pathSegments.last}: ${trips.length} trips, $reportCount local reports');
      }
    }
    await db.close();
  }

  print('\nSummary: Total trips = $totalTrips, DBs with reports = $tripsWithReports');
}

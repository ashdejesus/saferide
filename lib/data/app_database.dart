import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/report.dart';
import '../models/sync_status.dart';
import '../models/trip.dart';

class AppDatabase {
  static const _databaseName = 'saferide.db';
  static const _databaseVersion = 1;

  Database? _database;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null) {
      return existing;
    }

    final documentsDirectory = await getApplicationDocumentsDirectory();
    final dbPath = path.join(documentsDirectory.path, _databaseName);

    _database = await openDatabase(
      dbPath,
      version: _databaseVersion,
      onCreate: _onCreate,
    );

    return _database!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE trips (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        start_time TEXT NOT NULL,
        end_time TEXT,
        start_lat REAL,
        start_lng REAL,
        end_lat REAL,
        end_lng REAL,
        route_name TEXT,
        risk_score REAL,
        speeding_count INTEGER,
        braking_count INTEGER,
        turning_count INTEGER,
        route_points TEXT,
        sync_status TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE reports (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trip_id INTEGER NOT NULL,
        category TEXT NOT NULL,
        severity INTEGER NOT NULL,
        description TEXT,
        created_at TEXT NOT NULL,
        sync_status TEXT,
        FOREIGN KEY(trip_id) REFERENCES trips(id) ON DELETE CASCADE
      );
    ''');
  }

  Future<int> insertTrip(Trip trip) async {
    final db = await database;
    return db.insert('trips', trip.toMap());
  }

  Future<void> updateTrip(Trip trip) async {
    final db = await database;
    await db.update(
      'trips',
      trip.toMap(),
      where: 'id = ?',
      whereArgs: [trip.id],
    );
  }

  Future<List<Trip>> getTrips() async {
    final db = await database;
    final results = await db.query('trips', orderBy: 'start_time DESC');
    return results.map(Trip.fromMap).toList();
  }

  Future<Trip?> getTripById(int id) async {
    final db = await database;
    final results = await db.query('trips', where: 'id = ?', whereArgs: [id]);
    if (results.isEmpty) {
      return null;
    }
    return Trip.fromMap(results.first);
  }

  Future<int> insertReport(PassengerReport report) async {
    final db = await database;
    return db.insert('reports', report.toMap());
  }

  Future<List<PassengerReport>> getReportsForTrip(int tripId) async {
    final db = await database;
    final results = await db.query(
      'reports',
      where: 'trip_id = ?',
      whereArgs: [tripId],
      orderBy: 'created_at DESC',
    );
    return results.map(PassengerReport.fromMap).toList();
  }

  Future<List<PassengerReport>> getPendingReports() async {
    final db = await database;
    final results = await db.query(
      'reports',
      where: 'sync_status = ?',
      whereArgs: [SyncStatus.pending.label],
    );
    return results.map(PassengerReport.fromMap).toList();
  }

  Future<List<Trip>> getPendingTrips() async {
    final db = await database;
    final results = await db.query(
      'trips',
      where: 'sync_status = ?',
      whereArgs: [SyncStatus.pending.label],
    );
    return results.map(Trip.fromMap).toList();
  }

  Future<PendingCounts> getPendingCounts() async {
    final db = await database;
    final tripCount =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM trips WHERE sync_status = ?',
            [SyncStatus.pending.label],
          ),
        ) ??
        0;
    final reportCount =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM reports WHERE sync_status = ?',
            [SyncStatus.pending.label],
          ),
        ) ??
        0;
    return PendingCounts(trips: tripCount, reports: reportCount);
  }

  Future<void> updateReport(PassengerReport report) async {
    final db = await database;
    await db.update(
      'reports',
      report.toMap(),
      where: 'id = ?',
      whereArgs: [report.id],
    );
  }
}

class PendingCounts {
  const PendingCounts({required this.trips, required this.reports});

  final int trips;
  final int reports;

  int get total => trips + reports;
}

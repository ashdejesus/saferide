import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/passenger_trust_metrics.dart';
import '../models/report.dart';
import '../models/sync_status.dart';
import '../models/trip.dart';

class AppDatabase {
  static const _databaseBaseName = 'saferide';
  static const _databaseVersion = 3;

  Database? _database;
  String _activeStorageKey = 'signed_out';
  String? _openedStorageKey;

  void configureForUser({required String? uid, required bool isAnonymous}) {
    final key = _storageKeyForUser(uid: uid, isAnonymous: isAnonymous);
    _activeStorageKey = key;
  }

  String _storageKeyForUser({required String? uid, required bool isAnonymous}) {
    if (uid == null || uid.isEmpty) {
      return 'signed_out';
    }
    return isAnonymous ? 'anon_$uid' : 'user_$uid';
  }

  String _databaseFileNameForScope(String storageKey) {
    if (storageKey == 'signed_out') {
      return 'saferide.db';
    }
    return '${_databaseBaseName}_$storageKey.db';
  }

  Future<Database> get database async {
    final existing = _database;
    if (existing != null && _openedStorageKey == _activeStorageKey) {
      return existing;
    }

    if (existing != null && _openedStorageKey != _activeStorageKey) {
      await existing.close();
      _database = null;
    }

    final documentsDirectory = await getApplicationDocumentsDirectory();
    final dbPath = path.join(
      documentsDirectory.path,
      _databaseFileNameForScope(_activeStorageKey),
    );

    await _migrateAnonymousScopeIfNeeded(
      documentsPath: documentsDirectory.path,
      targetPath: dbPath,
      targetStorageKey: _activeStorageKey,
    );

    _database = await openDatabase(
      dbPath,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    _openedStorageKey = _activeStorageKey;

    return _database!;
  }

  Future<void> _migrateAnonymousScopeIfNeeded({
    required String documentsPath,
    required String targetPath,
    required String targetStorageKey,
  }) async {
    if (!targetStorageKey.startsWith('user_')) {
      return;
    }

    final targetFile = File(targetPath);
    if (await targetFile.exists()) {
      return;
    }

    final uid = targetStorageKey.substring('user_'.length);
    if (uid.isEmpty) {
      return;
    }

    final sourceFileName = _databaseFileNameForScope('anon_$uid');
    final sourcePath = path.join(documentsPath, sourceFileName);
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      return;
    }

    await sourceFile.copy(targetPath);
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
        sync_status TEXT,
        vehicle_type TEXT
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

    if (version >= 2) {
      await _createTrustMetricsTables(db);
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2 && newVersion >= 2) {
      await _createTrustMetricsTables(db);
    }
    if (oldVersion < 3 && newVersion >= 3) {
      await db.execute('ALTER TABLE trips ADD COLUMN vehicle_type TEXT;');
    }
  }

  Future<void> _createTrustMetricsTables(Database db) async {
    await db.execute('''
      CREATE TABLE passenger_trust_metrics (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        passenger_id TEXT UNIQUE NOT NULL,
        total_reports INTEGER DEFAULT 0,
        consistency_score REAL DEFAULT 0.5,
        anomaly_score REAL DEFAULT 0.0,
        sensor_alignment_score REAL DEFAULT 0.5,
        overall_trust REAL DEFAULT 0.5,
        last_updated TEXT NOT NULL,
        verified_count INTEGER DEFAULT 0,
        flagged_count INTEGER DEFAULT 0,
        sync_status TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE reports_with_trust (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        report_id INTEGER NOT NULL,
        passenger_id TEXT NOT NULL,
        category TEXT NOT NULL,
        severity INTEGER NOT NULL,
        description TEXT,
        latitude REAL,
        longitude REAL,
        timestamp TEXT NOT NULL,
        passenger_trust REAL DEFAULT 0.5,
        is_verified INTEGER DEFAULT 0,
        is_flagged INTEGER DEFAULT 0,
        sync_status TEXT
      ) 
    ''');
  }

  static final List<Trip> _webTrips = [
    Trip(
      id: 1,
      startTime: DateTime.now().subtract(const Duration(days: 1)),
      endTime: DateTime.now().subtract(const Duration(days: 1, hours: -1)),
      startLat: 37.422,
      startLng: -122.084,
      endLat: 37.425,
      endLng: -122.080,
      riskScore: 20, // Safe trip (80% safety)
      routePoints: [
        {'lat': 37.422, 'lng': -122.084},
        {'lat': 37.423, 'lng': -122.083},
        {'lat': 37.424, 'lng': -122.081},
        {'lat': 37.425, 'lng': -122.080},
      ],
    ),
    Trip(
      id: 2,
      startTime: DateTime.now().subtract(const Duration(days: 2)),
      endTime: DateTime.now().subtract(const Duration(days: 2, hours: -1)),
      startLat: 37.422,
      startLng: -122.084,
      endLat: 37.420,
      endLng: -122.088,
      riskScore: 60, // Risky trip (40% safety)
      speedingCount: 3,
      brakingCount: 1,
      turningCount: 2,
      routePoints: [
        {'lat': 37.422, 'lng': -122.084},
        {'lat': 37.421, 'lng': -122.086},
        {'lat': 37.420, 'lng': -122.088},
      ],
    ),
  ];

  Future<int> insertTrip(Trip trip) async {
    if (kIsWeb) {
      final newId = DateTime.now().millisecondsSinceEpoch;
      _webTrips.add(trip.copyWith(id: newId));
      return newId;
    }
    final db = await database;
    return db.insert('trips', trip.toMap());
  }

  Future<void> updateTrip(Trip trip) async {
    if (kIsWeb) {
      final index = _webTrips.indexWhere((t) => t.id == trip.id);
      if (index != -1) {
        _webTrips[index] = trip;
      } else {
        _webTrips.add(trip);
      }
      return;
    }
    final db = await database;
    await db.update(
      'trips',
      trip.toMap(),
      where: 'id = ?',
      whereArgs: [trip.id],
    );
  }

  Future<void> deleteTrip(int id) async {
    if (kIsWeb) {
      _webTrips.removeWhere((t) => t.id == id);
      return;
    }
    final db = await database;
    await db.delete(
      'trips',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Trip>> getTrips() async {
    if (kIsWeb) {
      return _webTrips.toList().reversed.toList();
    }
    final db = await database;
    final results = await db.query('trips', orderBy: 'start_time DESC');
    return results.map(Trip.fromMap).toList();
  }

  Future<Trip?> getTripById(int id) async {
    if (kIsWeb) return null;
    final db = await database;
    final results = await db.query('trips', where: 'id = ?', whereArgs: [id]);
    if (results.isEmpty) {
      return null;
    }
    return Trip.fromMap(results.first);
  }

  Future<int> insertReport(PassengerReport report) async {
    if (kIsWeb) return DateTime.now().millisecondsSinceEpoch;
    final db = await database;
    return db.insert('reports', report.toMap());
  }

  Future<List<PassengerReport>> getReportsForTrip(int tripId) async {
    if (kIsWeb) return [];
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
    if (kIsWeb) return [];
    final db = await database;
    final results = await db.query(
      'reports',
      where: 'sync_status = ?',
      whereArgs: [SyncStatus.pending.label],
    );
    return results.map(PassengerReport.fromMap).toList();
  }

  Future<List<Trip>> getPendingTrips() async {
    if (kIsWeb) return [];
    final db = await database;
    final results = await db.query(
      'trips',
      where: 'sync_status = ?',
      whereArgs: [SyncStatus.pending.label],
    );
    return results.map(Trip.fromMap).toList();
  }

  Future<PendingCounts> getPendingCounts() async {
    if (kIsWeb) return const PendingCounts(trips: 0, reports: 0);
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
    if (kIsWeb) return;
    final db = await database;
    await db.update(
      'reports',
      report.toMap(),
      where: 'id = ?',
      whereArgs: [report.id],
    );
  }

  /// Insert or update passenger trust metrics
  Future<int> upsertPassengerTrustMetrics(PassengerTrustMetrics metrics) async {
    if (kIsWeb) return DateTime.now().millisecondsSinceEpoch;
    final db = await database;
    return db.insert(
      'passenger_trust_metrics',
      metrics.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get trust metrics for a passenger
  Future<PassengerTrustMetrics?> getPassengerTrustMetrics(
    String passengerId,
  ) async {
    if (kIsWeb) return null;
    final db = await database;
    final results = await db.query(
      'passenger_trust_metrics',
      where: 'passenger_id = ?',
      whereArgs: [passengerId],
    );
    if (results.isEmpty) {
      return null;
    }
    return PassengerTrustMetrics.fromMap(results.first);
  }

  /// Insert report with trust information
  Future<int> insertReportWithTrust(ReportWithTrust report) async {
    if (kIsWeb) return DateTime.now().millisecondsSinceEpoch;
    final db = await database;
    return db.insert('reports_with_trust', report.toMap());
  }

  /// Get reports with trust information for a trip
  Future<List<ReportWithTrust>> getReportsWithTrust(int tripId) async {
    if (kIsWeb) return [];
    final db = await database;
    final results = await db.query(
      'reports_with_trust',
      where: 'trip_id = ?',
      whereArgs: [tripId],
      orderBy: 'timestamp DESC',
    );
    return results.map(ReportWithTrust.fromMap).toList();
  }

  /// Get pending trust metrics to sync
  Future<List<PassengerTrustMetrics>> getPendingTrustMetrics() async {
    if (kIsWeb) return [];
    final db = await database;
    final results = await db.query(
      'passenger_trust_metrics',
      where: 'sync_status = ?',
      whereArgs: [SyncStatus.pending.label],
    );
    return results.map(PassengerTrustMetrics.fromMap).toList();
  }

  /// Update trust metrics sync status
  Future<void> updateTrustMetricsSyncStatus(
    String passengerId,
    SyncStatus status,
  ) async {
    if (kIsWeb) return;
    final db = await database;
    await db.update(
      'passenger_trust_metrics',
      {'sync_status': status.label},
      where: 'passenger_id = ?',
      whereArgs: [passengerId],
    );
  }
}

class PendingCounts {
  const PendingCounts({required this.trips, required this.reports});

  final int trips;
  final int reports;

  int get total => trips + reports;
}

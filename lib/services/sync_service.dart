import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/app_database.dart';
import '../models/sync_status.dart';

class SyncService extends ChangeNotifier {
  SyncService(this._database);

  final AppDatabase _database;
  bool _initialized = false;
  String? _initError;
  DateTime? _lastSyncAt;
  SyncResult? _lastResult;
  bool _isSyncing = false;
  double? _syncProgress;
  int? _totalItems;
  int? _syncedItems;

  String? get initError => _initError;
  bool get isReady => _initialized;
  DateTime? get lastSyncAt => _lastSyncAt;
  SyncResult? get lastResult => _lastResult;
  bool get isSyncing => _isSyncing;
  double? get syncProgress => _syncProgress;
  int? get totalItems => _totalItems;
  int? get syncedItems => _syncedItems;

  Future<bool> initialize() async {
    if (_initialized) {
      return true;
    }

    try {
      await Firebase.initializeApp();
      _initialized = true;
      _initError = null;
      return true;
    } catch (error) {
      _initError = error.toString();
      return false;
    }
  }

  Future<SyncResult> syncPending() async {
    _isSyncing = true;
    _syncProgress = null;
    _syncedItems = 0;
    notifyListeners();

    final ready = await initialize();
    if (!ready) {
      final result = SyncResult.failed('Firebase not configured.');
      _lastSyncAt = DateTime.now();
      _lastResult = result;
      _isSyncing = false;
      notifyListeners();
      return result;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      final result = SyncResult.failed('Sign in to sync to Firestore.');
      _lastSyncAt = DateTime.now();
      _lastResult = result;
      _isSyncing = false;
      notifyListeners();
      return result;
    }

    final firestore = FirebaseFirestore.instance;
    final pendingTrips = await _database.getPendingTrips();
    final pendingReports = await _database.getPendingReports();

    _totalItems = pendingTrips.length + pendingReports.length;
    _syncedItems = 0;
    notifyListeners();

    final batch = firestore.batch();

    for (final trip in pendingTrips) {
      final docId =
          trip.id?.toString() ??
          trip.startTime.millisecondsSinceEpoch.toString();
      final doc = firestore.collection('trips').doc(docId);
      batch.set(doc, {
        'userId': user.uid,
        'startedAt': Timestamp.fromDate(trip.startTime),
        'endedAt': trip.endTime == null
            ? null
            : Timestamp.fromDate(trip.endTime!),
        'routeName': trip.routeName,
        'metadata': {
          'riskScore': trip.riskScore,
          'speedingCount': trip.speedingCount,
          'brakingCount': trip.brakingCount,
          'turningCount': trip.turningCount,
          'routePoints': trip.routePoints,
          'startLat': trip.startLat,
          'startLng': trip.startLng,
          'endLat': trip.endLat,
          'endLng': trip.endLng,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    for (final report in pendingReports) {
      final docId =
          report.id?.toString() ??
          report.createdAt.millisecondsSinceEpoch.toString();
      final doc = firestore.collection('incidents').doc(docId);
      batch.set(doc, {
        'reportedBy': user.uid,
        'description': report.description,
        'createdAt': FieldValue.serverTimestamp(),
        'metadata': {
          'tripId': report.tripId,
          'category': report.category,
          'severity': report.severity,
        },
      });
    }

    try {
      await batch.commit();
      await Future.wait([
        for (final trip in pendingTrips)
          _database.updateTrip(trip.copyWith(syncStatus: SyncStatus.synced)),
        for (final report in pendingReports)
          _database.updateReport(
            report.copyWith(syncStatus: SyncStatus.synced),
          ),
      ]);

      _syncedItems = _totalItems;
      _syncProgress = 1.0;
      notifyListeners();

      final result = SyncResult.success(
        tripsSynced: pendingTrips.length,
        reportsSynced: pendingReports.length,
      );
      _lastSyncAt = DateTime.now();
      _lastResult = result;
      _isSyncing = false;
      notifyListeners();
      return result;
    } catch (error) {
      final result = SyncResult.failed(error.toString());
      _lastSyncAt = DateTime.now();
      _lastResult = result;
      _isSyncing = false;
      notifyListeners();
      return result;
    }
  }
}

class SyncResult {
  SyncResult._(
    this.success,
    this.message, {
    this.tripsSynced = 0,
    this.reportsSynced = 0,
  });

  factory SyncResult.success({
    required int tripsSynced,
    required int reportsSynced,
  }) {
    return SyncResult._(
      true,
      'Sync complete',
      tripsSynced: tripsSynced,
      reportsSynced: reportsSynced,
    );
  }

  factory SyncResult.failed(String message) {
    return SyncResult._(false, message);
  }

  final bool success;
  final String message;
  final int tripsSynced;
  final int reportsSynced;
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../data/app_database.dart';
import '../models/sync_status.dart';

class SyncService extends ChangeNotifier {
  SyncService(this._database);

  final AppDatabase _database;
  bool _initialized = false;
  String? _initError;
  DateTime? _lastSyncAt;
  SyncResult? _lastResult;

  String? get initError => _initError;
  bool get isReady => _initialized;
  DateTime? get lastSyncAt => _lastSyncAt;
  SyncResult? get lastResult => _lastResult;

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
    final ready = await initialize();
    if (!ready) {
      final result = SyncResult.failed('Firebase not configured.');
      _lastSyncAt = DateTime.now();
      _lastResult = result;
      notifyListeners();
      return result;
    }

    final firestore = FirebaseFirestore.instance;
    final pendingTrips = await _database.getPendingTrips();
    final pendingReports = await _database.getPendingReports();

    final batch = firestore.batch();

    for (final trip in pendingTrips) {
      final doc = firestore.collection('trips').doc();
      batch.set(doc, {
        'startTime': trip.startTime.toIso8601String(),
        'endTime': trip.endTime?.toIso8601String(),
        'startLat': trip.startLat,
        'startLng': trip.startLng,
        'endLat': trip.endLat,
        'endLng': trip.endLng,
        'routeName': trip.routeName,
        'riskScore': trip.riskScore,
        'speedingCount': trip.speedingCount,
        'brakingCount': trip.brakingCount,
        'turningCount': trip.turningCount,
        'routePoints': trip.routePoints,
      });
    }

    for (final report in pendingReports) {
      final doc = firestore.collection('reports').doc();
      batch.set(doc, {
        'tripId': report.tripId,
        'category': report.category,
        'severity': report.severity,
        'description': report.description,
        'createdAt': report.createdAt.toIso8601String(),
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
      final result = SyncResult.success(
        tripsSynced: pendingTrips.length,
        reportsSynced: pendingReports.length,
      );
      _lastSyncAt = DateTime.now();
      _lastResult = result;
      notifyListeners();
      return result;
    } catch (error) {
      final result = SyncResult.failed(error.toString());
      _lastSyncAt = DateTime.now();
      _lastResult = result;
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

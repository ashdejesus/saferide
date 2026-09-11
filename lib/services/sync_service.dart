import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';

import '../data/app_database.dart';
import '../services/notification_service.dart';
import '../models/sync_status.dart';
import '../models/trip.dart';

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


  Future<void> restoreTripsFromCloud() async {
    final ready = await initialize();
    if (!ready) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) return;

    try {
      final firestore = FirebaseFirestore.instance;
      final tripsSnapshot = await firestore
          .collection('trips')
          .doc(user.uid)
          .collection('items')
          .get();

      if (tripsSnapshot.docs.isEmpty) return;

      final localTrips = await _database.getTrips();
      final localStartTimes = localTrips.map((t) => t.startTime.millisecondsSinceEpoch).toSet();

      for (final doc in tripsSnapshot.docs) {
        final data = doc.data();
        final metadata = data['metadata'] as Map<String, dynamic>? ?? {};

        final startedAtTs = data['startedAt'] as Timestamp?;
        if (startedAtTs == null) continue;

        if (localStartTimes.contains(startedAtTs.millisecondsSinceEpoch)) {
          continue; // Already exists locally
        }

        final endedAtTs = data['endedAt'] as Timestamp?;
        
        // Safely parse routePoints
        List<Map<String, double>> parsedRoutePoints = [];
        if (metadata['routePoints'] != null) {
          final rpList = metadata['routePoints'] as List<dynamic>;
          parsedRoutePoints = rpList.map((p) {
            final pMap = p as Map<String, dynamic>;
            return {
              'lat': (pMap['lat'] as num).toDouble(),
              'lng': (pMap['lng'] as num).toDouble(),
            };
          }).toList();
        }

        final trip = Trip(
          startTime: startedAtTs.toDate(),
          endTime: endedAtTs?.toDate(),
          routeName: data['routeName'] as String?,
          startLat: (metadata['startLat'] as num?)?.toDouble(),
          startLng: (metadata['startLng'] as num?)?.toDouble(),
          endLat: (metadata['endLat'] as num?)?.toDouble(),
          endLng: (metadata['endLng'] as num?)?.toDouble(),
          riskScore: (metadata['riskScore'] as num?)?.toDouble() ?? 0,
          speedingCount: (metadata['speedingCount'] as num?)?.toInt() ?? 0,
          brakingCount: (metadata['brakingCount'] as num?)?.toInt() ?? 0,
          turningCount: (metadata['turningCount'] as num?)?.toInt() ?? 0,
          routePoints: parsedRoutePoints,
          syncStatus: SyncStatus.synced,
        );

        await _database.insertTrip(trip);
      }
    } catch (e) {
      debugPrint('SyncService: Failed to restore trips from cloud: $e');
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

    if (user.isAnonymous) {
      final result = SyncResult.failed(
        'Register your guest account before syncing trips.',
      );
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

    final userTripsRoot = firestore.collection('trips').doc(user.uid);
    final userIncidentsRoot = firestore.collection('incidents').doc(user.uid);

    for (final trip in pendingTrips) {
      final docId =
          trip.id?.toString() ??
          trip.startTime.millisecondsSinceEpoch.toString();
      final doc = userTripsRoot.collection('items').doc(docId);
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
      final doc = userIncidentsRoot.collection('items').doc(docId);
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
      
      NotificationService().cancelSyncReminder();
      
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

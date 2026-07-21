import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../data/app_database.dart';
import '../models/report.dart';
import '../models/sync_status.dart';
import '../models/trip.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/risk_scoring.dart' as risk_scoring;
import '../services/firestore_service.dart';
import '../services/sensor_service.dart';

class TripController extends ChangeNotifier {
  TripController({
    required AppDatabase database,
    LocationService? locationService,
    SensorService? sensorService,
    FirestoreService? firestoreService,
  }) : _database = database,
       _locationService = locationService ?? LocationService(),
       _sensorService = sensorService ?? SensorService(),
       _firestoreService = firestoreService ?? FirestoreService();
  final FirestoreService _firestoreService;

  final AppDatabase _database;
  final LocationService _locationService;
  final SensorService _sensorService;
  final NotificationService _notificationService = NotificationService();

  Trip? _activeTrip;
  bool _isTracking = false;
  double _currentSpeed = 0;
  Position? _currentPosition;
  final List<Map<String, double>> _routePoints = [];

  int _speedingCount = 0;
  int _brakingCount = 0;
  int _turningCount = 0;
  int _potholeCount = 0; // P(t): pothole event aggregation
  double _totalSlopeDeviation = 0; // Σ|S(t)|: accumulated slope deviation
  int _reportSeveritySum = 0;
  int _consecutiveEventsInWindow = 0; // For rapid-fire event detection
  DateTime? _lastNotificationTime; // Throttle notifications
  List<RemoteReport> _remoteReports = [];
  StreamSubscription<List<RemoteReport>>? _remoteReportsSub;

  final risk_scoring.SlidingWindow _accelWindow = risk_scoring.SlidingWindow(
    size: 15,
  );
  final risk_scoring.SlidingWindow _speedWindow = risk_scoring.SlidingWindow(
    size: 10,
  );
  final risk_scoring.SlidingWindow _gyroWindow = risk_scoring.SlidingWindow(
    size: 10,
  );
  final List<risk_scoring.UnsafeEvent> _recentEvents = [];
  final risk_scoring.AdaptiveThresholds _adaptiveThresholds =
      risk_scoring.AdaptiveThresholds();
  DateTime? _lastBrakeEvent;
  DateTime? _lastTurnEvent;
  DateTime? _lastSpeedEvent;
  DateTime? _lastPotholeEvent; // Cooldown for pothole detection
  double _lastRecordedSpeed = 0;
  int _turningStreak = 0;

  // Slope calculation state: S(t) = (h(t) - h(t-1)) / d(t)
  double _lastAltitude = 0;
  double _lastLatitude = 0;
  double _lastLongitude = 0;
  bool _hasLastAltitude = false;

  // Latest vertical acceleration for pothole detection coordination
  double _lastVerticalAccel = 0;

  double _currentAcceleration = 0;
  double _currentTurnRate = 0;
  DateTime? _lastSensorNotify;

  StreamSubscription<Position>? _positionSub;
  StreamSubscription<UserAccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  Timer? _bufferTimer;
  int _tripHistoryVersion = 0;

  // Completed trips loaded from local database for map display
  List<Trip> _completedTrips = [];
  
  // Community trips fetched from Firestore
  List<Trip> _communityTrips = [];

  Trip? get activeTrip => _activeTrip;
  bool get isTracking => _isTracking;
  double get currentSpeed => _currentSpeed;
  Position? get currentPosition => _currentPosition;
  List<Map<String, double>> get routePoints => List.unmodifiable(_routePoints);

  int get speedingCount => _speedingCount;
  int get brakingCount => _brakingCount;
  int get turningCount => _turningCount;
  int get potholeCount => _potholeCount;
  double get totalSlopeDeviation => _totalSlopeDeviation;
  int get reportSeveritySum => _reportSeveritySum;
  List<RemoteReport> get remoteReports => List.unmodifiable(_remoteReports);
  List<risk_scoring.UnsafeEvent> get recentEvents =>
      List.unmodifiable(_recentEvents);

  double get currentAcceleration => _currentAcceleration;
  double get currentTurnRate => _currentTurnRate;
  double get averageAcceleration => _accelWindow.average;
  int get tripHistoryVersion => _tripHistoryVersion;

  // Context factor getters for UI display
  double get contextRoad => _adaptiveThresholds.contextRoad;
  double get contextEnvNoise => _adaptiveThresholds.contextEnvNoise;
  double get contextTraffic => _adaptiveThresholds.contextTraffic;

  bool _testMode = false;
  bool get testMode => _testMode;

  void setTestMode(bool value) {
    _testMode = value;
    notifyListeners();
  }



  // Completed trip history for map display
  List<Trip> get completedTrips => List.unmodifiable(_completedTrips);
  List<Trip> get communityTrips => List.unmodifiable(_communityTrips);

  /// Load completed trips from the local database for map risk visualization.
  /// Filters to only trips with route data and an end time.
  Future<void> loadCompletedTrips() async {
    final allTrips = await _database.getTrips();
    _completedTrips = allTrips
        .where((t) => t.endTime != null && t.routePoints.isNotEmpty)
        .toList();
        
    if (kIsWeb) {
      _communityTrips = [
        Trip(
          id: 101,
          startTime: DateTime.now().subtract(const Duration(hours: 5)),
          endTime: DateTime.now().subtract(const Duration(hours: 4)),
          startLat: 37.422,
          startLng: -122.084,
          endLat: 37.421,
          endLng: -122.083,
          riskScore: 30, // 70% safety
          routePoints: [
            {'lat': 37.422, 'lng': -122.084},
            {'lat': 37.421, 'lng': -122.083},
            {'lat': 37.422, 'lng': -122.085},
          ],
        ),
        Trip(
          id: 102,
          startTime: DateTime.now().subtract(const Duration(hours: 1)),
          endTime: DateTime.now(),
          startLat: 37.420,
          startLng: -122.088,
          endLat: 37.422,
          endLng: -122.084,
          riskScore: 80, // 20% safety (high risk)
          routePoints: [
            {'lat': 37.420, 'lng': -122.088},
            {'lat': 37.421, 'lng': -122.087},
            {'lat': 37.422, 'lng': -122.084},
          ],
        ),
      ];
      
      // Shift all dummy trips (historical and community) to the user's actual location!
      try {
        final pos = await _locationService.currentPosition();
        final latOffset = pos.latitude - 37.422;
        final lngOffset = pos.longitude - (-122.084);
        
        void shiftTrip(Trip t) {
          for (var p in t.routePoints) {
            p['lat'] = (p['lat'] ?? 0) + latOffset;
            p['lng'] = (p['lng'] ?? 0) + lngOffset;
          }
        }
        
        for (final t in _completedTrips) shiftTrip(t);
        for (final t in _communityTrips) shiftTrip(t);
      } catch (e) {
        debugPrint('Failed to shift dummy trips: $e');
      }
    } else {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          _communityTrips = await _firestoreService.getCommunityTrips(user.uid);
        } catch (e) {
          debugPrint('Failed to load community trips: $e');
        }
      }
    }
    
    notifyListeners();
  }

  /// Compute a live fused safety score (0-100) using current sensor counts
  /// and remote reports (if any). Returns null if not tracking.
  int? get liveSafetyScore {
    if (!_isTracking) return null;

    final weights = risk_scoring.RiskWeights();
    final sensorRisk = risk_scoring.computeSensorRiskScore(
      overspeedingCount: _speedingCount,
      harshBrakingCount: _brakingCount,
      sharpTurningCount: _turningCount,
      potholeCount: _potholeCount,
      totalSlopeDeviation: _totalSlopeDeviation,
      totalWindows: _tripDurationWindows,
      weights: weights,
      contextualAdjustment: _adaptiveThresholds.getContextualAdjustment(),
    );

    final reportRiskReports = _remoteReports
        .map(FirestoreService.toRiskReport)
        .toList();
    final reportRisk = risk_scoring.computeReportRiskScore(reportRiskReports);

    final adaptiveWeight = risk_scoring.computeAdaptiveWeight(
      _tripDurationWindows,
      _remoteReports.length,
    );

    final tripRisk = risk_scoring.computeTripRiskScore(
      sensorRisk: sensorRisk,
      reportRisk: reportRisk,
      adaptiveWeight: adaptiveWeight,
      inconsistencyPenalty: weights.phi,
    );

    final safety = risk_scoring.computeSafetyScore(tripRisk);
    return safety;
  }

  /// Calculates the total number of evaluation windows based on trip duration.
  /// Assuming an average event cooldown/window size of 2 seconds.
  int get _tripDurationWindows {
    if (_activeTrip == null) return 1;
    final duration = DateTime.now().difference(_activeTrip!.startTime);
    return max(1, duration.inSeconds ~/ 2);
  }

  Future<bool> startTrip({
    String? routeName,
    double vehicleMultiplier = 1.0,
  }) async {
    try {
      // Initialize notifications at trip start (network-optional, errors ignored)
      await _notificationService.initialize();
      await _notificationService.subscribeToTopic('critical_incidents');
    } catch (e) {
      debugPrint('TripController: Notification init failed ($e)');
    }

    try {
      // --- 1. Location permission (required — can't track without it) ---
      final hasPermission = await _locationService.ensurePermission();
      if (!hasPermission) {
        debugPrint('TripController: Location permission denied');
        return false;
      }

      // --- 2. Initial GPS fix (best-effort — trip starts even if this fails) ---
      // Without mobile data, A-GPS cold-start may time out. We attempt the fix
      // but proceed regardless so the user is never blocked from recording a trip.
      // The position stream (_listenToSensors) will supply coordinates once
      // satellites lock, usually within 30–60 s outdoors.
      Position? position;
      try {
        position = await _locationService.currentPosition();
      } catch (e) {
        debugPrint('TripController: Initial GPS fix failed ($e). '
            'Starting trip without initial position — stream will fill in.');
      }

      _currentPosition = position;
      _routePoints.clear();
      if (position != null) {
        _routePoints.add({'lat': position.latitude, 'lng': position.longitude});
      }

      // --- 3. Save trip to local SQLite (no internet needed) ---
      final startTime = DateTime.now();
      final tripId = await _database.insertTrip(
        Trip(
          startTime: startTime,
          startLat: position?.latitude,
          startLng: position?.longitude,
          routeName: routeName,
        ),
      );

      _activeTrip = Trip(
        id: tripId,
        startTime: startTime,
        startLat: position?.latitude,
        startLng: position?.longitude,
        routeName: routeName,
        routePoints: List.of(_routePoints),
        syncStatus: SyncStatus.pending,
      );

      _speedingCount = 0;
      _brakingCount = 0;
      _turningCount = 0;
      _potholeCount = 0;
      _totalSlopeDeviation = 0;
      _reportSeveritySum = 0;
      _recentEvents.clear();
      _turningStreak = 0;
      _hasLastAltitude = false;
      _lastVerticalAccel = 0;
      _isTracking = true;

      // Apply baseline vehicle thresholds before starting
      _adaptiveThresholds.vehicleMultiplier = vehicleMultiplier;

      // --- 4. Start sensor + report streams ---
      _listenToSensors();
      if (_activeTrip?.id != null) {
        _subscribeToRemoteReports(_activeTrip!.id!);
      }
      _startBuffering();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('TripController: startTrip failed ($e)');
      return false;
    }
  }

  Future<void> stopTrip() async {
    if (_activeTrip == null) {
      return;
    }

    // Unsubscribe from notification topics
    await _notificationService.unsubscribeFromTopic('critical_incidents');

    await _positionSub?.cancel();
    await _accelSub?.cancel();
    await _gyroSub?.cancel();
    _stopBuffering();

    // Reset notification tracking
    _consecutiveEventsInWindow = 0;
    _lastNotificationTime = null;

    final endPosition = _currentPosition;
    // Compute sensor-based risk (legacy counts -> normalized)
    final weights = risk_scoring.RiskWeights();
    final sensorRisk = risk_scoring.computeSensorRiskScore(
      overspeedingCount: _speedingCount,
      harshBrakingCount: _brakingCount,
      sharpTurningCount: _turningCount,
      potholeCount: _potholeCount,
      totalSlopeDeviation: _totalSlopeDeviation,
      totalWindows: _tripDurationWindows,
      weights: weights,
      contextualAdjustment: _adaptiveThresholds.getContextualAdjustment(),
    );

    // Map remote reports to risk_scoring.PassengerReport and compute report risk
    final reportRiskReports = _remoteReports
        .map((r) => FirestoreService.toRiskReport(r))
        .toList();
    final reportRisk = risk_scoring.computeReportRiskScore(reportRiskReports);

    final adaptiveWeight = risk_scoring.computeAdaptiveWeight(
      _tripDurationWindows,
      _remoteReports.length,
    );

    final tripRisk = risk_scoring.computeTripRiskScore(
      sensorRisk: sensorRisk,
      reportRisk: reportRisk,
      adaptiveWeight: adaptiveWeight,
      inconsistencyPenalty: weights.phi,
    );

    final riskScore = (tripRisk * 100.0);

    final completedTrip = _activeTrip!.copyWith(
      endTime: DateTime.now(),
      endLat: endPosition?.latitude,
      endLng: endPosition?.longitude,
      riskScore: riskScore.toDouble(),
      speedingCount: _speedingCount,
      brakingCount: _brakingCount,
      turningCount: _turningCount,
      routePoints: List.of(_routePoints),
      syncStatus: SyncStatus.pending,
    );

    await _database.updateTrip(completedTrip);

    // Unsubscribe reports listener
    await _remoteReportsSub?.cancel();
    _remoteReportsSub = null;

    _activeTrip = null;
    _isTracking = false;
    _currentSpeed = 0;
    _tripHistoryVersion++;
    // Refresh completed trips so the map shows the new trip immediately
    unawaited(loadCompletedTrips());
    notifyListeners();
  }

  void _subscribeToRemoteReports(int tripId) {
    _remoteReportsSub?.cancel();
    _remoteReportsSub = _firestoreService.reportsStream(tripId: tripId).listen((
      reports,
    ) {
      _remoteReports = reports;
      // Update severity sum to reflect remote reports as well
      _reportSeveritySum = _remoteReports.fold(0, (sum, r) => sum + (r.rating));
      notifyListeners();
    }, onError: (error) {
      debugPrint('Error subscribing to remote reports: $error');
      // Gracefully handle missing index by falling back to empty reports.
      _remoteReports = [];
      _reportSeveritySum = 0;
      notifyListeners();
    });
  }

  Future<void> addReport({
    required String category,
    required int severity,
    String? description,
  }) async {
    final activeTrip = _activeTrip;
    if (activeTrip == null || activeTrip.id == null) {
      return;
    }

    final report = PassengerReport(
      tripId: activeTrip.id!,
      category: category,
      severity: severity,
      description: description,
      createdAt: DateTime.now(),
    );

    await _database.insertReport(report);
    _reportSeveritySum += severity;
    unawaited(_persistActiveTripSnapshot());
    notifyListeners();
  }

  void _listenToSensors() {
    _positionSub = _locationService.positionStream().listen(_onPosition);
    _accelSub = _sensorService.userAccelerometerStream().listen(
      _onUserAccelerometer,
    );
    _gyroSub = _sensorService.gyroscopeStream().listen(_onGyroscope);
  }

  void _onPosition(Position position) {
    _currentPosition = position;
    _currentSpeed = max(position.speed, 0);
    _speedWindow.add(_currentSpeed);
    final avgSpeedKmh = _speedWindow.average * 3.6;
    _routePoints.add({'lat': position.latitude, 'lng': position.longitude});
    if (_routePoints.length > 200) {
      _routePoints.removeAt(0);
    }

    if (_routePoints.length % 5 == 0) {
      unawaited(_persistActiveTripSnapshot());
    }

    // Detect overspeeding using adaptive threshold
    if (risk_scoring.detectOverspeeding(avgSpeedKmh, _adaptiveThresholds)) {
      if (_cooldownElapsed(_lastSpeedEvent)) {
        _speedingCount++;
        _lastSpeedEvent = DateTime.now();
        _recordEvent(risk_scoring.UnsafeEventType.speeding);
      }
    }

    // Detect harsh braking using speed variation: Δv(k) = ṽ(k) - ṽ(k-1)
    // Formula: E_b(w) = 1 if Δv(k) < -θ_b
    final speedDelta = _currentSpeed - _lastRecordedSpeed;
    if (risk_scoring.detectHarshBraking(speedDelta, _adaptiveThresholds) &&
        (_testMode || _currentSpeed > _adaptiveThresholds.thetaSpeedMin)) {
      if (_cooldownElapsed(_lastBrakeEvent)) {
        _brakingCount++;
        _lastBrakeEvent = DateTime.now();
        _recordEvent(risk_scoring.UnsafeEventType.braking);
      }
    }

    // Slope calculation: S(t) = (h(t) - h(t-1)) / d(t)
    // Uses GPS altitude data for environmental hazard detection
    final currentAltitude = position.altitude;
    if (_hasLastAltitude) {
      final distance = _haversineDistance(
        _lastLatitude,
        _lastLongitude,
        position.latitude,
        position.longitude,
      );
      if (distance > 1.0) {
        // Only compute slope if moved at least 1 meter
        final slope = risk_scoring.computeSlope(
          currentAltitude: currentAltitude,
          previousAltitude: _lastAltitude,
          distanceTraveled: distance,
        );
        _totalSlopeDeviation += slope.abs();
      }
    }
    _lastAltitude = currentAltitude;
    _lastLatitude = position.latitude;
    _lastLongitude = position.longitude;
    _hasLastAltitude = true;

    _lastRecordedSpeed = _currentSpeed;
    notifyListeners();
  }

  void _onUserAccelerometer(UserAccelerometerEvent event) {
    // Calculate acceleration magnitude: a(k) = √(ax² + ay² + az²)
    final magnitude = sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );
    _currentAcceleration = magnitude;
    _accelWindow.add(magnitude);

    // Store vertical acceleration for pothole detection
    // az(k) is the Z-axis component (vertical)
    _lastVerticalAccel = event.z.abs();

    // Pothole detection: P(k) = 1 if az(k) > θ_p ∧ g(k) < θ_g ∧ v(k) > θ_v
    // Combines vertical acceleration spike with low gyro (not a turn) and moving
    if (_testMode || _currentSpeed > _adaptiveThresholds.thetaSpeedMin) {
      final isPothole = risk_scoring.detectPothole(
        verticalAccel: _lastVerticalAccel,
        gyroMagnitude: _gyroWindow.average,
        speed: _testMode ? 10.0 : _currentSpeed, // Mock speed if in test mode so pothole formula passes
        thresholds: _adaptiveThresholds,
      );
      if (isPothole && _cooldownElapsed(_lastPotholeEvent)) {
        _potholeCount++;
        _lastPotholeEvent = DateTime.now();
      }
    }

    // Note: Braking detection is now based on speed variation (Δv) from GPS
    // which is calculated in _onPosition using _speedWindow

    final now = DateTime.now();
    if (_lastSensorNotify == null ||
        now.difference(_lastSensorNotify!).inMilliseconds > 250) {
      _lastSensorNotify = now;
      notifyListeners();
    }
  }

  void _onGyroscope(GyroscopeEvent event) {
    // Calculate gyroscope magnitude: g(k) = √(gx² + gy² + gz²)
    final gyroMagnitude = risk_scoring.computeGyroMagnitude(
      event.x,
      event.y,
      event.z,
    );
    _currentTurnRate = gyroMagnitude;
    _gyroWindow.add(gyroMagnitude);

    // Detect sharp turning using adaptive threshold and full gyro magnitude
    // Requires: (1) sufficient vehicle speed, (2) high gyro, (3) sustained duration
    final maxGyro = _gyroWindow.max;
    final isMoving = _testMode || _currentSpeed >= 3.0; // ~11 km/h minimum to avoid stationary false positives
    if (isMoving && risk_scoring.detectSharpTurning(maxGyro, _adaptiveThresholds)) {
      _turningStreak++;
      if (_turningCooldownElapsed(_lastTurnEvent)) {
        if (_turningStreak >= 10) {
          // Require sustained turn (10 samples min) to filter out bumps/phone jitter
          _turningCount++;
          _lastTurnEvent = DateTime.now();
          _recordEvent(risk_scoring.UnsafeEventType.turning);
          notifyListeners();
          _turningStreak = 0;
        }
      }
    } else {
      _turningStreak = 0;
    }

    final now = DateTime.now();
    if (_lastSensorNotify == null ||
        now.difference(_lastSensorNotify!).inMilliseconds > 250) {
      _lastSensorNotify = now;
      notifyListeners();
    }
  }

  void _recordEvent(risk_scoring.UnsafeEventType type) {
    _recentEvents.insert(
      0,
      risk_scoring.UnsafeEvent(type: type, timestamp: DateTime.now()),
    );
    if (_recentEvents.length > 5) {
      _recentEvents.removeLast();
    }

    // Track consecutive events for criticality detection
    _consecutiveEventsInWindow++;

    // Check if we should send a notification (with throttling)
    _checkAndSendCriticalNotification();
  }

  void _checkAndSendCriticalNotification() {
    // Throttle notifications: max one every 10 seconds
    if (_lastNotificationTime != null &&
        DateTime.now().difference(_lastNotificationTime!).inSeconds < 10) {
      return;
    }

    // Get current safety score
    final currentScore = liveSafetyScore;
    if (currentScore == null) return;

    final riskScore = 1.0 - (currentScore / 100.0);

    // Determine criticality
    final criticality = determineCriticality(
      consecutiveEvents: _consecutiveEventsInWindow,
      riskScore: riskScore,
      reportSeveritySum: _reportSeveritySum,
    );

    // Only send notifications for medium and above
    if (criticality.index < IncidentCriticality.medium.index) {
      return;
    }

    _lastNotificationTime = DateTime.now();
    _sendCriticalIncidentNotification(criticality);

    // Reset counter after sending notification
    _consecutiveEventsInWindow = 0;
  }

  void _sendCriticalIncidentNotification(IncidentCriticality criticality) {
    final incidentType = _getIncidentTypeString();
    final title = getNotificationTitle(incidentType);
    final currentScore = liveSafetyScore;
    final body = getNotificationBody(
      incidentType,
      criticality,
      consecutiveEvents: _consecutiveEventsInWindow,
      riskScore: currentScore != null ? 1.0 - (currentScore / 100.0) : 0.5,
    );

    debugPrint('CRITICAL NOTIFICATION: [$criticality] $title - $body');

    // Log notification data
    final notificationData = CriticalIncidentNotification(
      incidentType: incidentType,
      severity: 1.0 - (currentScore ?? 50) / 100.0,
      message: body,
      timestamp: DateTime.now(),
      latitude: _currentPosition?.latitude,
      longitude: _currentPosition?.longitude,
    );

    debugPrint('Incident Data: ${notificationData.toMap()}');
  }

  String _getIncidentTypeString() {
    if (_consecutiveEventsInWindow >= 3) {
      return 'rapid_sequence';
    }
    if (_reportSeveritySum > 15) {
      return 'high_report_severity';
    }
    if (_speedingCount > 2) {
      return 'speeding';
    }
    if (_brakingCount > 2) {
      return 'harsh_braking';
    }
    if (_turningCount > 2) {
      return 'sharp_turn';
    }
    return 'unsafe_event';
  }

  bool _cooldownElapsed(DateTime? lastEvent) {
    if (lastEvent == null) {
      return true;
    }
    return DateTime.now().difference(lastEvent) > const Duration(seconds: 2);
  }

  /// Longer cooldown specifically for turning events to reduce false positives
  bool _turningCooldownElapsed(DateTime? lastEvent) {
    if (lastEvent == null) {
      return true;
    }
    return DateTime.now().difference(lastEvent) > const Duration(seconds: 5);
  }

  /// Update adaptive threshold context factors: θ(t) = θ_base(v) × (1 + α·R_c(t)) × (1 + β·T_d(t)) × (1 + γ·E_n(t))
  /// Called from settings UI to adjust detection sensitivity based on conditions.
  void updateContextFactors({
    required double roadCondition, // R_c(t): 0.0 (poor) to 1.0 (good)
    required double envNoise, // E_n(t): 0.0 (low) to 1.0 (high)
    required double trafficDensity, // T_d(t): 0.0 (light) to 1.0 (heavy)
  }) {
    _adaptiveThresholds.updateContextFactors(
      roadCondition: roadCondition,
      envNoise: envNoise,
      trafficDensity: trafficDensity,
    );
    notifyListeners();
  }

  /// Haversine distance between two GPS coordinates in meters
  /// Used for slope calculation: d(t) in S(t) = (h(t) - h(t-1)) / d(t)
  double _haversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusM = 6371000.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusM * c;
  }

  double _toRad(double degrees) => degrees * pi / 180.0;

  void _startBuffering() {
    _stopBuffering();
    _bufferTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      unawaited(_persistActiveTripSnapshot());
    });
  }

  void _stopBuffering() {
    _bufferTimer?.cancel();
    _bufferTimer = null;
  }

  Future<void> _persistActiveTripSnapshot() async {
    final activeTrip = _activeTrip;
    if (!_isTracking || activeTrip == null || activeTrip.id == null) {
      return;
    }

    final bufferedTrip = activeTrip.copyWith(
      endLat: _currentPosition?.latitude,
      endLng: _currentPosition?.longitude,
      speedingCount: _speedingCount,
      brakingCount: _brakingCount,
      turningCount: _turningCount,
      routePoints: List.of(_routePoints),
      syncStatus: SyncStatus.pending,
    );

    await _database.updateTrip(bufferedTrip);
    _activeTrip = bufferedTrip;
  }

  @override
  void dispose() {
    _stopBuffering();
    _positionSub?.cancel();
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _remoteReportsSub?.cancel();
    super.dispose();
  }
}

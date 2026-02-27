import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../data/app_database.dart';
import '../models/report.dart';
import '../models/sync_status.dart';
import '../models/trip.dart';
import '../services/location_service.dart';
import '../services/risk_scoring.dart';
import '../services/sensor_service.dart';

class TripController extends ChangeNotifier {
  TripController({
    required AppDatabase database,
    LocationService? locationService,
    SensorService? sensorService,
  }) : _database = database,
       _locationService = locationService ?? LocationService(),
       _sensorService = sensorService ?? SensorService();

  final AppDatabase _database;
  final LocationService _locationService;
  final SensorService _sensorService;

  Trip? _activeTrip;
  bool _isTracking = false;
  double _currentSpeed = 0;
  Position? _currentPosition;
  final List<Map<String, double>> _routePoints = [];

  int _speedingCount = 0;
  int _brakingCount = 0;
  int _turningCount = 0;
  int _reportSeveritySum = 0;

  final SlidingWindow _accelWindow = SlidingWindow(size: 15);
  final List<UnsafeEvent> _recentEvents = [];
  DateTime? _lastBrakeEvent;
  DateTime? _lastTurnEvent;
  DateTime? _lastSpeedEvent;

  double _currentAcceleration = 0;
  double _currentTurnRate = 0;

  StreamSubscription<Position>? _positionSub;
  StreamSubscription<UserAccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  Timer? _bufferTimer;
  int _tripHistoryVersion = 0;

  Trip? get activeTrip => _activeTrip;
  bool get isTracking => _isTracking;
  double get currentSpeed => _currentSpeed;
  Position? get currentPosition => _currentPosition;
  List<Map<String, double>> get routePoints => List.unmodifiable(_routePoints);

  int get speedingCount => _speedingCount;
  int get brakingCount => _brakingCount;
  int get turningCount => _turningCount;
  int get reportSeveritySum => _reportSeveritySum;
  List<UnsafeEvent> get recentEvents => List.unmodifiable(_recentEvents);

  double get currentAcceleration => _currentAcceleration;
  double get currentTurnRate => _currentTurnRate;
  double get averageAcceleration => _accelWindow.average;
  int get tripHistoryVersion => _tripHistoryVersion;

  Future<bool> startTrip({String? routeName}) async {
    final hasPermission = await _locationService.ensurePermission();
    if (!hasPermission) {
      return false;
    }

    final position = await _locationService.currentPosition();
    _currentPosition = position;
    _routePoints.clear();
    _routePoints.add({'lat': position.latitude, 'lng': position.longitude});

    final startTime = DateTime.now();
    final tripId = await _database.insertTrip(
      Trip(
        startTime: startTime,
        startLat: position.latitude,
        startLng: position.longitude,
        routeName: routeName,
      ),
    );

    _activeTrip = Trip(
      id: tripId,
      startTime: startTime,
      startLat: position.latitude,
      startLng: position.longitude,
      routeName: routeName,
      routePoints: List.of(_routePoints),
      syncStatus: SyncStatus.pending,
    );

    _speedingCount = 0;
    _brakingCount = 0;
    _turningCount = 0;
    _reportSeveritySum = 0;
    _recentEvents.clear();
    _isTracking = true;

    _listenToSensors();
    _startBuffering();
    notifyListeners();
    return true;
  }

  Future<void> stopTrip() async {
    if (_activeTrip == null) {
      return;
    }

    await _positionSub?.cancel();
    await _accelSub?.cancel();
    await _gyroSub?.cancel();
    _stopBuffering();

    final endPosition = _currentPosition;
    final riskScore = computeRiskScore(
      speedingCount: _speedingCount,
      brakingCount: _brakingCount,
      turningCount: _turningCount,
      reportSeveritySum: _reportSeveritySum,
    );

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

    _activeTrip = null;
    _isTracking = false;
    _currentSpeed = 0;
    _tripHistoryVersion++;
    notifyListeners();
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
    _routePoints.add({'lat': position.latitude, 'lng': position.longitude});
    if (_routePoints.length > 200) {
      _routePoints.removeAt(0);
    }

    if (_routePoints.length % 5 == 0) {
      unawaited(_persistActiveTripSnapshot());
    }

    if (_currentSpeed > 20) {
      if (_cooldownElapsed(_lastSpeedEvent)) {
        _speedingCount++;
        _lastSpeedEvent = DateTime.now();
        _recordEvent(UnsafeEventType.speeding);
      }
    }

    notifyListeners();
  }

  void _onUserAccelerometer(UserAccelerometerEvent event) {
    final magnitude = sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );
    _currentAcceleration = magnitude;
    _accelWindow.add(magnitude);

    if (_accelWindow.max > 3.5 && _currentSpeed > 5) {
      if (_cooldownElapsed(_lastBrakeEvent)) {
        _brakingCount++;
        _lastBrakeEvent = DateTime.now();
        _recordEvent(UnsafeEventType.braking);
        notifyListeners();
      }
    }
  }

  void _onGyroscope(GyroscopeEvent event) {
    final turnRate = event.z.abs();
    _currentTurnRate = turnRate;

    if (turnRate > 2.5) {
      if (_cooldownElapsed(_lastTurnEvent)) {
        _turningCount++;
        _lastTurnEvent = DateTime.now();
        _recordEvent(UnsafeEventType.turning);
        notifyListeners();
      }
    }
  }

  void _recordEvent(UnsafeEventType type) {
    _recentEvents.insert(0, UnsafeEvent(type: type, timestamp: DateTime.now()));
    if (_recentEvents.length > 5) {
      _recentEvents.removeLast();
    }
  }

  bool _cooldownElapsed(DateTime? lastEvent) {
    if (lastEvent == null) {
      return true;
    }
    return DateTime.now().difference(lastEvent) > const Duration(seconds: 2);
  }

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
    super.dispose();
  }
}

enum UnsafeEventType { speeding, braking, turning }

class UnsafeEvent {
  const UnsafeEvent({required this.type, required this.timestamp});

  final UnsafeEventType type;
  final DateTime timestamp;
}

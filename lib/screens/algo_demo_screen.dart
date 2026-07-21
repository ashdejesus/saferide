// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../services/risk_scoring.dart' as rs;
import '../services/trust_scoring_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AlgoDemoScreen — Live Algorithm Demonstration
// Settings ▸ Developer & Testing ▸ Live Algorithm Demo
// ─────────────────────────────────────────────────────────────────────────────

class AlgoDemoScreen extends StatefulWidget {
  const AlgoDemoScreen({super.key});

  @override
  State<AlgoDemoScreen> createState() => _AlgoDemoScreenState();
}

class _AlgoDemoScreenState extends State<AlgoDemoScreen>
    with SingleTickerProviderStateMixin {

  // ── Sensor streams ────────────────────────────────────────────────────────
  StreamSubscription<UserAccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;

  // ── Raw sensor values ─────────────────────────────────────────────────────
  double _ax = 0, _ay = 0, _az = 9.81;
  double _gx = 0, _gy = 0, _gz = 0;
  double _accelMag = 9.81;
  double _gyroMag  = 0;

  // ── Sliding windows ───────────────────────────────────────────────────────
  final rs.SlidingWindow _accelWindow = rs.SlidingWindow(size: 10);
  final rs.SlidingWindow _gyroWindow  = rs.SlidingWindow(size: 10);

  // ── Adaptive thresholds ───────────────────────────────────────────────────
  final rs.AdaptiveThresholds _thresholds = rs.AdaptiveThresholds();

  // ── Simulated speed ───────────────────────────────────────────────────────
  double _simulatedSpeedKmh = 0;
  double _lastSpeed = 0;

  // ── Event counters ────────────────────────────────────────────────────────
  int _overspeedCount = 0, _brakingCount = 0,
      _turningCount  = 0, _potholeCount  = 0,
      _totalWindows  = 0, _turningStreak = 0;

  DateTime? _lastBrake, _lastTurn, _lastPothole;

  // ── Slope inputs ──────────────────────────────────────────────────────────
  double _altitudePrev = 50.0;
  double _altitudeCurr = 70.0;
  double _distanceTraveled = 200.0;
  final double _totalSlopeDeviation = 0.05;
  double get _slope => rs.computeSlope(
    currentAltitude: _altitudeCurr,
    previousAltitude: _altitudePrev,
    distanceTraveled: _distanceTraveled,
  );

  // ── Report inputs ─────────────────────────────────────────────────────────
  double _report1Rating = 3.0, _report1Trust = 0.8;
  double _report2Rating = 2.0, _report2Trust = 0.6;

  // ── Trust inputs ──────────────────────────────────────────────────────────
  final List<int> _historicalSeverities = [3, 3, 2, 3, 4];
  int _currentSeverity = 3;
  double _totalReportsN = 10;

  // ── Tab ───────────────────────────────────────────────────────────────────
  late final TabController _tab;
  Timer? _windowTimer;

  // ─────────────────────────────────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _startSensors();
    _windowTimer = Timer.periodic(
      const Duration(seconds: 1), (_) { if (mounted) setState(() => _totalWindows++); });
  }

  void _startSensors() {
    _accelSub = userAccelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 100),
    ).listen((e) {
      if (!mounted) return;
      setState(() {
        _ax = e.x; _ay = e.y; _az = e.z;
        _accelMag = rs.computeAccelerationMagnitude(_ax, _ay, _az);
        _accelWindow.add(_accelMag);
        _processPothole();
      });
    });

    _gyroSub = gyroscopeEventStream(
      samplingPeriod: const Duration(milliseconds: 100),
    ).listen((e) {
      if (!mounted) return;
      setState(() {
        _gx = e.x; _gy = e.y; _gz = e.z;
        _gyroMag = rs.computeGyroMagnitude(_gx, _gy, _gz);
        _gyroWindow.add(_gyroMag);
        _processTurning();
      });
    });
  }

  bool _cd(DateTime? t, [int s = 2]) =>
      t == null || DateTime.now().difference(t).inSeconds >= s;

  void _processPothole() {
    if (rs.detectPothole(
          verticalAccel: _az.abs(),
          gyroMagnitude: _gyroWindow.average,
          speed: max(_simulatedSpeedKmh, 10.0),
          thresholds: _thresholds) &&
        _cd(_lastPothole, 3)) {
      _potholeCount++;
      _lastPothole = DateTime.now();
    }
  }

  void _processTurning() {
    if (rs.detectSharpTurning(_gyroWindow.max, _thresholds)) {
      _turningStreak++;
      if (_turningStreak >= 5 && _cd(_lastTurn, 5)) {
        _turningCount++;
        _lastTurn = DateTime.now();
        _turningStreak = 0;
      }
    } else {
      _turningStreak = 0;
    }
  }

  void _processSpeedEvents(double v) {
    if (rs.detectOverspeeding(v, _thresholds) && _cd(_lastBrake)) {
      _overspeedCount++;
    }
    final delta = v - _lastSpeed;
    if (rs.detectHarshBraking(delta, _thresholds) && _cd(_lastBrake)) {
      _brakingCount++;
      _lastBrake = DateTime.now();
    }
    _lastSpeed = v;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Derived getters
  // ─────────────────────────────────────────────────────────────────────────

  double get _filteredAccel => _accelWindow.average;
  double get _filteredGyro  => _gyroWindow.average;

  bool get _potholeNow => rs.detectPothole(
    verticalAccel: _az.abs(),
    gyroMagnitude: _gyroWindow.average,
    speed: max(_simulatedSpeedKmh, 10.0),
    thresholds: _thresholds,
  );
  bool get _overspeedNow =>
      rs.detectOverspeeding(_simulatedSpeedKmh, _thresholds);
  bool get _turningNow =>
      rs.detectSharpTurning(_gyroWindow.max, _thresholds);

  double get _sensorRisk {
    final w = rs.RiskWeights();
    return rs.computeSensorRiskScore(
      overspeedingCount: _overspeedCount, harshBrakingCount: _brakingCount,
      sharpTurningCount: _turningCount,  potholeCount:       _potholeCount,
      totalSlopeDeviation: _totalSlopeDeviation,
      totalWindows: max(1, _totalWindows), weights: w,
      contextualAdjustment: _thresholds.getContextualAdjustment(),
    );
  }

  double get _reportRisk {
    final now = DateTime.now();
    return rs.computeReportRiskScore([
      rs.PassengerReport(riskRating: _report1Rating.round(), trust: _report1Trust, timestamp: now),
      rs.PassengerReport(riskRating: _report2Rating.round(), trust: _report2Trust, timestamp: now),
    ]);
  }

  double get _lambda  => rs.computeAdaptiveWeight(_totalWindows, 2);
  double get _tripRisk => rs.computeTripRiskScore(
    sensorRisk: _sensorRisk, reportRisk: _reportRisk,
    adaptiveWeight: _lambda, inconsistencyPenalty: rs.RiskWeights().phi,
  );
  int    get _safetyScore => rs.computeSafetyScore(_tripRisk);

  double get _freqScore =>
      TrustScoringService.calculateFrequencyScore(totalReports: _totalReportsN.round());
  double get _consistScore =>
      TrustScoringService.calculateConsistencyScore(
        historicalSeverities: _historicalSeverities, currentSeverity: _currentSeverity);
  double get _anomalyScore =>
      TrustScoringService.calculateAnomalyScore(
        historicalSeverities: _historicalSeverities, currentSeverity: _currentSeverity);
  double get _alignScore =>
      TrustScoringService.calculateSensorAlignmentScore(
        reportSeverity: _currentSeverity,
        detectedEventCount: _potholeCount + _overspeedCount,
        averageSensorRisk: _sensorRisk);
  double get _overallTrust =>
      TrustScoringService.calculateOverallTrust(
        consistencyScore: _consistScore, anomalyScore: _anomalyScore,
        sensorAlignmentScore: _alignScore, totalReports: _totalReportsN.round());

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.science, size: 18, color: cs.onPrimaryContainer),
          ),
          const SizedBox(width: 10),
          const Text('Algorithm Demo'),
        ]),
        bottom: TabBar(
          controller: _tab,
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          indicator: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          labelColor: cs.onPrimaryContainer,
          unselectedLabelColor: cs.onSurfaceVariant,
          tabs: const [
            Tab(icon: Icon(Icons.sensors, size: 18),      text: 'Sensors'),
            Tab(icon: Icon(Icons.calculate, size: 18),    text: 'Risk Score'),
            Tab(icon: Icon(Icons.verified_user, size: 18),text: 'Trust Score'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reset event counters',
            onPressed: () => setState(() {
              _overspeedCount = 0; _brakingCount = 0;
              _turningCount = 0;   _potholeCount = 0;
              _totalWindows = 0;   _turningStreak = 0;
              _lastBrake = null;   _lastTurn = null;
              _lastPothole = null; _lastSpeed = 0;
            }),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _buildSensorTab(cs),
          _buildRiskTab(cs),
          _buildTrustTab(cs),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 1 — Sensors
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSensorTab(ColorScheme cs) {
    final String statusMsg;
    if (_potholeNow) {
      statusMsg = '🕳️  Possible pothole detected right now!';
    } else if (_turningNow) {
      statusMsg = '↩️  Sharp turn detected!';
    } else if (_overspeedNow) {
      statusMsg = '⚠️  Overspeeding!';
    } else {
      statusMsg = '✅  Phone is still — move it to see the sensors react';
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Status banner
        _StatusBanner(message: statusMsg, cs: cs,
            active: _potholeNow || _turningNow || _overspeedNow),
        const SizedBox(height: 20),

        // Speed slider
        _GroupHeader('🚗  Simulate Vehicle Speed', cs: cs,
            subtitle: 'No GPS needed — drag the slider to set the speed for this demo'),
        const SizedBox(height: 12),
        _SpeedSliderCard(
          speed: _simulatedSpeedKmh,
          threshold: _thresholds.thetaSpeedingBase,
          cs: cs,
          onChanged: (v) => setState(() { _processSpeedEvents(v); _simulatedSpeedKmh = v; }),
        ),
        const SizedBox(height: 24),

        // Raw readings
        _GroupHeader('📡  Raw Sensor Readings', cs: cs,
            subtitle: 'What the phone\'s accelerometer & gyroscope measure every 0.1 second'),
        const SizedBox(height: 12),
        _SensorGridCard(ax: _ax, ay: _ay, az: _az, gx: _gx, gy: _gy, gz: _gz, cs: cs),
        const SizedBox(height: 24),

        // Magnitudes
        _GroupHeader('🔢  Step 1 — Compute Magnitudes', cs: cs,
            subtitle: 'Combine all 3 axes into a single number using the Pythagorean theorem'),
        const SizedBox(height: 12),
        _FormulaCard(
          cs: cs, icon: Icons.straighten,
          color: cs.primary,
          formulaTitle: 'Acceleration Magnitude',
          formula: 'a(k) = √( ax² + ay² + az² )',
          explanation: '💡 Collapses the three accelerometer axes into one number that tells us the total physical force on the phone — like how hard the vehicle is shaking.',
          substituted: 'a(k) = √( ${_ax.toStringAsFixed(2)}² + ${_ay.toStringAsFixed(2)}² + ${_az.toStringAsFixed(2)}² )',
          result: '${_accelMag.toStringAsFixed(3)} m/s²',
          fraction: (_accelMag / 15).clamp(0, 1),
        ),
        const SizedBox(height: 12),
        _FormulaCard(
          cs: cs, icon: Icons.rotate_right,
          color: const Color(0xFF7C3AED),
          formulaTitle: 'Gyroscope Magnitude',
          formula: 'g(k) = √( gx² + gy² + gz² )',
          explanation: '💡 Combines all rotation axes into one number representing how fast the phone is spinning — large values mean the vehicle is turning sharply.',
          substituted: 'g(k) = √( ${_gx.toStringAsFixed(2)}² + ${_gy.toStringAsFixed(2)}² + ${_gz.toStringAsFixed(2)}² )',
          result: '${_gyroMag.toStringAsFixed(3)} rad/s',
          fraction: (_gyroMag / 10).clamp(0, 1),
        ),
        const SizedBox(height: 24),

        // Moving average
        _GroupHeader('🌊  Step 2 — Smooth the Readings', cs: cs,
            subtitle: 'A moving average filter removes random noise from the sensor signal'),
        const SizedBox(height: 12),
        _FormulaCard(
          cs: cs, icon: Icons.waves,
          color: const Color(0xFF0891B2),
          formulaTitle: 'Moving Average Filter  (window M = 10)',
          formula: 'x̃(k) = ( 1 / M ) · Σ x(k−i),   i = 0 … M−1',
          explanation: '💡 Instead of reacting to every single noisy reading, the system averages the last 10 readings. This prevents false alarms from bumps like speed bumps or potholes on a normal road.',
          substituted: 'Filtered accel: ${_filteredAccel.toStringAsFixed(3)} m/s²   ·   Filtered gyro: ${_filteredGyro.toStringAsFixed(3)} rad/s',
          result: 'Raw ${_accelMag.toStringAsFixed(2)} → Smoothed ${_filteredAccel.toStringAsFixed(2)} m/s²',
          fraction: (_filteredAccel / 15).clamp(0, 1),
        ),
        const SizedBox(height: 24),

        // Pothole
        _GroupHeader('🕳️  Step 3A — Pothole Detection', cs: cs,
            subtitle: 'Shake the phone upward to simulate hitting a pothole'),
        const SizedBox(height: 12),
        _PotholeCard(
          az: _az.abs(), gyroMag: _gyroWindow.average,
          speed: max(_simulatedSpeedKmh, 10.0),
          thresholds: _thresholds, detected: _potholeNow,
          count: _potholeCount, cs: cs,
        ),
        const SizedBox(height: 24),

        // Slope
        _GroupHeader('📐  Step 3B — Road Slope', cs: cs,
            subtitle: 'Measures how steep the road is (e.g. Antipolo zigzag roads)'),
        const SizedBox(height: 12),
        _SlopeCard(
          altitudePrev: _altitudePrev, altitudeCurr: _altitudeCurr,
          distanceTraveled: _distanceTraveled, slope: _slope, cs: cs,
          onAltPrev: (v) => setState(() => _altitudePrev = v),
          onAltCurr: (v) => setState(() => _altitudeCurr = v),
          onDist:    (v) => setState(() => _distanceTraveled = v),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 2 — Risk Score
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildRiskTab(ColorScheme cs) {
    final weights   = rs.RiskWeights();
    final theta     = _thresholds.getAdaptiveThreshold(_thresholds.thetaSpeedingBase);
    final contextAdj = _thresholds.getContextualAdjustment();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Pipeline overview
        _PipelineFlow(cs: cs),
        const SizedBox(height: 20),

        // Current safety score banner
        _ScoreBanner(score: _safetyScore, label: 'Current Safety Score', cs: cs),
        const SizedBox(height: 24),

        // Event detection
        _GroupHeader('⚡  Step 1 — Detect Unsafe Events', cs: cs,
            subtitle: 'The system checks 3 types of dangerous driving every second'),
        const SizedBox(height: 12),
        _EventFlagsCard(
          overspeed: _overspeedNow, sharpTurn: _turningNow,
          speed: _simulatedSpeedKmh, gyroMax: _gyroWindow.max,
          threshold: _thresholds,
          counts: (_overspeedCount, _brakingCount, _turningCount),
          cs: cs,
        ),
        const SizedBox(height: 24),

        // Adaptive threshold
        _GroupHeader('🎯  Step 2 — Adjust for Road Conditions', cs: cs,
            subtitle: 'Thresholds adapt to traffic and road quality — not every road is the same'),
        const SizedBox(height: 12),
        _ContextSlidersCard(thresholds: _thresholds, onChanged: () => setState(() {}), cs: cs),
        const SizedBox(height: 12),
        _FormulaCard(
          cs: cs, icon: Icons.tune,
          color: const Color(0xFFD97706),
          formulaTitle: 'Adaptive Threshold Formula',
          formula: 'θ(t) = θ_base × (1 + α·Rc) × (1 + β·Td) × (1 + γ·En)',
          explanation: '💡 On EDSA with heavy traffic (Td=1.0), the speed threshold rises automatically — because slow-and-stop traffic is normal, not dangerous. The formula prevents false positives caused by road context.',
          substituted: 'θ(t) = ${_thresholds.thetaSpeedingBase.toStringAsFixed(0)} × '
              '(1+${_thresholds.alpha}·${_thresholds.contextRoad.toStringAsFixed(1)}) × '
              '(1+${_thresholds.beta}·${_thresholds.contextTraffic.toStringAsFixed(1)}) × '
              '(1+${_thresholds.gamma}·${_thresholds.contextEnvNoise.toStringAsFixed(1)})\n'
              'A(t) = 1 + α·Rc + β·Td + γ·En  =  ${contextAdj.toStringAsFixed(3)}',
          result: 'Speed threshold: ${theta.toStringAsFixed(2)} km/h   ·   Context factor A(t) = ${contextAdj.toStringAsFixed(3)}',
          fraction: (theta / 80).clamp(0, 1),
        ),
        const SizedBox(height: 24),

        // Sensor risk
        _GroupHeader('📊  Step 3 — Sensor Risk Score  (R_sens)', cs: cs,
            subtitle: 'How risky was the trip based only on sensor data?'),
        const SizedBox(height: 12),
        _FormulaCard(
          cs: cs, icon: Icons.bar_chart,
          color: const Color(0xFFDC2626),
          formulaTitle: 'Sensor Risk Score',
          formula: 'R_sens = ( w1·Cv + w2·Cb + w3·Cg + w4·P + w5·|S| ) / W  ×  A(t)',
          explanation: '💡 Each type of unsafe event has a weight (w1–w5). Harsh braking (w2=0.30) is weighted highest because it is the strongest predictor of accidents. The result is divided by total windows to normalize across trip length.',
          substituted:
              '( ${weights.w1.toStringAsFixed(2)}·$_overspeedCount'
              ' + ${weights.w2.toStringAsFixed(2)}·$_brakingCount'
              ' + ${weights.w3.toStringAsFixed(2)}·$_turningCount'
              ' + ${weights.w4.toStringAsFixed(2)}·$_potholeCount'
              ' + ${weights.w5.toStringAsFixed(2)}·${_totalSlopeDeviation.toStringAsFixed(2)} )'
              ' / ${max(1, _totalWindows)}  ×  ${contextAdj.toStringAsFixed(2)}',
          result: 'R_sens = ${_sensorRisk.toStringAsFixed(4)}  (0 = safest, 1 = riskiest)',
          fraction: _sensorRisk, highlight: true,
        ),
        const SizedBox(height: 24),

        // Report risk
        _GroupHeader('👤  Step 4 — Passenger Report Score  (R_rep)', cs: cs,
            subtitle: 'What do passengers think about this ride? Adjust the sliders below'),
        const SizedBox(height: 12),
        _ReportInputsCard(
          report1Rating: _report1Rating, report1Trust: _report1Trust,
          report2Rating: _report2Rating, report2Trust: _report2Trust, cs: cs,
          onChanged: (r1r, r1t, r2r, r2t) => setState(() {
            _report1Rating = r1r; _report1Trust = r1t;
            _report2Rating = r2r; _report2Trust = r2t;
          }),
        ),
        const SizedBox(height: 12),
        _FormulaCard(
          cs: cs, icon: Icons.people,
          color: const Color(0xFF059669),
          formulaTitle: 'Report Risk Score  (trust-weighted average)',
          formula: 'R_rep = Σ( Ti · ri ) / Σ( Ti )',
          explanation: '💡 Not all passenger reports are equal. A highly-trusted passenger (T=0.9) who rates the ride as dangerous (r=5) has more influence than a new, low-trust passenger (T=0.2) rating the same. This prevents spam or malicious reports from distorting the score.',
          substituted:
              '( ${_report1Trust.toStringAsFixed(1)}·${((_report1Rating-1)/4).toStringAsFixed(2)}'
              ' + ${_report2Trust.toStringAsFixed(1)}·${((_report2Rating-1)/4).toStringAsFixed(2)} ) / '
              '( ${_report1Trust.toStringAsFixed(1)} + ${_report2Trust.toStringAsFixed(1)} )',
          result: 'R_rep = ${_reportRisk.toStringAsFixed(4)}  (0 = safest, 1 = riskiest)',
          fraction: _reportRisk, highlight: true,
        ),
        const SizedBox(height: 24),

        // Lambda
        _GroupHeader('⚖️  Step 5 — Adaptive Weight  λ(t)', cs: cs,
            subtitle: 'How much should we trust sensors vs passenger reports?'),
        const SizedBox(height: 12),
        _FormulaCard(
          cs: cs, icon: Icons.balance,
          color: const Color(0xFF7C3AED),
          formulaTitle: 'Adaptive Weight',
          formula: 'λ(t) = N_sensor / ( N_sensor + N_report )',
          explanation: '💡 Early in the trip, there are many sensor readings but few passenger reports, so sensors dominate (λ → 1). As passengers submit more reports, their data gains more influence. The balance is always automatic.',
          substituted: 'λ(t) = $_totalWindows / ( $_totalWindows + 2 )',
          result: 'λ = ${_lambda.toStringAsFixed(4)}   → Sensors: ${(_lambda*100).toStringAsFixed(0)}%   Reports: ${((1-_lambda)*100).toStringAsFixed(0)}%',
          fraction: _lambda,
        ),
        const SizedBox(height: 24),

        // Trip risk fusion
        _GroupHeader('🔀  Step 6 — Fuse Both Sources  (Nonlinear Fusion)', cs: cs,
            subtitle: 'Combine sensor risk and report risk into one trip risk score'),
        const SizedBox(height: 12),
        _FormulaCard(
          cs: cs, icon: Icons.merge_type,
          color: const Color(0xFFDB2777),
          formulaTitle: 'Nonlinear Trip Risk Fusion',
          formula: 'R_trip = λ·R_sens + (1−λ)·R_rep + φ·|R_sens − R_rep|',
          explanation: '💡 The extra term φ·|R_sens − R_rep| is the "inconsistency penalty" — if the sensor says the ride is safe but passengers report it as dangerous (or vice versa), the system adds extra risk. Disagreement = uncertainty = higher caution.',
          substituted:
              '${_lambda.toStringAsFixed(2)}·${_sensorRisk.toStringAsFixed(3)}'
              ' + ${(1-_lambda).toStringAsFixed(2)}·${_reportRisk.toStringAsFixed(3)}'
              ' + ${rs.RiskWeights().phi}·|${_sensorRisk.toStringAsFixed(3)} − ${_reportRisk.toStringAsFixed(3)}|',
          result: 'R_trip = ${_tripRisk.toStringAsFixed(4)}',
          fraction: _tripRisk, highlight: true,
        ),
        const SizedBox(height: 24),

        // Safety score
        _GroupHeader('🛡️  Step 7 — Final Safety Score', cs: cs,
            subtitle: 'Convert risk (0–1) to a human-friendly score (0–100)'),
        const SizedBox(height: 12),
        _FormulaCard(
          cs: cs, icon: Icons.shield,
          color: const Color(0xFF16A34A),
          formulaTitle: 'Safety Score',
          formula: 'S_trip = 100 × ( 1 − R_trip )',
          explanation: '💡 We invert the risk score so that higher always means safer — easier for passengers and drivers to understand. A score of 80 means 80% safe. Below 35 is classified as Risky.',
          substituted: 'S_trip = 100 × ( 1 − ${_tripRisk.toStringAsFixed(4)} )',
          result: 'S_trip = $_safetyScore / 100',
          fraction: 1 - _tripRisk, highlight: true,
        ),
        const SizedBox(height: 24),
        _SafetyGauge(score: _safetyScore, cs: cs),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 3 — Trust Score
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTrustTab(ColorScheme cs) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Intro
        _InfoBox(
          text: 'Before a passenger\'s report affects the safety score, '
              'SafeRide calculates a Trust Score (0–1) for that passenger. '
              'This prevents malicious, spammy, or inaccurate reports from '
              'distorting the risk computation.',
          cs: cs,
        ),
        const SizedBox(height: 20),

        _ScoreBanner(score: (_overallTrust * 100).round(), label: 'Current Passenger Trust', cs: cs),
        const SizedBox(height: 24),

        // Frequency
        _GroupHeader('📈  Component 1 — Reporting Frequency  (20% weight)', cs: cs,
            subtitle: 'Passengers who report more often gain credibility over time'),
        const SizedBox(height: 12),
        _FrequencyCard(totalReportsN: _totalReportsN, freqScore: _freqScore, cs: cs,
            onChanged: (v) => setState(() => _totalReportsN = v)),
        const SizedBox(height: 24),

        // History & current severity input
        _GroupHeader('📋  Historical Severity Ratings', cs: cs,
            subtitle: 'Drag the slider to change the current report and watch consistency & anomaly react'),
        const SizedBox(height: 12),
        _HistoryCard(history: _historicalSeverities, currentSeverity: _currentSeverity,
            cs: cs, onChanged: (v) => setState(() => _currentSeverity = v)),
        const SizedBox(height: 24),

        // Consistency
        _GroupHeader('📏  Component 2 — Consistency Score  (35% weight)', cs: cs,
            subtitle: 'Does this passenger report consistently, or wildly different each time?'),
        const SizedBox(height: 12),
        _FormulaCard(
          cs: cs, icon: Icons.linear_scale,
          color: const Color(0xFF0891B2),
          formulaTitle: 'Consistency Score',
          formula: 'C_score = 1 − ( σ / σ_max )',
          explanation: '💡 σ is the standard deviation of past ratings. If a passenger always gives "3" (low σ), their C_score is near 1. If they alternate between 1 and 5 randomly, σ is high and C_score is low — they look unreliable.',
          substituted: 'History: ${_historicalSeverities.join(", ")}   ·   Current: $_currentSeverity',
          result: 'C_score = ${_consistScore.toStringAsFixed(4)}',
          fraction: _consistScore, highlight: true,
        ),
        const SizedBox(height: 24),

        // Anomaly
        _GroupHeader('🚨  Component 3 — Anomaly Score  (25% weight, inverted)', cs: cs,
            subtitle: 'Is the current report an extreme outlier compared to past behaviour?'),
        const SizedBox(height: 12),
        _FormulaCard(
          cs: cs, icon: Icons.warning_amber,
          color: const Color(0xFFD97706),
          formulaTitle: 'Anomaly Detection via Z-Score',
          formula: 'z = (x − μ) / σ   →   anomaly = 1 / (1 + e^−|z|)',
          explanation: '💡 If a passenger always rates "3" but suddenly reports "5" (extreme), the z-score is large, giving a high anomaly score. A high anomaly reduces trust — the report may be exaggerated or inaccurate.',
          substituted: 'x = $_currentSeverity   ·   μ = mean of history   ·   σ = std dev',
          result: 'Anomaly = ${_anomalyScore.toStringAsFixed(4)}   (high = suspicious)',
          fraction: _anomalyScore, highlight: true,
        ),
        const SizedBox(height: 24),

        // Sensor alignment
        _GroupHeader('🔗  Component 4 — Sensor Alignment  (20% weight)', cs: cs,
            subtitle: 'Does the sensor data agree with what the passenger reported?'),
        const SizedBox(height: 12),
        _FormulaCard(
          cs: cs, icon: Icons.link,
          color: const Color(0xFF7C3AED),
          formulaTitle: 'Sensor Alignment Score',
          formula: 'Align = f( severity, detectedEvents, R_sens )\n'
              'expectedEvents = (severity − 1) × 2.5',
          explanation: '💡 If a passenger rates the ride as very dangerous (5/5) but the sensors detected zero unsafe events, the alignment score is low — the report is suspicious. If sensor events back the report, trust is high.',
          substituted:
              'severity=$_currentSeverity   ·   detected events=${_potholeCount + _overspeedCount}   ·   R_sens=${_sensorRisk.toStringAsFixed(2)}',
          result: 'Align = ${_alignScore.toStringAsFixed(4)}',
          fraction: _alignScore, highlight: true,
        ),
        const SizedBox(height: 24),

        // Overall trust
        _GroupHeader('✅  Final — Overall Trust Score  T', cs: cs,
            subtitle: 'Weighted combination of all four components'),
        const SizedBox(height: 12),
        _FormulaCard(
          cs: cs, icon: Icons.verified,
          color: const Color(0xFF16A34A),
          formulaTitle: 'Overall Trust Score',
          formula: 'T = 0.20·F(n) + 0.35·C_score + 0.25·(1−anomaly) + 0.20·Align',
          explanation: '💡 Consistency (35%) is weighted highest because it is the best long-term predictor of a reliable reporter. F(n) rewards frequent, engaged passengers. The anomaly term is inverted — high anomaly = low trust contribution.',
          substituted:
              '0.20·${_freqScore.toStringAsFixed(2)}'
              ' + 0.35·${_consistScore.toStringAsFixed(2)}'
              ' + 0.25·${(1-_anomalyScore).toStringAsFixed(2)}'
              ' + 0.20·${_alignScore.toStringAsFixed(2)}',
          result: 'T = ${_overallTrust.toStringAsFixed(4)}   (0 = untrusted, 1 = fully trusted)',
          fraction: _overallTrust, highlight: true,
        ),
        const SizedBox(height: 24),
        _SafetyGauge(score: (_overallTrust * 100).round(), cs: cs, label: 'Trust'),
        const SizedBox(height: 32),
      ],
    );
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _windowTimer?.cancel();
    _tab.dispose();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN HELPERS
// ─────────────────────────────────────────────────────────────────────────────

Color _riskColor(double v) {
  if (v < 0.40) return const Color(0xFF16A34A);
  if (v < 0.65) return const Color(0xFFD97706);
  return const Color(0xFFDC2626);
}

// ── _GroupHeader ──────────────────────────────────────────────────────────────

class _GroupHeader extends StatelessWidget {
  const _GroupHeader(this.title, {required this.cs, required this.subtitle});
  final String title, subtitle;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 4, height: 44,
              decoration: BoxDecoration(color: cs.primary,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(fontSize: 15,
                  fontWeight: FontWeight.w800, color: cs.onSurface)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant)),
            ]),
          ),
        ],
      );
}

// ── _StatusBanner ─────────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.message, required this.cs, required this.active});
  final String message;
  final ColorScheme cs;
  final bool active;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFDC2626).withValues(alpha: 0.1) : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: active ? const Color(0xFFDC2626).withValues(alpha: 0.5) : Colors.transparent),
        ),
        child: Text(message,
            style: TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13,
                color: active ? const Color(0xFFDC2626) : cs.onSurfaceVariant)),
      );
}

// ── _ScoreBanner ──────────────────────────────────────────────────────────────

class _ScoreBanner extends StatelessWidget {
  const _ScoreBanner({required this.score, required this.label, required this.cs});
  final int score;
  final String label;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final color = _riskColor(1 - score / 100);
    final text  = score >= 60 ? 'SAFE' : score >= 35 ? 'MODERATE' : 'RISKY';
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: score / 100),
      duration: const Duration(milliseconds: 500),
      builder: (_, v, child) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(children: [
          SizedBox(width: 64, height: 64,
            child: Stack(alignment: Alignment.center, children: [
              CircularProgressIndicator(
                value: v, strokeWidth: 7, strokeCap: StrokeCap.round,
                backgroundColor: cs.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(color),
              ),
              Text('$score', style: TextStyle(fontSize: 18,
                  fontWeight: FontWeight.w900, color: color)),
            ]),
          ),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            Text(text, style: TextStyle(fontSize: 22,
                fontWeight: FontWeight.w900, color: color)),
            Text('out of 100', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
          ]),
        ]),
      ),
    );
  }
}

// ── _InfoBox ──────────────────────────────────────────────────────────────────

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.text, required this.cs});
  final String text;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.primaryContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.info_outline, size: 18, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(text,
              style: TextStyle(fontSize: 12.5, color: cs.onPrimaryContainer, height: 1.5))),
        ]),
      );
}

// ── _PipelineFlow ─────────────────────────────────────────────────────────────

class _PipelineFlow extends StatelessWidget {
  const _PipelineFlow({required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final steps = [
      ('📡', 'Sensor\nReadings'),
      ('🌊', 'Filter\n& Smooth'),
      ('⚡', 'Detect\nEvents'),
      ('📊', 'Risk\nScore'),
      ('🔀', 'Fusion'),
      ('🛡️', 'Safety\nScore'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('How the Risk Score is Calculated',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurface)),
        Text('Each step below uses one of the formulas in this demo.',
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(steps.length * 2 - 1, (i) {
              if (i.isOdd) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Icons.arrow_forward_ios, size: 12, color: cs.onSurfaceVariant),
                );
              }
              final step = steps[i ~/ 2];
              return Column(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
                  ),
                  child: Text(step.$1, style: const TextStyle(fontSize: 18)),
                ),
                const SizedBox(height: 4),
                SizedBox(width: 60,
                  child: Text(step.$2,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 9, color: cs.onSurfaceVariant, height: 1.3))),
              ]);
            }),
          ),
        ),
      ]),
    );
  }
}

// ── _FormulaCard ──────────────────────────────────────────────────────────────

class _FormulaCard extends StatelessWidget {
  const _FormulaCard({
    required this.cs, required this.icon, required this.color,
    required this.formulaTitle, required this.formula,
    required this.explanation,
    required this.substituted, required this.result,
    required this.fraction, this.highlight = false,
  });

  final ColorScheme cs;
  final IconData icon;
  final Color color;
  final String formulaTitle, formula, explanation, substituted, result;
  final double fraction;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final barColor = _riskColor(fraction);
    final levelText = fraction < 0.40 ? 'LOW' : fraction < 0.65 ? 'MED' : 'HIGH';

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Gradient header: title + formula ────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.75)]),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(icon, color: Colors.white, size: 15),
              const SizedBox(width: 6),
              Text(formulaTitle, style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700,
                  color: Colors.white, letterSpacing: 0.3)),
            ]),
            const SizedBox(height: 6),
            Text(formula, style: const TextStyle(
                fontFamily: 'monospace', fontSize: 12.5,
                fontWeight: FontWeight.w500, color: Colors.white, height: 1.5)),
          ]),
        ),

        // ── Plain English explanation ────────────────────────────────────────
        Container(
          width: double.infinity,
          color: color.withValues(alpha: 0.07),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Text(explanation, style: TextStyle(
              fontSize: 12, color: cs.onSurface, height: 1.5)),
        ),

        // ── Substituted live values ──────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
          child: Text('Live calculation:',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                  color: cs.onSurfaceVariant, letterSpacing: 0.5)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: Text(substituted, style: TextStyle(
              fontSize: 11.5, color: cs.onSurfaceVariant, height: 1.6)),
        ),

        // ── Animated bar ─────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(children: [
            const Text('Safe', style: TextStyle(fontSize: 9)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: fraction.clamp(0, 1)),
                    duration: const Duration(milliseconds: 400),
                    builder: (_, v, child) => LinearProgressIndicator(
                      value: v, minHeight: 8,
                      backgroundColor: cs.surfaceContainerLow,
                      valueColor: AlwaysStoppedAnimation(barColor),
                    ),
                  ),
                ),
              ),
            ),
            const Text('Risky', style: TextStyle(fontSize: 9)),
          ]),
        ),

        // ── Result row ───────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          child: Row(children: [
            Expanded(
              child: highlight
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: barColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: barColor.withValues(alpha: 0.35)),
                      ),
                      child: Text(result, style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 13,
                          color: barColor, fontFamily: 'monospace')))
                  : Text(result, style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13,
                      color: cs.onSurface, fontFamily: 'monospace')),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: barColor,
                  borderRadius: BorderRadius.circular(8)),
              child: Text(levelText, style: const TextStyle(
                  color: Colors.white, fontSize: 10,
                  fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ── _SpeedSliderCard ──────────────────────────────────────────────────────────

class _SpeedSliderCard extends StatelessWidget {
  const _SpeedSliderCard(
      {required this.speed, required this.threshold, required this.cs, required this.onChanged});
  final double speed, threshold;
  final ColorScheme cs;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final over  = speed > threshold;
    final color = over ? const Color(0xFFDC2626) : const Color(0xFF16A34A);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('0 km/h', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(over ? Icons.warning_rounded : Icons.check_circle,
                  color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text('${speed.toStringAsFixed(0)} km/h  ${over ? "OVERSPEEDING" : "NORMAL"}',
                  style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w800, fontSize: 13)),
            ]),
          ),
          Text('120 km/h', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
        ]),
        Slider(value: speed, min: 0, max: 120, divisions: 120, activeColor: color,
            label: '${speed.toStringAsFixed(0)} km/h', onChanged: onChanged),
        Text('Speed threshold θ_v = ${threshold.toStringAsFixed(0)} km/h  '
            '(drag above this to trigger E_v = 1)',
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
      ]),
    );
  }
}

// ── _SensorGridCard ───────────────────────────────────────────────────────────

class _SensorGridCard extends StatelessWidget {
  const _SensorGridCard({
    required this.ax, required this.ay, required this.az,
    required this.gx, required this.gy, required this.gz, required this.cs,
  });
  final double ax, ay, az, gx, gy, gz;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Accelerometer  (m/s²)',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cs.onSurfaceVariant)),
          const SizedBox(height: 8),
          Row(children: [
            _SensorTile('ax', 'Left / Right', ax, const Color(0xFFDC2626), cs),
            const SizedBox(width: 8),
            _SensorTile('ay', 'Fwd / Back', ay, const Color(0xFFD97706), cs),
            const SizedBox(width: 8),
            _SensorTile('az', 'Up / Down', az, const Color(0xFF16A34A), cs),
          ]),
          const SizedBox(height: 12),
          Text('Gyroscope  (rad/s)',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cs.onSurfaceVariant)),
          const SizedBox(height: 8),
          Row(children: [
            _SensorTile('gx', 'Roll', gx, const Color(0xFF7C3AED), cs),
            const SizedBox(width: 8),
            _SensorTile('gy', 'Pitch', gy, const Color(0xFF0891B2), cs),
            const SizedBox(width: 8),
            _SensorTile('gz', 'Yaw / Turn', gz, const Color(0xFFDB2777), cs),
          ]),
        ]),
      );
}

class _SensorTile extends StatelessWidget {
  const _SensorTile(this.axis, this.meaning, this.value, this.color, this.cs);
  final String axis, meaning;
  final double value;
  final Color color;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final norm = (value.abs() / 15).clamp(0.0, 1.0);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 8, height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text(axis, style: TextStyle(fontSize: 10,
                fontWeight: FontWeight.w800, color: color)),
          ]),
          Text(meaning, style: TextStyle(fontSize: 8.5, color: cs.onSurfaceVariant)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: norm),
              duration: const Duration(milliseconds: 200),
              builder: (_, v, child) => LinearProgressIndicator(
                value: v, minHeight: 4,
                backgroundColor: cs.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(value.toStringAsFixed(2), style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w800, color: cs.onSurface)),
        ]),
      ),
    );
  }
}

// ── _PotholeCard ──────────────────────────────────────────────────────────────

class _PotholeCard extends StatelessWidget {
  const _PotholeCard({
    required this.az, required this.gyroMag, required this.speed,
    required this.thresholds, required this.detected, required this.count, required this.cs,
  });
  final double az, gyroMag, speed;
  final rs.AdaptiveThresholds thresholds;
  final bool detected;
  final int count;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final c1 = az > thresholds.thetaPothole;
    final c2 = gyroMag < thresholds.thetaGyroStable;
    final c3 = speed > thresholds.thetaSpeedMin;
    final color = detected ? const Color(0xFFDC2626) : const Color(0xFF16A34A);

    return Container(
      decoration: BoxDecoration(color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4))),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: const BoxDecoration(gradient: LinearGradient(
              colors: [Color(0xFF92400E), Color(0xFF78350F)])),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 15),
              SizedBox(width: 6),
              Text('Pothole Detection', style: TextStyle(fontSize: 12,
                  fontWeight: FontWeight.w700, color: Colors.white)),
            ]),
            const SizedBox(height: 6),
            const Text('P(k) = 1   if   az > θ_p  ∧  g̃ < θ_g  ∧  v > θ_v',
                style: TextStyle(fontFamily: 'monospace', fontSize: 12,
                    color: Colors.white)),
          ]),
        ),
        Container(
          color: const Color(0xFF92400E).withValues(alpha: 0.07),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: const Text(
            '💡 All 3 conditions must be true at the same time. '
            'This prevents false alarms: a sharp turn might spike "az" but high gyro (g̃) disqualifies it; '
            'a bump at a stop light is filtered by the speed condition.',
            style: TextStyle(fontSize: 12, height: 1.5),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            _CondRow('az = ${az.toStringAsFixed(2)} m/s²', '> θ_p = ${thresholds.thetaPothole}  (vertical spike?)', c1, 'Vertical acceleration is high enough', cs),
            const SizedBox(height: 8),
            _CondRow('g̃  = ${gyroMag.toStringAsFixed(2)} rad/s', '< θ_g = ${thresholds.thetaGyroStable}  (not turning?)', c2, 'Phone is not rotating (not a turn)', cs),
            const SizedBox(height: 8),
            _CondRow('v  = ${speed.toStringAsFixed(1)} km/h', '> θ_v = ${thresholds.thetaSpeedMin}  (moving?)', c3, 'Vehicle is actually moving', cs),
            const SizedBox(height: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: color,
                  borderRadius: BorderRadius.circular(14)),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(detected ? Icons.crisis_alert : Icons.check_circle,
                    color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  detected ? 'POTHOLE DETECTED  (total: $count)' : 'No pothole detected  (total: $count)',
                  style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w800, fontSize: 14)),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _CondRow extends StatelessWidget {
  const _CondRow(this.value, this.threshold, this.pass, this.meaning, this.cs);
  final String value, threshold, meaning;
  final bool pass;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final color = pass ? const Color(0xFF16A34A) : cs.onSurfaceVariant;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(pass ? Icons.check_circle_rounded : Icons.cancel_rounded,
          color: color, size: 18),
      const SizedBox(width: 8),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        RichText(text: TextSpan(children: [
          TextSpan(text: value, style: TextStyle(fontSize: 12,
              fontWeight: FontWeight.w700, color: color, fontFamily: 'monospace')),
          TextSpan(text: '  $threshold', style: TextStyle(fontSize: 11,
              color: cs.onSurfaceVariant, fontFamily: 'monospace')),
        ])),
        Text(meaning, style: TextStyle(fontSize: 10.5, color: cs.onSurfaceVariant)),
      ])),
    ]);
  }
}

// ── _SlopeCard ────────────────────────────────────────────────────────────────

class _SlopeCard extends StatelessWidget {
  const _SlopeCard({
    required this.altitudePrev, required this.altitudeCurr,
    required this.distanceTraveled, required this.slope, required this.cs,
    required this.onAltPrev, required this.onAltCurr, required this.onDist,
  });
  final double altitudePrev, altitudeCurr, distanceTraveled, slope;
  final ColorScheme cs;
  final ValueChanged<double> onAltPrev, onAltCurr, onDist;

  @override
  Widget build(BuildContext context) {
    final grade = (slope * 100);
    final color = slope.abs() > 0.15
        ? const Color(0xFFDC2626)
        : slope.abs() > 0.07
            ? const Color(0xFFD97706)
            : const Color(0xFF16A34A);

    return Container(
      decoration: BoxDecoration(color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.3))),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: const BoxDecoration(gradient: LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)])),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.terrain, color: Colors.white, size: 15),
              SizedBox(width: 6),
              Text('Road Slope Computation', style: TextStyle(fontSize: 12,
                  fontWeight: FontWeight.w700, color: Colors.white)),
            ]),
            const SizedBox(height: 6),
            const Text('S(t) = ( h(t) − h(t−1) ) / d(t)',
                style: TextStyle(fontFamily: 'monospace', fontSize: 12.5, color: Colors.white)),
          ]),
        ),
        Container(
          color: const Color(0xFF7C3AED).withValues(alpha: 0.07),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: const Text(
            '💡 Steeper roads (like Antipolo zigzag) contribute to risk even without bad driving. '
            'h(t) is the current GPS altitude, h(t-1) is the last recorded altitude, '
            'and d(t) is the distance traveled between them.',
            style: TextStyle(fontSize: 12, height: 1.5)),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            _SliderRow2('h(t−1)  Previous altitude', altitudePrev, 0, 500, 'm', onAltPrev, cs),
            const SizedBox(height: 6),
            _SliderRow2('h(t)   Current altitude',  altitudeCurr, 0, 500, 'm', onAltCurr, cs),
            const SizedBox(height: 6),
            _SliderRow2('d(t)   Distance traveled', distanceTraveled, 1, 1000, 'm', onDist, cs),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.4)),
              ),
              child: Row(children: [
                Icon(slope >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                    color: color, size: 22),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    'S(t) = (${altitudeCurr.toStringAsFixed(0)} − ${altitudePrev.toStringAsFixed(0)}) / ${distanceTraveled.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                  Text('= ${slope.toStringAsFixed(4)}  →  ${grade.toStringAsFixed(1)}% grade  '
                      '(${slope >= 0 ? "uphill" : "downhill"})',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                        color: color, fontFamily: 'monospace')),
                ])),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _SliderRow2 extends StatelessWidget {
  const _SliderRow2(this.label, this.value, this.min, this.max, this.unit,
      this.onChanged, this.cs);
  final String label, unit;
  final double value, min, max;
  final ValueChanged<double> onChanged;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) => Row(children: [
        SizedBox(width: 148,
            child: Text(label, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant))),
        Expanded(child: Slider(value: value, min: min, max: max,
            label: '${value.toStringAsFixed(0)} $unit', onChanged: onChanged)),
        SizedBox(width: 52,
            child: Text('${value.toStringAsFixed(0)} $unit',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: cs.onSurface))),
      ]);
}

// ── _EventFlagsCard ───────────────────────────────────────────────────────────

class _EventFlagsCard extends StatelessWidget {
  const _EventFlagsCard({
    required this.overspeed, required this.sharpTurn,
    required this.speed, required this.gyroMax,
    required this.threshold, required this.counts, required this.cs,
  });
  final bool overspeed, sharpTurn;
  final double speed, gyroMax;
  final rs.AdaptiveThresholds threshold;
  final (int, int, int) counts;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20)),
        child: Column(children: [
          _EventRow(
            label: 'E_v — Overspeeding',
            formula: 'E_v = 1   if   v_w > θ_v',
            detail: 'Drag speed above ${threshold.thetaSpeedingBase.toStringAsFixed(0)} km/h to trigger  ·  current: ${speed.toStringAsFixed(0)} km/h',
            explanation: 'Is the average window speed above the threshold?',
            active: overspeed, count: counts.$1, cs: cs,
          ),
          const SizedBox(height: 10),
          _EventRow(
            label: 'E_b — Harsh Braking',
            formula: 'E_b = 1   if   Δv < −θ_b',
            detail: 'Drag the speed slider downward quickly to trigger',
            explanation: 'Did speed drop suddenly? (Δv is the speed change per step)',
            active: false, count: counts.$2, cs: cs,
          ),
          const SizedBox(height: 10),
          _EventRow(
            label: 'E_g — Sharp Turning',
            formula: 'E_g = 1   if   g_max > θ_g',
            detail: 'Rotate the phone to trigger  ·  g_max=${gyroMax.toStringAsFixed(2)} rad/s, θ_g=${threshold.thetaTurningBase.toStringAsFixed(1)}',
            explanation: 'Is the maximum gyro reading in the window above the turn threshold?',
            active: sharpTurn, count: counts.$3, cs: cs,
          ),
        ]),
      );
}

class _EventRow extends StatelessWidget {
  const _EventRow({
    required this.label, required this.formula,
    required this.detail, required this.explanation,
    required this.active, required this.count, required this.cs,
  });
  final String label, formula, detail, explanation;
  final bool active;
  final int count;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFFDC2626) : cs.onSurfaceVariant;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFDC2626).withValues(alpha: 0.08) : cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: active ? const Color(0xFFDC2626).withValues(alpha: 0.5) : Colors.transparent),
      ),
      child: Row(children: [
        Icon(active ? Icons.warning_rounded : Icons.check_circle_outline,
            color: active ? const Color(0xFFDC2626) : const Color(0xFF16A34A), size: 24),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: color)),
          Text(formula, style: TextStyle(fontFamily: 'monospace',
              fontSize: 11, color: cs.onSurfaceVariant)),
          Text(explanation, style: TextStyle(fontSize: 11,
              color: cs.onSurfaceVariant, fontStyle: FontStyle.italic)),
          Text(detail, style: TextStyle(fontSize: 10.5, color: cs.onSurfaceVariant)),
        ])),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFDC2626) : cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('×$count', style: TextStyle(
              fontWeight: FontWeight.w800, fontSize: 12,
              color: active ? Colors.white : cs.onSurfaceVariant)),
        ),
      ]),
    );
  }
}

// ── _ContextSlidersCard ───────────────────────────────────────────────────────

class _ContextSlidersCard extends StatelessWidget {
  const _ContextSlidersCard(
      {required this.thresholds, required this.onChanged, required this.cs});
  final rs.AdaptiveThresholds thresholds;
  final VoidCallback onChanged;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20)),
        child: Column(children: [
          _SliderRow2('Rc — Road condition\n(0=poor, 1=good)', thresholds.contextRoad, 0, 1, '', (v) {
            thresholds.updateContextFactors(roadCondition: v,
                envNoise: thresholds.contextEnvNoise, trafficDensity: thresholds.contextTraffic);
            onChanged();
          }, cs),
          _SliderRow2('Td — Traffic density\n(0=light, 1=heavy)', thresholds.contextTraffic, 0, 1, '', (v) {
            thresholds.updateContextFactors(roadCondition: thresholds.contextRoad,
                envNoise: thresholds.contextEnvNoise, trafficDensity: v);
            onChanged();
          }, cs),
          _SliderRow2('En — Environmental noise\n(0=quiet, 1=loud)', thresholds.contextEnvNoise, 0, 1, '', (v) {
            thresholds.updateContextFactors(roadCondition: thresholds.contextRoad,
                envNoise: v, trafficDensity: thresholds.contextTraffic);
            onChanged();
          }, cs),
        ]),
      );
}

// ── _ReportInputsCard ─────────────────────────────────────────────────────────

class _ReportInputsCard extends StatelessWidget {
  const _ReportInputsCard({
    required this.report1Rating, required this.report1Trust,
    required this.report2Rating, required this.report2Trust,
    required this.cs, required this.onChanged,
  });
  final double report1Rating, report1Trust, report2Rating, report2Trust;
  final ColorScheme cs;
  final void Function(double, double, double, double) onChanged;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20)),
        child: Column(children: [
          _PassengerRow(label: 'Passenger 1  (r₁, T₁)',
              rating: report1Rating, trust: report1Trust, cs: cs,
              onRating: (v) => onChanged(v, report1Trust, report2Rating, report2Trust),
              onTrust:  (v) => onChanged(report1Rating, v, report2Rating, report2Trust)),
          Divider(color: cs.outlineVariant, height: 24),
          _PassengerRow(label: 'Passenger 2  (r₂, T₂)',
              rating: report2Rating, trust: report2Trust, cs: cs,
              onRating: (v) => onChanged(report1Rating, report1Trust, v, report2Trust),
              onTrust:  (v) => onChanged(report1Rating, report1Trust, report2Rating, v)),
        ]),
      );
}

class _PassengerRow extends StatelessWidget {
  const _PassengerRow({
    required this.label, required this.rating, required this.trust,
    required this.cs, required this.onRating, required this.onTrust,
  });
  final String label;
  final double rating, trust;
  final ColorScheme cs;
  final ValueChanged<double> onRating, onTrust;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.person, size: 16, color: cs.primary),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          ]),
          _SliderRow2('r_i  Danger rating (1–5)\n1=safe  5=very dangerous', rating, 1, 5, '', onRating, cs),
          _SliderRow2('T_i  Trust level (0–1)\n0=new/untrusted  1=highly trusted', trust, 0, 1, '', onTrust, cs),
        ],
      );
}

// ── _FrequencyCard ────────────────────────────────────────────────────────────

class _FrequencyCard extends StatelessWidget {
  const _FrequencyCard(
      {required this.totalReportsN, required this.freqScore, required this.cs, required this.onChanged});
  final double totalReportsN, freqScore;
  final ColorScheme cs;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    const k = 15.0;
    final color = _riskColor(1 - freqScore);

    return Container(
      decoration: BoxDecoration(color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.3))),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: const BoxDecoration(gradient: LinearGradient(
              colors: [Color(0xFF059669), Color(0xFF047857)])),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.trending_up, color: Colors.white, size: 15),
              SizedBox(width: 6),
              Text('Frequency Score', style: TextStyle(fontSize: 12,
                  fontWeight: FontWeight.w700, color: Colors.white)),
            ]),
            const SizedBox(height: 6),
            const Text('F(n) = 1 − e^( −n / k )   where k = 15',
                style: TextStyle(fontFamily: 'monospace', fontSize: 12.5, color: Colors.white)),
          ]),
        ),
        Container(
          color: const Color(0xFF059669).withValues(alpha: 0.07),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: const Text(
            '💡 A brand-new passenger starts with F(0)=0 (no credibility yet). '
            'As they submit more reports, F(n) grows toward 1. '
            'The curve levels off around n=30 — so very frequent reporters '
            'are not unfairly over-credited. Drag the slider to see this happen.',
            style: TextStyle(fontSize: 12, height: 1.5)),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            _SliderRow2('n — number of past reports', totalReportsN, 0, 50, 'reports', onChanged, cs),
            const SizedBox(height: 8),
            Text('F(${totalReportsN.round()}) = 1 − e^( −${totalReportsN.round()} / $k )',
                style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: cs.onSurfaceVariant)),
            const SizedBox(height: 8),
            Row(children: [
              const Text('0', style: TextStyle(fontSize: 9)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: freqScore),
                      duration: const Duration(milliseconds: 400),
                      builder: (_, v, child) => LinearProgressIndicator(
                        value: v, minHeight: 10,
                        backgroundColor: cs.surfaceContainerLow,
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                  ),
                ),
              ),
              const Text('1', style: TextStyle(fontSize: 9)),
            ]),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withValues(alpha: 0.35)),
              ),
              child: Text('F(n) = ${freqScore.toStringAsFixed(4)}',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14,
                      color: color, fontFamily: 'monospace')),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ── _HistoryCard ──────────────────────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.history, required this.currentSeverity,
    required this.cs, required this.onChanged,
  });
  final List<int> history;
  final int currentSeverity;
  final ColorScheme cs;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    Color chipColor(int s) => s <= 2
        ? const Color(0xFF16A34A)
        : s == 3
            ? const Color(0xFFD97706)
            : const Color(0xFFDC2626);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Past ratings from this passenger:',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: history.map((s) {
            final c = chipColor(s);
            return Container(
              width: 36, height: 36, alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: c.withValues(alpha: 0.5)),
              ),
              child: Text('$s', style: TextStyle(fontWeight: FontWeight.w800, color: c)));
          }).toList(),
        ),
        const SizedBox(height: 14),
        Text('Simulate a new report — drag to change severity:',
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
        Row(children: [
          const Text('1\n(safe)', textAlign: TextAlign.center,
              style: TextStyle(fontSize: 9)),
          Expanded(child: Slider(
            value: currentSeverity.toDouble(), min: 1, max: 5, divisions: 4,
            label: '$currentSeverity',
            onChanged: (v) => onChanged(v.round()),
          )),
          const Text('5\n(danger)', textAlign: TextAlign.center,
              style: TextStyle(fontSize: 9)),
        ]),
        Center(child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: chipColor(currentSeverity).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: chipColor(currentSeverity).withValues(alpha: 0.5)),
          ),
          child: Text('Current report: $currentSeverity / 5',
              style: TextStyle(fontWeight: FontWeight.w800,
                  color: chipColor(currentSeverity))),
        )),
      ]),
    );
  }
}

// ── _SafetyGauge ──────────────────────────────────────────────────────────────

class _SafetyGauge extends StatelessWidget {
  const _SafetyGauge({required this.score, required this.cs, this.label = 'Safety Score'});
  final int score;
  final ColorScheme cs;
  final String label;

  Color get _color {
    if (score >= 60) return const Color(0xFF16A34A);
    if (score >= 35) return const Color(0xFFD97706);
    return const Color(0xFFDC2626);
  }

  String get _classification {
    if (score >= 60) return '🟢  SAFE  (≥ 60)';
    if (score >= 35) return '🟡  MODERATE  (35–59)';
    return '🔴  RISKY  (< 35)';
  }

  String get _meaning {
    if (score >= 60) return 'The ride is classified as safe.';
    if (score >= 35) return 'The ride has moderate risk — caution advised.';
    return 'The ride is classified as risky — action needed.';
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _color.withValues(alpha: 0.4)),
        ),
        child: Column(children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: score / 100),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (_, v, child) => SizedBox(
              width: 160, height: 160,
              child: Stack(alignment: Alignment.center, children: [
                CircularProgressIndicator(
                  value: v, strokeWidth: 14, strokeCap: StrokeCap.round,
                  backgroundColor: cs.surfaceContainerLow,
                  valueColor: AlwaysStoppedAnimation(_color),
                ),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('$score', style: TextStyle(fontSize: 44,
                      fontWeight: FontWeight.w900, color: _color)),
                  Text('/ 100', style: TextStyle(fontSize: 12,
                      color: cs.onSurfaceVariant)),
                ]),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          Text(label, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(_classification, style: TextStyle(fontSize: 18,
              fontWeight: FontWeight.w800, color: _color)),
          const SizedBox(height: 6),
          Text(_meaning, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          // Classification legend
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _LegendDot('Safe', '≥ 60', const Color(0xFF16A34A)),
            const SizedBox(width: 16),
            _LegendDot('Moderate', '35–59', const Color(0xFFD97706)),
            const SizedBox(width: 16),
            _LegendDot('Risky', '< 35', const Color(0xFFDC2626)),
          ]),
        ]),
      );
}

class _LegendDot extends StatelessWidget {
  const _LegendDot(this.label, this.range, this.color);
  final String label, range;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(width: 10, height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
          Text(range, style: TextStyle(fontSize: 9, color: color)),
        ]),
      ]);
}

// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:saferide/services/risk_scoring.dart';
import 'package:saferide/services/trust_scoring_service.dart';

/// ─────────────────────────────────────────────────────────────────────────────
///  SafeRide – Algorithm Validation Tests (Philippine Road Conditions)
///
///  These unit tests validate every formula in risk_scoring.dart and
///  trust_scoring_service.dart using realistic scenarios drawn from
///  Philippine road contexts: EDSA (heavy traffic, frequent braking),
///  C5 / Commonwealth (high-speed arterials), Katipunan (moderate traffic),
///  Antipolo / zigzag roads (steep slopes + potholes), and provincial roads.
/// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ──────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ──────────────────────────────────────────────────────────────────────────

  /// Build a SensorReading with sensible defaults for the fields you don't care
  /// about in a particular test.
  SensorReading makeSensor({
    double speed = 30.0, // km/h
    double accelX = 0.0,
    double accelY = 0.0,
    double accelZ = 9.81, // gravity at rest
    double gyroX = 0.0,
    double gyroY = 0.0,
    double gyroZ = 0.0,
    double? altitude,
    double? distance,
    DateTime? timestamp,
  }) {
    return SensorReading(
      speed: speed,
      accelX: accelX,
      accelY: accelY,
      accelZ: accelZ,
      gyroX: gyroX,
      gyroY: gyroY,
      gyroZ: gyroZ,
      altitude: altitude,
      distance: distance,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // GROUP 1 – Acceleration & Gyro Magnitude
  // Formula: a(k) = sqrt(ax^2 + ay^2 + az^2)  |  g(k) = sqrt(gx^2 + gy^2 + gz^2)
  // ──────────────────────────────────────────────────────────────────────────
  group('Sensor Magnitude Computation', () {
    test('acceleration magnitude – idle on flat road', () {
      // At rest the only acceleration is gravity (~9.81 m/s^2) on the z-axis.
      final mag = computeAccelerationMagnitude(0, 0, 9.81);
      expect(mag, closeTo(9.81, 0.01));
    });

    test('acceleration magnitude – pothole impact (high vertical spike)', () {
      // Simulates hitting a large pothole: az spikes to ~15 m/s^2
      final mag = computeAccelerationMagnitude(0.5, 0.3, 15.0);
      expect(mag, greaterThan(10.0));
    });

    test('gyro magnitude – straight road, no rotation', () {
      final mag = computeGyroMagnitude(0.01, 0.01, 0.01);
      expect(mag, lessThan(0.1));
    });

    test('gyro magnitude – sharp U-turn at Katipunan flyover', () {
      // Aggressive lateral rotation (gz ~5 rad/s)
      final mag = computeGyroMagnitude(0.2, 0.3, 5.0);
      expect(mag, greaterThan(4.5));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // GROUP 2 – Moving Average Filter
  // Formula: x_tilde(k) = (1/M) * Sum(x(k-i)) for i = 0 to M-1
  // ──────────────────────────────────────────────────────────────────────────
  group('Moving Average Filter', () {
    test('returns 0 for empty list', () {
      expect(movingAverageFilter([], 5), 0.0);
    });

    test('single value equals itself', () {
      expect(movingAverageFilter([42.0], 5), 42.0);
    });

    test('filters noisy EDSA speed readings', () {
      // Simulated GPS speed noise around 30 km/h on heavy EDSA traffic
      final speeds = [28.0, 32.0, 29.5, 31.0, 30.5, 28.8, 33.0, 30.0];
      final filtered = movingAverageFilter(speeds, 4);
      // Should be roughly average of last 4 readings
      final expected = (28.8 + 33.0 + 30.0 + 30.5) / 4;
      expect(filtered, closeTo(expected, 0.5));
    });

    test('window larger than list uses all values', () {
      final values = [10.0, 20.0, 30.0];
      expect(movingAverageFilter(values, 10), closeTo(20.0, 0.01));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // GROUP 3 – Pothole Detection
  // Formula: P(k) = 1 if az(k) > theta_p AND g(k) < theta_g AND v(k) > theta_v
  // ──────────────────────────────────────────────────────────────────────────
  group('Pothole Detection', () {
    final thresholds = AdaptiveThresholds(); // theta_p=2.5, theta_g=0.8, theta_v=5.0

    test('detects pothole on rough Antipolo zigzag road', () {
      final detected = detectPothole(
        verticalAccel: 4.5, // strong bump
        gyroMagnitude: 0.3, // stable heading
        speed: 25.0, // moving
        thresholds: thresholds,
      );
      expect(detected, isTrue);
    });

    test('no false positive at stop light (speed too low)', () {
      final detected = detectPothole(
        verticalAccel: 3.0,
        gyroMagnitude: 0.2,
        speed: 2.0, // near-stationary
        thresholds: thresholds,
      );
      expect(detected, isFalse);
    });

    test('no false positive during sharp turn (high gyro)', () {
      final detected = detectPothole(
        verticalAccel: 3.0,
        gyroMagnitude: 1.5, // turning = not a pothole
        speed: 20.0,
        thresholds: thresholds,
      );
      expect(detected, isFalse);
    });

    test('no false positive on smooth NLEX (low vertical accel)', () {
      final detected = detectPothole(
        verticalAccel: 1.0, // smooth road
        gyroMagnitude: 0.1,
        speed: 80.0,
        thresholds: thresholds,
      );
      expect(detected, isFalse);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // GROUP 4 – Slope Computation
  // Formula: S(t) = (h(t) - h(t-1)) / d(t)
  // ──────────────────────────────────────────────────────────────────────────
  group('Slope Computation', () {
    test('flat road returns zero slope', () {
      final slope = computeSlope(
        currentAltitude: 50.0,
        previousAltitude: 50.0,
        distanceTraveled: 100.0,
      );
      expect(slope, 0.0);
    });

    test('Antipolo ascent: +20 m over 200 m road', () {
      // Steep uphill: ~10% grade
      final slope = computeSlope(
        currentAltitude: 370.0,
        previousAltitude: 350.0,
        distanceTraveled: 200.0,
      );
      expect(slope, closeTo(0.10, 0.001));
    });

    test('descent returns negative slope', () {
      final slope = computeSlope(
        currentAltitude: 100.0,
        previousAltitude: 120.0,
        distanceTraveled: 200.0,
      );
      expect(slope, closeTo(-0.10, 0.001));
    });

    test('zero distance returns zero to avoid division by zero', () {
      final slope = computeSlope(
        currentAltitude: 150.0,
        previousAltitude: 140.0,
        distanceTraveled: 0.0,
      );
      expect(slope, 0.0);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // GROUP 5 – Window Metrics Extraction
  // ──────────────────────────────────────────────────────────────────────────
  group('Window Metrics Extraction', () {
    test('empty window returns zero metrics', () {
      final metrics = extractWindowMetrics([], 5);
      expect(metrics.averageSpeed, 0.0);
      expect(metrics.maxAngularVelocity, 0.0);
    });

    test('EDSA stop-and-go: average speed and deceleration', () {
      final readings = [
        makeSensor(speed: 40.0),
        makeSensor(speed: 20.0), // sudden braking (traffic)
        makeSensor(speed: 5.0),
        makeSensor(speed: 0.0), // full stop at red light
        makeSensor(speed: 10.0),
      ];
      final metrics = extractWindowMetrics(readings, 5);

      expect(metrics.averageSpeed, closeTo(15.0, 0.1));
      expect(metrics.maxSpeedDeceleration, lessThan(-10.0)); // harsh decel
    });

    test('C5 highway: consistent high speed, low deceleration', () {
      final readings = [
        makeSensor(speed: 80.0),
        makeSensor(speed: 82.0),
        makeSensor(speed: 79.0),
        makeSensor(speed: 81.0),
      ];
      final metrics = extractWindowMetrics(readings, 4);

      expect(metrics.averageSpeed, closeTo(80.5, 1.0));
      expect(metrics.maxSpeedDeceleration, greaterThan(-5.0)); // smooth drive
    });

    test('sharp turning detected via high angular velocity', () {
      final readings = [
        makeSensor(gyroX: 0.1, gyroY: 0.1, gyroZ: 5.5), // hard turn
        makeSensor(gyroX: 0.0, gyroY: 0.0, gyroZ: 0.2),
      ];
      final metrics = extractWindowMetrics(readings, 2);
      expect(metrics.maxAngularVelocity, greaterThan(4.5));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // GROUP 6 – Event Detection (Overspeeding, Braking, Turning)
  // ──────────────────────────────────────────────────────────────────────────
  group('Event Detection', () {
    final thresholds = AdaptiveThresholds();

    test('overspeeding detected on C5 expressway (>40 km/h baseline)', () {
      expect(detectOverspeeding(60.0, thresholds), isTrue);
    });

    test('no overspeeding on school zone speed (25 km/h)', () {
      expect(detectOverspeeding(25.0, thresholds), isFalse);
    });

    test('harsh braking detected on EDSA (delta-v < -8 m/s^2)', () {
      expect(detectHarshBraking(-10.0, thresholds), isTrue);
    });

    test('gentle braking not flagged (-2 m/s^2)', () {
      expect(detectHarshBraking(-2.0, thresholds), isFalse);
    });

    test('sharp turning detected on Katipunan intersection', () {
      expect(detectSharpTurning(5.5, thresholds), isTrue);
    });

    test('normal curve not flagged (2 rad/s)', () {
      expect(detectSharpTurning(2.0, thresholds), isFalse);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // GROUP 7 – Adaptive Thresholds
  // Formula: theta(t) = theta_base(v) x (1 + alpha*R_c(t)) x (1 + beta*T_d(t)) x (1 + gamma*E_n(t))
  // ──────────────────────────────────────────────────────────────────────────
  group('Adaptive Thresholds', () {
    test('no context adjustment: threshold equals base', () {
      final t = AdaptiveThresholds();
      t.updateContextFactors(
        roadCondition: 0.0,
        envNoise: 0.0,
        trafficDensity: 0.0,
      );
      expect(t.speedingThreshold, closeTo(40.0, 0.01));
    });

    test('heavy EDSA traffic raises effective thresholds', () {
      final t = AdaptiveThresholds();
      t.updateContextFactors(
        roadCondition: 0.5, // moderate road condition
        envNoise: 0.3,
        trafficDensity: 1.0, // bumper-to-bumper
      );
      // theta_v = 40 x (1 + 0.3*0.5) x (1 + 0.2*1.0) x (1 + 0.1*0.3) = higher
      final expected =
          40.0 * (1 + 0.3 * 0.5) * (1 + 0.2 * 1.0) * (1 + 0.1 * 0.3);
      expect(t.speedingThreshold, closeTo(expected, 0.5));
    });

    test('contextual adjustment factor A(t) >= 1 for any non-negative inputs',
        () {
      final t = AdaptiveThresholds();
      t.updateContextFactors(
        roadCondition: 0.8,
        envNoise: 0.5,
        trafficDensity: 0.7,
      );
      expect(t.getContextualAdjustment(), greaterThanOrEqualTo(1.0));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // GROUP 8 – Sensor Risk Score
  // Formula: R_sens = (w1*C_v + w2*C_b + w3*C_g + w4*P + w5*|S|) / W_total x A(t)
  // ──────────────────────────────────────────────────────────────────────────
  group('Sensor Risk Score', () {
    test('zero events produces zero risk', () {
      final weights = RiskWeights();
      final score = computeSensorRiskScore(
        overspeedingCount: 0,
        harshBrakingCount: 0,
        sharpTurningCount: 0,
        potholeCount: 0,
        totalSlopeDeviation: 0,
        totalWindows: 10,
        weights: weights,
      );
      expect(score, 0.0);
    });

    test('score is clamped to [0, 1]', () {
      final weights = RiskWeights();
      final score = computeSensorRiskScore(
        overspeedingCount: 1000,
        harshBrakingCount: 1000,
        sharpTurningCount: 1000,
        potholeCount: 1000,
        totalSlopeDeviation: 1000,
        totalWindows: 1,
        weights: weights,
      );
      expect(score, 1.0);
    });

    test('dangerous EDSA driver: many braking + overspeeding events', () {
      final weights = RiskWeights();
      // 8 out of 20 windows had overspeeding or harsh braking
      final score = computeSensorRiskScore(
        overspeedingCount: 5,
        harshBrakingCount: 8,
        sharpTurningCount: 2,
        potholeCount: 3,
        totalSlopeDeviation: 0.1,
        totalWindows: 20,
        weights: weights,
      );
      // Formula: R_sens = (w1*5 + w2*8 + w3*2 + w4*3 + w5*0.1) / 20 ≈ 0.2255
      expect(score, greaterThan(0.2));
      print('EDSA driver sensor risk: ${score.toStringAsFixed(4)}');
    });

    test('smooth provincial road driver: minimal events', () {
      final weights = RiskWeights();
      final score = computeSensorRiskScore(
        overspeedingCount: 1,
        harshBrakingCount: 0,
        sharpTurningCount: 1,
        potholeCount: 2,
        totalSlopeDeviation: 0.05,
        totalWindows: 50,
        weights: weights,
      );
      expect(score, lessThan(0.2));
      print('Provincial road sensor risk: ${score.toStringAsFixed(4)}');
    });

    test('contextual adjustment A(t) > 1 amplifies the score', () {
      final weights = RiskWeights();
      final baseScore = computeSensorRiskScore(
        overspeedingCount: 3,
        harshBrakingCount: 3,
        sharpTurningCount: 2,
        potholeCount: 1,
        totalSlopeDeviation: 0.1,
        totalWindows: 20,
        weights: weights,
        contextualAdjustment: 1.0,
      );
      final adjustedScore = computeSensorRiskScore(
        overspeedingCount: 3,
        harshBrakingCount: 3,
        sharpTurningCount: 2,
        potholeCount: 1,
        totalSlopeDeviation: 0.1,
        totalWindows: 20,
        weights: weights,
        contextualAdjustment: 1.3, // heavy traffic context
      );
      expect(adjustedScore, greaterThanOrEqualTo(baseScore));
    });

    test('Antipolo zigzag: high slope deviation contributes to risk', () {
      final weights = RiskWeights();
      final flatScore = computeSensorRiskScore(
        overspeedingCount: 2,
        harshBrakingCount: 2,
        sharpTurningCount: 3,
        potholeCount: 1,
        totalSlopeDeviation: 0.0,
        totalWindows: 20,
        weights: weights,
      );
      final slopeScore = computeSensorRiskScore(
        overspeedingCount: 2,
        harshBrakingCount: 2,
        sharpTurningCount: 3,
        potholeCount: 1,
        totalSlopeDeviation: 2.5, // steep zigzag slopes
        totalWindows: 20,
        weights: weights,
      );
      expect(slopeScore, greaterThan(flatScore));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // GROUP 9 – Report Risk Score
  // Formula: R_rep(t) = Sum(T_i(t) * r_i(t)) / Sum(T_i(t))
  // ──────────────────────────────────────────────────────────────────────────
  group('Report Risk Score', () {
    test('empty reports returns 0', () {
      expect(computeReportRiskScore([]), 0.0);
    });

    test('all passengers rate 5 (most dangerous) -> high risk', () {
      final now = DateTime.now();
      final reports = [
        PassengerReport(riskRating: 5, trust: 0.8, timestamp: now),
        PassengerReport(riskRating: 5, trust: 0.9, timestamp: now),
        PassengerReport(riskRating: 5, trust: 0.7, timestamp: now),
      ];
      final risk = computeReportRiskScore(reports);
      expect(risk, closeTo(1.0, 0.01));
    });

    test('all passengers rate 1 (safest) -> zero risk', () {
      final now = DateTime.now();
      final reports = [
        PassengerReport(riskRating: 1, trust: 0.9, timestamp: now),
        PassengerReport(riskRating: 1, trust: 0.8, timestamp: now),
      ];
      final risk = computeReportRiskScore(reports);
      expect(risk, closeTo(0.0, 0.01));
    });

    test('mixed ratings from multiple commuters – weighted by trust', () {
      final now = DateTime.now();
      // High-trust passenger says risky (5), low-trust says safe (1)
      final reports = [
        PassengerReport(riskRating: 5, trust: 0.9, timestamp: now),
        PassengerReport(riskRating: 1, trust: 0.2, timestamp: now),
      ];
      final risk = computeReportRiskScore(reports);
      // High-trust rating of 5 should dominate
      expect(risk, greaterThan(0.5));
      print(
        'Mixed commuter report risk (trust-weighted): ${risk.toStringAsFixed(4)}',
      );
    });

    test('result is always in [0, 1]', () {
      final now = DateTime.now();
      final reports = [
        PassengerReport(riskRating: 3, trust: 0.5, timestamp: now),
      ];
      final risk = computeReportRiskScore(reports);
      expect(risk, inInclusiveRange(0.0, 1.0));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // GROUP 10 – Adaptive Weight lambda(t)
  // Formula: lambda(t) = N_sensor(t) / (N_sensor(t) + N_report(t))
  // ──────────────────────────────────────────────────────────────────────────
  group('Adaptive Weight lambda(t)', () {
    test('equal data -> lambda = 0.5', () {
      expect(computeAdaptiveWeight(10, 10), 0.5);
    });

    test('sensor only -> lambda = 1.0', () {
      expect(computeAdaptiveWeight(20, 0), 1.0);
    });

    test('report only -> lambda = 0.0', () {
      expect(computeAdaptiveWeight(0, 20), 0.0);
    });

    test('both zero -> defaults to 0.5', () {
      expect(computeAdaptiveWeight(0, 0), 0.5);
    });

    test('early trip: sensor dominates (more readings than reports)', () {
      // Trip just started – many sensor readings, no passenger reports yet
      final lambda = computeAdaptiveWeight(50, 2);
      expect(lambda, greaterThan(0.9));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // GROUP 11 – Trip Risk Score (Nonlinear Fusion)
  // Formula: R_trip = lambda*R_sens + (1-lambda)*R_rep + phi*|R_sens - R_rep|
  // ──────────────────────────────────────────────────────────────────────────
  group('Trip Risk Score – Nonlinear Fusion', () {
    const phi = 0.15; // inconsistency penalty

    test('sensor and report agree on high risk -> very high trip risk', () {
      final risk = computeTripRiskScore(
        sensorRisk: 0.8,
        reportRisk: 0.75,
        adaptiveWeight: 0.6,
        inconsistencyPenalty: phi,
      );
      expect(risk, greaterThan(0.7));
      print('Agreed high risk: ${risk.toStringAsFixed(4)}');
    });

    test('sensor and report agree on low risk -> very low trip risk', () {
      final risk = computeTripRiskScore(
        sensorRisk: 0.1,
        reportRisk: 0.12,
        adaptiveWeight: 0.6,
        inconsistencyPenalty: phi,
      );
      expect(risk, lessThan(0.25));
      print('Agreed low risk: ${risk.toStringAsFixed(4)}');
    });

    test('inconsistency penalty applied when sensor and report disagree', () {
      final consistent = computeTripRiskScore(
        sensorRisk: 0.5,
        reportRisk: 0.5,
        adaptiveWeight: 0.5,
        inconsistencyPenalty: phi,
      );
      final inconsistent = computeTripRiskScore(
        sensorRisk: 0.9, // sensor sees high risk
        reportRisk: 0.1, // passenger says safe
        adaptiveWeight: 0.5,
        inconsistencyPenalty: phi,
      );
      // Inconsistent case should be penalised beyond simple average
      final simpleAverage = (0.9 + 0.1) / 2;
      expect((inconsistent - simpleAverage).abs(), greaterThan(0.05));
      print(
        'Consistent risk: ${consistent.toStringAsFixed(4)}  '
        'Inconsistent: ${inconsistent.toStringAsFixed(4)}',
      );
    });

    test('result always clamped to [0, 1]', () {
      final risk = computeTripRiskScore(
        sensorRisk: 1.0,
        reportRisk: 1.0,
        adaptiveWeight: 1.0,
        inconsistencyPenalty: 1.0, // extreme values
      );
      expect(risk, inInclusiveRange(0.0, 1.0));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // GROUP 12 – Safety Score
  // Formula: S_trip(t) = 100 x (1 - R_trip(t))
  // ──────────────────────────────────────────────────────────────────────────
  group('Safety Score', () {
    test('zero risk -> safety score 100', () {
      expect(computeSafetyScore(0.0), 100);
    });

    test('maximum risk -> safety score 0', () {
      expect(computeSafetyScore(1.0), 0);
    });

    test('moderate EDSA risk (0.4) -> safety score 60', () {
      expect(computeSafetyScore(0.4), 60);
    });

    test('safety score is always in [0, 100]', () {
      expect(computeSafetyScore(0.73), inInclusiveRange(0, 100));
    });

    test('end-to-end: safe driver on Katipunan', () {
      final weights = RiskWeights();
      final sensorRisk = computeSensorRiskScore(
        overspeedingCount: 1,
        harshBrakingCount: 1,
        sharpTurningCount: 2,
        potholeCount: 1,
        totalSlopeDeviation: 0.05,
        totalWindows: 30,
        weights: weights,
      );
      final now = DateTime.now();
      final reports = [
        PassengerReport(riskRating: 2, trust: 0.8, timestamp: now),
        PassengerReport(riskRating: 1, trust: 0.7, timestamp: now),
      ];
      final reportRisk = computeReportRiskScore(reports);
      final lambda = computeAdaptiveWeight(30, reports.length);
      final tripRisk = computeTripRiskScore(
        sensorRisk: sensorRisk,
        reportRisk: reportRisk,
        adaptiveWeight: lambda,
        inconsistencyPenalty: weights.phi,
      );
      final safetyScore = computeSafetyScore(tripRisk);

      print(
        '\n[Katipunan safe driver]\n'
        '  Sensor risk  : ${sensorRisk.toStringAsFixed(4)}\n'
        '  Report risk  : ${reportRisk.toStringAsFixed(4)}\n'
        '  lambda       : ${lambda.toStringAsFixed(4)}\n'
        '  Trip risk    : ${tripRisk.toStringAsFixed(4)}\n'
        '  Safety score : $safetyScore / 100',
      );

      expect(safetyScore, greaterThan(60));
    });

    test('end-to-end: dangerous EDSA driver', () {
      final weights = RiskWeights();
      // Simulated 20-minute EDSA ride with many events
      final thresholds = AdaptiveThresholds();
      thresholds.updateContextFactors(
        roadCondition: 0.6,
        envNoise: 0.5,
        trafficDensity: 1.0,
      );
      final sensorRisk = computeSensorRiskScore(
        overspeedingCount: 8,
        harshBrakingCount: 10,
        sharpTurningCount: 4,
        potholeCount: 6,
        totalSlopeDeviation: 0.2,
        totalWindows: 20,
        weights: weights,
        contextualAdjustment: thresholds.getContextualAdjustment(),
      );
      final now = DateTime.now();
      final reports = [
        PassengerReport(riskRating: 5, trust: 0.85, timestamp: now),
        PassengerReport(riskRating: 4, trust: 0.75, timestamp: now),
        PassengerReport(riskRating: 5, trust: 0.90, timestamp: now),
      ];
      final reportRisk = computeReportRiskScore(reports);
      final lambda = computeAdaptiveWeight(20, reports.length);
      final tripRisk = computeTripRiskScore(
        sensorRisk: sensorRisk,
        reportRisk: reportRisk,
        adaptiveWeight: lambda,
        inconsistencyPenalty: weights.phi,
      );
      final safetyScore = computeSafetyScore(tripRisk);

      print(
        '\n[EDSA dangerous driver]\n'
        '  Sensor risk  : ${sensorRisk.toStringAsFixed(4)}\n'
        '  Report risk  : ${reportRisk.toStringAsFixed(4)}\n'
        '  lambda       : ${lambda.toStringAsFixed(4)}\n'
        '  A(t) context : ${thresholds.getContextualAdjustment().toStringAsFixed(4)}\n'
        '  Trip risk    : ${tripRisk.toStringAsFixed(4)}\n'
        '  Safety score : $safetyScore / 100',
      );

      expect(safetyScore, lessThan(50));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // GROUP 13 – Trust Scoring: Consistency Score
  // ──────────────────────────────────────────────────────────────────────────
  group('Trust Scoring – Consistency', () {
    test('new user (no history) -> default 0.5 trust', () {
      expect(
        TrustScoringService.calculateConsistencyScore(
          historicalSeverities: [],
          currentSeverity: 3,
        ),
        0.5,
      );
    });

    test('consistent reporter -> high consistency score', () {
      // Always reports severity 3 – very consistent
      final score = TrustScoringService.calculateConsistencyScore(
        historicalSeverities: [3, 3, 3, 3, 3],
        currentSeverity: 3,
      );
      expect(score, greaterThan(0.9));
    });

    test('inconsistent reporter -> lower consistency score', () {
      // Wildly oscillating between 1 and 5
      final score = TrustScoringService.calculateConsistencyScore(
        historicalSeverities: [1, 5, 1, 5, 1],
        currentSeverity: 5,
      );
      expect(score, lessThan(0.5));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // GROUP 14 – Trust Scoring: Anomaly Detection (z-score)
  // ──────────────────────────────────────────────────────────────────────────
  group('Trust Scoring – Anomaly Detection', () {
    test('not enough data -> no anomaly flagged', () {
      expect(
        TrustScoringService.calculateAnomalyScore(
          historicalSeverities: [3],
          currentSeverity: 5,
        ),
        0.0,
      );
    });

    test('z-score far from mean -> high anomaly score', () {
      // History is mostly 2 with slight variation; reporting 5 = extreme outlier.
      // Using a list with variance so stdDev != 0 and the sigmoid path is taken.
      // mean ≈ 2.17, stdDev ≈ 0.37 → zScore ≈ 7.6 → anomaly ≈ 0.9995
      final score = TrustScoringService.calculateAnomalyScore(
        historicalSeverities: [2, 2, 2, 2, 2, 3],
        currentSeverity: 5,
      );
      expect(score, greaterThan(0.8));
    });

    test('current severity near historical mean -> low anomaly', () {
      // mean ≈ 3.17, stdDev ≈ 0.37 → zScore ≈ 0.45 → sigmoid ≈ 0.61
      // Score is between 0.5–0.65 (slightly above 0.5 baseline = low anomaly)
      final score = TrustScoringService.calculateAnomalyScore(
        historicalSeverities: [3, 3, 3, 3, 4, 3],
        currentSeverity: 3,
      );
      expect(score, lessThan(0.65));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // GROUP 15 – Trust Scoring: Sensor Alignment
  // ──────────────────────────────────────────────────────────────────────────
  group('Trust Scoring – Sensor Alignment', () {
    test('no sensor events + high severity report -> low trust (0.2)', () {
      expect(
        TrustScoringService.calculateSensorAlignmentScore(
          reportSeverity: 5,
          detectedEventCount: 0,
          averageSensorRisk: 0.05,
        ),
        0.2,
      );
    });

    test('many events + high severity -> high trust (~0.95)', () {
      expect(
        TrustScoringService.calculateSensorAlignmentScore(
          reportSeverity: 5,
          detectedEventCount: 8,
          averageSensorRisk: 0.85,
        ),
        0.95,
      );
    });

    test('moderate alignment gives score in [0, 1]', () {
      final score = TrustScoringService.calculateSensorAlignmentScore(
        reportSeverity: 3,
        detectedEventCount: 4,
        averageSensorRisk: 0.5,
      );
      expect(score, inInclusiveRange(0.0, 1.0));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // GROUP 16 – Trust Scoring: Overall Trust
  // Weights: 20% frequency, 35% consistency, 25% anomaly (inverse), 20% sensor alignment
  // ──────────────────────────────────────────────────────────────────────────
  group('Trust Scoring – Overall Trust', () {
    test('perfect consistency, no anomaly, full alignment -> high trust', () {
      // totalReports=50 gives F(50)~0.964 so all four components are near max.
      final trust = TrustScoringService.calculateOverallTrust(
        consistencyScore: 1.0,
        anomalyScore: 0.0,
        sensorAlignmentScore: 1.0,
        totalReports: 50,
      );
      expect(trust, closeTo(1.0, 0.05));
    });

    test('zero consistency, high anomaly, zero alignment -> near-zero trust', () {
      final trust = TrustScoringService.calculateOverallTrust(
        consistencyScore: 0.0,
        anomalyScore: 1.0,
        sensorAlignmentScore: 0.0,
      );
      expect(trust, lessThan(0.15));
    });

    test('verification history boosts trust', () {
      final baseTrust = TrustScoringService.calculateOverallTrust(
        consistencyScore: 0.6,
        anomalyScore: 0.2,
        sensorAlignmentScore: 0.7,
      );
      final boostedTrust = TrustScoringService.calculateOverallTrust(
        consistencyScore: 0.6,
        anomalyScore: 0.2,
        sensorAlignmentScore: 0.7,
        verifiedCount: 20,
        flaggedCount: 0,
      );
      expect(boostedTrust, greaterThanOrEqualTo(baseTrust));
    });

    test('many flags reduce trust', () {
      final baseTrust = TrustScoringService.calculateOverallTrust(
        consistencyScore: 0.6,
        anomalyScore: 0.2,
        sensorAlignmentScore: 0.7,
      );
      final penalisedTrust = TrustScoringService.calculateOverallTrust(
        consistencyScore: 0.6,
        anomalyScore: 0.2,
        sensorAlignmentScore: 0.7,
        verifiedCount: 1,
        flaggedCount: 19,
      );
      expect(penalisedTrust, lessThanOrEqualTo(baseTrust));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // GROUP 17 – Trust Scoring: Suspicious Pattern Detection
  // ──────────────────────────────────────────────────────────────────────────
  group('Trust Scoring – Suspicious Pattern Detection', () {
    test('not enough reports -> no suspicious flag', () {
      expect(
        TrustScoringService.detectSuspiciousPattern(
          historicalSeverities: [3],
          currentSeverity: 5,
          flaggedCount: 0,
          totalReports: 2,
        ),
        isFalse,
      );
    });

    test('excessive flagging (>30%) -> suspicious', () {
      expect(
        TrustScoringService.detectSuspiciousPattern(
          historicalSeverities: [3, 3, 3, 3, 3],
          currentSeverity: 3,
          flaggedCount: 4,
          totalReports: 10,
        ),
        isTrue,
      );
    });

    test('extreme oscillation (1->5->1->5->1) -> suspicious', () {
      expect(
        TrustScoringService.detectSuspiciousPattern(
          historicalSeverities: [1, 5, 1, 5, 1],
          currentSeverity: 5,
          flaggedCount: 0,
          totalReports: 10,
        ),
        isTrue,
      );
    });

    test('consistent normal reporter -> not suspicious', () {
      expect(
        TrustScoringService.detectSuspiciousPattern(
          historicalSeverities: [3, 3, 2, 3, 3, 2, 3],
          currentSeverity: 3,
          flaggedCount: 0,
          totalReports: 10,
        ),
        isFalse,
      );
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // GROUP 18 – Trust Time Decay
  // Formula: weight = 2^(-days / halfLife)
  // ──────────────────────────────────────────────────────────────────────────
  group('Trust Scoring – Time Decay', () {
    test('fresh report (same day) -> near max weight', () {
      final now = DateTime.now();
      final decay = TrustScoringService.calculateTimeDecay(
        reportTime: now,
        referenceTime: now,
      );
      expect(decay, closeTo(1.0, 0.01));
    });

    test('30-day-old report -> half weight (half-life = 30 days)', () {
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));
      final decay = TrustScoringService.calculateTimeDecay(
        reportTime: thirtyDaysAgo,
        referenceTime: now,
      );
      expect(decay, closeTo(0.5, 0.05));
    });

    test('very old report (1 year) -> minimum weight (0.1)', () {
      final now = DateTime.now();
      final veryOld = now.subtract(const Duration(days: 365));
      final decay = TrustScoringService.calculateTimeDecay(
        reportTime: veryOld,
        referenceTime: now,
      );
      expect(decay, closeTo(0.1, 0.01));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // GROUP 19 – RiskWeights Normalisation
  // Ensures w1 + w2 + w3 + w4 + w5 = 1.0
  // ──────────────────────────────────────────────────────────────────────────
  group('RiskWeights Normalisation', () {
    test('weights sum to exactly 1.0 after normalisation', () {
      final weights = RiskWeights();
      final total =
          weights.w1 + weights.w2 + weights.w3 + weights.w4 + weights.w5;
      expect(total, closeTo(1.0, 0.0001));
    });

    test('all weights are positive', () {
      final weights = RiskWeights();
      expect(weights.w1, greaterThan(0));
      expect(weights.w2, greaterThan(0));
      expect(weights.w3, greaterThan(0));
      expect(weights.w4, greaterThan(0));
      expect(weights.w5, greaterThan(0));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // GROUP 20 – Legacy computeRiskScore (backward compat)
  // ──────────────────────────────────────────────────────────────────────────
  group('Legacy Risk Score (backward compatibility)', () {
    test('all zero -> low legacy risk score', () {
      final score = computeRiskScore(
        speedingCount: 0,
        brakingCount: 0,
        turningCount: 0,
        reportSeveritySum: 0,
      );
      expect(score, lessThan(20));
    });

    test('high counts -> high legacy risk score', () {
      final score = computeRiskScore(
        speedingCount: 10,
        brakingCount: 10,
        turningCount: 5,
        reportSeveritySum: 20,
      );
      expect(score, greaterThan(10));
    });

    test('output is within [0, 100]', () {
      final score = computeRiskScore(
        speedingCount: 999,
        brakingCount: 999,
        turningCount: 999,
        reportSeveritySum: 25,
      );
      expect(score, inInclusiveRange(0, 100));
    });
  });
}

import 'dart:math';

/// Sensor reading at a time step
class SensorReading {
  final double speed; // v(k)
  final double accelX; // ax(k)
  final double accelY; // ay(k)
  final double accelZ; // az(k)
  final double gyroX; // gx(k)
  final double gyroY; // gy(k)
  final double gyroZ; // gz(k)
  final double? altitude; // h(k)
  final double? distance; // d(k) - distance traveled
  final DateTime timestamp;

  SensorReading({
    required this.speed,
    required this.accelX,
    required this.accelY,
    required this.accelZ,
    required this.gyroX,
    required this.gyroY,
    required this.gyroZ,
    this.altitude,
    this.distance,
    required this.timestamp,
  });
}

/// Adaptive thresholds for event detection
class AdaptiveThresholds {
  // Base thresholds
  double thetaSpeedingBase =
      40.0; // km/h default for through streets / boulevards
  double thetaBrakingBase = -8.0; // m/s²
  double thetaTurningBase =
      4.5; // rad/s - raised to avoid false positives from phone handling/body movement
  double thetaPothole = 2.5; // m/s² vertical acceleration
  double thetaGyroStable = 0.8; // rad/s
  double thetaSpeedMin = 5.0; // minimum speed for pothole detection

  // Context factors
  double contextRoad = 1.0; // C_r(t): road condition factor
  double contextVehicle = 1.0; // C_v(t): vehicle type factor
  double contextTraffic = 1.0; // C_t(t): traffic condition factor

  /// Get adaptive threshold: θ(t) = θ0 * C_r(t) * C_v(t) * C_t(t)
  double getAdaptiveThreshold(double baseThreshold) {
    return baseThreshold * contextRoad * contextVehicle * contextTraffic;
  }

  /// Update context factors (0.8 - 1.2 range)
  void updateContextFactors({
    required double roadCondition,
    required double vehicleType,
    required double trafficLevel,
  }) {
    contextRoad = 0.8 + (roadCondition * 0.4);
    contextVehicle = 0.8 + (vehicleType * 0.4);
    contextTraffic = 0.8 + (trafficLevel * 0.4);
  }

  /// Get thresholds for event detection
  double get speedingThreshold => getAdaptiveThreshold(thetaSpeedingBase);
  double get brakingThreshold => getAdaptiveThreshold(thetaBrakingBase);
  double get turningThreshold => getAdaptiveThreshold(thetaTurningBase);
}

/// Weights for risk score computation
class RiskWeights {
  double w1 = 0.25; // Overspeeding weight
  double w2 = 0.30; // Harsh braking weight
  double w3 = 0.20; // Sharp turning weight
  double w4 = 0.15; // Pothole weight
  double w5 = 0.10; // Slope weight
  double phi = 0.15; // Inconsistency penalty weight

  RiskWeights() {
    // Normalize: w1 + w2 + w3 + w4 + w5 = 1
    final sum = w1 + w2 + w3 + w4 + w5;
    w1 /= sum;
    w2 /= sum;
    w3 /= sum;
    w4 /= sum;
    w5 /= sum;
  }
}

/// Passenger report data
class PassengerReport {
  final int riskRating; // r_i(t): 1-5 scale
  final double trust; // T_i(t): 0-1 scale
  final DateTime timestamp;

  PassengerReport({
    required this.riskRating,
    required this.trust,
    required this.timestamp,
  });
}

/// Computed sensor metrics for a window
class WindowMetrics {
  final double averageSpeed; // v_w
  final double maxAngularVelocity; // g_w_max
  final List<double> speedVariations; // Δv(k) values
  final double maxSpeedDeceleration; // Most negative speed change
  final List<SensorReading> readings;

  WindowMetrics({
    required this.averageSpeed,
    required this.maxAngularVelocity,
    required this.speedVariations,
    required this.maxSpeedDeceleration,
    required this.readings,
  });

  bool get hasOverspeeding =>
      averageSpeed > 40.0; // km/h default overspeeding threshold
  bool get hasHarshBraking =>
      maxSpeedDeceleration < -5.0; // Harsh braking threshold
  bool get hasSharpTurning => maxAngularVelocity > 4.5; // Sharp turn threshold
}

/// Sensor magnitude computation
/// a(k) = √(ax(k)² + ay(k)² + az(k)²)
double computeAccelerationMagnitude(double ax, double ay, double az) {
  return sqrt(ax * ax + ay * ay + az * az);
}

/// g(k) = √(gx(k)² + gy(k)² + gz(k)²)
double computeGyroMagnitude(double gx, double gy, double gz) {
  return sqrt(gx * gx + gy * gy + gz * gz);
}

/// Moving average filter
/// x̃(k) = (1/M) * Σ(x(k-i)) for i=0 to M-1
double movingAverageFilter(List<double> values, int filterWindow) {
  if (values.isEmpty) return 0.0;
  final window = min(filterWindow, values.length).toInt();
  final sum = values.sublist(values.length - window).fold(0.0, (a, b) => a + b);
  return sum / window;
}

/// Pothole detection: P(k) = 1 if az(k) > θ_p AND g(k) < θ_g AND v(k) > θ_v
bool detectPothole({
  required double verticalAccel,
  required double gyroMagnitude,
  required double speed,
  required AdaptiveThresholds thresholds,
}) {
  return verticalAccel > thresholds.thetaPothole &&
      gyroMagnitude < thresholds.thetaGyroStable &&
      speed > thresholds.thetaSpeedMin;
}

/// Slope computation: S(t) = (h(t) - h(t-1)) / d(t)
double computeSlope({
  required double currentAltitude,
  required double previousAltitude,
  required double distanceTraveled,
}) {
  if (distanceTraveled == 0) return 0.0;
  return (currentAltitude - previousAltitude) / distanceTraveled;
}

/// Extract metrics from a sliding window
WindowMetrics extractWindowMetrics(
  List<SensorReading> windowReadings,
  int filterWindow,
) {
  if (windowReadings.isEmpty) {
    return WindowMetrics(
      averageSpeed: 0,
      maxAngularVelocity: 0,
      speedVariations: [],
      maxSpeedDeceleration: 0,
      readings: [],
    );
  }

  // v_w: average speed in window
  final speedSum = windowReadings.fold(0.0, (sum, r) => sum + r.speed);
  final averageSpeed = speedSum / windowReadings.length;

  // g_w_max: maximum angular velocity in window
  double maxAngularVelocity = 0;
  for (final reading in windowReadings) {
    final gyroMag = computeGyroMagnitude(
      reading.gyroX,
      reading.gyroY,
      reading.gyroZ,
    );
    maxAngularVelocity = max(maxAngularVelocity, gyroMag);
  }

  // Δv(k): speed variations
  final speedVariations = <double>[];
  for (int i = 1; i < windowReadings.length; i++) {
    speedVariations.add(windowReadings[i].speed - windowReadings[i - 1].speed);
  }

  final maxSpeedDeceleration = speedVariations.isEmpty
      ? 0.0
      : speedVariations.reduce((a, b) => a < b ? a : b);

  return WindowMetrics(
    averageSpeed: averageSpeed,
    maxAngularVelocity: maxAngularVelocity,
    speedVariations: speedVariations,
    maxSpeedDeceleration: maxSpeedDeceleration,
    readings: windowReadings,
  );
}

/// Event detection: E_v(w) = 1 if v_w > θ_v
bool detectOverspeeding(double windowSpeed, AdaptiveThresholds thresholds) {
  return windowSpeed >
      thresholds.getAdaptiveThreshold(thresholds.thetaSpeedingBase);
}

/// Event detection: E_b(w) = 1 if Δv(k) < -θ_b
bool detectHarshBraking(double maxDeceleration, AdaptiveThresholds thresholds) {
  return maxDeceleration <
      thresholds.getAdaptiveThreshold(thresholds.thetaBrakingBase);
}

/// Event detection: E_g(w) = 1 if g_w_max > θ_g
bool detectSharpTurning(
  double maxAngularVelocity,
  AdaptiveThresholds thresholds,
) {
  return maxAngularVelocity >
      thresholds.getAdaptiveThreshold(thresholds.thetaTurningBase);
}

/// Compute sensor-based risk score
/// R_sens(t) = (w1*C_v + w2*C_b + w3*C_g + w4*P(t) + w5*|S(t)|) / W_total
double computeSensorRiskScore({
  required int overspeedingCount, // C_v
  required int harshBrakingCount, // C_b
  required int sharpTurningCount, // C_g
  required int potholeCount, // P(t)
  required double totalSlopeDeviation, // |S(t)|
  required int totalWindows,
  required RiskWeights weights,
}) {
  if (totalWindows == 0) return 0.0;

  final riskScore =
      (weights.w1 * overspeedingCount +
          weights.w2 * harshBrakingCount +
          weights.w3 * sharpTurningCount +
          weights.w4 * potholeCount +
          weights.w5 * totalSlopeDeviation) /
      totalWindows;

  return (riskScore).clamp(0.0, 1.0);
}

/// Compute report-based risk score
/// R_rep(t) = Σ(T_i(t) * r_i(t)) / Σ(T_i(t))
double computeReportRiskScore(List<PassengerReport> reports) {
  if (reports.isEmpty) return 0.0;

  double weightedSum = 0;
  double trustSum = 0;

  for (final report in reports) {
    // Normalize rating from 1-5 to 0-1 risk scale (inverse)
    final riskValue = (report.riskRating - 1) / 4;
    weightedSum += report.trust * riskValue;
    trustSum += report.trust;
  }

  if (trustSum == 0) return 0.0;
  return (weightedSum / trustSum).clamp(0.0, 1.0);
}

/// Adaptive weight for sensor vs report data
/// λ(t) = N_sensor(t) / (N_sensor(t) + N_report(t))
double computeAdaptiveWeight(int sensorDataPoints, int reportDataPoints) {
  final total = sensorDataPoints + reportDataPoints;
  if (total == 0) return 0.5; // Default to equal weight
  return sensorDataPoints / total;
}

/// Compute trip-level risk using nonlinear fusion
/// R_trip(t) = λ(t)*R_sens(t) + (1-λ(t))*R_rep(t) + φ*|R_sens(t) - R_rep(t)|
double computeTripRiskScore({
  required double sensorRisk,
  required double reportRisk,
  required double adaptiveWeight,
  required double inconsistencyPenalty,
}) {
  final weightedRisk =
      adaptiveWeight * sensorRisk +
      (1 - adaptiveWeight) * reportRisk +
      inconsistencyPenalty * (sensorRisk - reportRisk).abs();

  return weightedRisk.clamp(0.0, 1.0);
}

/// Compute final safety score (0-100)
/// S_trip(t) = 100 * (1 - R_trip(t))
int computeSafetyScore(double tripRisk) {
  final safetyScore = 100 * (1 - tripRisk);
  return safetyScore.toInt().clamp(0, 100);
}

/// Utility class for sliding window analysis
class SlidingWindow {
  final int size;
  final List<double> _values = [];

  SlidingWindow({required this.size});

  void add(double value) {
    _values.add(value);
    if (_values.length > size) {
      _values.removeAt(0);
    }
  }

  double get average {
    if (_values.isEmpty) return 0.0;
    return _values.fold(0.0, (sum, val) => sum + val) / _values.length;
  }

  double get max {
    if (_values.isEmpty) return 0.0;
    return _values.reduce((a, b) => a > b ? a : b);
  }

  double get min {
    if (_values.isEmpty) return 0.0;
    return _values.reduce((a, b) => a < b ? a : b);
  }

  List<double> get values => List.unmodifiable(_values);

  void clear() {
    _values.clear();
  }
}

/// Unsafe event type enumeration
enum UnsafeEventType { speeding, braking, turning }

/// Represents an unsafe driving event
class UnsafeEvent {
  const UnsafeEvent({required this.type, required this.timestamp});

  final UnsafeEventType type;
  final DateTime timestamp;
}

/// Legacy function for backward compatibility
int computeRiskScore({
  required int speedingCount,
  required int brakingCount,
  required int turningCount,
  required int reportSeveritySum,
}) {
  final weights = RiskWeights();

  // Compute sensor-based risk using legacy counts
  final sensorRisk = computeSensorRiskScore(
    overspeedingCount: speedingCount,
    harshBrakingCount: brakingCount,
    sharpTurningCount: turningCount,
    potholeCount: 0,
    totalSlopeDeviation: 0,
    totalWindows: max(1, speedingCount + brakingCount + turningCount).toInt(),
    weights: weights,
  );

  // Compute report-based risk from severity sum (1-5 normalized to 0-1)
  final reportRisk = ((reportSeveritySum / 25.0)).clamp(0.0, 1.0);

  // Adaptive weight (default to equal since no specific data count)
  final adaptiveWeight = 0.6; // Favor sensor data

  // Compute trip risk with nonlinear fusion
  final tripRisk = computeTripRiskScore(
    sensorRisk: sensorRisk,
    reportRisk: reportRisk,
    adaptiveWeight: adaptiveWeight,
    inconsistencyPenalty: weights.phi,
  );

  // Convert to safety score and scale for display
  final safetyScore = computeSafetyScore(tripRisk);
  return 100 - safetyScore; // Return as risk score (0-100)
}

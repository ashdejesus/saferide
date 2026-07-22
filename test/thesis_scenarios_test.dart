import 'package:flutter_test/flutter_test.dart';
import 'package:saferide/services/risk_scoring.dart';

void main() {
  group('Thesis Scenarios - Vehicle Types & Adaptive Thresholds', () {
    test('Jeepney threshold scaling (Base Multiplier 1.00)', () {
      final thresholds = AdaptiveThresholds();
      thresholds.vehicleMultiplier = VehicleType.jeepney.multiplier;
      
      expect(thresholds.speedingThreshold, closeTo(40.0, 0.01));
      expect(thresholds.brakingThreshold, closeTo(-8.0, 0.01));
    });

    test('Bus threshold scaling (Base Multiplier 1.20 - More lenient for heavy vehicles)', () {
      final thresholds = AdaptiveThresholds();
      thresholds.vehicleMultiplier = VehicleType.bus.multiplier;
      
      // Bus is allowed slightly higher thresholds before it's considered "unsafe"
      // or vice-versa depending on tuning. Here 40 * 1.2 = 48.0
      expect(thresholds.speedingThreshold, closeTo(48.0, 0.01));
      expect(thresholds.brakingThreshold, closeTo(-9.6, 0.01)); 
    });

    test('Tricycle threshold scaling (Base Multiplier 0.85 - Stricter for light vehicles)', () {
      final thresholds = AdaptiveThresholds();
      thresholds.vehicleMultiplier = VehicleType.tricycle.multiplier;
      
      // 40 * 0.85 = 34.0
      expect(thresholds.speedingThreshold, closeTo(34.0, 0.01));
      expect(thresholds.brakingThreshold, closeTo(-6.8, 0.01));
    });

    test('Contextual Context: Tricycle on poor barangay road with high noise', () {
      final thresholds = AdaptiveThresholds();
      thresholds.vehicleMultiplier = VehicleType.tricycle.multiplier;
      
      // Poor road (0.0), High noise (1.0), light traffic (0.0)
      thresholds.updateContextFactors(roadCondition: 0.0, envNoise: 1.0, trafficDensity: 0.0);
      
      // A(t) = 1 + α(0) + β(0) + γ(1.0) = 1 + 0.1 = 1.1
      final expectedSpeeding = 40.0 * 0.85 * 1.1; // 37.4
      expect(thresholds.speedingThreshold, closeTo(37.4, 0.01));
    });
  });

  group('Thesis Scenarios - End-to-End Trip Risk Assessment', () {
    test('Scenario 1: Jeepney on EDSA - Heavy Traffic, Frequent Braking', () {
      final thresholds = AdaptiveThresholds();
      thresholds.vehicleMultiplier = VehicleType.jeepney.multiplier;
      // Moderate road, high noise, heavy traffic
      thresholds.updateContextFactors(roadCondition: 0.5, envNoise: 0.8, trafficDensity: 0.9);
      
      final weights = RiskWeights();
      
      // Jeepney has a lot of harsh braking events due to traffic, but rarely overspeeds
      final sensorRisk = computeSensorRiskScore(
        overspeedingCount: 1, 
        harshBrakingCount: 15, // lots of stop-and-go
        sharpTurningCount: 3, 
        potholeCount: 2, 
        totalSlopeDeviation: 0.1, 
        totalWindows: 30, // 30 windows total
        weights: weights,
        contextualAdjustment: thresholds.getContextualAdjustment(),
      );

      // Passengers report moderate risk due to jerky ride
      final now = DateTime.now();
      final reports = [
        PassengerReport(riskRating: 3, trust: 0.9, timestamp: now),
        PassengerReport(riskRating: 4, trust: 0.8, timestamp: now),
      ];
      final reportRisk = computeReportRiskScore(reports);
      final lambda = computeAdaptiveWeight(21, reports.length); // 21 events

      final tripRisk = computeTripRiskScore(
        sensorRisk: sensorRisk, 
        reportRisk: reportRisk, 
        adaptiveWeight: lambda, 
        inconsistencyPenalty: weights.phi
      );
      
      final safetyScore = computeSafetyScore(tripRisk);

      // We expect the score to be noticeably impacted by the harsh braking
      expect(safetyScore, lessThan(85));
    });

    test('Scenario 2: Provincial Bus on NLEX - High Speed, Smooth Road', () {
      final thresholds = AdaptiveThresholds();
      thresholds.vehicleMultiplier = VehicleType.bus.multiplier;
      // Good road, moderate noise, light traffic
      thresholds.updateContextFactors(roadCondition: 0.9, envNoise: 0.4, trafficDensity: 0.2);
      
      final weights = RiskWeights();
      
      // Bus goes fast, but rarely brakes harshly or turns sharply
      final sensorRisk = computeSensorRiskScore(
        overspeedingCount: 8, // Several overspeeding windows
        harshBrakingCount: 0, 
        sharpTurningCount: 0, 
        potholeCount: 0, 
        totalSlopeDeviation: 0.05, 
        totalWindows: 40, 
        weights: weights,
        contextualAdjustment: thresholds.getContextualAdjustment(),
      );

      // Passengers feel very safe
      final now = DateTime.now();
      final reports = [
        PassengerReport(riskRating: 1, trust: 0.95, timestamp: now),
        PassengerReport(riskRating: 2, trust: 0.85, timestamp: now),
        PassengerReport(riskRating: 1, trust: 0.9, timestamp: now),
      ];
      final reportRisk = computeReportRiskScore(reports);
      final lambda = computeAdaptiveWeight(8, reports.length); 

      final tripRisk = computeTripRiskScore(
        sensorRisk: sensorRisk, 
        reportRisk: reportRisk, 
        adaptiveWeight: lambda, 
        inconsistencyPenalty: weights.phi
      );
      
      final safetyScore = computeSafetyScore(tripRisk);

      // Bus is mostly safe, but overspeeding lowers score slightly. 
      // High discrepancy between passenger (safe) and sensor (overspeed) adds inconsistency penalty.
      expect(safetyScore, greaterThan(65));
      expect(safetyScore, lessThan(95));
    });

    test('Scenario 3: Tricycle in Barangay - Potholes and Sharp Turns', () {
      final thresholds = AdaptiveThresholds();
      thresholds.vehicleMultiplier = VehicleType.tricycle.multiplier;
      // Poor road (potholes), low noise, light traffic
      thresholds.updateContextFactors(roadCondition: 0.1, envNoise: 0.2, trafficDensity: 0.1);
      
      final weights = RiskWeights();
      
      // Tricycle has to evade potholes -> sharp turns and hits some potholes
      final sensorRisk = computeSensorRiskScore(
        overspeedingCount: 0, 
        harshBrakingCount: 2, 
        sharpTurningCount: 12, // Evading
        potholeCount: 8, // Hitting
        totalSlopeDeviation: 0.1, 
        totalWindows: 20, 
        weights: weights,
        contextualAdjustment: thresholds.getContextualAdjustment(),
      );

      // Passengers complain about bumpy ride
      final now = DateTime.now();
      final reports = [
        PassengerReport(riskRating: 4, trust: 0.7, timestamp: now),
        PassengerReport(riskRating: 5, trust: 0.8, timestamp: now),
      ];
      final reportRisk = computeReportRiskScore(reports);
      final lambda = computeAdaptiveWeight(22, reports.length); 

      final tripRisk = computeTripRiskScore(
        sensorRisk: sensorRisk, 
        reportRisk: reportRisk, 
        adaptiveWeight: lambda, 
        inconsistencyPenalty: weights.phi
      );
      
      final safetyScore = computeSafetyScore(tripRisk);

      // Tricycle safety score should be relatively low due to poor conditions
      expect(safetyScore, lessThan(60));
    });
  });

  group('Thesis Scenarios - Edge Cases & Fusion Penalty', () {
    test('High Inconsistency between Sensor and Report triggers penalty', () {
      final weights = RiskWeights();
      // Sensor thinks trip is extremely safe
      final sensorRisk = 0.05; 
      // Passengers think trip is extremely dangerous (maybe driver was texting, not captured by IMU)
      final reportRisk = 0.90; 
      
      final lambda = 0.5; // Equal weight

      final tripRisk = computeTripRiskScore(
        sensorRisk: sensorRisk, 
        reportRisk: reportRisk, 
        adaptiveWeight: lambda, 
        inconsistencyPenalty: weights.phi // 0.30
      );

      final expectedBase = (0.5 * 0.05) + (0.5 * 0.90); // 0.475
      final expectedPenalty = 0.30 * (0.05 - 0.90).abs(); // 0.30 * 0.85 = 0.255
      final expectedTotal = expectedBase + expectedPenalty; // 0.73
      
      expect(tripRisk, closeTo(expectedTotal, 0.01));
    });
  });
}

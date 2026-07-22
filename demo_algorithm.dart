import 'dart:io';
import 'dart:math';
import 'package:saferide/services/risk_scoring.dart';

void main() {
  print('======================================================');
  print('    SAFERIDE FULL ALGORITHM INTERACTIVE DEMO          ');
  print('======================================================\n');
  
  final thresholds = AdaptiveThresholds();
  
  // ---------------------------------------------------------
  // 1. VEHICLE CONTEXT
  // ---------------------------------------------------------
  print('--- 1. VEHICLE CONTEXT ---');
  print('Select Vehicle Type:');
  print('1. Jeepney (Multiplier: 1.00)');
  print('2. Bus (Multiplier: 1.20)');
  print('3. Tricycle (Multiplier: 0.85)');
  stdout.write('Enter choice (1-3): ');
  final choice = stdin.readLineSync();
  
  String vehicleName = 'Jeepney';
  if (choice == '2') {
    thresholds.vehicleMultiplier = VehicleType.bus.multiplier;
    vehicleName = 'Bus';
  } else if (choice == '3') {
    thresholds.vehicleMultiplier = VehicleType.tricycle.multiplier;
    vehicleName = 'Tricycle';
  } else {
    thresholds.vehicleMultiplier = VehicleType.jeepney.multiplier;
  }
  
  print('\n[SYSTEM] Vehicle set to $vehicleName.');

  // ---------------------------------------------------------
  // 2. ENVIRONMENTAL CONTEXT A(t)
  // ---------------------------------------------------------
  print('\n--- 2. ENVIRONMENTAL CONTEXT ---');
  print('This adjusts thresholds based on environment (Formula A(t))');
  
  stdout.write('Enter Road Condition R_c (0.0 = Poor, 1.0 = Good): ');
  final roadInput = double.tryParse(stdin.readLineSync() ?? '0.5') ?? 0.5;
  
  stdout.write('Enter Traffic Density T_d (0.0 = Light, 1.0 = Heavy): ');
  final trafficInput = double.tryParse(stdin.readLineSync() ?? '0.5') ?? 0.5;

  stdout.write('Enter Env Noise E_n (0.0 = Quiet, 1.0 = Loud): ');
  final noiseInput = double.tryParse(stdin.readLineSync() ?? '0.5') ?? 0.5;

  thresholds.updateContextFactors(roadCondition: roadInput, trafficDensity: trafficInput, envNoise: noiseInput);
  
  print('\n[SYSTEM] Formula: A(t) = 1.0 + (1.0 - R_c)*0.2 + (T_d)*0.2 + (E_n)*0.1');
  print('[SYSTEM] Contextual Adjustment A(t) = ${thresholds.getContextualAdjustment().toStringAsFixed(2)}');
  print('[SYSTEM] Adaptive Speeding Threshold: ${thresholds.speedingThreshold.toStringAsFixed(2)} km/h');
  print('[SYSTEM] Adaptive Braking Threshold: ${thresholds.brakingThreshold.toStringAsFixed(2)} m/s²');
  print('[SYSTEM] Adaptive Turning Threshold: ${thresholds.turningThreshold.toStringAsFixed(2)} rad/s\n');

  // ---------------------------------------------------------
  // 3. SLIDING WINDOW (GPS + IMU SENSORS)
  // ---------------------------------------------------------
  print('--- 3. SLIDING WINDOW SENSOR SIMULATION ---');
  print('We will simulate a 3-second sliding window.');
  
  final readings = <SensorReading>[];
  for (int i = 1; i <= 3; i++) {
    print('\n> Second $i Readings:');
    
    stdout.write('  GPS Speed (km/h): ');
    final speed = double.tryParse(stdin.readLineSync() ?? '0') ?? 0.0;
    
    stdout.write('  Z-Axis Acceleration (m/s²) [9.8 = Flat, >12 = Pothole]: ');
    final zAccel = double.tryParse(stdin.readLineSync() ?? '9.8') ?? 9.8;
    
    stdout.write('  Z-Axis Gyroscope (rad/s) [0.0 = Straight, >4.5 = Sharp Turn]: ');
    final zGyro = double.tryParse(stdin.readLineSync() ?? '0') ?? 0.0;
    
    readings.add(SensorReading(
      speed: speed,
      accelX: 0, accelY: 0, accelZ: zAccel,
      gyroX: 0, gyroY: 0, gyroZ: zGyro,
      timestamp: DateTime.now().add(Duration(seconds: i)),
    ));
  }
  
  // ---------------------------------------------------------
  // 4. WINDOW PROCESSING & EVENT DETECTION
  // ---------------------------------------------------------
  print('\n--- 4. PROCESSING WINDOW METRICS & EVENT DETECTION ---');
  final metrics = extractWindowMetrics(readings, 3);
  
  print('=> Window Average Speed: ${metrics.averageSpeed.toStringAsFixed(2)} km/h');
  print('=> Max Deceleration (Δv): ${metrics.maxSpeedDeceleration.toStringAsFixed(2)} m/s²');
  print('=> Max Angular Velocity: ${metrics.maxAngularVelocity.toStringAsFixed(2)} rad/s\n');
  
  final isSpeeding = detectOverspeeding(metrics.averageSpeed, thresholds);
  final isBraking = detectHarshBraking(metrics.maxSpeedDeceleration, thresholds);
  final isTurning = detectSharpTurning(metrics.maxAngularVelocity, thresholds);
  
  // Pothole check: check if any reading breached vertical accel
  bool isPothole = false;
  for (var r in readings) {
    // We subtract gravity (9.8) to get the linear vertical acceleration
    final linearVerticalAccel = (r.accelZ - 9.8).abs();
    if (detectPothole(
      verticalAccel: linearVerticalAccel, 
      gyroMagnitude: computeGyroMagnitude(r.gyroX, r.gyroY, r.gyroZ), 
      speed: r.speed, 
      thresholds: thresholds)) {
        isPothole = true;
        break;
    }
  }

  print(isSpeeding ? '⚠️  ALERT: Overspeeding Detected!' : '✅  Speeding: OK');
  print(isBraking ? '⚠️  ALERT: Harsh Braking Detected!' : '✅  Braking: OK');
  print(isTurning ? '⚠️  ALERT: Sharp Turning Detected!' : '✅  Turning: OK');
  print(isPothole ? '⚠️  ALERT: Pothole Impact Detected!' : '✅  Road Impact: OK');
  
  // ---------------------------------------------------------
  // 5. SENSOR RISK SCORING (R_sens)
  // ---------------------------------------------------------
  print('\n--- 5. SENSOR RISK SCORING (R_sens) ---');
  final weights = RiskWeights();
  final sensorRisk = computeSensorRiskScore(
    overspeedingCount: isSpeeding ? 1 : 0,
    harshBrakingCount: isBraking ? 1 : 0,
    sharpTurningCount: isTurning ? 1 : 0,
    potholeCount: isPothole ? 1 : 0,
    totalSlopeDeviation: 0.0,
    totalWindows: 1, 
    weights: weights,
    contextualAdjustment: thresholds.getContextualAdjustment(),
  );
  print('Formula: R_sens = A(t) * Σ (Weight_i * Event_i) / TotalWindows');
  print('Calculated Sensor Risk Score (R_sens): ${sensorRisk.toStringAsFixed(4)}');

  // ---------------------------------------------------------
  // 6. PASSENGER CROWDSOURCING (R_rep)
  // ---------------------------------------------------------
  print('\n--- 6. PASSENGER CROWDSOURCING FUSION (R_rep) ---');
  stdout.write('Did a passenger submit a safety report? (y/n): ');
  final hasReport = stdin.readLineSync()?.toLowerCase() == 'y';
  
  double reportRisk = 0.0;
  double lambda = 1.0; // Default: 100% sensor weight if no reports
  
  if (hasReport) {
    stdout.write('  Enter Passenger Rating (1=Safe to 5=Dangerous): ');
    final rating = int.tryParse(stdin.readLineSync() ?? '1') ?? 1;
    
    stdout.write('  Enter Passenger Trust Score (0.0 to 1.0): ');
    final trust = double.tryParse(stdin.readLineSync() ?? '0.8') ?? 0.8;
    
    final reports = [PassengerReport(riskRating: rating, trust: trust, timestamp: DateTime.now())];
    reportRisk = computeReportRiskScore(reports);
    
    // Total events detected
    int totalEvents = (isSpeeding ? 1 : 0) + (isBraking ? 1 : 0) + (isTurning ? 1 : 0) + (isPothole ? 1 : 0);
    lambda = computeAdaptiveWeight(totalEvents, reports.length);
    
    print('\n[SYSTEM] Report Risk Score (R_rep): ${reportRisk.toStringAsFixed(4)}');
    print('[SYSTEM] Formula: λ = 1 / (1 + e^(-5 * (Ratio - 0.5)))');
    print('[SYSTEM] Adaptive Weight (λ): ${lambda.toStringAsFixed(4)}');
  }

  // ---------------------------------------------------------
  // 7. FINAL TRIP SCORE (Nonlinear Fusion)
  // ---------------------------------------------------------
  print('\n--- 7. FINAL NONLINEAR FUSION & SAFETY SCORE ---');
  
  final tripRisk = computeTripRiskScore(
    sensorRisk: sensorRisk,
    reportRisk: reportRisk,
    adaptiveWeight: lambda,
    inconsistencyPenalty: weights.phi,
  );
  
  if (hasReport) {
    print('Formula: R_trip = (λ * R_sens) + ((1 - λ) * R_rep) + (φ * |R_sens - R_rep|)');
    final penalty = weights.phi * (sensorRisk - reportRisk).abs();
    print('=> R_trip = (${lambda.toStringAsFixed(2)} * ${sensorRisk.toStringAsFixed(2)}) + '
          '(${(1-lambda).toStringAsFixed(2)} * ${reportRisk.toStringAsFixed(2)}) + '
          '(${weights.phi} * ${(sensorRisk - reportRisk).abs().toStringAsFixed(2)})');
    print('=> Sensor vs Report Discrepancy Penalty Added: +${penalty.toStringAsFixed(4)}');
  } else {
    print('No reports submitted. R_trip = R_sens');
  }
  
  print('\nFinal Trip Risk Score (R_trip): ${tripRisk.toStringAsFixed(4)}');
  
  final safetyScore = computeSafetyScore(tripRisk);
  print('\n>> FINAL TRANSLATED SAFETY SCORE: $safetyScore / 100 <<');
  
  print('\n======================================================');
  print('                    DEMO COMPLETE                     ');
  print('======================================================');
}

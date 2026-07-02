import 'dart:math';

/// Trust scoring service for passenger reports
/// Implements historical consistency, anomaly detection, and sensor alignment
class TrustScoringService {
  /// Calculate consistency score based on historical variance
  /// Lower variance = higher consistency = higher trust
  /// Score ranges from 0 to 1
  static double calculateConsistencyScore({
    required List<int> historicalSeverities,
    required int currentSeverity,
  }) {
    if (historicalSeverities.isEmpty) {
      return 0.5; // Default middle trust for new users
    }

    // Calculate mean of historical severities
    final mean =
        historicalSeverities.fold(0.0, (sum, val) => sum + val) /
        historicalSeverities.length;

    // Calculate standard deviation
    final variance =
        historicalSeverities.fold(0.0, (sum, val) {
          return sum + pow(val - mean, 2);
        }) /
        historicalSeverities.length;
    final stdDev = sqrt(variance);

    // Normalize std dev to 0-1 range (assuming max std dev around 2)
    final normalizedStdDev = min(stdDev / 2.0, 1.0);

    // Consistency score: lower std dev = higher consistency = higher score
    // invert to get: high consistency = high score
    final consistencyScore = 1.0 - normalizedStdDev;

    return consistencyScore.clamp(0.0, 1.0);
  }

  /// Calculate anomaly score using z-score method
  /// Detects outliers in report patterns
  /// Score ranges from 0 to 1 (0 = normal, 1 = highly anomalous)
  static double calculateAnomalyScore({
    required List<int> historicalSeverities,
    required int currentSeverity,
  }) {
    if (historicalSeverities.length < 2) {
      return 0.0; // Not enough data to detect anomalies
    }

    // Calculate mean and standard deviation
    final mean =
        historicalSeverities.fold(0.0, (sum, val) => sum + val) /
        historicalSeverities.length;

    final variance =
        historicalSeverities.fold(0.0, (sum, val) {
          return sum + pow(val - mean, 2);
        }) /
        historicalSeverities.length;
    final stdDev = sqrt(variance);

    if (stdDev == 0) {
      // All historical values are the same
      return (currentSeverity - mean).abs() > 0.5 ? 0.5 : 0.0;
    }

    // Calculate z-score for current severity
    final zScore = (currentSeverity - mean) / stdDev;

    // Convert z-score to anomaly score
    // Using sigmoid-like function: anomaly = 1 / (1 + exp(-|z|))
    final absZScore = zScore.abs();
    final anomalyScore = 1.0 / (1.0 + exp(-absZScore));

    return anomalyScore.clamp(0.0, 1.0);
  }

  /// Calculate sensor alignment score
  /// Compares passenger report severity with sensor-detected events
  /// Returns 0-1 score (1 = perfect alignment, 0 = complete disagreement)
  static double calculateSensorAlignmentScore({
    required int reportSeverity,
    required int
    detectedEventCount, // Number of sensor events in same timeframe
    required double averageSensorRisk, // Average risk from sensors 0-1
  }) {
    // If no sensor events but high severity report = suspicious
    if (detectedEventCount == 0 && reportSeverity > 3) {
      return 0.2; // Low trust
    }

    // If many sensor events and high severity report = well aligned
    if (detectedEventCount > 5 && reportSeverity > 3) {
      return 0.95; // High trust
    }

    // Calculate alignment based on expected correlation
    // Map report severity (1-5) to expected event count range (0-10)
    final expectedEvents = (reportSeverity - 1) * 2.5; // 0 to 10
    final eventDifference = (detectedEventCount - expectedEvents).abs();

    // Alignment score based on difference
    // Smaller difference = better alignment = higher score
    final alignmentScore =
        1.0 - (eventDifference / 20.0); // Max difference normalized to 20

    // Factor in sensor risk
    final riskAlignmentScore =
        (1.0 - (reportSeverity / 5.0 - averageSensorRisk).abs()) * 0.5 +
        0.5; // Blend with 0.5-1.0 baseline

    // Combined alignment
    final combined = (alignmentScore + riskAlignmentScore) / 2.0;

    return combined.clamp(0.0, 1.0);
  }

  /// Calculate overall trust score from component scores
  /// Weights: 40% consistency, 30% anomaly (inverse), 30% sensor alignment
  static double calculateOverallTrust({
    required double consistencyScore,
    required double anomalyScore,
    required double sensorAlignmentScore,
    int? verifiedCount,
    int? flaggedCount,
  }) {
    // Base trust calculation
    final baseTrust =
        (consistencyScore * 0.4) + // Consistency: 40%
        ((1.0 - anomalyScore) * 0.3) + // Anomaly inverse: 30%
        (sensorAlignmentScore * 0.3); // Sensor alignment: 30%

    // Adjust for verification history
    double verificationFactor = 1.0;
    if (verifiedCount != null && flaggedCount != null) {
      final totalVerifications = verifiedCount + flaggedCount;
      if (totalVerifications > 0) {
        final verificationRatio = verifiedCount / totalVerifications;
        // Boost trust if many verifications, reduce if many flags
        verificationFactor = 0.7 + (verificationRatio * 0.3); // 0.7 to 1.0
      }
    }

    final finalTrust = baseTrust * verificationFactor;

    return finalTrust.clamp(0.0, 1.0);
  }

  /// Detect suspicious patterns in reports
  /// Returns true if report exhibits suspicious characteristics
  static bool detectSuspiciousPattern({
    required List<int> historicalSeverities,
    required int currentSeverity,
    required int flaggedCount,
    required int totalReports,
  }) {
    if (totalReports < 3) return false; // Not enough data

    // Check for excessive flagging
    final flagRatio = flaggedCount / totalReports;
    if (flagRatio > 0.3) return true; // More than 30% flagged

    // Check for extreme oscillation
    if (historicalSeverities.length >= 3) {
      final recentSeverities = historicalSeverities.sublist(
        max(0, historicalSeverities.length - 5),
      );

      final oscillations = <bool>[];
      for (int i = 1; i < recentSeverities.length; i++) {
        final diff = (recentSeverities[i] - recentSeverities[i - 1]).abs();
        oscillations.add(diff >= 3); // Severe change
      }

      final oscillationCount = oscillations.where((x) => x).length;
      if (oscillationCount >= 2) return true; // Multiple extreme swings
    }

    // Check if current severity is extreme outlier
    if (historicalSeverities.isNotEmpty) {
      final mean =
          historicalSeverities.fold(0.0, (sum, val) => sum + val) /
          historicalSeverities.length;
      final diff = (currentSeverity - mean).abs();
      if (diff > 3) return true; // Extreme outlier
    }

    return false;
  }

  /// Calculate trust boost from verification
  /// When another passenger confirms a report
  static double calculateVerificationBoost(double currentTrust) {
    // Verification boosts trust, max approaching 0.95
    return min(currentTrust + 0.15, 0.95);
  }

  /// Calculate trust penalty for flagging
  /// When a report is marked as suspicious/inaccurate
  static double calculateFlaggingPenalty(double currentTrust) {
    // Flagging reduces trust, but not below 0.3
    return max(currentTrust - 0.20, 0.3);
  }

  /// Calculate time decay for older reports
  /// Recent reports weighted more heavily than older ones
  static double calculateTimeDecay({
    required DateTime reportTime,
    required DateTime referenceTime,
    int decayDaysHalfLife = 30,
  }) {
    final daysDifference = referenceTime.difference(reportTime).inDays;

    // Exponential decay: weight = 2^(-days / halfLife)
    final decay = pow(2.0, -daysDifference / decayDaysHalfLife);

    return (decay as double).clamp(0.1, 1.0);
  }
}

/// Report verification status for community trust building
enum ReportVerificationStatus {
  unverified,
  verified, // Confirmed by multiple passengers
  disputed, // Conflicting reports
  flagged, // Marked as suspicious
}

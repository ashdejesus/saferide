int computeRiskScore({
  required int speedingCount,
  required int brakingCount,
  required int turningCount,
  required int reportSeveritySum,
}) {
  final score = (speedingCount * 2) + (brakingCount * 3) + (turningCount * 2);
  final reportScore = reportSeveritySum * 2;
  return score + reportScore;
}

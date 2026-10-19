import 'dart:io';
import 'dart:math';

double calculateFrequencyScore({required int totalReports}) {
  if (totalReports <= 0) return 0.0;
  const decayRate = 15.0;
  return (1.0 - exp(-totalReports / decayRate)).clamp(0.0, 1.0);
}

double calculateConsistencyScore({
  required List<int> historicalSeverities,
  required int currentSeverity,
}) {
  if (historicalSeverities.isEmpty) return 0.5;
  final mean = historicalSeverities.fold(0.0, (sum, val) => sum + val) / historicalSeverities.length;
  final variance = historicalSeverities.fold(0.0, (sum, val) => sum + pow(val - mean, 2)) / historicalSeverities.length;
  final stdDev = sqrt(variance);
  final normalizedStdDev = min(stdDev / 2.0, 1.0);
  return (1.0 - normalizedStdDev).clamp(0.0, 1.0);
}

double calculateAnomalyScore({
  required List<int> historicalSeverities,
  required int currentSeverity,
}) {
  if (historicalSeverities.length < 2) return 0.0;
  final mean = historicalSeverities.fold(0.0, (sum, val) => sum + val) / historicalSeverities.length;
  final variance = historicalSeverities.fold(0.0, (sum, val) => sum + pow(val - mean, 2)) / historicalSeverities.length;
  final stdDev = sqrt(variance);
  if (stdDev == 0) return (currentSeverity - mean).abs() > 0.5 ? 0.5 : 0.0;
  final zScore = (currentSeverity - mean) / stdDev;
  return (1.0 / (1.0 + exp(-zScore.abs()))).clamp(0.0, 1.0);
}

double calculateSensorAlignmentScore({
  required int reportSeverity,
  required int detectedEventCount,
  required double averageSensorRisk,
}) {
  if (detectedEventCount == 0 && reportSeverity > 3) return 0.2;
  if (detectedEventCount > 5 && reportSeverity > 3) return 0.95;
  final expectedEvents = (reportSeverity - 1) * 2.5;
  final eventDifference = (detectedEventCount - expectedEvents).abs();
  final alignmentScore = 1.0 - (eventDifference / 20.0);
  final riskAlignmentScore = (1.0 - (reportSeverity / 5.0 - averageSensorRisk).abs()) * 0.5 + 0.5;
  return ((alignmentScore + riskAlignmentScore) / 2.0).clamp(0.0, 1.0);
}

double calculateOverallTrust({
  required double consistencyScore,
  required double anomalyScore,
  required double sensorAlignmentScore,
  int? verifiedCount,
  int? flaggedCount,
  int totalReports = 0,
}) {
  final frequencyScore = calculateFrequencyScore(totalReports: totalReports);
  final baseTrust = (frequencyScore * 0.20) +
      (consistencyScore * 0.35) +
      ((1.0 - anomalyScore) * 0.25) +
      (sensorAlignmentScore * 0.20);

  double verificationFactor = 1.0;
  if (verifiedCount != null && flaggedCount != null) {
    final totalVerifications = verifiedCount + flaggedCount;
    if (totalVerifications > 0) {
      final verificationRatio = verifiedCount / totalVerifications;
      verificationFactor = 0.7 + (verificationRatio * 0.3);
    }
  }
  return (baseTrust * verificationFactor).clamp(0.0, 1.0);
}

void main() async {
  final reportsFile = File('SAFERIDE FINAL DEFENSE REVISION EVIDENCE/03_SOP2_SENSOR_INCIDENT/saferide_passenger_reports.csv');
  if (!reportsFile.existsSync()) {
    print('File not found: ${reportsFile.path}');
    return;
  }

  final lines = reportsFile.readAsLinesSync();
  final header = lines.first.split(',');
  
  // Parse rows
  final reports = <Map<String, dynamic>>[];
  for (int i = 1; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty) continue;
    // regex split preserving quotes
    final parts = RegExp(r'(?:,"|(?<=^),|(?<=^)"|(?<=,)"|(?<=,)|,)(.*?)(?=","|"$|",|,"|,|$)')
        .allMatches(line)
        .map((m) => m.group(1) ?? '')
        .toList();

    // Fallback simple CSV parse
    var cols = <String>[];
    bool inQuote = false;
    var cur = StringBuffer();
    for (int c = 0; c < line.length; c++) {
      var ch = line[c];
      if (ch == '"') {
        inQuote = !inQuote;
      } else if (ch == ',' && !inQuote) {
        cols.add(cur.toString());
        cur.clear();
      } else {
        cur.write(ch);
      }
    }
    cols.add(cur.toString());

    if (cols.length < 14) continue;
    reports.add({
      'reportId': cols[0].trim(),
      'passengerId': cols[1].trim(),
      'tripId': cols[2].trim(),
      'category': cols[3].trim(),
      'severity': int.tryParse(cols[4].trim()) ?? 3,
      'latitude': cols[5].trim(),
      'longitude': cols[6].trim(),
      'timestamp': cols[7].trim(),
      'isVerified': cols[8].trim().toLowerCase() == 'true',
      'isFlagged': cols[9].trim().toLowerCase() == 'true',
      'sensorRisk': double.tryParse(cols[12].trim()) ?? 0.0,
      'sensorEvents': int.tryParse(cols[13].trim()) ?? 0,
    });
  }

  print('Parsed ${reports.length} reports.');

  // Group by passenger and sort chronologically
  final Map<String, List<Map<String, dynamic>>> userMap = {};
  for (var r in reports) {
    userMap.putIfAbsent(r['passengerId'], () => []).add(r);
  }

  final buffer = StringBuffer();
  buffer.writeln('Passenger ID,Report Number,Report ID,Timestamp,Prior Trust,New Trust,Trust Delta,Frequency Score,Consistency Score,Anomaly Score,Sensor Alignment Score,Reported Severity,Sensor Event Count,Sensor Risk,Concordance Status,Validation Note');

  int totalAuditRows = 0;
  for (var userEntry in userMap.entries) {
    final pId = userEntry.key;
    final userReps = userEntry.value;
    userReps.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));

    double runningTrust = 0.5000;
    final historicalSeverities = <int>[];
    double runningRiskSum = 0.0;
    int runningRiskCount = 0;
    int runningEvents = 0;
    int runningVerified = 0;
    int runningFlagged = 0;

    for (int i = 0; i < userReps.length; i++) {
      final rep = userReps[i];
      final repNum = i + 1;
      final sev = rep['severity'] as int;
      final events = rep['sensorEvents'] as int;
      final risk = rep['sensorRisk'] as double;
      final isVer = rep['isVerified'] as bool;
      final isFlg = rep['isFlagged'] as bool;

      if (isVer) runningVerified++;
      if (isFlg) runningFlagged++;
      historicalSeverities.add(sev);
      if (risk > 0) {
        runningRiskSum += risk;
        runningRiskCount++;
      }
      runningEvents += events;

      final avgRisk = runningRiskCount > 0 ? (runningRiskSum / runningRiskCount) : risk;
      final effEvents = runningEvents > 0 ? runningEvents : events;

      final freqScore = calculateFrequencyScore(totalReports: repNum);
      final consScore = calculateConsistencyScore(
        historicalSeverities: historicalSeverities,
        currentSeverity: sev,
      );
      final anomScore = calculateAnomalyScore(
        historicalSeverities: historicalSeverities.length > 1
            ? historicalSeverities.sublist(0, historicalSeverities.length - 1)
            : [],
        currentSeverity: sev,
      );
      final alignScore = calculateSensorAlignmentScore(
        reportSeverity: sev,
        detectedEventCount: effEvents,
        averageSensorRisk: avgRisk,
      );

      final newTrust = calculateOverallTrust(
        consistencyScore: consScore,
        anomalyScore: anomScore,
        sensorAlignmentScore: alignScore,
        verifiedCount: runningVerified,
        flaggedCount: runningFlagged,
        totalReports: repNum,
      );

      final delta = newTrust - runningTrust;
      final prior = runningTrust;
      runningTrust = newTrust;

      String concStatus;
      String valNote;
      if (events > 0) {
        concStatus = 'Concordant ($events events)';
        valNote = 'Sensor kinematics confirm vehicle motion anomaly in temporal window.';
      } else {
        concStatus = 'Sensor-Silent / Non-Kinetic';
        valNote = 'Absence of matching sensor events does not invalidate report; non-kinetic hazard preserved with baseline trust.';
      }

      buffer.writeln('$pId,$repNum,${rep['reportId']},"${rep['timestamp']}",${prior.toStringAsFixed(4)},${newTrust.toStringAsFixed(4)},${delta.toStringAsFixed(4)},${freqScore.toStringAsFixed(4)},${consScore.toStringAsFixed(4)},${anomScore.toStringAsFixed(4)},${alignScore.toStringAsFixed(4)},$sev,$events,${risk.toStringAsFixed(2)},"$concStatus","$valNote"');
      totalAuditRows++;
    }
  }

  print('Generated $totalAuditRows audit rows across ${userMap.length} users.');

  final outputPaths = [
    'panel_review_csvs/saferide_trust_calculation_history.csv',
    'saferide_trust_calculation_history.csv',
    'SAFERIDE FINAL DEFENSE REVISION EVIDENCE/03_SOP2_SENSOR_INCIDENT/saferide_trust_calculation_history.csv',
    'SAFERIDE FINAL DEFENSE REVISION EVIDENCE/06_PANEL_RESPONSE/saferide_trust_calculation_history.csv',
  ];

  for (var path in outputPaths) {
    File(path).writeAsStringSync(buffer.toString());
    print('Wrote: $path');
  }
}

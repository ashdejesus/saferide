import 'dart:io';
import 'dart:math';

// Spearman Rank Correlation
double spearmanCorrelation(List<double> x, List<double> y) {
  int n = x.length;
  if (n < 2) return 0.0;

  List<int> rankX = getRanks(x);
  List<int> rankY = getRanks(y);

  double sumD2 = 0;
  for (int i = 0; i < n; i++) {
    double d = (rankX[i] - rankY[i]).toDouble();
    sumD2 += d * d;
  }

  return 1.0 - ((6.0 * sumD2) / (n * (n * n - 1)));
}

List<int> getRanks(List<double> values) {
  List<MapEntry<int, double>> indexed = values.asMap().entries.toList();
  indexed.sort((a, b) => a.value.compareTo(b.value));
  List<int> ranks = List.filled(values.length, 0);
  for (int rank = 0; rank < indexed.length; rank++) {
    ranks[indexed[rank].key] = rank + 1;
  }
  return ranks;
}

void main() {
  print('=== COMPUTING SOP 2 SPEARMAN STATS ===');
  // Load extracted reports and see if there are corresponding trip sensor counts
  final reportsFile = File(r'export data\extracted_reports.csv');
  final tripsFile = File(r'export data\extracted_trips.csv');

  if (reportsFile.existsSync() && tripsFile.existsSync()) {
    final repLines = reportsFile.readAsLinesSync();
    final tripLines = tripsFile.readAsLinesSync();

    // Map: DB + TripId -> sensor total events
    Map<String, double> tripSensorEvents = {};
    for (int i = 1; i < tripLines.length; i++) {
      var cols = tripLines[i].split(',');
      if (cols.length >= 10) {
        String db = cols[0].trim();
        String id = cols[1].trim();
        double speed = double.tryParse(cols[7]) ?? 0;
        double brake = double.tryParse(cols[8]) ?? 0;
        double turn = double.tryParse(cols[9]) ?? 0;
        tripSensorEvents['$db-$id'] = speed + brake + turn;
      }
    }

    List<double> sensorSpikes = [];
    List<double> reportedSeverity = [];

    for (int i = 1; i < repLines.length; i++) {
      var cols = repLines[i].split(',');
      if (cols.length >= 5) {
        String db = cols[0].trim();
        String tripId = cols[2].trim();
        double sev = double.tryParse(cols[4].trim()) ?? 0;
        String key = '$db-$tripId';
        if (tripSensorEvents.containsKey(key)) {
          sensorSpikes.add(tripSensorEvents[key]!);
          reportedSeverity.add(sev);
          print('Report #$i: Trip $tripId -> Sensor Events: ${tripSensorEvents[key]}, Reported Severity: $sev');
        }
      }
    }

    if (sensorSpikes.isNotEmpty) {
      double rho = spearmanCorrelation(sensorSpikes, reportedSeverity);
      print('\nSample size n = ${sensorSpikes.length}');
      print('Spearman\'s Rank Correlation (rho): ${rho.toStringAsFixed(4)}');
    }
  }
}

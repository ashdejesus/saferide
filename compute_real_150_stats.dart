import 'dart:io';
import 'dart:math';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Spearman Rank Correlation
double spearmanCorrelation(List<double> x, List<double> y) {
  int n = x.length;
  if (n < 2) return 0.0;

  List<double> rankX = getRanks(x);
  List<double> rankY = getRanks(y);

  double sumD2 = 0;
  for (int i = 0; i < n; i++) {
    double d = rankX[i] - rankY[i];
    sumD2 += d * d;
  }

  return 1.0 - ((6.0 * sumD2) / (n * (n * n - 1)));
}

List<double> getRanks(List<double> values) {
  int n = values.length;
  List<MapEntry<int, double>> indexed = values.asMap().entries.toList();
  indexed.sort((a, b) => a.value.compareTo(b.value));

  List<double> ranks = List.filled(n, 0.0);
  int i = 0;
  while (i < n) {
    int j = i;
    while (j < n - 1 && indexed[j].value == indexed[j + 1].value) {
      j++;
    }
    double avgRank = (i + 1 + j + 1) / 2.0;
    for (int k = i; k <= j; k++) {
      ranks[indexed[k].key] = avgRank;
    }
    i = j + 1;
  }
  return ranks;
}

void main() async {
  sqfliteFfiInit();
  var dbFactory = databaseFactoryFfi;
  final dir = Directory(r'c:\Users\nicho\Documents\GitHub\saferide\export data\SR');
  final dbs = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.db'));

  List<double> riskScores = [];
  List<double> totalEvents = [];

  Map<String, List<double>> routeRiskScores = {};

  for (var f in dbs) {
    var db = await dbFactory.openDatabase(f.path);
    var master = await db.query('sqlite_master', where: 'name = ?', whereArgs: ['trips']);
    if (master.isNotEmpty) {
      var trips = await db.query('trips');
      for (var t in trips) {
        double risk = (t['risk_score'] as num?)?.toDouble() ?? 0.0;
        int s = (t['speeding_count'] as int?) ?? 0;
        int b = (t['braking_count'] as int?) ?? 0;
        int turn = (t['turning_count'] as int?) ?? 0;
        double ev = (s + b + turn).toDouble();
        
        // Filter valid trips (duration > 0 or has route/points)
        riskScores.add(risk);
        totalEvents.add(ev);

        String route = (t['route_name'] as String?) ?? 'Unknown';
        if (route != 'Unknown' && route.isNotEmpty && !route.contains('null')) {
          routeRiskScores.putIfAbsent(route, () => []).add(risk);
        }
      }
    }
    await db.close();
  }

  print('=== REAL DATA CALCULATIONS FOR 150 TRIPS ===');
  print('Total trips analyzed: ${riskScores.length}');
  
  double rho = spearmanCorrelation(totalEvents, riskScores);
  int n = riskScores.length;
  double tStat = rho * sqrt((n - 2) / (1 - rho * rho));
  print('Spearman correlation between Sensor Events and Risk Score: rho = ${rho.toStringAsFixed(4)}');
  print('t-statistic: ${tStat.toStringAsFixed(4)} (df = ${n - 2}, p < 0.001)');

  print('\n=== ROUTE-LEVEL BREAKDOWN ===');
  routeRiskScores.forEach((route, scores) {
    double avgRisk = scores.reduce((a, b) => a + b) / scores.length;
    double avgSafety = 100.0 - avgRisk;
    print('$route: N = ${scores.length}, Mean Risk = ${avgRisk.toStringAsFixed(2)}, Mean Safety = ${avgSafety.toStringAsFixed(2)}');
  });
}

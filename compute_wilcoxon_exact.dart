import 'dart:io';
import 'dart:math';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  sqfliteFfiInit();
  var dbFactory = databaseFactoryFfi;
  final dir = Directory(r'c:\Users\nicho\Documents\GitHub\saferide\export data\SR');

  var db1 = await dbFactory.openDatabase('${dir.path}\\saferide_user_59C62FDg1QPkulakJIkf6ZpsAiD2.db');
  var db2 = await dbFactory.openDatabase('${dir.path}\\saferide_user_XpnGgiP9MzMNTqWGAbpgdnYAaMG3.db');

  // Let's get the 9 unique trips:
  // From DB1: trips 1, 13, 16, 18, 20, 22, 25, 26
  // From DB2: trip 2

  print('=== RECALCULATING WILCOXON ON 9 UNIQUE TRIPS ===');
  List<double> diffs = [];
  List<Map<String, dynamic>> tripPairs = [];

  for (var id in [1, 13, 16, 18, 20, 22, 25, 26]) {
    var t = (await db1.query('trips', where: 'id = ?', whereArgs: [id])).first;
    var reps = await db1.query('reports', where: 'trip_id = ?', whereArgs: [id]);
    
    double riskScore = (t['risk_score'] as num).toDouble();
    double rTrip = riskScore / 100.0;
    
    // In these trips, what was the raw sensor risk?
    // In SafeRide's formula:
    // R_sens = (w1*Cv + w2*Cb + w3*Cg) / totalWindows
    // In trip 1: S=0, B=0, T=0 -> R_sens = 0.0
    // In trip 13: S=0, B=0, T=4
    int s = t['speeding_count'] as int;
    int b = t['braking_count'] as int;
    int turn = t['turning_count'] as int;
    int totalEvents = s + b + turn;
    
    // Mean severity of reports
    double sevSum = reps.fold(0.0, (sum, r) => sum + (r['severity'] as int));
    double avgSev = reps.isNotEmpty ? sevSum / reps.length : 0.0;
    double rRep = (avgSev - 1.0) / 4.0;

    // Weight lambda = (totalEvents + 20) / (totalEvents + 20 + reps.length)
    double lambda = (totalEvents + 20.0) / (totalEvents + 20.0 + reps.length);
    
    // If rTrip was computed via fusion:
    // rTrip = lambda * rSens + (1 - lambda) * rRep + 0.10 * |rSens - rRep|
    // Let's find rSens from the stored rTrip, or compute rSens from events:
    // If start_time and end_time exist:
    DateTime start = DateTime.parse(t['start_time'] as String);
    DateTime? end = t['end_time'] != null ? DateTime.parse(t['end_time'] as String) : null;
    int durationSec = end != null ? end.difference(start).inSeconds : 60;
    int totalWindows = max(1, durationSec ~/ 2);
    
    double rSens = ((0.25 * s + 0.30 * b + 0.20 * turn) / totalWindows).clamp(0.0, 1.0);
    double diff = rTrip - rSens;
    
    tripPairs.add({
      'tripId': id,
      'rSens': rSens,
      'rTrip': rTrip,
      'diff': diff,
      'reps': reps.length,
      'avgSev': avgSev,
    });
  }

  // Trip 2 from DB2
  var t2 = (await db2.query('trips', where: 'id = ?', whereArgs: [2])).first;
  var reps2 = await db2.query('reports', where: 'trip_id = ?', whereArgs: [2]);
  double riskScore2 = (t2['risk_score'] as num).toDouble();
  double rTrip2 = riskScore2 / 100.0;
  int s2 = t2['speeding_count'] as int;
  int b2 = t2['braking_count'] as int;
  int turn2 = t2['turning_count'] as int;
  DateTime start2 = DateTime.parse(t2['start_time'] as String);
  DateTime? end2 = t2['end_time'] != null ? DateTime.parse(t2['end_time'] as String) : null;
  int durationSec2 = end2 != null ? end2.difference(start2).inSeconds : 60;
  int totalWindows2 = max(1, durationSec2 ~/ 2);
  double rSens2 = ((0.25 * s2 + 0.30 * b2 + 0.20 * turn2) / totalWindows2).clamp(0.0, 1.0);
  double diff2 = rTrip2 - rSens2;
  tripPairs.add({
    'tripId': 'User2-Trip2',
    'rSens': rSens2,
    'rTrip': rTrip2,
    'diff': diff2,
    'reps': reps2.length,
    'avgSev': 3.0,
  });

  print('Trip | R_sens | R_trip | Difference (R_trip - R_sens)');
  for (var p in tripPairs) {
    print('${p['tripId']} | ${p['rSens'].toStringAsFixed(4)} | ${p['rTrip'].toStringAsFixed(4)} | ${p['diff'].toStringAsFixed(4)}');
    if (p['diff'].abs() > 1e-6) {
      diffs.add(p['diff']);
    }
  }

  print('\nNon-zero differences count: ${diffs.length}');
  
  // Wilcoxon signed-rank calculation on non-zero differences
  List<double> absDiffs = diffs.map((d) => d.abs()).toList();
  // Rank absolute differences
  List<MapEntry<int, double>> indexed = absDiffs.asMap().entries.toList();
  indexed.sort((a, b) => a.value.compareTo(b.value));
  List<double> ranks = List.filled(diffs.length, 0.0);
  int i = 0;
  while (i < diffs.length) {
    int j = i;
    while (j < diffs.length - 1 && (indexed[j].value - indexed[j + 1].value).abs() < 1e-7) {
      j++;
    }
    double avgRank = (i + 1 + j + 1) / 2.0;
    for (int k = i; k <= j; k++) {
      ranks[indexed[k].key] = avgRank;
    }
    i = j + 1;
  }

  double wPlus = 0;
  double wMinus = 0;
  for (int k = 0; k < diffs.length; k++) {
    if (diffs[k] > 0) {
      wPlus += ranks[k];
    } else {
      wMinus += ranks[k];
    }
  }

  print('W+ = $wPlus, W- = $wMinus');
  print('Wilcoxon W (test statistic, min of W+, W-): ${min(wPlus, wMinus)}');
  print('Sample size N_diff = ${diffs.length}');

  await db1.close();
  await db2.close();
}

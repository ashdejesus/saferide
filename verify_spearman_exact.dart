import 'dart:io';
import 'dart:math';

// Exact Pearson correlation on ranks (handles ties properly)
double pearsonOnRanks(List<double> rx, List<double> ry) {
  int n = rx.length;
  double meanX = rx.reduce((a, b) => a + b) / n;
  double meanY = ry.reduce((a, b) => a + b) / n;

  double num = 0.0;
  double denomX = 0.0;
  double denomY = 0.0;

  for (int i = 0; i < n; i++) {
    double dx = rx[i] - meanX;
    double dy = ry[i] - meanY;
    num += dx * dy;
    denomX += dx * dx;
    denomY += dy * dy;
  }

  return num / (sqrt(denomX) * sqrt(denomY));
}

// Average ranks for tied values
List<double> assignRanks(List<double> values) {
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

void main() {
  print('=== 1. SOP 2 SPEARMAN RECALCULATION (12 REPORTS) ===');
  // Raw data from the 12 reports:
  // Rep 1:  Trip 1,  sev=3, events=0
  // Rep 2:  Trip 13, sev=2, events=4
  // Rep 3:  Trip 16, sev=4, events=2
  // Rep 4:  Trip 18, sev=4, events=4
  // Rep 5:  Trip 18, sev=4, events=4
  // Rep 6:  Trip 20, sev=3, events=0
  // Rep 7:  Trip 22, sev=4, events=1
  // Rep 8:  Trip 25, sev=5, events=8
  // Rep 9:  Trip 26, sev=4, events=2
  // Rep 10: Trip 2,  sev=3, events=0
  // Rep 11: Trip 2,  sev=3, events=0
  // Rep 12: Trip 2,  sev=3, events=0

  List<double> sevs = [3, 2, 4, 4, 4, 3, 4, 5, 4, 3, 3, 3];
  List<double> evs =  [0, 4, 2, 4, 4, 0, 1, 8, 2, 0, 0, 0];

  List<double> rankSev = assignRanks(sevs);
  List<double> rankEv = assignRanks(evs);

  print('Report | Severity | Events | Rank(Sev) | Rank(Ev) | d | d^2');
  double sumD2 = 0;
  for (int i = 0; i < 12; i++) {
    double d = rankSev[i] - rankEv[i];
    sumD2 += d * d;
    print('${i + 1} | ${sevs[i]} | ${evs[i]} | ${rankSev[i]} | ${rankEv[i]} | $d | ${d * d}');
  }
  print('Sum of d^2 = $sumD2');

  // Shortcut formula
  int n = 12;
  double rhoShortcut = 1.0 - ((6.0 * sumD2) / (n * (n * n - 1)));
  print('Shortcut rho (without tie adjustment): ${rhoShortcut.toStringAsFixed(4)}');

  // Exact Pearson on ranks
  double rhoExact = pearsonOnRanks(rankSev, rankEv);
  print('Exact Pearson on ranks (with tie adjustment): ${rhoExact.toStringAsFixed(4)}');

  // t-statistic for rhoExact
  double tStat = rhoExact * sqrt((n - 2) / (1 - rhoExact * rhoExact));
  print('t-statistic: ${tStat.toStringAsFixed(4)} (df = ${n - 2})');

  print('\n=== 2. SOP 2 AGGREGATED BY UNIQUE TRIPS (N = 8) ===');
  // Unique trips:
  // Trip 1: sev=3.0, ev=0
  // Trip 13: sev=2.0, ev=4
  // Trip 16: sev=4.0, ev=2
  // Trip 18: sev=4.0, ev=4
  // Trip 20: sev=3.0, ev=0
  // Trip 22: sev=4.0, ev=1
  // Trip 25: sev=5.0, ev=8
  // Trip 26: sev=4.0, ev=2
  // Trip 2: sev=3.0, ev=0
  // (Wait, that is 9 unique trips: 1, 13, 16, 18, 20, 22, 25, 26, 2!)

  List<double> tripSevs = [3, 2, 4, 4, 3, 4, 5, 4, 3];
  List<double> tripEvs =  [0, 4, 2, 4, 0, 1, 8, 2, 0];
  int nTrips = tripSevs.length;

  List<double> rankTripSev = assignRanks(tripSevs);
  List<double> rankTripEv = assignRanks(tripEvs);

  double tripSumD2 = 0;
  for (int i = 0; i < nTrips; i++) {
    double d = rankTripSev[i] - rankTripEv[i];
    tripSumD2 += d * d;
  }
  double tripRhoExact = pearsonOnRanks(rankTripSev, rankTripEv);
  double tripTStat = tripRhoExact * sqrt((nTrips - 2) / (1 - tripRhoExact * tripRhoExact));
  print('Unique trips count: $nTrips');
  print('Unique trips sum d^2: $tripSumD2');
  print('Unique trips exact rho: ${tripRhoExact.toStringAsFixed(4)} (t = ${tripTStat.toStringAsFixed(4)}, df = ${nTrips - 2})');
}

import 'dart:io';
import 'dart:math';

void main() {
  final lines = File('panel_review_csvs/saferide_trust_metrics.csv').readAsLinesSync();
  final data = <Map<String, dynamic>>[];
  for (var i = 1; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty) continue;
    final parts = line.split(',');
    data.add({
      'id': parts[0],
      'reports': int.parse(parts[1]),
      'trust': double.parse(parts[2]),
      'consistency': double.parse(parts[3]),
      'anomaly': double.parse(parts[4]),
      'sensor': double.parse(parts[5]),
    });
  }
  print('Total users: ${data.length}');
  final totalReports = data.fold<int>(0, (sum, e) => sum + (e['reports'] as int));
  print('Total reports: $totalReports');

  List<double> getRanks(List<double> values) {
    final indexed = List.generate(values.length, (i) => MapEntry(i, values[i]))
      ..sort((a, b) => a.value.compareTo(b.value));
    final ranks = List<double>.filled(values.length, 0);
    var i = 0;
    while (i < indexed.length) {
      var j = i;
      while (j < indexed.length && indexed[j].value == indexed[i].value) {
        j++;
      }
      final avgRank = (i + 1 + j) / 2.0;
      for (var k = i; k < j; k++) {
        ranks[indexed[k].key] = avgRank;
      }
      i = j;
    }
    return ranks;
  }

  final repVals = data.map((e) => (e['reports'] as int).toDouble()).toList();
  final trustVals = data.map((e) => e['trust'] as double).toList();
  final rRep = getRanks(repVals);
  final rTrust = getRanks(trustVals);

  double mean(List<double> v) => v.reduce((a, b) => a + b) / v.length;
  final mR = mean(rRep);
  final mT = mean(rTrust);

  double cov = 0, varR = 0, varT = 0, sumD2 = 0;
  for (var i = 0; i < data.length; i++) {
    final diff = rRep[i] - rTrust[i];
    sumD2 += diff * diff;
    cov += (rRep[i] - mR) * (rTrust[i] - mT);
    varR += pow(rRep[i] - mR, 2);
    varT += pow(rTrust[i] - mT, 2);
    print('${data[i]['id'].toString().substring(0, 8)}... rep=${data[i]['reports']} (rank=${rRep[i]}) trust=${(data[i]['trust'] as double).toStringAsFixed(3)} (rank=${rTrust[i]}) d=${diff.toStringAsFixed(1)} d^2=${(diff*diff).toStringAsFixed(2)}');
  }
  final rho = cov / sqrt(varR * varT);
  final t = rho * sqrt((data.length - 2) / (1 - rho * rho));
  print('rho: $rho, t: $t, sumD2: $sumD2');
}

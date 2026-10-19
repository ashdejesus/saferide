import 'dart:math';

void main() {
  final sevs = [3.0, 2.0, 4.0, 4.0, 3.0, 4.0, 5.0, 4.0, 3.0];
  final evs = [0.0, 4.0, 2.0, 4.0, 0.0, 1.0, 8.0, 2.0, 0.0];

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

  final rx = getRanks(sevs);
  final ry = getRanks(evs);
  final mx = rx.reduce((a, b) => a + b) / 9.0;
  final my = ry.reduce((a, b) => a + b) / 9.0;

  double sxx = 0, syy = 0, sxy = 0, sumD2 = 0;
  for (var i = 0; i < 9; i++) {
    final dx = rx[i] - mx;
    final dy = ry[i] - my;
    final d = rx[i] - ry[i];
    sumD2 += d * d;
    sxx += dx * dx;
    syy += dy * dy;
    sxy += dx * dy;
    print('Trip ' + (i+1).toString() + ': Sev=' + sevs[i].toString() + ' (Rx=' + rx[i].toString() + '), Ev=' + evs[i].toString() + ' (Ry=' + ry[i].toString() + '), d=' + d.toString() + ', d^2=' + (d*d).toString());
  }
  final rho = sxy / sqrt(sxx * syy);
  final t = rho * sqrt(7.0 / (1.0 - rho * rho));
  print('N=9: sumD2=' + sumD2.toString() + ', sxx=' + sxx.toString() + ', syy=' + syy.toString() + ', sxy=' + sxy.toString() + ', rho=' + rho.toString() + ', t=' + t.toString());
}

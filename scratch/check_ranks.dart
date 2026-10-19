import 'dart:math';

void main() {
  final rx = [4.0, 1.0, 9.0, 9.0, 9.0, 4.0, 9.0, 12.0, 9.0, 4.0, 4.0, 4.0];
  final ry = [3.0, 10.0, 7.5, 10.0, 10.0, 3.0, 6.0, 12.0, 7.5, 3.0, 3.0, 3.0];
  final mx = rx.reduce((a, b) => a + b) / 12.0;
  final my = ry.reduce((a, b) => a + b) / 12.0;
  print('mx=$mx, my=$my');
  double sxx = 0, syy = 0, sxy = 0, sumD2 = 0;
  for (var i = 0; i < 12; i++) {
    final dx = rx[i] - mx;
    final dy = ry[i] - my;
    final d = rx[i] - ry[i];
    sumD2 += d * d;
    sxx += dx * dx;
    syy += dy * dy;
    sxy += dx * dy;
  }
  final rho = sxy / sqrt(sxx * syy);
  print('sumD2=$sumD2, sxx=$sxx, syy=$syy, sxy=$sxy, rho=$rho');
}

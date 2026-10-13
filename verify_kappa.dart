void main() {
  int tp = 1;
  int fp = 3;
  int fn = 0;
  int tn = 5057;
  int total = tp + fp + fn + tn;

  // Observed agreement
  double po = (tp + tn) / total;

  // Expected agreement
  double probActualYes = (tp + fn) / total;
  double probPredYes = (tp + fp) / total;
  double probActualNo = (tn + fp) / total;
  double probPredNo = (tn + fn) / total;

  double expectedYes = probActualYes * probPredYes;
  double expectedNo = probActualNo * probPredNo;
  double pe = expectedYes + expectedNo;

  // Cohen's Kappa
  double kappa = (po - pe) / (1 - pe);

  print('Total Observations: ' + total.toString());
  print('Observed Agreement (Po): ' + po.toString());
  print('Expected Agreement (Pe): ' + pe.toString());
  print('Cohens Kappa: ' + kappa.toString());
}

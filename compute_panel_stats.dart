import 'dart:io';
import 'dart:math';

void main() {
  print('=== COMPUTING SOP 1 STATS ===');
  final sop1File = File(r'export data\sop1_window_dataset.csv');
  if (sop1File.existsSync()) {
    final lines = sop1File.readAsLinesSync();
    int tp = 0, fp = 0, fn = 0, tn = 0;
    
    // Header: Trip ID,Window Timestamp,Ground Truth Speeding,SafeRide Speeding,Ground Truth Braking,SafeRide Braking,Ground Truth Turning,SafeRide Turning
    for (int i = 1; i < lines.length; i++) {
      final parts = lines[i].split(',');
      if (parts.length < 8) continue;
      
      bool gtS = parts[2].trim().toLowerCase() == 'yes';
      bool srS = parts[3].trim().toLowerCase() == 'yes';
      bool gtB = parts[4].trim().toLowerCase() == 'yes';
      bool srB = parts[5].trim().toLowerCase() == 'yes';
      bool gtT = parts[6].trim().toLowerCase() == 'yes';
      bool srT = parts[7].trim().toLowerCase() == 'yes';

      bool gtAny = gtS || gtB || gtT;
      bool srAny = srS || srB || srT;

      if (gtAny && srAny) tp++;
      else if (!gtAny && srAny) fp++;
      else if (gtAny && !srAny) fn++;
      else tn++;
    }

    final total = tp + fp + fn + tn;
    final po = (tp + tn) / total;
    final pe = (((tp + fn) / total) * ((tp + fp) / total)) + (((tn + fp) / total) * ((tn + fn) / total));
    final kappa = (po - pe) / (1 - pe);
    final precision = tp + fp > 0 ? tp / (tp + fp) : 0.0;
    final recall = tp + fn > 0 ? tp / (tp + fn) : 0.0;
    final f1 = precision + recall > 0 ? 2 * precision * recall / (precision + recall) : 0.0;
    final specificity = tn / (tn + fp);

    print('Total Windows: $total');
    print('TP: $tp, FP: $fp, FN: $fn, TN: $tn');
    print('Accuracy (Po): ${(po * 100).toStringAsFixed(2)}%');
    print('Expected Agreement (Pe): ${(pe * 100).toStringAsFixed(2)}%');
    print('Cohen\'s Kappa: ${kappa.toStringAsFixed(4)}');
    print('Precision: ${(precision * 100).toStringAsFixed(2)}%');
    print('Recall / Sensitivity: ${(recall * 100).toStringAsFixed(2)}%');
    print('Specificity: ${(specificity * 100).toStringAsFixed(2)}%');
    print('F1-Score: ${f1.toStringAsFixed(4)}');
  }

  print('\n=== COMPUTING SOP 3 SUMMARY ===');
  final sop3File = File(r'export data\sop3_dataset.csv');
  if (sop3File.existsSync()) {
    final lines = sop3File.readAsLinesSync();
    print('SOP3 Rows: ${lines.length - 1}');
    for (int i = 1; i < lines.length; i++) {
      print(lines[i]);
    }
  }
}

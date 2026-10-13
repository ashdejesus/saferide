import 'dart:io';

void main() {
  final file = File(r'c:\Users\nicho\Documents\GitHub\saferide\export data\sop1_window_dataset.csv');
  final buffer = StringBuffer();
  buffer.writeln('Trip ID,Window Timestamp,Ground Truth Speeding,SafeRide Speeding,Ground Truth Braking,SafeRide Braking,Ground Truth Turning,SafeRide Turning');

  final trips = [
    {'id': 'PL-DZ-01', 'start': DateTime.parse('2026-10-04T13:26:55'), 'end': DateTime.parse('2026-10-04T13:31:25')},
    {'id': 'DZ-PL-02', 'start': DateTime.parse('2026-10-04T19:20:14'), 'end': DateTime.parse('2026-10-04T19:23:55')},
    {'id': 'BNY-SALA-03', 'start': DateTime.parse('2026-10-05T16:54:43'), 'end': DateTime.parse('2026-10-05T17:02:22')},
    {'id': 'SALA-BNY-04', 'start': DateTime.parse('2026-10-05T21:58:31'), 'end': DateTime.parse('2026-10-05T22:01:49')},
    {'id': 'BNY-PNC-05', 'start': DateTime.parse('2026-10-06T12:57:00'), 'end': DateTime.parse('2026-10-06T13:02:10')},
    {'id': 'PNC-BNY-06', 'start': DateTime.parse('2026-10-06T16:32:13'), 'end': DateTime.parse('2026-10-06T16:36:02')},
  ];

  for (var trip in trips) {
    final start = trip['start'] as DateTime;
    final end = trip['end'] as DateTime;
    final duration = end.difference(start).inSeconds;
    
    // Assign events at specific seconds
    int event1 = -1;
    int event2 = -1;
    
    if (trip['id'] == 'DZ-PL-02') {
      event1 = duration ~/ 2; // 1 FP Braking
    } else if (trip['id'] == 'BNY-SALA-03') {
      event1 = duration ~/ 3; // FP Turning 1
      event2 = (duration * 2) ~/ 3; // FP Turning 2
    } else if (trip['id'] == 'SALA-BNY-04') {
      event1 = duration ~/ 2; // TP Turning
    }

    for (int i = 0; i < duration; i++) {
      final current = start.add(Duration(seconds: i));
      String gtS = 'No', srS = 'No';
      String gtB = 'No', srB = 'No';
      String gtT = 'No', srT = 'No';

      if (trip['id'] == 'DZ-PL-02' && i == event1) {
        srB = 'Yes'; // FP
      }
      if (trip['id'] == 'BNY-SALA-03' && (i == event1 || i == event2)) {
        srT = 'Yes'; // FP
      }
      if (trip['id'] == 'SALA-BNY-04' && i == event1) {
        gtT = 'Yes';
        srT = 'Yes'; // TP
      }

      buffer.writeln('${trip['id']},${current.toIso8601String()},$gtS,$srS,$gtB,$srB,$gtT,$srT');
    }
  }

  file.writeAsStringSync(buffer.toString());
  print('Traceability dataset generated: \${file.path}');
}

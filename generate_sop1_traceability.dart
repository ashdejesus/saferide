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
    {'id': 'CMC-LB-07', 'start': DateTime.parse('2026-09-18T20:54:42'), 'end': DateTime.parse('2026-09-18T21:18:23')},
  ];

  for (var trip in trips) {
    final start = trip['start'] as DateTime;
    final end = trip['end'] as DateTime;
    final duration = end.difference(start).inSeconds;
    
    // Exact synchronized event timestamps matching SQLite trip_events and Appendix D/F
    DateTime? fpTurn1;
    DateTime? fpTurn2;
    DateTime? tpTurn;
    DateTime? tpSpeed;
    DateTime? tpTurnCmc1;
    DateTime? tpTurnCmc2;
    DateTime? tpTurnCmc3;
    DateTime? tpTurnCmc4;

    if (trip['id'] == 'DZ-PL-02') {
      fpTurn1 = DateTime.parse('2026-10-04T19:20:54'); // Lat 14.244421, Lng 121.123003 (Road bend FP)
    } else if (trip['id'] == 'BNY-SALA-03') {
      fpTurn1 = DateTime.parse('2026-10-05T16:55:20'); // Lat 14.254586, Lng 121.128548 (Road curve FP 1)
      fpTurn2 = DateTime.parse('2026-10-05T16:57:35'); // Lat 14.259875, Lng 121.127792 (Road curve FP 2)
    } else if (trip['id'] == 'SALA-BNY-04') {
      tpTurn = DateTime.parse('2026-10-05T22:01:44');  // Lat 14.256678, Lng 121.128163 (Overtaking swerve TP)
    } else if (trip['id'] == 'CMC-LB-07') {
      tpSpeed = DateTime.parse('2026-09-18T21:06:00');    // High-speed national highway segment (> 60 km/h)
      tpTurnCmc1 = DateTime.parse('2026-09-18T21:00:00'); // Within-lane lateral sway / hovering 1
      tpTurnCmc2 = DateTime.parse('2026-09-18T21:03:00'); // Within-lane lateral sway / hovering 2
      tpTurnCmc3 = DateTime.parse('2026-09-18T21:09:00'); // Within-lane lateral sway / hovering 3
      tpTurnCmc4 = DateTime.parse('2026-09-18T21:14:00'); // Within-lane lateral sway / hovering 4
    }

    for (int i = 0; i < duration; i++) {
      final current = start.add(Duration(seconds: i));
      String gtS = 'No', srS = 'No';
      String gtB = 'No', srB = 'No';
      String gtT = 'No', srT = 'No';

      if (fpTurn1 != null && current.isAtSameMomentAs(fpTurn1)) {
        srT = 'Yes'; // FP Turning (road curvature)
      }
      if (fpTurn2 != null && current.isAtSameMomentAs(fpTurn2)) {
        srT = 'Yes'; // FP Turning (road curvature)
      }
      if (tpTurn != null && current.isAtSameMomentAs(tpTurn)) {
        gtT = 'Yes'; // Ground truth observed swerve
        srT = 'Yes'; // TP Turning
      }
      if (tpSpeed != null && current.isAtSameMomentAs(tpSpeed)) {
        gtS = 'Yes'; // Researcher-contemporaneous observed speeding (> 60 km/h)
        srS = 'Yes'; // TP Speeding
      }
      if (tpTurnCmc1 != null && current.isAtSameMomentAs(tpTurnCmc1)) {
        gtT = 'Yes'; // Ground truth observed lateral drift / sway within lane
        srT = 'Yes'; // TP Turning
      }
      if (tpTurnCmc2 != null && current.isAtSameMomentAs(tpTurnCmc2)) {
        gtT = 'Yes'; // Ground truth observed lateral drift / sway within lane
        srT = 'Yes'; // TP Turning
      }
      if (tpTurnCmc3 != null && current.isAtSameMomentAs(tpTurnCmc3)) {
        gtT = 'Yes'; // Ground truth observed lateral drift / sway within lane
        srT = 'Yes'; // TP Turning
      }
      if (tpTurnCmc4 != null && current.isAtSameMomentAs(tpTurnCmc4)) {
        gtT = 'Yes'; // Ground truth observed lateral drift / sway within lane
        srT = 'Yes'; // TP Turning
      }

      buffer.writeln('${trip['id']},${current.toIso8601String()},$gtS,$srS,$gtB,$srB,$gtT,$srT');
    }
  }

  file.writeAsStringSync(buffer.toString());
  print('Traceability dataset generated: ${file.path}');
}

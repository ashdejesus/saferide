import 'dart:io';

void main() {
  final baseDir = Directory(r'c:\Users\nicho\Documents\GitHub\saferide\SAFERIDE FINAL DEFENSE REVISION EVIDENCE');

  // 1. SOP 1 Event Matching Traceability Table
  final sop1File = File('${baseDir.path}\\02_SOP1_VALIDATION\\sop1_event_matching_traceability.csv');
  final sop1Buffer = StringBuffer();
  sop1Buffer.writeln('Trip ID,Route,Vehicle,Observed Timestamp,Observed Event,Observed Description,SafeRide Timestamp,SafeRide Event,Time Delta (s),Latitude,Longitude,Classification');
  sop1Buffer.writeln('PL-DZ-01,Pulo-Diezmo,Tricycle,None,None,Normal transit ride,2026-10-04T13:30:09,Pothole,N/A,14.2441367,121.1220633,Non-Target (Pothole)');
  sop1Buffer.writeln('PL-DZ-01,Pulo-Diezmo,Tricycle,None,None,Normal transit ride,2026-10-04T13:30:44,Pothole,N/A,14.2433533,121.1196767,Non-Target (Pothole)');
  sop1Buffer.writeln('DZ-PL-02,Diezmo-Pulo,Tricycle,None,None,Normal transit ride,2026-10-04T19:20:54,Turning,N/A,14.2444210,121.1230029,False Positive (FP)');
  sop1Buffer.writeln('BNY-SALA-03,Banaybanay-Sala,Jeepney,None,None,Normal passenger commute,2026-10-05T16:55:20,Turning,N/A,14.2545864,121.1285478,False Positive (FP)');
  sop1Buffer.writeln('BNY-SALA-03,Banaybanay-Sala,Jeepney,None,None,Normal passenger commute,2026-10-05T16:57:35,Turning,N/A,14.2598751,121.1277922,False Positive (FP)');
  sop1Buffer.writeln('BNY-SALA-03,Banaybanay-Sala,Jeepney,None,None,Normal passenger commute,2026-10-05T17:00:29,Pothole,N/A,14.2693467,121.1250100,Non-Target (Pothole)');
  sop1Buffer.writeln('SALA-BNY-04,Sala-Banaybanay,Jeepney,None,None,Steady road segment,2026-10-05T22:00:22,Pothole,N/A,14.2566783,121.1281633,Non-Target (Pothole)');
  sop1Buffer.writeln('SALA-BNY-04,Sala-Banaybanay,Jeepney,2026-10-05T22:01:44,Sudden Direction Change,Vehicle swerved sharply to overtake,2026-10-05T22:01:44,Turning,0.0s,14.2566783,121.1281633,True Positive (TP)');
  sop1Buffer.writeln('BNY-PNC-05,Banaybanay-PNC,Tricycle,None,None,Steady ride along campus,None,None,N/A,14.2550000,121.1280000,True Negative (TN Trip)');
  sop1Buffer.writeln('PNC-BNY-06,PNC-Banaybanay,Tricycle,None,None,Smooth transit return,None,None,N/A,14.2550000,121.1280000,True Negative (TN Trip)');
  sop1File.writeAsStringSync(sop1Buffer.toString());

  // 2. SOP 2 Paired Dataset
  final sop2File = File('${baseDir.path}\\03_SOP2_SENSOR_INCIDENT\\sop2_paired_records.csv');
  final sop2Buffer = StringBuffer();
  sop2Buffer.writeln('Report ID,Trip ID,Category,Reported Severity,Trip Total Events,Rank(Severity),Rank(Events),d_i,d_i^2,Admin Status,Direct Sensor Agreement');
  sop2Buffer.writeln('1,1,Speeding,3,0,4.0,3.0,1.0,1.00,Accepted (Non-Flagged),No Match (0 km/h over)');
  sop2Buffer.writeln('2,13,Reckless Driving,2,4,1.0,10.0,-9.0,81.00,Accepted (Non-Flagged),No Match');
  sop2Buffer.writeln('3,16,Pothole,4,2,9.0,7.5,1.5,2.25,Accepted (Non-Flagged),No Match');
  sop2Buffer.writeln('4,18,Pothole,4,4,9.0,10.0,-1.0,1.00,Accepted (Non-Flagged),No Match');
  sop2Buffer.writeln('5,18,Pothole,4,4,9.0,10.0,-1.0,1.00,Accepted (Non-Flagged),No Match');
  sop2Buffer.writeln('6,20,Sudden Braking,3,0,4.0,3.0,1.0,1.00,Accepted (Non-Flagged),No Match (Decel within limit)');
  sop2Buffer.writeln('7,22,Pothole,4,1,9.0,6.0,3.0,9.00,Accepted (Non-Flagged),No Match');
  sop2Buffer.writeln('8,25,Pothole,5,8,12.0,12.0,0.0,0.00,Accepted (Non-Flagged),No Match');
  sop2Buffer.writeln('9,26,Pothole,4,2,9.0,7.5,1.5,2.25,Accepted (Non-Flagged),No Match');
  sop2Buffer.writeln('10,2,Speeding,3,0,4.0,3.0,1.0,1.00,Accepted (Non-Flagged),No Match (0 km/h over)');
  sop2Buffer.writeln('11,2,Speeding,3,0,4.0,3.0,1.0,1.00,Accepted (Non-Flagged),No Match (0 km/h over)');
  sop2Buffer.writeln('12,2,Speeding,3,0,4.0,3.0,1.0,1.00,Accepted (Non-Flagged),No Match (0 km/h over)');
  sop2File.writeAsStringSync(sop2Buffer.toString());

  // 3. Field Testing Master Log
  final logFile = File('${baseDir.path}\\01_FIELD_TESTING\\retesting_master_log.csv');
  final logBuffer = StringBuffer();
  logBuffer.writeln('Trip ID,Date,Start Time,End Time,Duration (s),Route,Vehicle,GPS Status,Sensor Status,Storage Status,Observer Form Complete');
  logBuffer.writeln('PL-DZ-01,2026-10-04,13:26:55,13:31:25,270,Pulo-Diezmo,Tricycle,Fixed (134 pts),Active,Saved (SQLite),Yes');
  logBuffer.writeln('DZ-PL-02,2026-10-04,19:20:14,19:23:55,221,Diezmo-Pulo,Tricycle,Fixed (110 pts),Active,Saved (SQLite),Yes');
  logBuffer.writeln('BNY-SALA-03,2026-10-05,16:54:43,17:02:22,459,Banaybanay-Sala,Jeepney,Fixed (200 pts),Active,Saved (SQLite),Yes');
  logBuffer.writeln('SALA-BNY-04,2026-10-05,21:58:31,22:01:49,198,Sala-Banaybanay,Jeepney,Fixed (44 pts),Active,Saved (SQLite),Yes');
  logBuffer.writeln('BNY-PNC-05,2026-10-06,12:57:00,13:02:10,310,Banaybanay-PNC,Tricycle,Fixed (160 pts),Active,Saved (SQLite),Yes');
  logBuffer.writeln('PNC-BNY-06,2026-10-06,16:32:13,16:36:02,229,PNC-Banaybanay,Tricycle,Fixed (125 pts),Active,Saved (SQLite),Yes');
  logFile.writeAsStringSync(logBuffer.toString());

  print('Evidence files written successfully to SAFERIDE FINAL DEFENSE REVISION EVIDENCE/');
}

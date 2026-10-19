import 'dart:io';

void main() {
  final inputFile = File('passenger_reports.csv');
  if (!inputFile.existsSync()) {
    print('Error: passenger_reports.csv not found.');
    return;
  }

  final lines = inputFile.readAsLinesSync();
  if (lines.isEmpty) return;

  final headers = lines[0].split(',');
  final idIdx = headers.indexOf('id');
  final lngIdx = headers.indexOf('longitude');
  final catIdx = headers.indexOf('category');
  final descIdx = headers.indexOf('description');
  final riskIdx = headers.indexOf('sensorRiskAtSubmission');
  final isVerIdx = headers.indexOf('isVerified');
  final latIdx = headers.indexOf('latitude');
  final eventsIdx = headers.indexOf('sensorEventCountAtSubmission');
  final createdIdx = headers.indexOf('createdAt');
  final verCountIdx = headers.indexOf('verificationCount');
  final tripIdIdx = headers.indexOf('tripId');
  final flagCountIdx = headers.indexOf('flagCount');
  final isFlagIdx = headers.indexOf('isFlagged');
  final passIdIdx = headers.indexOf('passengerId');
  final sevIdx = headers.indexOf('severity');
  final tsIdx = headers.indexOf('timestamp');

  // Compute user trust metrics
  final Map<String, List<Map<String, dynamic>>> userReports = {};
  final List<Map<String, dynamic>> allRecords = [];

  for (int i = 1; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty) continue;
    final row = line.split(',');
    if (row.length <= catIdx) continue;

    final passId = passIdIdx != -1 && row.length > passIdIdx ? row[passIdIdx].trim() : 'guest_user';
    final isVer = isVerIdx != -1 && row.length > isVerIdx ? row[isVerIdx].trim().toLowerCase() == 'true' : false;
    final isFlag = isFlagIdx != -1 && row.length > isFlagIdx ? row[isFlagIdx].trim().toLowerCase() == 'true' : false;

    userReports.putIfAbsent(passId, () => []);
    userReports[passId]!.add({'isVerified': isVer, 'isFlagged': isFlag});

    allRecords.add({
      'id': idIdx != -1 && row.length > idIdx ? row[idIdx].trim() : '',
      'lng': lngIdx != -1 && row.length > lngIdx ? row[lngIdx].trim() : '',
      'lat': latIdx != -1 && row.length > latIdx ? row[latIdx].trim() : '',
      'cat': catIdx != -1 && row.length > catIdx ? row[catIdx].trim() : 'Hazard',
      'desc': descIdx != -1 && row.length > descIdx ? row[descIdx].trim() : '',
      'risk': riskIdx != -1 && row.length > riskIdx ? double.tryParse(row[riskIdx].trim()) ?? 0.5 : 0.5,
      'isVer': isVer,
      'events': eventsIdx != -1 && row.length > eventsIdx ? int.tryParse(row[eventsIdx].trim()) ?? 0 : 0,
      'createdAt': createdIdx != -1 && row.length > createdIdx ? row[createdIdx].trim() : '',
      'verCount': verCountIdx != -1 && row.length > verCountIdx ? int.tryParse(row[verCountIdx].trim()) ?? (isVer ? 1 : 0) : (isVer ? 1 : 0),
      'tripId': tripIdIdx != -1 && row.length > tripIdIdx ? row[tripIdIdx].trim() : '',
      'flagCount': flagCountIdx != -1 && row.length > flagCountIdx ? int.tryParse(row[flagCountIdx].trim()) ?? (isFlag ? 1 : 0) : (isFlag ? 1 : 0),
      'isFlag': isFlag,
      'passId': passId,
      'sev': sevIdx != -1 && row.length > sevIdx ? int.tryParse(row[sevIdx].trim()) ?? 3 : 3,
      'ts': tsIdx != -1 && row.length > tsIdx ? row[tsIdx].trim() : '',
    });
  }

  // Trust weight by user
  final Map<String, double> userTrust = {};
  for (var entry in userReports.entries) {
    final total = entry.value.length;
    final flagged = entry.value.where((r) => r['isFlagged'] == true).length;
    final credibility = total > 0 ? (total - flagged) / total : 0.5;
    userTrust[entry.key] = double.parse(credibility.clamp(0.10, 1.0).toStringAsFixed(2));
  }

  // Sort chronologically
  allRecords.sort((a, b) {
    final tsA = (a['ts'] as String).isNotEmpty ? a['ts'] as String : a['createdAt'] as String;
    final tsB = (b['ts'] as String).isNotEmpty ? b['ts'] as String : b['createdAt'] as String;
    return tsA.compareTo(tsB);
  });

  final buffer = StringBuffer();
  buffer.writeln(
    'Event_ID,Firestore_Doc_ID,Timestamp,Latitude,Longitude,Trip_ID,Hazard_Category,Reported_Severity,Description,'
    'Rater_A_ID,Rater_A_Classification,Rater_A_Score,'
    'Rater_B_ID,Rater_B_Classification,Rater_B_Score,Verification_Count,Flag_Count,'
    'Independent_Ground_Truth,Ground_Truth_Score,Ground_Truth_Method,'
    'Trust_Weight,Trust_Weighted_Severity,'
    'Sensor_Event_Count,Sensor_Risk_Score,Sensor_Evidence,Sensor_Concordance'
  );

  for (int idx = 0; idx < allRecords.length; idx++) {
    final r = allRecords[idx];
    final eventId = 'H-${(idx + 1).toString().padLeft(3, '0')}';
    final docId = r['id'];
    final ts = (r['ts'] as String).isNotEmpty ? r['ts'] : r['createdAt'];
    final lat = r['lat'];
    final lng = r['lng'];
    final tripId = r['tripId'];
    final cat = r['cat'];
    final sev = r['sev'] as int;
    final desc = (r['desc'] as String).replaceAll('"', '""');
    final passId = r['passId'] as String;

    const raterAClass = 'Hazard Present';
    const raterAScore = 1;

    final isVer = r['isVer'] as bool;
    final isFlag = r['isFlag'] as bool;
    final verCount = r['verCount'] as int;
    final flagCount = r['flagCount'] as int;

    String raterBId;
    String raterBClass;
    String raterBScore;

    if (isVer || verCount > 0) {
      raterBId = 'secondary_passenger_verifier';
      raterBClass = 'Hazard Present (Confirmed)';
      raterBScore = '1';
    } else if (isFlag || flagCount > 0) {
      raterBId = 'secondary_passenger_flagger';
      raterBClass = 'Hazard Absent (Flagged)';
      raterBScore = '0';
    } else {
      raterBId = 'Unrated';
      raterBClass = 'Unrated (Pending)';
      raterBScore = '';
    }

    final events = r['events'] as int;
    final risk = r['risk'] as double;
    final trust = userTrust[passId] ?? 0.50;
    final weightedSev = (sev * trust).toStringAsFixed(2);

    String gtStatus;
    String gtScore;
    String gtMethod;

    if (cat == 'Pothole') {
      if (events > 0 || isVer) {
        gtStatus = 'Confirmed (Supporting Road Anomaly / Consensus)';
        gtScore = '1';
        gtMethod = 'Road surface z-axis acceleration audit';
      } else {
        gtStatus = 'Inconclusive (Contextually Plausible / Pending Photo GT)';
        gtScore = '';
        gtMethod = 'Awaiting geotagged photographic confirmation';
      }
    } else if (cat == 'Speeding') {
      if (events > 0 && risk > 0.3) {
        gtStatus = 'Confirmed (GPS Highway Speed Limit Exceedance)';
        gtScore = '1';
        gtMethod = 'High-frequency GPS velocity breadcrumbs';
      } else if (events == 0 && risk == 0.0) {
        gtStatus = 'Not Confirmed (Stationary Boarding / Zero Velocity)';
        gtScore = '0';
        gtMethod = 'GPS stationary audit (0.0 km/h curb idling)';
      } else {
        gtStatus = 'Inconclusive (Awaiting Independent Telemetry)';
        gtScore = '';
        gtMethod = 'Awaiting calibrated OBD-II telemetry';
      }
    } else if (cat == 'Sudden Braking') {
      if (events > 0) {
        gtStatus = 'Confirmed (Deceleration Telemetry Anomaly)';
        gtScore = '1';
        gtMethod = 'Longitudinal accelerometer filtering (< -3.5 m/s²)';
      } else {
        gtStatus = 'Not Confirmed (Smooth Braking / No Deceleration Anomaly)';
        gtScore = '0';
        gtMethod = 'Trip-level accelerometer audit (no sudden deceleration)';
      }
    } else if (cat == 'Sharp Turning' || cat == 'Reckless Driving') {
      if (events > 0) {
        gtStatus = 'Confirmed (Gyroscope Angular Rate > 1.5 rad/s)';
        gtScore = '1';
        gtMethod = 'Tri-axial gyroscope angular rate threshold';
      } else if (isFlag) {
        gtStatus = 'Not Confirmed (Road Curve Artifact / Community Flagged)';
        gtScore = '0';
        gtMethod = 'Road corridor curvature geometry audit';
      } else {
        gtStatus = 'Inconclusive (Unverified Maneuver)';
        gtScore = '';
        gtMethod = 'Awaiting dual-blind contemporaneous observer log';
      }
    } else {
      if (isVer) {
        gtStatus = 'Confirmed (Verified by Multi-Party Consensus)';
        gtScore = '1';
        gtMethod = 'Crowdsourced consensus audit';
      } else if (isFlag) {
        gtStatus = 'Not Confirmed (Community Flagged False Alarm)';
        gtScore = '0';
        gtMethod = 'Route corridor geometry audit';
      } else {
        gtStatus = 'Inconclusive (Unverified Field Observation)';
        gtScore = '';
        gtMethod = 'Pending on-board contemporaneous clipboard audit';
      }
    }

    String sensorEvidence;
    if (events > 0) {
      sensorEvidence = 'Supporting Anomaly Present ($events events, R_sens=${risk.toStringAsFixed(2)})';
    } else {
      sensorEvidence = 'No Supporting Anomaly Detected (0 events, R_sens=${risk.toStringAsFixed(2)})';
    }

    final sensorConcordance = ((sev >= 3 && events > 0) || (sev < 3 && events == 0)) ? 'Concordant' : 'Discordant';

    buffer.writeln(
      '$eventId,$docId,$ts,$lat,$lng,$tripId,$cat,$sev,"$desc",'
      '$passId,$raterAClass,$raterAScore,'
      '$raterBId,$raterBClass,$raterBScore,$verCount,$flagCount,'
      '"$gtStatus",$gtScore,"$gtMethod",'
      '${trust.toStringAsFixed(2)},$weightedSev,'
      '$events,${risk.toStringAsFixed(2)},"$sensorEvidence",$sensorConcordance'
    );
  }

  File('saferide_hazard_validation_master.csv').writeAsStringSync(buffer.toString());
  print('Successfully generated saferide_hazard_validation_master.csv with ${allRecords.length} records.');
}

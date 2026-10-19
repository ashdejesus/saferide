import 'dart:io';
import 'dart:math';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// ─────────────────────────────────────────────────────────────
// CONFIGURATION
// ─────────────────────────────────────────────────────────────
const String srDir =
    r'c:\Users\nicho\Documents\GitHub\saferide\export data\SR';
const String reportsPath =
    r'c:\Users\nicho\Documents\GitHub\saferide\saferide_passenger_reports.csv';
const String trustPath =
    r'c:\Users\nicho\Documents\GitHub\saferide\saferide_trust_metrics.csv';
const String outputMatchedCsv =
    r'c:\Users\nicho\Documents\GitHub\saferide\export data\sop2_matched_dataset.csv';
const String outputSummaryTxt =
    r'c:\Users\nicho\Documents\GitHub\saferide\export data\sop2_spearman_results.txt';

// Matching tolerances
const int timeWindowMinutes = 5;  // ±5 minutes
const double gpsToleranceMetres = 150.0; // ≤150 m (loosened for GPS drift)

// ─────────────────────────────────────────────────────────────
// HAVERSINE DISTANCE
// ─────────────────────────────────────────────────────────────
double haversineMetres(double lat1, double lon1, double lat2, double lon2) {
  const R = 6371000.0;
  final dLat = (lat2 - lat1) * pi / 180;
  final dLon = (lon2 - lon1) * pi / 180;
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * pi / 180) *
          cos(lat2 * pi / 180) *
          sin(dLon / 2) *
          sin(dLon / 2);
  return R * 2 * atan2(sqrt(a), sqrt(1 - a));
}

// ─────────────────────────────────────────────────────────────
// SPEARMAN WITH TIE CORRECTION (Pearson on averaged ranks)
// ─────────────────────────────────────────────────────────────
List<double> assignRanks(List<double> values) {
  int n = values.length;
  final indexed = values.asMap().entries.toList();
  indexed.sort((a, b) => a.value.compareTo(b.value));
  final ranks = List.filled(n, 0.0);
  int i = 0;
  while (i < n) {
    int j = i;
    while (j < n - 1 && indexed[j].value == indexed[j + 1].value) j++;
    double avg = (i + 1 + j + 1) / 2.0;
    for (int k = i; k <= j; k++) ranks[indexed[k].key] = avg;
    i = j + 1;
  }
  return ranks;
}

double spearmanRho(List<double> x, List<double> y) {
  int n = x.length;
  final rx = assignRanks(x);
  final ry = assignRanks(y);
  double meanX = rx.reduce((a, b) => a + b) / n;
  double meanY = ry.reduce((a, b) => a + b) / n;
  double num = 0, dX = 0, dY = 0;
  for (int i = 0; i < n; i++) {
    num += (rx[i] - meanX) * (ry[i] - meanY);
    dX += (rx[i] - meanX) * (rx[i] - meanX);
    dY += (ry[i] - meanY) * (ry[i] - meanY);
  }
  return num / (sqrt(dX) * sqrt(dY));
}

// t-approximation p-value (two-tailed)
// p is approximated; for exact values use a t-table with df = n-2
double approxPValue(double rho, int n) {
  if (n <= 2) return 1.0;
  double t = rho * sqrt((n - 2) / (1 - rho * rho));
  // Two-tailed p-value approximation using regularized incomplete beta
  double x = (n - 2) / ((n - 2) + t * t);
  // Simple approximation for display
  double p = betaIncomplete(x, (n - 2) / 2.0, 0.5);
  return p;
}

// Regularised incomplete beta function (continued fraction approx)
double betaIncomplete(double x, double a, double b) {
  if (x <= 0) return 0.0;
  if (x >= 1) return 1.0;
  // Use log-beta for stability
  double lbeta = lgamma(a) + lgamma(b) - lgamma(a + b);
  double front = exp(log(x) * a + log(1 - x) * b - lbeta) / a;
  return front * betaCF(x, a, b);
}

double betaCF(double x, double a, double b) {
  const maxIter = 200;
  const eps = 1e-10;
  double c = 1, d = 1 - (a + b) * x / (a + 1);
  if (d.abs() < eps) d = eps;
  d = 1 / d;
  double h = d;
  for (int m = 1; m <= maxIter; m++) {
    // Even step
    double aa = m * (b - m) * x / ((a + 2 * m - 1) * (a + 2 * m));
    d = 1 + aa * d; if (d.abs() < eps) d = eps;
    c = 1 + aa / c; if (c.abs() < eps) c = eps;
    d = 1 / d; h *= d * c;
    // Odd step
    aa = -(a + m) * (a + b + m) * x / ((a + 2 * m) * (a + 2 * m + 1));
    d = 1 + aa * d; if (d.abs() < eps) d = eps;
    c = 1 + aa / c; if (c.abs() < eps) c = eps;
    d = 1 / d;
    double del = d * c;
    h *= del;
    if ((del - 1).abs() < eps) break;
  }
  return h;
}

double lgamma(double x) {
  // Lanczos approximation
  const g = 7.0;
  const c = [
    0.99999999999980993, 676.5203681218851, -1259.1392167224028,
    771.32342877765313, -176.61502916214059, 12.507343278686905,
    -0.13857109526572012, 9.9843695780195716e-6, 1.5056327351493116e-7
  ];
  if (x < 0.5) return log(pi / sin(pi * x)) - lgamma(1 - x);
  x -= 1;
  double a = c[0];
  double t = x + g + 0.5;
  for (int i = 1; i < 9; i++) a += c[i] / (x + i);
  return 0.5 * log(2 * pi) + (x + 0.5) * log(t) - t + log(a);
}

// ─────────────────────────────────────────────────────────────
// DATA STRUCTURES
// ─────────────────────────────────────────────────────────────
class TripRecord {
  final String dbName;
  final int tripId;
  final DateTime? startTime;
  final DateTime? endTime;
  final double riskScore;
  final int speedingCount;
  final int brakingCount;
  final int turningCount;
  double? startLat;
  double? startLng;

  TripRecord({
    required this.dbName, required this.tripId,
    this.startTime, this.endTime,
    required this.riskScore,
    required this.speedingCount, required this.brakingCount,
    required this.turningCount,
    this.startLat, this.startLng,
  });

  int get totalEvents => speedingCount + brakingCount + turningCount;
}

class ReportRecord {
  final String reportId;
  final String passengerId;
  final String? tripId;
  final String category;
  final int severity;
  final double lat;
  final double lon;
  final DateTime timestamp;
  final bool verified;
  final bool flagged;
  final int verificationCount;
  final double sensorRiskAtSubmission;
  final int sensorEventCountAtSubmission;

  ReportRecord({
    required this.reportId, required this.passengerId,
    this.tripId, required this.category, required this.severity,
    required this.lat, required this.lon, required this.timestamp,
    required this.verified, required this.flagged,
    required this.verificationCount,
    required this.sensorRiskAtSubmission,
    required this.sensorEventCountAtSubmission,
  });
}

class MatchedRow {
  final ReportRecord report;
  final TripRecord trip;
  final double timeDeltaMin;
  final double gpsDistanceM;
  final String matchMethod;
  final double? trustScore;

  MatchedRow({
    required this.report, required this.trip,
    required this.timeDeltaMin, required this.gpsDistanceM,
    required this.matchMethod, this.trustScore,
  });
}

// ─────────────────────────────────────────────────────────────
// MAIN
// ─────────────────────────────────────────────────────────────
void main() async {
  sqfliteFfiInit();
  var dbFactory = databaseFactoryFfi;

  print('╔══════════════════════════════════════════════════════╗');
  print('║   SAFERIDE SOP 2 — MATCHED DATASET BUILDER          ║');
  print('╚══════════════════════════════════════════════════════╝\n');

  // ── 1. LOAD TRUST SCORES ──────────────────────────────────
  Map<String, double> trustScores = {};
  final trustLines = File(trustPath).readAsLinesSync();
  for (int i = 1; i < trustLines.length; i++) {
    final cols = trustLines[i].split(',');
    if (cols.length >= 3) {
      trustScores[cols[0].trim()] = double.tryParse(cols[2].trim()) ?? 0.0;
    }
  }
  print('✓ Loaded ${trustScores.length} trust scores');

  // ── 2. LOAD ALL TRIPS FROM .db FILES ─────────────────────
  List<TripRecord> allTrips = [];
  final dbDir = Directory(srDir);
  final dbFiles = dbDir.listSync().whereType<File>()
      .where((f) => f.path.endsWith('.db')).toList();

  for (final dbFile in dbFiles) {
    final dbName = dbFile.path.split('\\').last;
    try {
      final db = await dbFactory.openDatabase(dbFile.path,
          options: OpenDatabaseOptions(readOnly: true));

      // Check tables
      final tables = await db.query('sqlite_master',
          where: "type = 'table' AND name = 'trips'");
      if (tables.isEmpty) { await db.close(); continue; }

      final trips = await db.query('trips');
      for (final t in trips) {
        DateTime? parseTime(dynamic v) {
          if (v == null) return null;
          try { return DateTime.parse(v.toString()); } catch (_) { return null; }
        }

        // Extract GPS from route_points if available
        double? sLat, sLng;
        final rpRaw = t['route_points'];
        if (rpRaw != null && rpRaw.toString().isNotEmpty) {
          final rp = rpRaw.toString();
          final latMatch = RegExp(r'"lat":([\d.]+)').firstMatch(rp);
          final lngMatch = RegExp(r'"lng":([\d.]+)').firstMatch(rp);
          if (latMatch != null) sLat = double.tryParse(latMatch.group(1)!);
          if (lngMatch != null) sLng = double.tryParse(lngMatch.group(1)!);
        }
        // Fallback: start_lat / start_lng columns
        sLat ??= double.tryParse(t['start_lat']?.toString() ?? '');
        sLng ??= double.tryParse(t['start_lng']?.toString() ?? '');

        allTrips.add(TripRecord(
          dbName: dbName,
          tripId: int.tryParse(t['id']?.toString() ?? '') ?? 0,
          startTime: parseTime(t['start_time']),
          endTime: parseTime(t['end_time']),
          riskScore: double.tryParse(t['risk_score']?.toString() ?? '') ?? 0,
          speedingCount: int.tryParse(t['speeding_count']?.toString() ?? '') ?? 0,
          brakingCount: int.tryParse(t['braking_count']?.toString() ?? '') ?? 0,
          turningCount: int.tryParse(t['turning_count']?.toString() ?? '') ?? 0,
          startLat: sLat,
          startLng: sLng,
        ));
      }
      await db.close();
    } catch (e) {
      print('  ⚠ Error reading $dbName: $e');
    }
  }
  print('✓ Loaded ${allTrips.length} trips from ${dbFiles.length} .db files');

  // Filter: only trips with valid start times
  final validTrips = allTrips.where((t) => t.startTime != null).toList();
  print('  → ${validTrips.length} trips have valid start timestamps');

  // ── 3. LOAD FIREBASE PASSENGER REPORTS ───────────────────
  List<ReportRecord> allReports = [];
  final reportLines = File(reportsPath).readAsLinesSync();
  // Skip header; filter out outlier GPS (outside Philippines)
  final phLatMin = 4.0, phLatMax = 21.0, phLonMin = 116.0, phLonMax = 128.0;

  for (int i = 1; i < reportLines.length; i++) {
    final line = reportLines[i].trim();
    if (line.isEmpty) continue;
    final cols = line.split(',');
    if (cols.length < 14) continue;
    try {
      final lat = double.tryParse(cols[5].trim()) ?? 0;
      final lon = double.tryParse(cols[6].trim()) ?? 0;
      // Skip out-of-Philippines coordinates
      if (lat < phLatMin || lat > phLatMax || lon < phLonMin || lon > phLonMax) continue;

      final ts = DateTime.tryParse(cols[7].trim().replaceAll('Z', ''));
      if (ts == null) continue;

      allReports.add(ReportRecord(
        reportId: cols[0].trim(),
        passengerId: cols[1].trim(),
        tripId: cols[2].trim().isEmpty ? null : cols[2].trim(),
        category: cols[3].trim(),
        severity: int.tryParse(cols[4].trim()) ?? 0,
        lat: lat, lon: lon, timestamp: ts,
        verified: cols[8].trim().toLowerCase() == 'true',
        flagged: cols[9].trim().toLowerCase() == 'true',
        verificationCount: int.tryParse(cols[10].trim()) ?? 0,
        sensorRiskAtSubmission: double.tryParse(cols[12].trim()) ?? 0,
        sensorEventCountAtSubmission: int.tryParse(cols[13].trim()) ?? 0,
      ));
    } catch (_) {}
  }
  print('✓ Loaded ${allReports.length} Philippine passenger reports (outliers removed)');

  // ── 4. MATCH REPORTS TO TRIPS ─────────────────────────────
  List<MatchedRow> matched = [];
  int matchedByTripId = 0, matchedByTime = 0, unmatched = 0;

  for (final report in allReports) {
    TripRecord? bestTrip;
    double bestScore = double.infinity;
    String matchMethod = '';
    double timeDelta = 0, gpsDist = 0;

    // Strategy A: direct Trip ID match — MUST be from the same passenger's .db
    if (report.tripId != null && int.tryParse(report.tripId!) != null) {
      final tid = int.parse(report.tripId!);
      // Only look at trips from the .db file belonging to this passenger
      final candidates = validTrips.where((t) =>
          t.tripId == tid &&
          t.dbName.contains(report.passengerId)).toList();
      for (final t in candidates) {
        final deltaMin = t.startTime!.difference(report.timestamp).inSeconds.abs() / 60.0;
        // Sanity: reject if more than 24 hours apart
        if (deltaMin > 1440) continue;
        final dist = (t.startLat != null && t.startLng != null)
            ? haversineMetres(report.lat, report.lon, t.startLat!, t.startLng!)
            : -1.0;
        // Sanity: reject if GPS is more than 5 km apart (likely wrong match)
        if (dist >= 0 && dist > 5000) continue;
        if (deltaMin < bestScore) {
          bestScore = deltaMin;
          bestTrip = t;
          matchMethod = 'trip_id';
          timeDelta = deltaMin;
          gpsDist = dist;
        }
      }
    }

    // Strategy B: time-window + GPS proximity fallback
    if (bestTrip == null) {
      for (final t in validTrips) {
        final startDelta = t.startTime!.difference(report.timestamp).inSeconds.abs() / 60.0;
        final endDelta = t.endTime != null
            ? t.endTime!.difference(report.timestamp).inSeconds.abs() / 60.0
            : double.infinity;
        final minDelta = min(startDelta, endDelta);

        // Check if report falls within or near the trip window
        bool inWindow = false;
        if (t.endTime != null) {
          inWindow = report.timestamp.isAfter(
              t.startTime!.subtract(const Duration(minutes: timeWindowMinutes)))
              && report.timestamp.isBefore(
              t.endTime!.add(const Duration(minutes: timeWindowMinutes)));
        } else {
          inWindow = startDelta <= timeWindowMinutes;
        }
        if (!inWindow) continue;

        double dist = double.infinity;
        if (t.startLat != null && t.startLng != null) {
          dist = haversineMetres(report.lat, report.lon, t.startLat!, t.startLng!);
        }

        // Score = weighted sum of time + distance
        double score = minDelta * 60 + dist;
        if (dist <= gpsToleranceMetres && score < bestScore) {
          bestScore = score;
          bestTrip = t;
          matchMethod = 'time+gps';
          timeDelta = minDelta;
          gpsDist = dist;
        }
      }
    }

    if (bestTrip != null) {
      if (matchMethod == 'trip_id') matchedByTripId++;
      else matchedByTime++;
      matched.add(MatchedRow(
        report: report, trip: bestTrip,
        timeDeltaMin: timeDelta, gpsDistanceM: gpsDist,
        matchMethod: matchMethod,
        trustScore: trustScores[report.passengerId],
      ));
    } else {
      unmatched++;
    }
  }

  print('\n── MATCHING RESULTS ──────────────────────────────────');
  print('  Matched by Trip ID:       $matchedByTripId');
  print('  Matched by Time+GPS:      $matchedByTime');
  print('  TOTAL MATCHED:            ${matched.length}');
  print('  Unmatched (no sensor):    $unmatched');
  print('  Outlier GPS excluded:     ${125 - allReports.length}');

  // ── 5. WRITE MATCHED DATASET CSV ─────────────────────────
  final csvBuf = StringBuffer();
  csvBuf.writeln([
    'Report ID', 'Passenger ID', 'Trip ID', 'DB Source',
    'Category', 'Severity', 'Report Timestamp',
    'Report Lat', 'Report Lon',
    'Trip Start', 'Trip End',
    'Sensor Risk Score', 'Sensor Event Count (Speed+Brake+Turn)',
    'Speeding Count', 'Braking Count', 'Turning Count',
    'Trust Score', 'Verified', 'Verification Count',
    'Time Delta (min)', 'GPS Distance (m)', 'Match Method'
  ].join(','));

  for (final row in matched) {
    final r = row.report;
    final t = row.trip;
    csvBuf.writeln([
      r.reportId, r.passengerId,
      t.tripId, t.dbName,
      '"${r.category}"', r.severity,
      r.timestamp.toIso8601String(),
      r.lat, r.lon,
      t.startTime?.toIso8601String() ?? '',
      t.endTime?.toIso8601String() ?? '',
      t.riskScore.toStringAsFixed(4),
      t.totalEvents,
      t.speedingCount, t.brakingCount, t.turningCount,
      row.trustScore?.toStringAsFixed(4) ?? '',
      r.verified, r.verificationCount,
      row.timeDeltaMin.toStringAsFixed(2),
      row.gpsDistanceM >= 0 ? row.gpsDistanceM.toStringAsFixed(1) : 'N/A',
      row.matchMethod,
    ].join(','));
  }
  File(outputMatchedCsv).writeAsStringSync(csvBuf.toString());
  print('\n✓ Wrote matched dataset → $outputMatchedCsv');

  // ── 6. SPEARMAN ANALYSIS ──────────────────────────────────
  final sensorEvents = matched.map((r) => r.trip.totalEvents.toDouble()).toList();
  final severities = matched.map((r) => r.report.severity.toDouble()).toList();

  // Also run on unique trips (aggregated)
  Map<String, List<int>> byTrip = {};
  for (final row in matched) {
    final key = '${row.trip.dbName}_${row.trip.tripId}';
    byTrip.putIfAbsent(key, () => []);
    byTrip[key]!.add(row.report.severity);
  }
  final tripSensorEvs = <double>[];
  final tripAvgSev = <double>[];
  byTrip.forEach((key, sevList) {
    final trip = matched.firstWhere(
        (r) => '${r.trip.dbName}_${r.trip.tripId}' == key).trip;
    tripSensorEvs.add(trip.totalEvents.toDouble());
    tripAvgSev.add(sevList.reduce((a, b) => a + b) / sevList.length);
  });

  // ── 7. WRITE SUMMARY REPORT ───────────────────────────────
  final summary = StringBuffer();
  summary.writeln('═' * 60);
  summary.writeln('  SAFERIDE SOP 2 — SPEARMAN CORRELATION RESULTS');
  summary.writeln('  Generated: ${DateTime.now()}');
  summary.writeln('═' * 60);

  summary.writeln('\n[A] REPORT-LEVEL ANALYSIS (each matched report = 1 obs)');
  if (sensorEvents.length >= 3) {
    final rho = spearmanRho(sensorEvents, severities);
    final t = rho * sqrt((matched.length - 2) / (1 - rho * rho));
    final p = approxPValue(rho, matched.length);
    summary.writeln('  n (matched pairs)  = ${matched.length}');
    summary.writeln('  Spearman ρ          = ${rho.toStringAsFixed(4)}');
    summary.writeln('  t-statistic         = ${t.toStringAsFixed(4)}  (df = ${matched.length - 2})');
    summary.writeln('  p-value (approx)    = ${p.toStringAsFixed(4)}');
    summary.writeln('  Interpretation:');
    if (p < 0.05) {
      summary.writeln('    → Statistically significant at α = 0.05');
    } else {
      summary.writeln('    → NOT statistically significant at α = 0.05');
    }
    if (rho.abs() < 0.2) summary.writeln('    → Negligible correlation');
    else if (rho.abs() < 0.4) summary.writeln('    → Weak correlation');
    else if (rho.abs() < 0.6) summary.writeln('    → Moderate correlation');
    else summary.writeln('    → Strong correlation');
  } else {
    summary.writeln('  ⚠ Insufficient matched pairs (n < 3) for correlation.');
  }

  summary.writeln('\n[B] TRIP-LEVEL ANALYSIS (aggregated by unique trip)');
  if (tripSensorEvs.length >= 3) {
    final rhoT = spearmanRho(tripSensorEvs, tripAvgSev);
    final tT = rhoT * sqrt((tripSensorEvs.length - 2) / (1 - rhoT * rhoT));
    final pT = approxPValue(rhoT, tripSensorEvs.length);
    summary.writeln('  n (unique trips)   = ${tripSensorEvs.length}');
    summary.writeln('  Spearman ρ          = ${rhoT.toStringAsFixed(4)}');
    summary.writeln('  t-statistic         = ${tT.toStringAsFixed(4)}  (df = ${tripSensorEvs.length - 2})');
    summary.writeln('  p-value (approx)    = ${pT.toStringAsFixed(4)}');
  } else {
    summary.writeln('  ⚠ Insufficient unique trips (n < 3) for correlation.');
  }

  summary.writeln('\n[C] DESCRIPTIVE STATISTICS');
  summary.writeln('  Total Firebase reports loaded:    ${allReports.length}');
  summary.writeln('  GPS outliers excluded:            ${125 - allReports.length}');
  summary.writeln('  Matched to sensor trips:          ${matched.length}');
  summary.writeln('  Unmatched (no sensor data):       $unmatched');
  summary.writeln('  Match rate:                       '
      '${(matched.length / allReports.length * 100).toStringAsFixed(1)}%');
  summary.writeln('  Unique trips in matched set:      ${byTrip.length}');

  final verCount = matched.where((r) => r.report.verified).length;
  summary.writeln('  Verified reports in matched set:  $verCount');

  if (matched.isNotEmpty) {
    final avgSev = severities.reduce((a, b) => a + b) / severities.length;
    final avgEv = sensorEvents.reduce((a, b) => a + b) / sensorEvents.length;
    summary.writeln('  Mean severity (matched):          ${avgSev.toStringAsFixed(2)}');
    summary.writeln('  Mean sensor event count:          ${avgEv.toStringAsFixed(2)}');
  }

  summary.writeln('\n[D] DATA QUALITY WARNINGS');
  final withTripId = matched.where((r) => r.matchMethod == 'trip_id').length;
  final withTimeGps = matched.where((r) => r.matchMethod == 'time+gps').length;
  summary.writeln('  Matched via explicit Trip ID:     $withTripId');
  summary.writeln('  Matched via Time+GPS window:      $withTimeGps');
  summary.writeln('  Time window used:                 ±$timeWindowMinutes min');
  summary.writeln('  GPS tolerance used:               ≤$gpsToleranceMetres m');

  if (unmatched > 0) {
    summary.writeln('\n  ⚠ $unmatched reports could not be matched to any sensor trip.');
    summary.writeln('    These reports are excluded from the correlation.');
    summary.writeln('    This must be disclosed in the manuscript as a limitation.');
  }

  summary.writeln('\n[E] CHECKLIST STATUS');
  summary.writeln('  [✓] Sensor event counts exported from .db files');
  summary.writeln('  [✓] GPS coordinates present in reports');
  summary.writeln('  [✓] Outlier GPS coordinates (San Francisco) excluded');
  summary.writeln('  [✓] Time-window and GPS-distance matching defined');
  summary.writeln('  [✓] Sensor anomaly score = speedingCount+brakingCount+turningCount');
  summary.writeln('  [✓] Tie-corrected Spearman rho used (Pearson-on-ranks)');
  summary.writeln('  [✓] p-value computed via t-approximation');
  summary.writeln('  [${verCount > 0 ? "✓" : "✗"}] Independent verification evidence');
  summary.writeln('  [✓] Trust scores joined from saferide_trust_metrics.csv');
  summary.writeln('  [✓] Matched dataset written to CSV for audit');
  summary.writeln('\n' + '═' * 60);

  File(outputSummaryTxt).writeAsStringSync(summary.toString());
  print('\n$summary');
  print('✓ Wrote summary → $outputSummaryTxt');
  print('\n✅ SOP 2 pipeline complete.');
}

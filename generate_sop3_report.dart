import 'dart:io';
import 'dart:math';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;

// Duplicated from risk_scoring.dart for the script
class RiskWeights {
  double w1 = 0.25;
  double w2 = 0.30;
  double w3 = 0.20;
  double w4 = 0.15;
  double w5 = 0.10;
  double phi = 0.10;

  RiskWeights() {
    final sum = w1 + w2 + w3 + w4 + w5;
    w1 /= sum;
    w2 /= sum;
    w3 /= sum;
    w4 /= sum;
    w5 /= sum;
  }
}

void main() async {
  sqfliteFfiInit();
  var databaseFactory = databaseFactoryFfi;

  final exportDir = Directory('export data/SR');
  if (!exportDir.existsSync()) {
    print('Export dir not found');
    return;
  }
  
  // 1. Parse Firebase Reports for Report Risk
  final firebaseReports = File('extracted_firebase_reports.csv'); // Check root first, or assume they moved it
  final Map<int, double> tripSeveritySum = {};
  if (firebaseReports.existsSync()) {
    final lines = firebaseReports.readAsLinesSync();
    for (var i = 1; i < lines.length; i++) {
      final cols = lines[i].split(',');
      if (cols.length > 4) {
        final tripIdStr = cols[2];
        final severityStr = cols[4];
        if (tripIdStr.isNotEmpty && severityStr.isNotEmpty) {
          final tripId = int.tryParse(tripIdStr);
          final severity = double.tryParse(severityStr);
          if (tripId != null && severity != null) {
            tripSeveritySum[tripId] = (tripSeveritySum[tripId] ?? 0) + severity;
          }
        }
      }
    }
  } else {
    print('Warning: extracted_firebase_reports.csv not found in root. Run the app export first.');
  }

  final files = exportDir.listSync().whereType<File>().where((f) => f.path.endsWith('.db'));
  
  final buffer = StringBuffer();
  buffer.writeln('Trip ID,Route,Vehicle,Sensor Risk,Report Risk,Final Safety Score');
  
  final weights = RiskWeights();
  
  // For route-level analysis
  final Map<String, List<int>> routeScores = {};

  for (var file in files) {
    try {
      var absolutePath = file.absolute.path;
      var db = await databaseFactory.openDatabase(absolutePath);
      var tables = await db.query('sqlite_master', where: 'type = ? AND name = ?', whereArgs: ['table', 'trips']);
      if (tables.isNotEmpty) {
        var trips = await db.query('trips');
        for (var t in trips) {
          final tripId = t['id'] as int;
          final routeName = t['route_name'] as String? ?? 'Unknown';
          final vehicleType = t['vehicle_type'] as String? ?? 'Unknown';
          final speedingCount = (t['speeding_count'] as int?) ?? 0;
          final brakingCount = (t['braking_count'] as int?) ?? 0;
          final turningCount = (t['turning_count'] as int?) ?? 0;
          
          final severitySum = tripSeveritySum[tripId] ?? 0.0;
          
          final totalWindows = max(1, speedingCount + brakingCount + turningCount).toInt();
          
          // Sensor Risk
          final riskScore = (weights.w1 * speedingCount +
              weights.w2 * brakingCount +
              weights.w3 * turningCount) / totalWindows;
          final sensorRisk = riskScore.clamp(0.0, 1.0);
          
          // Report Risk
          final reportRisk = (severitySum / 25.0).clamp(0.0, 1.0);
          
          final adaptiveWeight = 0.6; // Lambda
          final tripRisk = (adaptiveWeight * sensorRisk +
              (1 - adaptiveWeight) * reportRisk +
              weights.phi * (sensorRisk - reportRisk).abs()).clamp(0.0, 1.0);
              
          final finalSafetyScore = (100 * (1 - tripRisk)).toInt().clamp(0, 100);
          
          buffer.writeln('$tripId,$routeName,$vehicleType,${sensorRisk.toStringAsFixed(2)},${reportRisk.toStringAsFixed(2)},$finalSafetyScore');
          
          if (!routeScores.containsKey(routeName)) {
            routeScores[routeName] = [];
          }
          routeScores[routeName]!.add(finalSafetyScore);
        }
      }
      await db.close();
    } catch (e) {
      print('Error processing ${file.path}: $e');
    }
  }

  File('extracted_sop3_trips.csv').writeAsStringSync(buffer.toString());
  print('Trip-level analysis saved to extracted_sop3_trips.csv');
  
  // Route-level analysis
  final routeBuffer = StringBuffer();
  routeBuffer.writeln('Route,Number of trips,Mean safety score,Standard deviation');
  
  routeScores.forEach((route, scores) {
    final count = scores.length;
    final mean = scores.fold(0, (sum, val) => sum + val) / count;
    
    double variance = 0;
    if (count > 1) {
      for (var score in scores) {
        variance += pow(score - mean, 2);
      }
      variance /= (count - 1);
    }
    final stdDev = sqrt(variance);
    
    routeBuffer.writeln('$route,$count,${mean.toStringAsFixed(2)},${stdDev.toStringAsFixed(2)}');
  });
  
  File('extracted_sop3_routes.csv').writeAsStringSync(routeBuffer.toString());
  print('Route-level analysis saved to extracted_sop3_routes.csv');
}

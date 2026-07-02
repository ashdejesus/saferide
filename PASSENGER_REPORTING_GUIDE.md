# SafeRide Passenger Reporting System Implementation Guide

## System Overview

The SafeRide Passenger Reporting System implements the trust-weighted passenger reporting model as described in the SafeRide algorithm. It combines passenger incident reports with a sophisticated trust-scoring mechanism that evaluates the reliability of each passenger based on:

1. **Historical Consistency** - How consistent a passenger's reports are over time
2. **Anomaly Detection** - Whether reports deviate from the passenger's normal pattern
3. **Sensor Alignment** - How well passenger reports align with sensor-detected events

## Architecture

### Data Flow

```
Report Submission
    ↓
PassengerReportingService.submitReport()
    ↓
Firebase: passenger_reports collection
    ↓
TrustScoringService calculates trust metrics
    ↓
Firebase: passenger_trust_metrics collection
    ↓
TripController aggregates for safety score
    ↓
Live Safety Score (0-100)
```

## Components Usage

### 1. Submitting a Passenger Report

```dart
final reportingService = PassengerReportingService();

final reportId = await reportingService.submitReport(
  category: 'Speeding',
  severity: 4, // 1-5 scale
  latitude: 14.5995,
  longitude: 120.9842,
  tripId: 123,
  description: 'Driver was speeding on expressway',
);
```

### 2. Retrieving Passenger Trust Metrics

```dart
final metrics = await reportingService.getPassengerTrustMetrics('passenger_uid');

print('Trust Score: ${metrics.overallTrust}'); // 0.0 - 1.0
print('Consistency: ${metrics.consistencyScore}');
print('Sensor Alignment: ${metrics.sensorAlignmentScore}');
print('Total Reports: ${metrics.totalReports}');
```

### 3. Getting Reports for a Trip (with Trust Scores)

```dart
reportingService
    .getReportsForTrip(tripId)
    .listen((reports) {
      for (final report in reports) {
        print('${report.category}: Severity=${report.severity}, '
              'PassengerTrust=${report.passengerTrust}, '
              'WeightedSeverity=${report.weightedSeverity}');
      }
    });
```

### 4. Getting Reports in Geographic Area

```dart
reportingService
    .getReportsInArea(
      centerLat: 14.5995,
      centerLng: 120.9842,
      radiusKm: 1.0,
    )
    .listen((reports) {
      // Handle reports in area
    });
```

### 5. Verifying/Flagging Reports

```dart
// Verify a report (increase passenger trust)
await reportingService.verifyReport(reportId);

// Flag a report as suspicious (decrease passenger trust)
await reportingService.flagReport(reportId, 'Conflicting sensor data');
```

## Trust Scoring Details

### Consistency Score Calculation

Measures the variance in a passenger's historical reports. Lower variance = higher consistency.

```
consistencyScore = 1.0 - normalized_standard_deviation
Range: [0.0, 1.0]
```

### Anomaly Score Calculation

Uses Z-score method to detect outliers in reporting patterns.

```
zScore = (current_severity - mean) / std_dev
anomalyScore = 1.0 / (1.0 + exp(-|zScore|))
Range: [0.0, 1.0] where 1.0 = highly anomalous
```

### Sensor Alignment Score

Evaluates how well a report correlates with sensor-detected events.

```
- No sensor events + high severity report = 0.2 (suspicious)
- Many sensor events + high severity report = 0.95 (well-aligned)
- Weighted by magnitude of difference from expected
```

### Overall Trust Calculation

```
Overall Trust = (0.4 × consistency) 
              + (0.3 × (1 - anomaly)) 
              + (0.3 × sensor_alignment)
              × verification_factor

verification_factor = 0.7 + (verified_ratio × 0.3)
Range: [0.3, 1.0]
```

## UI Integration

### Enhanced Report Screen

The `ReportScreen` now includes:

1. **Intro Card** - Explains reporting purpose
2. **Trust Metrics Card** - Shows passenger's trust score with:
   - Overall trust percentage
   - Consistency progress bar
   - Sensor alignment progress bar
   - Anomaly detection status
   - Verification stats (verified/flagged counts)
3. **Report Form Card** - Original form with category/severity
4. **Reporting Guidelines Card** - Best practices for reporting

### Passenger Reporting Summary Widget

Display reports for a trip with trust indicators:

```dart
PassengerReportingSummaryWidget(tripId: 123)
```

Features:
- Report cards with severity color coding
- Trust badge showing passenger reliability
- Expandable details with description
- Verify/Flag action buttons
- Aggregate statistics by category

## Database Schema

### passenger_trust_metrics table
```sql
CREATE TABLE passenger_trust_metrics (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  passenger_id TEXT UNIQUE NOT NULL,
  total_reports INTEGER DEFAULT 0,
  consistency_score REAL DEFAULT 0.5,
  anomaly_score REAL DEFAULT 0.0,
  sensor_alignment_score REAL DEFAULT 0.5,
  overall_trust REAL DEFAULT 0.5,
  last_updated TEXT NOT NULL,
  verified_count INTEGER DEFAULT 0,
  flagged_count INTEGER DEFAULT 0,
  sync_status TEXT
);
```

### reports_with_trust table
```sql
CREATE TABLE reports_with_trust (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  report_id INTEGER NOT NULL,
  passenger_id TEXT NOT NULL,
  category TEXT NOT NULL,
  severity INTEGER NOT NULL,
  description TEXT,
  latitude REAL,
  longitude REAL,
  timestamp TEXT NOT NULL,
  passenger_trust REAL DEFAULT 0.5,
  is_verified INTEGER DEFAULT 0,
  is_flagged INTEGER DEFAULT 0,
  sync_status TEXT
);
```

## Firestore Collections

### passenger_reports
```json
{
  "passengerId": "user_123",
  "category": "Speeding",
  "severity": 4,
  "description": "Driver was exceeding speed limit",
  "latitude": 14.5995,
  "longitude": 120.9842,
  "tripId": 123,
  "timestamp": "2026-05-04T10:30:00Z",
  "isVerified": false,
  "isFlagged": false,
  "verificationCount": 0,
  "flagCount": 0
}
```

### passenger_trust_metrics
```json
{
  "passengerId": "user_123",
  "totalReports": 25,
  "consistencyScore": 0.82,
  "anomalyScore": 0.15,
  "sensorAlignmentScore": 0.78,
  "overallTrust": 0.79,
  "lastUpdated": "2026-05-04T10:30:00Z",
  "verifiedCount": 18,
  "flaggedCount": 2
}
```

## Integration with Risk Scoring

The trust-weighted reports are integrated into the final safety score:

```dart
// In TripController
final reportRiskReports = _remoteReports
    .map(FirestoreService.toRiskReport)
    .toList();
final reportRisk = risk_scoring.computeReportRiskScore(reportRiskReports);

// In risk_scoring
double computeReportRiskScore(List<PassengerReport> reports) {
  // R_rep(t) = Σ(T_i(t) * r_i(t)) / Σ(T_i(t))
  // Trust-weighted aggregation
}
```

## Best Practices

1. **Submit Detailed Reports** - Include description and location for better sensor alignment
2. **Be Consistent** - Regular, accurate reports build trust score
3. **Use Appropriate Severity** - Avoid extreme severity ratings for minor incidents
4. **Community Trust** - Reports are weighted by passenger trust, verified reports boost trust
5. **Avoid Flags** - Suspicious patterns lower trust score significantly

## Testing

### Unit Test for Trust Scoring

```dart
void main() {
  test('Trust score increases with consistency', () {
    final consistencyScore = TrustScoringService.calculateConsistencyScore(
      historicalSeverities: [3, 3, 3, 3],
      currentSeverity: 3,
    );
    expect(consistencyScore, greaterThan(0.8));
  });

  test('Anomaly detection identifies outliers', () {
    final anomalyScore = TrustScoringService.calculateAnomalyScore(
      historicalSeverities: [2, 2, 2, 2],
      currentSeverity: 5,
    );
    expect(anomalyScore, greaterThan(0.7));
  });
}
```

## Future Enhancements

1. **Machine Learning** - Train model for better anomaly detection
2. **Geofencing** - Automatic geospatial indexing for reports
3. **Real-time Notifications** - Alert nearby passengers of hazards
4. **Community Badges** - Reward highly-trusted passengers
5. **Report Clustering** - Group similar reports by location
6. **Advanced Analytics** - Dashboard showing trust trends
7. **Temporal Patterns** - Time-of-day based trust adjustments

## Troubleshooting

### Trust Score Not Updating
- Check Firestore rules allow updates
- Verify passenger_id is consistent
- Ensure TripController is listening to remote reports

### Reports Not Syncing
- Check Firebase connectivity
- Verify sync_status in database
- Check SyncService implementation

### Low Trust Score
- Check for flags/suspicions in report history
- Verify sensor alignment with actual trip data
- Review consistency of severity ratings

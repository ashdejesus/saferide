# Push Notifications System - Implementation Guide

## Overview

SafeRide now includes a comprehensive push notification system that alerts users about critical driving incidents in real-time. The system uses Firebase Cloud Messaging (FCM) to send targeted notifications based on incident severity and user behavior patterns.

---

## Architecture

### Core Components

#### 1. **NotificationService** (`lib/services/notification_service.dart`)
- Handles Firebase Cloud Messaging initialization
- Manages notification permissions and subscriptions
- Processes incoming notifications in foreground and background
- Provides helper functions for incident classification and message generation

**Key Responsibilities:**
- Request OS-level notification permissions
- Set up message handlers for different app states
- Subscribe/unsubscribe from topic-based messaging
- Generate appropriate notification content based on incident type

#### 2. **TripController Integration** (`lib/state/trip_controller.dart`)
- Integrates NotificationService with trip tracking
- Monitors consecutive events and risk patterns
- Determines when to send notifications (criticality detection)
- Throttles notifications to prevent alert fatigue

**Key Tracking:**
- `_consecutiveEventsInWindow`: Tracks rapid-fire events
- `_lastNotificationTime`: Throttles notifications (min 10 seconds between alerts)
- Subscription to `critical_incidents` topic on trip start
- Unsubscription on trip end

---

## Notification Types

### Incident Criticality Levels

| Level | Threshold | Triggers |
|-------|-----------|----------|
| **LOW** | Risk < 0.40 | Minor violations, isolated events |
| **MEDIUM** | Risk 0.40-0.60 | Multiple incidents, moderate concern |
| **HIGH** | Risk 0.60-0.75 | Sustained dangerous behavior |
| **CRITICAL** | Risk ≥ 0.75 OR 3+ events | Immediate danger, multiple violations |

### Incident Types

1. **Speeding** (`'speeding'`)
   - Title: "Excessive Speeding Detected"
   - Triggered by: Speed > adaptive threshold for 2+ times

2. **Harsh Braking** (`'harsh_braking'`)
   - Title: "Harsh Braking Event"
   - Triggered by: Rapid deceleration > braking threshold

3. **Sharp Turn** (`'sharp_turn'`)
   - Title: "Sharp Turn Detected"
   - Triggered by: Gyroscope magnitude > turning threshold

4. **Rapid Sequence** (`'rapid_sequence'`)
   - Title: "Multiple Unsafe Events"
   - Triggered by: 3+ events within notification window
   - Criticality: Typically CRITICAL

5. **High Report Severity** (`'high_report_severity'`)
   - Title: "Critical Incident Reported"
   - Triggered by: Community reports with severity sum > 15

---

## Implementation Details

### Notification Lifecycle

```
Trip Start
    ↓
Initialize NotificationService
    ↓
Subscribe to 'critical_incidents' topic
    ↓
[Event Detection Loop]
    ↓
Event Detected (_recordEvent called)
    ↓
Increment _consecutiveEventsInWindow
    ↓
Check Criticality
    ↓
[Critical?] → Send Notification → Reset Counter
    ↓
Throttle Check (10 sec minimum)
    ↓
Trip End
    ↓
Unsubscribe from 'critical_incidents' topic
    ↓
Reset Notification State
```

### Criticality Determination

```dart
determineCriticality({
  required int consecutiveEvents,
  required double riskScore,
  required int reportSeveritySum,
})
```

**Algorithm:**
```
if (consecutiveEvents >= 3) → CRITICAL
else if (riskScore >= 0.75) → CRITICAL
else if (riskScore >= 0.60) → HIGH
else if (riskScore >= 0.40) → MEDIUM
else if (reportSeveritySum >= 20) → CRITICAL
else if (reportSeveritySum >= 15) → HIGH
else → LOW
```

---

## Notification Content Generation

### Title Generation

```dart
String getNotificationTitle(String incidentType)
```

| Incident Type | Title |
|---------------|-------|
| speeding | "Excessive Speeding Detected" |
| harsh_braking | "Harsh Braking Event" |
| sharp_turn | "Sharp Turn Detected" |
| rapid_sequence | "Multiple Unsafe Events" |
| high_report_severity | "Critical Incident Reported" |
| Other | "Safety Alert" |

### Body Generation

```dart
String getNotificationBody(
  String incidentType,
  IncidentCriticality criticality,
  {int? consecutiveEvents, double? riskScore}
)
```

**Example Outputs:**
- `[HIGH] Speed exceeded safe threshold.`
- `[CRITICAL] 3 unsafe events in quick succession.`
- `[CRITICAL] High-severity incident from community reports. Risk: 87%`

---

## Firebase Cloud Messaging (FCM) Integration

### Topic-Based Messaging

**Current Topic:** `critical_incidents`

**Subscription Flow:**
```
User starts trip → Subscribe to 'critical_incidents'
During trip → Receive notifications for this device
User stops trip → Unsubscribe from 'critical_incidents'
```

**Backend Can Send:**
- To specific device via FCM token
- To all users via topic broadcast
- To user segments via custom topics

### Message Structure (Sent from Backend)

```json
{
  "notification": {
    "title": "Excessive Speeding Detected",
    "body": "Speed exceeded safe threshold. [HIGH]"
  },
  "data": {
    "incident_type": "speeding",
    "severity": "0.65",
    "timestamp": "2026-05-05T14:30:00Z",
    "latitude": "14.5995",
    "longitude": "120.9842"
  },
  "android": {
    "priority": "high"
  },
  "apns": {
    "headers": {
      "apns-priority": "10"
    }
  }
}
```

---

## Notification Handling States

### 1. **Foreground** (App Open)
- User sees notification while using SafeRide
- Notification handler (`_handleNotification`) processes in real-time
- UI updates automatically via TripController listeners

### 2. **Background** (App Paused)
- System displays native notification
- User can tap to open app
- `onMessageOpenedApp` handler triggers navigation

### 3. **Terminated** (App Closed)
- System queues notification
- When user launches app, initial message is processed
- Relevant incident screen shown based on data

---

## Configuration & Customization

### Adjusting Criticality Thresholds

In `notification_service.dart`:

```dart
IncidentCriticality determineCriticality({
  required int consecutiveEvents,
  required double riskScore,
  required int reportSeveritySum,
}) {
  // Modify these thresholds for your use case:
  if (consecutiveEvents >= 3) { // Change 3 to desired count
    return IncidentCriticality.critical;
  }
  
  if (riskScore >= 0.75) { // Adjust risk threshold (0-1)
    return IncidentCriticality.critical;
  }
  // ... more thresholds
}
```

### Adjusting Notification Throttling

In `trip_controller.dart`, `_checkAndSendCriticalNotification()`:

```dart
// Throttle notifications: max one every 10 seconds
if (_lastNotificationTime != null &&
    DateTime.now().difference(_lastNotificationTime!).inSeconds < 10) {
  // Change 10 to desired minimum seconds between notifications
  return;
}
```

### Filtering by Incident Type

In `_checkAndSendCriticalNotification()`, modify the criticality check:

```dart
// Only send notifications for medium and above
if (criticality.index < IncidentCriticality.medium.index) {
  // Change to HIGH to only send critical incidents:
  // if (criticality.index < IncidentCriticality.high.index)
  return;
}
```

---

## Testing Notifications

### Local Testing (Without Backend)

The `_sendCriticalIncidentNotification` method currently logs notifications:

```dart
debugPrint('CRITICAL NOTIFICATION: [$criticality] $title - $body');
debugPrint('Incident Data: ${notificationData.toMap()}');
```

**To enable system notifications**, implement native notification display:

```dart
// Android: Use flutter_local_notifications plugin
// iOS: Use UNUserNotificationCenter
```

### Production Testing

1. **Get Device FCM Token:**
   ```dart
   final token = await _notificationService.getDeviceToken();
   ```

2. **Send Test Message via Firebase Console:**
   - Go to Firebase Console → Cloud Messaging
   - Create new campaign
   - Target `critical_incidents` topic
   - Send test message

3. **Backend Implementation:**
   - Use Firebase Admin SDK to send messages
   - Query device tokens and send personalized alerts

---

## Code Examples

### Subscribing to Critical Incidents Topic

```dart
// Automatically done in startTrip()
await _notificationService.subscribeToTopic('critical_incidents');
```

### Checking Incident Criticality

```dart
final criticality = determineCriticality(
  consecutiveEvents: 3,
  riskScore: 0.82,
  reportSeveritySum: 10,
);
// Result: CRITICAL
```

### Getting Notification Message

```dart
final title = getNotificationTitle('speeding');
// Result: "Excessive Speeding Detected"

final body = getNotificationBody(
  'rapid_sequence',
  IncidentCriticality.critical,
  consecutiveEvents: 3,
);
// Result: "3 unsafe events in quick succession. [CRITICAL]"
```

---

## Data Storage & Analytics

### Notification Data Captured

```dart
CriticalIncidentNotification(
  incidentType: 'speeding',
  severity: 0.75,          // 0-1 risk scale
  message: '...',
  timestamp: DateTime.now(),
  latitude: 14.5995,
  longitude: 120.9842,
)
```

### Future Enhancements

1. **Store Notification Log:**
   - Log all sent notifications to Firestore
   - Enable analytics on notification effectiveness

2. **User Preferences:**
   - Allow users to customize notification sensitivity
   - Opt-in/out for incident types

3. **Notification History:**
   - Show users past critical incidents
   - Track notification response rates

4. **Smart Batching:**
   - Combine multiple events into single notification
   - Reduce notification fatigue for frequent drivers

---

## Troubleshooting

### Notifications Not Appearing

1. **Check Permissions:**
   ```dart
   final settings = await FirebaseMessaging.instance.getNotificationSettings();
   debugPrint('Permission: ${settings.authorizationStatus}');
   ```

2. **Verify Topic Subscription:**
   ```dart
   // Manually verify subscription
   await _notificationService.subscribeToTopic('critical_incidents');
   ```

3. **Check Firebase Project:**
   - Ensure google-services.json is in android/app/
   - Verify iOS app bundle ID in Firebase Console

### Too Many Notifications

- Increase throttle time in `_checkAndSendCriticalNotification()`
- Raise minimum criticality level
- Adjust event detection thresholds in AdaptiveThresholds

### Token Not Retrieving

```dart
final token = await _notificationService.getDeviceToken();
if (token == null) {
  debugPrint('FCM not available on this device');
}
```

---

## References

- [Firebase Cloud Messaging Documentation](https://firebase.google.com/docs/cloud-messaging)
- [Flutter Firebase Messaging Plugin](https://pub.dev/packages/firebase_messaging)
- [Android Notification Best Practices](https://developer.android.com/develop/ui/views/notifications)
- [iOS Remote Notifications](https://developer.apple.com/documentation/usernotifications)

---

## Implementation Checklist

- [x] NotificationService created with FCM integration
- [x] Incident criticality determination logic implemented
- [x] Notification content generation functions created
- [x] TripController integration with event monitoring
- [x] Notification throttling to prevent alert fatigue
- [x] Topic subscription on trip start/end
- [x] Debug logging for testing
- [ ] Native notification display (Android/iOS)
- [ ] Backend message sending implementation
- [ ] User notification preferences UI
- [ ] Analytics dashboard for notification metrics
- [ ] Push notification payload optimization


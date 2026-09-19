import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

/// Handles push notifications for critical incidents and local reminders
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  // Completer-based lock: prevents race conditions when initialize() is called
  // from multiple places (main.dart, app.dart, startTrip) before it completes.
  Completer<void>? _initCompleter;

  bool get _initialized => _initCompleter?.isCompleted == true;

  /// Initialize notification service and set up handlers.
  /// Safe to call multiple times — subsequent calls await the first.
  Future<void> initialize() async {
    if (_initCompleter != null) {
      // Already started — await the in-progress or completed init
      return _initCompleter!.future;
    }
    _initCompleter = Completer<void>();

    try {
      tz.initializeTimeZones();

      // Request notification permission (Android 13+)
      final notifStatus = await Permission.notification.request();
      debugPrint('[NotifService] Notification permission: $notifStatus');

      // Request battery optimization exemption — critical for Samsung One UI
      final batteryStatus = await Permission.ignoreBatteryOptimizations.request();
      debugPrint('[NotifService] Battery optimization exemption: $batteryStatus');

      // Initialize local notifications plugin
      const initializationSettingsAndroid = AndroidInitializationSettings('ic_notification');
      const initializationSettingsIOS = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );
      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );
      debugPrint('[NotifService] flutter_local_notifications initialized');

      final AndroidFlutterLocalNotificationsPlugin? androidImpl =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      // Create high-priority channel for critical driving incidents
      await androidImpl?.createNotificationChannel(
        const AndroidNotificationChannel(
          'critical_incidents_channel_v8',
          'Critical Incidents',
          description: 'Notifications for critical driving incidents',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        ),
      );
      debugPrint('[NotifService] critical_incidents_channel_v8 created');

      // Create channel for sync reminders — required for zonedSchedule() to work
      await androidImpl?.createNotificationChannel(
        const AndroidNotificationChannel(
          'sync_reminder_channel_v2',
          'Sync Reminders',
          description: 'Reminders to sync offline trips',
          importance: Importance.defaultImportance,
          playSound: true,
          enableVibration: true,
        ),
      );
      debugPrint('[NotifService] sync_reminder_channel_v2 created');

      // Request notification permission via Android plugin
      await androidImpl?.requestNotificationsPermission();

      // Firebase permission
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        criticalAlert: true,
      );
      debugPrint('[NotifService] Firebase auth: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        _setupMessageHandlers();
      }

      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      _initCompleter!.complete();
      debugPrint('[NotifService] Fully initialized ✓');
    } catch (e) {
      debugPrint('[NotifService] Error initializing: $e');
      // Complete with error so callers don't hang forever
      _initCompleter!.completeError(e);
      // Reset so a future call can retry
      _initCompleter = null;
    }
  }

  /// Called when the user taps on a local notification
  void _onNotificationResponse(NotificationResponse response) {
    debugPrint('[NotifService] Notification tapped: id=${response.id}, payload=${response.payload}');
  }


  /// Set up handlers for foreground and background messages
  void _setupMessageHandlers() {
    // Handle notification when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message in foreground');
      if (message.notification != null) {
        _handleNotification(message);
      }
    });

    // Handle notification click when app is terminated or in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Message opened from background');
      if (message.data['incident_type'] != null) {
        _handleIncidentNotificationTap(message.data);
      }
    });
  }

  /// Handle incoming notification in foreground
  void _handleNotification(RemoteMessage message) {
    final notification = message.notification;
    debugPrint('Notification Title: ${notification?.title}');
    debugPrint('Notification Body: ${notification?.body}');
    debugPrint('Notification Data: ${message.data}');

    if (notification != null) {
      showLocalNotification(
        title: notification.title ?? 'Notification',
        body: notification.body ?? '',
      );
    }
  }

  /// Handle notification tap from background/terminated state
  void _handleIncidentNotificationTap(Map<String, dynamic> data) {
    final incidentType = data['incident_type'] as String?;
    final severity = data['severity'] as String?;

    debugPrint('Incident type: $incidentType, Severity: $severity');
    // Navigate to relevant screen or perform action
  }

  /// Get device FCM token for server-side targeting
  Future<String?> getDeviceToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      debugPrint('Device FCM Token: $token');
      return token;
    } catch (e) {
      debugPrint('Error getting device token: $e');
      return null;
    }
  }

  /// Send local notification for testing
  /// In production, notifications come from Firebase Cloud Messaging
  Future<void> sendTestNotification({
    required String title,
    required String body,
    String? channelId,
  }) async {
    try {
      debugPrint('Sending test notification: $title - $body');
      // Actually show the local notification for dev testing
      await showLocalNotification(title: title, body: body, payload: 'test_payload');
    } catch (e) {
      debugPrint('Error sending test notification: $e');
    }
  }

  /// Show a local notification for critical incidents (heads-up with sound)
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      if (!_initialized) await initialize();
      final now = DateTime.now().millisecondsSinceEpoch;
      final androidDetails = AndroidNotificationDetails(
        'critical_incidents_channel_v8',
        'Critical Incidents',
        channelDescription: 'Notifications for critical driving incidents',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        icon: 'ic_notification',
        ticker: title,
        category: AndroidNotificationCategory.message,
        channelShowBadge: true,
        showWhen: true,
        when: now,
        styleInformation: BigTextStyleInformation(
          body,
          htmlFormatBigText: false,
          contentTitle: title,
          htmlFormatContentTitle: false,
          summaryText: 'SafeRide Safety Alert',
          htmlFormatSummaryText: false,
        ),
      );
      const iosDetails = DarwinNotificationDetails(presentSound: true);
      final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      await _localNotifications.show(
        payload?.hashCode ?? (DateTime.now().millisecondsSinceEpoch.remainder(100000)),
        title,
        body,
        details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('[NotifService] Error showing local notification: $e');
    }
  }

  // ─── Ongoing Trip Notification ────────────────────────────────────────────
  // Uses a fixed notification ID so the same card updates in-place instead of
  // stacking new notifications every second.
  static const int _ongoingTripNotifId = 1001;

  /// Show (or update) the persistent "Trip in Progress" notification.
  /// Call this on trip start and periodically during tracking.
  Future<void> showOngoingTripNotification({
    required int safetyScore,
    required int totalEvents,
    String? routeName,
    String? lastEventLabel,
  }) async {
    try {
      if (!_initialized) await initialize();

      final String scoreLabel;
      if (safetyScore >= 80) {
        scoreLabel = 'Safe 🟢';
      } else if (safetyScore >= 50) {
        scoreLabel = 'Moderate 🟡';
      } else {
        scoreLabel = 'Risky 🔴';
      }

      final String subtitle = routeName != null && routeName.isNotEmpty
          ? routeName
          : 'Monitoring your ride…';

      final String body = lastEventLabel != null
          ? '$scoreLabel · $totalEvents event${totalEvents == 1 ? '' : 's'} · Last: $lastEventLabel'
          : '$scoreLabel · ${totalEvents == 0 ? 'No incidents detected' : '$totalEvents event${totalEvents == 1 ? '' : 's'} recorded'}';

      final androidDetails = AndroidNotificationDetails(
        'ongoing_trip_channel_v1',
        'Trip Status',
        channelDescription: 'Live status while a trip is being recorded',
        importance: Importance.low, // Low so it doesn't make sound on updates
        priority: Priority.low,
        ongoing: true,           // Cannot be swiped away by the user
        autoCancel: false,
        showProgress: false,
        playSound: false,
        enableVibration: false,
        icon: 'ic_notification',
        ticker: 'SafeRide trip in progress',
        category: AndroidNotificationCategory.service,
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: '🚌 Trip in Progress · Score: $safetyScore',
          summaryText: subtitle,
        ),
      );
      const iosDetails = DarwinNotificationDetails(presentSound: false);
      final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      await _localNotifications.show(
        _ongoingTripNotifId,
        '🚌 Trip in Progress · Score: $safetyScore',
        body,
        details,
        payload: 'ongoing_trip',
      );
    } catch (e) {
      debugPrint('[NotifService] Error showing ongoing trip notification: $e');
    }
  }

  /// Cancel the persistent trip notification. Call this when the trip ends.
  Future<void> cancelOngoingTripNotification() async {
    try {
      await _localNotifications.cancel(_ongoingTripNotifId);
    } catch (e) {
      debugPrint('[NotifService] Error cancelling ongoing trip notification: $e');
    }
  }

  // ─── Trip Summary Notification ────────────────────────────────────────────

  /// Show a trip summary notification when a trip ends.
  Future<void> showTripSummaryNotification({
    required int safetyScore,
    required int speedingCount,
    required int brakingCount,
    required int turningCount,
    String? routeName,
    required Duration tripDuration,
  }) async {
    try {
      if (!_initialized) await initialize();

      final String riskLabel;
      final String emoji;
      if (safetyScore >= 80) {
        riskLabel = 'Low Risk';
        emoji = '✅';
      } else if (safetyScore >= 50) {
        riskLabel = 'Moderate Risk';
        emoji = '⚠️';
      } else {
        riskLabel = 'High Risk';
        emoji = '🚨';
      }

      final totalEvents = speedingCount + brakingCount + turningCount;
      final title = '$emoji Trip Complete · Safety Score: $safetyScore';
      final tripName = (routeName != null && routeName.isNotEmpty)
          ? routeName
          : '${tripDuration.inMinutes}-minute trip';

      final List<String> parts = [];
      if (speedingCount > 0) parts.add('$speedingCount speeding');
      if (brakingCount > 0) parts.add('$brakingCount braking');
      if (turningCount > 0) parts.add('$turningCount turning');

      final String body = totalEvents == 0
          ? '$tripName · $riskLabel · No unsafe events — great ride!'
          : '$tripName · $riskLabel · ${parts.join(', ')}. Tap to review.';

      final now = DateTime.now().millisecondsSinceEpoch;
      final androidDetails = AndroidNotificationDetails(
        'trip_summary_channel_v1',
        'Trip Summaries',
        channelDescription: 'Summary notification when a trip ends',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: 'ic_notification',
        autoCancel: true,
        showWhen: true,
        when: now,
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
          summaryText: 'SafeRide',
        ),
      );
      const iosDetails = DarwinNotificationDetails(presentSound: true);
      final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      await _localNotifications.show(
        1002,
        title,
        body,
        details,
        payload: 'trip_summary',
      );
    } catch (e) {
      debugPrint('[NotifService] Error showing trip summary notification: $e');
    }
  }

  // ─── Scheduled Reminders ─────────────────────────────────────────────────

  /// Subscribe to topic for group notifications
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic: $e');
    }
  }

  /// Schedule a local reminder to sync offline data
  Future<void> scheduleSyncReminder() async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'sync_reminder_channel_v2',
        'Sync Reminders',
        channelDescription: 'Reminders to sync offline trips',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        playSound: true,
      );
      const iosDetails = DarwinNotificationDetails(presentSound: true);
      const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      await _localNotifications.zonedSchedule(
        999,
        '🚗 Trip recorded!',
        'Your offline trip will automatically sync in 30 minutes. Make sure you are connected to the internet!',
        tz.TZDateTime.now(tz.local).add(const Duration(minutes: 30)),
        details,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      debugPrint('Scheduled sync reminder for 1 hour from now');
    } catch (e) {
      debugPrint('Error scheduling sync reminder: $e');
    }
  }

  /// Cancel the pending sync reminder
  Future<void> cancelSyncReminder() async {
    try {
      await _localNotifications.cancel(999);
      debugPrint('Cancelled pending sync reminder');
    } catch (e) {
      debugPrint('Error cancelling sync reminder: $e');
    }
  }
}

/// Send local notification for testing
Future<void> sendTestNotification(NotificationService service, {
  required String title,
  required String body,
}) async {
  try {
    debugPrint('Sending test notification: $title - $body');
    await service.showLocalNotification(title: title, body: body, payload: 'test_payload');
  } catch (e) {
    debugPrint('Error sending test notification: $e');
  }
}

/// Critical incident notification data
class CriticalIncidentNotification {
  final String incidentType;
  final double severity;
  final String message;
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;

  CriticalIncidentNotification({
    required this.incidentType,
    required this.severity,
    required this.message,
    required this.timestamp,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'incident_type': incidentType,
      'severity': severity,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

/// Criticality levels for incidents
enum IncidentCriticality { low, medium, high, critical }

/// Determine criticality of incident based on risk factors
IncidentCriticality determineCriticality({
  required int consecutiveEvents,
  required double riskScore,
  required int reportSeveritySum,
}) {
  if (consecutiveEvents >= 3) return IncidentCriticality.critical;
  if (riskScore >= 0.75) return IncidentCriticality.critical;
  if (riskScore >= 0.60) return IncidentCriticality.high;
  if (riskScore >= 0.40) return IncidentCriticality.medium;
  if (reportSeveritySum >= 20) return IncidentCriticality.critical;
  if (reportSeveritySum >= 15) return IncidentCriticality.high;
  return IncidentCriticality.low;
}

/// Get notification title — short, commuter-first wording
String getNotificationTitle(String incidentType) {
  switch (incidentType) {
    case 'speeding':       return '⚡ Driver Going Too Fast';
    case 'harsh_braking':  return '🛑 Sudden Stop Detected';
    case 'sharp_turn':     return '↩️ Sharp Turn';
    case 'pothole':        return '🕳️ Rough Road Ahead';
    case 'rapid_sequence': return '⚠️ Multiple Unsafe Events';
    case 'high_report_severity': return '🚨 Danger Reported Nearby';
    default:               return '⚠️ Safety Alert';
  }
}

/// Get notification body — actionable tip for the commuter, escalates with criticality
String getNotificationBody(
  String incidentType,
  IncidentCriticality criticality, {
  int? consecutiveEvents,
  double? riskScore,
}) {
  switch (incidentType) {
    case 'speeding':
      return criticality == IncidentCriticality.critical
          ? 'Driver is going dangerously fast — hold on tight and stay seated!'
          : 'Driver is exceeding safe speed — brace yourself and hold the rail.';

    case 'harsh_braking':
      return criticality == IncidentCriticality.critical
          ? 'Emergency braking! Brace your knees and grip the handle now.'
          : 'Sudden deceleration detected — keep both feet on the floor and hold on.';

    case 'sharp_turn':
      return criticality == IncidentCriticality.critical
          ? 'Very sharp turn! Lean into it and grip the nearest handle.'
          : 'Sharp turn detected — shift your weight and hold on.';

    case 'pothole':
      return 'Rough road or bump detected — hold on tight to avoid being thrown.';

    case 'rapid_sequence':
      final count = consecutiveEvents ?? 3;
      return '$count unsafe events in a row — consider reporting this driver when you arrive safely.';

    case 'high_report_severity':
      final risk = riskScore != null ? '${(riskScore * 100).toStringAsFixed(0)}%' : 'high';
      return 'Community reports flagged this ride as dangerous ($risk risk). Stay alert and hold on.';

    default:
      return 'Unsafe driving detected — stay seated and hold on tight.';
  }
}


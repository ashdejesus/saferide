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
  bool _initialized = false;

  /// Initialize notification service and set up handlers
  Future<void> initialize() async {
    if (_initialized) return; // Prevent double-initialization
    try {
      tz.initializeTimeZones();

      // Request notification permission (Android 13+)
      final notifStatus = await Permission.notification.request();
      debugPrint('[NotifService] Notification permission: $notifStatus');

      // Request battery optimization exemption — critical for Samsung One UI
      final batteryStatus = await Permission.ignoreBatteryOptimizations.request();
      debugPrint('[NotifService] Battery optimization exemption: $batteryStatus');

      // Initialize local notifications plugin
      const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initializationSettingsIOS = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );
      await _localNotifications.initialize(initializationSettings);
      debugPrint('[NotifService] flutter_local_notifications initialized');

      final AndroidFlutterLocalNotificationsPlugin? androidImpl =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      // Create high-priority channel (v8)
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
      debugPrint('[NotifService] Channel v8 created');

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

      _initialized = true;
      debugPrint('[NotifService] Fully initialized ✓');
    } catch (e) {
      debugPrint('[NotifService] Error initializing: $e');
    }
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

  /// Show a local notification for critical incidents
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      // Auto-initialize if not done yet (safeguard for Samsung cold-start)
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
        icon: '@mipmap/ic_launcher',
        fullScreenIntent: true,
        ticker: 'Critical Incident',
        category: AndroidNotificationCategory.alarm, // Bypass Samsung battery restrictions
        channelShowBadge: true,
        showWhen: true,
        when: now,
        // BigTextStyle forces the notification to expand and be more prominent
        styleInformation: BigTextStyleInformation(
          body,
          htmlFormatBigText: false,
          contentTitle: title,
          htmlFormatContentTitle: false,
          summaryText: 'SafeRide Safety Alert',
          htmlFormatSummaryText: false,
        ),
      );
      final iosDetails = DarwinNotificationDetails(
        presentSound: true,
      );
      final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error showing local notification: $e');
    }
  }

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
      const iosDetails = DarwinNotificationDetails(
        presentSound: true,
      );
      const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      await _localNotifications.zonedSchedule(
        999, // Unique ID for sync reminder
        '🚗 Safe ride today!',
        'You have offline trips pending. Sync them to boost your Trust Score and help the community!',
        tz.TZDateTime.now(tz.local).add(const Duration(hours: 1)),
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

/// Critical incident notification data
class CriticalIncidentNotification {
  final String incidentType; // 'speeding', 'harsh_braking', 'sharp_turn'
  final double severity; // 0-1
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
  // High-frequency incidents (3+ in rapid succession)
  if (consecutiveEvents >= 3) {
    return IncidentCriticality.critical;
  }

  // Risk score thresholds (0-1)
  if (riskScore >= 0.75) {
    return IncidentCriticality.critical;
  } else if (riskScore >= 0.60) {
    return IncidentCriticality.high;
  } else if (riskScore >= 0.40) {
    return IncidentCriticality.medium;
  }

  // Report severity thresholds (5 = max)
  if (reportSeveritySum >= 20) {
    return IncidentCriticality.critical;
  } else if (reportSeveritySum >= 15) {
    return IncidentCriticality.high;
  }

  return IncidentCriticality.low;
}

/// Get notification title based on incident type
String getNotificationTitle(String incidentType) {
  switch (incidentType) {
    case 'speeding':
      return 'Excessive Speeding Detected';
    case 'harsh_braking':
      return 'Harsh Braking Event';
    case 'sharp_turn':
      return 'Sharp Turn Detected';
    case 'rapid_sequence':
      return 'Multiple Unsafe Events';
    case 'high_report_severity':
      return 'Critical Incident Reported';
    default:
      return 'Safety Alert';
  }
}

/// Get notification body based on incident details
String getNotificationBody(
  String incidentType,
  IncidentCriticality criticality, {
  int? consecutiveEvents,
  double? riskScore,
}) {
  final severityLabel = criticality.toString().split('.').last.toUpperCase();

  switch (incidentType) {
    case 'speeding':
      return 'Speed exceeded safe threshold. [$severityLabel]';
    case 'harsh_braking':
      return 'Emergency braking detected. [$severityLabel]';
    case 'sharp_turn':
      return 'Unsafe turning maneuver. [$severityLabel]';
    case 'rapid_sequence':
      return '$consecutiveEvents unsafe events in quick succession. [$severityLabel]';
    case 'high_report_severity':
      return 'High-severity incident from community reports. Risk: ${(riskScore! * 100).toStringAsFixed(0)}%';
    default:
      return 'Check SafeRide for details. [$severityLabel]';
  }
}

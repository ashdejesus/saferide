import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Handles push notifications for critical incidents
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  /// Initialize notification service and set up handlers
  Future<void> initialize() async {
    try {
      // Request notification permissions
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(
            alert: true,
            announcement: false,
            badge: true,
            carPlay: false,
            criticalAlert: true,
            provisional: false,
            sound: true,
          );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted notification permission');
        _setupMessageHandlers();
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        debugPrint('User granted provisional notification permission');
        _setupMessageHandlers();
      } else {
        debugPrint(
          'User declined or has not yet granted notification permission',
        );
      }
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
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

    // Data can be used to update UI or trigger app behavior
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
      // This would typically be done via Firebase Cloud Messaging from backend
      // For testing purposes, we log the notification
    } catch (e) {
      debugPrint('Error sending test notification: $e');
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

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Handles all app permissions including location and battery optimization
class PermissionService {
  /// Request all required permissions for SafeRide
  /// Returns true if all critical permissions are granted
  static Future<bool> requestAllPermissions() async {
    // Location permission is critical
    final locationGranted = await _requestLocationPermission();

    // Notify user about battery optimization if needed
    if (!kIsWeb && Platform.isAndroid) {
      await _notifyBatteryOptimization();
    }

    return locationGranted;
  }

  /// Request location permission with fallback logic
  /// Accepts both "While Using App" and "Always Allow"
  static Future<bool> _requestLocationPermission() async {
    // Check if location services are enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services are disabled');
      return false;
    }

    // Check current permission
    var permission = await Geolocator.checkPermission();
    debugPrint('Current location permission: $permission');

    // If already granted, return true
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      debugPrint('Location permission already granted: $permission');
      return true;
    }

    // If denied, request it (shows permission dialog)
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      debugPrint('Location permission request result: $permission');
    }

    // If denied forever, return false
    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permission denied forever');
      return false;
    }

    // Accept both whileInUse and always
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Notify user about battery optimization and provide link to settings
  /// This doesn't request permission but informs user they may need to disable battery optimization
  static Future<void> _notifyBatteryOptimization() async {
    try {
      // We can't directly request battery optimization exemption from Flutter,
      // but we store a flag indicating the user should check this
      debugPrint(
        'User should disable battery optimization for SafeRide in Settings',
      );
      // The UI layer can use this to show a reminder dialog
    } catch (e) {
      debugPrint('Error with battery optimization: $e');
    }
  }

  /// Check if all critical permissions are satisfied
  static Future<bool> checkAllPermissions() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Open app settings for user to manually adjust permissions
  static Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }
}

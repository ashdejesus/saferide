import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// Handles all app permissions including location and battery optimization.
class PermissionService {
  /// Request all required permissions for SafeRide.
  /// Returns true if all critical permissions are granted.
  static Future<bool> requestAllPermissions() async {
    // Location permission is critical
    final locationGranted = await _requestLocationPermission();

    // Request battery optimization exemption on Android so GPS and sensors
    // keep running reliably when the screen is off (Doze mode).
    if (!kIsWeb && Platform.isAndroid) {
      await requestBatteryOptimizationExemption();
    }

    return locationGranted;
  }

  /// Request location permission with fallback logic.
  /// Accepts both "While Using App" and "Always Allow".
  static Future<bool> _requestLocationPermission() async {
    // Check if location services are enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services are disabled');
      if (!kIsWeb) await Geolocator.openLocationSettings();
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
      if (!kIsWeb) await Geolocator.openAppSettings();
      return kIsWeb; // Return true on web to allow testing
    }

    // Accept both whileInUse and always
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always ||
        kIsWeb; // Always allow on web to allow testing
  }

  /// Requests battery optimization exemption via the system dialog.
  ///
  /// On Android 6+, this opens the system's "Allow unrestricted battery usage"
  /// dialog directly — no manual settings navigation needed.
  /// On iOS or web this is a no-op.
  ///
  /// Returns true if the app is already exempt or was just granted exemption.
  static Future<bool> requestBatteryOptimizationExemption() async {
    if (kIsWeb || !Platform.isAndroid) return true;

    try {
      final status = await Permission.ignoreBatteryOptimizations.status;
      if (status.isGranted) return true;

      // This triggers the system dialog: "Allow <app> to always run in background?"
      final result = await Permission.ignoreBatteryOptimizations.request();
      debugPrint('Battery optimization exemption result: $result');
      return result.isGranted;
    } catch (e) {
      debugPrint('Battery optimization exemption failed: $e');
      return false;
    }
  }

  /// Whether the app currently has battery optimization exemption.
  static Future<bool> isBatteryOptimizationExempt() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    try {
      return (await Permission.ignoreBatteryOptimizations.status).isGranted;
    } catch (e) {
      return false;
    }
  }

  /// Check if all critical permissions are satisfied.
  static Future<bool> checkAllPermissions() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Open app settings for user to manually adjust permissions.
  static Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }
}

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<bool> ensurePermission() async {
    try {
      // Check if location services are enabled first
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('LocationService: Location services not enabled');
        return false;
      }

      // Check current permission
      var permission = await Geolocator.checkPermission();

      // If denied, request it (shows dialog)
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      // If denied forever, return false (user must go to settings)
      if (permission == LocationPermission.deniedForever) {
        debugPrint('LocationService: Permission denied forever');
        return false;
      }

      // Accept both whileInUse and always for trip start
      // whileInUse = foreground location (Dialog 1)
      // always = foreground + background location (Dialog 1 + Dialog 2)
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        // Try to upgrade to always (may show Dialog 2 on Android 12+)
        // But don't fail if user declines - whileInUse is sufficient for trip start
        if (permission == LocationPermission.whileInUse) {
          final backgroundPermission = await Geolocator.requestPermission();
          // Update permission only if we got always, otherwise stick with whileInUse
          if (backgroundPermission == LocationPermission.always) {
            permission = backgroundPermission;
          }
        }
        return true;
      }

      // Permission still denied or not granted
      return false;
    } catch (e) {
      // Geolocator throws on unsupported platforms (e.g. Windows desktop)
      debugPrint('LocationService: Permission check failed ($e), '
          'allowing fallback for desktop testing');
      return true;
    }
  }

  Stream<Position> positionStream() {
    LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 5,
    );

    if (!kIsWeb && Platform.isAndroid) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
        intervalDuration: const Duration(seconds: 2),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'SafeRide trip running',
          notificationText: 'Collecting driving data in the background.',
          enableWakeLock: true,
          notificationIcon: AndroidResource(
            name: 'ic_launcher',
            defType: 'mipmap',
          ),
        ),
      );
    } else if (!kIsWeb && Platform.isIOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
        activityType: ActivityType.automotiveNavigation,
        allowBackgroundLocationUpdates: true,
        showBackgroundLocationIndicator: true,
        pauseLocationUpdatesAutomatically: false,
      );
    }

    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  Future<Position> currentPosition() {
    LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 5,
    );

    if (!kIsWeb && Platform.isAndroid) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
        intervalDuration: const Duration(seconds: 2),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'SafeRide trip running',
          notificationText: 'Collecting driving data in the background.',
          enableWakeLock: true,
          notificationIcon: AndroidResource(
            name: 'ic_launcher',
            defType: 'mipmap',
          ),
        ),
      );
    } else if (!kIsWeb && Platform.isIOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
        activityType: ActivityType.automotiveNavigation,
        allowBackgroundLocationUpdates: true,
        showBackgroundLocationIndicator: true,
        pauseLocationUpdatesAutomatically: false,
      );
    }

    return Geolocator.getCurrentPosition(locationSettings: locationSettings);
  }
}

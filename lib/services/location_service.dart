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
        if (!kIsWeb) await Geolocator.openLocationSettings();
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
        if (!kIsWeb) await Geolocator.openAppSettings();
        return kIsWeb; // Allow mock on web
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
      return kIsWeb; // Allow mock on web
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

  Future<Position> currentPosition() async {
    // Use bestForNavigation on mobile, best elsewhere
    LocationAccuracy preferredAccuracy = LocationAccuracy.best;
    if (!kIsWeb && Platform.isAndroid) {
      preferredAccuracy = LocationAccuracy.bestForNavigation;
    } else if (!kIsWeb && Platform.isIOS) {
      preferredAccuracy = LocationAccuracy.bestForNavigation;
    }

    // Build settings helper
    LocationSettings _settings(LocationAccuracy accuracy) {
      if (!kIsWeb && Platform.isAndroid) {
        return AndroidSettings(
          accuracy: accuracy,
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
        return AppleSettings(
          accuracy: accuracy,
          distanceFilter: 5,
          activityType: ActivityType.automotiveNavigation,
          allowBackgroundLocationUpdates: true,
          showBackgroundLocationIndicator: true,
          pauseLocationUpdatesAutomatically: false,
        );
      }
      return LocationSettings(accuracy: accuracy, distanceFilter: 5);
    }

    // --- Attempt 1: preferred accuracy, 10-second timeout ---
    // Without mobile data, A-GPS cold-start can exceed the default timeout.
    // We give it 10 s first; if that fails we fall back to medium accuracy
    // (pure GPS, no network assist) with a longer 20-second window.
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: _settings(preferredAccuracy),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('GPS timeout on first attempt'),
      );
    } catch (e) {
      debugPrint('LocationService: First GPS attempt failed ($e). Retrying with medium accuracy...');
    }

    // --- Attempt 2: medium accuracy (satellite-only, no A-GPS), 20-second timeout ---
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: _settings(LocationAccuracy.medium),
      ).timeout(
        const Duration(seconds: 20),
        onTimeout: () => throw Exception('GPS timeout on fallback attempt'),
      );
    } catch (e) {
      debugPrint('LocationService: Fallback GPS attempt failed ($e).');
      if (kIsWeb) {
        debugPrint('Using mock position for web testing.');
        return Position(
          longitude: -122.084,
          latitude: 37.422,
          timestamp: DateTime.now(),
          accuracy: 10,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      }
      rethrow;
    }
  }
}

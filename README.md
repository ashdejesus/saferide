# SafeRide

A comprehensive Flutter application for real-time trip tracking, incident reporting, and safety monitoring. SafeRide helps improve road safety by detecting unsafe driving events and providing detailed trip analytics.

## Features

✨ **Core Features**
- 🚗 Real-time trip tracking with GPS
- 📊 Live sensor data monitoring (acceleration, gyroscope)
- ⚠️ Automatic unsafe event detection (speeding, harsh braking, sharp turns)
- 📝 Incident reporting with categories and severity levels
- 🗺️ Interactive route visualization using OpenStreetMap
- 📈 Comprehensive trip analytics and trip history
- ☁️ Cloud synchronization with Firebase

🎨 **UI/UX**
- Material 3 Expressive Design System
- Dark & Light theme support
- Responsive layouts for various screen sizes
- Smooth animations and transitions
- Real-time sensor data visualization
- Color-coded safety indicators

## Project Status

**Week 2 Complete:** UI Skeleton with Material 3 Expressive design
- ✅ All 4 main screens designed and navigable
- ✅ Trip start/stop functionality
- ✅ Incident reporting system
- ✅ Trip history and details
- ✅ Live sensor data display
- ✅ Material 3 Expressive theme applied throughout

## Prerequisites

Before you begin, ensure you have the following installed:

### System Requirements
- **Flutter SDK**: Version 3.0 or higher ([Install Flutter](https://flutter.dev/docs/get-started/install))
- **Dart SDK**: Comes with Flutter (version 2.17 or higher)
- **Android Studio** or **Xcode** (for mobile development)
- **Git**: For version control

### For Android Development
- Android SDK (API 24 or higher)
- Android Emulator or physical Android device

### For iOS Development
- Xcode 13 or higher
- iOS Deployment Target 12.0 or higher
- CocoaPods

### Verify Installation
```bash
flutter --version
dart --version
flutter doctor
```

The `flutter doctor` command should show all green checkmarks for your target platforms.

## Installation

### 1. Clone the Repository
```bash
git clone https://github.com/ashdejesus/saferide.git
cd saferide
```

### 2. Install Dependencies
```bash
flutter pub get
```

This command will download all required packages listed in `pubspec.yaml`.

### 3. Set Up Firebase (Optional)
If you want to enable cloud synchronization:

**For Android:**
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create a new project
3. Add Android app
4. Download `google-services.json`
5. Place it in `android/app/`

**For iOS:**
1. Add iOS app in Firebase Console
2. Download `GoogleService-Info.plist`
3. Add it to Xcode project

### 4. Update Configuration (if needed)
```bash
flutter config --enable-web  # Enable web if desired
```

## How to Run

### Run on Android Emulator/Device
```bash
# List available devices
flutter devices

# Run on default device
flutter run

# Run on specific device
flutter run -d <device_id>

# Run with verbose output for debugging
flutter run -v
```

### Run on iOS Simulator/Device
```bash
# Run on iOS simulator
flutter run -d ios

# Run on physical device (requires Apple Developer account)
flutter run -d <device_id>
```

### Run on Web (if enabled)
```bash
flutter run -d chrome
```

### Release Build
```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

## Project Structure

```
lib/
├── main.dart                 # Entry point
├── app.dart                  # App shell with navigation
├── theme.dart                # Material 3 design theme
├── screens/
│   ├── dashboard_screen.dart      # Home screen with trip status
│   ├── report_screen.dart         # Incident reporting
│   ├── map_screen.dart            # Route visualization
│   ├── trips_screen.dart          # Trip history
│   └── trip_detail_screen.dart    # Detailed trip info
├── widgets/
│   ├── empty_state.dart           # Empty state placeholder
│   ├── stat_card.dart             # Metric display
│   ├── sensor_data_card.dart      # Live sensor display
│   ├── trip_mini_hud.dart         # Compact trip status
│   ├── trip_action_sheet.dart     # Trip control modal
│   └── section_header.dart        # Section title
├── services/
│   ├── location_service.dart      # GPS tracking
│   ├── sensor_service.dart        # Accelerometer/Gyroscope
│   ├── risk_scoring.dart          # Safety calculations
│   └── sync_service.dart          # Firebase sync
├── state/
│   └── trip_controller.dart       # State management
├── models/
│   ├── trip.dart
│   ├── report.dart
│   └── sync_status.dart
└── data/
    └── app_database.dart          # Local SQLite storage
```

## Dependencies

Key packages used:
- **flutter_map**: Interactive map visualization
- **geolocator**: GPS location services
- **sensors_plus**: Accelerometer & gyroscope access
- **cloud_firestore**: Cloud database
- **firebase_core**: Firebase integration
- **provider**: State management
- **sqflite**: Local database

See `pubspec.yaml` for complete dependency list.

## Available Commands

```bash
# Analyze code for issues
flutter analyze

# Format code
dart format .

# Run tests
flutter test

# Clean build artifacts
flutter clean

# Get package updates
flutter pub upgrade
```

## Architecture

**State Management:** Provider Pattern
- `TripController`: Manages active trip state and sensor data
- `SyncService`: Handles cloud synchronization

**Navigation:** Material NavigationBar with IndexedStack
- Home (Dashboard)
- Report (Incident reporting)
- Map (Route visualization)
- Trips (Trip history)

**Local Storage:** SQLite database for offline-first approach
**Cloud Storage:** Firebase Firestore for data sync

## Troubleshooting

### Build Issues
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

### Gradle/Build Cache Issues (Android)
```bash
cd android
./gradlew clean
cd ..
flutter run
```

### Pod/Dependency Issues (iOS)
```bash
cd ios
pod repo update
pod install
cd ..
flutter run
```

### Emulator Issues
```bash
# Kill all emulators
adb devices -l
adb -s <device_id> emu kill

# Start fresh
flutter emulators --launch <emulator_name>
```

## Development Workflow

1. **Create local branch** for features
   ```bash
   git checkout -b feature/your-feature
   ```

2. **Make changes** and test locally
   ```bash
   flutter run
   ```

3. **Format and analyze** before commit
   ```bash
   dart format lib/
   flutter analyze
   ```

4. **Commit with descriptive message**
   ```bash
   git commit -m "feat: describe your changes"
   ```

5. **Push and create pull request**
   ```bash
   git push origin feature/your-feature
   ```

## Performance Tips

- Use `flutter run -O` for optimized debug build
- Enable Android native debugging in settings
- Use DevTools for profiling: `flutter pub global activate devtools && devtools`
- Monitor memory with Android Studio Profiler

## Contributing

Contributions are welcome! Please follow these guidelines:
1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'feat: add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see LICENSE file for details.

## Support

For issues, questions, or feature requests:
- Open an issue on GitHub
- Check existing issues for solutions
- Provide detailed reproduction steps

## Roadmap

- [ ] Week 3: Backend integration & data persistence
- [ ] Week 4: Push notifications
- [ ] Week 5: Advanced analytics
- [ ] Week 6: User authentication
- [ ] Future: AI-powered risk prediction

## Authors

- **Development:** ashdejesus
- **Design:** Material 3 Guidelines

## Acknowledgments

- Flutter team for excellent documentation
- Material Design for design guidelines
- OpenStreetMap for map data
- Firebase for backend services

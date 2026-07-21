// ─────────────────────────────────────────────────────────────────────────────
// main_demo.dart — Standalone Algorithm Demo App
//
// This is a SEPARATE entry point that launches only the Algorithm Demo screen
// with no Firebase, no authentication, and no production features.
//
// Build command (debug APK — fastest, sideload directly):
//   flutter build apk --debug -t lib/main_demo.dart
//
// Build command (release APK — smaller file, same content):
//   flutter build apk --release -t lib/main_demo.dart
//
// The APK is saved to: build/app/outputs/flutter-apk/app-debug.apk
// or                    build/app/outputs/flutter-apk/app-release.apk
//
// Install on a connected device:
//   flutter install -t lib/main_demo.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/algo_demo_screen.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Lock to portrait — demo works best in portrait
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const AlgoDemoApp());
}

class AlgoDemoApp extends StatelessWidget {
  const AlgoDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeRide — Algorithm Demo',
      debugShowCheckedModeBanner: false, // hide the red "DEBUG" banner
      theme: buildSafeRideTheme(),
      home: const _DemoLaunchScreen(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _DemoLaunchScreen  — splash / home screen before entering the demo
// ─────────────────────────────────────────────────────────────────────────────

class _DemoLaunchScreen extends StatelessWidget {
  const _DemoLaunchScreen();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // ── App badge ──────────────────────────────────────────────────
              Container(
                width: 96, height: 96,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cs.primary, cs.primary.withValues(alpha: 0.7)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: 0.35),
                      blurRadius: 24, offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.science_rounded, color: Colors.white, size: 52),
              ),
              const SizedBox(height: 28),

              // ── Title ──────────────────────────────────────────────────────
              Text(
                'SafeRide',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Algorithm Demo',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 16),

              // ── Internal badge ────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_rounded, size: 14, color: Color(0xFFDC2626)),
                    SizedBox(width: 6),
                    Text(
                      'INTERNAL USE ONLY — NOT FOR PUBLIC RELEASE',
                      style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w800,
                        color: Color(0xFFDC2626), letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── Description ───────────────────────────────────────────────
              Text(
                'Live demonstration of all risk scoring and trust scoring algorithms used in the SafeRide system.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: cs.onSurfaceVariant, height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Uses real-time accelerometer and gyroscope data from this phone.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
              const Spacer(flex: 2),

              // ── Feature list ──────────────────────────────────────────────
              _FeatureRow(cs: cs, icon: Icons.sensors,
                  text: 'Live sensor data — shake or move the phone'),
              const SizedBox(height: 10),
              _FeatureRow(cs: cs, icon: Icons.calculate,
                  text: 'Every formula shown with real substituted values'),
              const SizedBox(height: 10),
              _FeatureRow(cs: cs, icon: Icons.translate,
                  text: 'Plain English explanation for every computation'),
              const SizedBox(height: 10),
              _FeatureRow(cs: cs, icon: Icons.verified_user,
                  text: 'Risk scoring, trust scoring, and nonlinear fusion'),
              const Spacer(flex: 1),

              // ── CTA button ────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.play_arrow_rounded, size: 22),
                  label: const Text('Open Algorithm Demo', style: TextStyle(fontSize: 16)),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const AlgoDemoScreen()),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Developed by the SafeRide Research Team',
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.cs, required this.icon, required this.text});
  final ColorScheme cs;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: cs.onPrimaryContainer),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 13, color: cs.onSurface)),
          ),
        ],
      );
}

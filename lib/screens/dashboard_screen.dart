import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/trip_controller.dart';
import '../services/risk_scoring.dart' as risk_scoring;
import 'settings_screen.dart';
import '../widgets/stat_card.dart';
import '../widgets/section_header.dart';
import '../widgets/trip_action_sheet.dart';

import '../widgets/sensor_data_card.dart';
import '../widgets/split_button.dart';
import '../widgets/m3_progress_indicators.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Risk classification helpers (mirrors batch_accuracy_test.dart thresholds)
// ─────────────────────────────────────────────────────────────────────────────
enum _RiskLevel { safe, moderate, risky }

_RiskLevel _riskLevel(int safetyScore) {
  if (safetyScore >= 60) return _RiskLevel.safe;
  if (safetyScore >= 35) return _RiskLevel.moderate;
  return _RiskLevel.risky;
}

Color _riskColor(BuildContext context, _RiskLevel level) {
  return switch (level) {
    _RiskLevel.safe => const Color(0xFF2ECC71),
    _RiskLevel.moderate => const Color(0xFFF39C12),
    _RiskLevel.risky => const Color(0xFFE74C3C),
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Dashboard Screen
// ─────────────────────────────────────────────────────────────────────────────

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final AnimationController _controller;
  risk_scoring.VehicleType _selectedVehicle = risk_scoring.VehicleType.jeepney;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final controller = context.watch<TripController>();
    final colorScheme = Theme.of(context).colorScheme;

    final items = <Widget>[
      _buildHeader(context, controller),
      _buildTripCard(context, controller, colorScheme),
      if (controller.isTracking) ...[
        _buildSafetyScoreSection(context, controller),
        _buildRiskBanner(context, controller),
        _buildTripStatsRow(context, controller),
        _buildContextFactorsStrip(context, controller),
        _buildLiveSensorSection(controller),
      ],
      _buildUnsafeEvents(controller),
      _buildRecentEvents(context, controller),
      const SizedBox(height: 120),
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        for (var i = 0; i < items.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == 0 ? 12 : 16),
            child: _StaggeredItem(
              index: i,
              animation: _controller,
              child: items[i],
            ),
          ),
      ],
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, TripController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SafeRide',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              _TripStatusPill(isTracking: controller.isTracking),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Settings',
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          icon: const Icon(Icons.settings),
        ),
      ],
    );
  }

  // ── Trip Card (Start / Stop) ───────────────────────────────────────────────

  Widget _buildTripCard(
    BuildContext context,
    TripController controller,
    ColorScheme colorScheme,
  ) {
    final intensity = (controller.averageAcceleration / 4)
        .clamp(0.0, 1.0)
        .toDouble();
    return Card(
      elevation: controller.isTracking ? 6 : 2,
      color: controller.isTracking
          ? colorScheme.primaryContainer.withValues(alpha: 0.5)
          : colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (controller.isTracking)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.directions_run,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                if (controller.isTracking) const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    controller.isTracking
                        ? (controller.activeTrip?.routeName?.isNotEmpty == true
                            ? 'Traveling to ${controller.activeTrip!.routeName!}'
                            : 'Trip in progress')
                        : 'Ready to start a trip',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (controller.isTracking)
              FilledButton.icon(
                onPressed: () async {
                  await controller.stopTrip();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Trip saved locally.')),
                  );
                },
                icon: const Icon(Icons.stop_circle),
                label: const Text('End Trip'),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedButton<risk_scoring.VehicleType>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: risk_scoring.VehicleType.jeepney,
                        label: Text('Jeepney'),
                      ),
                      ButtonSegment(
                        value: risk_scoring.VehicleType.bus,
                        label: Text('Bus'),
                      ),
                      ButtonSegment(
                        value: risk_scoring.VehicleType.tricycle,
                        label: Text('Tricycle'),
                      ),
                    ],
                    selected: {_selectedVehicle},
                    onSelectionChanged: (Set<risk_scoring.VehicleType> newSelection) {
                      setState(() {
                        _selectedVehicle = newSelection.first;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  SplitButton(
                    label: 'Start Trip',
                    icon: Icons.play_circle_fill,
                    size: SplitButtonSize.medium,
                    onPressed: () async {
                      final started = await controller.startTrip(
                        vehicleMultiplier: _selectedVehicle.multiplier,
                      );
                      if (!context.mounted) return;
                      if (!started) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Could not start trip. Location permission required '
                              'or GPS unavailable on this platform.',
                            ),
                          ),
                        );
                      }
                    },
                    menuItems: [
                      SplitButtonMenuItem(
                        label: 'Start with route name',
                        icon: Icons.edit_road,
                        onPressed: () => TripActionSheet.show(context, vehicle: _selectedVehicle),
                      ),
                      SplitButtonMenuItem(
                        label: 'Quick start',
                        icon: Icons.bolt,
                        onPressed: () async {
                          final started = await controller.startTrip(
                            vehicleMultiplier: _selectedVehicle.multiplier,
                          );
                          if (!context.mounted) return;
                          if (!started) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Location permission is required.'),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            const SizedBox(height: 16),
            // Current speed row
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.speed, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Speed',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                        ),
                        Text(
                          '${(controller.currentSpeed * 3.6).toStringAsFixed(1)} km/h',
                          style: Theme.of(
                            context,
                          ).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ride intensity',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                Text(
                  '${(intensity * 100).round()}%',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            M3LinearProgress(value: intensity, wavy: true, minHeight: 6),
          ],
        ),
      ),
    );
  }

  // ── NEW: Live Safety Score Ring ────────────────────────────────────────────

  Widget _buildSafetyScoreSection(
    BuildContext context,
    TripController controller,
  ) {
    final score = controller.liveSafetyScore ?? 100;
    final level = _riskLevel(score);
    final ringColor = _riskColor(context, level);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Live Safety Score'),
        const SizedBox(height: 12),
        Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
            child: Row(
              children: [
                // Circular gauge
                SizedBox(
                  width: 110,
                  height: 110,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: score.toDouble()),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, animValue, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(110, 110),
                            painter: _SafetyRingPainter(
                              value: animValue / 100,
                              color: ringColor,
                              trackColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${animValue.toInt()}',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: ringColor,
                                ),
                              ),
                              Text(
                                '/ 100',
                                style: Theme.of(
                                  context,
                                ).textTheme.labelSmall?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(width: 24),
                // Score explanation
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Safety Score',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Combines sensor readings and passenger reports into a 0–100 safety rating.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Sensor vs Report breakdown
                      _ScoreBreakdownRow(
                        label: 'Sensor data',
                        color: Theme.of(context).colorScheme.primary,
                        value: _lambdaValue(controller),
                      ),
                      const SizedBox(height: 6),
                      _ScoreBreakdownRow(
                        label: 'Passenger reports',
                        color: Theme.of(context).colorScheme.secondary,
                        value: 1 - _lambdaValue(controller),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  double _lambdaValue(TripController c) {
    final sensorCount = c.speedingCount + c.brakingCount + c.turningCount;
    final reportCount = c.remoteReports.length;
    final total = sensorCount + reportCount;
    if (total == 0) return 0.5;
    return sensorCount / total;
  }

  // ── NEW: Risk Level Banner ─────────────────────────────────────────────────

  Widget _buildRiskBanner(BuildContext context, TripController controller) {
    final score = controller.liveSafetyScore ?? 100;
    final level = _riskLevel(score);
    final color = _riskColor(context, level);
    final (label, icon, desc) = switch (level) {
      _RiskLevel.safe => (
        'Safe',
        Icons.check_circle_rounded,
        'Driving conditions are within safe limits.',
      ),
      _RiskLevel.moderate => (
        'Moderate Risk',
        Icons.warning_rounded,
        'Multiple unsafe events detected — stay alert.',
      ),
      _RiskLevel.risky => (
        'High Risk',
        Icons.dangerous_rounded,
        'Dangerous driving pattern detected!',
      ),
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  desc,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── NEW: Trip Duration + Distance + Reports Row ────────────────────────────

  Widget _buildTripStatsRow(BuildContext context, TripController controller) {
    final activeTrip = controller.activeTrip;
    final elapsed = activeTrip != null
        ? DateTime.now().difference(activeTrip.startTime)
        : Duration.zero;

    // Estimate distance from route points using Haversine approximation
    double distanceKm = 0;
    final pts = controller.routePoints;
    for (int i = 1; i < pts.length; i++) {
      distanceKm += _haversineDist(
        pts[i - 1]['lat'] ?? 0,
        pts[i - 1]['lng'] ?? 0,
        pts[i]['lat'] ?? 0,
        pts[i]['lng'] ?? 0,
      );
    }

    final h = elapsed.inHours;
    final m = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    final durationStr = h > 0 ? '$h:$m:$s' : '$m:$s';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        const SectionHeader(title: 'Trip Info'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _InfoTile(
                icon: Icons.timer_outlined,
                label: 'Duration',
                value: durationStr,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _InfoTile(
                icon: Icons.route_outlined,
                label: 'Distance',
                value: '${distanceKm.toStringAsFixed(2)} km',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _InfoTile(
                icon: Icons.people_outline,
                label: 'Reports',
                value: controller.remoteReports.length.toString(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  double _haversineDist(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
            sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  // ── NEW: Context Factors Strip ─────────────────────────────────────────────

  Widget _buildContextFactorsStrip(
    BuildContext context,
    TripController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Adaptive Context Factors'),
        const SizedBox(height: 8),
        Card(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _ContextBar(
                  label: 'Road Condition',
                  value: controller.contextRoad,
                  color: const Color(0xFF8E44AD),
                ),
                const SizedBox(height: 10),
                _ContextBar(
                  label: 'Traffic Density',
                  value: controller.contextTraffic,
                  color: const Color(0xFFE67E22),
                ),
                const SizedBox(height: 10),
                _ContextBar(
                  label: 'Environmental Noise',
                  value: controller.contextEnvNoise,
                  color: const Color(0xFF2980B9),
                ),
                const SizedBox(height: 8),
                Text(
                  'These factors adjust how sensitive the app is to unsafe driving based on current road and traffic conditions.',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ── Live Sensor Section (existing, unchanged) ─────────────────────────────

  Widget _buildLiveSensorSection(TripController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Live Sensor Data'),
        const SizedBox(height: 12),
        SensorDataCard(
          acceleration: controller.currentAcceleration,
          averageAcceleration: controller.averageAcceleration,
          turnRate: controller.currentTurnRate,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ── Unsafe Events (expanded with Pothole + Slope) ─────────────────────────

  Widget _buildUnsafeEvents(TripController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Unsafe Events'),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            StatCard(
              title: 'Speeding',
              value: controller.speedingCount.toString(),
              icon: Icons.speed,
            ),
            StatCard(
              title: 'Harsh Braking',
              value: controller.brakingCount.toString(),
              icon: Icons.warning_amber,
            ),
            StatCard(
              title: 'Sharp Turns',
              value: controller.turningCount.toString(),
              icon: Icons.turn_right,
            ),
            StatCard(
              title: 'Potholes',
              value: controller.potholeCount.toString(),
              icon: Icons.texture,
            ),
            StatCard(
              title: 'Slope Deviation',
              value: controller.totalSlopeDeviation.toStringAsFixed(2),
              icon: Icons.terrain,
            ),
            StatCard(
              title: 'Report Severity',
              value: controller.reportSeveritySum.toString(),
              icon: Icons.report,
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ── Recent Events (unchanged) ─────────────────────────────────────────────

  Widget _buildRecentEvents(BuildContext context, TripController controller) {
    final events = controller.recentEvents;
    final cs = Theme.of(context).colorScheme;

    // Build children explicitly — Dart's `else ...spread` in a children list
    // silently drops the spread, so we build the list manually.
    final List<Widget> children = [
      const SectionHeader(title: 'Recent Events'),
      const SizedBox(height: 12),
    ];

    if (events.isEmpty) {
      children.add(
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: cs.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: const Color(0xFF2ECC71),
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                'No unsafe events detected yet.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                controller.isTracking
                    ? 'Events will appear here as you drive.'
                    : 'Start a trip to begin monitoring.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.4),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    } else {
      for (final event in events) {
        final (icon, label, color) = switch (event.type) {
          risk_scoring.UnsafeEventType.speeding => (
            Icons.speed,
            'Speeding detected',
            const Color(0xFFE74C3C),
          ),
          risk_scoring.UnsafeEventType.braking => (
            Icons.warning_amber_rounded,
            'Harsh braking',
            const Color(0xFFF39C12),
          ),
          risk_scoring.UnsafeEventType.turning => (
            Icons.turn_right,
            'Sharp turn',
            const Color(0xFF8E44AD),
          ),
        };

        children.add(
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              title: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              trailing: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatTime(event.timestamp),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }


  @override
  bool get wantKeepAlive => true;
}

// ─────────────────────────────────────────────────────────────────────────────
// NEW WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

/// Circular arc safety score painter
class _SafetyRingPainter extends CustomPainter {
  const _SafetyRingPainter({
    required this.value,
    required this.color,
    required this.trackColor,
  });

  final double value; // 0.0–1.0
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = (size.shortestSide / 2) - 8;
    const strokeWidth = 12.0;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -pi / 2;
    const fullSweep = 2 * pi;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      startAngle,
      fullSweep,
      false,
      trackPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      startAngle,
      fullSweep * value,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_SafetyRingPainter old) =>
      old.value != value || old.color != color;
}

/// λ / (1−λ) breakdown mini bar
class _ScoreBreakdownRow extends StatelessWidget {
  const _ScoreBreakdownRow({
    required this.label,
    required this.color,
    required this.value,
  });

  final String label;
  final Color color;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              color: color,
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${(value * 100).round()}%',
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: color),
        ),
      ],
    );
  }
}

/// Small info tile used in Trip Info row
class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: cs.primary),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

/// Labeled progress bar for context factors
class _ContextBar extends StatelessWidget {
  const _ContextBar({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value; // 0.0–1.0
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              backgroundColor: cs.surfaceContainerHighest,
              color: color,
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value.toStringAsFixed(2),
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: color),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EXISTING HELPERS (unchanged)
// ─────────────────────────────────────────────────────────────────────────────

class _StaggeredItem extends StatelessWidget {
  const _StaggeredItem({
    required this.index,
    required this.animation,
    required this.child,
  });

  final int index;
  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final start = 0.08 * index;
    final end = (start + 0.6).clamp(0.0, 1.0).toDouble();
    final intervalStart = start.clamp(0.0, 1.0).toDouble();
    final curve = CurvedAnimation(
      parent: animation,
      curve: Interval(intervalStart, end, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(curve),
        child: child,
      ),
    );
  }
}

class _TripStatusPill extends StatelessWidget {
  const _TripStatusPill({required this.isTracking});

  final bool isTracking;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final background = isTracking
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHighest;
    final foreground = isTracking
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isTracking ? Icons.radio_button_checked : Icons.pause_circle,
            size: 14,
            color: foreground,
          ),
          const SizedBox(width: 6),
          Text(
            isTracking ? 'Recording' : 'Idle',
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}

String _formatTime(DateTime timestamp) {
  final hour = timestamp.hour.toString().padLeft(2, '0');
  final minute = timestamp.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/trip_controller.dart';
import 'settings_screen.dart';
import '../widgets/stat_card.dart';
import '../widgets/section_header.dart';
import '../widgets/trip_action_sheet.dart';
import '../widgets/trip_mini_hud.dart';
import '../widgets/sensor_data_card.dart';
import '../widgets/split_button.dart';
import '../widgets/m3_progress_indicators.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final AnimationController _controller;

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
      if (controller.isTracking) _buildLiveSensorSection(controller),
      _buildUnsafeEvents(controller),
      _buildRecentEvents(context, controller),
      const SizedBox(height: 120),
    ];

    return Stack(
      children: [
        ListView(
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
        ),
        if (controller.isTracking)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: TripMiniHud(
              speed: controller.currentSpeed,
              speedingCount: controller.speedingCount,
              brakingCount: controller.brakingCount,
              turningCount: controller.turningCount,
            ),
          ),
      ],
    );
  }

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
                        ? 'Trip in progress'
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
              SplitButton(
                label: 'Start Trip',
                icon: Icons.play_circle_fill,
                size: SplitButtonSize.medium,
                onPressed: () async {
                  final started = await controller.startTrip();
                  if (!context.mounted) return;
                  if (!started) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Location permission is required.'),
                      ),
                    );
                  }
                },
                menuItems: [
                  SplitButtonMenuItem(
                    label: 'Start with route name',
                    icon: Icons.edit_road,
                    onPressed: () => TripActionSheet.show(context),
                  ),
                  SplitButtonMenuItem(
                    label: 'Quick start',
                    icon: Icons.bolt,
                    onPressed: () async {
                      final started = await controller.startTrip();
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
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.speed, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Speed',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                        ),
                        Text(
                          '${controller.currentSpeed.toStringAsFixed(1)} m/s',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
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
                    color: colorScheme.primary,
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

  Widget _buildLiveSensorSection(TripController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const SectionHeader(title: 'Live Sensor Data'),
        const SizedBox(height: 12),
        SensorDataCard(
          acceleration: controller.currentAcceleration,
          averageAcceleration: controller.averageAcceleration,
          turnRate: controller.currentTurnRate,
        ),
        const SizedBox(height: 24),
      ],
    );
  }

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
              title: 'Braking',
              value: controller.brakingCount.toString(),
              icon: Icons.warning_amber,
            ),
            StatCard(
              title: 'Sharp Turns',
              value: controller.turningCount.toString(),
              icon: Icons.turn_right,
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

  Widget _buildRecentEvents(BuildContext context, TripController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Recent Events'),
        const SizedBox(height: 12),
        if (controller.recentEvents.isEmpty)
          Text(
            'No unsafe events detected yet.',
            style: Theme.of(context).textTheme.bodyMedium,
          )
        else
          ...controller.recentEvents.map(
            (event) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(_eventIcon(event.type)),
              title: Text(_eventLabel(event.type)),
              subtitle: Text(_formatTime(event.timestamp)),
            ),
          ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}

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

IconData _eventIcon(UnsafeEventType type) {
  switch (type) {
    case UnsafeEventType.speeding:
      return Icons.speed;
    case UnsafeEventType.braking:
      return Icons.warning_amber;
    case UnsafeEventType.turning:
      return Icons.turn_right;
  }
}

String _eventLabel(UnsafeEventType type) {
  switch (type) {
    case UnsafeEventType.speeding:
      return 'Speeding detected';
    case UnsafeEventType.braking:
      return 'Harsh braking';
    case UnsafeEventType.turning:
      return 'Sharp turn';
  }
}

String _formatTime(DateTime timestamp) {
  final hour = timestamp.hour.toString().padLeft(2, '0');
  final minute = timestamp.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/trip_controller.dart';
import '../widgets/stat_card.dart';
import '../widgets/section_header.dart';
import '../widgets/trip_action_sheet.dart';
import '../widgets/trip_mini_hud.dart';
import '../widgets/sensor_data_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TripController>();
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Column(
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
              ],
            ),
            const SizedBox(height: 20),
            Card(
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
                    FilledButton.icon(
                      onPressed: () => TripActionSheet.show(context),
                      icon: Icon(
                        controller.isTracking
                            ? Icons.stop_circle
                            : Icons.play_circle_fill,
                      ),
                      label: Text(
                        controller.isTracking ? 'End Trip' : 'Start Trip',
                      ),
                    ),
                    if (!controller.isTracking) const SizedBox(height: 16),
                    if (controller.isTracking) const SizedBox(height: 16),
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
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: colorScheme.onSurface
                                            .withValues(alpha: 0.7),
                                      ),
                                ),
                                Text(
                                  '${controller.currentSpeed.toStringAsFixed(1)} m/s',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (controller.isTracking) ...[
              const SectionHeader(title: 'Live Sensor Data'),
              const SizedBox(height: 12),
              SensorDataCard(
                acceleration: controller.currentAcceleration,
                averageAcceleration: controller.averageAcceleration,
                turnRate: controller.currentTurnRate,
              ),
              const SizedBox(height: 24),
            ],
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
            const SizedBox(height: 80),
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

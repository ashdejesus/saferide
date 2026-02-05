import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_database.dart';
import '../services/sync_service.dart';
import '../state/trip_controller.dart';
import '../state/trip_controller.dart' show UnsafeEventType;
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
    final sync = context.watch<SyncService>();
    final database = context.read<AppDatabase>();
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                FilledButton.tonalIcon(
                  onPressed: () async {
                    final result = await sync.syncPending();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(result.message)));
                  },
                  icon: const Icon(Icons.sync),
                  label: const Text('Sync'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SyncStatusBanner(database: database, sync: sync),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.isTracking
                          ? 'Trip in progress'
                          : 'Ready to start a trip',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
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
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.speed, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          '${controller.currentSpeed.toStringAsFixed(1)} m/s',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
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

class _SyncStatusBanner extends StatelessWidget {
  const _SyncStatusBanner({required this.database, required this.sync});

  final AppDatabase database;
  final SyncService sync;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PendingCounts>(
      future: database.getPendingCounts(),
      builder: (context, snapshot) {
        final counts =
            snapshot.data ?? const PendingCounts(trips: 0, reports: 0);
        final lastSyncText = sync.lastSyncAt == null
            ? 'Not synced yet'
            : 'Last sync ${_formatTime(sync.lastSyncAt!)}';
        final pendingText = counts.total == 0
            ? 'All data synced'
            : '${counts.total} pending (${counts.trips} trips, ${counts.reports} reports)';
        final statusIcon = sync.lastResult?.success == false
            ? Icons.cloud_off
            : Icons.cloud_done;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(statusIcon),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pendingText,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lastSyncText,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
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

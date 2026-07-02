import 'package:flutter/material.dart';

import '../services/permission_service.dart';

class DataCollectionAgreementDialog extends StatelessWidget {
  const DataCollectionAgreementDialog({super.key, required this.onAccept});

  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.privacy_tip_outlined,
                    size: 28,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Data Collection Notice',
                      style: textTheme.headlineSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'SafeRide collects the following data to provide safety features:',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              // GPS Data
              _DataPointTile(
                icon: Icons.location_on,
                title: 'GPS Location Data',
                description:
                    'Real-time location tracking during trips to monitor your route and provide safety alerts.',
                color: colorScheme.primary,
              ),
              const SizedBox(height: 12),
              // Sensor Data
              _DataPointTile(
                icon: Icons.speed,
                title: 'Accelerometer & Gyroscope Data',
                description:
                    'Movement sensors to detect speeding, harsh braking, and sudden turns for driving safety analysis.',
                color: colorScheme.tertiary,
              ),
              const SizedBox(height: 12),
              // Data Usage
              _DataPointTile(
                icon: Icons.security,
                title: 'Data Security',
                description:
                    'All data is encrypted and stored locally on your device first. Synced data is protected by Firebase security rules.',
                color: colorScheme.secondary,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You can review or change your data preferences in Settings at any time.',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Learn More'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        // Request location permission first
                        final hasPermission =
                            await PermissionService.requestAllPermissions();

                        if (!context.mounted) return;

                        // Show battery optimization reminder
                        if (hasPermission) {
                          await _showBatteryOptimizationReminder(context);
                        }

                        if (!context.mounted) return;

                        onAccept();
                        Navigator.of(context).pop();
                      },
                      child: const Text('I Understand & Accept'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show reminder to disable battery optimization
  static Future<void> _showBatteryOptimizationReminder(
    BuildContext context,
  ) async {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.battery_alert,
                    size: 28,
                    color: colorScheme.errorContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Battery Optimization',
                      style: textTheme.headlineSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'For SafeRide to track your trips reliably, please disable battery optimization:',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '1. Open Settings',
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '2. Go to Apps > SafeRide',
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '3. Tap Battery > Battery Optimization',
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '4. Select "Don\'t optimize" or "Unrestricted"',
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'This ensures SafeRide can continue collecting location data even when your phone is sleeping.',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('Got it'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        PermissionService.openAppSettings();
                        Navigator.of(dialogContext).pop();
                      },
                      child: const Text('Open Settings'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DataPointTile extends StatelessWidget {
  const _DataPointTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 24, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(
                description,
                style: textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

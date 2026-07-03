import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';

import '../state/trip_controller.dart';

class TripActionSheet {
  static Future<void> show(BuildContext context) async {
    final controller = context.read<TripController>();
    final routeController = TextEditingController(
      text: controller.activeTrip?.routeName ?? '',
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final bottomPadding = MediaQuery.of(sheetContext).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                controller.isTracking ? 'End trip' : 'Start a trip',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              if (!controller.isTracking)
                TextField(
                  controller: routeController,
                  decoration: const InputDecoration(
                    labelText: 'Route name (optional)',
                  ),
                  textInputAction: TextInputAction.done,
                ),
              if (!controller.isTracking) const SizedBox(height: 12),
              if (controller.isTracking)
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _InfoChip(
                      label: 'Speeding ${controller.speedingCount}',
                      icon: Icons.speed,
                    ),
                    _InfoChip(
                      label: 'Brake ${controller.brakingCount}',
                      icon: Icons.warning_amber,
                    ),
                    _InfoChip(
                      label: 'Turn ${controller.turningCount}',
                      icon: Icons.turn_right,
                    ),
                  ],
                ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () async {
                  Navigator.of(sheetContext).pop();
                  if (controller.isTracking) {
                    await controller.stopTrip();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Trip saved locally.')),
                    );
                  } else {
                    final started = await controller.startTrip(
                      routeName: routeController.text.trim().isEmpty
                          ? null
                          : routeController.text.trim(),
                    );
                    if (!context.mounted) return;
                    if (!started) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'Allow background location access so SafeRide can keep tracking trips.',
                          ),
                          action: SnackBarAction(
                            label: 'Settings',
                            onPressed: () {
                              if (!kIsWeb) {
                                Geolocator.openAppSettings();
                              }
                            },
                          ),
                        ),
                      );
                    }
                  }
                },
                icon: Icon(
                  controller.isTracking ? Icons.stop : Icons.play_arrow,
                ),
                label: Text(controller.isTracking ? 'End Trip' : 'Start Trip'),
              ),
            ],
          ),
        );
      },
    );

    routeController.dispose();
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Chip(
      avatar: Icon(icon, size: 16, color: colorScheme.primary),
      label: Text(label),
    );
  }
}

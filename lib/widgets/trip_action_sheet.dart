import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';

import '../data/app_database.dart';
import '../state/trip_controller.dart';
import '../services/risk_scoring.dart' as risk_scoring;

class TripActionSheet {
  static Future<void> show(BuildContext context, {risk_scoring.VehicleType vehicle = risk_scoring.VehicleType.jeepney}) async {
    final controller = context.read<TripController>();
    final db = context.read<AppDatabase>();
    
    final trips = await db.getTrips();
    final routeNames = trips
        .map((t) => t.routeName)
        .where((r) => r != null && r.trim().isNotEmpty)
        .map((r) => r!.trim())
        .toSet()
        .toList();

    final routeController = TextEditingController(
      text: controller.activeTrip?.routeName ?? '',
    );

    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final bottomPadding = MediaQuery.of(sheetContext).viewInsets.bottom;
        return StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              child: Padding(
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
                    DropdownMenu<String>(
                      controller: routeController,
                      label: const Text('Route name (optional)'),
                      dropdownMenuEntries: routeNames
                          .map((r) => DropdownMenuEntry(value: r, label: r))
                          .toList(),
                      enableSearch: true,
                      enableFilter: true,
                      requestFocusOnTap: true,
                      width: MediaQuery.of(sheetContext).size.width - 40,
                      onSelected: (String? value) async {
                        if (value != null) {
                          routeController.text = value;
                          
                          // Instantly start trip
                          final routeName = value.trim();
                          Navigator.of(sheetContext).pop();
                          
                          final started = await controller.startTrip(
                            routeName: routeName.isEmpty ? null : routeName,
                            vehicleMultiplier: vehicle.multiplier,
                            vehicleType: vehicle.name,
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
                    ),
                  if (!controller.isTracking) const SizedBox(height: 16),
                  if (controller.isTracking)
                    if (controller.activeTrip != null)
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          Builder(builder: (context) {
                            final duration = DateTime.now().difference(controller.activeTrip!.startTime);
                            final mins = duration.inMinutes;
                            final secs = (duration.inSeconds % 60).toString().padLeft(2, '0');
                            return _InfoChip(
                              label: '$mins:$secs',
                              icon: Icons.timer,
                            );
                          }),
                          _InfoChip(
                            label: '${controller.currentSpeed.toStringAsFixed(1)} km/h',
                            icon: Icons.speed,
                          ),
                          _InfoChip(
                            label: 'Speeding ${controller.speedingCount}',
                            icon: Icons.speed,
                          ),
                          _InfoChip(
                            label: 'Brake ${controller.brakingCount}',
                            icon: Icons.car_crash,
                          ),
                          _InfoChip(
                            label: 'Turn ${controller.turningCount}',
                            icon: Icons.turn_right,
                          ),
                          _InfoChip(
                            label: 'Pothole ${controller.potholeCount}',
                            icon: Icons.moving,
                          ),
                        ],
                      ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        final isTracking = controller.isTracking;
                        final routeName = routeController.text.trim();
                        Navigator.of(sheetContext).pop();
                        
                        if (isTracking) {
                          final wasTestMode = controller.testMode;
                          await controller.stopTrip();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                wasTestMode ? 'Test trip ended (not saved).' : 'Trip saved locally.',
                              ),
                            ),
                          );
                        } else {
                          final started = await controller.startTrip(
                            routeName: routeName.isEmpty ? null : routeName,
                            vehicleMultiplier: vehicle.multiplier,
                            vehicleType: vehicle.name,
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
                  ),
                ],
              ),
            ));
          },
        );
      },
    );

    routeController.dispose();
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({super.key, required this.label, required this.icon});

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

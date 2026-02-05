import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../state/trip_controller.dart';
import '../widgets/empty_state.dart';
import '../widgets/section_header.dart';
import '../widgets/trip_action_sheet.dart';
import '../widgets/trip_mini_hud.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TripController>();
    final routePoints = controller.routePoints
        .map((point) => LatLng(point['lat']!, point['lng']!))
        .toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SectionHeader(title: 'Trip Map'),
        const SizedBox(height: 12),
        SizedBox(
          height: 360,
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: routePoints.isEmpty
                ? EmptyState(
                    icon: Icons.map,
                    title: 'No active trip',
                    message:
                        'Start a trip to see your live route and markers here.',
                    ctaLabel: 'Start Trip',
                    onCtaPressed: () => TripActionSheet.show(context),
                  )
                : Stack(
                    children: [
                      FlutterMap(
                        options: MapOptions(
                          initialCenter: routePoints.last,
                          initialZoom: 15,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.saferide.app',
                          ),
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: routePoints,
                                strokeWidth: 4,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ],
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: routePoints.last,
                                width: 40,
                                height: 40,
                                child: Icon(
                                  Icons.location_on,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 36,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (controller.isTracking)
                        Positioned(
                          bottom: 12,
                          left: 12,
                          right: 12,
                          child: TripMiniHud(
                            speed: controller.currentSpeed,
                            speedingCount: controller.speedingCount,
                            brakingCount: controller.brakingCount,
                            turningCount: controller.turningCount,
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

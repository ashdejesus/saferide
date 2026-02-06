import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../state/trip_controller.dart';
import '../widgets/empty_state.dart';
import '../widgets/section_header.dart';
import '../widgets/trip_action_sheet.dart';
import '../widgets/trip_mini_hud.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TripController>();

    final routePoints = controller.routePoints
        .map((point) => LatLng(point['lat']!, point['lng']!))
        .toList();

    final items = <Widget>[
      const SectionHeader(title: 'Trip Map'),
      _MapStatusCard(
        isTracking: controller.isTracking,
        speed: controller.currentSpeed,
        points: routePoints.length,
      ),
      _MapCard(
        isTracking: controller.isTracking,
        routePoints: routePoints,
        controller: controller,
      ),
      const SizedBox(height: 80),
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        for (var i = 0; i < items.length; i++)
          _StaggeredItem(
            index: i,
            animation: _animationController,
            child: Padding(
              padding: EdgeInsets.only(bottom: i == 0 ? 12 : 16),
              child: items[i],
            ),
          ),
      ],
    );
  }
}

class _MapStatusCard extends StatelessWidget {
  const _MapStatusCard({
    required this.isTracking,
    required this.speed,
    required this.points,
  });

  final bool isTracking;
  final double speed;
  final int points;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isTracking
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isTracking ? Icons.navigation : Icons.location_disabled,
                color: isTracking
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isTracking ? 'Live trip in progress' : 'No active trip',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Speed ${speed.toStringAsFixed(1)} m/s • $points points',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (isTracking)
              Chip(
                label: const Text('Live'),
                backgroundColor: colorScheme.secondaryContainer,
              ),
          ],
        ),
      ),
    );
  }
}

class _MapCard extends StatelessWidget {
  const _MapCard({
    required this.isTracking,
    required this.routePoints,
    required this.controller,
  });

  final bool isTracking;
  final List<LatLng> routePoints;
  final TripController controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
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
                            color: colorScheme.primary,
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
                              color: colorScheme.primary,
                              size: 36,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (isTracking)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Chip(
                        avatar: Icon(
                          Icons.radio_button_checked,
                          color: colorScheme.onSecondaryContainer,
                          size: 16,
                        ),
                        label: const Text('Live route'),
                        backgroundColor: colorScheme.secondaryContainer,
                      ),
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
    );
  }
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

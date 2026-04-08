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
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final AnimationController _animationController;
  bool _showHighRiskAreas = true;
  bool _showSaferRoutes = true;
  bool _showReportedIncidents = true;

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
    super.build(context);
    final controller = context.watch<TripController>();

    final routePoints = controller.routePoints
        .map((point) => LatLng(point['lat']!, point['lng']!))
        .toList();

    final items = <Widget>[
      const SectionHeader(title: 'Safety Map'),
      _MapLayerControls(
        showHighRiskAreas: _showHighRiskAreas,
        showSaferRoutes: _showSaferRoutes,
        showReportedIncidents: _showReportedIncidents,
        onHighRiskAreasChanged: (value) {
          setState(() => _showHighRiskAreas = value);
        },
        onSaferRoutesChanged: (value) {
          setState(() => _showSaferRoutes = value);
        },
        onReportedIncidentsChanged: (value) {
          setState(() => _showReportedIncidents = value);
        },
      ),
      _FullScreenMapCard(
        isTracking: controller.isTracking,
        routePoints: routePoints,
        controller: controller,
        showHighRiskAreas: _showHighRiskAreas,
        showSaferRoutes: _showSaferRoutes,
        showReportedIncidents: _showReportedIncidents,
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

  @override
  bool get wantKeepAlive => true;
}

class _MapLayerControls extends StatelessWidget {
  const _MapLayerControls({
    required this.showHighRiskAreas,
    required this.showSaferRoutes,
    required this.showReportedIncidents,
    required this.onHighRiskAreasChanged,
    required this.onSaferRoutesChanged,
    required this.onReportedIncidentsChanged,
  });

  final bool showHighRiskAreas;
  final bool showSaferRoutes;
  final bool showReportedIncidents;
  final ValueChanged<bool> onHighRiskAreasChanged;
  final ValueChanged<bool> onSaferRoutesChanged;
  final ValueChanged<bool> onReportedIncidentsChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Map Layers',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  selected: showHighRiskAreas,
                  onSelected: onHighRiskAreasChanged,
                  label: const Text('High-Risk Areas'),
                  avatar: Icon(
                    Icons.warning_rounded,
                    size: 18,
                    color: showHighRiskAreas
                        ? colorScheme.onSecondaryContainer
                        : colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                FilterChip(
                  selected: showSaferRoutes,
                  onSelected: onSaferRoutesChanged,
                  label: const Text('Safer Routes'),
                  avatar: Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: showSaferRoutes
                        ? colorScheme.onTertiaryContainer
                        : colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                FilterChip(
                  selected: showReportedIncidents,
                  onSelected: onReportedIncidentsChanged,
                  label: const Text('Incidents'),
                  avatar: Icon(
                    Icons.flag_rounded,
                    size: 18,
                    color: showReportedIncidents
                        ? colorScheme.onErrorContainer
                        : colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FullScreenMapCard extends StatefulWidget {
  const _FullScreenMapCard({
    required this.isTracking,
    required this.routePoints,
    required this.controller,
    required this.showHighRiskAreas,
    required this.showSaferRoutes,
    required this.showReportedIncidents,
  });

  final bool isTracking;
  final List<LatLng> routePoints;
  final TripController controller;
  final bool showHighRiskAreas;
  final bool showSaferRoutes;
  final bool showReportedIncidents;

  @override
  State<_FullScreenMapCard> createState() => _FullScreenMapCardState();
}

class _FullScreenMapCardState extends State<_FullScreenMapCard> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void didUpdateWidget(covariant _FullScreenMapCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final points = widget.routePoints;
    if (!widget.isTracking || points.isEmpty) {
      return;
    }

    if (points.length != oldWidget.routePoints.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _mapController.move(points.last, _mapController.camera.zoom);
      });
    }
  }

  List<Marker> _buildHighRiskAreaMarkers(ColorScheme colorScheme) {
    // Generate high-risk clusters from route points
    // For demonstration, we create zones around points with higher risk
    final markers = <Marker>[];

    if (widget.routePoints.length < 2) return markers;

    // Create high-risk zones at intervals along the route
    for (
      int i = 0;
      i < widget.routePoints.length;
      i += (widget.routePoints.length / 3).ceil().clamp(1, 10)
    ) {
      markers.add(
        Marker(
          point: widget.routePoints[i],
          width: 60,
          height: 60,
          child: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('High-risk area detected'),
                  backgroundColor: colorScheme.error,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: CustomPaint(
              painter: _HighRiskAreaPainter(
                color: colorScheme.error.withValues(alpha: 0.3),
              ),
              child: Icon(
                Icons.warning_rounded,
                color: colorScheme.error,
                size: 24,
              ),
            ),
          ),
        ),
      );
    }

    return markers;
  }

  List<Polyline<Object>> _buildSaferRoutes(ColorScheme colorScheme) {
    // Create alternative safer routes by offsetting the main route
    if (widget.routePoints.length < 2) return [];

    // Generate a parallel route (safer alternative)
    final saferRoute = widget.routePoints.map((point) {
      // Offset by ~0.0005 degrees (roughly 50 meters)
      return LatLng(point.latitude + 0.0005, point.longitude + 0.0005);
    }).toList();

    return [
      Polyline<Object>(
        points: saferRoute,
        strokeWidth: 3,
        color: colorScheme.tertiary.withValues(alpha: 0.6),
      ),
    ];
  }

  List<Marker> _buildReportedIncidentMarkers(ColorScheme colorScheme) {
    // Build markers for reported incidents
    final markers = <Marker>[];

    if (widget.routePoints.isEmpty) return markers;

    // Create sample incident markers at random points along the route
    final incidentPoints = [
      widget.routePoints[widget.routePoints.length ~/ 4],
      widget.routePoints[widget.routePoints.length ~/ 2],
      widget.routePoints[(widget.routePoints.length * 3) ~/ 4],
    ];

    final severities = ['Low', 'Medium', 'High'];
    final colors = [colorScheme.tertiary, Colors.orange, colorScheme.error];

    for (
      int i = 0;
      i < incidentPoints.length && i < widget.routePoints.length;
      i++
    ) {
      markers.add(
        Marker(
          point: incidentPoints[i],
          width: 50,
          height: 50,
          child: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${severities[i]} severity incident'),
                  backgroundColor: colors[i],
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: colors[i],
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors[i].withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                Icons.flag_rounded,
                color: Theme.of(context).colorScheme.surface,
                size: 20,
              ),
            ),
          ),
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (widget.routePoints.isEmpty) {
      return Card(
        clipBehavior: Clip.antiAlias,
        child: EmptyState(
          icon: Icons.map,
          title: 'No active trip',
          message:
              'Start a trip to see the safety map with high-risk areas, safer routes, and reported incidents.',
          ctaLabel: 'Start Trip',
          onCtaPressed: () => TripActionSheet.show(context),
        ),
      );
    }

    final List<Marker> highRiskMarkers = widget.showHighRiskAreas
        ? _buildHighRiskAreaMarkers(colorScheme)
        : <Marker>[];
    final List<Polyline<Object>> saferRoutes = widget.showSaferRoutes
        ? _buildSaferRoutes(colorScheme)
        : <Polyline<Object>>[];
    final List<Marker> incidentMarkers = widget.showReportedIncidents
        ? _buildReportedIncidentMarkers(colorScheme)
        : <Marker>[];

    return SizedBox(
      height: 480,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: widget.routePoints.isNotEmpty
                    ? widget.routePoints.last
                    : const LatLng(0, 0),
                initialZoom: 15,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.saferide.app',
                ),
                // Safer routes layer
                PolylineLayer<Object>(polylines: saferRoutes),
                // High-risk areas layer
                MarkerLayer(markers: highRiskMarkers),
                // Main route polyline
                PolylineLayer<Object>(
                  polylines: [
                    Polyline<Object>(
                      points: widget.routePoints,
                      strokeWidth: 4,
                      color: colorScheme.primary,
                    ),
                  ],
                ),
                // Reported incidents layer
                MarkerLayer(markers: incidentMarkers),
                // Current location marker
                MarkerLayer(
                  markers: [
                    Marker(
                      point: widget.routePoints.last,
                      width: 50,
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.surface,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.my_location,
                          color: colorScheme.onPrimary,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (widget.isTracking)
              Positioned(
                top: 12,
                left: 12,
                child: Chip(
                  avatar: Icon(
                    Icons.radio_button_checked,
                    color: colorScheme.onSecondaryContainer,
                    size: 16,
                  ),
                  label: const Text('Live tracking'),
                  backgroundColor: colorScheme.secondaryContainer,
                ),
              ),
            if (widget.controller.isTracking)
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: TripMiniHud(
                  speed: widget.controller.currentSpeed,
                  speedingCount: widget.controller.speedingCount,
                  brakingCount: widget.controller.brakingCount,
                  turningCount: widget.controller.turningCount,
                ),
              ),
            // Legend
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.showHighRiskAreas)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.warning_rounded,
                              size: 14,
                              color: colorScheme.error,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'High-Risk',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    if (widget.showSaferRoutes)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 2,
                              color: colorScheme.tertiary,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Safer Route',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    if (widget.showReportedIncidents)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.flag_rounded,
                            size: 14,
                            color: colorScheme.error,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Incidents',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HighRiskAreaPainter extends CustomPainter {
  final Color color;

  _HighRiskAreaPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2,
      paint,
    );
  }

  @override
  bool shouldRepaint(_HighRiskAreaPainter oldDelegate) => false;
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

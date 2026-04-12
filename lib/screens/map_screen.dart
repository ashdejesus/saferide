import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../state/trip_controller.dart';
import '../widgets/section_header.dart';
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

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _StaggeredItem(
            index: 0,
            animation: _animationController,
            child: const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: SectionHeader(title: 'Safety Map'),
            ),
          ),
          Expanded(
            child: _StaggeredItem(
              index: 1,
              animation: _animationController,
              child: _FullScreenMapCard(
                isTracking: controller.isTracking,
                routePoints: routePoints,
                controller: controller,
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
            ),
          ),
        ],
      ),
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
      elevation: 2,
      color: colorScheme.surface.withValues(alpha: 0.92),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
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
              spacing: 10,
              runSpacing: 8,
              children: [
                _LayerFilterChip(
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
                _LayerFilterChip(
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
                _LayerFilterChip(
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

class _LayerFilterChip extends StatelessWidget {
  const _LayerFilterChip({
    required this.selected,
    required this.onSelected,
    required this.label,
    required this.avatar,
  });

  final bool selected;
  final ValueChanged<bool> onSelected;
  final Widget label;
  final Widget avatar;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hoveredColor = colorScheme.primary.withValues(alpha: 0.08);
    final selectedColor = colorScheme.secondaryContainer;
    final baseColor = colorScheme.surfaceContainerHigh;

    return FilterChip(
      selected: selected,
      onSelected: onSelected,
      label: label,
      avatar: avatar,
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      labelPadding: const EdgeInsets.symmetric(horizontal: 2),
      avatarBoxConstraints: const BoxConstraints.tightFor(width: 18, height: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      side: BorderSide(
        color: selected
            ? colorScheme.secondary.withValues(alpha: 0.45)
            : colorScheme.outlineVariant,
      ),
      color: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return selectedColor;
        }
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused)) {
          return hoveredColor;
        }
        return baseColor;
      }),
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
    required this.onHighRiskAreasChanged,
    required this.onSaferRoutesChanged,
    required this.onReportedIncidentsChanged,
  });

  final bool isTracking;
  final List<LatLng> routePoints;
  final TripController controller;
  final bool showHighRiskAreas;
  final bool showSaferRoutes;
  final bool showReportedIncidents;
  final ValueChanged<bool> onHighRiskAreasChanged;
  final ValueChanged<bool> onSaferRoutesChanged;
  final ValueChanged<bool> onReportedIncidentsChanged;

  @override
  State<_FullScreenMapCard> createState() => _FullScreenMapCardState();
}

class _FullScreenMapCardState extends State<_FullScreenMapCard> {
  late final MapController _mapController;

  static const List<LatLng> _previewRoutePoints = [
    LatLng(14.6038, 120.9885),
    LatLng(14.6052, 120.9920),
    LatLng(14.6070, 120.9951),
    LatLng(14.6089, 120.9986),
    LatLng(14.6105, 121.0013),
  ];

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

  List<Marker> _buildHighRiskAreaMarkers(
    ColorScheme colorScheme,
    List<LatLng> routePoints,
  ) {
    // Generate high-risk clusters from route points
    // For demonstration, we create zones around points with higher risk
    final markers = <Marker>[];

    if (routePoints.length < 2) return markers;

    // Create high-risk zones at intervals along the route
    for (
      int i = 0;
      i < routePoints.length;
      i += (routePoints.length / 3).ceil().clamp(1, 10)
    ) {
      markers.add(
        Marker(
          point: routePoints[i],
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

  List<Polyline<Object>> _buildSaferRoutes(
    ColorScheme colorScheme,
    List<LatLng> routePoints,
  ) {
    // Create alternative safer routes by offsetting the main route
    if (routePoints.length < 2) return [];

    // Generate a parallel route (safer alternative)
    final saferRoute = routePoints.map((point) {
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

  List<Marker> _buildReportedIncidentMarkers(
    ColorScheme colorScheme,
    List<LatLng> routePoints,
  ) {
    // Build markers for reported incidents
    final markers = <Marker>[];

    if (routePoints.isEmpty) return markers;

    // Create sample incident markers at random points along the route
    final incidentPoints = [
      routePoints[routePoints.length ~/ 4],
      routePoints[routePoints.length ~/ 2],
      routePoints[(routePoints.length * 3) ~/ 4],
    ];

    final severities = ['Low', 'Medium', 'High'];
    final colors = [colorScheme.tertiary, Colors.orange, colorScheme.error];

    for (
      int i = 0;
      i < incidentPoints.length && i < routePoints.length;
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

  List<LatLng> _effectiveRoutePoints() {
    if (widget.routePoints.length >= 2) {
      return widget.routePoints;
    }
    return _previewRoutePoints;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasRealTripRoute = widget.routePoints.length >= 2;
    final routePointsForLayers = _effectiveRoutePoints();
    final List<Marker> highRiskMarkers = widget.showHighRiskAreas
        ? _buildHighRiskAreaMarkers(colorScheme, routePointsForLayers)
        : <Marker>[];
    final List<Polyline<Object>> saferRoutes = widget.showSaferRoutes
        ? _buildSaferRoutes(colorScheme, routePointsForLayers)
        : <Polyline<Object>>[];
    final List<Marker> incidentMarkers = widget.showReportedIncidents
        ? _buildReportedIncidentMarkers(colorScheme, routePointsForLayers)
        : <Marker>[];

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: routePointsForLayers.last,
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
                    points: routePointsForLayers,
                    strokeWidth: 4,
                    color: hasRealTripRoute
                        ? colorScheme.primary
                        : colorScheme.primary.withValues(alpha: 0.55),
                  ),
                ],
              ),
              // Reported incidents layer
              MarkerLayer(markers: incidentMarkers),
              // Current location marker
              MarkerLayer(
                markers: [
                  Marker(
                    point: routePointsForLayers.last,
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
                        hasRealTripRoute ? Icons.my_location : Icons.travel_explore,
                        color: colorScheme.onPrimary,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: _MapLayerControls(
              showHighRiskAreas: widget.showHighRiskAreas,
              showSaferRoutes: widget.showSaferRoutes,
              showReportedIncidents: widget.showReportedIncidents,
              onHighRiskAreasChanged: widget.onHighRiskAreasChanged,
              onSaferRoutesChanged: widget.onSaferRoutesChanged,
              onReportedIncidentsChanged: widget.onReportedIncidentsChanged,
            ),
          ),
          if (widget.isTracking)
            Positioned(
              top: 132,
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
          if (!hasRealTripRoute)
            Positioned(
              top: widget.isTracking ? 172 : 132,
              left: 12,
              child: Chip(
                avatar: Icon(
                  Icons.visibility,
                  color: colorScheme.onTertiaryContainer,
                  size: 16,
                ),
                label: const Text('Preview layers shown'),
                backgroundColor: colorScheme.tertiaryContainer,
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
                color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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

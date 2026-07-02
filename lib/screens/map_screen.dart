import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/trip.dart';
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

    // Load completed trips for map display
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TripController>().loadCompletedTrips();
    });
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
      labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      avatarBoxConstraints: const BoxConstraints.tightFor(
        width: 18,
        height: 18,
      ),
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
  LatLng? _lastCenteredLocation;
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  void _syncMapCenter({required bool force}) {
    final center = _resolveMapCenter();
    if (!force &&
        _lastCenteredLocation != null &&
        _lastCenteredLocation!.latitude == center.latitude &&
        _lastCenteredLocation!.longitude == center.longitude) {
      return;
    }

    _lastCenteredLocation = center;
    if (!_isMapReady) {
      return;
    }

    _mapController.move(center, _mapController.camera.zoom);
  }

  void _handleMapReady() {
    _isMapReady = true;
    _syncMapCenter(force: true);
  }

  @override
  void didUpdateWidget(covariant _FullScreenMapCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    _syncMapCenter(force: false);

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

  /// Determine the map center based on real data, not hardcoded coordinates.
  /// Priority: 1) live trip, 2) most recent completed trip, 3) GPS position
  LatLng _resolveMapCenter() {
    // 1. If tracking, center on current route
    if (widget.routePoints.isNotEmpty) {
      return widget.routePoints.last;
    }

    // 2. If completed trips exist, center on the most recent one
    final completedTrips = widget.controller.completedTrips;
    if (completedTrips.isNotEmpty) {
      final mostRecent = completedTrips.first; // already sorted DESC
      if (mostRecent.routePoints.isNotEmpty) {
        final lastPoint = mostRecent.routePoints.last;
        return LatLng(lastPoint['lat']!, lastPoint['lng']!);
      }
      // Fallback to start/end coordinates
      if (mostRecent.endLat != null && mostRecent.endLng != null) {
        return LatLng(mostRecent.endLat!, mostRecent.endLng!);
      }
      if (mostRecent.startLat != null && mostRecent.startLng != null) {
        return LatLng(mostRecent.startLat!, mostRecent.startLng!);
      }
    }

    // 3. If GPS position is available, use it
    final pos = widget.controller.currentPosition;
    if (pos != null) {
      return LatLng(pos.latitude, pos.longitude);
    }

    // 4. Last resort: world center (0,0) — user has no data at all
    return const LatLng(0, 0);
  }

  /// Get the color for a trip based on its safety score.
  /// Safety = 100 - riskScore, so lower riskScore = safer.
  Color _tripRouteColor(Trip trip) {
    final safetyScore = 100.0 - trip.riskScore;
    if (safetyScore >= 80) return Colors.green;
    if (safetyScore >= 50) return Colors.orange;
    return Colors.red;
  }

  /// Build polylines for completed trips, color-coded by safety score.
  List<Polyline<Object>> _buildHistoricalTripRoutes(ColorScheme colorScheme) {
    final completedTrips = widget.controller.completedTrips;
    final polylines = <Polyline<Object>>[];

    for (final trip in completedTrips) {
      if (trip.routePoints.length < 2) continue;

      final points = trip.routePoints
          .map((p) => LatLng(p['lat']!, p['lng']!))
          .toList();

      final color = _tripRouteColor(trip);

      polylines.add(
        Polyline<Object>(
          points: points,
          strokeWidth: 3.5,
          color: color.withValues(alpha: 0.6),
        ),
      );
    }

    return polylines;
  }

  /// Build high-risk markers from actual trip data — marks the start/end
  /// of trips with safety scores below 50.
  List<Marker> _buildHighRiskAreaMarkers(ColorScheme colorScheme) {
    final completedTrips = widget.controller.completedTrips;
    final markers = <Marker>[];

    for (final trip in completedTrips) {
      final safetyScore = 100.0 - trip.riskScore;
      if (safetyScore >= 50) continue; // Only show high-risk trips

      // Mark the start of the high-risk trip
      if (trip.routePoints.isNotEmpty) {
        final startPoint = trip.routePoints.first;
        final endPoint = trip.routePoints.last;

        markers.add(
          _buildRiskMarker(
            colorScheme: colorScheme,
            point: LatLng(startPoint['lat']!, startPoint['lng']!),
            safetyScore: safetyScore,
            trip: trip,
          ),
        );

        // Also mark the end if it's different enough from start
        if (trip.routePoints.length > 3) {
          markers.add(
            _buildRiskMarker(
              colorScheme: colorScheme,
              point: LatLng(endPoint['lat']!, endPoint['lng']!),
              safetyScore: safetyScore,
              trip: trip,
            ),
          );
        }
      }
    }

    return markers;
  }

  Marker _buildRiskMarker({
    required ColorScheme colorScheme,
    required LatLng point,
    required double safetyScore,
    required Trip trip,
  }) {
    return Marker(
      point: point,
      width: 60,
      height: 60,
      child: GestureDetector(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'High-risk area — Safety: ${safetyScore.toStringAsFixed(0)}% '
                '(${trip.speedingCount} speeding, '
                '${trip.brakingCount} braking, '
                '${trip.turningCount} turning)',
              ),
              backgroundColor: colorScheme.error,
              duration: const Duration(seconds: 3),
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
    );
  }

  /// Build safer route polylines — completed trips with safety score >= 80.
  List<Polyline<Object>> _buildSaferRoutes(ColorScheme colorScheme) {
    final completedTrips = widget.controller.completedTrips;
    final polylines = <Polyline<Object>>[];

    for (final trip in completedTrips) {
      final safetyScore = 100.0 - trip.riskScore;
      if (safetyScore < 80) continue; // Only safe trips

      if (trip.routePoints.length < 2) continue;

      final points = trip.routePoints
          .map((p) => LatLng(p['lat']!, p['lng']!))
          .toList();

      polylines.add(
        Polyline<Object>(
          points: points,
          strokeWidth: 4,
          color: colorScheme.tertiary.withValues(alpha: 0.7),
        ),
      );
    }

    return polylines;
  }

  /// Build reported incident markers from real Firestore data only.
  List<Marker> _buildReportedIncidentMarkers(ColorScheme colorScheme) {
    final markers = <Marker>[];
    final controller = widget.controller;

    for (final r in controller.remoteReports) {
      if (r.latitude == null || r.longitude == null) continue;
      final severity = (r.rating).clamp(1, 5);
      final color = severity >= 4
          ? colorScheme.error
          : (severity == 3 ? Colors.orange : colorScheme.tertiary);

      markers.add(
        Marker(
          point: LatLng(r.latitude!, r.longitude!),
          width: 46,
          height: 46,
          child: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${r.category ?? 'Report'} — rating ${r.rating}',
                  ),
                  backgroundColor: color,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 2,
                ),
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

  /// Build an aggregate stats card for all historical trips.
  Widget _buildTripStatsOverlay(ColorScheme colorScheme) {
    final trips = widget.controller.completedTrips;
    if (trips.isEmpty) return const SizedBox.shrink();

    final avgSafety =
        trips.fold<double>(0, (sum, t) => sum + (100.0 - t.riskScore)) /
        trips.length;
    final highRiskCount = trips.where((t) => (100.0 - t.riskScore) < 50).length;
    final safeCount = trips.where((t) => (100.0 - t.riskScore) >= 80).length;

    final avgColor = avgSafety >= 80
        ? Colors.green
        : (avgSafety >= 50 ? Colors.orange : colorScheme.error);

    return Card(
      elevation: 4,
      color: colorScheme.surface.withValues(alpha: 0.96),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Trip History',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield, color: avgColor, size: 18),
                const SizedBox(width: 4),
                Text(
                  '${avgSafety.toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: avgColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '${trips.length} trips · $safeCount safe · $highRiskCount risky',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasRealTripRoute = widget.routePoints.length >= 2;
    final hasCompletedTrips = widget.controller.completedTrips.isNotEmpty;

    // Build layers from real data
    final List<Polyline<Object>> historicalRoutes = _buildHistoricalTripRoutes(
      colorScheme,
    );
    final List<Marker> highRiskMarkers = widget.showHighRiskAreas
        ? _buildHighRiskAreaMarkers(colorScheme)
        : <Marker>[];
    final List<Polyline<Object>> saferRoutes = widget.showSaferRoutes
        ? _buildSaferRoutes(colorScheme)
        : <Polyline<Object>>[];
    final List<Marker> incidentMarkers = widget.showReportedIncidents
        ? _buildReportedIncidentMarkers(colorScheme)
        : <Marker>[];

    final mapCenter = _resolveMapCenter();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: mapCenter,
              initialZoom: hasRealTripRoute || hasCompletedTrips ? 15 : 2,
              onMapReady: _handleMapReady,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.saferide.app',
              ),
              // Historical trip routes (color-coded by safety score)
              PolylineLayer<Object>(polylines: historicalRoutes),
              // Safer routes layer (green, score ≥ 80)
              PolylineLayer<Object>(polylines: saferRoutes),
              // High-risk area markers
              MarkerLayer(markers: highRiskMarkers),
              // Active trip polyline (on top)
              if (hasRealTripRoute)
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
              if (hasRealTripRoute || widget.controller.currentPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: hasRealTripRoute
                          ? widget.routePoints.last
                          : LatLng(
                              widget.controller.currentPosition!.latitude,
                              widget.controller.currentPosition!.longitude,
                            ),
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
          // Layer controls
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 150),
              child: SingleChildScrollView(
                child: _MapLayerControls(
                  showHighRiskAreas: widget.showHighRiskAreas,
                  showSaferRoutes: widget.showSaferRoutes,
                  showReportedIncidents: widget.showReportedIncidents,
                  onHighRiskAreasChanged: widget.onHighRiskAreasChanged,
                  onSaferRoutesChanged: widget.onSaferRoutesChanged,
                  onReportedIncidentsChanged: widget.onReportedIncidentsChanged,
                ),
              ),
            ),
          ),
          // Live tracking chip
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
          // "No trips yet" message when no data at all
          if (!hasRealTripRoute && !hasCompletedTrips)
            Positioned(
              top: widget.isTracking ? 172 : 132,
              left: 12,
              child: Chip(
                avatar: Icon(
                  Icons.info_outline,
                  color: colorScheme.onTertiaryContainer,
                  size: 16,
                ),
                label: const Text('No trip data yet — start a trip'),
                backgroundColor: colorScheme.tertiaryContainer,
              ),
            ),
          // Trip mini HUD during live tracking
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
          // Live safety score overlay
          if (widget.controller.isTracking)
            Positioned(
              top: 12,
              right: 12,
              child: Builder(
                builder: (context) {
                  final score = widget.controller.liveSafetyScore;
                  final color = (score == null)
                      ? colorScheme.surface
                      : (score >= 80
                            ? Colors.green
                            : (score >= 50
                                  ? Colors.orange
                                  : colorScheme.error));
                  return Card(
                    elevation: 4,
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withValues(alpha: 0.96),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Safety Score',
                                style: TextStyle(fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                score == null ? '--' : '$score%',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: color,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.shield, color: color),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          // Trip history stats overlay (bottom-right, when not tracking)
          if (!widget.controller.isTracking && hasCompletedTrips)
            Positioned(
              bottom: 12,
              left: 12,
              child: _buildTripStatsOverlay(colorScheme),
            ),
          // Legend
          Positioned(
            bottom: 12,
            right: 12,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: 0.92),
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
                          Container(
                            width: 12,
                            height: 3,
                            color: Colors.red.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'High-Risk (<50%)',
                            style: TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 3,
                          color: Colors.orange.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Moderate (50-79%)',
                          style: TextStyle(fontSize: 11),
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
                            height: 3,
                            color: Colors.green.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Safe (≥80%)',
                            style: TextStyle(fontSize: 11),
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
                        const Text('Incidents', style: TextStyle(fontSize: 11)),
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

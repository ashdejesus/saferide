import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/trip.dart';
import '../models/passenger_trust_metrics.dart';
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
  bool _showCommunitySafety = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    // Load completed trips for map display
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await context.read<TripController>().loadCompletedTrips();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Weak connection: Community data may be delayed.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
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
                showCommunitySafety: _showCommunitySafety,
                onHighRiskAreasChanged: (value) {
                  setState(() => _showHighRiskAreas = value);
                },
                onSaferRoutesChanged: (value) {
                  setState(() => _showSaferRoutes = value);
                },
                onReportedIncidentsChanged: (value) {
                  setState(() => _showReportedIncidents = value);
                },
                onCommunitySafetyChanged: (value) {
                  setState(() => _showCommunitySafety = value);
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
    required this.showCommunitySafety,
    required this.onHighRiskAreasChanged,
    required this.onSaferRoutesChanged,
    required this.onReportedIncidentsChanged,
    required this.onCommunitySafetyChanged,
  });

  final bool showHighRiskAreas;
  final bool showSaferRoutes;
  final bool showReportedIncidents;
  final bool showCommunitySafety;
  final ValueChanged<bool> onHighRiskAreasChanged;
  final ValueChanged<bool> onSaferRoutesChanged;
  final ValueChanged<bool> onReportedIncidentsChanged;
  final ValueChanged<bool> onCommunitySafetyChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return FloatingActionButton.small(
      heroTag: 'map_layers_fab_main',
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.primary,
      elevation: 2,
      onPressed: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: colorScheme.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (context) {
            return _LayerBottomSheet(
              showHighRiskAreas: showHighRiskAreas,
              showSaferRoutes: showSaferRoutes,
              showReportedIncidents: showReportedIncidents,
              showCommunitySafety: showCommunitySafety,
              onHighRiskAreasChanged: onHighRiskAreasChanged,
              onSaferRoutesChanged: onSaferRoutesChanged,
              onReportedIncidentsChanged: onReportedIncidentsChanged,
              onCommunitySafetyChanged: onCommunitySafetyChanged,
            );
          },
        );
      },
      child: const Icon(Icons.layers_rounded),
    );
  }
}

class _LayerBottomSheet extends StatefulWidget {
  final bool showHighRiskAreas;
  final bool showSaferRoutes;
  final bool showReportedIncidents;
  final bool showCommunitySafety;
  final ValueChanged<bool> onHighRiskAreasChanged;
  final ValueChanged<bool> onSaferRoutesChanged;
  final ValueChanged<bool> onReportedIncidentsChanged;
  final ValueChanged<bool> onCommunitySafetyChanged;

  const _LayerBottomSheet({
    required this.showHighRiskAreas,
    required this.showSaferRoutes,
    required this.showReportedIncidents,
    required this.showCommunitySafety,
    required this.onHighRiskAreasChanged,
    required this.onSaferRoutesChanged,
    required this.onReportedIncidentsChanged,
    required this.onCommunitySafetyChanged,
  });

  @override
  State<_LayerBottomSheet> createState() => _LayerBottomSheetState();
}

class _LayerBottomSheetState extends State<_LayerBottomSheet> {
  late bool _showHighRiskAreas;
  late bool _showSaferRoutes;
  late bool _showReportedIncidents;
  late bool _showCommunitySafety;

  @override
  void initState() {
    super.initState();
    _showHighRiskAreas = widget.showHighRiskAreas;
    _showSaferRoutes = widget.showSaferRoutes;
    _showReportedIncidents = widget.showReportedIncidents;
    _showCommunitySafety = widget.showCommunitySafety;
  }

  @override
  void didUpdateWidget(covariant _LayerBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showHighRiskAreas != widget.showHighRiskAreas) {
      _showHighRiskAreas = widget.showHighRiskAreas;
    }
    if (oldWidget.showSaferRoutes != widget.showSaferRoutes) {
      _showSaferRoutes = widget.showSaferRoutes;
    }
    if (oldWidget.showReportedIncidents != widget.showReportedIncidents) {
      _showReportedIncidents = widget.showReportedIncidents;
    }
    if (oldWidget.showCommunitySafety != widget.showCommunitySafety) {
      _showCommunitySafety = widget.showCommunitySafety;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Text('Map Layers', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          ),
          SwitchListTile(
            title: const Text('High-Risk Areas'),
            secondary: const Icon(Icons.warning_rounded, color: Colors.red),
            value: _showHighRiskAreas,
            onChanged: (val) {
              setState(() => _showHighRiskAreas = val);
              widget.onHighRiskAreasChanged(val);
            },
          ),
          SwitchListTile(
            title: const Text('Safer Routes'),
            secondary: const Icon(Icons.check_circle_rounded, color: Colors.green),
            value: _showSaferRoutes,
            onChanged: (val) {
              setState(() => _showSaferRoutes = val);
              widget.onSaferRoutesChanged(val);
            },
          ),
          SwitchListTile(
            title: const Text('Incidents'),
            secondary: const Icon(Icons.flag_rounded, color: Colors.orange),
            value: _showReportedIncidents,
            onChanged: (val) {
              setState(() => _showReportedIncidents = val);
              widget.onReportedIncidentsChanged(val);
            },
          ),
          SwitchListTile(
            title: const Text('Community Safety'),
            secondary: Icon(Icons.public_rounded, color: Theme.of(context).colorScheme.primary),
            value: _showCommunitySafety,
            onChanged: (val) {
              setState(() => _showCommunitySafety = val);
              widget.onCommunitySafetyChanged(val);
            },
          ),
        ],
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
    required this.showCommunitySafety,
    required this.onHighRiskAreasChanged,
    required this.onSaferRoutesChanged,
    required this.onReportedIncidentsChanged,
    required this.onCommunitySafetyChanged,
    this.isFullScreen = false,
  });

  final bool isTracking;
  final List<LatLng> routePoints;
  final TripController controller;
  final bool showHighRiskAreas;
  final bool showSaferRoutes;
  final bool showReportedIncidents;
  final bool showCommunitySafety;
  final ValueChanged<bool> onHighRiskAreasChanged;
  final ValueChanged<bool> onSaferRoutesChanged;
  final ValueChanged<bool> onReportedIncidentsChanged;
  final ValueChanged<bool> onCommunitySafetyChanged;
  final bool isFullScreen;

  @override
  State<_FullScreenMapCard> createState() => _FullScreenMapCardState();
}

class _FullScreenMapCardState extends State<_FullScreenMapCard> {
  late final MapController _mapController;
  LatLng? _lastCenteredLocation;
  bool _isMapReady = false;
  double _currentZoom = 15.0;

  late bool _showHighRiskAreas;
  late bool _showSaferRoutes;
  late bool _showReportedIncidents;
  late bool _showCommunitySafety;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _showHighRiskAreas = widget.showHighRiskAreas;
    _showSaferRoutes = widget.showSaferRoutes;
    _showReportedIncidents = widget.showReportedIncidents;
    _showCommunitySafety = widget.showCommunitySafety;
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

  void _showReportHazardDialog() {
    final colorScheme = Theme.of(context).colorScheme;
    final recentEvent = widget.controller.getRecentSensorEventCategory();
    String selectedCategory = recentEvent ?? 'Hazard';
    int selectedSeverity = recentEvent != null ? 4 : 3;
    final descriptionController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Report Hazard',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (recentEvent != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome, size: 14, color: colorScheme.primary),
                          const SizedBox(width: 6),
                          Text(
                            'Auto-detected from sensors',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: ['Speeding', 'Sudden Braking', 'Sharp Turning', 'Pothole', 'Reckless Driving', 'Accident', 'Hazard', 'Other']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) => setState(() => selectedCategory = val!),
                  ),
                  const SizedBox(height: 16),
                  Text('Severity (1-5)', style: Theme.of(context).textTheme.labelLarge),
                  Slider(
                    value: selectedSeverity.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: selectedSeverity.toString(),
                    onChanged: (val) => setState(() => selectedSeverity = val.toInt()),
                    activeColor: selectedSeverity >= 4 ? colorScheme.error : colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description (Optional)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: () {
                        final pos = widget.controller.currentPosition;
                        final lat = pos?.latitude ?? _mapController.camera.center.latitude;
                        final lng = pos?.longitude ?? _mapController.camera.center.longitude;

                        // 1. Instantly render marker on map locally
                        final reportId = DateTime.now().millisecondsSinceEpoch;
                        widget.controller.addRemoteReportLocally(
                          ReportWithTrust(
                            reportId: reportId,
                            passengerId: 'guest_user',
                            category: selectedCategory,
                            severity: selectedSeverity,
                            description: descriptionController.text,
                            latitude: lat,
                            longitude: lng,
                            passengerTrust: 1.0,
                            timestamp: DateTime.now(),
                          ),
                        );

                        // 2. Dismiss modal and notify user immediately
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Report submitted successfully!')),
                        );

                        // 3. Persist to backend asynchronously in background
                        unawaited(
                          widget.controller.passengerReportingService
                              .submitReport(
                                category: selectedCategory,
                                severity: selectedSeverity,
                                description: descriptionController.text,
                                latitude: lat,
                                longitude: lng,
                                tripId: null,
                              )
                              .catchError((_) => 'local_fallback'),
                        );
                      },
                      child: const Text('Submit Report'),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              );
            },
          ),
        ));
      },
    );
  }

  void _showIncidentDetailsBottomSheet(BuildContext context, ReportWithTrust report) {
    final colorScheme = Theme.of(context).colorScheme;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.flag_rounded,
                    color: report.severity >= 4 ? colorScheme.error : Colors.orange,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${report.category} reported',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _StatChip(label: 'Severity', value: '${report.severity}/5'),
                  const SizedBox(width: 8),
                  _StatChip(label: 'Confidence', value: '${(report.passengerTrust * 100).toStringAsFixed(0)}%'),
                  if (report.isVerified) ...[
                    const SizedBox(width: 8),
                    const _StatChip(label: 'Status', value: 'Verified', color: Colors.green),
                  ] else if (report.isFlagged) ...[
                    const SizedBox(width: 8),
                    const _StatChip(label: 'Status', value: 'Flagged', color: Colors.orange),
                  ],
                ],
              ),
              if (report.description != null && report.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('"${report.description}"', style: const TextStyle(fontStyle: FontStyle.italic)),
              ],
              const SizedBox(height: 24),
              const Text('Is this still accurate?', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        if (report.firestoreId != null) {
                          await widget.controller.passengerReportingService.flagReport(report.firestoreId!, 'Inaccurate');
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report flagged as inaccurate.')));
                        }
                      },
                      icon: const Icon(Icons.thumb_down_outlined),
                      label: const Text('No (Flag)'),
                      style: OutlinedButton.styleFrom(foregroundColor: colorScheme.error),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        if (report.firestoreId != null) {
                          await widget.controller.passengerReportingService.verifyReport(report.firestoreId!);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report verified.')));
                        }
                      },
                      icon: const Icon(Icons.thumb_up_outlined),
                      label: const Text('Yes (Verify)'),
                      style: FilledButton.styleFrom(backgroundColor: Colors.green),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }



  void _handleMapReady() {
    _isMapReady = true;
    _syncMapCenter(force: true);
  }

  @override
  void didUpdateWidget(covariant _FullScreenMapCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.showHighRiskAreas != widget.showHighRiskAreas) {
      _showHighRiskAreas = widget.showHighRiskAreas;
    }
    if (oldWidget.showSaferRoutes != widget.showSaferRoutes) {
      _showSaferRoutes = widget.showSaferRoutes;
    }
    if (oldWidget.showReportedIncidents != widget.showReportedIncidents) {
      _showReportedIncidents = widget.showReportedIncidents;
    }
    if (oldWidget.showCommunitySafety != widget.showCommunitySafety) {
      _showCommunitySafety = widget.showCommunitySafety;
    }


    _syncMapCenter(force: false);

    final points = widget.routePoints;
    if (!widget.isTracking || points.isEmpty) {
      return;
    }

    // If we just started tracking, zoom in to the user's location
    if (widget.isTracking && !oldWidget.isTracking) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _mapController.move(points.last, 16.0);
      });
      return;
    }

    // Auto-pan if the location changed significantly
    if (points.last.latitude != oldWidget.routePoints.lastOrNull?.latitude ||
        points.last.longitude != oldWidget.routePoints.lastOrNull?.longitude) {
      _mapController.move(points.last, _mapController.camera.zoom);
    }
  }

  /// Determine the map center based on real data, not hardcoded coordinates.
  /// Priority: 1) live trip, 2) most recent completed trip, 3) GPS position
  LatLng _resolveMapCenter() {
    // 1. If actively tracking, use the latest route point
    if (widget.isTracking && widget.routePoints.isNotEmpty) {
      return widget.routePoints.last;
    }

    // 2. If we have completed trips, focus on the most recent one
    if (widget.controller.completedTrips.isNotEmpty) {
      final mostRecent = widget.controller.completedTrips.first;
      if (mostRecent.routePoints.isNotEmpty) {
        final p = mostRecent.routePoints.last;
        return LatLng(p['lat']!, p['lng']!);
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
  List<Polyline<Object>> _buildHistoricalTripPolylines(ColorScheme colorScheme, bool isZoomedOut) {
    final completedTrips = widget.controller.completedTrips;
    final polylines = <Polyline<Object>>[];

    for (final trip in completedTrips) {
      if (trip.routePoints.isEmpty) continue;
      
      // If zoomed out, only show high-risk trips to declutter
      final safetyScore = 100.0 - trip.riskScore;
      if (isZoomedOut && safetyScore >= 50) continue;

      final color = _tripRouteColor(trip);
      final points = trip.routePoints.map((p) => LatLng(p['lat']!, p['lng']!)).toList();

      // Use a gradient for high risk trips to simulate event heatmaps along the route
      List<Color>? gradient;
      if (safetyScore < 50 && points.length >= 3) {
        gradient = [
          Colors.green.withValues(alpha: 0.8),
          color.withValues(alpha: 0.8),
          color.withValues(alpha: 0.8),
          Colors.green.withValues(alpha: 0.8),
        ];
      }

      polylines.add(
        Polyline<Object>(
          points: points,
          color: color.withValues(alpha: 0.8),
          strokeWidth: isZoomedOut ? 3.0 : 6.0,
          borderStrokeWidth: isZoomedOut ? 1.0 : 2.5,
          borderColor: color,
          gradientColors: gradient,
          strokeCap: StrokeCap.round,
          strokeJoin: StrokeJoin.round,
        ),
      );
    }

    return polylines;
  }

  /// Build interactive markers (info and directional arrows) for routes
  List<Marker> _buildRouteInteractiveMarkers(ColorScheme colorScheme, bool isZoomedOut) {
    final completedTrips = widget.controller.completedTrips;
    final markers = <Marker>[];

    if (isZoomedOut) return markers; // Hide when zoomed out

    for (final trip in completedTrips) {
      if (trip.routePoints.length < 2) continue;

      final safetyScore = 100.0 - trip.riskScore;
      final points = trip.routePoints;
      final start = LatLng(points[0]['lat']!, points[0]['lng']!);
      final end = LatLng(points.last['lat']!, points.last['lng']!);
      
      // Info Marker at start
      markers.add(
        Marker(
          point: start,
          width: 32,
          height: 32,
          child: GestureDetector(
            onTap: () {
              _showTripSummaryBottomSheet(trip, safetyScore, colorScheme);
            },
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                shape: BoxShape.circle,
                border: Border.all(color: _tripRouteColor(trip), width: 2),
              ),
              child: Icon(Icons.info_outline, size: 20, color: _tripRouteColor(trip)),
            ),
          ),
        ),
      );

      // Directional arrow at end
      final preEnd = LatLng(points[points.length - 2]['lat']!, points[points.length - 2]['lng']!);
      final dy = end.latitude - preEnd.latitude;
      final dx = end.longitude - preEnd.longitude;
      final angle = atan2(dx, dy);

      markers.add(
        Marker(
          point: end,
          width: 24,
          height: 24,
          child: Transform.rotate(
            angle: angle,
            child: Icon(Icons.navigation, size: 20, color: _tripRouteColor(trip)),
          ),
        ),
      );
    }
    return markers;
  }

  void _showTripSummaryBottomSheet(Trip trip, double safetyScore, ColorScheme colorScheme) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Trip Summary', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.security, color: _tripRouteColor(trip)),
                title: Text('Safety Score: ${safetyScore.toStringAsFixed(0)}%'),
              ),
              ListTile(
                leading: const Icon(Icons.speed, color: Colors.orange),
                title: Text('Speeding Events: ${trip.speedingCount}'),
              ),
              ListTile(
                leading: const Icon(Icons.warning, color: Colors.red),
                title: Text('Harsh Braking: ${trip.brakingCount}'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
    );
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
  List<Polyline<Object>> _buildSaferRoutesPolylines(ColorScheme colorScheme) {
    final completedTrips = widget.controller.completedTrips;
    final polylines = <Polyline<Object>>[];

    for (final trip in completedTrips) {
      final safetyScore = 100.0 - trip.riskScore;
      if (safetyScore < 80) continue; // Only safe trips

      if (trip.routePoints.isEmpty) continue;

      final points = trip.routePoints.map((p) => LatLng(p['lat']!, p['lng']!)).toList();

      polylines.add(
        Polyline<Object>(
          points: points,
          color: colorScheme.tertiary.withValues(alpha: 0.8),
          strokeWidth: 6.0,
          borderStrokeWidth: 2.5,
          borderColor: colorScheme.tertiary,
          strokeCap: StrokeCap.round,
          strokeJoin: StrokeJoin.round,
        ),
      );
    }

    return polylines;
  }

  /// Build community routes as a polyline-based heatmap
  List<Polyline<Object>> _buildCommunityPolylines(ColorScheme colorScheme) {
    final communityTrips = widget.controller.communityTrips;
    final polylines = <Polyline<Object>>[];

    for (final trip in communityTrips) {
      if (trip.routePoints.isEmpty) continue;

      final color = _tripRouteColor(trip);
      final points = trip.routePoints.map((p) => LatLng(p['lat']!, p['lng']!)).toList();

      polylines.add(
        Polyline<Object>(
          points: points,
          color: color.withValues(alpha: 0.6),
          strokeWidth: 5.0,
          borderStrokeWidth: 2.0,
          borderColor: color,
          strokeCap: StrokeCap.round,
          strokeJoin: StrokeJoin.round,
        ),
      );
    }

    return polylines;
  }

  /// Build reported incident heatmap circles from real Firestore data.
  List<CircleMarker> _buildReportedIncidentHeatmap(ColorScheme colorScheme) {
    final circles = <CircleMarker>[];
    final controller = widget.controller;

    for (final r in controller.remoteReports) {
      if (r.latitude == null || r.longitude == null) continue;
      final severity = (r.severity).clamp(1, 5);
      final color = severity >= 4
          ? colorScheme.error
          : (severity == 3 ? Colors.orange : colorScheme.tertiary);

      circles.add(
        CircleMarker(
          point: LatLng(r.latitude!, r.longitude!),
          color: color.withValues(alpha: 0.25),
          borderStrokeWidth: 0,
          useRadiusInMeter: false,
          radius: 40 + (severity * 5.0), 
        ),
      );
    }

    return circles;
  }

  /// Build reported incident markers from real Firestore data only.
  List<Marker> _buildReportedIncidentMarkers(ColorScheme colorScheme) {
    final markers = <Marker>[];
    final controller = widget.controller;

    for (final r in controller.remoteReports) {
      if (r.latitude == null || r.longitude == null) continue;
      final severity = (r.severity).clamp(1, 5);
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
              _showIncidentDetailsBottomSheet(context, r);
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

  Widget _buildCommunitySafetyCard(ColorScheme colorScheme) {
    final trips = widget.controller.communityTrips;
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
      elevation: 0,
      margin: EdgeInsets.zero,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.public_rounded, size: 22, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Community Safety',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${avgSafety.toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: avgColor,
                  ),
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    'Avg Score',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StatChip(label: 'Analyzed', value: '${trips.length}', color: colorScheme.primary),
                const SizedBox(width: 8),
                _StatChip(label: 'High Risk', value: '$highRiskCount', color: Colors.red),
              ],
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

    final isZoomedOut = _currentZoom < 13.0;
    
    // Build layers from real data
    final List<Polyline<Object>> historicalPolylines = _buildHistoricalTripPolylines(
      colorScheme,
      isZoomedOut
    );
    final List<Marker> routeInteractiveMarkers = _buildRouteInteractiveMarkers(colorScheme, isZoomedOut);

    final List<Marker> highRiskMarkers = _showHighRiskAreas
        ? _buildHighRiskAreaMarkers(colorScheme)
        : <Marker>[];
    final List<Polyline<Object>> saferRoutesPolylines = _showSaferRoutes
        ? _buildSaferRoutesPolylines(colorScheme)
        : <Polyline<Object>>[];
    final List<Marker> incidentMarkers = _showReportedIncidents
        ? _buildReportedIncidentMarkers(colorScheme)
        : <Marker>[];
    final List<CircleMarker> incidentHeatmap = _showReportedIncidents
        ? _buildReportedIncidentHeatmap(colorScheme)
        : <CircleMarker>[];
    final List<Polyline<Object>> communityPolylines = _showCommunitySafety
        ? _buildCommunityPolylines(colorScheme)
        : <Polyline<Object>>[];

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
              onPositionChanged: (position, hasGesture) {
                final newZoom = position.zoom;
                if (newZoom != null && newZoom != _currentZoom) {
                  setState(() => _currentZoom = newZoom as double);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: Theme.of(context).brightness == Brightness.dark
                    ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
                    : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.saferide.app',
              ),
              // Historical trip routes (color-coded by safety score)
              PolylineLayer<Object>(polylines: historicalPolylines),
              // Community heatmap polylines
              PolylineLayer<Object>(polylines: communityPolylines),
              // Safer routes layer (green, score >= 80)
              PolylineLayer<Object>(polylines: saferRoutesPolylines),
              // High-risk area markers
              MarkerLayer(markers: highRiskMarkers),
              // Route interactive markers (info + arrows)
              MarkerLayer(markers: routeInteractiveMarkers),
              // Reported incidents heatmap (below lines and markers)
              CircleLayer(circles: incidentHeatmap),
              // Active trip polyline (on top)
              if (hasRealTripRoute)
                PolylineLayer<Object>(
                  polylines: [
                    Polyline<Object>(
                      points: widget.routePoints,
                      strokeWidth: 7.0,
                      color: colorScheme.primary.withValues(alpha: 0.9),
                      borderStrokeWidth: 3.0,
                      borderColor: colorScheme.primary,
                      strokeCap: StrokeCap.round,
                      strokeJoin: StrokeJoin.round,
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
            right: 12,
            child: _MapLayerControls(
              showHighRiskAreas: _showHighRiskAreas,
              showSaferRoutes: _showSaferRoutes,
              showReportedIncidents: _showReportedIncidents,
              showCommunitySafety: _showCommunitySafety,
              onHighRiskAreasChanged: (v) {
                setState(() => _showHighRiskAreas = v);
                widget.onHighRiskAreasChanged(v);
              },
              onSaferRoutesChanged: (v) {
                setState(() => _showSaferRoutes = v);
                widget.onSaferRoutesChanged(v);
              },
              onReportedIncidentsChanged: (v) {
                setState(() => _showReportedIncidents = v);
                widget.onReportedIncidentsChanged(v);
              },
              onCommunitySafetyChanged: (v) {
                setState(() => _showCommunitySafety = v);
                widget.onCommunitySafetyChanged(v);
              },
            ),
          ),
          // (Crowd Alert Banner moved to end of Stack to prevent overlay issues)
          // Full screen toggle button
          Positioned(
            top: 170, // Placed below the layer controls
            right: 12,
            child: FloatingActionButton.small(
              heroTag: 'map_fullscreen_btn_${widget.isFullScreen}',
              backgroundColor: colorScheme.surface,
              foregroundColor: colorScheme.primary,
              onPressed: () {
                if (widget.isFullScreen) {
                  Navigator.of(context).pop();
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) {
                        final ctrl = context.watch<TripController>();
                        final points = ctrl.routePoints
                            .map((p) => LatLng(p['lat']!, p['lng']!))
                            .toList();
                        return Scaffold(
                          body: SafeArea(
                            child: _FullScreenMapCard(
                              isTracking: ctrl.isTracking,
                              routePoints: points,
                              controller: ctrl,
                              showHighRiskAreas: _showHighRiskAreas,
                              showSaferRoutes: _showSaferRoutes,
                              showReportedIncidents: _showReportedIncidents,
                              showCommunitySafety: _showCommunitySafety,
                              onHighRiskAreasChanged: widget.onHighRiskAreasChanged,
                              onSaferRoutesChanged: widget.onSaferRoutesChanged,
                              onReportedIncidentsChanged: widget.onReportedIncidentsChanged,
                              onCommunitySafetyChanged: widget.onCommunitySafetyChanged,
                              isFullScreen: true,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }
              },
              child: Icon(
                widget.isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
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
          // Live safety score overlay (top left)
          if (widget.controller.isTracking)
            Positioned(
              top: 12,
              left: 12,
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
                    elevation: 0,
                    margin: EdgeInsets.zero,
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withValues(alpha: 0.96),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Live Safety',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
                          const SizedBox(width: 12),
                          Icon(Icons.shield, color: color, size: 28),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          // Community Safety Stats (top-left, when not tracking)
          if (!widget.controller.isTracking && hasCompletedTrips)
            Positioned(
              top: 12,
              left: 12,
              child: _buildCommunitySafetyCard(colorScheme),
            ),
          // Report Hazard FAB
          Positioned(
            bottom: 60,
            right: 12,
            child: FloatingActionButton(
              heroTag: 'report_fab',
              backgroundColor: colorScheme.errorContainer,
              foregroundColor: colorScheme.onErrorContainer,
              elevation: 4,
              onPressed: _showReportHazardDialog,
              child: const Icon(Icons.warning_rounded),
            ),
          ),
          // Legend
          Positioned(
            bottom: 12,
            right: 12,
            child: _CollapsibleLegend(
              showHighRiskAreas: widget.showHighRiskAreas,
              showSaferRoutes: widget.showSaferRoutes,
              showReportedIncidents: widget.showReportedIncidents,
              showCommunitySafety: widget.showCommunitySafety,
            ),
          ),
          // Crowd Alert Banner (Placed at end of Stack so it stays on top of other HUDs)
          if (widget.controller.currentAlert != null)
            Positioned(
              top: 90,
              left: 12,
              right: 60,
              child: _CrowdAlertBanner(
                alert: widget.controller.currentAlert!,
                onDismiss: () {
                  // Clears automatically in controller after 8s
                },
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
    // Create a radial gradient that is solid in the center and transparent at the edges
    final gradient = RadialGradient(
      colors: [
        color.withValues(alpha: 0.7), // Strong core
        color.withValues(alpha: 0.3), // Mid fade
        color.withValues(alpha: 0.0), // Fully transparent edge
      ],
      stops: const [0.2, 0.6, 1.0],
    );

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..shader = gradient.createShader(rect)
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

class _CollapsibleLegend extends StatefulWidget {
  final bool showHighRiskAreas;
  final bool showSaferRoutes;
  final bool showReportedIncidents;
  final bool showCommunitySafety;

  const _CollapsibleLegend({
    required this.showHighRiskAreas,
    required this.showSaferRoutes,
    required this.showReportedIncidents,
    required this.showCommunitySafety,
  });

  @override
  State<_CollapsibleLegend> createState() => _CollapsibleLegendState();
}

class _CollapsibleLegendState extends State<_CollapsibleLegend> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (!_expanded) {
      return FloatingActionButton.small(
        heroTag: 'legend_fab',
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.primary,
        elevation: 2,
        onPressed: () => setState(() => _expanded = true),
        child: const Icon(Icons.info_outline_rounded),
      );
    }

    final showRouteColors = widget.showHighRiskAreas || widget.showSaferRoutes || widget.showCommunitySafety;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Legend', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => setState(() => _expanded = false),
                child: Icon(Icons.close, size: 16, color: colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (showRouteColors) ...[
            const Padding(
              padding: EdgeInsets.only(bottom: 6, top: 2),
              child: Text('Safety/Risk Score', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 12, height: 3, color: Colors.red.withValues(alpha: 0.6)),
                  const SizedBox(width: 4),
                  const Text('High-Risk (<50%)', style: TextStyle(fontSize: 11)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 12, height: 3, color: Colors.orange.withValues(alpha: 0.6)),
                  const SizedBox(width: 4),
                  const Text('Moderate (50-79%)', style: TextStyle(fontSize: 11)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 12, height: 3, color: Colors.green.withValues(alpha: 0.7)),
                  const SizedBox(width: 4),
                  const Text('Safe (≥80%)', style: TextStyle(fontSize: 11)),
                ],
              ),
            ),
          ],
          if (widget.showReportedIncidents)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.flag_rounded, size: 14, color: colorScheme.error),
                const SizedBox(width: 4),
                const Text('Incidents', style: TextStyle(fontSize: 11)),
              ],
            ),
          if (!showRouteColors && !widget.showReportedIncidents)
            const Text('No layers selected', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _StatChip({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? Theme.of(context).colorScheme.primary).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
          const SizedBox(width: 4),
          Text(value, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _CrowdAlertBanner extends StatefulWidget {
  final ReportWithTrust alert;
  final VoidCallback onDismiss;

  const _CrowdAlertBanner({required this.alert, required this.onDismiss});

  @override
  State<_CrowdAlertBanner> createState() => _CrowdAlertBannerState();
}

class _CrowdAlertBannerState extends State<_CrowdAlertBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    ));
    
    _animController.forward();
  }

  @override
  void didUpdateWidget(_CrowdAlertBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.alert.reportId != widget.alert.reportId) {
      _animController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SlideTransition(
      position: _slideAnimation,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        color: colorScheme.errorContainer,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: widget.onDismiss,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: colorScheme.error,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.alert.category} Reported',
                        style: TextStyle(
                          color: colorScheme.error,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        widget.alert.description?.isNotEmpty == true
                            ? '"${widget.alert.description}"'
                            : 'Hazard ahead',
                        style: TextStyle(
                          color: colorScheme.onErrorContainer,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Confidence: ${(widget.alert.passengerTrust * 100).toInt()}% • Severity: ${widget.alert.severity}/5',
                        style: TextStyle(
                          color: colorScheme.onErrorContainer.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

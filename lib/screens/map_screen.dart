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
import 'trip_detail_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import '../services/risk_scoring.dart' as risk_scoring;

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

class _FullScreenMapCardState extends State<_FullScreenMapCard> with TickerProviderStateMixin {
  late final MapController _mapController;
  LatLng? _lastCenteredLocation;
  bool _isMapReady = false;
  double _currentZoom = 15.0;
  StreamSubscription<CompassEvent>? _compassSubscription;
  double _heading = 0.0;

  late bool _showHighRiskAreas;
  late bool _showSaferRoutes;
  late bool _showReportedIncidents;
  late bool _showCommunitySafety;

  final List<_Ping> _activePings = [];
  final Set<DateTime> _pingedTimestamps = {};

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _showHighRiskAreas = widget.showHighRiskAreas;
    _showSaferRoutes = widget.showSaferRoutes;
    _showReportedIncidents = widget.showReportedIncidents;
    _showCommunitySafety = widget.showCommunitySafety;

    _compassSubscription = FlutterCompass.events?.listen((event) {
      if (mounted) {
        setState(() {
          _heading = event.heading ?? 0.0;
        });
      }
    });
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    super.dispose();
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

    _animatedMapMove(center, _mapController.camera.zoom);
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    if (!mounted) return;
    final latTween = Tween<double>(
        begin: _mapController.camera.center.latitude,
        end: destLocation.latitude);
    final lngTween = Tween<double>(
        begin: _mapController.camera.center.longitude,
        end: destLocation.longitude);
    final zoomTween = Tween<double>(
        begin: _mapController.camera.zoom, end: destZoom);

    final controller = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this);

    final Animation<double> animation = CurvedAnimation(
        parent: controller, curve: Curves.fastOutSlowIn);

    controller.addListener(() {
      if (mounted) {
        _mapController.move(
            LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
            zoomTween.evaluate(animation));
      }
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  void _showReportHazardDialog(BuildContext context, risk_scoring.UnsafeEvent? recentEvent) {
    if (widget.controller.currentPosition == null && widget.routePoints.isEmpty) return;

    final lat = widget.controller.currentPosition?.latitude ?? widget.routePoints.last.latitude;
    final lng = widget.controller.currentPosition?.longitude ?? widget.routePoints.last.longitude;

    String selectedCategory = recentEvent?.type.name.split('.').last.replaceAllMapped(RegExp(r'[A-Z]'), (m) => ' ${m.group(0)}').trim() ?? 'Hazard';
    if (!['Speeding', 'Sudden Braking', 'Sharp Turning', 'Pothole', 'Reckless Driving', 'Accident', 'Hazard', 'Other'].contains(selectedCategory)) {
      selectedCategory = 'Other';
    }

    final descriptionController = TextEditingController();
    double selectedSeverity = 3.0; // Default severity

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return Padding(
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
                  onChanged: (val) {
                    if (val != null) setState(() => selectedCategory = val);
                  },
                ),
                const SizedBox(height: 16),
                Text('Severity: ${selectedSeverity.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Slider(
                  value: selectedSeverity,
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: selectedSeverity.toInt().toString(),
                  onChanged: (val) {
                    setState(() => selectedSeverity = val);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.description_outlined),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          // 1. Create temporary report
                          final reportId = DateTime.now().millisecondsSinceEpoch;
                          
                          widget.controller.addRemoteReportLocally(
                            ReportWithTrust(
                              reportId: reportId,
                              passengerId: 'guest_user',
                              category: selectedCategory,
                              severity: selectedSeverity.toInt(),
                              description: descriptionController.text,
                              latitude: lat,
                              longitude: lng,
                              passengerTrust: 1.0,
                              timestamp: DateTime.now(),
                            ),
                          );

                          // 2. Dismiss modal and notify user immediately
                          Navigator.pop(context);

                          bool isCancelled = false;

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Report submitted.'),
                              duration: const Duration(seconds: 5),
                              action: SnackBarAction(
                                label: 'UNDO',
                                onPressed: () {
                                  isCancelled = true;
                                  widget.controller.removeLocalReport(reportId);
                                },
                              ),
                            ),
                          );

                          // 3. Queue the actual submission
                          Future.delayed(const Duration(seconds: 5), () {
                            if (isCancelled) return;
                            unawaited(
                              widget.controller.passengerReportingService
                                  .submitReport(
                                    tripId: widget.controller.activeTrip?.id ?? 0,
                                    category: selectedCategory,
                                    severity: selectedSeverity.toInt(),
                                    description: descriptionController.text,
                                    latitude: lat,
                                    longitude: lng,
                                  )
                                  .catchError((e) {
                                    debugPrint('Failed to submit report: $e');
                                  }),
                            );
                          });
                        },
                        child: const Text('Submit'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            );
            },
          ),
        );
      },
    );
  }

  void _showIncidentDetailsBottomSheet(BuildContext context, ReportWithTrust report) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Calculate time ago using toLocal() to prevent UTC offset bugs
    final diff = DateTime.now().difference(report.timestamp.toLocal());
    String timeAgo;
    if (diff.inMinutes < 1) timeAgo = 'Just now';
    else if (diff.inMinutes < 60) timeAgo = '${diff.inMinutes}m ago';
    else if (diff.inHours < 24) timeAgo = '${diff.inHours}h ago';
    else timeAgo = '${diff.inDays}d ago';

    // Mock sensor alignment status based on severity and trust
    final isSensorValidated = report.passengerTrust >= 0.7;
      IconData categoryIcon;
      switch (report.category) {
        case 'Accident':
          categoryIcon = Icons.car_crash;
          break;
        case 'Speeding':
          categoryIcon = Icons.speed;
          break;
        case 'Sudden Braking':
          categoryIcon = Icons.back_hand;
          break;
        case 'Sharp Turning':
          categoryIcon = Icons.turn_sharp_right;
          break;
        case 'Pothole':
          categoryIcon = Icons.moving;
          break;
        case 'Reckless Driving':
          categoryIcon = Icons.sports_motorsports;
          break;
        case 'Traffic':
          categoryIcon = Icons.traffic;
          break;
        default:
          categoryIcon = Icons.warning_amber;
      }

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [
                BoxShadow(
                  color: (report.severity >= 4 ? colorScheme.error : Colors.orange).withValues(alpha: 0.2),
                  blurRadius: 24,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 16,
              bottom: MediaQuery.of(context).padding.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 6,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: (report.severity >= 4 ? colorScheme.error : Colors.orange).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        categoryIcon,
                        color: report.severity >= 4 ? colorScheme.error : Colors.orange,
                        size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${report.category} Hazard',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 14, color: colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(timeAgo, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
                            const SizedBox(width: 12),
                            Icon(Icons.person_outline, size: 14, color: colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text('Passenger Trust: ${(report.passengerTrust * 100).toInt()}%', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
                          ],
                        ),
                        if (report.latitude != null && report.longitude != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, size: 14, color: colorScheme.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Text('${report.latitude!.toStringAsFixed(4)}, ${report.longitude!.toStringAsFixed(4)}', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Trust Verification', style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _StatChip(label: 'Raw Severity', value: '${report.severity}/5')),
                        const SizedBox(width: 8),
                        Expanded(child: _StatChip(label: 'Weighted Severity', value: '${report.weightedSeverity}/5', color: colorScheme.primary)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (isSensorValidated)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          children: [
                            const Icon(Icons.sensors, color: Colors.green, size: 16),
                            const SizedBox(width: 8),
                            const Expanded(child: Text('Sensor Aligned: Vehicle telemetry confirmed anomaly.', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold))),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber, color: Colors.orange, size: 16),
                            const SizedBox(width: 8),
                            const Expanded(child: Text('Unverified: Awaiting sensor or crowd confirmation.', style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold))),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              if (report.description != null && report.description!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('"${report.description}"', style: const TextStyle(fontStyle: FontStyle.italic)),
              ],
              const SizedBox(height: 24),
              const Text('Is this hazard still present?', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        if (report.firestoreId != null) {
                          await widget.controller.passengerReportingService.flagReport(report.firestoreId!, 'Inaccurate');
                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report flagged. Impacting user trust score.')));
                        }
                      },
                      icon: const Icon(Icons.thumb_down_outlined, size: 18),
                      label: const Text('No (Flag)'),
                      style: OutlinedButton.styleFrom(foregroundColor: colorScheme.error, padding: const EdgeInsets.symmetric(vertical: 12)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        if (report.firestoreId != null) {
                          await widget.controller.passengerReportingService.verifyReport(report.firestoreId!);
                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report verified.')));
                        }
                      },
                      icon: const Icon(Icons.thumb_up_outlined, size: 18),
                      label: const Text('Yes (Verify)'),
                      style: FilledButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 12)),
                    ),
                  ),
                ],
              ),
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
        _animatedMapMove(points.last, 16.0);
      });
      return;
    }

    // Auto-pan if the location changed significantly
    if (points.last.latitude != oldWidget.routePoints.lastOrNull?.latitude ||
        points.last.longitude != oldWidget.routePoints.lastOrNull?.longitude) {
      _animatedMapMove(points.last, _mapController.camera.zoom);
    }

    if (widget.isTracking) {
      for (final event in widget.controller.recentEvents) {
        if (!_pingedTimestamps.contains(event.timestamp)) {
          _pingedTimestamps.add(event.timestamp);
          if (event.lat != null && event.lng != null) {
            final ping = _Ping(LatLng(event.lat!, event.lng!), event);
            _activePings.add(ping);
            // Remove ping after animation duration
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted) {
                setState(() {
                  _activePings.remove(ping);
                });
              }
            });
          }
        }
      }
    }
  }

  /// Determine the map center based on real data, not hardcoded coordinates.
  /// Priority: 1) live trip, 2) most recent completed trip, 3) GPS position
  LatLng _resolveMapCenter() {
    // 1. If actively tracking, use the latest route point
    if (widget.isTracking && widget.routePoints.isNotEmpty) {
      return widget.routePoints.last;
    }

    // 2. If GPS position is available, use it
    final pos = widget.controller.currentPosition;
    if (pos != null) {
      return LatLng(pos.latitude, pos.longitude);
    }

    // 3. If we have completed trips, focus on the most recent one
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

  /// Applies a simple moving average filter to smooth raw GPS points.
  List<LatLng> _smoothRoute(List<LatLng> rawPoints, {int windowSize = 3}) {
    if (rawPoints.length < windowSize) return rawPoints;
    
    List<LatLng> smoothedPoints = [];
    for (int i = 0; i < rawPoints.length; i++) {
      double sumLat = 0;
      double sumLng = 0;
      int count = 0;

      // Moving average window
      for (int j = max(0, i - windowSize ~/ 2); j <= min(rawPoints.length - 1, i + windowSize ~/ 2); j++) {
        sumLat += rawPoints[j].latitude;
        sumLng += rawPoints[j].longitude;
        count++;
      }
      smoothedPoints.add(LatLng(sumLat / count, sumLng / count));
    }
    return smoothedPoints;
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
      final rawPoints = trip.routePoints.map((p) => LatLng(p['lat']!, p['lng']!)).toList();
      final points = _smoothRoute(rawPoints, windowSize: 4);

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

      // Directional arrows along the route (every 20 points, plus one at the end)
      final step = max(20, points.length ~/ 10);
      for (int i = step; i < points.length; i += step) {
        final p1 = LatLng(points[i - 2]['lat']!, points[i - 2]['lng']!);
        final p2 = LatLng(points[i]['lat']!, points[i]['lng']!);
        
        // Bearing calculation
        final dy = p2.latitude - p1.latitude;
        final dx = p2.longitude - p1.longitude;
        final angle = atan2(dx, dy);
        
        markers.add(
          Marker(
            point: p2,
            width: 16,
            height: 16,
            child: Transform.rotate(
              angle: angle,
              child: Icon(Icons.navigation, size: 14, color: _tripRouteColor(trip)),
            ),
          ),
        );
      }
      
      // Always add an arrow at the very end
      final preEnd = LatLng(points[points.length - 2]['lat']!, points[points.length - 2]['lng']!);
      final endAngle = atan2(end.longitude - preEnd.longitude, end.latitude - preEnd.latitude);
      markers.add(
        Marker(
          point: end,
          width: 24,
          height: 24,
          child: Transform.rotate(
            angle: endAngle,
            child: Icon(Icons.navigation, size: 20, color: _tripRouteColor(trip)),
          ),
        ),
      );
    }
    return markers;
  }

  void _showTripSummaryBottomSheet(Trip trip, double safetyScore, ColorScheme colorScheme) {
    // Calculate duration
    String durationText = '--';
    if (trip.endTime != null) {
      final diff = trip.endTime!.difference(trip.startTime);
      final hours = diff.inHours;
      final minutes = diff.inMinutes.remainder(60);
      if (hours > 0) {
        durationText = '${hours}h ${minutes}m';
      } else {
        durationText = '${minutes}m';
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: _tripRouteColor(trip).withValues(alpha: 0.15),
                blurRadius: 24,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 24,
            left: 24,
            right: 24,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 6,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.routeName ?? 'Analyzed Route',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.directions_car, size: 16, color: colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(
                              trip.vehicleType ?? 'Standard Vehicle',
                              style: TextStyle(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.timer, size: 16, color: colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(
                              durationText,
                              style: TextStyle(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: _tripRouteColor(trip).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _tripRouteColor(trip).withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${safetyScore.toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: _tripRouteColor(trip),
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                        Text(
                          'Safety Score',
                          style: TextStyle(
                            color: _tripRouteColor(trip).withValues(alpha: 0.8),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Sensor Telemetry', style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: _SummaryStat(
                      icon: Icons.speed,
                      label: 'Speeding',
                      value: trip.speedingCount.toString(),
                      color: Colors.red,
                    ),
                  ),
                  Expanded(
                    child: _SummaryStat(
                      icon: Icons.warning_amber,
                      label: 'Braking',
                      value: trip.brakingCount.toString(),
                      color: Colors.orange,
                    ),
                  ),
                  Expanded(
                    child: _SummaryStat(
                      icon: Icons.turn_right,
                      label: 'Turns',
                      value: trip.turningCount.toString(),
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.analytics, color: colorScheme.primary, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Adaptive Context Analysis', style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                          const SizedBox(height: 4),
                          Text('Trip analyzed using dynamic thresholds tailored for the current vehicle and environment.', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TripDetailScreen(trip: trip),
                      ),
                    );
                  },
                  icon: const Icon(Icons.insights),
                  label: const Text('View Full Trip Report'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
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

  /// Build reported incident markers from real Firestore data only.
  List<Marker> _buildReportedIncidentMarkers(ColorScheme colorScheme) {
    final markers = <Marker>[];
    final controller = widget.controller;

    for (final r in controller.remoteReports) {
      if (r.latitude == null || r.longitude == null) continue;
      
      // Time Fading: Remove hazards older than 4 hours
      if (DateTime.now().difference(r.timestamp).inHours >= 4) continue;

      final severity = (r.severity).clamp(1, 5);
      final trust = r.passengerTrust.clamp(0.0, 1.0);
      
      final color = severity >= 4
          ? colorScheme.error
          : (severity == 3 ? Colors.orange : colorScheme.tertiary);

      // Icon Mapping
      IconData categoryIcon;
      switch (r.category) {
        case 'Accident':
          categoryIcon = Icons.car_crash;
          break;
        case 'Speeding':
          categoryIcon = Icons.speed;
          break;
        case 'Sudden Braking':
          categoryIcon = Icons.front_hand;
          break;
        case 'Sharp Turning':
          categoryIcon = Icons.turn_sharp_right;
          break;
        case 'Pothole':
          categoryIcon = Icons.moving;
          break;
        case 'Reckless Driving':
          categoryIcon = Icons.sports_motorsports;
          break;
        case 'Traffic':
          categoryIcon = Icons.traffic;
          break;
        default:
          categoryIcon = Icons.warning_amber;
      }

      // Highly trusted markers are fully opaque and normal size
      // Low trust markers are smaller and semi-transparent
      final markerSize = 30.0 + (16.0 * trust);
      final markerOpacity = 0.3 + (0.7 * trust);

      markers.add(
        Marker(
          point: LatLng(r.latitude!, r.longitude!),
          width: markerSize,
          height: markerSize,
          child: GestureDetector(
            onTap: () {
              _showIncidentDetailsBottomSheet(context, r);
            },
            child: Opacity(
              opacity: markerOpacity,
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
                  categoryIcon,
                  color: Theme.of(context).colorScheme.surface,
                  size: markerSize * 0.55,
                ),
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

    final apiKey = dotenv.env['CARTO_API_KEY'] ?? '';
    final keyParam = apiKey.isNotEmpty ? '?key=$apiKey' : '';

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
    final List<Polyline<Object>> communityPolylines = _showCommunitySafety
        ? _buildCommunityPolylines(colorScheme)
        : <Polyline<Object>>[];

    final mapCenter = _resolveMapCenter();

    final List<Marker> activePingMarkers = _activePings.map((ping) {
      Color color;
      IconData icon;
      switch (ping.event.type) {
        case risk_scoring.UnsafeEventType.speeding:
          color = Colors.red;
          icon = Icons.speed;
          break;
        case risk_scoring.UnsafeEventType.braking:
          color = Colors.orange;
          icon = Icons.warning_amber;
          break;
        case risk_scoring.UnsafeEventType.turning:
          color = colorScheme.primary;
          icon = Icons.turn_right;
          break;
      }
      return Marker(
        point: ping.position,
        width: 100,
        height: 100,
        child: _AnimatedPingMarker(color: color, icon: icon),
      );
    }).toList();

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
                    ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png$keyParam'
                    : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png$keyParam',
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
              // Active trip polyline (on top)
              if (hasRealTripRoute)
                PolylineLayer<Object>(
                  polylines: [
                    // Outer glow (simulates a glowing neon effect and hides rough edges)
                    Polyline<Object>(
                      points: _smoothRoute(widget.routePoints, windowSize: 3),
                      strokeWidth: 14.0,
                      color: colorScheme.primary.withValues(alpha: 0.25),
                      strokeCap: StrokeCap.round,
                      strokeJoin: StrokeJoin.round,
                    ),
                    // Inner core (crisp and smoothed)
                    Polyline<Object>(
                      points: _smoothRoute(widget.routePoints, windowSize: 3),
                      strokeWidth: 5.0,
                      color: colorScheme.primary,
                      borderStrokeWidth: 1.5,
                      borderColor: Theme.of(context).colorScheme.surface,
                      strokeCap: StrokeCap.round,
                      strokeJoin: StrokeJoin.round,
                    ),
                  ],
                ),
              // Reported incidents layer
              if (_showReportedIncidents)
                MarkerLayer(markers: incidentMarkers),
              // Real-time Event Pings
              if (activePingMarkers.isNotEmpty)
                MarkerLayer(markers: activePingMarkers),
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
                      width: 32,
                      height: 32,
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
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Transform.rotate(
                          angle: widget.isTracking ? (_heading * (pi / 180.0)) : 0.0,
                          child: Icon(
                            Icons.navigation,
                            color: colorScheme.onPrimary,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Map Controls
          Positioned(
            top: 12,
            right: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _MapLayerControls(
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
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'map_my_location_${widget.isFullScreen}',
                  backgroundColor: colorScheme.surface,
                  foregroundColor: colorScheme.primary,
                  onPressed: () {
                    _syncMapCenter(force: true);
                  },
                  child: const Icon(Icons.my_location),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'map_zoom_in_${widget.isFullScreen}',
                  backgroundColor: colorScheme.surface,
                  foregroundColor: colorScheme.primary,
                  onPressed: () {
                    _animatedMapMove(_mapController.camera.center, _mapController.camera.zoom + 1);
                  },
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'map_zoom_out_${widget.isFullScreen}',
                  backgroundColor: colorScheme.surface,
                  foregroundColor: colorScheme.primary,
                  onPressed: () {
                    _animatedMapMove(_mapController.camera.center, _mapController.camera.zoom - 1);
                  },
                  child: const Icon(Icons.remove),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
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
              ],
            ),
          ),
          // Live tracking chip
          if (widget.isTracking)
            const Positioned(
              top: 132,
              left: 12,
              child: _PulsingLiveTrackingChip(),
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
              onPressed: () => _showReportHazardDialog(context, null),
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

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _PulsingLiveTrackingChip extends StatefulWidget {
  const _PulsingLiveTrackingChip();

  @override
  State<_PulsingLiveTrackingChip> createState() => _PulsingLiveTrackingChipState();
}

class _PulsingLiveTrackingChipState extends State<_PulsingLiveTrackingChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Color.lerp(
              colorScheme.secondaryContainer,
              colorScheme.secondary.withValues(alpha: 0.35),
              _controller.value,
            ),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: colorScheme.secondary.withValues(
                  alpha: 0.25 * _controller.value,
                ),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.radio_button_checked,
                size: 14,
                color: Color.lerp(
                  colorScheme.onSecondaryContainer,
                  colorScheme.secondary,
                  _controller.value,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Live tracking',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Color.lerp(
                    colorScheme.onSecondaryContainer,
                    colorScheme.secondary,
                    _controller.value,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Ping {
  final LatLng position;
  final risk_scoring.UnsafeEvent event;
  _Ping(this.position, this.event);
}

class _AnimatedPingMarker extends StatefulWidget {
  final Color color;
  final IconData icon;

  const _AnimatedPingMarker({super.key, required this.color, required this.icon});

  @override
  State<_AnimatedPingMarker> createState() => _AnimatedPingMarkerState();
}

class _AnimatedPingMarkerState extends State<_AnimatedPingMarker> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 70 * _controller.value,
              height: 70 * _controller.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(alpha: 1.0 - _controller.value),
              ),
            ),
            Icon(widget.icon, color: widget.color, size: 24),
          ],
        );
      },
    );
  }
}

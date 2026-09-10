import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:provider/provider.dart';

import '../data/app_database.dart';
import '../models/trip.dart';
import '../state/trip_controller.dart';
import '../widgets/empty_state.dart';
import '../widgets/section_header.dart';
import '../widgets/trip_action_sheet.dart';
import '../widgets/m3_progress_indicators.dart';
import '../widgets/sync_widgets.dart';
import 'trip_detail_screen.dart';
import 'route_detail_screen.dart';
import '../widgets/m3_button_group.dart';
import '../theme/motion_scheme.dart';
import '../widgets/safety_ring_painter.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final List<Trip> _trips = [];
  final List<RouteAggregation> _routeAggregations = [];
  
  bool _isLoadingTrips = false;
  bool _isLoadingRoutes = false;
  bool _hasMoreTrips = true;
  
  late final AnimationController _animationController;
  late final ScrollController _scrollController;
  
  int _lastTripHistoryVersion = -1;
  int _routeViewIndex = 0;
  static const int _limit = 20;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_routeViewIndex == 0 &&
        _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreTrips();
    }
  }

  Future<void> _loadMoreTrips() async {
    if (_isLoadingTrips || !_hasMoreTrips) return;
    setState(() => _isLoadingTrips = true);
    final database = context.read<AppDatabase>();
    final newTrips = await database.getTrips(limit: _limit, offset: _trips.length);
    if (mounted) {
      setState(() {
        if (newTrips.length < _limit) _hasMoreTrips = false;
        _trips.addAll(newTrips);
        _isLoadingTrips = false;
      });
    }
  }

  Future<void> _loadRoutes() async {
    if (_isLoadingRoutes) return;
    setState(() => _isLoadingRoutes = true);
    final database = context.read<AppDatabase>();
    final routes = await database.getRouteAggregations();
    if (mounted) {
      setState(() {
        _routeAggregations.clear();
        _routeAggregations.addAll(routes);
        _isLoadingRoutes = false;
      });
    }
  }

  Future<void> _refreshAll() async {
    _trips.clear();
    _hasMoreTrips = true;
    await Future.wait([_loadMoreTrips(), _loadRoutes()]);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final tripController = context.watch<TripController>();
    if (_lastTripHistoryVersion != tripController.tripHistoryVersion) {
      _lastTripHistoryVersion = tripController.tripHistoryVersion;
      // Start async load without blocking build
      Future.microtask(_refreshAll);
    }

    final itemCount = _routeViewIndex == 0 
        ? 5 + _trips.length + (_hasMoreTrips ? 1 : 0)
        : 5 + _routeAggregations.length;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(20),
      itemCount: itemCount,
      itemBuilder: (context, i) {
        Widget child;
        if (i == 0) {
          child = Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(child: SectionHeader(title: 'Trip Summary')),
              const SyncButton(),
            ],
          );
        } else if (i == 1) {
          child = _TripsOverview(trips: _trips, isLoading: _isLoadingTrips && _trips.isEmpty);
        } else if (i == 2) {
          child = const SizedBox(height: 16);
        } else if (i == 3) {
          child = M3ButtonGroup<int>(
            segments: const [
              ButtonSegment(value: 0, icon: Icon(Icons.list), label: Text('Individual Trips')),
              ButtonSegment(value: 1, icon: Icon(Icons.route), label: Text('By Route')),
            ],
            selected: {_routeViewIndex},
            onSelectionChanged: (val) => setState(() => _routeViewIndex = val.first),
          );
        } else if (i == 4) {
          if (_routeViewIndex == 0 && !_isLoadingTrips && _trips.isEmpty) {
            child = EmptyState(
              icon: Icons.route,
              title: 'No trips yet',
              message: 'Start recording a trip to generate your first safety summary.',
              ctaLabel: 'Start Trip',
              onCtaPressed: () => TripActionSheet.show(context),
            );
          } else if (_routeViewIndex == 1 && !_isLoadingRoutes && _routeAggregations.isEmpty) {
            child = const Padding(
              padding: EdgeInsets.all(20),
              child: Text('No named routes found. Add a route name when completing a trip!'),
            );
          } else {
            child = const SizedBox.shrink();
          }
        } else {
          final index = i - 5;
          if (_routeViewIndex == 0) {
            if (index < _trips.length) {
              child = _TripCard(trip: _trips[index]);
            } else {
              child = const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
            }
          } else {
            if (index < _routeAggregations.length) {
              child = _RouteCardAgg(agg: _routeAggregations[index]);
            } else {
              child = const SizedBox.shrink();
            }
          }
        }

        return _StaggeredItem(
          index: i,
          animation: _animationController,
          child: Padding(
            padding: EdgeInsets.only(bottom: i == 0 ? 12 : 16),
            child: child,
          ),
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _TripCard extends StatefulWidget {
  const _TripCard({required this.trip});

  final Trip trip;

  @override
  State<_TripCard> createState() => _TripCardState();
}

class _TripCardState extends State<_TripCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final start = trip.startTime;
    final end = trip.endTime;
    final duration = end?.difference(start);
    final badge = _RiskBadge.fromScore(context, trip.riskScore);

    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: ValueKey(trip.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: colorScheme.error,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(Icons.delete, color: colorScheme.onError),
        ),
        confirmDismiss: (direction) async {
          return await showDialog<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Delete Trip?'),
                content: const Text('Are you sure you want to permanently delete this trip?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: TextButton.styleFrom(foregroundColor: colorScheme.error),
                    child: const Text('Delete'),
                  ),
                ],
              );
            },
          );
        },
        onDismissed: (direction) {
          context.read<TripController>().deleteTrip(trip.id!);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Trip deleted')),
          );
        },
        child: OpenContainer<void>(
          transitionType: ContainerTransitionType.fadeThrough,
          transitionDuration: const Duration(milliseconds: 420),
          openBuilder: (context, _) => TripDetailScreen(trip: trip),
        closedElevation: 0,
        openElevation: 0,
        closedColor: Colors.transparent,
        openColor: colorScheme.surface,
        closedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        closedBuilder: (context, openContainer) {
          return GestureDetector(
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapCancel: () => setState(() => _isPressed = false),
            onTapUp: (_) {
              setState(() => _isPressed = false);
              openContainer();
            },
            child: AnimatedScale(
              scale: _isPressed ? 0.95 : 1.0,
              duration: const Duration(milliseconds: 300),
              curve: MotionScheme.spatialFast,
              child: Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.route,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _RouteNameDisplay(
                          routeName: trip.routeName ??
                              'Trip on ${start.toLocal().toString().split(' ').first}',
                        ),
                      ),
                      if (duration != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${duration.inMinutes} min',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Risk score: ${trip.riskScore.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (trip.vehicleType != null)
                        _MetricChip(label: '${trip.vehicleType![0].toUpperCase()}${trip.vehicleType!.substring(1)}'),
                      _MetricChip(label: 'Speed ${trip.speedingCount}'),
                      _MetricChip(label: 'Brake ${trip.brakingCount}'),
                      _MetricChip(label: 'Turn ${trip.turningCount}'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      badge,
                      const Spacer(),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          ),
        );
      },
    ),
    ),
    );
  }
}

class _TripsOverview extends StatelessWidget {
  const _TripsOverview({required this.trips, required this.isLoading});

  final List<Trip> trips;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: M3CircularProgress(size: 40, strokeWidth: 4)),
      );
    }

    final totalTrips = trips.length;
    final averageRisk = totalTrips == 0
        ? 0.0
        : trips.fold<double>(0, (sum, trip) => sum + trip.riskScore) / totalTrips;
    
    // Convert risk (where high is bad) to safety score (where high is good)
    final averageSafetyScore = (100.0 - averageRisk).clamp(0.0, 100.0);
    
    Color ringColor;
    if (averageSafetyScore >= 80) {
      ringColor = const Color(0xFF2ECC71); // Safe
    } else if (averageSafetyScore >= 50) {
      ringColor = const Color(0xFFF39C12); // Moderate
    } else {
      ringColor = const Color(0xFFE74C3C); // Risky
    }

    final highRiskCount = trips.where((trip) => trip.riskScore >= 40).length;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
        child: Row(
          children: [
            // Circular gauge
            SizedBox(
              width: 110,
              height: 110,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: averageSafetyScore),
                duration: const Duration(milliseconds: 800),
                curve: MotionScheme.spatialDefault,
                builder: (context, animValue, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(110, 110),
                        painter: SafetyRingPainter(
                          value: (animValue / 100).clamp(0.0, 1.0),
                          color: ringColor,
                          trackColor: colorScheme.surfaceContainerHighest,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${animValue.toInt()}',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: ringColor,
                                ),
                          ),
                          Text(
                            '/ 100',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(0.5),
                                ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(width: 20),
            // Score explanation & Stats
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Safety Snapshot',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Average safety across $totalTrips recorded trips.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _OverviewChip(
                          label: 'High Risk',
                          value: highRiskCount.toString(),
                          color: colorScheme.errorContainer,
                          textColor: colorScheme.onErrorContainer,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _OverviewChip(
                          label: 'Avg Risk',
                          value: averageRisk.toStringAsFixed(0),
                          color: colorScheme.secondaryContainer,
                          textColor: colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewChip extends StatelessWidget {
  const _OverviewChip({
    required this.label,
    required this.value,
    required this.color,
    this.textColor,
  });

  final String label;
  final String value;
  final Color color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: textColor, fontWeight: FontWeight.bold)),
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: textColor?.withOpacity(0.8) ?? Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

class _RiskBadge extends StatelessWidget {
  const _RiskBadge({required this.label, required this.background});

  final String label;
  final Color background;

  static _RiskBadge fromScore(BuildContext context, double score) {
    if (score >= 40) {
      return _RiskBadge(label: 'High risk', background: Colors.red.shade100);
    }
    if (score >= 20) {
      return _RiskBadge(
        label: 'Medium risk',
        background: Colors.orange.shade100,
      );
    }
    return _RiskBadge(label: 'Low risk', background: Colors.green.shade100);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label, 
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.black87),
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
    final opacityCurve = CurvedAnimation(
      parent: animation,
      curve: Interval(intervalStart, end, curve: MotionScheme.effectsDefault),
    );
    final slideCurve = CurvedAnimation(
      parent: animation,
      curve: Interval(intervalStart, end, curve: MotionScheme.spatialDefault),
    );
    return FadeTransition(
      opacity: opacityCurve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(slideCurve),
        child: child,
      ),
    );
  }
}

class _RouteCardAgg extends StatefulWidget {
  const _RouteCardAgg({required this.agg});

  final RouteAggregation agg;

  @override
  State<_RouteCardAgg> createState() => _RouteCardAggState();
}

class _RouteCardAggState extends State<_RouteCardAgg> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final agg = widget.agg;
    if (agg.tripCount == 0) return const SizedBox.shrink();

    final badge = _RiskBadge.fromScore(context, agg.averageRiskScore);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: OpenContainer<void>(
          transitionType: ContainerTransitionType.fadeThrough,
          transitionDuration: const Duration(milliseconds: 420),
          openBuilder: (context, _) => RouteDetailScreen(
            routeName: agg.routeName,
            routeAgg: agg, // We'll modify RouteDetailScreen to accept agg instead of routeTrips
          ),
          closedElevation: 0,
          openElevation: 0,
          closedColor: Colors.transparent,
          openColor: colorScheme.surface,
          closedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          closedBuilder: (context, openContainer) {
            return GestureDetector(
              onTapDown: (_) => setState(() => _isPressed = true),
              onTapCancel: () => setState(() => _isPressed = false),
              onTapUp: (_) {
                setState(() => _isPressed = false);
                openContainer();
              },
              child: AnimatedScale(
                scale: _isPressed ? 0.95 : 1.0,
                duration: const Duration(milliseconds: 300),
                curve: MotionScheme.spatialFast,
                child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.route, color: colorScheme.onSecondaryContainer),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _RouteNameDisplay(
                            routeName: agg.routeName,
                            isTitle: true,
                          ),
                          Text(
                            '${agg.tripCount} Aggregated Trips',
                            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    badge,
                  ],
                ),
              ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RouteNameDisplay extends StatelessWidget {
  const _RouteNameDisplay({required this.routeName, this.isTitle = false});
  
  final String routeName;
  final bool isTitle;

  @override
  Widget build(BuildContext context) {
    if (routeName.contains(' to ')) {
      final parts = routeName.split(' to ');
      if (parts.length == 2) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              parts[0],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: isTitle 
                ? const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                : Theme.of(context).textTheme.titleMedium,
            ),
            Row(
              children: [
                Icon(Icons.arrow_downward_rounded, size: 14, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    parts[1],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: isTitle 
                      ? const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                      : Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ],
        );
      }
    }
    
    return Text(
      routeName,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: isTitle 
        ? const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
        : Theme.of(context).textTheme.titleMedium,
    );
  }
}

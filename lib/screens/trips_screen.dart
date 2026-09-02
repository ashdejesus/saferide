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

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late Future<List<Trip>> _tripsFuture;
  late final AnimationController _animationController;
  int _lastTripHistoryVersion = -1;
  bool _initialized = false;
  int _routeViewIndex = 0;

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
    final tripController = context.watch<TripController>();
    if (!_initialized) {
      final database = context.read<AppDatabase>();
      _tripsFuture = database.getTrips();
      _lastTripHistoryVersion = tripController.tripHistoryVersion;
      _initialized = true;
    } else if (_lastTripHistoryVersion != tripController.tripHistoryVersion) {
      final database = context.read<AppDatabase>();
      _tripsFuture = database.getTrips();
      _lastTripHistoryVersion = tripController.tripHistoryVersion;
    }

    return FutureBuilder<List<Trip>>(
      future: _tripsFuture,
      builder: (context, snapshot) {
        final trips = snapshot.data ?? [];
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        final Map<String, List<Trip>> routesMap = {};
        for (var t in trips) {
          if (t.routeName != null && t.routeName!.trim().isNotEmpty) {
            routesMap.putIfAbsent(t.routeName!.trim(), () => []).add(t);
          }
        }

        final items = <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              SectionHeader(title: 'Trip Summary'),
              SyncButton(),
            ],
          ),
          _TripsOverview(trips: trips, isLoading: isLoading),
          const SizedBox(height: 16),
            Center(
              child: Wrap(
                spacing: 12,
                children: [
                  FilterChip(
                    label: const Text('Individual Trips'),
                    selected: _routeViewIndex == 0,
                    onSelected: (val) => setState(() => _routeViewIndex = 0),
                  ),
                  FilterChip(
                    label: const Text('By Route'),
                    selected: _routeViewIndex == 1,
                    onSelected: (val) => setState(() => _routeViewIndex = 1),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          if (!isLoading && trips.isEmpty)
            EmptyState(
              icon: Icons.route,
              title: 'No trips yet',
              message:
                  'Start recording a trip to generate your first safety summary.',
              ctaLabel: 'Start Trip',
              onCtaPressed: () => TripActionSheet.show(context),
            ),
          if (trips.isNotEmpty && _routeViewIndex == 0)
            ...trips.map((trip) => _TripCard(trip: trip)),
          if (trips.isNotEmpty && _routeViewIndex == 1 && routesMap.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('No named routes found. Add a route name when completing a trip!'),
            ),
          if (trips.isNotEmpty && _routeViewIndex == 1)
            ...routesMap.entries.map((e) => _RouteCard(routeName: e.key, routeTrips: e.value)),
          const SizedBox(height: 80),
        ];

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: items.length,
          itemBuilder: (context, i) {
            return _StaggeredItem(
              index: i,
              animation: _animationController,
              child: Padding(
                padding: EdgeInsets.only(bottom: i == 0 ? 12 : 16),
                child: items[i],
              ),
            );
          },
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final start = trip.startTime;
    final end = trip.endTime;
    final duration = end?.difference(start);
    final badge = _RiskBadge.fromScore(context, trip.riskScore);

    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
          return Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              onTap: openContainer,
              borderRadius: BorderRadius.circular(16),
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
                        child: Text(
                          trip.routeName ??
                              'Trip on ${start.toLocal().toString().split(' ').first}',
                          style: Theme.of(context).textTheme.titleMedium,
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
        );
      },
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
        ? 0
        : trips.fold<double>(0, (sum, trip) => sum + trip.riskScore) /
              totalTrips;
    final highRiskCount = trips.where((trip) => trip.riskScore >= 40).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your safety snapshot',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _OverviewChip(
                    label: 'Trips',
                    value: totalTrips.toString(),
                    color: colorScheme.primaryContainer,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _OverviewChip(
                    label: 'Avg Risk',
                    value: averageRisk.toStringAsFixed(0),
                    color: colorScheme.secondaryContainer,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _OverviewChip(
                    label: 'High Risk',
                    value: highRiskCount.toString(),
                    color: colorScheme.tertiaryContainer,
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

class _OverviewChip extends StatelessWidget {
  const _OverviewChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: Theme.of(context).textTheme.titleMedium),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
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
    final scheme = Theme.of(context).colorScheme;
    if (score >= 40) {
      return _RiskBadge(label: 'High risk', background: scheme.errorContainer);
    }
    if (score >= 20) {
      return _RiskBadge(
        label: 'Medium risk',
        background: scheme.tertiaryContainer,
      );
    }
    return _RiskBadge(label: 'Low risk', background: scheme.secondaryContainer);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
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

class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.routeName, required this.routeTrips});

  final String routeName;
  final List<Trip> routeTrips;

  @override
  Widget build(BuildContext context) {
    if (routeTrips.isEmpty) return const SizedBox.shrink();

    final avgScore = routeTrips.fold(0.0, (sum, t) => sum + t.riskScore) / routeTrips.length;
    final badge = _RiskBadge.fromScore(context, avgScore);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                        Text(
                          routeName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          '${routeTrips.length} Aggregated Trips',
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Route Safety Score:', style: Theme.of(context).textTheme.titleSmall),
                  badge,
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


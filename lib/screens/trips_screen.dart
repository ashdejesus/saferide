import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_database.dart';
import '../models/trip.dart';
import '../widgets/empty_state.dart';
import '../widgets/section_header.dart';
import '../widgets/trip_action_sheet.dart';
import 'trip_detail_screen.dart';

class TripsScreen extends StatelessWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final database = context.read<AppDatabase>();

    return FutureBuilder<List<Trip>>(
      future: database.getTrips(),
      builder: (context, snapshot) {
        final trips = snapshot.data ?? [];
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SectionHeader(title: 'Trip Summary'),
            const SizedBox(height: 12),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator()),
            if (snapshot.connectionState != ConnectionState.waiting &&
                trips.isEmpty)
              EmptyState(
                icon: Icons.route,
                title: 'No trips yet',
                message:
                    'Start recording a trip to generate your first safety summary.',
                ctaLabel: 'Start Trip',
                onCtaPressed: () => TripActionSheet.show(context),
              ),
            if (trips.isNotEmpty) ...trips.map((trip) => _TripCard(trip: trip)),
          ],
        );
      },
    );
  }
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => TripDetailScreen(trip: trip),
            ),
          );
        },
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
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
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${duration.inMinutes} min',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Risk score: ${trip.riskScore.toStringAsFixed(0)} • '
                'Speeding ${trip.speedingCount} • Brake ${trip.brakingCount} • Turn ${trip.turningCount}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  badge,
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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

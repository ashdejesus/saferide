import 'package:flutter/material.dart';
import '../models/trip.dart';
import 'trip_detail_screen.dart';

class RouteDetailScreen extends StatelessWidget {
  const RouteDetailScreen({
    super.key,
    required this.routeName,
    required this.routeTrips,
  });

  final String routeName;
  final List<Trip> routeTrips;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final avgScore = routeTrips.fold(0.0, (sum, t) => sum + t.riskScore) / routeTrips.length;
    final totalSpeeding = routeTrips.fold(0, (sum, t) => sum + t.speedingCount);
    final totalBraking = routeTrips.fold(0, (sum, t) => sum + t.brakingCount);
    final totalTurning = routeTrips.fold(0, (sum, t) => sum + t.turningCount);
    String riskLabel = 'Low risk';
    Color riskColor = Colors.green.shade100;
    Color riskTextColor = Colors.black87; // Dark text for the light pastel background
    
    if (avgScore >= 40) {
      riskLabel = 'High risk';
      riskColor = Colors.red.shade100;
    } else if (avgScore >= 20) {
      riskLabel = 'Medium risk';
      riskColor = Colors.orange.shade100;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Summary'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.route, color: colorScheme.onSecondaryContainer, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        routeName,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Based on ${routeTrips.length} trips',
                        style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Average Score Card
            Card(
              elevation: 0,
              color: riskColor,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Average Safety Score',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: riskTextColor),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          riskLabel.toUpperCase(),
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: riskTextColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      avgScore.toStringAsFixed(0),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: riskTextColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Hazard Breakdown
            Text(
              'Total Hazard Breakdown',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            
            _StatRow(
              icon: Icons.speed,
              label: 'Speeding Incidents',
              value: totalSpeeding.toString(),
            ),
            const Divider(),
            _StatRow(
              icon: Icons.car_crash,
              label: 'Harsh Braking',
              value: totalBraking.toString(),
            ),
            const Divider(),
            _StatRow(
              icon: Icons.turn_right,
              label: 'Sharp Turns',
              value: totalTurning.toString(),
            ),
            
            const SizedBox(height: 40),
            Text(
              'History on this Route',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ...routeTrips.map((trip) {
              Color badgeColor;
              String badgeLabel;
              if (trip.riskScore >= 40) {
                badgeColor = Colors.red.shade100;
                badgeLabel = 'High risk';
              } else if (trip.riskScore >= 20) {
                badgeColor = Colors.orange.shade100;
                badgeLabel = 'Medium risk';
              } else {
                badgeColor = Colors.green.shade100;
                badgeLabel = 'Low risk';
              }

              return ListTile(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => TripDetailScreen(trip: trip)),
                  );
                },
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(Icons.history, color: colorScheme.onPrimaryContainer),
                ),
                title: Text(trip.startTime.toLocal().toString().split('.')[0]),
                subtitle: Text('Score: ${trip.riskScore.toStringAsFixed(0)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        badgeLabel,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.black87),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.primary),
          const SizedBox(width: 16),
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/trip.dart';
import '../services/passenger_reporting_service.dart';
import '../widgets/section_header.dart';
class TripDetailScreen extends StatelessWidget {
  const TripDetailScreen({super.key, required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final duration = trip.endTime?.difference(trip.startTime);
    final routePoints = trip.routePoints
        .map((point) => LatLng(point['lat']!, point['lng']!))
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(trip.routeName ?? 'Trip Details')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Risk Score Card
          Card(
            color: _getRiskColor(trip.riskScore, colorScheme),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text('Risk Score', style: textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    trip.riskScore.toStringAsFixed(0),
                    style: textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getRiskLabel(trip.riskScore),
                    style: textTheme.titleSmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Low (<20)', Colors.green.shade100, textTheme),
              const SizedBox(width: 12),
              _buildLegendItem('Medium (20-39)', Colors.orange.shade100, textTheme),
              const SizedBox(width: 12),
              _buildLegendItem('High (≥40)', Colors.red.shade100, textTheme),
            ],
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Trip Information'),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  if (trip.vehicleType != null) ...[
                    _InfoRow(
                      icon: Icons.directions_car,
                      label: 'Vehicle',
                      value: '${trip.vehicleType![0].toUpperCase()}${trip.vehicleType!.substring(1)}',
                    ),
                    const SizedBox(height: 12),
                  ],
                  _InfoRow(
                    icon: Icons.access_time,
                    label: 'Duration',
                    value: duration != null
                        ? '${duration.inMinutes} minutes'
                        : 'In progress',
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.calendar_today,
                    label: 'Date',
                    value: _formatDate(trip.startTime),
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.schedule,
                    label: 'Time',
                    value:
                        '${_formatTime(trip.startTime)} - ${trip.endTime != null ? _formatTime(trip.endTime!) : 'Ongoing'}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Safety Events'),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _EventRow(
                    icon: Icons.speed,
                    label: 'Speeding Incidents',
                    count: trip.speedingCount,
                    color: colorScheme.error,
                  ),
                  const SizedBox(height: 12),
                  _EventRow(
                    icon: Icons.warning_amber,
                    label: 'Harsh Braking',
                    count: trip.brakingCount,
                    color: colorScheme.tertiary,
                  ),
                  const SizedBox(height: 12),
                  _EventRow(
                    icon: Icons.turn_right,
                    label: 'Sharp Turns',
                    count: trip.turningCount,
                    color: colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Route Map'),
          const SizedBox(height: 12),
          SizedBox(
            height: 300,
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: routePoints.isEmpty
                  ? Center(
                      child: Text(
                        'No route data available',
                        style: textTheme.bodyMedium,
                      ),
                    )
                  : FlutterMap(
                      options: MapOptions(
                        initialCenter: routePoints.first,
                        initialZoom: 13,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: Theme.of(context).brightness == Brightness.dark
                              ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
                              : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                          subdomains: const ['a', 'b', 'c', 'd'],
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
                            if (routePoints.isNotEmpty)
                              Marker(
                                point: routePoints.first,
                                width: 40,
                                height: 40,
                                child: Icon(
                                  Icons.location_on,
                                  color: colorScheme.tertiary,
                                  size: 36,
                                ),
                              ),
                            if (routePoints.length > 1)
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, TextTheme textTheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.withValues(alpha: 0.5)),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: textTheme.bodySmall),
      ],
    );
  }

  Color _getRiskColor(double score, ColorScheme colorScheme) {
    if (score >= 40) return Colors.red.shade100;
    if (score >= 20) return Colors.orange.shade100;
    return Colors.green.shade100;
  }

  String _getRiskLabel(double score) {
    if (score >= 40) return 'High Risk';
    if (score >= 20) return 'Medium Risk';
    return 'Low Risk';
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(icon, color: colorScheme.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: textTheme.bodyMedium)),
        Text(
          value,
          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  final IconData icon;
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: textTheme.bodyMedium)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            count.toString(),
            style: textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

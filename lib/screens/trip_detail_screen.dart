import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/trip.dart';
import '../services/passenger_reporting_service.dart';
import '../widgets/section_header.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
class TripDetailScreen extends StatefulWidget {
  const TripDetailScreen({super.key, required this.trip});

  final Trip trip;

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final duration = widget.trip.endTime?.difference(widget.trip.startTime);
    final routePoints = widget.trip.routePoints
        .map((point) => LatLng(point['lat']!, point['lng']!))
        .toList();

    final apiKey = dotenv.env['CARTO_API_KEY'] ?? '';
    final keyParam = apiKey.isNotEmpty ? '?key=$apiKey' : '';

    return Scaffold(
      appBar: AppBar(title: Text(widget.trip.routeName ?? 'Trip Details')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Risk Score Card
          Card(
            color: _getRiskColor(widget.trip.riskScore, colorScheme),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text('Risk Score', style: textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    widget.trip.riskScore.toStringAsFixed(0),
                    style: textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getRiskLabel(widget.trip.riskScore),
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
                  if (widget.trip.vehicleType != null) ...[
                    _InfoRow(
                      icon: Icons.directions_car,
                      label: 'Vehicle',
                      value: '${widget.trip.vehicleType![0].toUpperCase()}${widget.trip.vehicleType!.substring(1)}',
                    ),
                    const SizedBox(height: 12),
                  ],
                  _InfoRow(
                    icon: Icons.access_time,
                    label: 'Duration',
                    value: duration != null
                        ? _formatDuration(duration)
                        : 'In progress',
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.calendar_today,
                    label: 'Date',
                    value: _formatDate(widget.trip.startTime),
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.schedule,
                    label: 'Time',
                    value:
                        '${_formatTime(widget.trip.startTime)} - ${widget.trip.endTime != null ? _formatTime(widget.trip.endTime!) : 'Ongoing'}',
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
                    description: 'Exceeding safe speed limits',
                    count: widget.trip.speedingCount,
                    color: colorScheme.error,
                  ),
                  const SizedBox(height: 12),
                  _EventRow(
                    icon: Icons.warning_amber,
                    label: 'Harsh Braking',
                    description: 'Sudden decelerations indicating reckless driving',
                    count: widget.trip.brakingCount,
                    color: colorScheme.tertiary,
                  ),
                  const SizedBox(height: 12),
                  _EventRow(
                    icon: Icons.turn_right,
                    label: 'Sharp Turns',
                    description: 'Aggressive cornering or swerving',
                    count: widget.trip.turningCount,
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
                  : Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: routePoints.first,
                            initialZoom: 13,
                            initialCameraFit: routePoints.length > 1
                                ? CameraFit.bounds(
                                    bounds: LatLngBounds.fromPoints(routePoints),
                                    padding: const EdgeInsets.all(40),
                                  )
                                : null,
                          ),
                          children: [
                        TileLayer(
                          urlTemplate: Theme.of(context).brightness == Brightness.dark
                              ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png$keyParam'
                              : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png$keyParam',
                          subdomains: const ['a', 'b', 'c', 'd'],
                          userAgentPackageName: 'com.saferide.app',
                        ),
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 4000),
                          curve: Curves.easeInOut,
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          builder: (context, animValue, child) {
                            final pointCount = (routePoints.length * animValue).toInt();
                            final animatedPoints = routePoints.sublist(0, pointCount);

                            // Determine the ending color based on risk score
                            Color endColor = Colors.green;
                            if (widget.trip.riskScore >= 40) endColor = Colors.red;
                            else if (widget.trip.riskScore >= 20) endColor = Colors.orange;

                            return Stack(
                              children: [
                                PolylineLayer(
                                  polylines: [
                                    if (animatedPoints.length > 1)
                                      for (int i = 0; i < animatedPoints.length - 1; i++)
                                        Polyline(
                                          points: [animatedPoints[i], animatedPoints[i + 1]],
                                          strokeWidth: 6,
                                          strokeCap: StrokeCap.round,
                                          strokeJoin: StrokeJoin.round,
                                          color: Color.lerp(
                                            Colors.green,
                                            endColor,
                                            i / (animatedPoints.length - 1),
                                          ) ?? endColor,
                                        )
                                    else if (animatedPoints.isNotEmpty)
                                      Polyline(
                                        points: animatedPoints,
                                        strokeWidth: 6,
                                        strokeCap: StrokeCap.round,
                                        strokeJoin: StrokeJoin.round,
                                        color: Colors.green,
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
                                        child: const Icon(
                                          Icons.location_on,
                                          color: Colors.green,
                                          size: 36,
                                        ),
                                      ),
                                    if (animatedPoints.length == routePoints.length && routePoints.length > 1)
                                      Marker(
                                        point: routePoints.last,
                                        width: 40,
                                        height: 40,
                                        child: Icon(
                                          Icons.flag,
                                          color: endColor,
                                          size: 36,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                    if (routePoints.isNotEmpty)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Column(
                          children: [
                            FloatingActionButton.small(
                              heroTag: 'trip_detail_my_location',
                              backgroundColor: colorScheme.surface,
                              foregroundColor: colorScheme.primary,
                              onPressed: () {
                                if (routePoints.length > 1) {
                                  _mapController.move(routePoints.first, _mapController.camera.zoom);
                                }
                              },
                              child: const Icon(Icons.my_location),
                            ),
                            const SizedBox(height: 8),
                            FloatingActionButton.small(
                              heroTag: 'trip_detail_zoom_in',
                              backgroundColor: colorScheme.surface,
                              foregroundColor: colorScheme.primary,
                              onPressed: () {
                                _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1);
                              },
                              child: const Icon(Icons.add),
                            ),
                            const SizedBox(height: 8),
                            FloatingActionButton.small(
                              heroTag: 'trip_detail_zoom_out',
                              backgroundColor: colorScheme.surface,
                              foregroundColor: colorScheme.primary,
                              onPressed: () {
                                _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1);
                              },
                              child: const Icon(Icons.remove),
                            ),
                          ],
                        ),
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
    int hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final amPm = hour >= 12 ? 'PM' : 'AM';
    
    if (hour == 0) {
      hour = 12;
    } else if (hour > 12) {
      hour -= 12;
    }
    
    return '$hour:$minute $amPm';
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes < 60) {
      return '${duration.inMinutes} mins';
    } else {
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      return '${hours}h ${minutes}m';
    }
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
    required this.description,
    required this.count,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String description;
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(
                description,
                style: textTheme.bodySmall?.copyWith(color: textTheme.bodySmall?.color?.withValues(alpha: 0.7)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
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

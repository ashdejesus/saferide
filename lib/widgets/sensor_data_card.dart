import 'package:flutter/material.dart';

class SensorDataCard extends StatelessWidget {
  const SensorDataCard({
    super.key,
    required this.acceleration,
    required this.averageAcceleration,
    required this.turnRate,
  });

  final double acceleration;
  final double averageAcceleration;
  final double turnRate;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surfaceContainerHighest,
              colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.sensors,
                      color: colorScheme.onPrimaryContainer,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Live Sensor Data',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SensorReading(
                icon: Icons.speed,
                label: 'Acceleration',
                value: '${acceleration.toStringAsFixed(2)} m/s²',
                color: _getAccelColor(acceleration, colorScheme),
              ),
              const SizedBox(height: 12),
              _SensorReading(
                icon: Icons.trending_up,
                label: 'Avg Acceleration',
                value: '${averageAcceleration.toStringAsFixed(2)} m/s²',
                color: _getAccelColor(averageAcceleration, colorScheme),
              ),
              const SizedBox(height: 12),
              _SensorReading(
                icon: Icons.rotate_right,
                label: 'Turn Rate',
                value: '${turnRate.toStringAsFixed(2)} rad/s',
                color: _getTurnColor(turnRate, colorScheme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getAccelColor(double value, ColorScheme colorScheme) {
    if (value > 3.5) {
      return colorScheme.error;
    } else if (value > 2.5) {
      return colorScheme.tertiary;
    } else {
      return colorScheme.primary;
    }
  }

  Color _getTurnColor(double value, ColorScheme colorScheme) {
    if (value > 2.5) {
      return colorScheme.error;
    } else if (value > 1.5) {
      return colorScheme.tertiary;
    } else {
      return colorScheme.primary;
    }
  }
}

class _SensorReading extends StatelessWidget {
  const _SensorReading({
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
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              Text(
                value,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

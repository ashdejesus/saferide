import 'package:flutter/material.dart';

class TripMiniHud extends StatelessWidget {
  const TripMiniHud({
    super.key,
    required this.speed,
    required this.speedingCount,
    required this.brakingCount,
    required this.turningCount,
  });

  final double speed;
  final int speedingCount;
  final int brakingCount;
  final int turningCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.speed, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              '${speed.toStringAsFixed(1)} m/s',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(width: 16),
            _HudStat(label: 'S', value: speedingCount),
            const SizedBox(width: 8),
            _HudStat(label: 'B', value: brakingCount),
            const SizedBox(width: 8),
            _HudStat(label: 'T', value: turningCount),
          ],
        ),
      ),
    );
  }
}

class _HudStat extends StatelessWidget {
  const _HudStat({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label $value',
        style: Theme.of(context).textTheme.labelMedium,
      ),
    );
  }
}

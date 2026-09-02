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
    final speedKmh = speed * 3.6;
    final isHighSpeed = speedKmh > 40;
    
    return Card(
      elevation: 8,
      shadowColor: isHighSpeed
          ? colorScheme.error.withValues(alpha: 0.4)
          : Colors.black.withValues(alpha: 0.2),
      color: colorScheme.surfaceContainerHighest,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: isHighSpeed
              ? Border.all(
                  color: colorScheme.error.withValues(alpha: 0.3),
                  width: 2,
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.speed,
                  color: isHighSpeed ? colorScheme.error : colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${speedKmh.toStringAsFixed(1)} km/h',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: isHighSpeed ? colorScheme.error : null,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (isHighSpeed)
                      Text(
                        'High Speed',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: colorScheme.error,
                            ),
                      ),
                  ],
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

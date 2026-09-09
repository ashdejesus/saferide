import 'package:flutter/material.dart';
import '../theme/motion_scheme.dart';

/// An M3 Expressive shape-shifting button group.
/// This widget mimics the "bumping and reacting" fluid motion introduced in M3 Expressive.
class M3ButtonGroup<T> extends StatelessWidget {
  const M3ButtonGroup({
    super.key,
    required this.segments,
    required this.selected,
    required this.onSelectionChanged,
    this.gap = 8.0,
  });

  final List<ButtonSegment<T>> segments;
  final Set<T> selected;
  final ValueChanged<Set<T>> onSelectionChanged;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalGap = gap * (segments.length - 1);
        final availableWidth = constraints.maxWidth - totalGap;
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: segments.map((segment) {
            final isSelected = selected.contains(segment.value);
            
            // Width calculations for the shape-shifting effect
            // We give the selected segment roughly 45% of the space,
            // and split the remaining 55% among the unselected ones.
            final numUnselected = segments.length - 1;
            final double selectedWidth = availableWidth * 0.45;
            final double unselectedWidth = numUnselected > 0 
                ? (availableWidth * 0.55) / numUnselected 
                : availableWidth;
            
            final targetWidth = isSelected ? selectedWidth : unselectedWidth;
            
            final colorScheme = Theme.of(context).colorScheme;
            final targetColor = isSelected 
                ? colorScheme.primaryContainer 
                : colorScheme.surfaceContainerHighest;
            
            final targetTextColor = isSelected
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurface;

            final targetRadius = isSelected ? 24.0 : 12.0;

            return GestureDetector(
              onTap: () {
                if (!isSelected) {
                  onSelectionChanged({segment.value});
                }
              },
              child: AnimatedContainer(
                // Use a spring-like curve for M3 Expressive motion
                duration: const Duration(milliseconds: 600),
                curve: MotionScheme.spatialDefault,
                width: targetWidth,
                height: 48, // More compact touch target height
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: targetColor,
                  borderRadius: BorderRadius.circular(targetRadius),
                ),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 400),
                  curve: MotionScheme.effectsDefault,
                  style: Theme.of(context).textTheme.labelMedium!.copyWith(
                    color: targetTextColor,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (segment.icon != null) ...[
                          Icon(
                            (segment.icon as Icon).icon,
                            color: targetTextColor,
                            size: 18,
                          ),
                          if (segment.label != null && isSelected) const SizedBox(width: 8),
                        ],
                        if (segment.label != null && (isSelected || segment.icon == null)) segment.label!,
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

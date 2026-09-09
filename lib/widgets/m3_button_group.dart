import 'package:flutter/material.dart';

import '../theme/motion_scheme.dart';
/// A clean M3-styled segmented button group.
///
/// Uses smooth color and shape transitions without the jarring shape-shifting
/// width animation. The selected segment gets a filled background; unselected
/// segments are outlined.
class M3ButtonGroup<T> extends StatelessWidget {
  const M3ButtonGroup({
    super.key,
    required this.segments,
    required this.selected,
    required this.onSelectionChanged,
    this.gap = 0.0,
  });

  final List<ButtonSegment<T>> segments;
  final Set<T> selected;
  final ValueChanged<Set<T>> onSelectionChanged;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          children: List.generate(segments.length * 2 - 1, (index) {
            // Odd indices are dividers
            if (index.isOdd) {
              final leftIdx = index ~/ 2;
              final rightIdx = leftIdx + 1;
              final leftSelected = selected.contains(segments[leftIdx].value);
              final rightSelected = selected.contains(segments[rightIdx].value);
              // Hide divider if either neighbor is selected
              if (leftSelected || rightSelected) {
                return const SizedBox.shrink();
              }
              return Container(
                width: 1,
                color: colorScheme.outlineVariant,
              );
            }

            final segmentIndex = index ~/ 2;
            final segment = segments[segmentIndex];
            final isSelected = selected.contains(segment.value);
            final isFirst = segmentIndex == 0;
            final isLast = segmentIndex == segments.length - 1;

            return Expanded(
              child: _SegmentTile<T>(
                segment: segment,
                isSelected: isSelected,
                isFirst: isFirst,
                isLast: isLast,
                colorScheme: colorScheme,
                onTap: () {
                  if (!isSelected) {
                    onSelectionChanged({segment.value});
                  }
                },
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _SegmentTile<T> extends StatelessWidget {
  const _SegmentTile({
    required this.segment,
    required this.isSelected,
    required this.isFirst,
    required this.isLast,
    required this.colorScheme,
    required this.onTap,
  });

  final ButtonSegment<T> segment;
  final bool isSelected;
  final bool isFirst;
  final bool isLast;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 800),
      curve: MotionScheme.spatialFast,
      decoration: BoxDecoration(
        color: isSelected
            ? colorScheme.secondaryContainer
            : Colors.transparent,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  Icon(
                    Icons.check,
                    size: 16,
                    color: colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 6),
                ],
                if (segment.icon != null && !isSelected) ...[
                  Icon(
                    (segment.icon as Icon).icon,
                    size: 18,
                    color: isSelected
                        ? colorScheme.onSecondaryContainer
                        : colorScheme.onSurfaceVariant,
                  ),
                  if (segment.label != null) const SizedBox(width: 6),
                ],
                if (segment.label != null)
                  Flexible(
                    child: DefaultTextStyle.merge(
                      style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        color: isSelected
                            ? colorScheme.onSecondaryContainer
                            : colorScheme.onSurfaceVariant,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                      child: segment.label!,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

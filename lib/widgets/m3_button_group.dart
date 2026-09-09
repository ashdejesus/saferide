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

class _SegmentTile<T> extends StatefulWidget {
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
  State<_SegmentTile<T>> createState() => _SegmentTileState<T>();
}

class _SegmentTileState<T> extends State<_SegmentTile<T>> {
  bool _isPressed = false;
  DateTime? _lastPressTime;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _lastPressTime = DateTime.now();
        setState(() => _isPressed = true);
      },
      onTapUp: (_) async {
        if (_lastPressTime != null) {
          final diff = DateTime.now().difference(_lastPressTime!);
          if (diff.inMilliseconds < 150) {
            await Future.delayed(Duration(milliseconds: 150 - diff.inMilliseconds));
          }
        }
        if (mounted) setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () {
        if (mounted) setState(() => _isPressed = false);
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 300),
        curve: MotionScheme.spatialFast,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 800),
          curve: MotionScheme.spatialFast,
          decoration: BoxDecoration(
            color: widget.isSelected
                ? widget.colorScheme.secondaryContainer
                : Colors.transparent,
          ),
          child: Material(
            color: Colors.transparent,
            child: IgnorePointer(
              ignoring: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.isSelected) ...[
                      Icon(
                        Icons.check,
                        size: 16,
                        color: widget.colorScheme.onSecondaryContainer,
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (widget.segment.icon != null && !widget.isSelected) ...[
                      Icon(
                        (widget.segment.icon as Icon).icon,
                        size: 18,
                        color: widget.isSelected
                            ? widget.colorScheme.onSecondaryContainer
                            : widget.colorScheme.onSurfaceVariant,
                      ),
                      if (widget.segment.label != null) const SizedBox(width: 6),
                    ],
                    if (widget.segment.label != null)
                      Flexible(
                        child: DefaultTextStyle.merge(
                          style: Theme.of(context).textTheme.labelLarge!.copyWith(
                            color: widget.isSelected
                                ? widget.colorScheme.onSecondaryContainer
                                : widget.colorScheme.onSurfaceVariant,
                            fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                          child: widget.segment.label!,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

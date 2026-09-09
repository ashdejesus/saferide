import 'package:flutter/material.dart';
import '../theme/motion_scheme.dart';

class M3SeveritySelector extends StatefulWidget {
  final double severity;
  final ValueChanged<double> onChanged;

  const M3SeveritySelector({
    super.key,
    required this.severity,
    required this.onChanged,
  });

  @override
  State<M3SeveritySelector> createState() => _M3SeveritySelectorState();
}

class _M3SeveritySelectorState extends State<M3SeveritySelector> {
  void _handleDrag(double localDx, double totalWidth) {
    // There are 5 zones. 
    // localDx / totalWidth gives us a percentage 0.0 to 1.0
    // Multiply by 5 gives us 0 to 5.
    // Clamp to 0..4 for the array index, then add 1 for the severity value.
    final percent = (localDx / totalWidth).clamp(0.0, 0.999);
    final index = (percent * 5).floor(); 
    final val = (index + 1).toDouble();
    
    if (val != widget.severity) {
      widget.onChanged(val);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        // 5 chips, 4 gaps of 8px = 32px total gap
        final chipSize = (availableWidth - 32) / 5;
        // Cap the height to avoid massive circles on wide screens
        final boundedSize = chipSize > 64.0 ? 64.0 : chipSize;

        // Wrap the entire row in a GestureDetector to allow dragging across it
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: (details) {
            _handleDrag(details.localPosition.dx, availableWidth);
          },
          onTapDown: (details) {
            _handleDrag(details.localPosition.dx, availableWidth);
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (index) {
              final val = index + 1;
              final isSelected = widget.severity.round() == val;
              
              // We pass the selection state down to the chip, which animates itself
              return _SeverityChip(
                value: val,
                isSelected: isSelected,
                size: boundedSize,
              );
            }),
          ),
        );
      }
    );
  }
}

class _SeverityChip extends StatefulWidget {
  final int value;
  final bool isSelected;
  final double size;

  const _SeverityChip({
    required this.value,
    required this.isSelected,
    required this.size,
  });

  @override
  State<_SeverityChip> createState() => _SeverityChipState();
}

class _SeverityChipState extends State<_SeverityChip> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _scale = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _ctrl, curve: MotionScheme.spatialFast),
    );
  }
  
  @override
  void didUpdateWidget(_SeverityChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      // Little bounce when selected via drag
      _ctrl.forward().then((_) => _ctrl.reverse());
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color _getContainerColor(int val, ColorScheme cs) {
    if (val >= 4) return cs.error;
    if (val == 3) return cs.tertiary; 
    return cs.primary; 
  }

  Color _getOnColor(int val, ColorScheme cs) {
    if (val >= 4) return cs.onError;
    if (val == 3) return cs.onTertiary;
    return cs.onPrimary;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final activeColor = _getContainerColor(widget.value, cs);
    final onColor = _getOnColor(widget.value, cs);
    
    return ScaleTransition(
      scale: _scale,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: MotionScheme.spatialDefault,
        width: widget.size,
        height: widget.size, 
        decoration: BoxDecoration(
          color: widget.isSelected ? activeColor : cs.surfaceContainerHighest,
          // Morphs from a rounded square to a perfect circle when selected
          // Clamp to ensure spring overshoot doesn't cause a negative radius (which throws in painting.dart)
          borderRadius: BorderRadius.circular(
            (widget.isSelected ? widget.size / 2 : 12.0).clamp(0.0, 999.0)
          ),
          boxShadow: widget.isSelected ? [
            BoxShadow(
              color: activeColor.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ] : [],
          border: Border.all(
            color: widget.isSelected ? activeColor : cs.outlineVariant.withOpacity(0.5),
            width: widget.isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: widget.isSelected ? 20 : 16,
              fontWeight: widget.isSelected ? FontWeight.w900 : FontWeight.w500,
              color: widget.isSelected ? onColor : cs.onSurfaceVariant,
            ),
            child: Text(widget.value.toString()),
          ),
        ),
      ),
    );
  }
}

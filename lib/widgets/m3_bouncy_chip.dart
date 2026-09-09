import 'package:flutter/material.dart';
import '../theme/motion_scheme.dart';

class M3BouncyChip extends StatefulWidget {
  const M3BouncyChip({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });
  
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<M3BouncyChip> createState() => _M3BouncyChipState();
}

class _M3BouncyChipState extends State<M3BouncyChip> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _scale = Tween<double>(begin: 1.0, end: 0.90).animate(
      CurvedAnimation(parent: _ctrl, curve: MotionScheme.spatialFast),
    );
  }

  @override
  void dispose() { 
    _ctrl.dispose(); 
    super.dispose(); 
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300), // Adjusted from 800 for color transition
          curve: Curves.easeOut, // Safe curve for colors
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isSelected ? cs.primaryContainer : cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(widget.isSelected ? 20 : 12),
            border: Border.all(
              color: widget.isSelected ? cs.primary : cs.outlineVariant,
              width: widget.isSelected ? 2 : 1,
            ),
            boxShadow: widget.isSelected ? [
              BoxShadow(color: cs.primary.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 4)),
            ] : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 16,
                color: widget.isSelected ? cs.onPrimaryContainer : cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(widget.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: widget.isSelected ? cs.onPrimaryContainer : cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

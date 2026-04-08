import 'package:flutter/material.dart';

/// M3 Expressive linear progress indicator with optional wavy animation
class M3LinearProgress extends StatelessWidget {
  const M3LinearProgress({
    super.key,
    this.value,
    this.wavy = false,
    this.showStopIndicator = true,
    this.minHeight = 4.0,
  });

  final double? value;
  final bool wavy;
  final bool showStopIndicator;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final height = wavy ? minHeight + 4 : minHeight;

    return SizedBox(
      height: height,
      child: Stack(
        children: [
          // Track
          Container(
            height: minHeight,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(minHeight / 2),
            ),
          ),
          // Active indicator
          if (value != null)
            FractionallySizedBox(
              widthFactor: value!.clamp(0.0, 1.0),
              child: wavy
                  ? _WavyProgress(color: colorScheme.primary, height: height)
                  : Container(
                      height: minHeight,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(minHeight / 2),
                      ),
                    ),
            )
          else
            // Indeterminate
            _IndeterminateProgress(
              color: colorScheme.primary,
              height: minHeight,
              wavy: wavy,
            ),
          // Stop indicator (for determinate only)
          if (value != null && showStopIndicator && value! > 0.0)
            Positioned(
              left: (value! * MediaQuery.of(context).size.width).clamp(
                4.0,
                MediaQuery.of(context).size.width - 4,
              ),
              top: (height - 4) / 2,
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _WavyProgress extends StatefulWidget {
  const _WavyProgress({required this.color, required this.height});

  final Color color;
  final double height;

  @override
  State<_WavyProgress> createState() => _WavyProgressState();
}

class _WavyProgressState extends State<_WavyProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(double.infinity, widget.height),
          painter: _WavyPainter(
            color: widget.color,
            animationValue: _controller.value,
          ),
        );
      },
    );
  }
}

class _WavyPainter extends CustomPainter {
  _WavyPainter({required this.color, required this.animationValue});

  final Color color;
  final double animationValue;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final waveHeight = size.height * 0.3;

    path.moveTo(0, size.height / 2);

    for (double x = 0; x <= size.width; x += 0.5) {
      final y =
          size.height / 2 +
          waveHeight *
              (animationValue * 2 - 1) *
              (x / size.width).clamp(0.0, 1.0);
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavyPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}

class _IndeterminateProgress extends StatefulWidget {
  const _IndeterminateProgress({
    required this.color,
    required this.height,
    required this.wavy,
  });

  final Color color;
  final double height;
  final bool wavy;

  @override
  State<_IndeterminateProgress> createState() => _IndeterminateProgressState();
}

class _IndeterminateProgressState extends State<_IndeterminateProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final segmentWidth = width * 0.3;
            final position = _controller.value * (width + segmentWidth);

            return Stack(
              children: [
                Positioned(
                  left: position - segmentWidth,
                  child: Container(
                    width: segmentWidth,
                    height: widget.height,
                    decoration: BoxDecoration(
                      color: widget.color,
                      borderRadius: BorderRadius.circular(widget.height / 2),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// M3 Expressive circular progress indicator
class M3CircularProgress extends StatelessWidget {
  const M3CircularProgress({
    super.key,
    this.value,
    this.size = 40,
    this.strokeWidth = 4,
    this.backgroundColor,
  });

  final double? value;
  final double size;
  final double strokeWidth;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        value: value,
        strokeWidth: strokeWidth,
        backgroundColor:
            backgroundColor ?? colorScheme.primary.withValues(alpha: 0.2),
        valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
      ),
    );
  }
}

/// Sync progress card with determinate/indeterminate states
class SyncProgressCard extends StatelessWidget {
  const SyncProgressCard({
    super.key,
    required this.isSyncing,
    this.progress,
    this.totalItems,
    this.syncedItems,
  });

  final bool isSyncing;
  final double? progress;
  final int? totalItems;
  final int? syncedItems;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (!isSyncing) {
      return const SizedBox.shrink();
    }

    final isDeterminate = progress != null && totalItems != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                M3CircularProgress(value: progress, size: 24, strokeWidth: 3),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Syncing data...',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      if (isDeterminate && syncedItems != null)
                        Text(
                          '$syncedItems of $totalItems items',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (progress != null) ...[
              const SizedBox(height: 12),
              M3LinearProgress(value: progress, wavy: true, minHeight: 6),
            ],
          ],
        ),
      ),
    );
  }
}

/// Button with integrated progress indicator
class ProgressButton extends StatelessWidget {
  const ProgressButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.size = ButtonSize.medium,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final ButtonSize size;

  @override
  Widget build(BuildContext context) {
    final progressSize = _getProgressSize();

    if (isLoading) {
      return FilledButton.icon(
        onPressed: null,
        icon: M3CircularProgress(
          size: progressSize,
          strokeWidth: 2.5,
          backgroundColor: Colors.transparent,
        ),
        label: Text(label),
      );
    }

    if (icon != null) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      );
    }

    return FilledButton(onPressed: onPressed, child: Text(label));
  }

  double _getProgressSize() {
    switch (size) {
      case ButtonSize.small:
        return 16;
      case ButtonSize.medium:
        return 18;
      case ButtonSize.large:
        return 20;
    }
  }
}

enum ButtonSize { small, medium, large }

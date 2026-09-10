import 'dart:math';
import 'package:flutter/material.dart';

/// Circular arc safety score painter
class SafetyRingPainter extends CustomPainter {
  const SafetyRingPainter({
    required this.value,
    required this.color,
    required this.trackColor,
  });

  final double value; // 0.0–1.0
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = (size.shortestSide / 2) - 8;
    const strokeWidth = 12.0;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -pi / 2;
    const fullSweep = 2 * pi;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      startAngle,
      fullSweep,
      false,
      trackPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      startAngle,
      fullSweep * value,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(SafetyRingPainter old) =>
      old.value != value || old.color != color;
}

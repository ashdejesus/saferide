import 'dart:math' as math;
import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

/// A custom curve that perfectly mimics Jetpack Compose's Spring physics
/// allowing us to use M3 Expressive motion in Flutter implicitly.
class SpringCurve extends Curve {
  SpringCurve({
    this.dampingRatio = 0.6,
    this.stiffness = 700.0,
    this.mass = 1.0,
  }) {
    // damping = dampingRatio * 2 * sqrt(mass * stiffness)
    final damping = dampingRatio * 2 * math.sqrt(mass * stiffness);
    _sim = SpringSimulation(
      SpringDescription(
        mass: mass,
        stiffness: stiffness,
        damping: damping,
      ),
      0.0, // start
      1.0, // end
      0.0, // initial velocity
    );
  }

  final double dampingRatio;
  final double stiffness;
  final double mass;
  late final SpringSimulation _sim;

  @override
  double transformInternal(double t) {
    // A standard SpringSimulation computes x(time).
    // To map it to a Curve (which takes t from 0 to 1), we scale t by a constant.
    // By mapping to 1.2s we give the spring enough time to overshoot and bounce back
    // while keeping the movement feeling weighty and tactile.
    final time = t * 1.2; 
    return _sim.x(time);
  }
}

/// Pre-defined M3 Expressive Motion specs mapped from the Compose guidelines
class MotionScheme {
  // Spatial: movement, scale, rotation (Bouncy)
  // Lowered damping ratio (0.5) for a much more prominent, juicy bounce 
  // that you can truly "feel". Lower stiffness gives it more physical weight.
  static final Curve spatialDefault = SpringCurve(dampingRatio: 0.5, stiffness: 450.0);
  static final Curve spatialFast = SpringCurve(dampingRatio: 0.5, stiffness: 900.0);
  static final Curve spatialSlow = SpringCurve(dampingRatio: 0.5, stiffness: 250.0);

  // Effects: color, opacity (No Bounce)
  static final Curve effectsDefault = SpringCurve(dampingRatio: 1.0, stiffness: 1200.0);
  static final Curve effectsFast = SpringCurve(dampingRatio: 1.0, stiffness: 2400.0);
  static final Curve effectsSlow = SpringCurve(dampingRatio: 1.0, stiffness: 600.0);
}

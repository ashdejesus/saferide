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
    // To map it to a Curve (which takes t from 0 to 1), we scale t by a constant
    // representing the "settling duration" of the spring.
    // For stiffness=700, dampingRatio=0.6, the settling time is roughly 0.6s to 1s.
    // We'll map t (0 to 1) to time (0 to 1.5 seconds) to give the spring room to bounce.
    final time = t * 1.5; 
    return _sim.x(time);
  }
}

/// Pre-defined M3 Expressive Motion specs mapped from the Compose guidelines
class MotionScheme {
  // Spatial: movement, scale, rotation (Bouncy)
  static final Curve spatialDefault = SpringCurve(dampingRatio: 0.6, stiffness: 700.0);
  static final Curve spatialFast = SpringCurve(dampingRatio: 0.6, stiffness: 1400.0);
  static final Curve spatialSlow = SpringCurve(dampingRatio: 0.6, stiffness: 300.0);

  // Effects: color, opacity (No Bounce)
  static final Curve effectsDefault = SpringCurve(dampingRatio: 1.0, stiffness: 1600.0);
  static final Curve effectsFast = SpringCurve(dampingRatio: 1.0, stiffness: 3800.0);
  static final Curve effectsSlow = SpringCurve(dampingRatio: 1.0, stiffness: 800.0);
}

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

class SpringCurve extends Curve {
  /// A Curve that uses the Flutter Physics engine to drive realistic
  /// animations.
  ///
  /// Provides a critically damped spring by default, with an easily
  /// overrideable damping value.
  ///
  /// See also: [SpringCurve.custom], [SpringCurve.underDamped],
  /// [SpringCurve.criticallyDamped], [SpringCurve.overDamped]
  factory SpringCurve([double damping = 20]) =>
      SpringCurve.custom(damping: damping);

  /// Provides a critically damped spring by default, with an easily
  /// overrideable damping, stiffness and mass value.
  SpringCurve.custom({
    double damping = 20,
    double stiffness = 180,
    double mass = 1.0,
  }) : _sim = SpringSimulation(
          SpringDescription(
            damping: damping,
            mass: mass,
            stiffness: stiffness,
          ),
          0,
          1,
          0,
        );

  /// The underlying physics simulation.
  final SpringSimulation _sim;

  /// Provides an **under damped** spring, which wobbles loosely at the end.
  static Curve get underDamped => SpringCurve(12);

  /// Provides a **critically damped** spring, which overshoots
  /// once very slightly.
  static Curve get criticallyDamped => SpringCurve();

  /// Provides an **over damped** spring, which smoothly glides into place.
  static Curve get overDamped => SpringCurve(28);

  /// Returns the position from the simulator and corrects the final
  /// output `x(1.0)` for tight tolerances.
  @override
  double transform(double t) => _sim.x(t) + t * (1 - _sim.x(1));
}

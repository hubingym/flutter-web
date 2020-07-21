import 'dart:math' as math;

import 'simulation.dart';
import 'tolerance.dart';
import 'utils.dart';

class SpringDescription {
  const SpringDescription({this.mass, this.stiffness, this.damping});

  SpringDescription.withDampingRatio(
      {this.mass, this.stiffness, double ratio = 1.0})
      : damping = ratio * 2.0 * math.sqrt(mass * stiffness);

  final double mass;

  final double stiffness;

  final double damping;

  @override
  String toString() =>
      '$runtimeType(mass: ${mass.toStringAsFixed(1)}, stiffness: '
      '${stiffness.toStringAsFixed(1)}, damping: '
      '${damping.toStringAsFixed(1)})';
}

enum SpringType {
  criticallyDamped,

  underDamped,

  overDamped,
}

class SpringSimulation extends Simulation {
  SpringSimulation(
    SpringDescription spring,
    double start,
    double end,
    double velocity, {
    Tolerance tolerance = Tolerance.defaultTolerance,
  })  : _endPosition = end,
        _solution = new _SpringSolution(spring, start - end, velocity),
        super(tolerance: tolerance);

  final double _endPosition;
  final _SpringSolution _solution;

  SpringType get type => _solution.type;

  @override
  double x(double time) => _endPosition + _solution.x(time);

  @override
  double dx(double time) => _solution.dx(time);

  @override
  bool isDone(double time) {
    return nearZero(_solution.x(time), tolerance.distance) &&
        nearZero(_solution.dx(time), tolerance.velocity);
  }

  @override
  String toString() => '$runtimeType(end: $_endPosition, $type)';
}

class ScrollSpringSimulation extends SpringSimulation {
  ScrollSpringSimulation(
    SpringDescription spring,
    double start,
    double end,
    double velocity, {
    Tolerance tolerance = Tolerance.defaultTolerance,
  }) : super(spring, start, end, velocity, tolerance: tolerance);

  @override
  double x(double time) => isDone(time) ? _endPosition : super.x(time);
}

abstract class _SpringSolution {
  factory _SpringSolution(SpringDescription spring, double initialPosition,
      double initialVelocity) {
    assert(spring != null);
    assert(spring.mass != null);
    assert(spring.stiffness != null);
    assert(spring.damping != null);
    assert(initialPosition != null);
    assert(initialVelocity != null);
    final double cmk =
        spring.damping * spring.damping - 4 * spring.mass * spring.stiffness;
    if (cmk == 0.0)
      return new _CriticalSolution(spring, initialPosition, initialVelocity);
    if (cmk > 0.0)
      return new _OverdampedSolution(spring, initialPosition, initialVelocity);
    return new _UnderdampedSolution(spring, initialPosition, initialVelocity);
  }

  double x(double time);
  double dx(double time);
  SpringType get type;
}

class _CriticalSolution implements _SpringSolution {
  factory _CriticalSolution(
      SpringDescription spring, double distance, double velocity) {
    final double r = -spring.damping / (2.0 * spring.mass);
    final double c1 = distance;
    final double c2 = velocity / (r * distance);
    return new _CriticalSolution.withArgs(r, c1, c2);
  }

  _CriticalSolution.withArgs(double r, double c1, double c2)
      : _r = r,
        _c1 = c1,
        _c2 = c2;

  final double _r, _c1, _c2;

  @override
  double x(double time) {
    return (_c1 + _c2 * time) * math.pow(math.e, _r * time);
  }

  @override
  double dx(double time) {
    final double power = math.pow(math.e, _r * time);
    return _r * (_c1 + _c2 * time) * power + _c2 * power;
  }

  @override
  SpringType get type => SpringType.criticallyDamped;
}

class _OverdampedSolution implements _SpringSolution {
  factory _OverdampedSolution(
      SpringDescription spring, double distance, double velocity) {
    final double cmk =
        spring.damping * spring.damping - 4 * spring.mass * spring.stiffness;
    final double r1 = (-spring.damping - math.sqrt(cmk)) / (2.0 * spring.mass);
    final double r2 = (-spring.damping + math.sqrt(cmk)) / (2.0 * spring.mass);
    final double c2 = (velocity - r1 * distance) / (r2 - r1);
    final double c1 = distance - c2;
    return new _OverdampedSolution.withArgs(r1, r2, c1, c2);
  }

  _OverdampedSolution.withArgs(double r1, double r2, double c1, double c2)
      : _r1 = r1,
        _r2 = r2,
        _c1 = c1,
        _c2 = c2;

  final double _r1, _r2, _c1, _c2;

  @override
  double x(double time) {
    return _c1 * math.pow(math.e, _r1 * time) +
        _c2 * math.pow(math.e, _r2 * time);
  }

  @override
  double dx(double time) {
    return _c1 * _r1 * math.pow(math.e, _r1 * time) +
        _c2 * _r2 * math.pow(math.e, _r2 * time);
  }

  @override
  SpringType get type => SpringType.overDamped;
}

class _UnderdampedSolution implements _SpringSolution {
  factory _UnderdampedSolution(
      SpringDescription spring, double distance, double velocity) {
    final double w = math.sqrt(4.0 * spring.mass * spring.stiffness -
            spring.damping * spring.damping) /
        (2.0 * spring.mass);
    final double r = -(spring.damping / 2.0 * spring.mass);
    final double c1 = distance;
    final double c2 = (velocity - r * distance) / w;
    return new _UnderdampedSolution.withArgs(w, r, c1, c2);
  }

  _UnderdampedSolution.withArgs(double w, double r, double c1, double c2)
      : _w = w,
        _r = r,
        _c1 = c1,
        _c2 = c2;

  final double _w, _r, _c1, _c2;

  @override
  double x(double time) {
    return math.pow(math.e, _r * time) *
        (_c1 * math.cos(_w * time) + _c2 * math.sin(_w * time));
  }

  @override
  double dx(double time) {
    final double power = math.pow(math.e, _r * time);
    final double cosine = math.cos(_w * time);
    final double sine = math.sin(_w * time);
    return power * (_c2 * _w * cosine - _c1 * _w * sine) +
        _r * power * (_c2 * sine + _c1 * cosine);
  }

  @override
  SpringType get type => SpringType.underDamped;
}

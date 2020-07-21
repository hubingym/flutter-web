import 'dart:math' as math;

import 'simulation.dart';
import 'tolerance.dart';

class FrictionSimulation extends Simulation {
  FrictionSimulation(
    double drag,
    double position,
    double velocity, {
    Tolerance tolerance = Tolerance.defaultTolerance,
  })  : _drag = drag,
        _dragLog = math.log(drag),
        _x = position,
        _v = velocity,
        super(tolerance: tolerance);

  factory FrictionSimulation.through(double startPosition, double endPosition,
      double startVelocity, double endVelocity) {
    assert(startVelocity == 0.0 ||
        endVelocity == 0.0 ||
        startVelocity.sign == endVelocity.sign);
    assert(startVelocity.abs() >= endVelocity.abs());
    assert((endPosition - startPosition).sign == startVelocity.sign);
    return FrictionSimulation(
      _dragFor(startPosition, endPosition, startVelocity, endVelocity),
      startPosition,
      startVelocity,
      tolerance: Tolerance(velocity: endVelocity.abs()),
    );
  }

  final double _drag;
  final double _dragLog;
  final double _x;
  final double _v;

  static double _dragFor(double startPosition, double endPosition,
      double startVelocity, double endVelocity) {
    return math.pow(
        math.e, (startVelocity - endVelocity) / (startPosition - endPosition));
  }

  @override
  double x(double time) =>
      _x + _v * math.pow(_drag, time) / _dragLog - _v / _dragLog;

  @override
  double dx(double time) => _v * math.pow(_drag, time);

  double get finalX => _x - _v / _dragLog;

  double timeAtX(double x) {
    if (x == _x) return 0.0;
    if (_v == 0.0 || (_v > 0 ? (x < _x || x > finalX) : (x > _x || x < finalX)))
      return double.infinity;
    return math.log(_dragLog * (x - _x) / _v + 1.0) / _dragLog;
  }

  @override
  bool isDone(double time) => dx(time).abs() < tolerance.velocity;
}

class BoundedFrictionSimulation extends FrictionSimulation {
  BoundedFrictionSimulation(
    double drag,
    double position,
    double velocity,
    this._minX,
    this._maxX,
  )   : assert(position.clamp(_minX, _maxX) == position),
        super(drag, position, velocity);

  final double _minX;
  final double _maxX;

  @override
  double x(double time) {
    return super.x(time).clamp(_minX, _maxX);
  }

  @override
  bool isDone(double time) {
    return super.isDone(time) ||
        (x(time) - _minX).abs() < tolerance.distance ||
        (x(time) - _maxX).abs() < tolerance.distance;
  }
}

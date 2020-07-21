import 'dart:math' as math;

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/physics.dart';

import '../util.dart';

class BouncingScrollSimulation extends Simulation {
  BouncingScrollSimulation({
    @required double position,
    @required double velocity,
    @required this.leadingExtent,
    @required this.trailingExtent,
    @required this.spring,
    Tolerance tolerance = Tolerance.defaultTolerance,
  })  : assert(position != null),
        assert(velocity != null),
        assert(leadingExtent != null),
        assert(trailingExtent != null),
        assert(leadingExtent <= trailingExtent),
        assert(spring != null),
        super(tolerance: tolerance) {
    if (position < leadingExtent) {
      _springSimulation = _underscrollSimulation(position, velocity);
      _springTime = double.negativeInfinity;
    } else if (position > trailingExtent) {
      _springSimulation = _overscrollSimulation(position, velocity);
      _springTime = double.negativeInfinity;
    } else {
      _frictionSimulation = new FrictionSimulation(0.135, position, velocity);
      final double finalX = _frictionSimulation.finalX;
      if (velocity > 0.0 && finalX > trailingExtent) {
        _springTime = _frictionSimulation.timeAtX(trailingExtent);
        _springSimulation = _overscrollSimulation(
          trailingExtent,
          math.min(
              _frictionSimulation.dx(_springTime), maxSpringTransferVelocity),
        );
        assert(_springTime.isFinite);
      } else if (velocity < 0.0 && finalX < leadingExtent) {
        _springTime = _frictionSimulation.timeAtX(leadingExtent);
        _springSimulation = _underscrollSimulation(
          leadingExtent,
          math.min(
              _frictionSimulation.dx(_springTime), maxSpringTransferVelocity),
        );
        assert(_springTime.isFinite);
      } else {
        _springTime = double.infinity;
      }
    }
    assert(_springTime != null);
  }

  static const double maxSpringTransferVelocity = 5000.0;

  final double leadingExtent;

  final double trailingExtent;

  final SpringDescription spring;

  FrictionSimulation _frictionSimulation;
  Simulation _springSimulation;
  double _springTime;
  double _timeOffset = 0.0;

  Simulation _underscrollSimulation(double x, double dx) {
    return new ScrollSpringSimulation(spring, x, leadingExtent, dx);
  }

  Simulation _overscrollSimulation(double x, double dx) {
    return new ScrollSpringSimulation(spring, x, trailingExtent, dx);
  }

  Simulation _simulation(double time) {
    Simulation simulation;
    if (time > _springTime) {
      _timeOffset = _springTime.isFinite ? _springTime : 0.0;
      simulation = _springSimulation;
    } else {
      _timeOffset = 0.0;
      simulation = _frictionSimulation;
    }
    return simulation..tolerance = tolerance;
  }

  @override
  double x(double time) => _simulation(time).x(time - _timeOffset);

  @override
  double dx(double time) => _simulation(time).dx(time - _timeOffset);

  @override
  bool isDone(double time) => _simulation(time).isDone(time - _timeOffset);

  @override
  String toString() {
    if (assertionsEnabled) {
      return '$runtimeType(leadingExtent: $leadingExtent, '
          'trailingExtent: $trailingExtent)';
    } else {
      return super.toString();
    }
  }
}

class ClampingScrollSimulation extends Simulation {
  ClampingScrollSimulation({
    @required this.position,
    @required this.velocity,
    this.friction = 0.015,
    Tolerance tolerance = Tolerance.defaultTolerance,
  })  : assert(_flingVelocityPenetration(0.0) == _initialVelocityPenetration),
        super(tolerance: tolerance) {
    _duration = _flingDuration(velocity);
    _distance = (velocity * _duration / _initialVelocityPenetration).abs();
  }

  final double position;

  final double velocity;

  final double friction;

  double _duration;
  double _distance;

  static final double _kDecelerationRate = math.log(0.78) / math.log(0.9);

  static double _decelerationForFriction(double friction) {
    return friction * 61774.04968;
  }

  double _flingDuration(double velocity) {
    final double scaledFriction = friction * _decelerationForFriction(0.84);

    final double deceleration =
        math.log(0.35 * velocity.abs() / scaledFriction);

    return math.exp(deceleration / (_kDecelerationRate - 1.0));
  }

  static const double _initialVelocityPenetration = 3.065;
  static double _flingDistancePenetration(double t) {
    return (1.2 * t * t * t) -
        (3.27 * t * t) +
        (_initialVelocityPenetration * t);
  }

  static double _flingVelocityPenetration(double t) {
    return (3.6 * t * t) - (6.54 * t) + _initialVelocityPenetration;
  }

  @override
  double x(double time) {
    final double t = (time / _duration).clamp(0.0, 1.0);
    return position + _distance * _flingDistancePenetration(t) * velocity.sign;
  }

  @override
  double dx(double time) {
    final double t = (time / _duration).clamp(0.0, 1.0);
    return _distance * _flingVelocityPenetration(t) * velocity.sign / _duration;
  }

  @override
  bool isDone(double time) {
    return time >= _duration;
  }
}

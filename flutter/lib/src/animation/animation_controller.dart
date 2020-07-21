import 'dart:async' show Future;

import 'package:meta/meta.dart';

import 'package:flutter_web/scheduler.dart'
    show TickerProvider, Ticker, TickerFuture;
import 'package:flutter_web/foundation.dart' show FlutterError;
import 'package:flutter_web/physics.dart'
    show SpringDescription, SpringSimulation, Tolerance, Simulation;
import 'package:flutter_web/semantics.dart';
import 'package:flutter_web/ui.dart' as ui show lerpDouble;

import 'animation.dart';
import 'curves.dart';
import 'listener_helpers.dart';

export 'package:flutter_web/scheduler.dart' show TickerFuture, TickerCanceled;

enum _AnimationDirection {
  forward,

  reverse,
}

final SpringDescription _kFlingSpringDescription =
    SpringDescription.withDampingRatio(
  mass: 1.0,
  stiffness: 500.0,
  ratio: 1.0,
);

const Tolerance _kFlingTolerance = Tolerance(
  velocity: double.infinity,
  distance: 0.01,
);

enum AnimationBehavior {
  normal,

  preserve,
}

class AnimationController extends Animation<double>
    with
        AnimationEagerListenerMixin,
        AnimationLocalListenersMixin,
        AnimationLocalStatusListenersMixin {
  AnimationController({
    double value,
    this.duration,
    this.reverseDuration,
    this.debugLabel,
    this.lowerBound = 0.0,
    this.upperBound = 1.0,
    this.animationBehavior = AnimationBehavior.normal,
    @required TickerProvider vsync,
  })  : assert(lowerBound != null),
        assert(upperBound != null),
        assert(upperBound >= lowerBound),
        assert(vsync != null),
        _direction = _AnimationDirection.forward {
    _ticker = vsync.createTicker(_tick);
    _internalSetValue(value ?? lowerBound);
  }

  AnimationController.unbounded({
    double value = 0.0,
    this.duration,
    this.reverseDuration,
    this.debugLabel,
    @required TickerProvider vsync,
    this.animationBehavior = AnimationBehavior.preserve,
  })  : assert(value != null),
        assert(vsync != null),
        lowerBound = double.negativeInfinity,
        upperBound = double.infinity,
        _direction = _AnimationDirection.forward {
    _ticker = vsync.createTicker(_tick);
    _internalSetValue(value);
  }

  final double lowerBound;

  final double upperBound;

  final String debugLabel;

  final AnimationBehavior animationBehavior;

  Animation<double> get view => this;

  Duration duration;

  Duration reverseDuration;

  Ticker _ticker;

  void resync(TickerProvider vsync) {
    final Ticker oldTicker = _ticker;
    _ticker = vsync.createTicker(_tick);
    _ticker.absorbTicker(oldTicker);
  }

  Simulation _simulation;

  @override
  double get value => _value;
  double _value;

  set value(double newValue) {
    assert(newValue != null);
    stop();
    _internalSetValue(newValue);
    notifyListeners();
    _checkStatusChanged();
  }

  void reset() {
    value = lowerBound;
  }

  double get velocity {
    if (!isAnimating) return 0.0;
    return _simulation.dx(lastElapsedDuration.inMicroseconds.toDouble() /
        Duration.microsecondsPerSecond);
  }

  void _internalSetValue(double newValue) {
    _value = newValue.clamp(lowerBound, upperBound);
    if (_value == lowerBound) {
      _status = AnimationStatus.dismissed;
    } else if (_value == upperBound) {
      _status = AnimationStatus.completed;
    } else {
      _status = (_direction == _AnimationDirection.forward)
          ? AnimationStatus.forward
          : AnimationStatus.reverse;
    }
  }

  Duration get lastElapsedDuration => _lastElapsedDuration;
  Duration _lastElapsedDuration;

  bool get isAnimating => _ticker != null && _ticker.isActive;

  _AnimationDirection _direction;

  @override
  AnimationStatus get status => _status;
  AnimationStatus _status;

  TickerFuture forward({double from}) {
    assert(() {
      if (duration == null) {
        throw FlutterError(
            'AnimationController.forward() called with no default duration.\n'
            'The "duration" property should be set, either in the constructor or later, before '
            'calling the forward() function.');
      }
      return true;
    }());
    assert(
        _ticker != null,
        'AnimationController.forward() called after AnimationController.dispose()\n'
        'AnimationController methods should not be used after calling dispose.');
    _direction = _AnimationDirection.forward;
    if (from != null) value = from;
    return _animateToInternal(upperBound);
  }

  TickerFuture reverse({double from}) {
    assert(() {
      if (duration == null && reverseDuration == null) {
        throw FlutterError(
            'AnimationController.reverse() called with no default duration or reverseDuration.\n'
            'The "duration" or "reverseDuration" property should be set, either in the constructor or later, before '
            'calling the reverse() function.');
      }
      return true;
    }());
    assert(
        _ticker != null,
        'AnimationController.reverse() called after AnimationController.dispose()\n'
        'AnimationController methods should not be used after calling dispose.');
    _direction = _AnimationDirection.reverse;
    if (from != null) value = from;
    return _animateToInternal(lowerBound);
  }

  TickerFuture animateTo(double target,
      {Duration duration, Curve curve = Curves.linear}) {
    assert(
        _ticker != null,
        'AnimationController.animateTo() called after AnimationController.dispose()\n'
        'AnimationController methods should not be used after calling dispose.');
    _direction = _AnimationDirection.forward;
    return _animateToInternal(target, duration: duration, curve: curve);
  }

  TickerFuture animateBack(double target,
      {Duration duration, Curve curve = Curves.linear}) {
    assert(
        _ticker != null,
        'AnimationController.animateBack() called after AnimationController.dispose()\n'
        'AnimationController methods should not be used after calling dispose.');
    _direction = _AnimationDirection.reverse;
    return _animateToInternal(target, duration: duration, curve: curve);
  }

  TickerFuture _animateToInternal(double target,
      {Duration duration, Curve curve = Curves.linear}) {
    double scale = 1.0;
    if (SemanticsBinding.instance.disableAnimations) {
      switch (animationBehavior) {
        case AnimationBehavior.normal:
          scale = 0.05;
          break;
        case AnimationBehavior.preserve:
          break;
      }
    }
    Duration simulationDuration = duration;
    if (simulationDuration == null) {
      assert(() {
        if ((this.duration == null &&
                _direction == _AnimationDirection.reverse &&
                reverseDuration == null) ||
            this.duration == null) {
          throw FlutterError(
              'AnimationController.animateTo() called with no explicit duration and no default duration or reverseDuration.\n'
              'Either the "duration" argument to the animateTo() method should be provided, or the '
              '"duration" and/or "reverseDuration" property should be set, either in the constructor or later, before '
              'calling the animateTo() function.');
        }
        return true;
      }());
      final double range = upperBound - lowerBound;
      final double remainingFraction =
          range.isFinite ? (target - _value).abs() / range : 1.0;
      final Duration directionDuration =
          (_direction == _AnimationDirection.reverse && reverseDuration != null)
              ? reverseDuration
              : this.duration;
      simulationDuration = directionDuration * remainingFraction;
    } else if (target == value) {
      simulationDuration = Duration.zero;
    }
    stop();
    if (simulationDuration == Duration.zero) {
      if (value != target) {
        _value = target.clamp(lowerBound, upperBound);
        notifyListeners();
      }
      _status = (_direction == _AnimationDirection.forward)
          ? AnimationStatus.completed
          : AnimationStatus.dismissed;
      _checkStatusChanged();
      return TickerFuture.complete();
    }
    assert(simulationDuration > Duration.zero);
    assert(!isAnimating);
    return _startSimulation(_InterpolationSimulation(
        _value, target, simulationDuration, curve, scale));
  }

  TickerFuture repeat(
      {double min, double max, bool reverse = false, Duration period}) {
    min ??= lowerBound;
    max ??= upperBound;
    period ??= duration;
    assert(() {
      if (period == null) {
        throw FlutterError(
            'AnimationController.repeat() called without an explicit period and with no default Duration.\n'
            'Either the "period" argument to the repeat() method should be provided, or the '
            '"duration" property should be set, either in the constructor or later, before '
            'calling the repeat() function.');
      }
      return true;
    }());
    assert(max >= min);
    assert(max <= upperBound && min >= lowerBound);
    assert(reverse != null);
    return animateWith(_RepeatingSimulation(_value, min, max, reverse, period));
  }

  TickerFuture fling(
      {double velocity = 1.0, AnimationBehavior animationBehavior}) {
    _direction = velocity < 0.0
        ? _AnimationDirection.reverse
        : _AnimationDirection.forward;
    final double target = velocity < 0.0
        ? lowerBound - _kFlingTolerance.distance
        : upperBound + _kFlingTolerance.distance;
    double scale = 1.0;
    final AnimationBehavior behavior =
        animationBehavior ?? this.animationBehavior;
    if (SemanticsBinding.instance.disableAnimations) {
      switch (behavior) {
        case AnimationBehavior.normal:
          scale = 200.0;
          break;
        case AnimationBehavior.preserve:
          break;
      }
    }
    final Simulation simulation = SpringSimulation(
        _kFlingSpringDescription, value, target, velocity * scale)
      ..tolerance = _kFlingTolerance;
    return animateWith(simulation);
  }

  TickerFuture animateWith(Simulation simulation) {
    assert(
        _ticker != null,
        'AnimationController.animateWith() called after AnimationController.dispose()\n'
        'AnimationController methods should not be used after calling dispose.');
    stop();
    return _startSimulation(simulation);
  }

  TickerFuture _startSimulation(Simulation simulation) {
    assert(simulation != null);
    assert(!isAnimating);
    _simulation = simulation;
    _lastElapsedDuration = Duration.zero;
    _value = simulation.x(0.0).clamp(lowerBound, upperBound);
    final TickerFuture result = _ticker.start();
    _status = (_direction == _AnimationDirection.forward)
        ? AnimationStatus.forward
        : AnimationStatus.reverse;
    _checkStatusChanged();
    return result;
  }

  void stop({bool canceled = true}) {
    assert(
        _ticker != null,
        'AnimationController.stop() called after AnimationController.dispose()\n'
        'AnimationController methods should not be used after calling dispose.');
    _simulation = null;
    _lastElapsedDuration = null;
    _ticker.stop(canceled: canceled);
  }

  @override
  void dispose() {
    assert(() {
      if (_ticker == null) {
        throw FlutterError(
            'AnimationController.dispose() called more than once.\n'
            'A given $runtimeType cannot be disposed more than once.\n'
            'The following $runtimeType object was disposed multiple times:\n'
            '  $this');
      }
      return true;
    }());
    _ticker.dispose();
    _ticker = null;
    super.dispose();
  }

  AnimationStatus _lastReportedStatus = AnimationStatus.dismissed;
  void _checkStatusChanged() {
    final AnimationStatus newStatus = status;
    if (_lastReportedStatus != newStatus) {
      _lastReportedStatus = newStatus;
      notifyStatusListeners(newStatus);
    }
  }

  void _tick(Duration elapsed) {
    _lastElapsedDuration = elapsed;
    final double elapsedInSeconds =
        elapsed.inMicroseconds.toDouble() / Duration.microsecondsPerSecond;
    assert(elapsedInSeconds >= 0.0);
    _value = _simulation.x(elapsedInSeconds).clamp(lowerBound, upperBound);
    if (_simulation.isDone(elapsedInSeconds)) {
      _status = (_direction == _AnimationDirection.forward)
          ? AnimationStatus.completed
          : AnimationStatus.dismissed;
      stop(canceled: false);
    }
    notifyListeners();
    _checkStatusChanged();
  }

  @override
  String toStringDetails() {
    final String paused = isAnimating ? '' : '; paused';
    final String ticker =
        _ticker == null ? '; DISPOSED' : (_ticker.muted ? '; silenced' : '');
    final String label = debugLabel == null ? '' : '; for $debugLabel';
    final String more =
        '${super.toStringDetails()} ${value.toStringAsFixed(3)}';
    return '$more$paused$ticker$label';
  }
}

class _InterpolationSimulation extends Simulation {
  _InterpolationSimulation(
      this._begin, this._end, Duration duration, this._curve, double scale)
      : assert(_begin != null),
        assert(_end != null),
        assert(duration != null && duration.inMicroseconds > 0),
        _durationInSeconds =
            (duration.inMicroseconds * scale) / Duration.microsecondsPerSecond;

  final double _durationInSeconds;
  final double _begin;
  final double _end;
  final Curve _curve;

  @override
  double x(double timeInSeconds) {
    final double t = (timeInSeconds / _durationInSeconds).clamp(0.0, 1.0);
    if (t == 0.0)
      return _begin;
    else if (t == 1.0)
      return _end;
    else
      return _begin + (_end - _begin) * _curve.transform(t);
  }

  @override
  double dx(double timeInSeconds) {
    final double epsilon = tolerance.time;
    return (x(timeInSeconds + epsilon) - x(timeInSeconds - epsilon)) /
        (2 * epsilon);
  }

  @override
  bool isDone(double timeInSeconds) => timeInSeconds > _durationInSeconds;
}

class _RepeatingSimulation extends Simulation {
  _RepeatingSimulation(
      double initialValue, this.min, this.max, this.reverse, Duration period)
      : _periodInSeconds =
            period.inMicroseconds / Duration.microsecondsPerSecond,
        _initialT = (max == min)
            ? 0.0
            : (initialValue / (max - min)) *
                (period.inMicroseconds / Duration.microsecondsPerSecond) {
    assert(_periodInSeconds > 0.0);
    assert(_initialT >= 0.0);
  }

  final double min;
  final double max;
  final bool reverse;

  final double _periodInSeconds;
  final double _initialT;

  @override
  double x(double timeInSeconds) {
    assert(timeInSeconds >= 0.0);

    final double totalTimeInSeconds = timeInSeconds + _initialT;
    final double t = (totalTimeInSeconds / _periodInSeconds) % 1.0;
    final bool _isPlayingReverse =
        (totalTimeInSeconds ~/ _periodInSeconds) % 2 == 1;

    if (reverse && _isPlayingReverse) {
      return ui.lerpDouble(max, min, t);
    } else {
      return ui.lerpDouble(min, max, t);
    }
  }

  @override
  double dx(double timeInSeconds) => (max - min) / _periodInSeconds;

  @override
  bool isDone(double timeInSeconds) => false;
}

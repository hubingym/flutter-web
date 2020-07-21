import 'package:flutter_web/ui.dart' show Offset;

import 'package:flutter_web/foundation.dart';

import 'lsq_solver.dart';

export 'package:flutter_web/ui.dart' show Offset;

class Velocity {
  const Velocity({
    @required this.pixelsPerSecond,
  }) : assert(pixelsPerSecond != null);

  static const Velocity zero = Velocity(pixelsPerSecond: Offset.zero);

  final Offset pixelsPerSecond;

  Velocity operator -() => Velocity(pixelsPerSecond: -pixelsPerSecond);

  Velocity operator -(Velocity other) {
    return Velocity(pixelsPerSecond: pixelsPerSecond - other.pixelsPerSecond);
  }

  Velocity operator +(Velocity other) {
    return Velocity(pixelsPerSecond: pixelsPerSecond + other.pixelsPerSecond);
  }

  Velocity clampMagnitude(double minValue, double maxValue) {
    assert(minValue != null && minValue >= 0.0);
    assert(maxValue != null && maxValue >= 0.0 && maxValue >= minValue);
    final double valueSquared = pixelsPerSecond.distanceSquared;
    if (valueSquared > maxValue * maxValue)
      return Velocity(
          pixelsPerSecond:
              (pixelsPerSecond / pixelsPerSecond.distance) * maxValue);
    if (valueSquared < minValue * minValue)
      return Velocity(
          pixelsPerSecond:
              (pixelsPerSecond / pixelsPerSecond.distance) * minValue);
    return this;
  }

  @override
  bool operator ==(dynamic other) {
    if (other is! Velocity) return false;
    final Velocity typedOther = other;
    return pixelsPerSecond == typedOther.pixelsPerSecond;
  }

  @override
  int get hashCode => pixelsPerSecond.hashCode;

  @override
  String toString() =>
      'Velocity(${pixelsPerSecond.dx.toStringAsFixed(1)}, ${pixelsPerSecond.dy.toStringAsFixed(1)})';
}

class VelocityEstimate {
  const VelocityEstimate({
    @required this.pixelsPerSecond,
    @required this.confidence,
    @required this.duration,
    @required this.offset,
  })  : assert(pixelsPerSecond != null),
        assert(confidence != null),
        assert(duration != null),
        assert(offset != null);

  final Offset pixelsPerSecond;

  final double confidence;

  final Duration duration;

  final Offset offset;

  @override
  String toString() =>
      'VelocityEstimate(${pixelsPerSecond.dx.toStringAsFixed(1)}, ${pixelsPerSecond.dy.toStringAsFixed(1)}; offset: $offset, duration: $duration, confidence: ${confidence.toStringAsFixed(1)})';
}

class _PointAtTime {
  const _PointAtTime(this.point, this.time)
      : assert(point != null),
        assert(time != null);

  final Duration time;
  final Offset point;

  @override
  String toString() => '_PointAtTime($point at $time)';
}

class VelocityTracker {
  static const int _assumePointerMoveStoppedMilliseconds = 40;
  static const int _historySize = 20;
  static const int _horizonMilliseconds = 100;
  static const int _minSampleSize = 3;

  final List<_PointAtTime> _samples = List<_PointAtTime>(_historySize);
  int _index = 0;

  void addPosition(Duration time, Offset position) {
    _index += 1;
    if (_index == _historySize) _index = 0;
    _samples[_index] = _PointAtTime(position, time);
  }

  VelocityEstimate getVelocityEstimate() {
    final List<double> x = <double>[];
    final List<double> y = <double>[];
    final List<double> w = <double>[];
    final List<double> time = <double>[];
    int sampleCount = 0;
    int index = _index;

    final _PointAtTime newestSample = _samples[index];
    if (newestSample == null) return null;

    _PointAtTime previousSample = newestSample;
    _PointAtTime oldestSample = newestSample;

    do {
      final _PointAtTime sample = _samples[index];
      if (sample == null) break;

      final double age =
          (newestSample.time - sample.time).inMilliseconds.toDouble();
      final double delta =
          (sample.time - previousSample.time).inMilliseconds.abs().toDouble();
      previousSample = sample;
      if (age > _horizonMilliseconds ||
          delta > _assumePointerMoveStoppedMilliseconds) break;

      oldestSample = sample;
      final Offset position = sample.point;
      x.add(position.dx);
      y.add(position.dy);
      w.add(1.0);
      time.add(-age);
      index = (index == 0 ? _historySize : index) - 1;

      sampleCount += 1;
    } while (sampleCount < _historySize);

    if (sampleCount >= _minSampleSize) {
      final LeastSquaresSolver xSolver = LeastSquaresSolver(time, x, w);
      final PolynomialFit xFit = xSolver.solve(2);
      if (xFit != null) {
        final LeastSquaresSolver ySolver = LeastSquaresSolver(time, y, w);
        final PolynomialFit yFit = ySolver.solve(2);
        if (yFit != null) {
          return VelocityEstimate(
            pixelsPerSecond: Offset(
                xFit.coefficients[1] * 1000, yFit.coefficients[1] * 1000),
            confidence: xFit.confidence * yFit.confidence,
            duration: newestSample.time - oldestSample.time,
            offset: newestSample.point - oldestSample.point,
          );
        }
      }
    }

    return VelocityEstimate(
      pixelsPerSecond: Offset.zero,
      confidence: 1.0,
      duration: newestSample.time - oldestSample.time,
      offset: newestSample.point - oldestSample.point,
    );
  }

  Velocity getVelocity() {
    final VelocityEstimate estimate = getVelocityEstimate();
    if (estimate == null || estimate.pixelsPerSecond == Offset.zero)
      return Velocity.zero;
    return Velocity(pixelsPerSecond: estimate.pixelsPerSecond);
  }
}

import 'dart:math' as math;

import 'package:meta/meta.dart';

@immutable
abstract class Curve {
  const Curve();

  double transform(double t) {
    assert(t >= 0.0 && t <= 1.0);
    if (t == 0.0 || t == 1.0) {
      return t;
    }
    return transformInternal(t);
  }

  @protected
  double transformInternal(double t) {
    throw UnimplementedError();
  }

  Curve get flipped => FlippedCurve(this);

  @override
  String toString() {
    return '$runtimeType';
  }
}

class _Linear extends Curve {
  const _Linear._();

  @override
  double transformInternal(double t) => t;
}

class SawTooth extends Curve {
  const SawTooth(this.count) : assert(count != null);

  final int count;

  @override
  double transformInternal(double t) {
    t *= count;
    return t - t.truncateToDouble();
  }

  @override
  String toString() {
    return '$runtimeType($count)';
  }
}

class Interval extends Curve {
  const Interval(this.begin, this.end, {this.curve = Curves.linear})
      : assert(begin != null),
        assert(end != null),
        assert(curve != null);

  final double begin;

  final double end;

  final Curve curve;

  @override
  double transformInternal(double t) {
    assert(begin >= 0.0);
    assert(begin <= 1.0);
    assert(end >= 0.0);
    assert(end <= 1.0);
    assert(end >= begin);
    t = ((t - begin) / (end - begin)).clamp(0.0, 1.0);
    if (t == 0.0 || t == 1.0) return t;
    return curve.transform(t);
  }

  @override
  String toString() {
    if (curve is! _Linear) return '$runtimeType($begin\u22EF$end)\u27A9$curve';
    return '$runtimeType($begin\u22EF$end)';
  }
}

class Threshold extends Curve {
  const Threshold(this.threshold) : assert(threshold != null);

  final double threshold;

  @override
  double transformInternal(double t) {
    assert(threshold >= 0.0);
    assert(threshold <= 1.0);
    return t < threshold ? 0.0 : 1.0;
  }
}

class Cubic extends Curve {
  const Cubic(this.a, this.b, this.c, this.d)
      : assert(a != null),
        assert(b != null),
        assert(c != null),
        assert(d != null);

  final double a;

  final double b;

  final double c;

  final double d;

  static const double _cubicErrorBound = 0.001;

  double _evaluateCubic(double a, double b, double m) {
    return 3 * a * (1 - m) * (1 - m) * m + 3 * b * (1 - m) * m * m + m * m * m;
  }

  @override
  double transformInternal(double t) {
    double start = 0.0;
    double end = 1.0;
    while (true) {
      final double midpoint = (start + end) / 2;
      final double estimate = _evaluateCubic(a, c, midpoint);
      if ((t - estimate).abs() < _cubicErrorBound)
        return _evaluateCubic(b, d, midpoint);
      if (estimate < t)
        start = midpoint;
      else
        end = midpoint;
    }
  }

  @override
  String toString() {
    return '$runtimeType(${a.toStringAsFixed(2)}, ${b.toStringAsFixed(2)}, ${c.toStringAsFixed(2)}, ${d.toStringAsFixed(2)})';
  }
}

class FlippedCurve extends Curve {
  const FlippedCurve(this.curve) : assert(curve != null);

  final Curve curve;

  @override
  double transformInternal(double t) => 1.0 - curve.transform(1.0 - t);

  @override
  String toString() {
    return '$runtimeType($curve)';
  }
}

class _DecelerateCurve extends Curve {
  const _DecelerateCurve._();

  @override
  double transformInternal(double t) {
    t = 1.0 - t;
    return 1.0 - t * t;
  }
}

double _bounce(double t) {
  if (t < 1.0 / 2.75) {
    return 7.5625 * t * t;
  } else if (t < 2 / 2.75) {
    t -= 1.5 / 2.75;
    return 7.5625 * t * t + 0.75;
  } else if (t < 2.5 / 2.75) {
    t -= 2.25 / 2.75;
    return 7.5625 * t * t + 0.9375;
  }
  t -= 2.625 / 2.75;
  return 7.5625 * t * t + 0.984375;
}

class _BounceInCurve extends Curve {
  const _BounceInCurve._();

  @override
  double transformInternal(double t) {
    return 1.0 - _bounce(1.0 - t);
  }
}

class _BounceOutCurve extends Curve {
  const _BounceOutCurve._();

  @override
  double transformInternal(double t) {
    return _bounce(t);
  }
}

class _BounceInOutCurve extends Curve {
  const _BounceInOutCurve._();

  @override
  double transformInternal(double t) {
    if (t < 0.5)
      return (1.0 - _bounce(1.0 - t * 2.0)) * 0.5;
    else
      return _bounce(t * 2.0 - 1.0) * 0.5 + 0.5;
  }
}

class ElasticInCurve extends Curve {
  const ElasticInCurve([this.period = 0.4]);

  final double period;

  @override
  double transformInternal(double t) {
    final double s = period / 4.0;
    t = t - 1.0;
    return -math.pow(2.0, 10.0 * t) *
        math.sin((t - s) * (math.pi * 2.0) / period);
  }

  @override
  String toString() {
    return '$runtimeType($period)';
  }
}

class ElasticOutCurve extends Curve {
  const ElasticOutCurve([this.period = 0.4]);

  final double period;

  @override
  double transformInternal(double t) {
    final double s = period / 4.0;
    return math.pow(2.0, -10 * t) *
            math.sin((t - s) * (math.pi * 2.0) / period) +
        1.0;
  }

  @override
  String toString() {
    return '$runtimeType($period)';
  }
}

class ElasticInOutCurve extends Curve {
  const ElasticInOutCurve([this.period = 0.4]);

  final double period;

  @override
  double transformInternal(double t) {
    final double s = period / 4.0;
    t = 2.0 * t - 1.0;
    if (t < 0.0)
      return -0.5 *
          math.pow(2.0, 10.0 * t) *
          math.sin((t - s) * (math.pi * 2.0) / period);
    else
      return math.pow(2.0, -10.0 * t) *
              math.sin((t - s) * (math.pi * 2.0) / period) *
              0.5 +
          1.0;
  }

  @override
  String toString() {
    return '$runtimeType($period)';
  }
}

class Curves {
  Curves._();

  static const Curve linear = _Linear._();

  static const Curve decelerate = _DecelerateCurve._();

  static const Cubic fastLinearToSlowEaseIn = Cubic(0.18, 1.0, 0.04, 1.0);

  static const Cubic ease = Cubic(0.25, 0.1, 0.25, 1.0);

  static const Cubic easeIn = Cubic(0.42, 0.0, 1.0, 1.0);

  static const Cubic easeInToLinear = Cubic(0.67, 0.03, 0.65, 0.09);

  static const Cubic easeInSine = Cubic(0.47, 0.0, 0.745, 0.715);

  static const Cubic easeInQuad = Cubic(0.55, 0.085, 0.68, 0.53);

  static const Cubic easeInCubic = Cubic(0.55, 0.055, 0.675, 0.19);

  static const Cubic easeInQuart = Cubic(0.895, 0.03, 0.685, 0.22);

  static const Cubic easeInQuint = Cubic(0.755, 0.05, 0.855, 0.06);

  static const Cubic easeInExpo = Cubic(0.95, 0.05, 0.795, 0.035);

  static const Cubic easeInCirc = Cubic(0.6, 0.04, 0.98, 0.335);

  static const Cubic easeInBack = Cubic(0.6, -0.28, 0.735, 0.045);

  static const Cubic easeOut = Cubic(0.0, 0.0, 0.58, 1.0);

  static const Cubic linearToEaseOut = Cubic(0.35, 0.91, 0.33, 0.97);

  static const Cubic easeOutSine = Cubic(0.39, 0.575, 0.565, 1.0);

  static const Cubic easeOutQuad = Cubic(0.25, 0.46, 0.45, 0.94);

  static const Cubic easeOutCubic = Cubic(0.215, 0.61, 0.355, 1.0);

  static const Cubic easeOutQuart = Cubic(0.165, 0.84, 0.44, 1.0);

  static const Cubic easeOutQuint = Cubic(0.23, 1.0, 0.32, 1.0);

  static const Cubic easeOutExpo = Cubic(0.19, 1.0, 0.22, 1.0);

  static const Cubic easeOutCirc = Cubic(0.075, 0.82, 0.165, 1.0);

  static const Cubic easeOutBack = Cubic(0.175, 0.885, 0.32, 1.275);

  static const Cubic easeInOut = Cubic(0.42, 0.0, 0.58, 1.0);

  static const Cubic easeInOutSine = Cubic(0.445, 0.05, 0.55, 0.95);

  static const Cubic easeInOutQuad = Cubic(0.455, 0.03, 0.515, 0.955);

  static const Cubic easeInOutCubic = Cubic(0.645, 0.045, 0.355, 1.0);

  static const Cubic easeInOutQuart = Cubic(0.77, 0.0, 0.175, 1.0);

  static const Cubic easeInOutQuint = Cubic(0.86, 0.0, 0.07, 1.0);

  static const Cubic easeInOutExpo = Cubic(1.0, 0.0, 0.0, 1.0);

  static const Cubic easeInOutCirc = Cubic(0.785, 0.135, 0.15, 0.86);

  static const Cubic easeInOutBack = Cubic(0.68, -0.55, 0.265, 1.55);

  static const Cubic fastOutSlowIn = Cubic(0.4, 0.0, 0.2, 1.0);

  static const Cubic slowMiddle = Cubic(0.15, 0.85, 0.85, 0.15);

  static const Curve bounceIn = _BounceInCurve._();

  static const Curve bounceOut = _BounceOutCurve._();

  static const Curve bounceInOut = _BounceInOutCurve._();

  static const ElasticInCurve elasticIn = ElasticInCurve();

  static const ElasticOutCurve elasticOut = ElasticOutCurve();

  static const ElasticInOutCurve elasticInOut = ElasticInOutCurve();
}

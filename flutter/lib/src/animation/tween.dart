import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/ui.dart';

import 'animation.dart';
import 'animations.dart';
import 'curves.dart';

abstract class Animatable<T> {
  const Animatable();

  T transform(double t);

  T evaluate(Animation<double> animation) => transform(animation.value);

  Animation<T> animate(Animation<double> parent) {
    return _AnimatedEvaluation<T>(parent, this);
  }

  Animatable<T> chain(Animatable<double> parent) {
    return _ChainedEvaluation<T>(parent, this);
  }
}

class _AnimatedEvaluation<T> extends Animation<T>
    with AnimationWithParentMixin<double> {
  _AnimatedEvaluation(this.parent, this._evaluatable);

  @override
  final Animation<double> parent;

  final Animatable<T> _evaluatable;

  @override
  T get value => _evaluatable.evaluate(parent);

  @override
  String toString() {
    return '$parent\u27A9$_evaluatable\u27A9$value';
  }

  @override
  String toStringDetails() {
    return '${super.toStringDetails()} $_evaluatable';
  }
}

class _ChainedEvaluation<T> extends Animatable<T> {
  _ChainedEvaluation(this._parent, this._evaluatable);

  final Animatable<double> _parent;
  final Animatable<T> _evaluatable;

  @override
  T transform(double t) {
    return _evaluatable.transform(_parent.transform(t));
  }

  @override
  String toString() {
    return '$_parent\u27A9$_evaluatable';
  }
}

class Tween<T extends dynamic> extends Animatable<T> {
  Tween({this.begin, this.end});

  T begin;

  T end;

  @protected
  T lerp(double t) {
    assert(begin != null);
    assert(end != null);
    return begin + (end - begin) * t;
  }

  @override
  T transform(double t) {
    if (t == 0.0) return begin;
    if (t == 1.0) return end;
    return lerp(t);
  }

  @override
  String toString() => '$runtimeType($begin \u2192 $end)';
}

class ReverseTween<T> extends Tween<T> {
  ReverseTween(this.parent)
      : assert(parent != null),
        super(begin: parent.end, end: parent.begin);

  final Tween<T> parent;

  @override
  T lerp(double t) => parent.lerp(1.0 - t);
}

class ColorTween extends Tween<Color> {
  ColorTween({Color begin, Color end}) : super(begin: begin, end: end);

  @override
  Color lerp(double t) => Color.lerp(begin, end, t);
}

class SizeTween extends Tween<Size> {
  SizeTween({Size begin, Size end}) : super(begin: begin, end: end);

  @override
  Size lerp(double t) => Size.lerp(begin, end, t);
}

class RectTween extends Tween<Rect> {
  RectTween({Rect begin, Rect end}) : super(begin: begin, end: end);

  @override
  Rect lerp(double t) => Rect.lerp(begin, end, t);
}

class IntTween extends Tween<int> {
  IntTween({int begin, int end}) : super(begin: begin, end: end);

  @override
  int lerp(double t) => (begin + (end - begin) * t).round();
}

class StepTween extends Tween<int> {
  StepTween({int begin, int end}) : super(begin: begin, end: end);

  @override
  int lerp(double t) => (begin + (end - begin) * t).floor();
}

class ConstantTween<T> extends Tween<T> {
  ConstantTween(T value) : super(begin: value, end: value);

  @override
  T lerp(double t) => begin;

  @override
  String toString() => '$runtimeType(value: begin)';
}

class CurveTween extends Animatable<double> {
  CurveTween({@required this.curve}) : assert(curve != null);

  Curve curve;

  @override
  double transform(double t) {
    if (t == 0.0 || t == 1.0) {
      assert(curve.transform(t).round() == t);
      return t;
    }
    return curve.transform(t);
  }

  @override
  String toString() => '$runtimeType(curve: $curve)';
}

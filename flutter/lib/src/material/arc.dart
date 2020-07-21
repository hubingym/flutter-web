import 'dart:math' as math;
import 'package:flutter_web/ui.dart' show lerpDouble;

import 'package:flutter_web/animation.dart';
import 'package:flutter_web/painting.dart';

const double _kOnAxisDelta = 2.0;

class MaterialPointArcTween extends Tween<Offset> {
  MaterialPointArcTween({
    Offset begin,
    Offset end,
  }) : super(begin: begin, end: end);

  bool _dirty = true;

  void _initialize() {
    assert(begin != null);
    assert(end != null);

    final Offset delta = end - begin;
    final double deltaX = delta.dx.abs();
    final double deltaY = delta.dy.abs();
    final double distanceFromAtoB = delta.distance;
    final Offset c = Offset(end.dx, begin.dy);

    double sweepAngle() => 2.0 * math.asin(distanceFromAtoB / (2.0 * _radius));

    if (deltaX > _kOnAxisDelta && deltaY > _kOnAxisDelta) {
      if (deltaX < deltaY) {
        _radius =
            distanceFromAtoB * distanceFromAtoB / (c - begin).distance / 2.0;
        _center = Offset(end.dx + _radius * (begin.dx - end.dx).sign, end.dy);
        if (begin.dx < end.dx) {
          _beginAngle = sweepAngle() * (begin.dy - end.dy).sign;
          _endAngle = 0.0;
        } else {
          _beginAngle = math.pi + sweepAngle() * (end.dy - begin.dy).sign;
          _endAngle = math.pi;
        }
      } else {
        _radius =
            distanceFromAtoB * distanceFromAtoB / (c - end).distance / 2.0;
        _center =
            Offset(begin.dx, begin.dy + (end.dy - begin.dy).sign * _radius);
        if (begin.dy < end.dy) {
          _beginAngle = -math.pi / 2.0;
          _endAngle = _beginAngle + sweepAngle() * (end.dx - begin.dx).sign;
        } else {
          _beginAngle = math.pi / 2.0;
          _endAngle = _beginAngle + sweepAngle() * (begin.dx - end.dx).sign;
        }
      }
      assert(_beginAngle != null);
      assert(_endAngle != null);
    } else {
      _beginAngle = null;
      _endAngle = null;
    }
    _dirty = false;
  }

  Offset get center {
    if (begin == null || end == null) return null;
    if (_dirty) _initialize();
    return _center;
  }

  Offset _center;

  double get radius {
    if (begin == null || end == null) return null;
    if (_dirty) _initialize();
    return _radius;
  }

  double _radius;

  double get beginAngle {
    if (begin == null || end == null) return null;
    if (_dirty) _initialize();
    return _beginAngle;
  }

  double _beginAngle;

  double get endAngle {
    if (begin == null || end == null) return null;
    if (_dirty) _initialize();
    return _beginAngle;
  }

  double _endAngle;

  @override
  set begin(Offset value) {
    if (value != begin) {
      super.begin = value;
      _dirty = true;
    }
  }

  @override
  set end(Offset value) {
    if (value != end) {
      super.end = value;
      _dirty = true;
    }
  }

  @override
  Offset lerp(double t) {
    if (_dirty) _initialize();
    if (t == 0.0) return begin;
    if (t == 1.0) return end;
    if (_beginAngle == null || _endAngle == null)
      return Offset.lerp(begin, end, t);
    final double angle = lerpDouble(_beginAngle, _endAngle, t);
    final double x = math.cos(angle) * _radius;
    final double y = math.sin(angle) * _radius;
    return _center + Offset(x, y);
  }

  @override
  String toString() {
    return '$runtimeType($begin \u2192 $end; center=$center, radius=$radius, beginAngle=$beginAngle, endAngle=$endAngle)';
  }
}

enum _CornerId { topLeft, topRight, bottomLeft, bottomRight }

class _Diagonal {
  const _Diagonal(this.beginId, this.endId);
  final _CornerId beginId;
  final _CornerId endId;
}

const List<_Diagonal> _allDiagonals = <_Diagonal>[
  _Diagonal(_CornerId.topLeft, _CornerId.bottomRight),
  _Diagonal(_CornerId.bottomRight, _CornerId.topLeft),
  _Diagonal(_CornerId.topRight, _CornerId.bottomLeft),
  _Diagonal(_CornerId.bottomLeft, _CornerId.topRight),
];

typedef _KeyFunc<T> = dynamic Function(T input);

T _maxBy<T>(Iterable<T> input, _KeyFunc<T> keyFunc) {
  T maxValue;
  dynamic maxKey;
  for (T value in input) {
    final dynamic key = keyFunc(value);
    if (maxKey == null || key > maxKey) {
      maxValue = value;
      maxKey = key;
    }
  }
  return maxValue;
}

class MaterialRectArcTween extends RectTween {
  MaterialRectArcTween({
    Rect begin,
    Rect end,
  }) : super(begin: begin, end: end);

  bool _dirty = true;

  void _initialize() {
    assert(begin != null);
    assert(end != null);
    final Offset centersVector = end.center - begin.center;
    final _Diagonal diagonal = _maxBy<_Diagonal>(
        _allDiagonals, (_Diagonal d) => _diagonalSupport(centersVector, d));
    _beginArc = MaterialPointArcTween(
        begin: _cornerFor(begin, diagonal.beginId),
        end: _cornerFor(end, diagonal.beginId));
    _endArc = MaterialPointArcTween(
        begin: _cornerFor(begin, diagonal.endId),
        end: _cornerFor(end, diagonal.endId));
    _dirty = false;
  }

  double _diagonalSupport(Offset centersVector, _Diagonal diagonal) {
    final Offset delta =
        _cornerFor(begin, diagonal.endId) - _cornerFor(begin, diagonal.beginId);
    final double length = delta.distance;
    return centersVector.dx * delta.dx / length +
        centersVector.dy * delta.dy / length;
  }

  Offset _cornerFor(Rect rect, _CornerId id) {
    switch (id) {
      case _CornerId.topLeft:
        return rect.topLeft;
      case _CornerId.topRight:
        return rect.topRight;
      case _CornerId.bottomLeft:
        return rect.bottomLeft;
      case _CornerId.bottomRight:
        return rect.bottomRight;
    }
    return Offset.zero;
  }

  MaterialPointArcTween get beginArc {
    if (begin == null) return null;
    if (_dirty) _initialize();
    return _beginArc;
  }

  MaterialPointArcTween _beginArc;

  MaterialPointArcTween get endArc {
    if (end == null) return null;
    if (_dirty) _initialize();
    return _endArc;
  }

  MaterialPointArcTween _endArc;

  @override
  set begin(Rect value) {
    if (value != begin) {
      super.begin = value;
      _dirty = true;
    }
  }

  @override
  set end(Rect value) {
    if (value != end) {
      super.end = value;
      _dirty = true;
    }
  }

  @override
  Rect lerp(double t) {
    if (_dirty) _initialize();
    if (t == 0.0) return begin;
    if (t == 1.0) return end;
    return Rect.fromPoints(_beginArc.lerp(t), _endArc.lerp(t));
  }

  @override
  String toString() {
    return '$runtimeType($begin \u2192 $end; beginArc=$beginArc, endArc=$endArc)';
  }
}

class MaterialRectCenterArcTween extends RectTween {
  MaterialRectCenterArcTween({
    Rect begin,
    Rect end,
  }) : super(begin: begin, end: end);

  bool _dirty = true;

  void _initialize() {
    assert(begin != null);
    assert(end != null);
    _centerArc = MaterialPointArcTween(
      begin: begin.center,
      end: end.center,
    );
    _dirty = false;
  }

  MaterialPointArcTween get centerArc {
    if (begin == null || end == null) return null;
    if (_dirty) _initialize();
    return _centerArc;
  }

  MaterialPointArcTween _centerArc;

  @override
  set begin(Rect value) {
    if (value != begin) {
      super.begin = value;
      _dirty = true;
    }
  }

  @override
  set end(Rect value) {
    if (value != end) {
      super.end = value;
      _dirty = true;
    }
  }

  @override
  Rect lerp(double t) {
    if (_dirty) _initialize();
    if (t == 0.0) return begin;
    if (t == 1.0) return end;
    final Offset center = _centerArc.lerp(t);
    final double width = lerpDouble(begin.width, end.width, t);
    final double height = lerpDouble(begin.height, end.height, t);
    return Rect.fromLTWH(
        center.dx - width / 2.0, center.dy - height / 2.0, width, height);
  }

  @override
  String toString() {
    return '$runtimeType($begin \u2192 $end; centerArc=$centerArc)';
  }
}

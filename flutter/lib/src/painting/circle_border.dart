import 'dart:math' as math;

import 'basic_types.dart';
import 'borders.dart';
import 'edge_insets.dart';

class CircleBorder extends ShapeBorder {
  const CircleBorder({this.side = BorderSide.none}) : assert(side != null);

  final BorderSide side;

  @override
  EdgeInsetsGeometry get dimensions {
    return EdgeInsets.all(side.width);
  }

  @override
  ShapeBorder scale(double t) => CircleBorder(side: side.scale(t));

  @override
  ShapeBorder lerpFrom(ShapeBorder a, double t) {
    if (a is CircleBorder)
      return CircleBorder(side: BorderSide.lerp(a.side, side, t));
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder lerpTo(ShapeBorder b, double t) {
    if (b is CircleBorder)
      return CircleBorder(side: BorderSide.lerp(side, b.side, t));
    return super.lerpTo(b, t);
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection textDirection}) {
    return Path()
      ..addOval(Rect.fromCircle(
        center: rect.center,
        radius: math.max(0.0, rect.shortestSide / 2.0 - side.width),
      ));
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection textDirection}) {
    return Path()
      ..addOval(Rect.fromCircle(
        center: rect.center,
        radius: rect.shortestSide / 2.0,
      ));
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection textDirection}) {
    switch (side.style) {
      case BorderStyle.none:
        break;
      case BorderStyle.solid:
        canvas.drawCircle(rect.center, (rect.shortestSide - side.width) / 2.0,
            side.toPaint());
    }
  }

  @override
  bool operator ==(dynamic other) {
    if (runtimeType != other.runtimeType) return false;
    final CircleBorder typedOther = other;
    return side == typedOther.side;
  }

  @override
  int get hashCode => side.hashCode;

  @override
  String toString() {
    return '$runtimeType($side)';
  }
}

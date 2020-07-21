import 'package:flutter_web/foundation.dart';

import 'basic_types.dart';
import 'border_radius.dart';
import 'borders.dart';
import 'edge_insets.dart';

import '../util.dart';

enum BoxShape {
  rectangle,

  circle,
}

abstract class BoxBorder extends ShapeBorder {
  const BoxBorder();

  BorderSide get top;

  BorderSide get bottom;

  bool get isUniform;

  @override
  BoxBorder add(ShapeBorder other, {bool reversed = false}) => null;

  static BoxBorder lerp(BoxBorder a, BoxBorder b, double t) {
    assert(t != null);
    if ((a is Border || a == null) && (b is Border || b == null))
      return Border.lerp(a, b, t);
    if ((a is BorderDirectional || a == null) &&
        (b is BorderDirectional || b == null))
      return BorderDirectional.lerp(a, b, t);
    if (b is Border && a is BorderDirectional) {
      final BoxBorder c = b;
      b = a;
      a = c;
      t = 1.0 - t;
    }
    if (a is Border && b is BorderDirectional) {
      if (b.start == BorderSide.none && b.end == BorderSide.none) {
        return Border(
          top: BorderSide.lerp(a.top, b.top, t),
          right: BorderSide.lerp(a.right, BorderSide.none, t),
          bottom: BorderSide.lerp(a.bottom, b.bottom, t),
          left: BorderSide.lerp(a.left, BorderSide.none, t),
        );
      }
      if (a.left == BorderSide.none && a.right == BorderSide.none) {
        return BorderDirectional(
          top: BorderSide.lerp(a.top, b.top, t),
          start: BorderSide.lerp(BorderSide.none, b.start, t),
          end: BorderSide.lerp(BorderSide.none, b.end, t),
          bottom: BorderSide.lerp(a.bottom, b.bottom, t),
        );
      }

      if (t < 0.5) {
        return Border(
          top: BorderSide.lerp(a.top, b.top, t),
          right: BorderSide.lerp(a.right, BorderSide.none, t * 2.0),
          bottom: BorderSide.lerp(a.bottom, b.bottom, t),
          left: BorderSide.lerp(a.left, BorderSide.none, t * 2.0),
        );
      }
      return BorderDirectional(
        top: BorderSide.lerp(a.top, b.top, t),
        start: BorderSide.lerp(BorderSide.none, b.start, (t - 0.5) * 2.0),
        end: BorderSide.lerp(BorderSide.none, b.end, (t - 0.5) * 2.0),
        bottom: BorderSide.lerp(a.bottom, b.bottom, t),
      );
    }
    throw FlutterError(
        'BoxBorder.lerp can only interpolate Border and BorderDirectional classes.\n'
        'BoxBorder.lerp() was called with two objects of type ${a.runtimeType} and ${b.runtimeType}:\n'
        '  $a\n'
        '  $b\n'
        'However, only Border and BorderDirectional classes are supported by this method. '
        'For a more general interpolation method, consider using ShapeBorder.lerp instead.');
  }

  @override
  Path getInnerPath(Rect rect, {@required TextDirection textDirection}) {
    assert(
        textDirection != null,
        'The textDirection argument to '
        '$runtimeType.getInnerPath must not be null.');
    return new Path()
      ..addRect(dimensions.resolve(textDirection).deflateRect(rect));
  }

  @override
  Path getOuterPath(Rect rect, {@required TextDirection textDirection}) {
    assert(
        textDirection != null,
        'The textDirection argument to '
        '$runtimeType.getOuterPath must not be null.');
    return new Path()..addRect(rect);
  }

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    TextDirection textDirection,
    BoxShape shape = BoxShape.rectangle,
    BorderRadius borderRadius,
  });

  static void _paintUniformBorderWithRadius(
      Canvas canvas, Rect rect, BorderSide side, BorderRadius borderRadius) {
    assert(side.style != BorderStyle.none);
    final Paint paint = new Paint()..color = side.color;
    final RRect outer = borderRadius.toRRect(rect);
    final double width = side.width;
    if (width == 0.0) {
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.0;
      canvas.drawRRect(outer, paint);
    } else {
      final RRect inner = outer.deflate(width);
      canvas.drawDRRect(outer, inner, paint);
    }
  }

  static void _paintUniformBorderWithCircle(
      Canvas canvas, Rect rect, BorderSide side) {
    assert(side.style != BorderStyle.none);
    final double width = side.width;
    final Paint paint = side.toPaint();
    final double radius = (rect.shortestSide - width) / 2.0;
    canvas.drawCircle(rect.center, radius, paint);
  }

  static void _paintUniformBorderWithRectangle(
      Canvas canvas, Rect rect, BorderSide side) {
    assert(side.style != BorderStyle.none);
    final double width = side.width;
    final Paint paint = side.toPaint();
    canvas.drawRect(rect.deflate(width / 2.0), paint);
  }
}

class Border extends BoxBorder {
  const Border({
    this.top = BorderSide.none,
    this.right = BorderSide.none,
    this.bottom = BorderSide.none,
    this.left = BorderSide.none,
  })  : assert(top != null),
        assert(right != null),
        assert(bottom != null),
        assert(left != null);

  factory Border.all({
    Color color = const Color(0xFF000000),
    double width = 1.0,
    BorderStyle style = BorderStyle.solid,
  }) {
    final BorderSide side =
        new BorderSide(color: color, width: width, style: style);
    return new Border(top: side, right: side, bottom: side, left: side);
  }

  static Border merge(Border a, Border b) {
    assert(a != null);
    assert(b != null);
    assert(BorderSide.canMerge(a.top, b.top));
    assert(BorderSide.canMerge(a.right, b.right));
    assert(BorderSide.canMerge(a.bottom, b.bottom));
    assert(BorderSide.canMerge(a.left, b.left));
    return new Border(
      top: BorderSide.merge(a.top, b.top),
      right: BorderSide.merge(a.right, b.right),
      bottom: BorderSide.merge(a.bottom, b.bottom),
      left: BorderSide.merge(a.left, b.left),
    );
  }

  @override
  final BorderSide top;

  final BorderSide right;

  @override
  final BorderSide bottom;

  final BorderSide left;

  @override
  EdgeInsetsGeometry get dimensions {
    return new EdgeInsets.fromLTRB(
        left.width, top.width, right.width, bottom.width);
  }

  @override
  bool get isUniform {
    final Color topColor = top.color;
    if (right.color != topColor ||
        bottom.color != topColor ||
        left.color != topColor) return false;

    final double topWidth = top.width;
    if (right.width != topWidth ||
        bottom.width != topWidth ||
        left.width != topWidth) return false;

    final BorderStyle topStyle = top.style;
    if (right.style != topStyle ||
        bottom.style != topStyle ||
        left.style != topStyle) return false;

    return true;
  }

  @override
  Border add(ShapeBorder other, {bool reversed = false}) {
    if (other is! Border) return null;
    final Border typedOther = other;
    if (BorderSide.canMerge(top, typedOther.top) &&
        BorderSide.canMerge(right, typedOther.right) &&
        BorderSide.canMerge(bottom, typedOther.bottom) &&
        BorderSide.canMerge(left, typedOther.left)) {
      return Border.merge(this, typedOther);
    }
    return null;
  }

  @override
  Border scale(double t) {
    return new Border(
      top: top.scale(t),
      right: right.scale(t),
      bottom: bottom.scale(t),
      left: left.scale(t),
    );
  }

  @override
  ShapeBorder lerpFrom(ShapeBorder a, double t) {
    if (a is Border) return Border.lerp(a, this, t);
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder lerpTo(ShapeBorder b, double t) {
    if (b is Border) return Border.lerp(this, b, t);
    return super.lerpTo(b, t);
  }

  static Border lerp(Border a, Border b, double t) {
    assert(t != null);
    if (a == null && b == null) return null;
    if (a == null) return b.scale(t);
    if (b == null) return a.scale(1.0 - t);
    return new Border(
      top: BorderSide.lerp(a.top, b.top, t),
      right: BorderSide.lerp(a.right, b.right, t),
      bottom: BorderSide.lerp(a.bottom, b.bottom, t),
      left: BorderSide.lerp(a.left, b.left, t),
    );
  }

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    TextDirection textDirection,
    BoxShape shape = BoxShape.rectangle,
    BorderRadius borderRadius,
  }) {
    if (isUniform) {
      switch (top.style) {
        case BorderStyle.none:
          return;
        case BorderStyle.solid:
          switch (shape) {
            case BoxShape.circle:
              assert(borderRadius == null,
                  'A borderRadius can only be given for rectangular boxes.');
              BoxBorder._paintUniformBorderWithCircle(canvas, rect, top);
              break;
            case BoxShape.rectangle:
              if (borderRadius != null) {
                BoxBorder._paintUniformBorderWithRadius(
                    canvas, rect, top, borderRadius);
                return;
              }
              BoxBorder._paintUniformBorderWithRectangle(canvas, rect, top);
              break;
          }
          return;
      }
    }

    assert(borderRadius == null,
        'A borderRadius can only be given for uniform borders.');
    assert(shape == BoxShape.rectangle,
        'A border can only be drawn as a circle if it is uniform.');

    paintBorder(canvas, rect,
        top: top, right: right, bottom: bottom, left: left);
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (other is! Border) return false;
    final Border typedOther = other;
    return top == typedOther.top &&
        right == typedOther.right &&
        bottom == typedOther.bottom &&
        left == typedOther.left;
  }

  @override
  int get hashCode => hashValues(top, right, bottom, left);

  @override
  String toString() {
    if (assertionsEnabled) {
      if (isUniform) return '$runtimeType.all($top)';
      final List<String> arguments = <String>[];
      if (top != BorderSide.none) arguments.add('top: $top');
      if (right != BorderSide.none) arguments.add('right: $right');
      if (bottom != BorderSide.none) arguments.add('bottom: $bottom');
      if (left != BorderSide.none) arguments.add('left: $left');
      return '$runtimeType(${arguments.join(", ")})';
    } else {
      return super.toString();
    }
  }
}

class BorderDirectional extends BoxBorder {
  const BorderDirectional({
    this.top = BorderSide.none,
    this.start = BorderSide.none,
    this.end = BorderSide.none,
    this.bottom = BorderSide.none,
  })  : assert(top != null),
        assert(start != null),
        assert(end != null),
        assert(bottom != null);

  static BorderDirectional merge(BorderDirectional a, BorderDirectional b) {
    assert(a != null);
    assert(b != null);
    assert(BorderSide.canMerge(a.top, b.top));
    assert(BorderSide.canMerge(a.start, b.start));
    assert(BorderSide.canMerge(a.end, b.end));
    assert(BorderSide.canMerge(a.bottom, b.bottom));
    return new BorderDirectional(
      top: BorderSide.merge(a.top, b.top),
      start: BorderSide.merge(a.start, b.start),
      end: BorderSide.merge(a.end, b.end),
      bottom: BorderSide.merge(a.bottom, b.bottom),
    );
  }

  @override
  final BorderSide top;

  final BorderSide start;

  final BorderSide end;

  @override
  final BorderSide bottom;

  @override
  EdgeInsetsGeometry get dimensions {
    return new EdgeInsetsDirectional.fromSTEB(
        start.width, top.width, end.width, bottom.width);
  }

  @override
  bool get isUniform {
    final Color topColor = top.color;
    if (start.color != topColor ||
        end.color != topColor ||
        bottom.color != topColor) return false;

    final double topWidth = top.width;
    if (start.width != topWidth ||
        end.width != topWidth ||
        bottom.width != topWidth) return false;

    final BorderStyle topStyle = top.style;
    if (start.style != topStyle ||
        end.style != topStyle ||
        bottom.style != topStyle) return false;

    return true;
  }

  @override
  BoxBorder add(ShapeBorder other, {bool reversed = false}) {
    if (other is BorderDirectional) {
      final BorderDirectional typedOther = other;
      if (BorderSide.canMerge(top, typedOther.top) &&
          BorderSide.canMerge(start, typedOther.start) &&
          BorderSide.canMerge(end, typedOther.end) &&
          BorderSide.canMerge(bottom, typedOther.bottom)) {
        return BorderDirectional.merge(this, typedOther);
      }
      return null;
    }
    if (other is Border) {
      final Border typedOther = other;
      if (!BorderSide.canMerge(typedOther.top, top) ||
          !BorderSide.canMerge(typedOther.bottom, bottom)) return null;
      if (start != BorderSide.none || end != BorderSide.none) {
        if (typedOther.left != BorderSide.none ||
            typedOther.right != BorderSide.none) return null;
        assert(typedOther.left == BorderSide.none);
        assert(typedOther.right == BorderSide.none);
        return new BorderDirectional(
          top: BorderSide.merge(typedOther.top, top),
          start: start,
          end: end,
          bottom: BorderSide.merge(typedOther.bottom, bottom),
        );
      }
      assert(start == BorderSide.none);
      assert(end == BorderSide.none);
      return new Border(
        top: BorderSide.merge(typedOther.top, top),
        right: typedOther.right,
        bottom: BorderSide.merge(typedOther.bottom, bottom),
        left: typedOther.left,
      );
    }
    return null;
  }

  @override
  BorderDirectional scale(double t) {
    return new BorderDirectional(
      top: top.scale(t),
      start: start.scale(t),
      end: end.scale(t),
      bottom: bottom.scale(t),
    );
  }

  @override
  ShapeBorder lerpFrom(ShapeBorder a, double t) {
    if (a is BorderDirectional) return BorderDirectional.lerp(a, this, t);
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder lerpTo(ShapeBorder b, double t) {
    if (b is BorderDirectional) return BorderDirectional.lerp(this, b, t);
    return super.lerpTo(b, t);
  }

  static BorderDirectional lerp(
      BorderDirectional a, BorderDirectional b, double t) {
    assert(t != null);
    if (a == null && b == null) return null;
    if (a == null) return b.scale(t);
    if (b == null) return a.scale(1.0 - t);
    return new BorderDirectional(
      top: BorderSide.lerp(a.top, b.top, t),
      end: BorderSide.lerp(a.end, b.end, t),
      bottom: BorderSide.lerp(a.bottom, b.bottom, t),
      start: BorderSide.lerp(a.start, b.start, t),
    );
  }

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    TextDirection textDirection,
    BoxShape shape = BoxShape.rectangle,
    BorderRadius borderRadius,
  }) {
    if (isUniform) {
      switch (top.style) {
        case BorderStyle.none:
          return;
        case BorderStyle.solid:
          switch (shape) {
            case BoxShape.circle:
              assert(borderRadius == null,
                  'A borderRadius can only be given for rectangular boxes.');
              BoxBorder._paintUniformBorderWithCircle(canvas, rect, top);
              break;
            case BoxShape.rectangle:
              if (borderRadius != null) {
                BoxBorder._paintUniformBorderWithRadius(
                    canvas, rect, top, borderRadius);
                return;
              }
              BoxBorder._paintUniformBorderWithRectangle(canvas, rect, top);
              break;
          }
          return;
      }
    }

    assert(borderRadius == null,
        'A borderRadius can only be given for uniform borders.');
    assert(shape == BoxShape.rectangle,
        'A border can only be drawn as a circle if it is uniform.');

    BorderSide left, right;
    assert(
        textDirection != null,
        'Non-uniform BorderDirectional objects '
        'require a TextDirection when painting.');
    switch (textDirection) {
      case TextDirection.rtl:
        left = end;
        right = start;
        break;
      case TextDirection.ltr:
        left = start;
        right = end;
        break;
    }
    paintBorder(canvas, rect,
        top: top, left: left, bottom: bottom, right: right);
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final BorderDirectional typedOther = other;
    return top == typedOther.top &&
        start == typedOther.start &&
        end == typedOther.end &&
        bottom == typedOther.bottom;
  }

  @override
  int get hashCode => hashValues(top, start, end, bottom);

  @override
  String toString() {
    if (assertionsEnabled) {
      final List<String> arguments = <String>[];
      if (top != BorderSide.none) arguments.add('top: $top');
      if (start != BorderSide.none) arguments.add('start: $start');
      if (end != BorderSide.none) arguments.add('end: $end');
      if (bottom != BorderSide.none) arguments.add('bottom: $bottom');
      return '$runtimeType(${arguments.join(", ")})';
    } else {
      return super.toString();
    }
  }
}

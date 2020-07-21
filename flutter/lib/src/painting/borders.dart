import 'dart:math' as math;

import 'package:meta/meta.dart';

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/widgets.dart';
import 'package:flutter_web/ui.dart' as ui show lerpDouble;

import 'edge_insets.dart';

enum BorderStyle {
  none,

  solid,
}

@immutable
class BorderSide {
  const BorderSide({
    this.color = const Color(0xFF000000),
    this.width = 1.0,
    this.style = BorderStyle.solid,
  })  : assert(color != null),
        assert(width != null),
        assert(width >= 0.0),
        assert(style != null);

  static BorderSide merge(BorderSide a, BorderSide b) {
    assert(a != null);
    assert(b != null);
    assert(canMerge(a, b));
    final bool aIsNone = a.style == BorderStyle.none && a.width == 0.0;
    final bool bIsNone = b.style == BorderStyle.none && b.width == 0.0;
    if (aIsNone && bIsNone) return BorderSide.none;
    if (aIsNone) return b;
    if (bIsNone) return a;
    assert(a.color == b.color);
    assert(a.style == b.style);
    return BorderSide(
      color: a.color,
      width: a.width + b.width,
      style: a.style,
    );
  }

  final Color color;

  final double width;

  final BorderStyle style;

  static const BorderSide none =
      BorderSide(width: 0.0, style: BorderStyle.none);

  BorderSide copyWith({Color color, double width, BorderStyle style}) {
    assert(width == null || width >= 0.0);
    return BorderSide(
      color: color ?? this.color,
      width: width ?? this.width,
      style: style ?? this.style,
    );
  }

  BorderSide scale(double t) {
    assert(t != null);
    return BorderSide(
      color: color,
      width: math.max(0.0, width * t),
      style: t <= 0.0 ? BorderStyle.none : style,
    );
  }

  Paint toPaint() {
    switch (style) {
      case BorderStyle.solid:
        return Paint()
          ..color = color
          ..strokeWidth = width
          ..style = PaintingStyle.stroke;
      case BorderStyle.none:
        return Paint()
          ..color = const Color(0x00000000)
          ..strokeWidth = 0.0
          ..style = PaintingStyle.stroke;
    }
    return null;
  }

  static bool canMerge(BorderSide a, BorderSide b) {
    assert(a != null);
    assert(b != null);
    if ((a.style == BorderStyle.none && a.width == 0.0) ||
        (b.style == BorderStyle.none && b.width == 0.0)) return true;
    return a.style == b.style && a.color == b.color;
  }

  static BorderSide lerp(BorderSide a, BorderSide b, double t) {
    assert(a != null);
    assert(b != null);
    assert(t != null);
    if (t == 0.0) return a;
    if (t == 1.0) return b;
    final double width = ui.lerpDouble(a.width, b.width, t);
    if (width < 0.0) return BorderSide.none;
    if (a.style == b.style) {
      return BorderSide(
        color: Color.lerp(a.color, b.color, t),
        width: width,
        style: a.style,
      );
    }
    Color colorA, colorB;
    switch (a.style) {
      case BorderStyle.solid:
        colorA = a.color;
        break;
      case BorderStyle.none:
        colorA = a.color.withAlpha(0x00);
        break;
    }
    switch (b.style) {
      case BorderStyle.solid:
        colorB = b.color;
        break;
      case BorderStyle.none:
        colorB = b.color.withAlpha(0x00);
        break;
    }
    return BorderSide(
      color: Color.lerp(colorA, colorB, t),
      width: width,
      style: BorderStyle.solid,
    );
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final BorderSide typedOther = other;
    return color == typedOther.color &&
        width == typedOther.width &&
        style == typedOther.style;
  }

  @override
  int get hashCode => hashValues(color, width, style);

  @override
  String toString() =>
      '$runtimeType($color, ${width.toStringAsFixed(1)}, $style)';
}

@immutable
abstract class ShapeBorder {
  const ShapeBorder();

  EdgeInsetsGeometry get dimensions;

  @protected
  ShapeBorder add(ShapeBorder other, {bool reversed = false}) => null;

  ShapeBorder operator +(ShapeBorder other) {
    return add(other) ??
        other.add(this, reversed: true) ??
        _CompoundBorder(<ShapeBorder>[other, this]);
  }

  ShapeBorder scale(double t);

  @protected
  ShapeBorder lerpFrom(ShapeBorder a, double t) {
    if (a == null) return scale(t);
    return null;
  }

  @protected
  ShapeBorder lerpTo(ShapeBorder b, double t) {
    if (b == null) return scale(1.0 - t);
    return null;
  }

  static ShapeBorder lerp(ShapeBorder a, ShapeBorder b, double t) {
    assert(t != null);
    ShapeBorder result;
    if (b != null) result = b.lerpFrom(a, t);
    if (result == null && a != null) result = a.lerpTo(b, t);
    return result ?? (t < 0.5 ? a : b);
  }

  Path getOuterPath(Rect rect, {TextDirection textDirection});

  Path getInnerPath(Rect rect, {TextDirection textDirection});

  void paint(Canvas canvas, Rect rect, {TextDirection textDirection});

  @override
  String toString() {
    return '$runtimeType()';
  }
}

class _CompoundBorder extends ShapeBorder {
  _CompoundBorder(this.borders)
      : assert(borders != null),
        assert(borders.length >= 2),
        assert(!borders.any((ShapeBorder border) => border is _CompoundBorder));

  final List<ShapeBorder> borders;

  @override
  EdgeInsetsGeometry get dimensions {
    return borders.fold<EdgeInsetsGeometry>(
      EdgeInsets.zero,
      (EdgeInsetsGeometry previousValue, ShapeBorder border) {
        return previousValue.add(border.dimensions);
      },
    );
  }

  @override
  ShapeBorder add(ShapeBorder other, {bool reversed = false}) {
    if (other is! _CompoundBorder) {
      final ShapeBorder ours = reversed ? borders.last : borders.first;
      final ShapeBorder merged = ours.add(other, reversed: reversed) ??
          other.add(ours, reversed: !reversed);
      if (merged != null) {
        final List<ShapeBorder> result = <ShapeBorder>[];
        result.addAll(borders);
        result[reversed ? result.length - 1 : 0] = merged;
        return _CompoundBorder(result);
      }
    }

    final List<ShapeBorder> mergedBorders = <ShapeBorder>[];
    if (reversed) mergedBorders.addAll(borders);
    if (other is _CompoundBorder)
      mergedBorders.addAll(other.borders);
    else
      mergedBorders.add(other);
    if (!reversed) mergedBorders.addAll(borders);
    return _CompoundBorder(mergedBorders);
  }

  @override
  ShapeBorder scale(double t) {
    return _CompoundBorder(borders
        .map<ShapeBorder>((ShapeBorder border) => border.scale(t))
        .toList());
  }

  @override
  ShapeBorder lerpFrom(ShapeBorder a, double t) {
    return _CompoundBorder.lerp(a, this, t);
  }

  @override
  ShapeBorder lerpTo(ShapeBorder b, double t) {
    return _CompoundBorder.lerp(this, b, t);
  }

  static _CompoundBorder lerp(ShapeBorder a, ShapeBorder b, double t) {
    assert(t != null);
    assert(a is _CompoundBorder || b is _CompoundBorder);
    final List<ShapeBorder> aList =
        a is _CompoundBorder ? a.borders : <ShapeBorder>[a];
    final List<ShapeBorder> bList =
        b is _CompoundBorder ? b.borders : <ShapeBorder>[b];
    final List<ShapeBorder> results = <ShapeBorder>[];
    final int length = math.max(aList.length, bList.length);
    for (int index = 0; index < length; index += 1) {
      final ShapeBorder localA = index < aList.length ? aList[index] : null;
      final ShapeBorder localB = index < bList.length ? bList[index] : null;
      if (localA != null && localB != null) {
        final ShapeBorder localResult =
            localA.lerpTo(localB, t) ?? localB.lerpFrom(localA, t);
        if (localResult != null) {
          results.add(localResult);
          continue;
        }
      }

      if (localB != null) results.add(localB.scale(t));
      if (localA != null) results.add(localA.scale(1.0 - t));
    }
    return _CompoundBorder(results);
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection textDirection}) {
    for (int index = 0; index < borders.length - 1; index += 1)
      rect = borders[index].dimensions.resolve(textDirection).deflateRect(rect);
    return borders.last.getInnerPath(rect, textDirection: textDirection);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection textDirection}) {
    return borders.first.getOuterPath(rect, textDirection: textDirection);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection textDirection}) {
    for (ShapeBorder border in borders) {
      border.paint(canvas, rect, textDirection: textDirection);
      rect = border.dimensions.resolve(textDirection).deflateRect(rect);
    }
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final _CompoundBorder typedOther = other;
    if (borders == typedOther.borders) return true;
    if (borders.length != typedOther.borders.length) return false;
    for (int index = 0; index < borders.length; index += 1) {
      if (borders[index] != typedOther.borders[index]) return false;
    }
    return true;
  }

  @override
  int get hashCode => hashList(borders);

  @override
  String toString() {
    return borders.reversed
        .map<String>((ShapeBorder border) => border.toString())
        .join(' + ');
  }
}

void paintBorder(
  Canvas canvas,
  Rect rect, {
  BorderSide top = BorderSide.none,
  BorderSide right = BorderSide.none,
  BorderSide bottom = BorderSide.none,
  BorderSide left = BorderSide.none,
}) {
  assert(canvas != null);
  assert(rect != null);
  assert(top != null);
  assert(right != null);
  assert(bottom != null);
  assert(left != null);

  final Paint paint = Paint()..strokeWidth = 0.0;

  final Path path = Path();

  switch (top.style) {
    case BorderStyle.solid:
      paint.color = top.color;
      path.reset();
      path.moveTo(rect.left, rect.top);
      path.lineTo(rect.right, rect.top);
      if (top.width == 0.0) {
        paint.style = PaintingStyle.stroke;
      } else {
        paint.style = PaintingStyle.fill;
        path.lineTo(rect.right - right.width, rect.top + top.width);
        path.lineTo(rect.left + left.width, rect.top + top.width);
      }
      canvas.drawPath(path, paint);
      break;
    case BorderStyle.none:
      break;
  }

  switch (right.style) {
    case BorderStyle.solid:
      paint.color = right.color;
      path.reset();
      path.moveTo(rect.right, rect.top);
      path.lineTo(rect.right, rect.bottom);
      if (right.width == 0.0) {
        paint.style = PaintingStyle.stroke;
      } else {
        paint.style = PaintingStyle.fill;
        path.lineTo(rect.right - right.width, rect.bottom - bottom.width);
        path.lineTo(rect.right - right.width, rect.top + top.width);
      }
      canvas.drawPath(path, paint);
      break;
    case BorderStyle.none:
      break;
  }

  switch (bottom.style) {
    case BorderStyle.solid:
      paint.color = bottom.color;
      path.reset();
      path.moveTo(rect.right, rect.bottom);
      path.lineTo(rect.left, rect.bottom);
      if (bottom.width == 0.0) {
        paint.style = PaintingStyle.stroke;
      } else {
        paint.style = PaintingStyle.fill;
        path.lineTo(rect.left + left.width, rect.bottom - bottom.width);
        path.lineTo(rect.right - right.width, rect.bottom - bottom.width);
      }
      canvas.drawPath(path, paint);
      break;
    case BorderStyle.none:
      break;
  }

  switch (left.style) {
    case BorderStyle.solid:
      paint.color = left.color;
      path.reset();
      path.moveTo(rect.left, rect.bottom);
      path.lineTo(rect.left, rect.top);
      if (left.width == 0.0) {
        paint.style = PaintingStyle.stroke;
      } else {
        paint.style = PaintingStyle.fill;
        path.lineTo(rect.left + left.width, rect.top + top.width);
        path.lineTo(rect.left + left.width, rect.bottom - bottom.width);
      }
      canvas.drawPath(path, paint);
      break;
    case BorderStyle.none:
      break;
  }
}

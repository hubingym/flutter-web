import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/painting.dart' hide Border;

@immutable
class TableBorder {
  const TableBorder({
    this.top = BorderSide.none,
    this.right = BorderSide.none,
    this.bottom = BorderSide.none,
    this.left = BorderSide.none,
    this.horizontalInside = BorderSide.none,
    this.verticalInside = BorderSide.none,
  });

  factory TableBorder.all({
    Color color = const Color(0xFF000000),
    double width = 1.0,
    BorderStyle style = BorderStyle.solid,
  }) {
    final BorderSide side =
        BorderSide(color: color, width: width, style: style);
    return TableBorder(
        top: side,
        right: side,
        bottom: side,
        left: side,
        horizontalInside: side,
        verticalInside: side);
  }

  factory TableBorder.symmetric({
    BorderSide inside = BorderSide.none,
    BorderSide outside = BorderSide.none,
  }) {
    return TableBorder(
      top: outside,
      right: outside,
      bottom: outside,
      left: outside,
      horizontalInside: inside,
      verticalInside: inside,
    );
  }

  final BorderSide top;

  final BorderSide right;

  final BorderSide bottom;

  final BorderSide left;

  final BorderSide horizontalInside;

  final BorderSide verticalInside;

  EdgeInsets get dimensions {
    return EdgeInsets.fromLTRB(
        left.width, top.width, right.width, bottom.width);
  }

  bool get isUniform {
    assert(top != null);
    assert(right != null);
    assert(bottom != null);
    assert(left != null);
    assert(horizontalInside != null);
    assert(verticalInside != null);

    final Color topColor = top.color;
    if (right.color != topColor ||
        bottom.color != topColor ||
        left.color != topColor ||
        horizontalInside.color != topColor ||
        verticalInside.color != topColor) return false;

    final double topWidth = top.width;
    if (right.width != topWidth ||
        bottom.width != topWidth ||
        left.width != topWidth ||
        horizontalInside.width != topWidth ||
        verticalInside.width != topWidth) return false;

    final BorderStyle topStyle = top.style;
    if (right.style != topStyle ||
        bottom.style != topStyle ||
        left.style != topStyle ||
        horizontalInside.style != topStyle ||
        verticalInside.style != topStyle) return false;

    return true;
  }

  TableBorder scale(double t) {
    return TableBorder(
      top: top.scale(t),
      right: right.scale(t),
      bottom: bottom.scale(t),
      left: left.scale(t),
      horizontalInside: horizontalInside.scale(t),
      verticalInside: verticalInside.scale(t),
    );
  }

  static TableBorder lerp(TableBorder a, TableBorder b, double t) {
    assert(t != null);
    if (a == null && b == null) return null;
    if (a == null) return b.scale(t);
    if (b == null) return a.scale(1.0 - t);
    return TableBorder(
      top: BorderSide.lerp(a.top, b.top, t),
      right: BorderSide.lerp(a.right, b.right, t),
      bottom: BorderSide.lerp(a.bottom, b.bottom, t),
      left: BorderSide.lerp(a.left, b.left, t),
      horizontalInside:
          BorderSide.lerp(a.horizontalInside, b.horizontalInside, t),
      verticalInside: BorderSide.lerp(a.verticalInside, b.verticalInside, t),
    );
  }

  void paint(
    Canvas canvas,
    Rect rect, {
    @required Iterable<double> rows,
    @required Iterable<double> columns,
  }) {
    assert(top != null);
    assert(right != null);
    assert(bottom != null);
    assert(left != null);
    assert(horizontalInside != null);
    assert(verticalInside != null);

    assert(canvas != null);
    assert(rect != null);
    assert(rows != null);
    assert(rows.isEmpty || (rows.first >= 0.0 && rows.last <= rect.height));
    assert(columns != null);
    assert(columns.isEmpty ||
        (columns.first >= 0.0 && columns.last <= rect.width));

    if (columns.isNotEmpty || rows.isNotEmpty) {
      final Paint paint = Paint();
      final Path path = Path();

      if (columns.isNotEmpty) {
        switch (verticalInside.style) {
          case BorderStyle.solid:
            paint
              ..color = verticalInside.color
              ..strokeWidth = verticalInside.width
              ..style = PaintingStyle.stroke;
            path.reset();
            for (double x in columns) {
              path.moveTo(rect.left + x, rect.top);
              path.lineTo(rect.left + x, rect.bottom);
            }
            canvas.drawPath(path, paint);
            break;
          case BorderStyle.none:
            break;
        }
      }

      if (rows.isNotEmpty) {
        switch (horizontalInside.style) {
          case BorderStyle.solid:
            paint
              ..color = horizontalInside.color
              ..strokeWidth = horizontalInside.width
              ..style = PaintingStyle.stroke;
            path.reset();
            for (double y in rows) {
              path.moveTo(rect.left, rect.top + y);
              path.lineTo(rect.right, rect.top + y);
            }
            canvas.drawPath(path, paint);
            break;
          case BorderStyle.none:
            break;
        }
      }
    }
    paintBorder(canvas, rect,
        top: top, right: right, bottom: bottom, left: left);
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final TableBorder typedOther = other;
    return top == typedOther.top &&
        right == typedOther.right &&
        bottom == typedOther.bottom &&
        left == typedOther.left &&
        horizontalInside == typedOther.horizontalInside &&
        verticalInside == typedOther.verticalInside;
  }

  @override
  int get hashCode =>
      hashValues(top, right, bottom, left, horizontalInside, verticalInside);

  @override
  String toString() =>
      'TableBorder($top, $right, $bottom, $left, $horizontalInside, $verticalInside)';
}

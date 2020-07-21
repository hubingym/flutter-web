import 'package:flutter_web/src/util.dart';

import 'package:flutter_web/painting.dart';
import 'package:flutter_web/ui.dart';

abstract class EdgeInsetsGeometry {
  const EdgeInsetsGeometry();

  double get bottom;
  double get end;
  double get left;
  double get right;
  double get start;
  double get top;

  bool get isNonNegative {
    return left >= 0.0 &&
        right >= 0.0 &&
        start >= 0.0 &&
        end >= 0.0 &&
        top >= 0.0 &&
        bottom >= 0.0;
  }

  double get horizontal => left + right + start + end;

  double get vertical => top + bottom;

  double along(Axis axis) {
    assert(axis != null);
    switch (axis) {
      case Axis.horizontal:
        return horizontal;
      case Axis.vertical:
        return vertical;
    }
    return null;
  }

  Size get collapsedSize => new Size(horizontal, vertical);

  EdgeInsetsGeometry get flipped =>
      new _MixedEdgeInsets.fromLRSETB(right, left, end, start, bottom, top);

  Size inflateSize(Size size) {
    return new Size(size.width + horizontal, size.height + vertical);
  }

  Size deflateSize(Size size) {
    return new Size(size.width - horizontal, size.height - vertical);
  }

  EdgeInsetsGeometry subtract(EdgeInsetsGeometry other) {
    return new _MixedEdgeInsets.fromLRSETB(
      left - other.left,
      right - other.right,
      start - other.start,
      end - other.end,
      top - other.top,
      bottom - other.bottom,
    );
  }

  EdgeInsetsGeometry add(EdgeInsetsGeometry other) {
    return new _MixedEdgeInsets.fromLRSETB(
      left + other.left,
      right + other.right,
      start + other.start,
      end + other.end,
      top + other.top,
      bottom + other.bottom,
    );
  }

  EdgeInsetsGeometry operator -();

  EdgeInsetsGeometry operator *(double other);

  EdgeInsetsGeometry operator /(double other);

  EdgeInsetsGeometry operator ~/(double other);

  EdgeInsetsGeometry operator %(double other);

  static EdgeInsetsGeometry lerp(
      EdgeInsetsGeometry a, EdgeInsetsGeometry b, double t) {
    assert(t != null);
    if (a == null && b == null) return null;
    if (a == null) return b * t;
    if (b == null) return a * (1.0 - t);
    if (a is EdgeInsets && b is EdgeInsets) return EdgeInsets.lerp(a, b, t);
    if (a is EdgeInsetsDirectional && b is EdgeInsetsDirectional)
      return EdgeInsetsDirectional.lerp(a, b, t);
    return new _MixedEdgeInsets.fromLRSETB(
      lerpDouble(a.left, b.left, t),
      lerpDouble(a.right, b.right, t),
      lerpDouble(a.start, b.start, t),
      lerpDouble(a.end, b.end, t),
      lerpDouble(a.top, b.top, t),
      lerpDouble(a.bottom, b.bottom, t),
    );
  }

  EdgeInsets resolve(TextDirection direction);

  @override
  String toString() {
    if (assertionsEnabled) {
      if (start == 0.0 && end == 0.0) {
        if (left == 0.0 && right == 0.0 && top == 0.0 && bottom == 0.0)
          return 'EdgeInsets.zero';
        if (left == right && right == top && top == bottom)
          return 'EdgeInsets.all(${left.toStringAsFixed(1)})';
        return 'EdgeInsets(${left.toStringAsFixed(1)}, '
            '${top.toStringAsFixed(1)}, '
            '${right.toStringAsFixed(1)}, '
            '${bottom.toStringAsFixed(1)})';
      }
      if (left == 0.0 && right == 0.0) {
        return 'EdgeInsetsDirectional(${start.toStringAsFixed(1)}, '
            '${top.toStringAsFixed(1)}, '
            '${end.toStringAsFixed(1)}, '
            '${bottom.toStringAsFixed(1)})';
      }
      return 'EdgeInsets(${left.toStringAsFixed(1)}, '
          '${top.toStringAsFixed(1)}, '
          '${right.toStringAsFixed(1)}, '
          '${bottom.toStringAsFixed(1)})'
          ' + '
          'EdgeInsetsDirectional(${start.toStringAsFixed(1)}, '
          '0.0, '
          '${end.toStringAsFixed(1)}, '
          '0.0)';
    } else {
      return super.toString();
    }
  }

  @override
  bool operator ==(dynamic other) {
    if (other is! EdgeInsetsGeometry) return false;
    final EdgeInsetsGeometry typedOther = other;
    return left == typedOther.left &&
        right == typedOther.right &&
        start == typedOther.start &&
        end == typedOther.end &&
        top == typedOther.top &&
        bottom == typedOther.bottom;
  }

  @override
  int get hashCode => hashValues(left, right, start, end, top, bottom);
}

class EdgeInsets extends EdgeInsetsGeometry {
  const EdgeInsets.fromLTRB(this._left, this._top, this._right, this._bottom);

  const EdgeInsets.all(double value)
      : _left = value,
        _top = value,
        _right = value,
        _bottom = value;

  const EdgeInsets.only(
      {double left = 0.0,
      double top = 0.0,
      double right = 0.0,
      double bottom = 0.0})
      : _left = left,
        _top = top,
        _right = right,
        _bottom = bottom;

  const EdgeInsets.symmetric({double vertical = 0.0, double horizontal = 0.0})
      : _left = horizontal,
        _top = vertical,
        _right = horizontal,
        _bottom = vertical;

  EdgeInsets.fromWindowPadding(WindowPadding padding, double devicePixelRatio)
      : _left = padding.left / devicePixelRatio,
        _top = padding.top / devicePixelRatio,
        _right = padding.right / devicePixelRatio,
        _bottom = padding.bottom / devicePixelRatio;

  static const EdgeInsets zero = const EdgeInsets.only();

  final double _left;

  @override
  double get left => _left;

  final double _top;

  @override
  double get top => _top;

  final double _right;

  @override
  double get right => _right;

  final double _bottom;

  @override
  double get bottom => _bottom;

  @override
  double get start => 0.0;

  @override
  double get end => 0.0;

  Offset get topLeft => new Offset(left, top);

  Offset get topRight => new Offset(-right, top);

  Offset get bottomLeft => new Offset(left, -bottom);

  Offset get bottomRight => new Offset(-right, -bottom);

  @override
  EdgeInsets get flipped => new EdgeInsets.fromLTRB(right, bottom, left, top);

  Rect inflateRect(Rect rect) {
    return new Rect.fromLTRB(rect.left - left, rect.top - top,
        rect.right + right, rect.bottom + bottom);
  }

  Rect deflateRect(Rect rect) {
    return new Rect.fromLTRB(rect.left + left, rect.top + top,
        rect.right - right, rect.bottom - bottom);
  }

  @override
  EdgeInsetsGeometry subtract(EdgeInsetsGeometry other) {
    if (other is EdgeInsets) return this - other;
    return super.subtract(other);
  }

  @override
  EdgeInsetsGeometry add(EdgeInsetsGeometry other) {
    if (other is EdgeInsets) return this + other;
    return super.add(other);
  }

  EdgeInsets operator -(EdgeInsets other) {
    return new EdgeInsets.fromLTRB(
      left - other.left,
      top - other.top,
      right - other.right,
      bottom - other.bottom,
    );
  }

  EdgeInsets operator +(EdgeInsets other) {
    return new EdgeInsets.fromLTRB(
      left + other.left,
      top + other.top,
      right + other.right,
      bottom + other.bottom,
    );
  }

  @override
  EdgeInsets operator -() {
    return new EdgeInsets.fromLTRB(
      -left,
      -top,
      -right,
      -bottom,
    );
  }

  @override
  EdgeInsets operator *(double other) {
    return new EdgeInsets.fromLTRB(
      left * other,
      top * other,
      right * other,
      bottom * other,
    );
  }

  @override
  EdgeInsets operator /(double other) {
    return new EdgeInsets.fromLTRB(
      left / other,
      top / other,
      right / other,
      bottom / other,
    );
  }

  @override
  EdgeInsets operator ~/(double other) {
    return new EdgeInsets.fromLTRB(
      (left ~/ other).toDouble(),
      (top ~/ other).toDouble(),
      (right ~/ other).toDouble(),
      (bottom ~/ other).toDouble(),
    );
  }

  @override
  EdgeInsets operator %(double other) {
    return new EdgeInsets.fromLTRB(
      left % other,
      top % other,
      right % other,
      bottom % other,
    );
  }

  static EdgeInsets lerp(EdgeInsets a, EdgeInsets b, double t) {
    assert(t != null);
    if (a == null && b == null) return null;
    if (a == null) return b * t;
    if (b == null) return a * (1.0 - t);
    return new EdgeInsets.fromLTRB(
      lerpDouble(a.left, b.left, t),
      lerpDouble(a.top, b.top, t),
      lerpDouble(a.right, b.right, t),
      lerpDouble(a.bottom, b.bottom, t),
    );
  }

  @override
  EdgeInsets resolve(TextDirection direction) => this;

  EdgeInsets copyWith({
    double left,
    double top,
    double right,
    double bottom,
  }) {
    return new EdgeInsets.only(
      left: left ?? this.left,
      top: top ?? this.top,
      right: right ?? this.right,
      bottom: bottom ?? this.bottom,
    );
  }
}

class EdgeInsetsDirectional extends EdgeInsetsGeometry {
  const EdgeInsetsDirectional.fromSTEB(
      this._start, this._top, this._end, this._bottom);

  const EdgeInsetsDirectional.only(
      {double start = 0.0,
      double top = 0.0,
      double end = 0.0,
      double bottom = 0.0})
      : _start = start,
        _top = top,
        _end = end,
        _bottom = bottom;

  static const EdgeInsetsDirectional zero = const EdgeInsetsDirectional.only();

  final double _start;

  @override
  double get start => _start;

  final double _top;

  @override
  double get top => _top;

  final double _end;

  @override
  double get end => _end;

  final double _bottom;

  @override
  double get bottom => _bottom;

  @override
  double get left => 0.0;

  @override
  double get right => 0.0;

  @override
  bool get isNonNegative =>
      start >= 0.0 && top >= 0.0 && end >= 0.0 && bottom >= 0.0;

  @override
  EdgeInsetsDirectional get flipped =>
      new EdgeInsetsDirectional.fromSTEB(end, bottom, start, top);

  @override
  EdgeInsetsGeometry subtract(EdgeInsetsGeometry other) {
    if (other is EdgeInsetsDirectional) return this - other;
    return super.subtract(other);
  }

  @override
  EdgeInsetsGeometry add(EdgeInsetsGeometry other) {
    if (other is EdgeInsetsDirectional) return this + other;
    return super.add(other);
  }

  EdgeInsetsDirectional operator -(EdgeInsetsDirectional other) {
    return new EdgeInsetsDirectional.fromSTEB(
      start - other.start,
      top - other.top,
      end - other.end,
      bottom - other.bottom,
    );
  }

  EdgeInsetsDirectional operator +(EdgeInsetsDirectional other) {
    return new EdgeInsetsDirectional.fromSTEB(
      start + other.start,
      top + other.top,
      end + other.end,
      bottom + other.bottom,
    );
  }

  @override
  EdgeInsetsDirectional operator -() {
    return new EdgeInsetsDirectional.fromSTEB(
      -start,
      -top,
      -end,
      -bottom,
    );
  }

  @override
  EdgeInsetsDirectional operator *(double other) {
    return new EdgeInsetsDirectional.fromSTEB(
      start * other,
      top * other,
      end * other,
      bottom * other,
    );
  }

  @override
  EdgeInsetsDirectional operator /(double other) {
    return new EdgeInsetsDirectional.fromSTEB(
      start / other,
      top / other,
      end / other,
      bottom / other,
    );
  }

  @override
  EdgeInsetsDirectional operator ~/(double other) {
    return new EdgeInsetsDirectional.fromSTEB(
      (start ~/ other).toDouble(),
      (top ~/ other).toDouble(),
      (end ~/ other).toDouble(),
      (bottom ~/ other).toDouble(),
    );
  }

  @override
  EdgeInsetsDirectional operator %(double other) {
    return new EdgeInsetsDirectional.fromSTEB(
      start % other,
      top % other,
      end % other,
      bottom % other,
    );
  }

  static EdgeInsetsDirectional lerp(
      EdgeInsetsDirectional a, EdgeInsetsDirectional b, double t) {
    assert(t != null);
    if (a == null && b == null) return null;
    if (a == null) return b * t;
    if (b == null) return a * (1.0 - t);
    return new EdgeInsetsDirectional.fromSTEB(
      lerpDouble(a.start, b.start, t),
      lerpDouble(a.top, b.top, t),
      lerpDouble(a.end, b.end, t),
      lerpDouble(a.bottom, b.bottom, t),
    );
  }

  @override
  EdgeInsets resolve(TextDirection direction) {
    assert(direction != null);
    switch (direction) {
      case TextDirection.rtl:
        return new EdgeInsets.fromLTRB(end, top, start, bottom);
      case TextDirection.ltr:
        return new EdgeInsets.fromLTRB(start, top, end, bottom);
    }
    return null;
  }
}

class _MixedEdgeInsets extends EdgeInsetsGeometry {
  const _MixedEdgeInsets.fromLRSETB(
      this.left, this.right, this.start, this.end, this.top, this.bottom);

  @override
  final double left;

  @override
  final double right;

  @override
  final double start;

  @override
  final double end;

  @override
  final double top;

  @override
  final double bottom;

  @override
  bool get isNonNegative {
    return left >= 0.0 &&
        right >= 0.0 &&
        start >= 0.0 &&
        end >= 0.0 &&
        top >= 0.0 &&
        bottom >= 0.0;
  }

  @override
  _MixedEdgeInsets operator -() {
    return new _MixedEdgeInsets.fromLRSETB(
      -left,
      -right,
      -start,
      -end,
      -top,
      -bottom,
    );
  }

  @override
  _MixedEdgeInsets operator *(double other) {
    return new _MixedEdgeInsets.fromLRSETB(
      left * other,
      right * other,
      start * other,
      end * other,
      top * other,
      bottom * other,
    );
  }

  @override
  _MixedEdgeInsets operator /(double other) {
    return new _MixedEdgeInsets.fromLRSETB(
      left / other,
      right / other,
      start / other,
      end / other,
      top / other,
      bottom / other,
    );
  }

  @override
  _MixedEdgeInsets operator ~/(double other) {
    return new _MixedEdgeInsets.fromLRSETB(
      (left ~/ other).toDouble(),
      (right ~/ other).toDouble(),
      (start ~/ other).toDouble(),
      (end ~/ other).toDouble(),
      (top ~/ other).toDouble(),
      (bottom ~/ other).toDouble(),
    );
  }

  @override
  _MixedEdgeInsets operator %(double other) {
    return new _MixedEdgeInsets.fromLRSETB(
      left % other,
      right % other,
      start % other,
      end % other,
      top % other,
      bottom % other,
    );
  }

  @override
  EdgeInsets resolve(TextDirection direction) {
    assert(direction != null);
    switch (direction) {
      case TextDirection.rtl:
        return new EdgeInsets.fromLTRB(end + left, top, start + right, bottom);
      case TextDirection.ltr:
        return new EdgeInsets.fromLTRB(start + left, top, end + right, bottom);
    }
    return null;
  }
}

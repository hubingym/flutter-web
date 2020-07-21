import 'dart:math' as math;

import 'package:flutter_web/widgets.dart';
import 'package:flutter_web/ui.dart';

abstract class InputBorder extends ShapeBorder {
  static const InputBorder none = const _NoInputBorder();

  const InputBorder({
    this.borderSide = BorderSide.none,
  });

  final BorderSide borderSide;

  InputBorder copyWith({BorderSide borderSide});

  bool get isOutline;

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double gapStart,
    double gapExtent = 0.0,
    double gapPercentage = 0.0,
    TextDirection textDirection,
  });
}

class _NoInputBorder extends InputBorder {
  const _NoInputBorder() : super(borderSide: BorderSide.none);

  @override
  _NoInputBorder copyWith({BorderSide borderSide}) => const _NoInputBorder();

  @override
  bool get isOutline => false;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  _NoInputBorder scale(double t) => const _NoInputBorder();

  @override
  Path getInnerPath(Rect rect, {TextDirection textDirection}) {
    return new Path()..addRect(rect);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection textDirection}) {
    return new Path()..addRect(rect);
  }

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double gapStart,
    double gapExtent = 0.0,
    double gapPercentage = 0.0,
    TextDirection textDirection,
  }) {}
}

class UnderlineInputBorder extends InputBorder {
  const UnderlineInputBorder({
    BorderSide borderSide = const BorderSide(),
    this.borderRadius = const BorderRadius.only(
      topLeft: Radius.circular(4.0),
      topRight: Radius.circular(4.0),
    ),
  })  : assert(borderRadius != null),
        super(borderSide: borderSide);

  final BorderRadius borderRadius;

  @override
  bool get isOutline => false;

  @override
  UnderlineInputBorder copyWith(
      {BorderSide borderSide, BorderRadius borderRadius}) {
    return UnderlineInputBorder(
      borderSide: borderSide ?? this.borderSide,
      borderRadius: borderRadius ?? this.borderRadius,
    );
  }

  @override
  EdgeInsetsGeometry get dimensions {
    return EdgeInsets.only(bottom: borderSide.width);
  }

  @override
  UnderlineInputBorder scale(double t) {
    return UnderlineInputBorder(borderSide: borderSide.scale(t));
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection textDirection}) {
    return Path()
      ..addRect(Rect.fromLTWH(rect.left, rect.top, rect.width,
          math.max(0.0, rect.height - borderSide.width)));
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection textDirection}) {
    return Path()..addRRect(borderRadius.resolve(textDirection).toRRect(rect));
  }

  @override
  ShapeBorder lerpFrom(ShapeBorder a, double t) {
    if (a is UnderlineInputBorder) {
      return UnderlineInputBorder(
        borderSide: BorderSide.lerp(a.borderSide, borderSide, t),
        borderRadius: BorderRadius.lerp(a.borderRadius, borderRadius, t),
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder lerpTo(ShapeBorder b, double t) {
    if (b is UnderlineInputBorder) {
      return UnderlineInputBorder(
        borderSide: BorderSide.lerp(borderSide, b.borderSide, t),
        borderRadius: BorderRadius.lerp(borderRadius, b.borderRadius, t),
      );
    }
    return super.lerpTo(b, t);
  }

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double gapStart,
    double gapExtent = 0.0,
    double gapPercentage = 0.0,
    TextDirection textDirection,
  }) {
    if (borderRadius.bottomLeft != Radius.zero ||
        borderRadius.bottomRight != Radius.zero)
      canvas.clipPath(getOuterPath(rect, textDirection: textDirection));
    canvas.drawLine(rect.bottomLeft, rect.bottomRight, borderSide.toPaint());
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final InputBorder typedOther = other;
    return typedOther.borderSide == borderSide;
  }

  @override
  int get hashCode => borderSide.hashCode;
}

class OutlineInputBorder extends InputBorder {
  const OutlineInputBorder({
    BorderSide borderSide = const BorderSide(),
    this.borderRadius = const BorderRadius.all(Radius.circular(4.0)),
    this.gapPadding = 4.0,
  })  : assert(borderRadius != null),
        assert(gapPadding != null && gapPadding >= 0.0),
        super(borderSide: borderSide);

  static bool _cornersAreCircular(BorderRadius borderRadius) {
    return borderRadius.topLeft.x == borderRadius.topLeft.y &&
        borderRadius.bottomLeft.x == borderRadius.bottomLeft.y &&
        borderRadius.topRight.x == borderRadius.topRight.y &&
        borderRadius.bottomRight.x == borderRadius.bottomRight.y;
  }

  final double gapPadding;

  final BorderRadius borderRadius;

  @override
  bool get isOutline => true;

  @override
  OutlineInputBorder copyWith({
    BorderSide borderSide,
    BorderRadius borderRadius,
    double gapPadding,
  }) {
    return OutlineInputBorder(
      borderSide: borderSide ?? this.borderSide,
      borderRadius: borderRadius ?? this.borderRadius,
      gapPadding: gapPadding ?? this.gapPadding,
    );
  }

  @override
  EdgeInsetsGeometry get dimensions {
    return EdgeInsets.all(borderSide.width);
  }

  @override
  OutlineInputBorder scale(double t) {
    return OutlineInputBorder(
      borderSide: borderSide.scale(t),
      borderRadius: borderRadius * t,
      gapPadding: gapPadding * t,
    );
  }

  @override
  ShapeBorder lerpFrom(ShapeBorder a, double t) {
    if (a is OutlineInputBorder) {
      final OutlineInputBorder outline = a;
      return OutlineInputBorder(
        borderRadius: BorderRadius.lerp(outline.borderRadius, borderRadius, t),
        borderSide: BorderSide.lerp(outline.borderSide, borderSide, t),
        gapPadding: outline.gapPadding,
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder lerpTo(ShapeBorder b, double t) {
    if (b is OutlineInputBorder) {
      final OutlineInputBorder outline = b;
      return OutlineInputBorder(
        borderRadius: BorderRadius.lerp(borderRadius, outline.borderRadius, t),
        borderSide: BorderSide.lerp(borderSide, outline.borderSide, t),
        gapPadding: outline.gapPadding,
      );
    }
    return super.lerpTo(b, t);
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection textDirection}) {
    return Path()
      ..addRRect(borderRadius
          .resolve(textDirection)
          .toRRect(rect)
          .deflate(borderSide.width));
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection textDirection}) {
    return Path()..addRRect(borderRadius.resolve(textDirection).toRRect(rect));
  }

  Path _gapBorderPath(
      Canvas canvas, RRect center, double start, double extent) {
    final Rect tlCorner = Rect.fromLTWH(
      center.left,
      center.top,
      center.tlRadiusX * 2.0,
      center.tlRadiusY * 2.0,
    );
    final Rect trCorner = Rect.fromLTWH(
      center.right - center.trRadiusX * 2.0,
      center.top,
      center.trRadiusX * 2.0,
      center.trRadiusY * 2.0,
    );
    final Rect brCorner = Rect.fromLTWH(
      center.right - center.brRadiusX * 2.0,
      center.bottom - center.brRadiusY * 2.0,
      center.brRadiusX * 2.0,
      center.brRadiusY * 2.0,
    );
    final Rect blCorner = Rect.fromLTWH(
      center.left,
      center.bottom - center.brRadiusY * 2.0,
      center.blRadiusX * 2.0,
      center.blRadiusY * 2.0,
    );

    const double cornerArcSweep = math.pi / 2.0;
    final double tlCornerArcSweep = start < center.tlRadiusX
        ? math.asin(start / center.tlRadiusX)
        : math.pi / 2.0;

    final Path path = Path()
      ..addArc(tlCorner, math.pi, tlCornerArcSweep)
      ..moveTo(center.left + center.tlRadiusX, center.top);

    if (start > center.tlRadiusX) path.lineTo(center.left + start, center.top);

    const double trCornerArcStart = (3 * math.pi) / 2.0;
    const double trCornerArcSweep = cornerArcSweep;
    if (start + extent < center.width - center.trRadiusX) {
      path
        ..relativeMoveTo(extent, 0.0)
        ..lineTo(center.right - center.trRadiusX, center.top)
        ..addArc(trCorner, trCornerArcStart, trCornerArcSweep);
    } else if (start + extent < center.width) {
      final double dx = center.width - (start + extent);
      final double sweep = math.acos(dx / center.trRadiusX);
      path.addArc(trCorner, trCornerArcStart + sweep, trCornerArcSweep - sweep);
    }

    return path
      ..moveTo(center.right, center.top + center.trRadiusY)
      ..lineTo(center.right, center.bottom - center.brRadiusY)
      ..addArc(brCorner, 0.0, cornerArcSweep)
      ..lineTo(center.left + center.blRadiusX, center.bottom)
      ..addArc(blCorner, math.pi / 2.0, cornerArcSweep)
      ..lineTo(center.left, center.top + center.trRadiusY);
  }

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double gapStart,
    double gapExtent = 0.0,
    double gapPercentage = 0.0,
    TextDirection textDirection,
  }) {
    assert(gapExtent != null);
    assert(gapPercentage >= 0.0 && gapPercentage <= 1.0);
    assert(_cornersAreCircular(borderRadius));

    final Paint paint = borderSide.toPaint();
    final RRect outer = borderRadius.toRRect(rect);
    final RRect center = outer.deflate(borderSide.width / 2.0);
    if (gapStart == null || gapExtent <= 0.0 || gapPercentage == 0.0) {
      canvas.drawRRect(center, paint);
    } else {
      final double extent =
          lerpDouble(0.0, gapExtent + gapPadding * 2.0, gapPercentage);
      switch (textDirection) {
        case TextDirection.rtl:
          {
            final Path path = _gapBorderPath(
                canvas, center, gapStart + gapPadding - extent, extent);
            canvas.drawPath(path, paint);
            break;
          }
        case TextDirection.ltr:
          {
            final Path path =
                _gapBorderPath(canvas, center, gapStart - gapPadding, extent);
            canvas.drawPath(path, paint);
            break;
          }
      }
    }
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final OutlineInputBorder typedOther = other;
    return typedOther.borderSide == borderSide &&
        typedOther.borderRadius == borderRadius &&
        typedOther.gapPadding == gapPadding;
  }

  @override
  int get hashCode => hashValues(borderSide, borderRadius, gapPadding);
}

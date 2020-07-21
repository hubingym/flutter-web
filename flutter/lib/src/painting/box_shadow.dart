import 'dart:math' as math;
import 'package:flutter_web/ui.dart' as ui show Shadow, lerpDouble;

import 'package:flutter_web/foundation.dart';

import 'basic_types.dart';
import 'debug.dart';

@immutable
class BoxShadow extends ui.Shadow {
  const BoxShadow({
    Color color = const Color(0xFF000000),
    Offset offset = Offset.zero,
    double blurRadius = 0.0,
    this.spreadRadius = 0.0,
  }) : super(color: color, offset: offset, blurRadius: blurRadius);

  final double spreadRadius;

  @override
  Paint toPaint() {
    final Paint result = Paint()
      ..color = color
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma);
    assert(() {
      if (debugDisableShadows) result.maskFilter = null;
      return true;
    }());
    return result;
  }

  @override
  BoxShadow scale(double factor) {
    return BoxShadow(
      color: color,
      offset: offset * factor,
      blurRadius: blurRadius * factor,
      spreadRadius: spreadRadius * factor,
    );
  }

  static BoxShadow lerp(BoxShadow a, BoxShadow b, double t) {
    assert(t != null);
    if (a == null && b == null) return null;
    if (a == null) return b.scale(t);
    if (b == null) return a.scale(1.0 - t);
    return BoxShadow(
      color: Color.lerp(a.color, b.color, t),
      offset: Offset.lerp(a.offset, b.offset, t),
      blurRadius: ui.lerpDouble(a.blurRadius, b.blurRadius, t),
      spreadRadius: ui.lerpDouble(a.spreadRadius, b.spreadRadius, t),
    );
  }

  static List<BoxShadow> lerpList(
      List<BoxShadow> a, List<BoxShadow> b, double t) {
    assert(t != null);
    if (a == null && b == null) return null;
    a ??= <BoxShadow>[];
    b ??= <BoxShadow>[];
    final List<BoxShadow> result = <BoxShadow>[];
    final int commonLength = math.min(a.length, b.length);
    for (int i = 0; i < commonLength; i += 1)
      result.add(BoxShadow.lerp(a[i], b[i], t));
    for (int i = commonLength; i < a.length; i += 1)
      result.add(a[i].scale(1.0 - t));
    for (int i = commonLength; i < b.length; i += 1) result.add(b[i].scale(t));
    return result;
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final BoxShadow typedOther = other;
    return color == typedOther.color &&
        offset == typedOther.offset &&
        blurRadius == typedOther.blurRadius &&
        spreadRadius == typedOther.spreadRadius;
  }

  @override
  int get hashCode => hashValues(color, offset, blurRadius, spreadRadius);

  @override
  String toString() =>
      'BoxShadow($color, $offset, ${debugFormatDouble(blurRadius)}, ${debugFormatDouble(spreadRadius)})';
}

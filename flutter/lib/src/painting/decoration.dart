import 'package:flutter_web/foundation.dart';

import 'basic_types.dart';
import 'edge_insets.dart';
import 'image_provider.dart';

@immutable
abstract class Decoration extends Diagnosticable {
  const Decoration();

  @override
  String toStringShort() => '$runtimeType';

  bool debugAssertIsValid() => true;

  EdgeInsetsGeometry get padding => EdgeInsets.zero;

  bool get isComplex => false;

  @protected
  Decoration lerpFrom(Decoration a, double t) => null;

  @protected
  Decoration lerpTo(Decoration b, double t) => null;

  static Decoration lerp(Decoration a, Decoration b, double t) {
    assert(t != null);
    if (a == null && b == null) return null;
    if (a == null) return b.lerpFrom(null, t) ?? b;
    if (b == null) return a.lerpTo(null, t) ?? a;
    if (t == 0.0) return a;
    if (t == 1.0) return b;
    return b.lerpFrom(a, t) ??
        a.lerpTo(b, t) ??
        (t < 0.5
            ? (a.lerpTo(null, t * 2.0) ?? a)
            : (b.lerpFrom(null, (t - 0.5) * 2.0) ?? b));
  }

  bool hitTest(Size size, Offset position, {TextDirection textDirection}) =>
      true;

  BoxPainter createBoxPainter([VoidCallback onChanged]);
}

abstract class BoxPainter {
  const BoxPainter([this.onChanged]);

  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration);

  final VoidCallback onChanged;

  @mustCallSuper
  void dispose() {}
}

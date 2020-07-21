import 'package:flutter_web/foundation.dart';

import 'package:flutter_web/ui.dart';
import 'package:flutter_web/ui.dart' as ui show lerpDouble;

class IconThemeData extends Diagnosticable {
  const IconThemeData({this.color, double opacity, this.size})
      : _opacity = opacity;

  const IconThemeData.fallback()
      : color = const Color(0xFF000000),
        _opacity = 1.0,
        size = 24.0;

  IconThemeData copyWith({Color color, double opacity, double size}) {
    return IconThemeData(
      color: color ?? this.color,
      opacity: opacity ?? this.opacity,
      size: size ?? this.size,
    );
  }

  IconThemeData merge(IconThemeData other) {
    if (other == null) return this;
    return copyWith(
      color: other.color,
      opacity: other.opacity,
      size: other.size,
    );
  }

  bool get isConcrete => color != null && opacity != null && size != null;

  final Color color;

  double get opacity => _opacity?.clamp(0.0, 1.0);
  final double _opacity;

  final double size;

  static IconThemeData lerp(IconThemeData a, IconThemeData b, double t) {
    assert(t != null);
    return IconThemeData(
      color: Color.lerp(a?.color, b?.color, t),
      opacity: ui.lerpDouble(a?.opacity, b?.opacity, t),
      size: ui.lerpDouble(a?.size, b?.size, t),
    );
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) return false;
    final IconThemeData typedOther = other;
    return color == typedOther.color &&
        opacity == typedOther.opacity &&
        size == typedOther.size;
  }

  @override
  int get hashCode => hashValues(color, opacity, size);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(DiagnosticsProperty<Color>('color', color, defaultValue: null));
    properties.add(DoubleProperty('opacity', opacity, defaultValue: null));
    properties.add(DoubleProperty('size', size, defaultValue: null));
  }
}

import 'package:flutter_web/ui.dart';

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/widgets.dart';

import 'theme.dart';

class CardTheme extends Diagnosticable {
  const CardTheme({
    this.clipBehavior,
    this.color,
    this.elevation,
    this.margin,
    this.shape,
  }) : assert(elevation == null || elevation >= 0.0);

  final Clip clipBehavior;

  final Color color;

  final double elevation;

  final EdgeInsetsGeometry margin;

  final ShapeBorder shape;

  CardTheme copyWith({
    Clip clipBehavior,
    Color color,
    double elevation,
    EdgeInsetsGeometry margin,
    ShapeBorder shape,
  }) {
    return CardTheme(
      clipBehavior: clipBehavior ?? this.clipBehavior,
      color: color ?? this.color,
      elevation: elevation ?? this.elevation,
      margin: margin ?? this.margin,
      shape: shape ?? this.shape,
    );
  }

  static CardTheme of(BuildContext context) {
    return Theme.of(context).cardTheme;
  }

  static CardTheme lerp(CardTheme a, CardTheme b, double t) {
    assert(t != null);
    return CardTheme(
      clipBehavior: t < 0.5 ? a?.clipBehavior : b?.clipBehavior,
      color: Color.lerp(a?.color, b?.color, t),
      elevation: lerpDouble(a?.elevation, b?.elevation, t),
      margin: EdgeInsetsGeometry.lerp(a?.margin, b?.margin, t),
      shape: ShapeBorder.lerp(a?.shape, b?.shape, t),
    );
  }

  @override
  int get hashCode {
    return hashValues(
      clipBehavior,
      color,
      elevation,
      margin,
      shape,
    );
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    final CardTheme typedOther = other;
    return typedOther.clipBehavior == clipBehavior &&
        typedOther.color == color &&
        typedOther.elevation == elevation &&
        typedOther.margin == margin &&
        typedOther.shape == shape;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Clip>('clipBehavior', clipBehavior,
        defaultValue: null));
    properties.add(ColorProperty('color', color, defaultValue: null));
    properties.add(DiagnosticsProperty<double>('elevation', elevation,
        defaultValue: null));
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('margin', margin,
        defaultValue: null));
    properties.add(
        DiagnosticsProperty<ShapeBorder>('shape', shape, defaultValue: null));
  }
}

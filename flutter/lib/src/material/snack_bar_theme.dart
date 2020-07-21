import 'package:flutter_web/ui.dart' show lerpDouble;

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/widgets.dart';

import 'theme.dart';

enum SnackBarBehavior {
  fixed,

  floating,
}

class SnackBarThemeData extends Diagnosticable {
  const SnackBarThemeData({
    this.backgroundColor,
    this.actionTextColor,
    this.disabledActionTextColor,
    this.elevation,
    this.shape,
    this.behavior,
  }) : assert(elevation == null || elevation >= 0.0);

  final Color backgroundColor;

  final Color actionTextColor;

  final Color disabledActionTextColor;

  final double elevation;

  final ShapeBorder shape;

  final SnackBarBehavior behavior;

  SnackBarThemeData copyWith({
    Color backgroundColor,
    Color actionTextColor,
    Color disabledActionTextColor,
    double elevation,
    ShapeBorder shape,
    SnackBarBehavior behavior,
  }) {
    return SnackBarThemeData(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      actionTextColor: actionTextColor ?? this.actionTextColor,
      disabledActionTextColor:
          disabledActionTextColor ?? this.disabledActionTextColor,
      elevation: elevation ?? this.elevation,
      shape: shape ?? this.shape,
      behavior: behavior ?? this.behavior,
    );
  }

  static SnackBarThemeData lerp(
      SnackBarThemeData a, SnackBarThemeData b, double t) {
    assert(t != null);
    return SnackBarThemeData(
      backgroundColor: Color.lerp(a?.backgroundColor, b?.backgroundColor, t),
      actionTextColor: Color.lerp(a?.actionTextColor, b?.actionTextColor, t),
      disabledActionTextColor:
          Color.lerp(a?.disabledActionTextColor, b?.disabledActionTextColor, t),
      elevation: lerpDouble(a?.elevation, b?.elevation, t),
      shape: ShapeBorder.lerp(a?.shape, b?.shape, t),
      behavior: t < 0.5 ? a.behavior : b.behavior,
    );
  }

  @override
  int get hashCode {
    return hashValues(
      backgroundColor,
      actionTextColor,
      disabledActionTextColor,
      elevation,
      shape,
      behavior,
    );
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    final SnackBarThemeData typedOther = other;
    return typedOther.backgroundColor == backgroundColor &&
        typedOther.actionTextColor == actionTextColor &&
        typedOther.disabledActionTextColor == disabledActionTextColor &&
        typedOther.elevation == elevation &&
        typedOther.shape == shape &&
        typedOther.behavior == behavior;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Color>(
        'backgroundColor', backgroundColor,
        defaultValue: null));
    properties.add(DiagnosticsProperty<Color>(
        'actionTextColor', actionTextColor,
        defaultValue: null));
    properties.add(DiagnosticsProperty<Color>(
        'disabledActionTextColor', disabledActionTextColor,
        defaultValue: null));
    properties.add(DiagnosticsProperty<double>('elevation', elevation,
        defaultValue: null));
    properties.add(
        DiagnosticsProperty<ShapeBorder>('shape', shape, defaultValue: null));
    properties.add(DiagnosticsProperty<SnackBarBehavior>('behavior', behavior,
        defaultValue: null));
  }
}

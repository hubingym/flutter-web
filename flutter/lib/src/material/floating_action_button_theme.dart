import 'package:flutter_web/ui.dart' show lerpDouble;

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/rendering.dart';

class FloatingActionButtonThemeData extends Diagnosticable {
  const FloatingActionButtonThemeData({
    this.foregroundColor,
    this.backgroundColor,
    this.focusColor,
    this.hoverColor,
    this.elevation,
    this.focusElevation,
    this.hoverElevation,
    this.disabledElevation,
    this.highlightElevation,
    this.shape,
  });

  final Color foregroundColor;

  final Color backgroundColor;

  final Color focusColor;

  final Color hoverColor;

  final double elevation;

  final double focusElevation;

  final double hoverElevation;

  final double disabledElevation;

  final double highlightElevation;

  final ShapeBorder shape;

  FloatingActionButtonThemeData copyWith({
    Color foregroundColor,
    Color backgroundColor,
    Color focusColor,
    Color hoverColor,
    double elevation,
    double focusElevation,
    double hoverElevation,
    double disabledElevation,
    double highlightElevation,
    ShapeBorder shape,
  }) {
    return FloatingActionButtonThemeData(
      foregroundColor: foregroundColor ?? this.foregroundColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      focusColor: focusColor ?? this.focusColor,
      hoverColor: hoverColor ?? this.hoverColor,
      elevation: elevation ?? this.elevation,
      focusElevation: focusElevation ?? this.focusElevation,
      hoverElevation: hoverElevation ?? this.hoverElevation,
      disabledElevation: disabledElevation ?? this.disabledElevation,
      highlightElevation: highlightElevation ?? this.highlightElevation,
      shape: shape ?? this.shape,
    );
  }

  static FloatingActionButtonThemeData lerp(FloatingActionButtonThemeData a,
      FloatingActionButtonThemeData b, double t) {
    assert(t != null);
    if (a == null && b == null) return null;
    return FloatingActionButtonThemeData(
      foregroundColor: Color.lerp(a?.foregroundColor, b?.foregroundColor, t),
      backgroundColor: Color.lerp(a?.backgroundColor, b?.backgroundColor, t),
      focusColor: Color.lerp(a?.focusColor, b?.focusColor, t),
      hoverColor: Color.lerp(a?.hoverColor, b?.hoverColor, t),
      elevation: lerpDouble(a?.elevation, b?.elevation, t),
      focusElevation: lerpDouble(a?.focusElevation, b?.focusElevation, t),
      hoverElevation: lerpDouble(a?.hoverElevation, b?.hoverElevation, t),
      disabledElevation:
          lerpDouble(a?.disabledElevation, b?.disabledElevation, t),
      highlightElevation:
          lerpDouble(a?.highlightElevation, b?.highlightElevation, t),
      shape: ShapeBorder.lerp(a?.shape, b?.shape, t),
    );
  }

  @override
  int get hashCode {
    return hashValues(
      foregroundColor,
      backgroundColor,
      focusColor,
      hoverColor,
      elevation,
      focusElevation,
      hoverElevation,
      disabledElevation,
      highlightElevation,
      shape,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    final FloatingActionButtonThemeData otherData = other;
    return otherData.foregroundColor == foregroundColor &&
        otherData.backgroundColor == backgroundColor &&
        otherData.focusColor == focusColor &&
        otherData.hoverColor == hoverColor &&
        otherData.elevation == elevation &&
        otherData.focusElevation == focusElevation &&
        otherData.hoverElevation == hoverElevation &&
        otherData.disabledElevation == disabledElevation &&
        otherData.highlightElevation == highlightElevation &&
        otherData.shape == shape;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    const FloatingActionButtonThemeData defaultData =
        FloatingActionButtonThemeData();

    properties.add(ColorProperty('foregroundColor', foregroundColor,
        defaultValue: defaultData.foregroundColor));
    properties.add(ColorProperty('backgroundColor', backgroundColor,
        defaultValue: defaultData.backgroundColor));
    properties.add(ColorProperty('focusColor', focusColor,
        defaultValue: defaultData.focusColor));
    properties.add(ColorProperty('hoverColor', hoverColor,
        defaultValue: defaultData.hoverColor));
    properties.add(DoubleProperty('elevation', elevation,
        defaultValue: defaultData.elevation));
    properties.add(DoubleProperty('focusElevation', focusElevation,
        defaultValue: defaultData.focusElevation));
    properties.add(DoubleProperty('hoverElevation', hoverElevation,
        defaultValue: defaultData.hoverElevation));
    properties.add(DoubleProperty('disabledElevation', disabledElevation,
        defaultValue: defaultData.disabledElevation));
    properties.add(DoubleProperty('highlightElevation', highlightElevation,
        defaultValue: defaultData.highlightElevation));
    properties.add(DiagnosticsProperty<ShapeBorder>('shape', shape,
        defaultValue: defaultData.shape));
  }
}

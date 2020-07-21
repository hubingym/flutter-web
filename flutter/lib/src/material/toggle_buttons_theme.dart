import 'package:flutter_web/ui.dart' show lerpDouble;

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/rendering.dart';
import 'package:flutter_web/widgets.dart';

import 'theme.dart';

class ToggleButtonsThemeData extends Diagnosticable {
  const ToggleButtonsThemeData({
    this.color,
    this.selectedColor,
    this.disabledColor,
    this.fillColor,
    this.focusColor,
    this.highlightColor,
    this.hoverColor,
    this.splashColor,
    this.borderColor,
    this.selectedBorderColor,
    this.disabledBorderColor,
    this.borderRadius,
    this.borderWidth,
  });

  final Color color;

  final Color selectedColor;

  final Color disabledColor;

  final Color fillColor;

  final Color focusColor;

  final Color highlightColor;

  final Color splashColor;

  final Color hoverColor;

  final Color borderColor;

  final Color selectedBorderColor;

  final Color disabledBorderColor;

  final double borderWidth;

  final BorderRadius borderRadius;

  ToggleButtonsThemeData copyWith({
    Color color,
    Color selectedColor,
    Color disabledColor,
    Color fillColor,
    Color focusColor,
    Color highlightColor,
    Color hoverColor,
    Color splashColor,
    Color borderColor,
    Color selectedBorderColor,
    Color disabledBorderColor,
    BorderRadius borderRadius,
    double borderWidth,
  }) {
    return ToggleButtonsThemeData(
      color: color ?? this.color,
      selectedColor: selectedColor ?? this.selectedColor,
      disabledColor: disabledColor ?? this.disabledColor,
      fillColor: fillColor ?? this.fillColor,
      focusColor: focusColor ?? this.focusColor,
      highlightColor: highlightColor ?? this.highlightColor,
      hoverColor: hoverColor ?? this.hoverColor,
      splashColor: splashColor ?? this.splashColor,
      borderColor: borderColor ?? this.borderColor,
      selectedBorderColor: selectedBorderColor ?? this.selectedBorderColor,
      disabledBorderColor: disabledBorderColor ?? this.disabledBorderColor,
      borderRadius: borderRadius ?? this.borderRadius,
      borderWidth: borderWidth ?? this.borderWidth,
    );
  }

  static ToggleButtonsThemeData lerp(
      ToggleButtonsThemeData a, ToggleButtonsThemeData b, double t) {
    assert(t != null);
    if (a == null && b == null) return null;
    return ToggleButtonsThemeData(
      color: Color.lerp(a?.color, b?.color, t),
      selectedColor: Color.lerp(a?.selectedColor, b?.selectedColor, t),
      disabledColor: Color.lerp(a?.disabledColor, b?.disabledColor, t),
      fillColor: Color.lerp(a?.fillColor, b?.fillColor, t),
      focusColor: Color.lerp(a?.focusColor, b?.focusColor, t),
      highlightColor: Color.lerp(a?.highlightColor, b?.highlightColor, t),
      hoverColor: Color.lerp(a?.hoverColor, b?.hoverColor, t),
      splashColor: Color.lerp(a?.splashColor, b?.splashColor, t),
      borderColor: Color.lerp(a?.borderColor, b?.borderColor, t),
      selectedBorderColor:
          Color.lerp(a?.selectedBorderColor, b?.selectedBorderColor, t),
      disabledBorderColor:
          Color.lerp(a?.disabledBorderColor, b?.disabledBorderColor, t),
      borderRadius: BorderRadius.lerp(a?.borderRadius, b?.borderRadius, t),
      borderWidth: lerpDouble(a?.borderWidth, b?.borderWidth, t),
    );
  }

  @override
  int get hashCode {
    return hashValues(
      color,
      selectedColor,
      disabledColor,
      fillColor,
      focusColor,
      highlightColor,
      hoverColor,
      splashColor,
      borderColor,
      selectedBorderColor,
      disabledBorderColor,
      borderRadius,
      borderWidth,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    final ToggleButtonsThemeData typedOther = other;
    return typedOther.color == color &&
        typedOther.selectedColor == selectedColor &&
        typedOther.disabledColor == disabledColor &&
        typedOther.fillColor == fillColor &&
        typedOther.focusColor == focusColor &&
        typedOther.highlightColor == highlightColor &&
        typedOther.hoverColor == hoverColor &&
        typedOther.splashColor == splashColor &&
        typedOther.borderColor == borderColor &&
        typedOther.selectedBorderColor == selectedBorderColor &&
        typedOther.disabledBorderColor == disabledBorderColor &&
        typedOther.borderRadius == borderRadius &&
        typedOther.borderWidth == borderWidth;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ColorProperty('color', color, defaultValue: null));
    properties
        .add(ColorProperty('selectedColor', selectedColor, defaultValue: null));
    properties
        .add(ColorProperty('disabledColor', disabledColor, defaultValue: null));
    properties.add(ColorProperty('fillColor', fillColor, defaultValue: null));
    properties.add(ColorProperty('focusColor', focusColor, defaultValue: null));
    properties.add(
        ColorProperty('highlightColor', highlightColor, defaultValue: null));
    properties.add(ColorProperty('hoverColor', hoverColor, defaultValue: null));
    properties
        .add(ColorProperty('splashColor', splashColor, defaultValue: null));
    properties
        .add(ColorProperty('borderColor', borderColor, defaultValue: null));
    properties.add(ColorProperty('selectedBorderColor', selectedBorderColor,
        defaultValue: null));
    properties.add(ColorProperty('disabledBorderColor', disabledBorderColor,
        defaultValue: null));
    properties.add(DiagnosticsProperty<BorderRadius>(
        'borderRadius', borderRadius,
        defaultValue: null));
    properties
        .add(DoubleProperty('borderWidth', borderWidth, defaultValue: null));
  }
}

class ToggleButtonsTheme extends InheritedWidget {
  ToggleButtonsTheme({
    Key key,
    Color color,
    Color selectedColor,
    Color disabledColor,
    Color fillColor,
    Color focusColor,
    Color highlightColor,
    Color hoverColor,
    Color splashColor,
    Color borderColor,
    Color selectedBorderColor,
    Color disabledBorderColor,
    BorderRadius borderRadius,
    double borderWidth,
    Widget child,
  })  : data = ToggleButtonsThemeData(
          color: color,
          selectedColor: selectedColor,
          disabledColor: disabledColor,
          fillColor: fillColor,
          focusColor: focusColor,
          highlightColor: highlightColor,
          hoverColor: hoverColor,
          splashColor: splashColor,
          borderColor: borderColor,
          selectedBorderColor: selectedBorderColor,
          disabledBorderColor: disabledBorderColor,
          borderRadius: borderRadius,
          borderWidth: borderWidth,
        ),
        super(key: key, child: child);

  final ToggleButtonsThemeData data;

  static ToggleButtonsThemeData of(BuildContext context) {
    final ToggleButtonsTheme toggleButtonsTheme =
        context.inheritFromWidgetOfExactType(ToggleButtonsTheme);
    return toggleButtonsTheme?.data ?? Theme.of(context).toggleButtonsTheme;
  }

  @override
  bool updateShouldNotify(ToggleButtonsTheme oldWidget) =>
      data != oldWidget.data;
}

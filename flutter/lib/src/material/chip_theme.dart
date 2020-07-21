import 'package:flutter_web/ui.dart' show lerpDouble;

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/rendering.dart';
import 'package:flutter_web/widgets.dart';

import 'colors.dart';
import 'theme.dart';

class ChipTheme extends InheritedWidget {
  const ChipTheme({
    Key key,
    @required this.data,
    @required Widget child,
  })  : assert(child != null),
        assert(data != null),
        super(key: key, child: child);

  final ChipThemeData data;

  static ChipThemeData of(BuildContext context) {
    final ChipTheme inheritedTheme =
        context.inheritFromWidgetOfExactType(ChipTheme);
    return inheritedTheme?.data ?? Theme.of(context).chipTheme;
  }

  @override
  bool updateShouldNotify(ChipTheme oldWidget) => data != oldWidget.data;
}

class ChipThemeData extends Diagnosticable {
  const ChipThemeData({
    @required this.backgroundColor,
    this.deleteIconColor,
    @required this.disabledColor,
    @required this.selectedColor,
    @required this.secondarySelectedColor,
    this.shadowColor,
    this.selectedShadowColor,
    @required this.labelPadding,
    @required this.padding,
    @required this.shape,
    @required this.labelStyle,
    @required this.secondaryLabelStyle,
    @required this.brightness,
    this.elevation,
    this.pressElevation,
  })  : assert(backgroundColor != null),
        assert(disabledColor != null),
        assert(selectedColor != null),
        assert(secondarySelectedColor != null),
        assert(labelPadding != null),
        assert(padding != null),
        assert(shape != null),
        assert(labelStyle != null),
        assert(secondaryLabelStyle != null),
        assert(brightness != null);

  factory ChipThemeData.fromDefaults({
    Brightness brightness,
    Color primaryColor,
    @required Color secondaryColor,
    @required TextStyle labelStyle,
  }) {
    assert(primaryColor != null || brightness != null,
        'One of primaryColor or brightness must be specified');
    assert(primaryColor == null || brightness == null,
        'Only one of primaryColor or brightness may be specified');
    assert(secondaryColor != null);
    assert(labelStyle != null);

    if (primaryColor != null) {
      brightness = ThemeData.estimateBrightnessForColor(primaryColor);
    }

    const int backgroundAlpha = 0x1f;
    const int deleteIconAlpha = 0xde;
    const int disabledAlpha = 0x0c;
    const int selectAlpha = 0x3d;
    const int textLabelAlpha = 0xde;
    const ShapeBorder shape = StadiumBorder();
    const EdgeInsetsGeometry labelPadding =
        EdgeInsets.symmetric(horizontal: 8.0);
    const EdgeInsetsGeometry padding = EdgeInsets.all(4.0);

    primaryColor = primaryColor ??
        (brightness == Brightness.light ? Colors.black : Colors.white);
    final Color backgroundColor = primaryColor.withAlpha(backgroundAlpha);
    final Color deleteIconColor = primaryColor.withAlpha(deleteIconAlpha);
    final Color disabledColor = primaryColor.withAlpha(disabledAlpha);
    final Color selectedColor = primaryColor.withAlpha(selectAlpha);
    final Color secondarySelectedColor = secondaryColor.withAlpha(selectAlpha);
    final TextStyle secondaryLabelStyle = labelStyle.copyWith(
      color: secondaryColor.withAlpha(textLabelAlpha),
    );
    labelStyle =
        labelStyle.copyWith(color: primaryColor.withAlpha(textLabelAlpha));

    return ChipThemeData(
      backgroundColor: backgroundColor,
      deleteIconColor: deleteIconColor,
      disabledColor: disabledColor,
      selectedColor: selectedColor,
      secondarySelectedColor: secondarySelectedColor,
      labelPadding: labelPadding,
      padding: padding,
      shape: shape,
      labelStyle: labelStyle,
      secondaryLabelStyle: secondaryLabelStyle,
      brightness: brightness,
    );
  }

  final Color backgroundColor;

  final Color deleteIconColor;

  final Color disabledColor;

  final Color selectedColor;

  final Color secondarySelectedColor;

  final Color shadowColor;

  final Color selectedShadowColor;

  final EdgeInsetsGeometry labelPadding;

  final EdgeInsetsGeometry padding;

  final ShapeBorder shape;

  final TextStyle labelStyle;

  final TextStyle secondaryLabelStyle;

  final Brightness brightness;

  final double elevation;

  final double pressElevation;

  ChipThemeData copyWith({
    Color backgroundColor,
    Color deleteIconColor,
    Color disabledColor,
    Color selectedColor,
    Color secondarySelectedColor,
    Color shadowColor,
    Color selectedShadowColor,
    EdgeInsetsGeometry labelPadding,
    EdgeInsetsGeometry padding,
    ShapeBorder shape,
    TextStyle labelStyle,
    TextStyle secondaryLabelStyle,
    Brightness brightness,
    double elevation,
    double pressElevation,
  }) {
    return ChipThemeData(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      deleteIconColor: deleteIconColor ?? this.deleteIconColor,
      disabledColor: disabledColor ?? this.disabledColor,
      selectedColor: selectedColor ?? this.selectedColor,
      secondarySelectedColor:
          secondarySelectedColor ?? this.secondarySelectedColor,
      shadowColor: shadowColor ?? this.shadowColor,
      selectedShadowColor: selectedShadowColor ?? this.selectedShadowColor,
      labelPadding: labelPadding ?? this.labelPadding,
      padding: padding ?? this.padding,
      shape: shape ?? this.shape,
      labelStyle: labelStyle ?? this.labelStyle,
      secondaryLabelStyle: secondaryLabelStyle ?? this.secondaryLabelStyle,
      brightness: brightness ?? this.brightness,
      elevation: elevation ?? this.elevation,
      pressElevation: pressElevation ?? this.pressElevation,
    );
  }

  static ChipThemeData lerp(ChipThemeData a, ChipThemeData b, double t) {
    assert(t != null);
    if (a == null && b == null) return null;
    return ChipThemeData(
      backgroundColor: Color.lerp(a?.backgroundColor, b?.backgroundColor, t),
      deleteIconColor: Color.lerp(a?.deleteIconColor, b?.deleteIconColor, t),
      disabledColor: Color.lerp(a?.disabledColor, b?.disabledColor, t),
      selectedColor: Color.lerp(a?.selectedColor, b?.selectedColor, t),
      secondarySelectedColor:
          Color.lerp(a?.secondarySelectedColor, b?.secondarySelectedColor, t),
      shadowColor: Color.lerp(a?.shadowColor, b?.shadowColor, t),
      selectedShadowColor:
          Color.lerp(a?.selectedShadowColor, b?.selectedShadowColor, t),
      labelPadding:
          EdgeInsetsGeometry.lerp(a?.labelPadding, b?.labelPadding, t),
      padding: EdgeInsetsGeometry.lerp(a?.padding, b?.padding, t),
      shape: ShapeBorder.lerp(a?.shape, b?.shape, t),
      labelStyle: TextStyle.lerp(a?.labelStyle, b?.labelStyle, t),
      secondaryLabelStyle:
          TextStyle.lerp(a?.secondaryLabelStyle, b?.secondaryLabelStyle, t),
      brightness: t < 0.5
          ? a?.brightness ?? Brightness.light
          : b?.brightness ?? Brightness.light,
      elevation: lerpDouble(a?.elevation, b?.elevation, t),
      pressElevation: lerpDouble(a?.pressElevation, b?.pressElevation, t),
    );
  }

  @override
  int get hashCode {
    return hashValues(
      backgroundColor,
      deleteIconColor,
      disabledColor,
      selectedColor,
      secondarySelectedColor,
      shadowColor,
      selectedShadowColor,
      labelPadding,
      padding,
      shape,
      labelStyle,
      secondaryLabelStyle,
      brightness,
      elevation,
      pressElevation,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    final ChipThemeData otherData = other;
    return otherData.backgroundColor == backgroundColor &&
        otherData.deleteIconColor == deleteIconColor &&
        otherData.disabledColor == disabledColor &&
        otherData.selectedColor == selectedColor &&
        otherData.secondarySelectedColor == secondarySelectedColor &&
        otherData.shadowColor == shadowColor &&
        otherData.selectedShadowColor == selectedShadowColor &&
        otherData.labelPadding == labelPadding &&
        otherData.padding == padding &&
        otherData.shape == shape &&
        otherData.labelStyle == labelStyle &&
        otherData.secondaryLabelStyle == secondaryLabelStyle &&
        otherData.brightness == brightness &&
        otherData.elevation == elevation &&
        otherData.pressElevation == pressElevation;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    final ThemeData defaultTheme = ThemeData.fallback();
    final ChipThemeData defaultData = ChipThemeData.fromDefaults(
      secondaryColor: defaultTheme.primaryColor,
      brightness: defaultTheme.brightness,
      labelStyle: defaultTheme.textTheme.body2,
    );
    properties.add(DiagnosticsProperty<Color>(
        'backgroundColor', backgroundColor,
        defaultValue: defaultData.backgroundColor));
    properties.add(DiagnosticsProperty<Color>(
        'deleteIconColor', deleteIconColor,
        defaultValue: defaultData.deleteIconColor));
    properties.add(DiagnosticsProperty<Color>('disabledColor', disabledColor,
        defaultValue: defaultData.disabledColor));
    properties.add(DiagnosticsProperty<Color>('selectedColor', selectedColor,
        defaultValue: defaultData.selectedColor));
    properties.add(DiagnosticsProperty<Color>(
        'secondarySelectedColor', secondarySelectedColor,
        defaultValue: defaultData.secondarySelectedColor));
    properties.add(DiagnosticsProperty<Color>('shadowColor', shadowColor,
        defaultValue: defaultData.shadowColor));
    properties.add(DiagnosticsProperty<Color>(
        'selectedShadowColor', selectedShadowColor,
        defaultValue: defaultData.selectedShadowColor));
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>(
        'labelPadding', labelPadding,
        defaultValue: defaultData.labelPadding));
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('padding', padding,
        defaultValue: defaultData.padding));
    properties.add(DiagnosticsProperty<ShapeBorder>('shape', shape,
        defaultValue: defaultData.shape));
    properties.add(DiagnosticsProperty<TextStyle>('labelStyle', labelStyle,
        defaultValue: defaultData.labelStyle));
    properties.add(DiagnosticsProperty<TextStyle>(
        'secondaryLabelStyle', secondaryLabelStyle,
        defaultValue: defaultData.secondaryLabelStyle));
    properties.add(EnumProperty<Brightness>('brightness', brightness,
        defaultValue: defaultData.brightness));
    properties.add(DoubleProperty('elevation', elevation,
        defaultValue: defaultData.elevation));
    properties.add(DoubleProperty('pressElevation', pressElevation,
        defaultValue: defaultData.pressElevation));
  }
}

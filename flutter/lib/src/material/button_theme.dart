import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/widgets.dart';

import 'color_scheme.dart';
import 'colors.dart';
import 'constants.dart';
import 'flat_button.dart';
import 'material_button.dart';
import 'outline_button.dart';
import 'raised_button.dart';
import 'theme.dart';
import 'theme_data.dart' show MaterialTapTargetSize;

enum ButtonTextTheme {
  normal,

  accent,

  primary,
}

enum ButtonBarLayoutBehavior {
  constrained,

  padded,
}

class ButtonTheme extends InheritedWidget {
  ButtonTheme({
    Key key,
    ButtonTextTheme textTheme = ButtonTextTheme.normal,
    ButtonBarLayoutBehavior layoutBehavior = ButtonBarLayoutBehavior.padded,
    double minWidth = 88.0,
    double height = 36.0,
    EdgeInsetsGeometry padding,
    ShapeBorder shape,
    bool alignedDropdown = false,
    Color buttonColor,
    Color disabledColor,
    Color focusColor,
    Color hoverColor,
    Color highlightColor,
    Color splashColor,
    ColorScheme colorScheme,
    MaterialTapTargetSize materialTapTargetSize,
    Widget child,
  })  : assert(textTheme != null),
        assert(minWidth != null && minWidth >= 0.0),
        assert(height != null && height >= 0.0),
        assert(alignedDropdown != null),
        assert(layoutBehavior != null),
        data = ButtonThemeData(
          textTheme: textTheme,
          minWidth: minWidth,
          height: height,
          padding: padding,
          shape: shape,
          alignedDropdown: alignedDropdown,
          layoutBehavior: layoutBehavior,
          buttonColor: buttonColor,
          disabledColor: disabledColor,
          focusColor: focusColor,
          hoverColor: hoverColor,
          highlightColor: highlightColor,
          splashColor: splashColor,
          colorScheme: colorScheme,
          materialTapTargetSize: materialTapTargetSize,
        ),
        super(key: key, child: child);

  const ButtonTheme.fromButtonThemeData({
    Key key,
    @required this.data,
    Widget child,
  })  : assert(data != null),
        super(key: key, child: child);

  ButtonTheme.bar({
    Key key,
    ButtonTextTheme textTheme = ButtonTextTheme.accent,
    double minWidth = 64.0,
    double height = 36.0,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 8.0),
    ShapeBorder shape,
    bool alignedDropdown = false,
    Color buttonColor,
    Color disabledColor,
    Color focusColor,
    Color hoverColor,
    Color highlightColor,
    Color splashColor,
    ColorScheme colorScheme,
    Widget child,
    ButtonBarLayoutBehavior layoutBehavior = ButtonBarLayoutBehavior.padded,
  })  : assert(textTheme != null),
        assert(minWidth != null && minWidth >= 0.0),
        assert(height != null && height >= 0.0),
        assert(alignedDropdown != null),
        data = ButtonThemeData(
          textTheme: textTheme,
          minWidth: minWidth,
          height: height,
          padding: padding,
          shape: shape,
          alignedDropdown: alignedDropdown,
          layoutBehavior: layoutBehavior,
          buttonColor: buttonColor,
          disabledColor: disabledColor,
          focusColor: focusColor,
          hoverColor: hoverColor,
          highlightColor: highlightColor,
          splashColor: splashColor,
          colorScheme: colorScheme,
        ),
        super(key: key, child: child);

  final ButtonThemeData data;

  static ButtonThemeData of(BuildContext context) {
    final ButtonTheme inheritedButtonTheme =
        context.inheritFromWidgetOfExactType(ButtonTheme);
    ButtonThemeData buttonTheme = inheritedButtonTheme?.data;
    if (buttonTheme?.colorScheme == null) {
      final ThemeData theme = Theme.of(context);
      buttonTheme ??= theme.buttonTheme;
      if (buttonTheme.colorScheme == null) {
        buttonTheme = buttonTheme.copyWith(
          colorScheme: theme.buttonTheme.colorScheme ?? theme.colorScheme,
        );
        assert(buttonTheme.colorScheme != null);
      }
    }
    return buttonTheme;
  }

  @override
  bool updateShouldNotify(ButtonTheme oldWidget) => data != oldWidget.data;
}

class ButtonThemeData extends Diagnosticable {
  const ButtonThemeData({
    this.textTheme = ButtonTextTheme.normal,
    this.minWidth = 88.0,
    this.height = 36.0,
    EdgeInsetsGeometry padding,
    ShapeBorder shape,
    this.layoutBehavior = ButtonBarLayoutBehavior.padded,
    this.alignedDropdown = false,
    Color buttonColor,
    Color disabledColor,
    Color focusColor,
    Color hoverColor,
    Color highlightColor,
    Color splashColor,
    this.colorScheme,
    MaterialTapTargetSize materialTapTargetSize,
  })  : assert(textTheme != null),
        assert(minWidth != null && minWidth >= 0.0),
        assert(height != null && height >= 0.0),
        assert(alignedDropdown != null),
        assert(layoutBehavior != null),
        _buttonColor = buttonColor,
        _disabledColor = disabledColor,
        _focusColor = focusColor,
        _hoverColor = hoverColor,
        _highlightColor = highlightColor,
        _splashColor = splashColor,
        _padding = padding,
        _shape = shape,
        _materialTapTargetSize = materialTapTargetSize;

  final double minWidth;

  final double height;

  final ButtonTextTheme textTheme;

  final ButtonBarLayoutBehavior layoutBehavior;

  BoxConstraints get constraints {
    return BoxConstraints(
      minWidth: minWidth,
      minHeight: height,
    );
  }

  EdgeInsetsGeometry get padding {
    if (_padding != null) return _padding;
    switch (textTheme) {
      case ButtonTextTheme.normal:
      case ButtonTextTheme.accent:
        return const EdgeInsets.symmetric(horizontal: 16.0);
      case ButtonTextTheme.primary:
        return const EdgeInsets.symmetric(horizontal: 24.0);
    }
    assert(false);
    return EdgeInsets.zero;
  }

  final EdgeInsetsGeometry _padding;

  ShapeBorder get shape {
    if (_shape != null) return _shape;
    switch (textTheme) {
      case ButtonTextTheme.normal:
      case ButtonTextTheme.accent:
        return const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(2.0)),
        );
      case ButtonTextTheme.primary:
        return const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(4.0)),
        );
    }
    return const RoundedRectangleBorder();
  }

  final ShapeBorder _shape;

  final bool alignedDropdown;

  final Color _buttonColor;

  final Color _disabledColor;

  final Color _focusColor;

  final Color _hoverColor;

  final Color _highlightColor;

  final Color _splashColor;

  final ColorScheme colorScheme;

  final MaterialTapTargetSize _materialTapTargetSize;

  Brightness getBrightness(MaterialButton button) {
    return button.colorBrightness ?? colorScheme.brightness;
  }

  ButtonTextTheme getTextTheme(MaterialButton button) {
    return button.textTheme ?? textTheme;
  }

  Color _getDisabledColor(MaterialButton button) {
    return getBrightness(button) == Brightness.dark
        ? colorScheme.onSurface.withOpacity(0.30)
        : colorScheme.onSurface.withOpacity(0.38);
  }

  Color getDisabledTextColor(MaterialButton button) {
    if (button.disabledTextColor != null) return button.disabledTextColor;
    return _getDisabledColor(button);
  }

  Color getDisabledFillColor(MaterialButton button) {
    if (button.disabledColor != null) return button.disabledColor;
    if (_disabledColor != null) return _disabledColor;
    return _getDisabledColor(button);
  }

  Color getFillColor(MaterialButton button) {
    final Color fillColor =
        button.enabled ? button.color : button.disabledColor;
    if (fillColor != null) return fillColor;

    if (button is FlatButton ||
        button is OutlineButton ||
        button.runtimeType == MaterialButton) return null;

    if (button.enabled && button is RaisedButton && _buttonColor != null)
      return _buttonColor;

    switch (getTextTheme(button)) {
      case ButtonTextTheme.normal:
      case ButtonTextTheme.accent:
        return button.enabled
            ? colorScheme.primary
            : getDisabledFillColor(button);
      case ButtonTextTheme.primary:
        return button.enabled
            ? _buttonColor ?? colorScheme.primary
            : colorScheme.onSurface.withOpacity(0.12);
    }

    assert(false);
    return null;
  }

  Color getTextColor(MaterialButton button) {
    if (!button.enabled) return getDisabledTextColor(button);

    if (button.textColor != null) return button.textColor;

    switch (getTextTheme(button)) {
      case ButtonTextTheme.normal:
        return getBrightness(button) == Brightness.dark
            ? Colors.white
            : Colors.black87;

      case ButtonTextTheme.accent:
        return colorScheme.secondary;

      case ButtonTextTheme.primary:
        {
          final Color fillColor = getFillColor(button);
          final bool fillIsDark = fillColor != null
              ? ThemeData.estimateBrightnessForColor(fillColor) ==
                  Brightness.dark
              : getBrightness(button) == Brightness.dark;
          if (fillIsDark) return Colors.white;
          if (button is FlatButton || button is OutlineButton)
            return colorScheme.primary;
          return Colors.black;
        }
    }

    assert(false);
    return null;
  }

  Color getSplashColor(MaterialButton button) {
    if (button.splashColor != null) return button.splashColor;

    if (_splashColor != null &&
        (button is RaisedButton || button is OutlineButton))
      return _splashColor;

    if (_splashColor != null && button is FlatButton) {
      switch (getTextTheme(button)) {
        case ButtonTextTheme.normal:
        case ButtonTextTheme.accent:
          return _splashColor;
        case ButtonTextTheme.primary:
          break;
      }
    }

    return getTextColor(button).withOpacity(0.12);
  }

  Color getFocusColor(MaterialButton button) {
    return button.focusColor ??
        _focusColor ??
        getTextColor(button).withOpacity(0.12);
  }

  Color getHoverColor(MaterialButton button) {
    return button.hoverColor ??
        _hoverColor ??
        getTextColor(button).withOpacity(0.04);
  }

  Color getHighlightColor(MaterialButton button) {
    if (button.highlightColor != null) return button.highlightColor;

    switch (getTextTheme(button)) {
      case ButtonTextTheme.normal:
      case ButtonTextTheme.accent:
        return _highlightColor ?? getTextColor(button).withOpacity(0.16);
      case ButtonTextTheme.primary:
        return Colors.transparent;
    }

    assert(false);
    return Colors.transparent;
  }

  double getElevation(MaterialButton button) {
    if (button.elevation != null) return button.elevation;
    if (button is FlatButton) return 0.0;
    return 2.0;
  }

  double getFocusElevation(MaterialButton button) {
    if (button.focusElevation != null) return button.focusElevation;
    if (button is FlatButton) return 0.0;
    if (button is OutlineButton) return 0.0;
    return 4.0;
  }

  double getHoverElevation(MaterialButton button) {
    if (button.hoverElevation != null) return button.hoverElevation;
    if (button is FlatButton) return 0.0;
    if (button is OutlineButton) return 0.0;
    return 4.0;
  }

  double getHighlightElevation(MaterialButton button) {
    if (button.highlightElevation != null) return button.highlightElevation;
    if (button is FlatButton) return 0.0;
    if (button is OutlineButton) return 0.0;
    return 8.0;
  }

  double getDisabledElevation(MaterialButton button) {
    if (button.disabledElevation != null) return button.disabledElevation;
    return 0.0;
  }

  EdgeInsetsGeometry getPadding(MaterialButton button) {
    if (button.padding != null) return button.padding;

    if (button is MaterialButtonWithIconMixin)
      return const EdgeInsetsDirectional.only(start: 12.0, end: 16.0);

    if (_padding != null) return _padding;

    switch (getTextTheme(button)) {
      case ButtonTextTheme.normal:
      case ButtonTextTheme.accent:
        return const EdgeInsets.symmetric(horizontal: 16.0);
      case ButtonTextTheme.primary:
        return const EdgeInsets.symmetric(horizontal: 24.0);
    }
    assert(false);
    return EdgeInsets.zero;
  }

  ShapeBorder getShape(MaterialButton button) {
    return button.shape ?? shape;
  }

  Duration getAnimationDuration(MaterialButton button) {
    return button.animationDuration ?? kThemeChangeDuration;
  }

  BoxConstraints getConstraints(MaterialButton button) => constraints;

  MaterialTapTargetSize getMaterialTapTargetSize(MaterialButton button) {
    return button.materialTapTargetSize ??
        _materialTapTargetSize ??
        MaterialTapTargetSize.padded;
  }

  ButtonThemeData copyWith({
    ButtonTextTheme textTheme,
    ButtonBarLayoutBehavior layoutBehavior,
    double minWidth,
    double height,
    EdgeInsetsGeometry padding,
    ShapeBorder shape,
    bool alignedDropdown,
    Color buttonColor,
    Color disabledColor,
    Color focusColor,
    Color hoverColor,
    Color highlightColor,
    Color splashColor,
    ColorScheme colorScheme,
    MaterialTapTargetSize materialTapTargetSize,
  }) {
    return ButtonThemeData(
      textTheme: textTheme ?? this.textTheme,
      layoutBehavior: layoutBehavior ?? this.layoutBehavior,
      minWidth: minWidth ?? this.minWidth,
      height: height ?? this.height,
      padding: padding ?? this.padding,
      shape: shape ?? this.shape,
      alignedDropdown: alignedDropdown ?? this.alignedDropdown,
      buttonColor: buttonColor ?? _buttonColor,
      disabledColor: disabledColor ?? _disabledColor,
      focusColor: focusColor ?? _focusColor,
      hoverColor: hoverColor ?? _hoverColor,
      highlightColor: highlightColor ?? _highlightColor,
      splashColor: splashColor ?? _splashColor,
      colorScheme: colorScheme ?? this.colorScheme,
      materialTapTargetSize: materialTapTargetSize ?? _materialTapTargetSize,
    );
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) return false;
    final ButtonThemeData typedOther = other;
    return textTheme == typedOther.textTheme &&
        minWidth == typedOther.minWidth &&
        height == typedOther.height &&
        padding == typedOther.padding &&
        shape == typedOther.shape &&
        alignedDropdown == typedOther.alignedDropdown &&
        _buttonColor == typedOther._buttonColor &&
        _disabledColor == typedOther._disabledColor &&
        _focusColor == typedOther._focusColor &&
        _hoverColor == typedOther._hoverColor &&
        _highlightColor == typedOther._highlightColor &&
        _splashColor == typedOther._splashColor &&
        colorScheme == typedOther.colorScheme &&
        _materialTapTargetSize == typedOther._materialTapTargetSize;
  }

  @override
  int get hashCode {
    return hashValues(
      textTheme,
      minWidth,
      height,
      padding,
      shape,
      alignedDropdown,
      _buttonColor,
      _disabledColor,
      _focusColor,
      _hoverColor,
      _highlightColor,
      _splashColor,
      colorScheme,
      _materialTapTargetSize,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    const ButtonThemeData defaultTheme = ButtonThemeData();
    properties.add(EnumProperty<ButtonTextTheme>('textTheme', textTheme,
        defaultValue: defaultTheme.textTheme));
    properties.add(DoubleProperty('minWidth', minWidth,
        defaultValue: defaultTheme.minWidth));
    properties.add(
        DoubleProperty('height', height, defaultValue: defaultTheme.height));
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('padding', padding,
        defaultValue: defaultTheme.padding));
    properties.add(DiagnosticsProperty<ShapeBorder>('shape', shape,
        defaultValue: defaultTheme.shape));
    properties.add(FlagProperty(
      'alignedDropdown',
      value: alignedDropdown,
      defaultValue: defaultTheme.alignedDropdown,
      ifTrue: 'dropdown width matches button',
    ));
    properties.add(DiagnosticsProperty<Color>('buttonColor', _buttonColor,
        defaultValue: null));
    properties.add(DiagnosticsProperty<Color>('disabledColor', _disabledColor,
        defaultValue: null));
    properties.add(DiagnosticsProperty<Color>('focusColor', _focusColor,
        defaultValue: null));
    properties.add(DiagnosticsProperty<Color>('hoverColor', _hoverColor,
        defaultValue: null));
    properties.add(DiagnosticsProperty<Color>('highlightColor', _highlightColor,
        defaultValue: null));
    properties.add(DiagnosticsProperty<Color>('splashColor', _splashColor,
        defaultValue: null));
    properties.add(DiagnosticsProperty<ColorScheme>('colorScheme', colorScheme,
        defaultValue: defaultTheme.colorScheme));
    properties.add(DiagnosticsProperty<MaterialTapTargetSize>(
        'materialTapTargetSize', _materialTapTargetSize,
        defaultValue: null));
  }
}

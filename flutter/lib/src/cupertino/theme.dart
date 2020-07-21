import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/services.dart';
import 'package:flutter_web/widgets.dart';

import 'colors.dart';
import 'text_theme.dart';

export 'package:flutter_web/services.dart' show Brightness;

const Color _kDefaultBarLightBackgroundColor = Color(0xCCF8F8F8);
const Color _kDefaultBarDarkBackgroundColor = Color(0xB7212121);

class CupertinoTheme extends StatelessWidget {
  const CupertinoTheme({
    Key key,
    @required this.data,
    @required this.child,
  })  : assert(child != null),
        assert(data != null),
        super(key: key);

  final CupertinoThemeData data;

  static CupertinoThemeData of(BuildContext context) {
    final _InheritedCupertinoTheme inheritedTheme =
        context.inheritFromWidgetOfExactType(_InheritedCupertinoTheme);
    return inheritedTheme?.theme?.data ?? const CupertinoThemeData();
  }

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _InheritedCupertinoTheme(
        theme: this,
        child: IconTheme(
          data: IconThemeData(color: data.primaryColor),
          child: child,
        ));
  }
}

class _InheritedCupertinoTheme extends InheritedWidget {
  const _InheritedCupertinoTheme({
    Key key,
    @required this.theme,
    @required Widget child,
  })  : assert(theme != null),
        super(key: key, child: child);

  final CupertinoTheme theme;

  @override
  bool updateShouldNotify(_InheritedCupertinoTheme old) =>
      theme.data != old.theme.data;
}

@immutable
class CupertinoThemeData extends Diagnosticable {
  const CupertinoThemeData({
    Brightness brightness,
    Color primaryColor,
    Color primaryContrastingColor,
    CupertinoTextThemeData textTheme,
    Color barBackgroundColor,
    Color scaffoldBackgroundColor,
  }) : this.raw(
          brightness,
          primaryColor,
          primaryContrastingColor,
          textTheme,
          barBackgroundColor,
          scaffoldBackgroundColor,
        );

  @protected
  const CupertinoThemeData.raw(
    this._brightness,
    this._primaryColor,
    this._primaryContrastingColor,
    this._textTheme,
    this._barBackgroundColor,
    this._scaffoldBackgroundColor,
  );

  bool get _isLight => brightness == Brightness.light;

  Brightness get brightness => _brightness ?? Brightness.light;
  final Brightness _brightness;

  Color get primaryColor {
    return _primaryColor ??
        (_isLight ? CupertinoColors.activeBlue : CupertinoColors.activeOrange);
  }

  final Color _primaryColor;

  Color get primaryContrastingColor {
    return _primaryContrastingColor ??
        (_isLight ? CupertinoColors.white : CupertinoColors.black);
  }

  final Color _primaryContrastingColor;

  CupertinoTextThemeData get textTheme {
    return _textTheme ??
        CupertinoTextThemeData(
          brightness: brightness,
          primaryColor: primaryColor,
        );
  }

  final CupertinoTextThemeData _textTheme;

  Color get barBackgroundColor {
    return _barBackgroundColor ??
        (_isLight
            ? _kDefaultBarLightBackgroundColor
            : _kDefaultBarDarkBackgroundColor);
  }

  final Color _barBackgroundColor;

  Color get scaffoldBackgroundColor {
    return _scaffoldBackgroundColor ??
        (_isLight ? CupertinoColors.white : CupertinoColors.black);
  }

  final Color _scaffoldBackgroundColor;

  CupertinoThemeData noDefault() {
    return _NoDefaultCupertinoThemeData(
      _brightness,
      _primaryColor,
      _primaryContrastingColor,
      _textTheme,
      _barBackgroundColor,
      _scaffoldBackgroundColor,
    );
  }

  CupertinoThemeData copyWith({
    Brightness brightness,
    Color primaryColor,
    Color primaryContrastingColor,
    CupertinoTextThemeData textTheme,
    Color barBackgroundColor,
    Color scaffoldBackgroundColor,
  }) {
    return CupertinoThemeData(
      brightness: brightness ?? _brightness,
      primaryColor: primaryColor ?? _primaryColor,
      primaryContrastingColor:
          primaryContrastingColor ?? _primaryContrastingColor,
      textTheme: textTheme ?? _textTheme,
      barBackgroundColor: barBackgroundColor ?? _barBackgroundColor,
      scaffoldBackgroundColor:
          scaffoldBackgroundColor ?? _scaffoldBackgroundColor,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    const CupertinoThemeData defaultData = CupertinoThemeData();
    properties.add(EnumProperty<Brightness>('brightness', brightness,
        defaultValue: defaultData.brightness));
    properties.add(ColorProperty('primaryColor', primaryColor,
        defaultValue: defaultData.primaryColor));
    properties.add(ColorProperty(
        'primaryContrastingColor', primaryContrastingColor,
        defaultValue: defaultData.primaryContrastingColor));
    properties.add(DiagnosticsProperty<CupertinoTextThemeData>(
        'textTheme', textTheme,
        defaultValue: defaultData.textTheme));
    properties.add(ColorProperty('barBackgroundColor', barBackgroundColor,
        defaultValue: defaultData.barBackgroundColor));
    properties.add(ColorProperty(
        'scaffoldBackgroundColor', scaffoldBackgroundColor,
        defaultValue: defaultData.scaffoldBackgroundColor));
  }
}

class _NoDefaultCupertinoThemeData extends CupertinoThemeData {
  const _NoDefaultCupertinoThemeData(
    this.brightness,
    this.primaryColor,
    this.primaryContrastingColor,
    this.textTheme,
    this.barBackgroundColor,
    this.scaffoldBackgroundColor,
  ) : super.raw(
          brightness,
          primaryColor,
          primaryContrastingColor,
          textTheme,
          barBackgroundColor,
          scaffoldBackgroundColor,
        );

  @override
  final Brightness brightness;
  @override
  final Color primaryColor;
  @override
  final Color primaryContrastingColor;
  @override
  final CupertinoTextThemeData textTheme;
  @override
  final Color barBackgroundColor;
  @override
  final Color scaffoldBackgroundColor;
}

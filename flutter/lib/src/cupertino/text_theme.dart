import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/services.dart' show Brightness;
import 'package:flutter_web/widgets.dart';

import 'colors.dart';

const TextStyle _kDefaultLightTextStyle = TextStyle(
  inherit: false,
  fontFamily: '.SF Pro Text',
  fontSize: 17.0,
  letterSpacing: -0.41,
  color: CupertinoColors.black,
  decoration: TextDecoration.none,
);

const TextStyle _kDefaultDarkTextStyle = TextStyle(
  inherit: false,
  fontFamily: '.SF Pro Text',
  fontSize: 17.0,
  letterSpacing: -0.41,
  color: CupertinoColors.white,
  decoration: TextDecoration.none,
);

const TextStyle _kDefaultActionTextStyle = TextStyle(
  inherit: false,
  fontFamily: '.SF Pro Text',
  fontSize: 17.0,
  letterSpacing: -0.41,
  color: CupertinoColors.activeBlue,
  decoration: TextDecoration.none,
);

const TextStyle _kDefaultTabLabelTextStyle = TextStyle(
  inherit: false,
  fontFamily: '.SF Pro Text',
  fontSize: 10.0,
  letterSpacing: -0.24,
  color: CupertinoColors.inactiveGray,
);

const TextStyle _kDefaultMiddleTitleLightTextStyle = TextStyle(
  inherit: false,
  fontFamily: '.SF Pro Text',
  fontSize: 17.0,
  fontWeight: FontWeight.w600,
  letterSpacing: -0.41,
  color: CupertinoColors.black,
);

const TextStyle _kDefaultMiddleTitleDarkTextStyle = TextStyle(
  inherit: false,
  fontFamily: '.SF Pro Text',
  fontSize: 17.0,
  fontWeight: FontWeight.w600,
  letterSpacing: -0.41,
  color: CupertinoColors.white,
);

const TextStyle _kDefaultLargeTitleLightTextStyle = TextStyle(
  inherit: false,
  fontFamily: '.SF Pro Display',
  fontSize: 34.0,
  fontWeight: FontWeight.w700,
  letterSpacing: 0.41,
  color: CupertinoColors.black,
);

const TextStyle _kDefaultLargeTitleDarkTextStyle = TextStyle(
  inherit: false,
  fontFamily: '.SF Pro Display',
  fontSize: 34.0,
  fontWeight: FontWeight.w700,
  letterSpacing: 0.41,
  color: CupertinoColors.white,
);

const TextStyle _kDefaultPickerLightTextStyle = TextStyle(
  inherit: false,
  fontFamily: '.SF Pro Display',
  fontSize: 25.0,
  fontWeight: FontWeight.w400,
  letterSpacing: -0.41,
  color: CupertinoColors.black,
);

const TextStyle _kDefaultPickerDarkTextStyle = TextStyle(
  inherit: false,
  fontFamily: '.SF Pro Display',
  fontSize: 25.0,
  fontWeight: FontWeight.w400,
  letterSpacing: -0.41,
  color: CupertinoColors.white,
);

const TextStyle _kDefaultDateTimePickerLightTextStyle = TextStyle(
  inherit: false,
  fontFamily: '.SF Pro Display',
  fontSize: 21,
  fontWeight: FontWeight.w300,
  letterSpacing: -1.05,
  color: CupertinoColors.black,
);

const TextStyle _kDefaultDateTimePickerDarkTextStyle = TextStyle(
  inherit: false,
  fontFamily: '.SF Pro Display',
  fontSize: 21,
  fontWeight: FontWeight.w300,
  letterSpacing: -1.05,
  color: CupertinoColors.white,
);

@immutable
class CupertinoTextThemeData extends Diagnosticable {
  const CupertinoTextThemeData({
    Color primaryColor,
    Brightness brightness,
    TextStyle textStyle,
    TextStyle actionTextStyle,
    TextStyle tabLabelTextStyle,
    TextStyle navTitleTextStyle,
    TextStyle navLargeTitleTextStyle,
    TextStyle navActionTextStyle,
    TextStyle pickerTextStyle,
    TextStyle dateTimePickerTextStyle,
  })  : _primaryColor = primaryColor ?? CupertinoColors.activeBlue,
        _brightness = brightness,
        _textStyle = textStyle,
        _actionTextStyle = actionTextStyle,
        _tabLabelTextStyle = tabLabelTextStyle,
        _navTitleTextStyle = navTitleTextStyle,
        _navLargeTitleTextStyle = navLargeTitleTextStyle,
        _navActionTextStyle = navActionTextStyle,
        _pickerTextStyle = pickerTextStyle,
        _dateTimePickerTextStyle = dateTimePickerTextStyle;

  final Color _primaryColor;
  final Brightness _brightness;
  bool get _isLight => _brightness != Brightness.dark;

  final TextStyle _textStyle;

  TextStyle get textStyle =>
      _textStyle ??
      (_isLight ? _kDefaultLightTextStyle : _kDefaultDarkTextStyle);

  final TextStyle _actionTextStyle;

  TextStyle get actionTextStyle {
    return _actionTextStyle ??
        _kDefaultActionTextStyle.copyWith(
          color: _primaryColor,
        );
  }

  final TextStyle _tabLabelTextStyle;

  TextStyle get tabLabelTextStyle =>
      _tabLabelTextStyle ?? _kDefaultTabLabelTextStyle;

  final TextStyle _navTitleTextStyle;

  TextStyle get navTitleTextStyle {
    return _navTitleTextStyle ??
        (_isLight
            ? _kDefaultMiddleTitleLightTextStyle
            : _kDefaultMiddleTitleDarkTextStyle);
  }

  final TextStyle _navLargeTitleTextStyle;

  TextStyle get navLargeTitleTextStyle {
    return _navLargeTitleTextStyle ??
        (_isLight
            ? _kDefaultLargeTitleLightTextStyle
            : _kDefaultLargeTitleDarkTextStyle);
  }

  final TextStyle _navActionTextStyle;

  TextStyle get navActionTextStyle {
    return _navActionTextStyle ??
        _kDefaultActionTextStyle.copyWith(
          color: _primaryColor,
        );
  }

  final TextStyle _pickerTextStyle;

  TextStyle get pickerTextStyle {
    return _pickerTextStyle ??
        (_isLight
            ? _kDefaultPickerLightTextStyle
            : _kDefaultPickerDarkTextStyle);
  }

  final TextStyle _dateTimePickerTextStyle;

  TextStyle get dateTimePickerTextStyle {
    return _dateTimePickerTextStyle ??
        (_isLight
            ? _kDefaultDateTimePickerLightTextStyle
            : _kDefaultDateTimePickerDarkTextStyle);
  }

  CupertinoTextThemeData copyWith({
    Color primaryColor,
    Brightness brightness,
    TextStyle textStyle,
    TextStyle actionTextStyle,
    TextStyle tabLabelTextStyle,
    TextStyle navTitleTextStyle,
    TextStyle navLargeTitleTextStyle,
    TextStyle navActionTextStyle,
    TextStyle pickerTextStyle,
    TextStyle dateTimePickerTextStyle,
  }) {
    return CupertinoTextThemeData(
      primaryColor: primaryColor ?? _primaryColor,
      brightness: brightness ?? _brightness,
      textStyle: textStyle ?? _textStyle,
      actionTextStyle: actionTextStyle ?? _actionTextStyle,
      tabLabelTextStyle: tabLabelTextStyle ?? _tabLabelTextStyle,
      navTitleTextStyle: navTitleTextStyle ?? _navTitleTextStyle,
      navLargeTitleTextStyle: navLargeTitleTextStyle ?? _navLargeTitleTextStyle,
      navActionTextStyle: navActionTextStyle ?? _navActionTextStyle,
      pickerTextStyle: pickerTextStyle ?? _pickerTextStyle,
      dateTimePickerTextStyle:
          dateTimePickerTextStyle ?? _dateTimePickerTextStyle,
    );
  }
}

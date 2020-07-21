import 'package:flutter_web/ui.dart' show Color, hashList;

import 'package:flutter_web/cupertino.dart';
import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/services.dart';
import 'package:flutter_web/widgets.dart';

import 'app_bar_theme.dart';
import 'bottom_app_bar_theme.dart';
import 'bottom_sheet_theme.dart';
import 'button_theme.dart';
import 'card_theme.dart';
import 'chip_theme.dart';
import 'color_scheme.dart';
import 'colors.dart';
import 'dialog_theme.dart';
import 'floating_action_button_theme.dart';
import 'ink_splash.dart';
import 'ink_well.dart' show InteractiveInkFeatureFactory;
import 'input_decorator.dart';
import 'page_transitions_theme.dart';
import 'popup_menu_theme.dart';
import 'slider_theme.dart';
import 'snack_bar_theme.dart';
import 'tab_bar_theme.dart';
import 'text_theme.dart';
import 'toggle_buttons_theme.dart';
import 'tooltip_theme.dart';
import 'typography.dart';

export 'package:flutter_web/services.dart' show Brightness;

const Color _kLightThemeHighlightColor = Color(0x66BCBCBC);

const Color _kLightThemeSplashColor = Color(0x66C8C8C8);

const Color _kDarkThemeHighlightColor = Color(0x40CCCCCC);
const Color _kDarkThemeSplashColor = Color(0x40CCCCCC);

enum MaterialTapTargetSize {
  padded,

  shrinkWrap,
}

@immutable
class ThemeData extends Diagnosticable {
  factory ThemeData({
    Brightness brightness,
    MaterialColor primarySwatch,
    Color primaryColor,
    Brightness primaryColorBrightness,
    Color primaryColorLight,
    Color primaryColorDark,
    Color accentColor,
    Brightness accentColorBrightness,
    Color canvasColor,
    Color scaffoldBackgroundColor,
    Color bottomAppBarColor,
    Color cardColor,
    Color dividerColor,
    Color focusColor,
    Color hoverColor,
    Color highlightColor,
    Color splashColor,
    InteractiveInkFeatureFactory splashFactory,
    Color selectedRowColor,
    Color unselectedWidgetColor,
    Color disabledColor,
    Color buttonColor,
    ButtonThemeData buttonTheme,
    ToggleButtonsThemeData toggleButtonsTheme,
    Color secondaryHeaderColor,
    Color textSelectionColor,
    Color cursorColor,
    Color textSelectionHandleColor,
    Color backgroundColor,
    Color dialogBackgroundColor,
    Color indicatorColor,
    Color hintColor,
    Color errorColor,
    Color toggleableActiveColor,
    String fontFamily,
    TextTheme textTheme,
    TextTheme primaryTextTheme,
    TextTheme accentTextTheme,
    InputDecorationTheme inputDecorationTheme,
    IconThemeData iconTheme,
    IconThemeData primaryIconTheme,
    IconThemeData accentIconTheme,
    SliderThemeData sliderTheme,
    TabBarTheme tabBarTheme,
    TooltipThemeData tooltipTheme,
    CardTheme cardTheme,
    ChipThemeData chipTheme,
    TargetPlatform platform,
    MaterialTapTargetSize materialTapTargetSize,
    bool applyElevationOverlayColor,
    PageTransitionsTheme pageTransitionsTheme,
    AppBarTheme appBarTheme,
    BottomAppBarTheme bottomAppBarTheme,
    ColorScheme colorScheme,
    DialogTheme dialogTheme,
    FloatingActionButtonThemeData floatingActionButtonTheme,
    Typography typography,
    CupertinoThemeData cupertinoOverrideTheme,
    SnackBarThemeData snackBarTheme,
    BottomSheetThemeData bottomSheetTheme,
    PopupMenuThemeData popupMenuTheme,
  }) {
    brightness ??= Brightness.light;
    final bool isDark = brightness == Brightness.dark;
    primarySwatch ??= Colors.blue;
    primaryColor ??= isDark ? Colors.grey[900] : primarySwatch;
    primaryColorBrightness ??= estimateBrightnessForColor(primaryColor);
    primaryColorLight ??= isDark ? Colors.grey[500] : primarySwatch[100];
    primaryColorDark ??= isDark ? Colors.black : primarySwatch[700];
    final bool primaryIsDark = primaryColorBrightness == Brightness.dark;
    toggleableActiveColor ??=
        isDark ? Colors.tealAccent[200] : (accentColor ?? primarySwatch[600]);
    accentColor ??= isDark ? Colors.tealAccent[200] : primarySwatch[500];
    accentColorBrightness ??= estimateBrightnessForColor(accentColor);
    final bool accentIsDark = accentColorBrightness == Brightness.dark;
    canvasColor ??= isDark ? Colors.grey[850] : Colors.grey[50];
    scaffoldBackgroundColor ??= canvasColor;
    bottomAppBarColor ??= isDark ? Colors.grey[800] : Colors.white;
    cardColor ??= isDark ? Colors.grey[800] : Colors.white;
    dividerColor ??= isDark ? const Color(0x1FFFFFFF) : const Color(0x1F000000);

    colorScheme ??= ColorScheme.fromSwatch(
      primarySwatch: primarySwatch,
      primaryColorDark: primaryColorDark,
      accentColor: accentColor,
      cardColor: cardColor,
      backgroundColor: backgroundColor,
      errorColor: errorColor,
      brightness: brightness,
    );

    splashFactory ??= InkSplash.splashFactory;
    selectedRowColor ??= Colors.grey[100];
    unselectedWidgetColor ??= isDark ? Colors.white70 : Colors.black54;

    secondaryHeaderColor ??= isDark ? Colors.grey[700] : primarySwatch[50];
    textSelectionColor ??= isDark ? accentColor : primarySwatch[200];

    cursorColor = cursorColor ?? const Color.fromRGBO(66, 133, 244, 1.0);
    textSelectionHandleColor ??=
        isDark ? Colors.tealAccent[400] : primarySwatch[300];
    backgroundColor ??= isDark ? Colors.grey[700] : primarySwatch[200];
    dialogBackgroundColor ??= isDark ? Colors.grey[800] : Colors.white;
    indicatorColor ??= accentColor == primaryColor ? Colors.white : accentColor;
    hintColor ??= isDark ? const Color(0x80FFFFFF) : const Color(0x8A000000);
    errorColor ??= Colors.red[700];
    inputDecorationTheme ??= const InputDecorationTheme();
    pageTransitionsTheme ??= const PageTransitionsTheme();
    primaryIconTheme ??= primaryIsDark
        ? const IconThemeData(color: Colors.white)
        : const IconThemeData(color: Colors.black);
    accentIconTheme ??= accentIsDark
        ? const IconThemeData(color: Colors.white)
        : const IconThemeData(color: Colors.black);
    iconTheme ??= isDark
        ? const IconThemeData(color: Colors.white)
        : const IconThemeData(color: Colors.black87);
    platform ??= defaultTargetPlatform;
    typography ??= Typography(platform: platform);
    final TextTheme defaultTextTheme =
        isDark ? typography.white : typography.black;
    textTheme = defaultTextTheme.merge(textTheme);
    final TextTheme defaultPrimaryTextTheme =
        primaryIsDark ? typography.white : typography.black;
    primaryTextTheme = defaultPrimaryTextTheme.merge(primaryTextTheme);
    final TextTheme defaultAccentTextTheme =
        accentIsDark ? typography.white : typography.black;
    accentTextTheme = defaultAccentTextTheme.merge(accentTextTheme);
    materialTapTargetSize ??= MaterialTapTargetSize.padded;
    applyElevationOverlayColor ??= false;
    if (fontFamily != null) {
      textTheme = textTheme.apply(fontFamily: fontFamily);
      primaryTextTheme = primaryTextTheme.apply(fontFamily: fontFamily);
      accentTextTheme = accentTextTheme.apply(fontFamily: fontFamily);
    }

    buttonColor ??= isDark ? primarySwatch[600] : Colors.grey[300];
    focusColor ??= isDark
        ? Colors.white.withOpacity(0.12)
        : Colors.black.withOpacity(0.12);
    hoverColor ??= isDark
        ? Colors.white.withOpacity(0.04)
        : Colors.black.withOpacity(0.04);
    buttonTheme ??= ButtonThemeData(
      colorScheme: colorScheme,
      buttonColor: buttonColor,
      disabledColor: disabledColor,
      focusColor: focusColor,
      hoverColor: hoverColor,
      highlightColor: highlightColor,
      splashColor: splashColor,
      materialTapTargetSize: materialTapTargetSize,
    );
    toggleButtonsTheme ??= const ToggleButtonsThemeData();
    disabledColor ??= isDark ? Colors.white38 : Colors.black38;
    highlightColor ??=
        isDark ? _kDarkThemeHighlightColor : _kLightThemeHighlightColor;
    splashColor ??= isDark ? _kDarkThemeSplashColor : _kLightThemeSplashColor;

    sliderTheme ??= const SliderThemeData();
    tabBarTheme ??= const TabBarTheme();
    tooltipTheme ??= const TooltipThemeData();
    appBarTheme ??= const AppBarTheme();
    bottomAppBarTheme ??= const BottomAppBarTheme();
    cardTheme ??= const CardTheme();
    chipTheme ??= ChipThemeData.fromDefaults(
      secondaryColor: primaryColor,
      brightness: brightness,
      labelStyle: textTheme.body2,
    );
    dialogTheme ??= const DialogTheme();
    floatingActionButtonTheme ??= const FloatingActionButtonThemeData();
    cupertinoOverrideTheme = cupertinoOverrideTheme?.noDefault();
    snackBarTheme ??= const SnackBarThemeData();
    bottomSheetTheme ??= const BottomSheetThemeData();
    popupMenuTheme ??= const PopupMenuThemeData();

    return ThemeData.raw(
      brightness: brightness,
      primaryColor: primaryColor,
      primaryColorBrightness: primaryColorBrightness,
      primaryColorLight: primaryColorLight,
      primaryColorDark: primaryColorDark,
      accentColor: accentColor,
      accentColorBrightness: accentColorBrightness,
      canvasColor: canvasColor,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      bottomAppBarColor: bottomAppBarColor,
      cardColor: cardColor,
      dividerColor: dividerColor,
      focusColor: focusColor,
      hoverColor: hoverColor,
      highlightColor: highlightColor,
      splashColor: splashColor,
      splashFactory: splashFactory,
      selectedRowColor: selectedRowColor,
      unselectedWidgetColor: unselectedWidgetColor,
      disabledColor: disabledColor,
      buttonTheme: buttonTheme,
      buttonColor: buttonColor,
      toggleButtonsTheme: toggleButtonsTheme,
      toggleableActiveColor: toggleableActiveColor,
      secondaryHeaderColor: secondaryHeaderColor,
      textSelectionColor: textSelectionColor,
      cursorColor: cursorColor,
      textSelectionHandleColor: textSelectionHandleColor,
      backgroundColor: backgroundColor,
      dialogBackgroundColor: dialogBackgroundColor,
      indicatorColor: indicatorColor,
      hintColor: hintColor,
      errorColor: errorColor,
      textTheme: textTheme,
      primaryTextTheme: primaryTextTheme,
      accentTextTheme: accentTextTheme,
      inputDecorationTheme: inputDecorationTheme,
      iconTheme: iconTheme,
      primaryIconTheme: primaryIconTheme,
      accentIconTheme: accentIconTheme,
      sliderTheme: sliderTheme,
      tabBarTheme: tabBarTheme,
      tooltipTheme: tooltipTheme,
      cardTheme: cardTheme,
      chipTheme: chipTheme,
      platform: platform,
      materialTapTargetSize: materialTapTargetSize,
      applyElevationOverlayColor: applyElevationOverlayColor,
      pageTransitionsTheme: pageTransitionsTheme,
      appBarTheme: appBarTheme,
      bottomAppBarTheme: bottomAppBarTheme,
      colorScheme: colorScheme,
      dialogTheme: dialogTheme,
      floatingActionButtonTheme: floatingActionButtonTheme,
      typography: typography,
      cupertinoOverrideTheme: cupertinoOverrideTheme,
      snackBarTheme: snackBarTheme,
      bottomSheetTheme: bottomSheetTheme,
      popupMenuTheme: popupMenuTheme,
    );
  }

  const ThemeData.raw({
    @required this.brightness,
    @required this.primaryColor,
    @required this.primaryColorBrightness,
    @required this.primaryColorLight,
    @required this.primaryColorDark,
    @required this.canvasColor,
    @required this.accentColor,
    @required this.accentColorBrightness,
    @required this.scaffoldBackgroundColor,
    @required this.bottomAppBarColor,
    @required this.cardColor,
    @required this.dividerColor,
    @required this.focusColor,
    @required this.hoverColor,
    @required this.highlightColor,
    @required this.splashColor,
    @required this.splashFactory,
    @required this.selectedRowColor,
    @required this.unselectedWidgetColor,
    @required this.disabledColor,
    @required this.buttonTheme,
    @required this.buttonColor,
    @required this.toggleButtonsTheme,
    @required this.secondaryHeaderColor,
    @required this.textSelectionColor,
    @required this.cursorColor,
    @required this.textSelectionHandleColor,
    @required this.backgroundColor,
    @required this.dialogBackgroundColor,
    @required this.indicatorColor,
    @required this.hintColor,
    @required this.errorColor,
    @required this.toggleableActiveColor,
    @required this.textTheme,
    @required this.primaryTextTheme,
    @required this.accentTextTheme,
    @required this.inputDecorationTheme,
    @required this.iconTheme,
    @required this.primaryIconTheme,
    @required this.accentIconTheme,
    @required this.sliderTheme,
    @required this.tabBarTheme,
    @required this.tooltipTheme,
    @required this.cardTheme,
    @required this.chipTheme,
    @required this.platform,
    @required this.materialTapTargetSize,
    @required this.applyElevationOverlayColor,
    @required this.pageTransitionsTheme,
    @required this.appBarTheme,
    @required this.bottomAppBarTheme,
    @required this.colorScheme,
    @required this.dialogTheme,
    @required this.floatingActionButtonTheme,
    @required this.typography,
    @required this.cupertinoOverrideTheme,
    @required this.snackBarTheme,
    @required this.bottomSheetTheme,
    @required this.popupMenuTheme,
  })  : assert(brightness != null),
        assert(primaryColor != null),
        assert(primaryColorBrightness != null),
        assert(primaryColorLight != null),
        assert(primaryColorDark != null),
        assert(accentColor != null),
        assert(accentColorBrightness != null),
        assert(canvasColor != null),
        assert(scaffoldBackgroundColor != null),
        assert(bottomAppBarColor != null),
        assert(cardColor != null),
        assert(dividerColor != null),
        assert(focusColor != null),
        assert(hoverColor != null),
        assert(highlightColor != null),
        assert(splashColor != null),
        assert(splashFactory != null),
        assert(selectedRowColor != null),
        assert(unselectedWidgetColor != null),
        assert(disabledColor != null),
        assert(toggleableActiveColor != null),
        assert(buttonTheme != null),
        assert(toggleButtonsTheme != null),
        assert(secondaryHeaderColor != null),
        assert(textSelectionColor != null),
        assert(cursorColor != null),
        assert(textSelectionHandleColor != null),
        assert(backgroundColor != null),
        assert(dialogBackgroundColor != null),
        assert(indicatorColor != null),
        assert(hintColor != null),
        assert(errorColor != null),
        assert(textTheme != null),
        assert(primaryTextTheme != null),
        assert(accentTextTheme != null),
        assert(inputDecorationTheme != null),
        assert(iconTheme != null),
        assert(primaryIconTheme != null),
        assert(accentIconTheme != null),
        assert(sliderTheme != null),
        assert(tabBarTheme != null),
        assert(tooltipTheme != null),
        assert(cardTheme != null),
        assert(chipTheme != null),
        assert(platform != null),
        assert(materialTapTargetSize != null),
        assert(pageTransitionsTheme != null),
        assert(appBarTheme != null),
        assert(bottomAppBarTheme != null),
        assert(colorScheme != null),
        assert(dialogTheme != null),
        assert(floatingActionButtonTheme != null),
        assert(typography != null),
        assert(snackBarTheme != null),
        assert(bottomSheetTheme != null),
        assert(popupMenuTheme != null);

  factory ThemeData.light() => ThemeData(brightness: Brightness.light);

  factory ThemeData.dark() => ThemeData(brightness: Brightness.dark);

  factory ThemeData.fallback() => ThemeData.light();

  final Brightness brightness;

  final Color primaryColor;

  final Brightness primaryColorBrightness;

  final Color primaryColorLight;

  final Color primaryColorDark;

  final Color canvasColor;

  final Color accentColor;

  final Brightness accentColorBrightness;

  final Color scaffoldBackgroundColor;

  final Color bottomAppBarColor;

  final Color cardColor;

  final Color dividerColor;

  final Color focusColor;

  final Color hoverColor;

  final Color highlightColor;

  final Color splashColor;

  final InteractiveInkFeatureFactory splashFactory;

  final Color selectedRowColor;

  final Color unselectedWidgetColor;

  final Color disabledColor;

  final ButtonThemeData buttonTheme;

  final ToggleButtonsThemeData toggleButtonsTheme;

  final Color buttonColor;

  final Color secondaryHeaderColor;

  final Color textSelectionColor;

  final Color cursorColor;

  final Color textSelectionHandleColor;

  final Color backgroundColor;

  final Color dialogBackgroundColor;

  final Color indicatorColor;

  final Color hintColor;

  final Color errorColor;

  final Color toggleableActiveColor;

  final TextTheme textTheme;

  final TextTheme primaryTextTheme;

  final TextTheme accentTextTheme;

  final InputDecorationTheme inputDecorationTheme;

  final IconThemeData iconTheme;

  final IconThemeData primaryIconTheme;

  final IconThemeData accentIconTheme;

  final SliderThemeData sliderTheme;

  final TabBarTheme tabBarTheme;

  final TooltipThemeData tooltipTheme;

  final CardTheme cardTheme;

  final ChipThemeData chipTheme;

  final TargetPlatform platform;

  final MaterialTapTargetSize materialTapTargetSize;

  final bool applyElevationOverlayColor;

  final PageTransitionsTheme pageTransitionsTheme;

  final AppBarTheme appBarTheme;

  final BottomAppBarTheme bottomAppBarTheme;

  final ColorScheme colorScheme;

  final SnackBarThemeData snackBarTheme;

  final DialogTheme dialogTheme;

  final FloatingActionButtonThemeData floatingActionButtonTheme;

  final Typography typography;

  final CupertinoThemeData cupertinoOverrideTheme;

  final BottomSheetThemeData bottomSheetTheme;

  final PopupMenuThemeData popupMenuTheme;

  ThemeData copyWith({
    Brightness brightness,
    Color primaryColor,
    Brightness primaryColorBrightness,
    Color primaryColorLight,
    Color primaryColorDark,
    Color accentColor,
    Brightness accentColorBrightness,
    Color canvasColor,
    Color scaffoldBackgroundColor,
    Color bottomAppBarColor,
    Color cardColor,
    Color dividerColor,
    Color focusColor,
    Color hoverColor,
    Color highlightColor,
    Color splashColor,
    InteractiveInkFeatureFactory splashFactory,
    Color selectedRowColor,
    Color unselectedWidgetColor,
    Color disabledColor,
    ButtonThemeData buttonTheme,
    ToggleButtonsTheme toggleButtonsTheme,
    Color buttonColor,
    Color secondaryHeaderColor,
    Color textSelectionColor,
    Color cursorColor,
    Color textSelectionHandleColor,
    Color backgroundColor,
    Color dialogBackgroundColor,
    Color indicatorColor,
    Color hintColor,
    Color errorColor,
    Color toggleableActiveColor,
    TextTheme textTheme,
    TextTheme primaryTextTheme,
    TextTheme accentTextTheme,
    InputDecorationTheme inputDecorationTheme,
    IconThemeData iconTheme,
    IconThemeData primaryIconTheme,
    IconThemeData accentIconTheme,
    SliderThemeData sliderTheme,
    TabBarTheme tabBarTheme,
    TooltipThemeData tooltipTheme,
    CardTheme cardTheme,
    ChipThemeData chipTheme,
    TargetPlatform platform,
    MaterialTapTargetSize materialTapTargetSize,
    bool applyElevationOverlayColor,
    PageTransitionsTheme pageTransitionsTheme,
    AppBarTheme appBarTheme,
    BottomAppBarTheme bottomAppBarTheme,
    ColorScheme colorScheme,
    DialogTheme dialogTheme,
    FloatingActionButtonThemeData floatingActionButtonTheme,
    Typography typography,
    CupertinoThemeData cupertinoOverrideTheme,
    SnackBarThemeData snackBarTheme,
    BottomSheetThemeData bottomSheetTheme,
    PopupMenuThemeData popupMenuTheme,
  }) {
    cupertinoOverrideTheme = cupertinoOverrideTheme?.noDefault();
    return ThemeData.raw(
      brightness: brightness ?? this.brightness,
      primaryColor: primaryColor ?? this.primaryColor,
      primaryColorBrightness:
          primaryColorBrightness ?? this.primaryColorBrightness,
      primaryColorLight: primaryColorLight ?? this.primaryColorLight,
      primaryColorDark: primaryColorDark ?? this.primaryColorDark,
      accentColor: accentColor ?? this.accentColor,
      accentColorBrightness:
          accentColorBrightness ?? this.accentColorBrightness,
      canvasColor: canvasColor ?? this.canvasColor,
      scaffoldBackgroundColor:
          scaffoldBackgroundColor ?? this.scaffoldBackgroundColor,
      bottomAppBarColor: bottomAppBarColor ?? this.bottomAppBarColor,
      cardColor: cardColor ?? this.cardColor,
      dividerColor: dividerColor ?? this.dividerColor,
      focusColor: focusColor ?? this.focusColor,
      hoverColor: hoverColor ?? this.hoverColor,
      highlightColor: highlightColor ?? this.highlightColor,
      splashColor: splashColor ?? this.splashColor,
      splashFactory: splashFactory ?? this.splashFactory,
      selectedRowColor: selectedRowColor ?? this.selectedRowColor,
      unselectedWidgetColor:
          unselectedWidgetColor ?? this.unselectedWidgetColor,
      disabledColor: disabledColor ?? this.disabledColor,
      buttonColor: buttonColor ?? this.buttonColor,
      buttonTheme: buttonTheme ?? this.buttonTheme,
      toggleButtonsTheme: toggleButtonsTheme ?? this.toggleButtonsTheme,
      secondaryHeaderColor: secondaryHeaderColor ?? this.secondaryHeaderColor,
      textSelectionColor: textSelectionColor ?? this.textSelectionColor,
      cursorColor: cursorColor ?? this.cursorColor,
      textSelectionHandleColor:
          textSelectionHandleColor ?? this.textSelectionHandleColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      dialogBackgroundColor:
          dialogBackgroundColor ?? this.dialogBackgroundColor,
      indicatorColor: indicatorColor ?? this.indicatorColor,
      hintColor: hintColor ?? this.hintColor,
      errorColor: errorColor ?? this.errorColor,
      toggleableActiveColor:
          toggleableActiveColor ?? this.toggleableActiveColor,
      textTheme: textTheme ?? this.textTheme,
      primaryTextTheme: primaryTextTheme ?? this.primaryTextTheme,
      accentTextTheme: accentTextTheme ?? this.accentTextTheme,
      inputDecorationTheme: inputDecorationTheme ?? this.inputDecorationTheme,
      iconTheme: iconTheme ?? this.iconTheme,
      primaryIconTheme: primaryIconTheme ?? this.primaryIconTheme,
      accentIconTheme: accentIconTheme ?? this.accentIconTheme,
      sliderTheme: sliderTheme ?? this.sliderTheme,
      tabBarTheme: tabBarTheme ?? this.tabBarTheme,
      tooltipTheme: tooltipTheme ?? this.tooltipTheme,
      cardTheme: cardTheme ?? this.cardTheme,
      chipTheme: chipTheme ?? this.chipTheme,
      platform: platform ?? this.platform,
      materialTapTargetSize:
          materialTapTargetSize ?? this.materialTapTargetSize,
      applyElevationOverlayColor:
          applyElevationOverlayColor ?? this.applyElevationOverlayColor,
      pageTransitionsTheme: pageTransitionsTheme ?? this.pageTransitionsTheme,
      appBarTheme: appBarTheme ?? this.appBarTheme,
      bottomAppBarTheme: bottomAppBarTheme ?? this.bottomAppBarTheme,
      colorScheme: colorScheme ?? this.colorScheme,
      dialogTheme: dialogTheme ?? this.dialogTheme,
      floatingActionButtonTheme:
          floatingActionButtonTheme ?? this.floatingActionButtonTheme,
      typography: typography ?? this.typography,
      cupertinoOverrideTheme:
          cupertinoOverrideTheme ?? this.cupertinoOverrideTheme,
      snackBarTheme: snackBarTheme ?? this.snackBarTheme,
      bottomSheetTheme: bottomSheetTheme ?? this.bottomSheetTheme,
      popupMenuTheme: popupMenuTheme ?? this.popupMenuTheme,
    );
  }

  static const int _localizedThemeDataCacheSize = 5;

  static final _FifoCache<_IdentityThemeDataCacheKey, ThemeData>
      _localizedThemeDataCache =
      _FifoCache<_IdentityThemeDataCacheKey, ThemeData>(
          _localizedThemeDataCacheSize);

  static ThemeData localize(ThemeData baseTheme, TextTheme localTextGeometry) {
    assert(baseTheme != null);
    assert(localTextGeometry != null);

    return _localizedThemeDataCache.putIfAbsent(
      _IdentityThemeDataCacheKey(baseTheme, localTextGeometry),
      () {
        return baseTheme.copyWith(
          primaryTextTheme: localTextGeometry.merge(baseTheme.primaryTextTheme),
          accentTextTheme: localTextGeometry.merge(baseTheme.accentTextTheme),
          textTheme: localTextGeometry.merge(baseTheme.textTheme),
        );
      },
    );
  }

  static Brightness estimateBrightnessForColor(Color color) {
    final double relativeLuminance = color.computeLuminance();

    const double kThreshold = 0.15;
    if ((relativeLuminance + 0.05) * (relativeLuminance + 0.05) > kThreshold)
      return Brightness.light;
    return Brightness.dark;
  }

  static ThemeData lerp(ThemeData a, ThemeData b, double t) {
    assert(a != null);
    assert(b != null);
    assert(t != null);

    return ThemeData.raw(
      brightness: t < 0.5 ? a.brightness : b.brightness,
      primaryColor: Color.lerp(a.primaryColor, b.primaryColor, t),
      primaryColorBrightness:
          t < 0.5 ? a.primaryColorBrightness : b.primaryColorBrightness,
      primaryColorLight:
          Color.lerp(a.primaryColorLight, b.primaryColorLight, t),
      primaryColorDark: Color.lerp(a.primaryColorDark, b.primaryColorDark, t),
      canvasColor: Color.lerp(a.canvasColor, b.canvasColor, t),
      accentColor: Color.lerp(a.accentColor, b.accentColor, t),
      accentColorBrightness:
          t < 0.5 ? a.accentColorBrightness : b.accentColorBrightness,
      scaffoldBackgroundColor:
          Color.lerp(a.scaffoldBackgroundColor, b.scaffoldBackgroundColor, t),
      bottomAppBarColor:
          Color.lerp(a.bottomAppBarColor, b.bottomAppBarColor, t),
      cardColor: Color.lerp(a.cardColor, b.cardColor, t),
      dividerColor: Color.lerp(a.dividerColor, b.dividerColor, t),
      focusColor: Color.lerp(a.focusColor, b.focusColor, t),
      hoverColor: Color.lerp(a.hoverColor, b.hoverColor, t),
      highlightColor: Color.lerp(a.highlightColor, b.highlightColor, t),
      splashColor: Color.lerp(a.splashColor, b.splashColor, t),
      splashFactory: t < 0.5 ? a.splashFactory : b.splashFactory,
      selectedRowColor: Color.lerp(a.selectedRowColor, b.selectedRowColor, t),
      unselectedWidgetColor:
          Color.lerp(a.unselectedWidgetColor, b.unselectedWidgetColor, t),
      disabledColor: Color.lerp(a.disabledColor, b.disabledColor, t),
      buttonTheme: t < 0.5 ? a.buttonTheme : b.buttonTheme,
      toggleButtonsTheme: ToggleButtonsThemeData.lerp(
          a.toggleButtonsTheme, b.toggleButtonsTheme, t),
      buttonColor: Color.lerp(a.buttonColor, b.buttonColor, t),
      secondaryHeaderColor:
          Color.lerp(a.secondaryHeaderColor, b.secondaryHeaderColor, t),
      textSelectionColor:
          Color.lerp(a.textSelectionColor, b.textSelectionColor, t),
      cursorColor: Color.lerp(a.cursorColor, b.cursorColor, t),
      textSelectionHandleColor:
          Color.lerp(a.textSelectionHandleColor, b.textSelectionHandleColor, t),
      backgroundColor: Color.lerp(a.backgroundColor, b.backgroundColor, t),
      dialogBackgroundColor:
          Color.lerp(a.dialogBackgroundColor, b.dialogBackgroundColor, t),
      indicatorColor: Color.lerp(a.indicatorColor, b.indicatorColor, t),
      hintColor: Color.lerp(a.hintColor, b.hintColor, t),
      errorColor: Color.lerp(a.errorColor, b.errorColor, t),
      toggleableActiveColor:
          Color.lerp(a.toggleableActiveColor, b.toggleableActiveColor, t),
      textTheme: TextTheme.lerp(a.textTheme, b.textTheme, t),
      primaryTextTheme:
          TextTheme.lerp(a.primaryTextTheme, b.primaryTextTheme, t),
      accentTextTheme: TextTheme.lerp(a.accentTextTheme, b.accentTextTheme, t),
      inputDecorationTheme:
          t < 0.5 ? a.inputDecorationTheme : b.inputDecorationTheme,
      iconTheme: IconThemeData.lerp(a.iconTheme, b.iconTheme, t),
      primaryIconTheme:
          IconThemeData.lerp(a.primaryIconTheme, b.primaryIconTheme, t),
      accentIconTheme:
          IconThemeData.lerp(a.accentIconTheme, b.accentIconTheme, t),
      sliderTheme: SliderThemeData.lerp(a.sliderTheme, b.sliderTheme, t),
      tabBarTheme: TabBarTheme.lerp(a.tabBarTheme, b.tabBarTheme, t),
      tooltipTheme: TooltipThemeData.lerp(a.tooltipTheme, b.tooltipTheme, t),
      cardTheme: CardTheme.lerp(a.cardTheme, b.cardTheme, t),
      chipTheme: ChipThemeData.lerp(a.chipTheme, b.chipTheme, t),
      platform: t < 0.5 ? a.platform : b.platform,
      materialTapTargetSize:
          t < 0.5 ? a.materialTapTargetSize : b.materialTapTargetSize,
      applyElevationOverlayColor:
          t < 0.5 ? a.applyElevationOverlayColor : b.applyElevationOverlayColor,
      pageTransitionsTheme:
          t < 0.5 ? a.pageTransitionsTheme : b.pageTransitionsTheme,
      appBarTheme: AppBarTheme.lerp(a.appBarTheme, b.appBarTheme, t),
      bottomAppBarTheme:
          BottomAppBarTheme.lerp(a.bottomAppBarTheme, b.bottomAppBarTheme, t),
      colorScheme: ColorScheme.lerp(a.colorScheme, b.colorScheme, t),
      dialogTheme: DialogTheme.lerp(a.dialogTheme, b.dialogTheme, t),
      floatingActionButtonTheme: FloatingActionButtonThemeData.lerp(
          a.floatingActionButtonTheme, b.floatingActionButtonTheme, t),
      typography: Typography.lerp(a.typography, b.typography, t),
      cupertinoOverrideTheme:
          t < 0.5 ? a.cupertinoOverrideTheme : b.cupertinoOverrideTheme,
      snackBarTheme:
          SnackBarThemeData.lerp(a.snackBarTheme, b.snackBarTheme, t),
      bottomSheetTheme:
          BottomSheetThemeData.lerp(a.bottomSheetTheme, b.bottomSheetTheme, t),
      popupMenuTheme:
          PopupMenuThemeData.lerp(a.popupMenuTheme, b.popupMenuTheme, t),
    );
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    final ThemeData otherData = other;

    return (otherData.brightness == brightness) &&
        (otherData.primaryColor == primaryColor) &&
        (otherData.primaryColorBrightness == primaryColorBrightness) &&
        (otherData.primaryColorLight == primaryColorLight) &&
        (otherData.primaryColorDark == primaryColorDark) &&
        (otherData.accentColor == accentColor) &&
        (otherData.accentColorBrightness == accentColorBrightness) &&
        (otherData.canvasColor == canvasColor) &&
        (otherData.scaffoldBackgroundColor == scaffoldBackgroundColor) &&
        (otherData.bottomAppBarColor == bottomAppBarColor) &&
        (otherData.cardColor == cardColor) &&
        (otherData.dividerColor == dividerColor) &&
        (otherData.highlightColor == highlightColor) &&
        (otherData.splashColor == splashColor) &&
        (otherData.splashFactory == splashFactory) &&
        (otherData.selectedRowColor == selectedRowColor) &&
        (otherData.unselectedWidgetColor == unselectedWidgetColor) &&
        (otherData.disabledColor == disabledColor) &&
        (otherData.buttonTheme == buttonTheme) &&
        (otherData.buttonColor == buttonColor) &&
        (otherData.toggleButtonsTheme == toggleButtonsTheme) &&
        (otherData.secondaryHeaderColor == secondaryHeaderColor) &&
        (otherData.textSelectionColor == textSelectionColor) &&
        (otherData.cursorColor == cursorColor) &&
        (otherData.textSelectionHandleColor == textSelectionHandleColor) &&
        (otherData.backgroundColor == backgroundColor) &&
        (otherData.dialogBackgroundColor == dialogBackgroundColor) &&
        (otherData.indicatorColor == indicatorColor) &&
        (otherData.hintColor == hintColor) &&
        (otherData.errorColor == errorColor) &&
        (otherData.toggleableActiveColor == toggleableActiveColor) &&
        (otherData.textTheme == textTheme) &&
        (otherData.primaryTextTheme == primaryTextTheme) &&
        (otherData.accentTextTheme == accentTextTheme) &&
        (otherData.inputDecorationTheme == inputDecorationTheme) &&
        (otherData.iconTheme == iconTheme) &&
        (otherData.primaryIconTheme == primaryIconTheme) &&
        (otherData.accentIconTheme == accentIconTheme) &&
        (otherData.sliderTheme == sliderTheme) &&
        (otherData.tabBarTheme == tabBarTheme) &&
        (otherData.tooltipTheme == tooltipTheme) &&
        (otherData.cardTheme == cardTheme) &&
        (otherData.chipTheme == chipTheme) &&
        (otherData.platform == platform) &&
        (otherData.materialTapTargetSize == materialTapTargetSize) &&
        (otherData.applyElevationOverlayColor == applyElevationOverlayColor) &&
        (otherData.pageTransitionsTheme == pageTransitionsTheme) &&
        (otherData.appBarTheme == appBarTheme) &&
        (otherData.bottomAppBarTheme == bottomAppBarTheme) &&
        (otherData.colorScheme == colorScheme) &&
        (otherData.dialogTheme == dialogTheme) &&
        (otherData.floatingActionButtonTheme == floatingActionButtonTheme) &&
        (otherData.typography == typography) &&
        (otherData.cupertinoOverrideTheme == cupertinoOverrideTheme) &&
        (otherData.snackBarTheme == snackBarTheme) &&
        (otherData.bottomSheetTheme == bottomSheetTheme) &&
        (otherData.popupMenuTheme == popupMenuTheme);
  }

  @override
  int get hashCode {
    final List<Object> values = <Object>[
      brightness,
      primaryColor,
      primaryColorBrightness,
      primaryColorLight,
      primaryColorDark,
      accentColor,
      accentColorBrightness,
      canvasColor,
      scaffoldBackgroundColor,
      bottomAppBarColor,
      cardColor,
      dividerColor,
      focusColor,
      hoverColor,
      highlightColor,
      splashColor,
      splashFactory,
      selectedRowColor,
      unselectedWidgetColor,
      disabledColor,
      buttonTheme,
      buttonColor,
      toggleButtonsTheme,
      toggleableActiveColor,
      secondaryHeaderColor,
      textSelectionColor,
      cursorColor,
      textSelectionHandleColor,
      backgroundColor,
      dialogBackgroundColor,
      indicatorColor,
      hintColor,
      errorColor,
      textTheme,
      primaryTextTheme,
      accentTextTheme,
      inputDecorationTheme,
      iconTheme,
      primaryIconTheme,
      accentIconTheme,
      sliderTheme,
      tabBarTheme,
      tooltipTheme,
      cardTheme,
      chipTheme,
      platform,
      materialTapTargetSize,
      applyElevationOverlayColor,
      pageTransitionsTheme,
      appBarTheme,
      bottomAppBarTheme,
      colorScheme,
      dialogTheme,
      floatingActionButtonTheme,
      typography,
      cupertinoOverrideTheme,
      snackBarTheme,
      bottomSheetTheme,
      popupMenuTheme,
    ];
    return hashList(values);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    final ThemeData defaultData = ThemeData.fallback();
    properties.add(EnumProperty<TargetPlatform>('platform', platform,
        defaultValue: defaultTargetPlatform));
    properties.add(EnumProperty<Brightness>('brightness', brightness,
        defaultValue: defaultData.brightness));
    properties.add(ColorProperty('primaryColor', primaryColor,
        defaultValue: defaultData.primaryColor));
    properties.add(EnumProperty<Brightness>(
        'primaryColorBrightness', primaryColorBrightness,
        defaultValue: defaultData.primaryColorBrightness));
    properties.add(ColorProperty('accentColor', accentColor,
        defaultValue: defaultData.accentColor));
    properties.add(EnumProperty<Brightness>(
        'accentColorBrightness', accentColorBrightness,
        defaultValue: defaultData.accentColorBrightness));
    properties.add(ColorProperty('canvasColor', canvasColor,
        defaultValue: defaultData.canvasColor));
    properties.add(ColorProperty(
        'scaffoldBackgroundColor', scaffoldBackgroundColor,
        defaultValue: defaultData.scaffoldBackgroundColor));
    properties.add(ColorProperty('bottomAppBarColor', bottomAppBarColor,
        defaultValue: defaultData.bottomAppBarColor));
    properties.add(ColorProperty('cardColor', cardColor,
        defaultValue: defaultData.cardColor));
    properties.add(ColorProperty('dividerColor', dividerColor,
        defaultValue: defaultData.dividerColor));
    properties.add(ColorProperty('focusColor', focusColor,
        defaultValue: defaultData.focusColor));
    properties.add(ColorProperty('hoverColor', hoverColor,
        defaultValue: defaultData.hoverColor));
    properties.add(ColorProperty('highlightColor', highlightColor,
        defaultValue: defaultData.highlightColor));
    properties.add(ColorProperty('splashColor', splashColor,
        defaultValue: defaultData.splashColor));
    properties.add(ColorProperty('selectedRowColor', selectedRowColor,
        defaultValue: defaultData.selectedRowColor));
    properties.add(ColorProperty('unselectedWidgetColor', unselectedWidgetColor,
        defaultValue: defaultData.unselectedWidgetColor));
    properties.add(ColorProperty('disabledColor', disabledColor,
        defaultValue: defaultData.disabledColor));
    properties.add(ColorProperty('buttonColor', buttonColor,
        defaultValue: defaultData.buttonColor));
    properties.add(ColorProperty('secondaryHeaderColor', secondaryHeaderColor,
        defaultValue: defaultData.secondaryHeaderColor));
    properties.add(ColorProperty('textSelectionColor', textSelectionColor,
        defaultValue: defaultData.textSelectionColor));
    properties.add(ColorProperty('cursorColor', cursorColor,
        defaultValue: defaultData.cursorColor));
    properties.add(ColorProperty(
        'textSelectionHandleColor', textSelectionHandleColor,
        defaultValue: defaultData.textSelectionHandleColor));
    properties.add(ColorProperty('backgroundColor', backgroundColor,
        defaultValue: defaultData.backgroundColor));
    properties.add(ColorProperty('dialogBackgroundColor', dialogBackgroundColor,
        defaultValue: defaultData.dialogBackgroundColor));
    properties.add(ColorProperty('indicatorColor', indicatorColor,
        defaultValue: defaultData.indicatorColor));
    properties.add(ColorProperty('hintColor', hintColor,
        defaultValue: defaultData.hintColor));
    properties.add(ColorProperty('errorColor', errorColor,
        defaultValue: defaultData.errorColor));
    properties.add(ColorProperty('toggleableActiveColor', toggleableActiveColor,
        defaultValue: defaultData.toggleableActiveColor));
    properties
        .add(DiagnosticsProperty<ButtonThemeData>('buttonTheme', buttonTheme));
    properties.add(DiagnosticsProperty<ToggleButtonsThemeData>(
        'toggleButtonsTheme', toggleButtonsTheme));
    properties.add(DiagnosticsProperty<TextTheme>('textTheme', textTheme));
    properties.add(
        DiagnosticsProperty<TextTheme>('primaryTextTheme', primaryTextTheme));
    properties.add(
        DiagnosticsProperty<TextTheme>('accentTextTheme', accentTextTheme));
    properties.add(DiagnosticsProperty<InputDecorationTheme>(
        'inputDecorationTheme', inputDecorationTheme));
    properties.add(DiagnosticsProperty<IconThemeData>('iconTheme', iconTheme));
    properties.add(DiagnosticsProperty<IconThemeData>(
        'primaryIconTheme', primaryIconTheme));
    properties.add(
        DiagnosticsProperty<IconThemeData>('accentIconTheme', accentIconTheme));
    properties
        .add(DiagnosticsProperty<SliderThemeData>('sliderTheme', sliderTheme));
    properties
        .add(DiagnosticsProperty<TabBarTheme>('tabBarTheme', tabBarTheme));
    properties.add(
        DiagnosticsProperty<TooltipThemeData>('tooltipTheme', tooltipTheme));
    properties.add(DiagnosticsProperty<CardTheme>('cardTheme', cardTheme));
    properties.add(DiagnosticsProperty<ChipThemeData>('chipTheme', chipTheme));
    properties.add(DiagnosticsProperty<MaterialTapTargetSize>(
        'materialTapTargetSize', materialTapTargetSize));
    properties.add(DiagnosticsProperty<bool>(
        'applyElevationOverlayColor', applyElevationOverlayColor));
    properties.add(DiagnosticsProperty<PageTransitionsTheme>(
        'pageTransitionsTheme', pageTransitionsTheme));
    properties.add(DiagnosticsProperty<AppBarTheme>('appBarTheme', appBarTheme,
        defaultValue: defaultData.appBarTheme));
    properties.add(DiagnosticsProperty<BottomAppBarTheme>(
        'bottomAppBarTheme', bottomAppBarTheme,
        defaultValue: defaultData.bottomAppBarTheme));
    properties.add(DiagnosticsProperty<ColorScheme>('colorScheme', colorScheme,
        defaultValue: defaultData.colorScheme));
    properties.add(DiagnosticsProperty<DialogTheme>('dialogTheme', dialogTheme,
        defaultValue: defaultData.dialogTheme));
    properties.add(DiagnosticsProperty<FloatingActionButtonThemeData>(
        'floatingActionButtonThemeData', floatingActionButtonTheme,
        defaultValue: defaultData.floatingActionButtonTheme));
    properties.add(DiagnosticsProperty<Typography>('typography', typography,
        defaultValue: defaultData.typography));
    properties.add(DiagnosticsProperty<CupertinoThemeData>(
        'cupertinoOverrideTheme', cupertinoOverrideTheme,
        defaultValue: defaultData.cupertinoOverrideTheme));
    properties.add(DiagnosticsProperty<SnackBarThemeData>(
        'snackBarTheme', snackBarTheme,
        defaultValue: defaultData.snackBarTheme));
    properties.add(DiagnosticsProperty<BottomSheetThemeData>(
        'bottomSheetTheme', bottomSheetTheme,
        defaultValue: defaultData.bottomSheetTheme));
    properties.add(DiagnosticsProperty<PopupMenuThemeData>(
        'popupMenuTheme', popupMenuTheme,
        defaultValue: defaultData.popupMenuTheme));
  }
}

class MaterialBasedCupertinoThemeData extends CupertinoThemeData {
  MaterialBasedCupertinoThemeData({
    @required ThemeData materialTheme,
  })  : assert(materialTheme != null),
        _materialTheme = materialTheme,
        super.raw(
          materialTheme.cupertinoOverrideTheme?.brightness,
          materialTheme.cupertinoOverrideTheme?.primaryColor,
          materialTheme.cupertinoOverrideTheme?.primaryContrastingColor,
          materialTheme.cupertinoOverrideTheme?.textTheme,
          materialTheme.cupertinoOverrideTheme?.barBackgroundColor,
          materialTheme.cupertinoOverrideTheme?.scaffoldBackgroundColor,
        );

  final ThemeData _materialTheme;

  @override
  Brightness get brightness =>
      _materialTheme.cupertinoOverrideTheme?.brightness ??
      _materialTheme.brightness;

  @override
  Color get primaryColor =>
      _materialTheme.cupertinoOverrideTheme?.primaryColor ??
      _materialTheme.colorScheme.primary;

  @override
  Color get primaryContrastingColor =>
      _materialTheme.cupertinoOverrideTheme?.primaryContrastingColor ??
      _materialTheme.colorScheme.onPrimary;

  @override
  Color get scaffoldBackgroundColor =>
      _materialTheme.cupertinoOverrideTheme?.scaffoldBackgroundColor ??
      _materialTheme.scaffoldBackgroundColor;

  @override
  CupertinoThemeData copyWith({
    Brightness brightness,
    Color primaryColor,
    Color primaryContrastingColor,
    CupertinoTextThemeData textTheme,
    Color barBackgroundColor,
    Color scaffoldBackgroundColor,
  }) {
    return _materialTheme.cupertinoOverrideTheme?.copyWith(
          brightness: brightness,
          primaryColor: primaryColor,
          primaryContrastingColor: primaryContrastingColor,
          textTheme: textTheme,
          barBackgroundColor: barBackgroundColor,
          scaffoldBackgroundColor: scaffoldBackgroundColor,
        ) ??
        CupertinoThemeData(
          brightness: brightness,
          primaryColor: primaryColor,
          primaryContrastingColor: primaryContrastingColor,
          textTheme: textTheme,
          barBackgroundColor: barBackgroundColor,
          scaffoldBackgroundColor: scaffoldBackgroundColor,
        );
  }
}

class _IdentityThemeDataCacheKey {
  _IdentityThemeDataCacheKey(this.baseTheme, this.localTextGeometry);

  final ThemeData baseTheme;
  final TextTheme localTextGeometry;

  @override
  int get hashCode =>
      identityHashCode(baseTheme) ^ identityHashCode(localTextGeometry);

  @override
  bool operator ==(Object other) {
    final _IdentityThemeDataCacheKey otherKey = other;
    return identical(baseTheme, otherKey.baseTheme) &&
        identical(localTextGeometry, otherKey.localTextGeometry);
  }
}

class _FifoCache<K, V> {
  _FifoCache(this._maximumSize)
      : assert(_maximumSize != null && _maximumSize > 0);

  final Map<K, V> _cache = <K, V>{};

  final int _maximumSize;

  V putIfAbsent(K key, V loader()) {
    assert(key != null);
    assert(loader != null);
    final V result = _cache[key];
    if (result != null) return result;
    if (_cache.length == _maximumSize) _cache.remove(_cache.keys.first);
    return _cache[key] = loader();
  }
}

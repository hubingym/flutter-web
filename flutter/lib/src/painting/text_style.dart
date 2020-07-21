import 'package:flutter_web/ui.dart' as ui
    show ParagraphStyle, TextStyle, StrutStyle, lerpDouble, Shadow;

import 'package:flutter_web/foundation.dart';

import 'basic_types.dart';
import 'strut_style.dart';

const String _kDefaultDebugLabel = 'unknown';

const String _kColorForegroundWarning =
    'Cannot provide both a color and a foreground\n'
    'The color argument is just a shorthand for "foreground: new Paint()..color = color".';

const String _kColorBackgroundWarning =
    'Cannot provide both a backgroundColor and a background\n'
    'The backgroundColor argument is just a shorthand for "background: new Paint()..color = color".';

@immutable
class TextStyle extends Diagnosticable {
  const TextStyle({
    this.inherit = true,
    this.color,
    this.backgroundColor,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
    this.letterSpacing,
    this.wordSpacing,
    this.textBaseline,
    this.height,
    this.locale,
    this.foreground,
    this.background,
    this.shadows,
    this.decoration,
    this.decorationColor,
    this.decorationStyle,
    this.decorationThickness,
    this.debugLabel,
    String fontFamily,
    List<String> fontFamilyFallback,
    String package,
  })  : fontFamily =
            package == null ? fontFamily : 'packages/$package/$fontFamily',
        _fontFamilyFallback = fontFamilyFallback,
        _package = package,
        assert(inherit != null),
        assert(color == null || foreground == null, _kColorForegroundWarning),
        assert(backgroundColor == null || background == null,
            _kColorBackgroundWarning);

  final bool inherit;

  final Color color;

  final Color backgroundColor;

  final String fontFamily;

  List<String> get fontFamilyFallback =>
      _package != null && _fontFamilyFallback != null
          ? _fontFamilyFallback
              .map((String str) => 'packages/$_package/$str')
              .toList()
          : _fontFamilyFallback;
  final List<String> _fontFamilyFallback;

  final String _package;

  final double fontSize;

  static const double _defaultFontSize = 14.0;

  final FontWeight fontWeight;

  final FontStyle fontStyle;

  final double letterSpacing;

  final double wordSpacing;

  final TextBaseline textBaseline;

  final double height;

  final Locale locale;

  final Paint foreground;

  final Paint background;

  final TextDecoration decoration;

  final Color decorationColor;

  final TextDecorationStyle decorationStyle;

  final double decorationThickness;

  final String debugLabel;

  final List<ui.Shadow> shadows;

  TextStyle copyWith({
    bool inherit,
    Color color,
    Color backgroundColor,
    String fontFamily,
    List<String> fontFamilyFallback,
    double fontSize,
    FontWeight fontWeight,
    FontStyle fontStyle,
    double letterSpacing,
    double wordSpacing,
    TextBaseline textBaseline,
    double height,
    Locale locale,
    Paint foreground,
    Paint background,
    List<ui.Shadow> shadows,
    TextDecoration decoration,
    Color decorationColor,
    TextDecorationStyle decorationStyle,
    double decorationThickness,
    String debugLabel,
  }) {
    assert(color == null || foreground == null, _kColorForegroundWarning);
    assert(backgroundColor == null || background == null,
        _kColorBackgroundWarning);
    String newDebugLabel;
    assert(() {
      if (this.debugLabel != null)
        newDebugLabel = debugLabel ?? '(${this.debugLabel}).copyWith';
      return true;
    }());
    return TextStyle(
      inherit: inherit ?? this.inherit,
      color: this.foreground == null && foreground == null
          ? color ?? this.color
          : null,
      backgroundColor: this.background == null && background == null
          ? backgroundColor ?? this.backgroundColor
          : null,
      fontFamily: fontFamily ?? this.fontFamily,
      fontFamilyFallback: fontFamilyFallback ?? this.fontFamilyFallback,
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight ?? this.fontWeight,
      fontStyle: fontStyle ?? this.fontStyle,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      wordSpacing: wordSpacing ?? this.wordSpacing,
      textBaseline: textBaseline ?? this.textBaseline,
      height: height ?? this.height,
      locale: locale ?? this.locale,
      foreground: foreground ?? this.foreground,
      background: background ?? this.background,
      shadows: shadows ?? this.shadows,
      decoration: decoration ?? this.decoration,
      decorationColor: decorationColor ?? this.decorationColor,
      decorationStyle: decorationStyle ?? this.decorationStyle,
      decorationThickness: decorationThickness ?? this.decorationThickness,
      debugLabel: newDebugLabel,
    );
  }

  TextStyle apply({
    Color color,
    Color backgroundColor,
    TextDecoration decoration,
    Color decorationColor,
    TextDecorationStyle decorationStyle,
    double decorationThicknessFactor = 1.0,
    double decorationThicknessDelta = 0.0,
    String fontFamily,
    List<String> fontFamilyFallback,
    double fontSizeFactor = 1.0,
    double fontSizeDelta = 0.0,
    int fontWeightDelta = 0,
    double letterSpacingFactor = 1.0,
    double letterSpacingDelta = 0.0,
    double wordSpacingFactor = 1.0,
    double wordSpacingDelta = 0.0,
    double heightFactor = 1.0,
    double heightDelta = 0.0,
  }) {
    assert(fontSizeFactor != null);
    assert(fontSizeDelta != null);
    assert(fontSize != null || (fontSizeFactor == 1.0 && fontSizeDelta == 0.0));
    assert(fontWeightDelta != null);
    assert(fontWeight != null || fontWeightDelta == 0.0);
    assert(letterSpacingFactor != null);
    assert(letterSpacingDelta != null);
    assert(letterSpacing != null ||
        (letterSpacingFactor == 1.0 && letterSpacingDelta == 0.0));
    assert(wordSpacingFactor != null);
    assert(wordSpacingDelta != null);
    assert(wordSpacing != null ||
        (wordSpacingFactor == 1.0 && wordSpacingDelta == 0.0));
    assert(heightFactor != null);
    assert(heightDelta != null);
    assert(heightFactor != null || (heightFactor == 1.0 && heightDelta == 0.0));
    assert(decorationThicknessFactor != null);
    assert(decorationThicknessDelta != null);
    assert(decorationThickness != null ||
        (decorationThicknessFactor == 1.0 && decorationThicknessDelta == 0.0));

    String modifiedDebugLabel;
    assert(() {
      if (debugLabel != null) modifiedDebugLabel = '($debugLabel).apply';
      return true;
    }());

    return TextStyle(
      inherit: inherit,
      color: foreground == null ? color ?? this.color : null,
      backgroundColor:
          background == null ? backgroundColor ?? this.backgroundColor : null,
      fontFamily: fontFamily ?? this.fontFamily,
      fontFamilyFallback: fontFamilyFallback ?? this.fontFamilyFallback,
      fontSize:
          fontSize == null ? null : fontSize * fontSizeFactor + fontSizeDelta,
      fontWeight: fontWeight == null
          ? null
          : FontWeight.values[(fontWeight.index + fontWeightDelta)
              .clamp(0, FontWeight.values.length - 1)],
      fontStyle: fontStyle,
      letterSpacing: letterSpacing == null
          ? null
          : letterSpacing * letterSpacingFactor + letterSpacingDelta,
      wordSpacing: wordSpacing == null
          ? null
          : wordSpacing * wordSpacingFactor + wordSpacingDelta,
      textBaseline: textBaseline,
      height: height == null ? null : height * heightFactor + heightDelta,
      locale: locale,
      foreground: foreground,
      background: background,
      shadows: shadows,
      decoration: decoration ?? this.decoration,
      decorationColor: decorationColor ?? this.decorationColor,
      decorationStyle: decorationStyle ?? this.decorationStyle,
      decorationThickness: decorationThickness == null
          ? null
          : decorationThickness * decorationThicknessFactor +
              decorationThicknessDelta,
      debugLabel: modifiedDebugLabel,
    );
  }

  TextStyle merge(TextStyle other) {
    if (other == null) return this;
    if (!other.inherit) return other;

    String mergedDebugLabel;
    assert(() {
      if (other.debugLabel != null || debugLabel != null)
        mergedDebugLabel =
            '(${debugLabel ?? _kDefaultDebugLabel}).merge(${other.debugLabel ?? _kDefaultDebugLabel})';
      return true;
    }());

    return copyWith(
      color: other.color,
      backgroundColor: other.backgroundColor,
      fontFamily: other.fontFamily,
      fontFamilyFallback: other.fontFamilyFallback,
      fontSize: other.fontSize,
      fontWeight: other.fontWeight,
      fontStyle: other.fontStyle,
      letterSpacing: other.letterSpacing,
      wordSpacing: other.wordSpacing,
      textBaseline: other.textBaseline,
      height: other.height,
      locale: other.locale,
      foreground: other.foreground,
      background: other.background,
      shadows: other.shadows,
      decoration: other.decoration,
      decorationColor: other.decorationColor,
      decorationStyle: other.decorationStyle,
      decorationThickness: other.decorationThickness,
      debugLabel: mergedDebugLabel,
    );
  }

  static TextStyle lerp(TextStyle a, TextStyle b, double t) {
    assert(t != null);
    assert(a == null || b == null || a.inherit == b.inherit);
    if (a == null && b == null) {
      return null;
    }

    String lerpDebugLabel;
    assert(() {
      lerpDebugLabel =
          'lerp(${a?.debugLabel ?? _kDefaultDebugLabel} ⎯${t.toStringAsFixed(1)}→ ${b?.debugLabel ?? _kDefaultDebugLabel})';
      return true;
    }());

    if (a == null) {
      return TextStyle(
        inherit: b.inherit,
        color: Color.lerp(null, b.color, t),
        backgroundColor: Color.lerp(null, b.backgroundColor, t),
        fontFamily: t < 0.5 ? null : b.fontFamily,
        fontFamilyFallback: t < 0.5 ? null : b.fontFamilyFallback,
        fontSize: t < 0.5 ? null : b.fontSize,
        fontWeight: FontWeight.lerp(null, b.fontWeight, t),
        fontStyle: t < 0.5 ? null : b.fontStyle,
        letterSpacing: t < 0.5 ? null : b.letterSpacing,
        wordSpacing: t < 0.5 ? null : b.wordSpacing,
        textBaseline: t < 0.5 ? null : b.textBaseline,
        height: t < 0.5 ? null : b.height,
        locale: t < 0.5 ? null : b.locale,
        foreground: t < 0.5 ? null : b.foreground,
        background: t < 0.5 ? null : b.background,
        decoration: t < 0.5 ? null : b.decoration,
        shadows: t < 0.5 ? null : b.shadows,
        decorationColor: Color.lerp(null, b.decorationColor, t),
        decorationStyle: t < 0.5 ? null : b.decorationStyle,
        decorationThickness: t < 0.5 ? null : b.decorationThickness,
        debugLabel: lerpDebugLabel,
      );
    }

    if (b == null) {
      return TextStyle(
        inherit: a.inherit,
        color: Color.lerp(a.color, null, t),
        backgroundColor: Color.lerp(null, a.backgroundColor, t),
        fontFamily: t < 0.5 ? a.fontFamily : null,
        fontFamilyFallback: t < 0.5 ? a.fontFamilyFallback : null,
        fontSize: t < 0.5 ? a.fontSize : null,
        fontWeight: FontWeight.lerp(a.fontWeight, null, t),
        fontStyle: t < 0.5 ? a.fontStyle : null,
        letterSpacing: t < 0.5 ? a.letterSpacing : null,
        wordSpacing: t < 0.5 ? a.wordSpacing : null,
        textBaseline: t < 0.5 ? a.textBaseline : null,
        height: t < 0.5 ? a.height : null,
        locale: t < 0.5 ? a.locale : null,
        foreground: t < 0.5 ? a.foreground : null,
        background: t < 0.5 ? a.background : null,
        shadows: t < 0.5 ? a.shadows : null,
        decoration: t < 0.5 ? a.decoration : null,
        decorationColor: Color.lerp(a.decorationColor, null, t),
        decorationStyle: t < 0.5 ? a.decorationStyle : null,
        decorationThickness: t < 0.5 ? a.decorationThickness : null,
        debugLabel: lerpDebugLabel,
      );
    }

    return TextStyle(
      inherit: b.inherit,
      color: a.foreground == null && b.foreground == null
          ? Color.lerp(a.color, b.color, t)
          : null,
      backgroundColor: a.background == null && b.background == null
          ? Color.lerp(a.backgroundColor, b.backgroundColor, t)
          : null,
      fontFamily: t < 0.5 ? a.fontFamily : b.fontFamily,
      fontFamilyFallback: t < 0.5 ? a.fontFamilyFallback : b.fontFamilyFallback,
      fontSize:
          ui.lerpDouble(a.fontSize ?? b.fontSize, b.fontSize ?? a.fontSize, t),
      fontWeight: FontWeight.lerp(a.fontWeight, b.fontWeight, t),
      fontStyle: t < 0.5 ? a.fontStyle : b.fontStyle,
      letterSpacing: ui.lerpDouble(a.letterSpacing ?? b.letterSpacing,
          b.letterSpacing ?? a.letterSpacing, t),
      wordSpacing: ui.lerpDouble(
          a.wordSpacing ?? b.wordSpacing, b.wordSpacing ?? a.wordSpacing, t),
      textBaseline: t < 0.5 ? a.textBaseline : b.textBaseline,
      height: ui.lerpDouble(a.height ?? b.height, b.height ?? a.height, t),
      locale: t < 0.5 ? a.locale : b.locale,
      foreground: (a.foreground != null || b.foreground != null)
          ? t < 0.5
              ? a.foreground ?? (Paint()..color = a.color)
              : b.foreground ?? (Paint()..color = b.color)
          : null,
      background: (a.background != null || b.background != null)
          ? t < 0.5
              ? a.background ?? (Paint()..color = a.backgroundColor)
              : b.background ?? (Paint()..color = b.backgroundColor)
          : null,
      shadows: t < 0.5 ? a.shadows : b.shadows,
      decoration: t < 0.5 ? a.decoration : b.decoration,
      decorationColor: Color.lerp(a.decorationColor, b.decorationColor, t),
      decorationStyle: t < 0.5 ? a.decorationStyle : b.decorationStyle,
      decorationThickness: ui.lerpDouble(
          a.decorationThickness ?? b.decorationThickness,
          b.decorationThickness ?? a.decorationThickness,
          t),
      debugLabel: lerpDebugLabel,
    );
  }

  ui.TextStyle getTextStyle({double textScaleFactor = 1.0}) {
    return ui.TextStyle(
      color: color,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      decorationThickness: decorationThickness,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      textBaseline: textBaseline,
      fontFamily: fontFamily,
      fontFamilyFallback: fontFamilyFallback,
      fontSize: fontSize == null ? null : fontSize * textScaleFactor,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      height: height,
      locale: locale,
      foreground: foreground,
      background: background ??
          (backgroundColor != null ? (Paint()..color = backgroundColor) : null),
      shadows: shadows,
    );
  }

  ui.ParagraphStyle getParagraphStyle({
    TextAlign textAlign,
    TextDirection textDirection,
    double textScaleFactor = 1.0,
    String ellipsis,
    int maxLines,
    Locale locale,
    String fontFamily,
    double fontSize,
    FontWeight fontWeight,
    FontStyle fontStyle,
    double height,
    StrutStyle strutStyle,
  }) {
    assert(textScaleFactor != null);
    assert(maxLines == null || maxLines > 0);
    return ui.ParagraphStyle(
      textAlign: textAlign,
      textDirection: textDirection,
      fontWeight: fontWeight ?? this.fontWeight,
      fontStyle: fontStyle ?? this.fontStyle,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize:
          (fontSize ?? this.fontSize ?? _defaultFontSize) * textScaleFactor,
      height: height ?? this.height,
      strutStyle: strutStyle == null
          ? null
          : ui.StrutStyle(
              fontFamily: strutStyle.fontFamily,
              fontFamilyFallback: strutStyle.fontFamilyFallback,
              fontSize: strutStyle.fontSize,
              height: strutStyle.height,
              leading: strutStyle.leading,
              fontWeight: strutStyle.fontWeight,
              fontStyle: strutStyle.fontStyle,
              forceStrutHeight: strutStyle.forceStrutHeight,
            ),
      maxLines: maxLines,
      ellipsis: ellipsis,
      locale: locale,
    );
  }

  RenderComparison compareTo(TextStyle other) {
    if (identical(this, other)) return RenderComparison.identical;
    if (inherit != other.inherit ||
        fontFamily != other.fontFamily ||
        fontSize != other.fontSize ||
        fontWeight != other.fontWeight ||
        fontStyle != other.fontStyle ||
        letterSpacing != other.letterSpacing ||
        wordSpacing != other.wordSpacing ||
        textBaseline != other.textBaseline ||
        height != other.height ||
        locale != other.locale ||
        foreground != other.foreground ||
        background != other.background ||
        !listEquals(shadows, other.shadows) ||
        !listEquals(fontFamilyFallback, other.fontFamilyFallback))
      return RenderComparison.layout;
    if (color != other.color ||
        backgroundColor != other.backgroundColor ||
        decoration != other.decoration ||
        decorationColor != other.decorationColor ||
        decorationStyle != other.decorationStyle ||
        decorationThickness != other.decorationThickness)
      return RenderComparison.paint;
    return RenderComparison.identical;
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    final TextStyle typedOther = other;
    return inherit == typedOther.inherit &&
        color == typedOther.color &&
        backgroundColor == typedOther.backgroundColor &&
        fontFamily == typedOther.fontFamily &&
        fontSize == typedOther.fontSize &&
        fontWeight == typedOther.fontWeight &&
        fontStyle == typedOther.fontStyle &&
        letterSpacing == typedOther.letterSpacing &&
        wordSpacing == typedOther.wordSpacing &&
        textBaseline == typedOther.textBaseline &&
        height == typedOther.height &&
        locale == typedOther.locale &&
        foreground == typedOther.foreground &&
        background == typedOther.background &&
        decoration == typedOther.decoration &&
        decorationColor == typedOther.decorationColor &&
        decorationStyle == typedOther.decorationStyle &&
        decorationThickness == typedOther.decorationThickness &&
        listEquals(shadows, typedOther.shadows) &&
        listEquals(fontFamilyFallback, typedOther.fontFamilyFallback);
  }

  @override
  int get hashCode {
    return hashValues(
      inherit,
      color,
      backgroundColor,
      fontFamily,
      fontFamilyFallback,
      fontSize,
      fontWeight,
      fontStyle,
      letterSpacing,
      wordSpacing,
      textBaseline,
      height,
      locale,
      foreground,
      background,
      decoration,
      decorationColor,
      decorationStyle,
      shadows,
    );
  }

  @override
  String toStringShort() => '$runtimeType';

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties,
      {String prefix = ''}) {
    super.debugFillProperties(properties);
    if (debugLabel != null)
      properties.add(MessageProperty('${prefix}debugLabel', debugLabel));
    final List<DiagnosticsNode> styles = <DiagnosticsNode>[];
    styles.add(DiagnosticsProperty<Color>('${prefix}color', color,
        defaultValue: null));
    styles.add(DiagnosticsProperty<Color>(
        '${prefix}backgroundColor', backgroundColor,
        defaultValue: null));
    styles.add(StringProperty('${prefix}family', fontFamily,
        defaultValue: null, quoted: false));
    styles.add(IterableProperty<String>(
        '${prefix}familyFallback', fontFamilyFallback,
        defaultValue: null));
    styles.add(DoubleProperty('${prefix}size', fontSize, defaultValue: null));
    String weightDescription;
    if (fontWeight != null) {
      weightDescription = '${fontWeight.index + 1}00';
    }

    styles.add(DiagnosticsProperty<FontWeight>(
      '${prefix}weight',
      fontWeight,
      description: weightDescription,
      defaultValue: null,
    ));
    styles.add(EnumProperty<FontStyle>('${prefix}style', fontStyle,
        defaultValue: null));
    styles.add(DoubleProperty('${prefix}letterSpacing', letterSpacing,
        defaultValue: null));
    styles.add(DoubleProperty('${prefix}wordSpacing', wordSpacing,
        defaultValue: null));
    styles.add(EnumProperty<TextBaseline>('${prefix}baseline', textBaseline,
        defaultValue: null));
    styles.add(DoubleProperty('${prefix}height', height,
        unit: 'x', defaultValue: null));
    styles.add(DiagnosticsProperty<Locale>('${prefix}locale', locale,
        defaultValue: null));
    styles.add(DiagnosticsProperty<Paint>('${prefix}foreground', foreground,
        defaultValue: null));
    styles.add(DiagnosticsProperty<Paint>('${prefix}background', background,
        defaultValue: null));
    if (decoration != null ||
        decorationColor != null ||
        decorationStyle != null ||
        decorationThickness != null) {
      final List<String> decorationDescription = <String>[];
      if (decorationStyle != null)
        decorationDescription.add(describeEnum(decorationStyle));

      styles.add(DiagnosticsProperty<Color>(
          '${prefix}decorationColor', decorationColor,
          defaultValue: null, level: DiagnosticLevel.fine));

      if (decorationColor != null)
        decorationDescription.add('$decorationColor');

      styles.add(DiagnosticsProperty<TextDecoration>(
          '${prefix}decoration', decoration,
          defaultValue: null, level: DiagnosticLevel.hidden));
      if (decoration != null) decorationDescription.add('$decoration');
      assert(decorationDescription.isNotEmpty);
      styles.add(MessageProperty(
          '${prefix}decoration', decorationDescription.join(' ')));
      styles.add(DoubleProperty(
          '${prefix}decorationThickness', decorationThickness,
          unit: 'x', defaultValue: null));
    }

    final bool styleSpecified =
        styles.any((DiagnosticsNode n) => !n.isFiltered(DiagnosticLevel.info));
    properties.add(DiagnosticsProperty<bool>('${prefix}inherit', inherit,
        level: (!styleSpecified && inherit)
            ? DiagnosticLevel.fine
            : DiagnosticLevel.info));
    styles.forEach(properties.add);

    if (!styleSpecified)
      properties.add(FlagProperty('inherit',
          value: inherit,
          ifTrue: '$prefix<all styles inherited>',
          ifFalse: '$prefix<no style specified>'));
  }
}

import 'package:flutter_web/foundation.dart';

import 'basic_types.dart';
import 'text_style.dart';

@immutable
class StrutStyle extends Diagnosticable {
  const StrutStyle({
    String fontFamily,
    List<String> fontFamilyFallback,
    this.fontSize,
    this.height,
    this.leading,
    this.fontWeight,
    this.fontStyle,
    this.forceStrutHeight,
    this.debugLabel,
    String package,
  })  : fontFamily =
            package == null ? fontFamily : 'packages/$package/$fontFamily',
        _fontFamilyFallback = fontFamilyFallback,
        _package = package,
        assert(fontSize == null || fontSize > 0),
        assert(leading == null || leading >= 0),
        assert(package == null ||
            (package != null &&
                (fontFamily != null || fontFamilyFallback != null)));

  StrutStyle.fromTextStyle(
    TextStyle textStyle, {
    String fontFamily,
    List<String> fontFamilyFallback,
    double fontSize,
    double height,
    this.leading,
    FontWeight fontWeight,
    FontStyle fontStyle,
    this.forceStrutHeight,
    String debugLabel,
    String package,
  })  : assert(textStyle != null),
        assert(fontSize == null || fontSize > 0),
        assert(leading == null || leading >= 0),
        assert(package == null ||
            (package != null &&
                (fontFamily != null || fontFamilyFallback != null))),
        fontFamily = fontFamily != null
            ? (package == null ? fontFamily : 'packages/$package/$fontFamily')
            : textStyle.fontFamily,
        _fontFamilyFallback =
            fontFamilyFallback ?? textStyle.fontFamilyFallback,
        height = height ?? textStyle.height,
        fontSize = fontSize ?? textStyle.fontSize,
        fontWeight = fontWeight ?? textStyle.fontWeight,
        fontStyle = fontStyle ?? textStyle.fontStyle,
        debugLabel = debugLabel ?? textStyle.debugLabel,
        _package = package;

  static const StrutStyle disabled = StrutStyle(
    height: 0.0,
    leading: 0.0,
  );

  final String fontFamily;

  List<String> get fontFamilyFallback {
    if (_package != null && _fontFamilyFallback != null)
      return _fontFamilyFallback
          .map((String family) => 'packages/$_package/$family')
          .toList();
    return _fontFamilyFallback;
  }

  final List<String> _fontFamilyFallback;

  final String _package;

  final double fontSize;

  final double height;

  final FontWeight fontWeight;

  final FontStyle fontStyle;

  final double leading;

  final bool forceStrutHeight;

  final String debugLabel;

  RenderComparison compareTo(StrutStyle other) {
    if (identical(this, other)) return RenderComparison.identical;
    if (fontFamily != other.fontFamily ||
        fontSize != other.fontSize ||
        fontWeight != other.fontWeight ||
        fontStyle != other.fontStyle ||
        height != other.height ||
        leading != other.leading ||
        forceStrutHeight != other.forceStrutHeight ||
        !listEquals(fontFamilyFallback, other.fontFamilyFallback))
      return RenderComparison.layout;
    return RenderComparison.identical;
  }

  StrutStyle inheritFromTextStyle(TextStyle other) {
    if (other == null) return this;

    return StrutStyle(
      fontFamily: fontFamily ?? other.fontFamily,
      fontFamilyFallback: fontFamilyFallback ?? other.fontFamilyFallback,
      fontSize: fontSize ?? other.fontSize,
      height: height ?? other.height,
      leading: leading,
      fontWeight: fontWeight ?? other.fontWeight,
      fontStyle: fontStyle ?? other.fontStyle,
      forceStrutHeight: forceStrutHeight,
      debugLabel: debugLabel ?? other.debugLabel,
    );
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    final StrutStyle typedOther = other;
    return fontFamily == typedOther.fontFamily &&
        fontSize == typedOther.fontSize &&
        fontWeight == typedOther.fontWeight &&
        fontStyle == typedOther.fontStyle &&
        height == typedOther.height &&
        leading == typedOther.leading &&
        forceStrutHeight == typedOther.forceStrutHeight;
  }

  @override
  int get hashCode {
    return hashValues(
      fontFamily,
      fontSize,
      fontWeight,
      fontStyle,
      height,
      leading,
      forceStrutHeight,
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
    styles.add(StringProperty('${prefix}family', fontFamily,
        defaultValue: null, quoted: false));
    styles.add(IterableProperty<String>(
        '${prefix}familyFallback', fontFamilyFallback,
        defaultValue: null));
    styles.add(DoubleProperty('${prefix}size', fontSize, defaultValue: null));
    String weightDescription;
    if (fontWeight != null) {
      weightDescription = 'w${fontWeight.index + 1}00';
    }

    styles.add(DiagnosticsProperty<FontWeight>(
      '${prefix}weight',
      fontWeight,
      description: weightDescription,
      defaultValue: null,
    ));
    styles.add(EnumProperty<FontStyle>('${prefix}style', fontStyle,
        defaultValue: null));
    styles.add(DoubleProperty('${prefix}height', height,
        unit: 'x', defaultValue: null));
    styles.add(FlagProperty('${prefix}forceStrutHeight',
        value: forceStrutHeight, defaultValue: null));

    final bool styleSpecified =
        styles.any((DiagnosticsNode n) => !n.isFiltered(DiagnosticLevel.info));
    styles.forEach(properties.add);

    if (!styleSpecified)
      properties.add(FlagProperty('forceStrutHeight',
          value: forceStrutHeight,
          ifTrue: '$prefix<strut height forced>',
          ifFalse: '$prefix<strut height normal>'));
  }
}

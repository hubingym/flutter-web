import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/painting.dart';

import 'typography.dart';

@immutable
class TextTheme extends Diagnosticable {
  const TextTheme({
    this.display4,
    this.display3,
    this.display2,
    this.display1,
    this.headline,
    this.title,
    this.subhead,
    this.body2,
    this.body1,
    this.caption,
    this.button,
    this.subtitle,
    this.overline,
  });

  final TextStyle display4;

  final TextStyle display3;

  final TextStyle display2;

  final TextStyle display1;

  final TextStyle headline;

  final TextStyle title;

  final TextStyle subhead;

  final TextStyle body2;

  final TextStyle body1;

  final TextStyle caption;

  final TextStyle button;

  final TextStyle subtitle;

  final TextStyle overline;

  TextTheme copyWith({
    TextStyle display4,
    TextStyle display3,
    TextStyle display2,
    TextStyle display1,
    TextStyle headline,
    TextStyle title,
    TextStyle subhead,
    TextStyle body2,
    TextStyle body1,
    TextStyle caption,
    TextStyle button,
    TextStyle subtitle,
    TextStyle overline,
  }) {
    return TextTheme(
      display4: display4 ?? this.display4,
      display3: display3 ?? this.display3,
      display2: display2 ?? this.display2,
      display1: display1 ?? this.display1,
      headline: headline ?? this.headline,
      title: title ?? this.title,
      subhead: subhead ?? this.subhead,
      body2: body2 ?? this.body2,
      body1: body1 ?? this.body1,
      caption: caption ?? this.caption,
      button: button ?? this.button,
      subtitle: subtitle ?? this.subtitle,
      overline: overline ?? this.overline,
    );
  }

  TextTheme merge(TextTheme other) {
    if (other == null) return this;
    return copyWith(
      display4: display4?.merge(other.display4) ?? other.display4,
      display3: display3?.merge(other.display3) ?? other.display3,
      display2: display2?.merge(other.display2) ?? other.display2,
      display1: display1?.merge(other.display1) ?? other.display1,
      headline: headline?.merge(other.headline) ?? other.headline,
      title: title?.merge(other.title) ?? other.title,
      subhead: subhead?.merge(other.subhead) ?? other.subhead,
      body2: body2?.merge(other.body2) ?? other.body2,
      body1: body1?.merge(other.body1) ?? other.body1,
      caption: caption?.merge(other.caption) ?? other.caption,
      button: button?.merge(other.button) ?? other.button,
      subtitle: subtitle?.merge(other.subtitle) ?? other.subtitle,
      overline: overline?.merge(other.overline) ?? other.overline,
    );
  }

  TextTheme apply({
    String fontFamily,
    double fontSizeFactor = 1.0,
    double fontSizeDelta = 0.0,
    Color displayColor,
    Color bodyColor,
    TextDecoration decoration,
    Color decorationColor,
    TextDecorationStyle decorationStyle,
  }) {
    return TextTheme(
      display4: display4?.apply(
        color: displayColor,
        decoration: decoration,
        decorationColor: decorationColor,
        decorationStyle: decorationStyle,
        fontFamily: fontFamily,
        fontSizeFactor: fontSizeFactor,
        fontSizeDelta: fontSizeDelta,
      ),
      display3: display3?.apply(
        color: displayColor,
        decoration: decoration,
        decorationColor: decorationColor,
        decorationStyle: decorationStyle,
        fontFamily: fontFamily,
        fontSizeFactor: fontSizeFactor,
        fontSizeDelta: fontSizeDelta,
      ),
      display2: display2?.apply(
        color: displayColor,
        decoration: decoration,
        decorationColor: decorationColor,
        decorationStyle: decorationStyle,
        fontFamily: fontFamily,
        fontSizeFactor: fontSizeFactor,
        fontSizeDelta: fontSizeDelta,
      ),
      display1: display1?.apply(
        color: displayColor,
        decoration: decoration,
        decorationColor: decorationColor,
        decorationStyle: decorationStyle,
        fontFamily: fontFamily,
        fontSizeFactor: fontSizeFactor,
        fontSizeDelta: fontSizeDelta,
      ),
      headline: headline?.apply(
        color: bodyColor,
        decoration: decoration,
        decorationColor: decorationColor,
        decorationStyle: decorationStyle,
        fontFamily: fontFamily,
        fontSizeFactor: fontSizeFactor,
        fontSizeDelta: fontSizeDelta,
      ),
      title: title?.apply(
        color: bodyColor,
        decoration: decoration,
        decorationColor: decorationColor,
        decorationStyle: decorationStyle,
        fontFamily: fontFamily,
        fontSizeFactor: fontSizeFactor,
        fontSizeDelta: fontSizeDelta,
      ),
      subhead: subhead?.apply(
        color: bodyColor,
        decoration: decoration,
        decorationColor: decorationColor,
        decorationStyle: decorationStyle,
        fontFamily: fontFamily,
        fontSizeFactor: fontSizeFactor,
        fontSizeDelta: fontSizeDelta,
      ),
      body2: body2?.apply(
        color: bodyColor,
        decoration: decoration,
        decorationColor: decorationColor,
        decorationStyle: decorationStyle,
        fontFamily: fontFamily,
        fontSizeFactor: fontSizeFactor,
        fontSizeDelta: fontSizeDelta,
      ),
      body1: body1?.apply(
        color: bodyColor,
        decoration: decoration,
        decorationColor: decorationColor,
        decorationStyle: decorationStyle,
        fontFamily: fontFamily,
        fontSizeFactor: fontSizeFactor,
        fontSizeDelta: fontSizeDelta,
      ),
      caption: caption?.apply(
        color: displayColor,
        decoration: decoration,
        decorationColor: decorationColor,
        decorationStyle: decorationStyle,
        fontFamily: fontFamily,
        fontSizeFactor: fontSizeFactor,
        fontSizeDelta: fontSizeDelta,
      ),
      button: button?.apply(
        color: bodyColor,
        decoration: decoration,
        decorationColor: decorationColor,
        decorationStyle: decorationStyle,
        fontFamily: fontFamily,
        fontSizeFactor: fontSizeFactor,
        fontSizeDelta: fontSizeDelta,
      ),
      subtitle: subtitle?.apply(
        color: bodyColor,
        decoration: decoration,
        decorationColor: decorationColor,
        decorationStyle: decorationStyle,
        fontFamily: fontFamily,
        fontSizeFactor: fontSizeFactor,
        fontSizeDelta: fontSizeDelta,
      ),
      overline: overline?.apply(
        color: bodyColor,
        decoration: decoration,
        decorationColor: decorationColor,
        decorationStyle: decorationStyle,
        fontFamily: fontFamily,
        fontSizeFactor: fontSizeFactor,
        fontSizeDelta: fontSizeDelta,
      ),
    );
  }

  static TextTheme lerp(TextTheme a, TextTheme b, double t) {
    assert(t != null);
    return TextTheme(
      display4: TextStyle.lerp(a?.display4, b?.display4, t),
      display3: TextStyle.lerp(a?.display3, b?.display3, t),
      display2: TextStyle.lerp(a?.display2, b?.display2, t),
      display1: TextStyle.lerp(a?.display1, b?.display1, t),
      headline: TextStyle.lerp(a?.headline, b?.headline, t),
      title: TextStyle.lerp(a?.title, b?.title, t),
      subhead: TextStyle.lerp(a?.subhead, b?.subhead, t),
      body2: TextStyle.lerp(a?.body2, b?.body2, t),
      body1: TextStyle.lerp(a?.body1, b?.body1, t),
      caption: TextStyle.lerp(a?.caption, b?.caption, t),
      button: TextStyle.lerp(a?.button, b?.button, t),
      subtitle: TextStyle.lerp(a?.subtitle, b?.subtitle, t),
      overline: TextStyle.lerp(a?.overline, b?.overline, t),
    );
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    final TextTheme typedOther = other;
    return display4 == typedOther.display4 &&
        display3 == typedOther.display3 &&
        display2 == typedOther.display2 &&
        display1 == typedOther.display1 &&
        headline == typedOther.headline &&
        title == typedOther.title &&
        subhead == typedOther.subhead &&
        body2 == typedOther.body2 &&
        body1 == typedOther.body1 &&
        caption == typedOther.caption &&
        button == typedOther.button &&
        subtitle == typedOther.subtitle &&
        overline == typedOther.overline;
  }

  @override
  int get hashCode {
    return hashValues(
      display4,
      display3,
      display2,
      display1,
      headline,
      title,
      subhead,
      body2,
      body1,
      caption,
      button,
      subtitle,
      overline,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    final TextTheme defaultTheme =
        Typography(platform: defaultTargetPlatform).black;
    properties.add(DiagnosticsProperty<TextStyle>('display4', display4,
        defaultValue: defaultTheme.display4));
    properties.add(DiagnosticsProperty<TextStyle>('display3', display3,
        defaultValue: defaultTheme.display3));
    properties.add(DiagnosticsProperty<TextStyle>('display2', display2,
        defaultValue: defaultTheme.display2));
    properties.add(DiagnosticsProperty<TextStyle>('display1', display1,
        defaultValue: defaultTheme.display1));
    properties.add(DiagnosticsProperty<TextStyle>('headline', headline,
        defaultValue: defaultTheme.headline));
    properties.add(DiagnosticsProperty<TextStyle>('title', title,
        defaultValue: defaultTheme.title));
    properties.add(DiagnosticsProperty<TextStyle>('subhead', subhead,
        defaultValue: defaultTheme.subhead));
    properties.add(DiagnosticsProperty<TextStyle>('body2', body2,
        defaultValue: defaultTheme.body2));
    properties.add(DiagnosticsProperty<TextStyle>('body1', body1,
        defaultValue: defaultTheme.body1));
    properties.add(DiagnosticsProperty<TextStyle>('caption', caption,
        defaultValue: defaultTheme.caption));
    properties.add(DiagnosticsProperty<TextStyle>('button', button,
        defaultValue: defaultTheme.button));
    properties.add(DiagnosticsProperty<TextStyle>('subtitle)', subtitle,
        defaultValue: defaultTheme.subtitle));
    properties.add(DiagnosticsProperty<TextStyle>('overline', overline,
        defaultValue: defaultTheme.overline));
  }
}

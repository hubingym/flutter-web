import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/painting.dart';

import 'colors.dart';
import 'text_theme.dart';

enum ScriptCategory {
  englishLike,

  dense,

  tall,
}

@immutable
class Typography extends Diagnosticable {
  factory Typography({
    TargetPlatform platform = TargetPlatform.android,
    TextTheme black,
    TextTheme white,
    TextTheme englishLike,
    TextTheme dense,
    TextTheme tall,
  }) {
    assert(platform != null || (black != null && white != null));
    switch (platform) {
      case TargetPlatform.iOS:
        black ??= blackCupertino;
        white ??= whiteCupertino;
        break;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        black ??= blackMountainView;
        white ??= whiteMountainView;
    }
    englishLike ??= englishLike2014;
    dense ??= dense2014;
    tall ??= tall2014;
    return Typography._(black, white, englishLike, dense, tall);
  }

  const Typography._(
      this.black, this.white, this.englishLike, this.dense, this.tall)
      : assert(black != null),
        assert(white != null),
        assert(englishLike != null),
        assert(dense != null),
        assert(tall != null);

  final TextTheme black;

  final TextTheme white;

  final TextTheme englishLike;

  final TextTheme dense;

  final TextTheme tall;

  TextTheme geometryThemeFor(ScriptCategory category) {
    assert(category != null);
    switch (category) {
      case ScriptCategory.englishLike:
        return englishLike;
      case ScriptCategory.dense:
        return dense;
      case ScriptCategory.tall:
        return tall;
    }
    return null;
  }

  Typography copyWith({
    TextTheme black,
    TextTheme white,
    TextTheme englishLike,
    TextTheme dense,
    TextTheme tall,
  }) {
    return Typography(
      black: black ?? this.black,
      white: white ?? this.white,
      englishLike: englishLike ?? this.englishLike,
      dense: dense ?? this.dense,
      tall: tall ?? this.tall,
    );
  }

  static Typography lerp(Typography a, Typography b, double t) {
    return Typography(
      black: TextTheme.lerp(a.black, b.black, t),
      white: TextTheme.lerp(a.white, b.white, t),
      englishLike: TextTheme.lerp(a.englishLike, b.englishLike, t),
      dense: TextTheme.lerp(a.dense, b.dense, t),
      tall: TextTheme.lerp(a.tall, b.tall, t),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    final Typography otherTypography = other;
    return otherTypography.black == black &&
        otherTypography.white == white &&
        otherTypography.englishLike == englishLike &&
        otherTypography.dense == dense &&
        otherTypography.tall == tall;
  }

  @override
  int get hashCode {
    return hashValues(
      black,
      white,
      englishLike,
      dense,
      tall,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    final Typography defaultTypography = Typography();
    properties.add(DiagnosticsProperty<TextTheme>('black', black,
        defaultValue: defaultTypography.black));
    properties.add(DiagnosticsProperty<TextTheme>('white', white,
        defaultValue: defaultTypography.white));
    properties.add(DiagnosticsProperty<TextTheme>('englishLike', englishLike,
        defaultValue: defaultTypography.englishLike));
    properties.add(DiagnosticsProperty<TextTheme>('dense', dense,
        defaultValue: defaultTypography.dense));
    properties.add(DiagnosticsProperty<TextTheme>('tall', tall,
        defaultValue: defaultTypography.tall));
  }

  static const TextTheme blackMountainView = TextTheme(
    display4: TextStyle(
        debugLabel: 'blackMountainView display4',
        fontFamily: 'Roboto',
        inherit: true,
        color: Colors.black54,
        decoration: TextDecoration.none),
    display3: TextStyle(
        debugLabel: 'blackMountainView display3',
        fontFamily: 'Roboto',
        inherit: true,
        color: Colors.black54,
        decoration: TextDecoration.none),
    display2: TextStyle(
        debugLabel: 'blackMountainView display2',
        fontFamily: 'Roboto',
        inherit: true,
        color: Colors.black54,
        decoration: TextDecoration.none),
    display1: TextStyle(
        debugLabel: 'blackMountainView display1',
        fontFamily: 'Roboto',
        inherit: true,
        color: Colors.black54,
        decoration: TextDecoration.none),
    headline: TextStyle(
        debugLabel: 'blackMountainView headline',
        fontFamily: 'Roboto',
        inherit: true,
        color: Colors.black87,
        decoration: TextDecoration.none),
    title: TextStyle(
        debugLabel: 'blackMountainView title',
        fontFamily: 'Roboto',
        inherit: true,
        color: Colors.black87,
        decoration: TextDecoration.none),
    subhead: TextStyle(
        debugLabel: 'blackMountainView subhead',
        fontFamily: 'Roboto',
        inherit: true,
        color: Colors.black87,
        decoration: TextDecoration.none),
    body2: TextStyle(
        debugLabel: 'blackMountainView body2',
        fontFamily: 'Roboto',
        inherit: true,
        color: Colors.black87,
        decoration: TextDecoration.none),
    body1: TextStyle(
        debugLabel: 'blackMountainView body1',
        fontFamily: 'Roboto',
        inherit: true,
        color: Colors.black87,
        decoration: TextDecoration.none),
    caption: TextStyle(
        debugLabel: 'blackMountainView caption',
        fontFamily: 'Roboto',
        inherit: true,
        color: Colors.black54,
        decoration: TextDecoration.none),
    button: TextStyle(
        debugLabel: 'blackMountainView button',
        fontFamily: 'Roboto',
        inherit: true,
        color: Colors.black87,
        decoration: TextDecoration.none),
    subtitle: TextStyle(
        debugLabel: 'blackMountainView subtitle',
        fontFamily: 'Roboto',
        inherit: true,
        color: Colors.black,
        decoration: TextDecoration.none),
    overline: TextStyle(
        debugLabel: 'blackMountainView overline',
        fontFamily: 'Roboto',
        inherit: true,
        color: Colors.black,
        decoration: TextDecoration.none),
  );

  static const TextTheme whiteMountainView = TextTheme(
    display4: TextStyle(
        debugLabel: 'whiteMountainView display4',
        fontFamily: 'Roboto',
        inherit: true,
        color: Colors.white70,
        decoration: TextDecoration.none),
    display3: TextStyle(
        debugLabel: 'whiteMountainView display3',
        fontFamily: 'Roboto',
        inherit: true,
        color: Colors.white70,
        decoration: TextDecoration.none),
    display2: TextStyle(
        debugLabel: 'whiteMountainView display2',
        fontFamily: 'Roboto',
        inherit: true,
        color: Colors.white70,
        decoration: TextDecoration.none),
    display1: TextStyle(
        debugLabel: 'whiteMountainView display1',
        fontFamily: 'Roboto',
        inherit: true,
        color: Colors.white70,
        decoration: TextDecoration.none),
    headline: TextStyle(
        debugLabel: 'whiteMountainView headline',
        fontFamily: 'Roboto',
        inherit: true,
        color: Colors.white,
        decoration: TextDecoration.none),
    title: TextStyle(
        debugLabel: 'whiteMountainView title',
        fontFamily: 'Roboto',
        inherit: true,
        color: Colors.white,
        decoration: TextDecoration.none),
    subhead: TextStyle(
        debugLabel: 'whiteMountainView subhead',
        fontFamily: 'Roboto',
        inherit: true,
        color: Colors.white,
        decoration: TextDecoration.none),
    body2: TextStyle(
        debugLabel: 'whiteMountainView body2',
        fontFamily: 'Roboto',
        inherit: true,
        color: Colors.white,
        decoration: TextDecoration.none),
    body1: TextStyle(
        debugLabel: 'whiteMountainView body1',
        fontFamily: 'Roboto',
        inherit: true,
        color: Colors.white,
        decoration: TextDecoration.none),
    caption: TextStyle(
        debugLabel: 'whiteMountainView caption',
        fontFamily: 'Roboto',
        inherit: true,
        color: Colors.white70,
        decoration: TextDecoration.none),
    button: TextStyle(
        debugLabel: 'whiteMountainView button',
        fontFamily: 'Roboto',
        inherit: true,
        color: Colors.white,
        decoration: TextDecoration.none),
    subtitle: TextStyle(
        debugLabel: 'whiteMountainView subtitle',
        fontFamily: 'Roboto',
        inherit: true,
        color: Colors.white,
        decoration: TextDecoration.none),
    overline: TextStyle(
        debugLabel: 'whiteMountainView overline',
        fontFamily: 'Roboto',
        inherit: true,
        color: Colors.white,
        decoration: TextDecoration.none),
  );

  static const TextTheme blackCupertino = TextTheme(
    display4: TextStyle(
        debugLabel: 'blackCupertino display4',
        fontFamily: '.SF UI Display',
        inherit: true,
        color: Colors.black54,
        decoration: TextDecoration.none),
    display3: TextStyle(
        debugLabel: 'blackCupertino display3',
        fontFamily: '.SF UI Display',
        inherit: true,
        color: Colors.black54,
        decoration: TextDecoration.none),
    display2: TextStyle(
        debugLabel: 'blackCupertino display2',
        fontFamily: '.SF UI Display',
        inherit: true,
        color: Colors.black54,
        decoration: TextDecoration.none),
    display1: TextStyle(
        debugLabel: 'blackCupertino display1',
        fontFamily: '.SF UI Display',
        inherit: true,
        color: Colors.black54,
        decoration: TextDecoration.none),
    headline: TextStyle(
        debugLabel: 'blackCupertino headline',
        fontFamily: '.SF UI Display',
        inherit: true,
        color: Colors.black87,
        decoration: TextDecoration.none),
    title: TextStyle(
        debugLabel: 'blackCupertino title',
        fontFamily: '.SF UI Display',
        inherit: true,
        color: Colors.black87,
        decoration: TextDecoration.none),
    subhead: TextStyle(
        debugLabel: 'blackCupertino subhead',
        fontFamily: '.SF UI Text',
        inherit: true,
        color: Colors.black87,
        decoration: TextDecoration.none),
    body2: TextStyle(
        debugLabel: 'blackCupertino body2',
        fontFamily: '.SF UI Text',
        inherit: true,
        color: Colors.black87,
        decoration: TextDecoration.none),
    body1: TextStyle(
        debugLabel: 'blackCupertino body1',
        fontFamily: '.SF UI Text',
        inherit: true,
        color: Colors.black87,
        decoration: TextDecoration.none),
    caption: TextStyle(
        debugLabel: 'blackCupertino caption',
        fontFamily: '.SF UI Text',
        inherit: true,
        color: Colors.black54,
        decoration: TextDecoration.none),
    button: TextStyle(
        debugLabel: 'blackCupertino button',
        fontFamily: '.SF UI Text',
        inherit: true,
        color: Colors.black87,
        decoration: TextDecoration.none),
    subtitle: TextStyle(
        debugLabel: 'blackCupertino subtitle',
        fontFamily: '.SF UI Text',
        inherit: true,
        color: Colors.black,
        decoration: TextDecoration.none),
    overline: TextStyle(
        debugLabel: 'blackCupertino overline',
        fontFamily: '.SF UI Text',
        inherit: true,
        color: Colors.black,
        decoration: TextDecoration.none),
  );

  static const TextTheme whiteCupertino = TextTheme(
    display4: TextStyle(
        debugLabel: 'whiteCupertino display4',
        fontFamily: '.SF UI Display',
        inherit: true,
        color: Colors.white70,
        decoration: TextDecoration.none),
    display3: TextStyle(
        debugLabel: 'whiteCupertino display3',
        fontFamily: '.SF UI Display',
        inherit: true,
        color: Colors.white70,
        decoration: TextDecoration.none),
    display2: TextStyle(
        debugLabel: 'whiteCupertino display2',
        fontFamily: '.SF UI Display',
        inherit: true,
        color: Colors.white70,
        decoration: TextDecoration.none),
    display1: TextStyle(
        debugLabel: 'whiteCupertino display1',
        fontFamily: '.SF UI Display',
        inherit: true,
        color: Colors.white70,
        decoration: TextDecoration.none),
    headline: TextStyle(
        debugLabel: 'whiteCupertino headline',
        fontFamily: '.SF UI Display',
        inherit: true,
        color: Colors.white,
        decoration: TextDecoration.none),
    title: TextStyle(
        debugLabel: 'whiteCupertino title',
        fontFamily: '.SF UI Display',
        inherit: true,
        color: Colors.white,
        decoration: TextDecoration.none),
    subhead: TextStyle(
        debugLabel: 'whiteCupertino subhead',
        fontFamily: '.SF UI Text',
        inherit: true,
        color: Colors.white,
        decoration: TextDecoration.none),
    body2: TextStyle(
        debugLabel: 'whiteCupertino body2',
        fontFamily: '.SF UI Text',
        inherit: true,
        color: Colors.white,
        decoration: TextDecoration.none),
    body1: TextStyle(
        debugLabel: 'whiteCupertino body1',
        fontFamily: '.SF UI Text',
        inherit: true,
        color: Colors.white,
        decoration: TextDecoration.none),
    caption: TextStyle(
        debugLabel: 'whiteCupertino caption',
        fontFamily: '.SF UI Text',
        inherit: true,
        color: Colors.white70,
        decoration: TextDecoration.none),
    button: TextStyle(
        debugLabel: 'whiteCupertino button',
        fontFamily: '.SF UI Text',
        inherit: true,
        color: Colors.white,
        decoration: TextDecoration.none),
    subtitle: TextStyle(
        debugLabel: 'whiteCupertino subtitle',
        fontFamily: '.SF UI Text',
        inherit: true,
        color: Colors.white,
        decoration: TextDecoration.none),
    overline: TextStyle(
        debugLabel: 'whiteCupertino overline',
        fontFamily: '.SF UI Text',
        inherit: true,
        color: Colors.white,
        decoration: TextDecoration.none),
  );

  static const TextTheme englishLike2014 = TextTheme(
    display4: TextStyle(
        debugLabel: 'englishLike display4 2014',
        inherit: false,
        fontSize: 112.0,
        fontWeight: FontWeight.w100,
        textBaseline: TextBaseline.alphabetic),
    display3: TextStyle(
        debugLabel: 'englishLike display3 2014',
        inherit: false,
        fontSize: 56.0,
        fontWeight: FontWeight.w400,
        textBaseline: TextBaseline.alphabetic),
    display2: TextStyle(
        debugLabel: 'englishLike display2 2014',
        inherit: false,
        fontSize: 45.0,
        fontWeight: FontWeight.w400,
        textBaseline: TextBaseline.alphabetic),
    display1: TextStyle(
        debugLabel: 'englishLike display1 2014',
        inherit: false,
        fontSize: 34.0,
        fontWeight: FontWeight.w400,
        textBaseline: TextBaseline.alphabetic),
    headline: TextStyle(
        debugLabel: 'englishLike headline 2014',
        inherit: false,
        fontSize: 24.0,
        fontWeight: FontWeight.w400,
        textBaseline: TextBaseline.alphabetic),
    title: TextStyle(
        debugLabel: 'englishLike title 2014',
        inherit: false,
        fontSize: 20.0,
        fontWeight: FontWeight.w500,
        textBaseline: TextBaseline.alphabetic),
    subhead: TextStyle(
        debugLabel: 'englishLike subhead 2014',
        inherit: false,
        fontSize: 16.0,
        fontWeight: FontWeight.w400,
        textBaseline: TextBaseline.alphabetic),
    body2: TextStyle(
        debugLabel: 'englishLike body2 2014',
        inherit: false,
        fontSize: 14.0,
        fontWeight: FontWeight.w500,
        textBaseline: TextBaseline.alphabetic),
    body1: TextStyle(
        debugLabel: 'englishLike body1 2014',
        inherit: false,
        fontSize: 14.0,
        fontWeight: FontWeight.w400,
        textBaseline: TextBaseline.alphabetic),
    caption: TextStyle(
        debugLabel: 'englishLike caption 2014',
        inherit: false,
        fontSize: 12.0,
        fontWeight: FontWeight.w400,
        textBaseline: TextBaseline.alphabetic),
    button: TextStyle(
        debugLabel: 'englishLike button 2014',
        inherit: false,
        fontSize: 14.0,
        fontWeight: FontWeight.w500,
        textBaseline: TextBaseline.alphabetic),
    subtitle: TextStyle(
        debugLabel: 'englishLike subtitle 2014',
        inherit: false,
        fontSize: 14.0,
        fontWeight: FontWeight.w500,
        textBaseline: TextBaseline.alphabetic,
        letterSpacing: 0.1),
    overline: TextStyle(
        debugLabel: 'englishLike overline 2014',
        inherit: false,
        fontSize: 10.0,
        fontWeight: FontWeight.w400,
        textBaseline: TextBaseline.alphabetic,
        letterSpacing: 1.5),
  );

  static const TextTheme englishLike2018 = TextTheme(
    display4: TextStyle(
        debugLabel: 'englishLike display4 2018',
        fontSize: 96.0,
        fontWeight: FontWeight.w300,
        textBaseline: TextBaseline.alphabetic,
        letterSpacing: -1.5),
    display3: TextStyle(
        debugLabel: 'englishLike display3 2018',
        fontSize: 60.0,
        fontWeight: FontWeight.w300,
        textBaseline: TextBaseline.alphabetic,
        letterSpacing: -0.5),
    display2: TextStyle(
        debugLabel: 'englishLike display2 2018',
        fontSize: 48.0,
        fontWeight: FontWeight.w400,
        textBaseline: TextBaseline.alphabetic,
        letterSpacing: 0.0),
    display1: TextStyle(
        debugLabel: 'englishLike display1 2018',
        fontSize: 34.0,
        fontWeight: FontWeight.w400,
        textBaseline: TextBaseline.alphabetic,
        letterSpacing: 0.25),
    headline: TextStyle(
        debugLabel: 'englishLike headline 2018',
        fontSize: 24.0,
        fontWeight: FontWeight.w400,
        textBaseline: TextBaseline.alphabetic,
        letterSpacing: 0.0),
    title: TextStyle(
        debugLabel: 'englishLike title 2018',
        fontSize: 20.0,
        fontWeight: FontWeight.w500,
        textBaseline: TextBaseline.alphabetic,
        letterSpacing: 0.15),
    subhead: TextStyle(
        debugLabel: 'englishLike subhead 2018',
        fontSize: 16.0,
        fontWeight: FontWeight.w400,
        textBaseline: TextBaseline.alphabetic,
        letterSpacing: 0.15),
    body2: TextStyle(
        debugLabel: 'englishLike body2 2018',
        fontSize: 14.0,
        fontWeight: FontWeight.w400,
        textBaseline: TextBaseline.alphabetic,
        letterSpacing: 0.25),
    body1: TextStyle(
        debugLabel: 'englishLike body1 2018',
        fontSize: 16.0,
        fontWeight: FontWeight.w400,
        textBaseline: TextBaseline.alphabetic,
        letterSpacing: 0.5),
    button: TextStyle(
        debugLabel: 'englishLike button 2018',
        fontSize: 14.0,
        fontWeight: FontWeight.w500,
        textBaseline: TextBaseline.alphabetic,
        letterSpacing: 0.75),
    caption: TextStyle(
        debugLabel: 'englishLike caption 2018',
        fontSize: 12.0,
        fontWeight: FontWeight.w400,
        textBaseline: TextBaseline.alphabetic,
        letterSpacing: 0.4),
    subtitle: TextStyle(
        debugLabel: 'englishLike subtitle 2018',
        fontSize: 14.0,
        fontWeight: FontWeight.w500,
        textBaseline: TextBaseline.alphabetic,
        letterSpacing: 0.1),
    overline: TextStyle(
        debugLabel: 'englishLike overline 2018',
        fontSize: 10.0,
        fontWeight: FontWeight.w400,
        textBaseline: TextBaseline.alphabetic,
        letterSpacing: 1.5),
  );

  static const TextTheme dense2014 = TextTheme(
    display4: TextStyle(
        debugLabel: 'dense display4 2014',
        inherit: false,
        fontSize: 112.0,
        fontWeight: FontWeight.w100,
        textBaseline: TextBaseline.ideographic),
    display3: TextStyle(
        debugLabel: 'dense display3 2014',
        inherit: false,
        fontSize: 56.0,
        fontWeight: FontWeight.w400,
        textBaseline: TextBaseline.ideographic),
    display2: TextStyle(
        debugLabel: 'dense display2 2014',
        inherit: false,
        fontSize: 45.0,
        fontWeight: FontWeight.w400,
        textBaseline: TextBaseline.ideographic),
    display1: TextStyle(
        debugLabel: 'dense display1 2014',
        inherit: false,
        fontSize: 34.0,
        fontWeight: FontWeight.w400,
        textBaseline: TextBaseline.ideographic),
    headline: TextStyle(
        debugLabel: 'dense headline 2014',
        inherit: false,
        fontSize: 24.0,
        fontWeight: FontWeight.w400,
        textBaseline: TextBaseline.ideographic),
    title: TextStyle(
        debugLabel: 'dense title 2014',
        inherit: false,
        fontSize: 21.0,
        fontWeight: FontWeight.w500,
        textBaseline: TextBaseline.ideographic),
    subhead: TextStyle(
        debugLabel: 'dense subhead 2014',
        inherit: false,
        fontSize: 17.0,
        fontWeight: FontWeight.w400,
        textBaseline: TextBaseline.ideographic),
    body2: TextStyle(
        debugLabel: 'dense body2 2014',
        inherit: false,
        fontSize: 15.0,
        fontWeight: FontWeight.w500,
        textBaseline: TextBaseline.ideographic),
    body1: TextStyle(
        debugLabel: 'dense body1 2014',
        inherit: false,
        fontSize: 15.0,
        fontWeight: FontWeight.w400,
        textBaseline: TextBaseline.ideographic),
    caption: TextStyle(
        debugLabel: 'dense caption 2014',
        inherit: false,
        fontSize: 13.0,
        fontWeight: FontWeight.w400,
        textBaseline: TextBaseline.ideographic),
    button: TextStyle(
        debugLabel: 'dense button 2014',
        inherit: false,
        fontSize: 15.0,
        fontWeight: FontWeight.w500,
        textBaseline: TextBaseline.ideographic),
    subtitle: TextStyle(
        debugLabel: 'dense subtitle 2014',
        inherit: false,
        fontSize: 15.0,
        fontWeight: FontWeight.w500,
        textBaseline: TextBaseline.ideographic),
    overline: TextStyle(
        debugLabel: 'dense overline 2014',
        inherit: false,
        fontSize: 11.0,
        fontWeight: FontWeight.w400,
        textBaseline: TextBaseline.ideographic),
  );

  static const TextTheme dense2018 = TextTheme(
    display4: TextStyle(
        debugLabel: 'dense display4 2018',
        fontSize: 96.0,
        fontWeight: FontWeight.w100,
        textBaseline: TextBaseline.ideographic),
    display3: TextStyle(
        debugLabel: 'dense display3 2018',
        fontSize: 60.0,
        fontWeight: FontWeight.w100,
        textBaseline: TextBaseline.ideographic),
    display2: TextStyle(
        debugLabel: 'dense display2 2018',
        fontSize: 48.0,
        fontWeight: FontWeight.w400,
        textBaseline: TextBaseline.ideographic),
    display1: TextStyle(
        debugLabel: 'dense display1 2018',
        fontSize: 34.0,
        fontWeight: FontWeight.w400,
        textBaseline: TextBaseline.ideographic),
    headline: TextStyle(
        debugLabel: 'dense headline 2018',
        fontSize: 24.0,
        fontWeight: FontWeight.w400,
        textBaseline: TextBaseline.ideographic),
    title: TextStyle(
        debugLabel: 'dense title 2018',
        fontSize: 21.0,
        fontWeight: FontWeight.w500,
        textBaseline: TextBaseline.ideographic),
    subhead: TextStyle(
        debugLabel: 'dense subhead 2018',
        fontSize: 17.0,
        fontWeight: FontWeight.w400,
        textBaseline: TextBaseline.ideographic),
    body2: TextStyle(
        debugLabel: 'dense body2 2018',
        fontSize: 17.0,
        fontWeight: FontWeight.w400,
        textBaseline: TextBaseline.ideographic),
    body1: TextStyle(
        debugLabel: 'dense body1 2018',
        fontSize: 15.0,
        fontWeight: FontWeight.w400,
        textBaseline: TextBaseline.ideographic),
    caption: TextStyle(
        debugLabel: 'dense caption 2018',
        fontSize: 13.0,
        fontWeight: FontWeight.w400,
        textBaseline: TextBaseline.ideographic),
    button: TextStyle(
        debugLabel: 'dense button 2018',
        fontSize: 15.0,
        fontWeight: FontWeight.w500,
        textBaseline: TextBaseline.ideographic),
    subtitle: TextStyle(
        debugLabel: 'dense subtitle 2018',
        fontSize: 15.0,
        fontWeight: FontWeight.w500,
        textBaseline: TextBaseline.ideographic),
    overline: TextStyle(
        debugLabel: 'dense overline 2018',
        fontSize: 11.0,
        fontWeight: FontWeight.w400,
        textBaseline: TextBaseline.ideographic),
  );

  static const TextTheme tall2014 = TextTheme(
    display4: TextStyle(
        debugLabel: 'tall display4 2014',
        inherit: false,
        fontSize: 112.0,
        fontWeight: FontWeight.w400,
        textBaseline: TextBaseline.alphabetic),
    display3: TextStyle(
        debugLabel: 'tall display3 2014',
        inherit: false,
        fontSize: 56.0,
        fontWeight: FontWeight.w400,
        textBaseline: TextBaseline.alphabetic),
    display2: TextStyle(
        debugLabel: 'tall display2 2014',
        inherit: false,
        fontSize: 45.0,
        fontWeight: FontWeight.w400,
        textBaseline: TextBaseline.alphabetic),
    display1: TextStyle(
        debugLabel: 'tall display1 2014',
        inherit: false,
        fontSize: 34.0,
        fontWeight: FontWeight.w400,
        textBaseline: TextBaseline.alphabetic),
    headline: TextStyle(
        debugLabel: 'tall headline 2014',
        inherit: false,
        fontSize: 24.0,
        fontWeight: FontWeight.w400,
        textBaseline: TextBaseline.alphabetic),
    title: TextStyle(
        debugLabel: 'tall title 2014',
        inherit: false,
        fontSize: 21.0,
        fontWeight: FontWeight.w700,
        textBaseline: TextBaseline.alphabetic),
    subhead: TextStyle(
        debugLabel: 'tall subhead 2014',
        inherit: false,
        fontSize: 17.0,
        fontWeight: FontWeight.w400,
        textBaseline: TextBaseline.alphabetic),
    body2: TextStyle(
        debugLabel: 'tall body2 2014',
        inherit: false,
        fontSize: 15.0,
        fontWeight: FontWeight.w700,
        textBaseline: TextBaseline.alphabetic),
    body1: TextStyle(
        debugLabel: 'tall body1 2014',
        inherit: false,
        fontSize: 15.0,
        fontWeight: FontWeight.w400,
        textBaseline: TextBaseline.alphabetic),
    caption: TextStyle(
        debugLabel: 'tall caption 2014',
        inherit: false,
        fontSize: 13.0,
        fontWeight: FontWeight.w400,
        textBaseline: TextBaseline.alphabetic),
    button: TextStyle(
        debugLabel: 'tall button 2014',
        inherit: false,
        fontSize: 15.0,
        fontWeight: FontWeight.w700,
        textBaseline: TextBaseline.alphabetic),
    subtitle: TextStyle(
        debugLabel: 'tall subtitle 2014',
        inherit: false,
        fontSize: 15.0,
        fontWeight: FontWeight.w500,
        textBaseline: TextBaseline.alphabetic),
    overline: TextStyle(
        debugLabel: 'tall overline 2014',
        inherit: false,
        fontSize: 11.0,
        fontWeight: FontWeight.w400,
        textBaseline: TextBaseline.alphabetic),
  );

  static const TextTheme tall2018 = TextTheme(
    display4: TextStyle(
        debugLabel: 'tall display4 2018',
        fontSize: 96.0,
        fontWeight: FontWeight.w400,
        textBaseline: TextBaseline.alphabetic),
    display3: TextStyle(
        debugLabel: 'tall display3 2018',
        fontSize: 60.0,
        fontWeight: FontWeight.w400,
        textBaseline: TextBaseline.alphabetic),
    display2: TextStyle(
        debugLabel: 'tall display2 2018',
        fontSize: 48.0,
        fontWeight: FontWeight.w400,
        textBaseline: TextBaseline.alphabetic),
    display1: TextStyle(
        debugLabel: 'tall display1 2018',
        fontSize: 34.0,
        fontWeight: FontWeight.w400,
        textBaseline: TextBaseline.alphabetic),
    headline: TextStyle(
        debugLabel: 'tall headline 2018',
        fontSize: 24.0,
        fontWeight: FontWeight.w400,
        textBaseline: TextBaseline.alphabetic),
    title: TextStyle(
        debugLabel: 'tall title 2018',
        fontSize: 21.0,
        fontWeight: FontWeight.w700,
        textBaseline: TextBaseline.alphabetic),
    subhead: TextStyle(
        debugLabel: 'tall subhead 2018',
        fontSize: 17.0,
        fontWeight: FontWeight.w400,
        textBaseline: TextBaseline.alphabetic),
    body2: TextStyle(
        debugLabel: 'tall body2 2018',
        fontSize: 17.0,
        fontWeight: FontWeight.w700,
        textBaseline: TextBaseline.alphabetic),
    body1: TextStyle(
        debugLabel: 'tall body1 2018',
        fontSize: 15.0,
        fontWeight: FontWeight.w400,
        textBaseline: TextBaseline.alphabetic),
    button: TextStyle(
        debugLabel: 'tall button 2018',
        fontSize: 15.0,
        fontWeight: FontWeight.w700,
        textBaseline: TextBaseline.alphabetic),
    caption: TextStyle(
        debugLabel: 'tall caption 2018',
        fontSize: 13.0,
        fontWeight: FontWeight.w400,
        textBaseline: TextBaseline.alphabetic),
    subtitle: TextStyle(
        debugLabel: 'tall subtitle 2018',
        fontSize: 15.0,
        fontWeight: FontWeight.w500,
        textBaseline: TextBaseline.alphabetic),
    overline: TextStyle(
        debugLabel: 'tall overline 2018',
        fontSize: 11.0,
        fontWeight: FontWeight.w400,
        textBaseline: TextBaseline.alphabetic),
  );
}

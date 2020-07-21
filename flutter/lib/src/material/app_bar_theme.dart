import 'package:flutter_web/ui.dart' show lerpDouble;

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/widgets.dart';

import 'text_theme.dart';
import 'theme.dart';

class AppBarTheme extends Diagnosticable {
  const AppBarTheme({
    this.brightness,
    this.color,
    this.elevation,
    this.iconTheme,
    this.textTheme,
  });

  final Brightness brightness;

  final Color color;

  final double elevation;

  final IconThemeData iconTheme;

  final TextTheme textTheme;

  AppBarTheme copyWith({
    Brightness brightness,
    Color color,
    double elevation,
    IconThemeData iconTheme,
    TextTheme textTheme,
  }) {
    return AppBarTheme(
      brightness: brightness ?? this.brightness,
      color: color ?? this.color,
      elevation: elevation ?? this.elevation,
      iconTheme: iconTheme ?? this.iconTheme,
      textTheme: textTheme ?? this.textTheme,
    );
  }

  static AppBarTheme of(BuildContext context) {
    return Theme.of(context).appBarTheme;
  }

  static AppBarTheme lerp(AppBarTheme a, AppBarTheme b, double t) {
    assert(t != null);
    return AppBarTheme(
      brightness: t < 0.5 ? a?.brightness : b?.brightness,
      color: Color.lerp(a?.color, b?.color, t),
      elevation: lerpDouble(a?.elevation, b?.elevation, t),
      iconTheme: IconThemeData.lerp(a?.iconTheme, b?.iconTheme, t),
      textTheme: TextTheme.lerp(a?.textTheme, b?.textTheme, t),
    );
  }

  @override
  int get hashCode {
    return hashValues(
      brightness,
      color,
      elevation,
      iconTheme,
      textTheme,
    );
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    final AppBarTheme typedOther = other;
    return typedOther.brightness == brightness &&
        typedOther.color == color &&
        typedOther.elevation == elevation &&
        typedOther.iconTheme == iconTheme &&
        typedOther.textTheme == textTheme;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Brightness>('brightness', brightness,
        defaultValue: null));
    properties
        .add(DiagnosticsProperty<Color>('color', color, defaultValue: null));
    properties.add(DiagnosticsProperty<double>('elevation', elevation,
        defaultValue: null));
    properties.add(DiagnosticsProperty<IconThemeData>('iconTheme', iconTheme,
        defaultValue: null));
    properties.add(DiagnosticsProperty<TextTheme>('textTheme', textTheme,
        defaultValue: null));
  }
}

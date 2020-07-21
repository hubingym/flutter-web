import 'package:flutter_web/ui.dart' show lerpDouble;

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/widgets.dart';

import 'theme.dart';

class BottomAppBarTheme extends Diagnosticable {
  const BottomAppBarTheme({
    this.color,
    this.elevation,
    this.shape,
  });

  final Color color;

  final double elevation;

  final NotchedShape shape;

  BottomAppBarTheme copyWith({
    Color color,
    double elevation,
    NotchedShape shape,
  }) {
    return BottomAppBarTheme(
      color: color ?? this.color,
      elevation: elevation ?? this.elevation,
      shape: shape ?? this.shape,
    );
  }

  static BottomAppBarTheme of(BuildContext context) {
    return Theme.of(context).bottomAppBarTheme;
  }

  static BottomAppBarTheme lerp(
      BottomAppBarTheme a, BottomAppBarTheme b, double t) {
    assert(t != null);
    return BottomAppBarTheme(
      color: Color.lerp(a?.color, b?.color, t),
      elevation: lerpDouble(a?.elevation, b?.elevation, t),
      shape: t < 0.5 ? a?.shape : b?.shape,
    );
  }

  @override
  int get hashCode {
    return hashValues(
      color,
      elevation,
      shape,
    );
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    final BottomAppBarTheme typedOther = other;
    return typedOther.color == color &&
        typedOther.elevation == elevation &&
        typedOther.shape == shape;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(DiagnosticsProperty<Color>('color', color, defaultValue: null));
    properties.add(DiagnosticsProperty<double>('elevation', elevation,
        defaultValue: null));
    properties.add(
        DiagnosticsProperty<NotchedShape>('shape', shape, defaultValue: null));
  }
}

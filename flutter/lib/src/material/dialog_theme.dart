import 'package:flutter_web/ui.dart' show lerpDouble;

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/widgets.dart';

import 'theme.dart';

class DialogTheme extends Diagnosticable {
  const DialogTheme({
    this.backgroundColor,
    this.elevation,
    this.shape,
    this.titleTextStyle,
    this.contentTextStyle,
  });

  final Color backgroundColor;

  final double elevation;

  final ShapeBorder shape;

  final TextStyle titleTextStyle;

  final TextStyle contentTextStyle;

  DialogTheme copyWith({
    Color backgroundColor,
    double elevation,
    ShapeBorder shape,
    TextStyle titleTextStyle,
    TextStyle contentTextStyle,
  }) {
    return DialogTheme(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      elevation: elevation ?? this.elevation,
      shape: shape ?? this.shape,
      titleTextStyle: titleTextStyle ?? this.titleTextStyle,
      contentTextStyle: contentTextStyle ?? this.contentTextStyle,
    );
  }

  static DialogTheme of(BuildContext context) {
    return Theme.of(context).dialogTheme;
  }

  static DialogTheme lerp(DialogTheme a, DialogTheme b, double t) {
    assert(t != null);
    return DialogTheme(
      backgroundColor: Color.lerp(a?.backgroundColor, b?.backgroundColor, t),
      elevation: lerpDouble(a?.elevation, b?.elevation, t),
      shape: ShapeBorder.lerp(a?.shape, b?.shape, t),
      titleTextStyle: TextStyle.lerp(a?.titleTextStyle, b?.titleTextStyle, t),
      contentTextStyle:
          TextStyle.lerp(a?.contentTextStyle, b?.contentTextStyle, t),
    );
  }

  @override
  int get hashCode => shape.hashCode;

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    final DialogTheme typedOther = other;
    return typedOther.backgroundColor == backgroundColor &&
        typedOther.elevation == elevation &&
        typedOther.shape == shape &&
        typedOther.titleTextStyle == titleTextStyle &&
        typedOther.contentTextStyle == contentTextStyle;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ColorProperty('backgroundColor', backgroundColor));
    properties.add(
        DiagnosticsProperty<ShapeBorder>('shape', shape, defaultValue: null));
    properties.add(DoubleProperty('elevation', elevation));
    properties.add(DiagnosticsProperty<TextStyle>(
        'titleTextStyle', titleTextStyle,
        defaultValue: null));
    properties.add(DiagnosticsProperty<TextStyle>(
        'contentTextStyle', contentTextStyle,
        defaultValue: null));
  }
}

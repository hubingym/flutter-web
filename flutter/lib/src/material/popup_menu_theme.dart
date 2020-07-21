import 'package:flutter_web/ui.dart' show lerpDouble;

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/widgets.dart';

import 'theme.dart';

class PopupMenuThemeData extends Diagnosticable {
  const PopupMenuThemeData({
    this.color,
    this.shape,
    this.elevation,
    this.textStyle,
  });

  final Color color;

  final ShapeBorder shape;

  final double elevation;

  final TextStyle textStyle;

  PopupMenuThemeData copyWith({
    Color color,
    ShapeBorder shape,
    double elevation,
    TextStyle textStyle,
  }) {
    return PopupMenuThemeData(
      color: color ?? this.color,
      shape: shape ?? this.shape,
      elevation: elevation ?? this.elevation,
      textStyle: textStyle ?? this.textStyle,
    );
  }

  static PopupMenuThemeData lerp(
      PopupMenuThemeData a, PopupMenuThemeData b, double t) {
    assert(t != null);
    if (a == null && b == null) return null;
    return PopupMenuThemeData(
      color: Color.lerp(a?.color, b?.color, t),
      shape: ShapeBorder.lerp(a?.shape, b?.shape, t),
      elevation: lerpDouble(a?.elevation, b?.elevation, t),
      textStyle: TextStyle.lerp(a?.textStyle, b?.textStyle, t),
    );
  }

  @override
  int get hashCode {
    return hashValues(
      color,
      shape,
      elevation,
      textStyle,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    final PopupMenuThemeData typedOther = other;
    return typedOther.elevation == elevation &&
        typedOther.color == color &&
        typedOther.shape == shape &&
        typedOther.textStyle == textStyle;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ColorProperty('color', color, defaultValue: null));
    properties.add(
        DiagnosticsProperty<ShapeBorder>('shape', shape, defaultValue: null));
    properties.add(DoubleProperty('elevation', elevation, defaultValue: null));
    properties.add(DiagnosticsProperty<TextStyle>('text style', textStyle,
        defaultValue: null));
  }
}

class PopupMenuTheme extends InheritedWidget {
  PopupMenuTheme({
    Key key,
    Color color,
    ShapeBorder shape,
    double elevation,
    TextStyle textStyle,
    Widget child,
  })  : data = PopupMenuThemeData(
          color: color,
          shape: shape,
          elevation: elevation,
          textStyle: textStyle,
        ),
        super(key: key, child: child);

  final PopupMenuThemeData data;

  static PopupMenuThemeData of(BuildContext context) {
    final PopupMenuTheme popupMenuTheme =
        context.inheritFromWidgetOfExactType(PopupMenuTheme);
    return popupMenuTheme?.data ?? Theme.of(context).popupMenuTheme;
  }

  @override
  bool updateShouldNotify(PopupMenuTheme oldWidget) => data != oldWidget.data;
}

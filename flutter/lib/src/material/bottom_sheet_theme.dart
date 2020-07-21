import 'package:flutter_web/ui.dart' show lerpDouble;

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/rendering.dart';

class BottomSheetThemeData extends Diagnosticable {
  const BottomSheetThemeData({
    this.backgroundColor,
    this.elevation,
    this.shape,
  });

  final Color backgroundColor;

  final double elevation;

  final ShapeBorder shape;

  BottomSheetThemeData copyWith({
    Color backgroundColor,
    double elevation,
    ShapeBorder shape,
  }) {
    return BottomSheetThemeData(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      elevation: elevation ?? this.elevation,
      shape: shape ?? this.shape,
    );
  }

  static BottomSheetThemeData lerp(
      BottomSheetThemeData a, BottomSheetThemeData b, double t) {
    assert(t != null);
    if (a == null && b == null) return null;
    return BottomSheetThemeData(
      backgroundColor: Color.lerp(a?.backgroundColor, b?.backgroundColor, t),
      elevation: lerpDouble(a?.elevation, b?.elevation, t),
      shape: ShapeBorder.lerp(a?.shape, b?.shape, t),
    );
  }

  @override
  int get hashCode {
    return hashValues(
      backgroundColor,
      elevation,
      shape,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    final BottomSheetThemeData typedOther = other;
    return typedOther.backgroundColor == backgroundColor &&
        typedOther.elevation == elevation &&
        typedOther.shape == shape;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Color>(
        'backgroundColor', backgroundColor,
        defaultValue: null));
    properties.add(DiagnosticsProperty<double>('elevation', elevation,
        defaultValue: null));
    properties.add(
        DiagnosticsProperty<ShapeBorder>('shape', shape, defaultValue: null));
  }
}

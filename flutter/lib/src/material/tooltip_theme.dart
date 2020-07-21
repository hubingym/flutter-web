import 'package:flutter_web/ui.dart' show lerpDouble;

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/widgets.dart';

import 'theme.dart';

class TooltipThemeData extends Diagnosticable {
  const TooltipThemeData({
    this.height,
    this.padding,
    this.margin,
    this.verticalOffset,
    this.preferBelow,
    this.excludeFromSemantics,
    this.decoration,
    this.textStyle,
    this.waitDuration,
    this.showDuration,
  });

  final double height;

  final EdgeInsetsGeometry padding;

  final EdgeInsetsGeometry margin;

  final double verticalOffset;

  final bool preferBelow;

  final bool excludeFromSemantics;

  final Decoration decoration;

  final TextStyle textStyle;

  final Duration waitDuration;

  final Duration showDuration;

  TooltipThemeData copyWith({
    double height,
    EdgeInsetsGeometry padding,
    EdgeInsetsGeometry margin,
    double verticalOffset,
    bool preferBelow,
    bool excludeFromSemantics,
    Decoration decoration,
    TextStyle textStyle,
    Duration waitDuration,
    Duration showDuration,
  }) {
    return TooltipThemeData(
      height: height ?? this.height,
      padding: padding ?? this.padding,
      margin: margin ?? this.margin,
      verticalOffset: verticalOffset ?? this.verticalOffset,
      preferBelow: preferBelow ?? this.preferBelow,
      excludeFromSemantics: excludeFromSemantics ?? this.excludeFromSemantics,
      decoration: decoration ?? this.decoration,
      textStyle: textStyle ?? this.textStyle,
      waitDuration: waitDuration ?? this.waitDuration,
      showDuration: showDuration ?? this.showDuration,
    );
  }

  static TooltipThemeData lerp(
      TooltipThemeData a, TooltipThemeData b, double t) {
    if (a == null && b == null) return null;
    assert(t != null);
    return TooltipThemeData(
      height: lerpDouble(a?.height, b?.height, t),
      padding: EdgeInsets.lerp(a?.padding, b?.padding, t),
      margin: EdgeInsets.lerp(a?.margin, b?.margin, t),
      verticalOffset: lerpDouble(a?.verticalOffset, b?.verticalOffset, t),
      preferBelow: t < 0.5 ? a.preferBelow : b.preferBelow,
      excludeFromSemantics:
          t < 0.5 ? a.excludeFromSemantics : b.excludeFromSemantics,
      decoration: Decoration.lerp(a?.decoration, b?.decoration, t),
      textStyle: TextStyle.lerp(a?.textStyle, b?.textStyle, t),
    );
  }

  @override
  int get hashCode {
    return hashValues(
      height,
      padding,
      margin,
      verticalOffset,
      preferBelow,
      excludeFromSemantics,
      decoration,
      textStyle,
      waitDuration,
      showDuration,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    final TooltipThemeData typedOther = other;
    return typedOther.height == height &&
        typedOther.padding == padding &&
        typedOther.margin == margin &&
        typedOther.verticalOffset == verticalOffset &&
        typedOther.preferBelow == preferBelow &&
        typedOther.excludeFromSemantics == excludeFromSemantics &&
        typedOther.decoration == decoration &&
        typedOther.textStyle == textStyle &&
        typedOther.waitDuration == waitDuration &&
        typedOther.showDuration == showDuration;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('height', height, defaultValue: null));
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('padding', padding,
        defaultValue: null));
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('margin', margin,
        defaultValue: null));
    properties.add(
        DoubleProperty('vertical offset', verticalOffset, defaultValue: null));
    properties.add(FlagProperty('position',
        value: preferBelow,
        ifTrue: 'below',
        ifFalse: 'above',
        showName: true,
        defaultValue: null));
    properties.add(FlagProperty('semantics',
        value: excludeFromSemantics,
        ifTrue: 'excluded',
        showName: true,
        defaultValue: null));
    properties.add(DiagnosticsProperty<Decoration>('decoration', decoration,
        defaultValue: null));
    properties.add(DiagnosticsProperty<TextStyle>('textStyle', textStyle,
        defaultValue: null));
    properties.add(DiagnosticsProperty<Duration>('wait duration', waitDuration,
        defaultValue: null));
    properties.add(DiagnosticsProperty<Duration>('show duration', showDuration,
        defaultValue: null));
  }
}

class TooltipTheme extends InheritedWidget {
  TooltipTheme({
    Key key,
    double height,
    EdgeInsetsGeometry padding,
    EdgeInsetsGeometry margin,
    double verticalOffset,
    bool preferBelow,
    bool excludeFromSemantics,
    Decoration decoration,
    TextStyle textStyle,
    Duration waitDuration,
    Duration showDuration,
    Widget child,
  })  : data = TooltipThemeData(
          height: height,
          padding: padding,
          margin: margin,
          verticalOffset: verticalOffset,
          preferBelow: preferBelow,
          excludeFromSemantics: excludeFromSemantics,
          decoration: decoration,
          textStyle: textStyle,
          waitDuration: waitDuration,
          showDuration: showDuration,
        ),
        super(key: key, child: child);

  final TooltipThemeData data;

  static TooltipThemeData of(BuildContext context) {
    final TooltipTheme tooltipTheme =
        context.inheritFromWidgetOfExactType(TooltipTheme);
    return tooltipTheme?.data ?? Theme.of(context).tooltipTheme;
  }

  @override
  bool updateShouldNotify(TooltipTheme oldWidget) => data != oldWidget.data;
}

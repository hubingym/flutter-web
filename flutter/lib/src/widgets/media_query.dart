import 'dart:math' as math;
import 'package:meta/meta.dart';

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/painting.dart';
import 'package:flutter_web/ui.dart';
import 'package:flutter_web/ui.dart' as ui;

import 'framework.dart';

enum Orientation {
  portrait,

  landscape
}

@immutable
class MediaQueryData {
  const MediaQueryData({
    this.size = Size.zero,
    this.devicePixelRatio = 1.0,
    this.textScaleFactor = 1.0,
    this.platformBrightness = Brightness.light,
    this.padding = EdgeInsets.zero,
    this.viewInsets = EdgeInsets.zero,
    this.viewPadding = EdgeInsets.zero,
    this.alwaysUse24HourFormat = false,
    this.accessibleNavigation = false,
    this.invertColors = false,
    this.disableAnimations = false,
    this.boldText = false,
  });

  MediaQueryData.fromWindow(ui.Window window)
      : size = window.physicalSize / window.devicePixelRatio,
        devicePixelRatio = window.devicePixelRatio,
        textScaleFactor = window.textScaleFactor,
        platformBrightness = window.platformBrightness,
        padding = EdgeInsets.fromWindowPadding(
            window.padding, window.devicePixelRatio),
        viewPadding = EdgeInsets.fromWindowPadding(
            window.viewPadding, window.devicePixelRatio),
        viewInsets = EdgeInsets.fromWindowPadding(
            window.viewInsets, window.devicePixelRatio),
        accessibleNavigation =
            window.accessibilityFeatures.accessibleNavigation,
        invertColors = window.accessibilityFeatures.invertColors,
        disableAnimations = window.accessibilityFeatures.disableAnimations,
        boldText = window.accessibilityFeatures.boldText,
        alwaysUse24HourFormat = window.alwaysUse24HourFormat;

  final Size size;

  final double devicePixelRatio;

  final double textScaleFactor;

  final Brightness platformBrightness;

  final EdgeInsets viewInsets;

  final EdgeInsets padding;

  final EdgeInsets viewPadding;

  final bool alwaysUse24HourFormat;

  final bool accessibleNavigation;

  final bool invertColors;

  final bool disableAnimations;

  final bool boldText;

  Orientation get orientation {
    return size.width > size.height
        ? Orientation.landscape
        : Orientation.portrait;
  }

  MediaQueryData copyWith({
    Size size,
    double devicePixelRatio,
    double textScaleFactor,
    Brightness platformBrightness,
    EdgeInsets padding,
    EdgeInsets viewPadding,
    EdgeInsets viewInsets,
    bool alwaysUse24HourFormat,
    bool disableAnimations,
    bool invertColors,
    bool accessibleNavigation,
    bool boldText,
  }) {
    return MediaQueryData(
      size: size ?? this.size,
      devicePixelRatio: devicePixelRatio ?? this.devicePixelRatio,
      textScaleFactor: textScaleFactor ?? this.textScaleFactor,
      platformBrightness: platformBrightness ?? this.platformBrightness,
      padding: padding ?? this.padding,
      viewPadding: viewPadding ?? this.viewPadding,
      viewInsets: viewInsets ?? this.viewInsets,
      alwaysUse24HourFormat:
          alwaysUse24HourFormat ?? this.alwaysUse24HourFormat,
      invertColors: invertColors ?? this.invertColors,
      disableAnimations: disableAnimations ?? this.disableAnimations,
      accessibleNavigation: accessibleNavigation ?? this.accessibleNavigation,
      boldText: boldText ?? this.boldText,
    );
  }

  MediaQueryData removePadding({
    bool removeLeft = false,
    bool removeTop = false,
    bool removeRight = false,
    bool removeBottom = false,
  }) {
    if (!(removeLeft || removeTop || removeRight || removeBottom)) return this;
    return MediaQueryData(
      size: size,
      devicePixelRatio: devicePixelRatio,
      textScaleFactor: textScaleFactor,
      platformBrightness: platformBrightness,
      padding: padding.copyWith(
        left: removeLeft ? 0.0 : null,
        top: removeTop ? 0.0 : null,
        right: removeRight ? 0.0 : null,
        bottom: removeBottom ? 0.0 : null,
      ),
      viewPadding: viewPadding.copyWith(
        left: math.max(0.0, viewPadding.left - padding.left),
        top: math.max(0.0, viewPadding.top - padding.top),
        right: math.max(0.0, viewPadding.right - padding.right),
        bottom: math.max(0.0, viewPadding.bottom - padding.bottom),
      ),
      viewInsets: viewInsets,
      alwaysUse24HourFormat: alwaysUse24HourFormat,
      disableAnimations: disableAnimations,
      invertColors: invertColors,
      accessibleNavigation: accessibleNavigation,
      boldText: boldText,
    );
  }

  MediaQueryData removeViewInsets({
    bool removeLeft = false,
    bool removeTop = false,
    bool removeRight = false,
    bool removeBottom = false,
  }) {
    if (!(removeLeft || removeTop || removeRight || removeBottom)) return this;
    return MediaQueryData(
      size: size,
      devicePixelRatio: devicePixelRatio,
      textScaleFactor: textScaleFactor,
      platformBrightness: platformBrightness,
      padding: padding,
      viewPadding: viewPadding.copyWith(
        left: math.max(0.0, viewPadding.left - viewInsets.left),
        top: math.max(0.0, viewPadding.top - viewInsets.top),
        right: math.max(0.0, viewPadding.right - viewInsets.right),
        bottom: math.max(0.0, viewPadding.bottom - viewInsets.bottom),
      ),
      viewInsets: viewInsets.copyWith(
        left: removeLeft ? 0.0 : null,
        top: removeTop ? 0.0 : null,
        right: removeRight ? 0.0 : null,
        bottom: removeBottom ? 0.0 : null,
      ),
      alwaysUse24HourFormat: alwaysUse24HourFormat,
      disableAnimations: disableAnimations,
      invertColors: invertColors,
      accessibleNavigation: accessibleNavigation,
      boldText: boldText,
    );
  }

  MediaQueryData removeViewPadding({
    bool removeLeft = false,
    bool removeTop = false,
    bool removeRight = false,
    bool removeBottom = false,
  }) {
    if (!(removeLeft || removeTop || removeRight || removeBottom)) return this;
    return MediaQueryData(
      size: size,
      devicePixelRatio: devicePixelRatio,
      textScaleFactor: textScaleFactor,
      platformBrightness: platformBrightness,
      padding: padding.copyWith(
        left: removeLeft ? 0.0 : null,
        top: removeTop ? 0.0 : null,
        right: removeRight ? 0.0 : null,
        bottom: removeBottom ? 0.0 : null,
      ),
      viewInsets: viewInsets,
      viewPadding: viewPadding.copyWith(
        left: removeLeft ? 0.0 : null,
        top: removeTop ? 0.0 : null,
        right: removeRight ? 0.0 : null,
        bottom: removeBottom ? 0.0 : null,
      ),
      alwaysUse24HourFormat: alwaysUse24HourFormat,
      disableAnimations: disableAnimations,
      invertColors: invertColors,
      accessibleNavigation: accessibleNavigation,
      boldText: boldText,
    );
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    final MediaQueryData typedOther = other;
    return typedOther.size == size &&
        typedOther.devicePixelRatio == devicePixelRatio &&
        typedOther.textScaleFactor == textScaleFactor &&
        typedOther.platformBrightness == platformBrightness &&
        typedOther.padding == padding &&
        typedOther.viewPadding == viewPadding &&
        typedOther.viewInsets == viewInsets &&
        typedOther.alwaysUse24HourFormat == alwaysUse24HourFormat &&
        typedOther.disableAnimations == disableAnimations &&
        typedOther.invertColors == invertColors &&
        typedOther.accessibleNavigation == accessibleNavigation &&
        typedOther.boldText == boldText;
  }

  @override
  int get hashCode {
    return hashValues(
      size,
      devicePixelRatio,
      textScaleFactor,
      platformBrightness,
      padding,
      viewPadding,
      viewInsets,
      alwaysUse24HourFormat,
      disableAnimations,
      invertColors,
      accessibleNavigation,
      boldText,
    );
  }

  @override
  String toString() {
    return '$runtimeType('
        'size: $size, '
        'devicePixelRatio: ${devicePixelRatio.toStringAsFixed(1)}, '
        'textScaleFactor: ${textScaleFactor.toStringAsFixed(1)}, '
        'platformBrightness: $platformBrightness, '
        'padding: $padding, '
        'viewPadding: $viewPadding, '
        'viewInsets: $viewInsets, '
        'alwaysUse24HourFormat: $alwaysUse24HourFormat, '
        'accessibleNavigation: $accessibleNavigation, '
        'disableAnimations: $disableAnimations, '
        'invertColors: $invertColors, '
        'boldText: $boldText'
        ')';
  }
}

class MediaQuery extends InheritedWidget {
  const MediaQuery({
    Key key,
    @required this.data,
    @required Widget child,
  })  : assert(child != null),
        assert(data != null),
        super(key: key, child: child);

  factory MediaQuery.removePadding({
    Key key,
    @required BuildContext context,
    bool removeLeft = false,
    bool removeTop = false,
    bool removeRight = false,
    bool removeBottom = false,
    @required Widget child,
  }) {
    return MediaQuery(
      key: key,
      data: MediaQuery.of(context).removePadding(
        removeLeft: removeLeft,
        removeTop: removeTop,
        removeRight: removeRight,
        removeBottom: removeBottom,
      ),
      child: child,
    );
  }

  factory MediaQuery.removeViewInsets({
    Key key,
    @required BuildContext context,
    bool removeLeft = false,
    bool removeTop = false,
    bool removeRight = false,
    bool removeBottom = false,
    @required Widget child,
  }) {
    return MediaQuery(
      key: key,
      data: MediaQuery.of(context).removeViewInsets(
        removeLeft: removeLeft,
        removeTop: removeTop,
        removeRight: removeRight,
        removeBottom: removeBottom,
      ),
      child: child,
    );
  }

  factory MediaQuery.removeViewPadding({
    Key key,
    @required BuildContext context,
    bool removeLeft = false,
    bool removeTop = false,
    bool removeRight = false,
    bool removeBottom = false,
    @required Widget child,
  }) {
    return MediaQuery(
      key: key,
      data: MediaQuery.of(context).removeViewPadding(
        removeLeft: removeLeft,
        removeTop: removeTop,
        removeRight: removeRight,
        removeBottom: removeBottom,
      ),
      child: child,
    );
  }

  final MediaQueryData data;

  static MediaQueryData of(BuildContext context, {bool nullOk = false}) {
    assert(context != null);
    assert(nullOk != null);
    final MediaQuery query = context.inheritFromWidgetOfExactType(MediaQuery);
    if (query != null) return query.data;
    if (nullOk) return null;
    throw FlutterError(
        'MediaQuery.of() called with a context that does not contain a MediaQuery.\n'
        'No MediaQuery ancestor could be found starting from the context that was passed '
        'to MediaQuery.of(). This can happen because you do not have a WidgetsApp or '
        'MaterialApp widget (those widgets introduce a MediaQuery), or it can happen '
        'if the context you use comes from a widget above those widgets.\n'
        'The context used was:\n'
        '  $context');
  }

  static double textScaleFactorOf(BuildContext context) {
    return MediaQuery.of(context, nullOk: true)?.textScaleFactor ?? 1.0;
  }

  static Brightness platformBrightnessOf(BuildContext context) {
    return MediaQuery.of(context, nullOk: true)?.platformBrightness ??
        Brightness.light;
  }

  static bool boldTextOverride(BuildContext context) {
    return MediaQuery.of(context, nullOk: true)?.boldText ?? false;
  }

  @override
  bool updateShouldNotify(MediaQuery oldWidget) => data != oldWidget.data;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
        DiagnosticsProperty<MediaQueryData>('data', data, showName: false));
  }
}

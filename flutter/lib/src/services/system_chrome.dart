import 'dart:async';
import 'package:flutter_web/ui.dart';

import 'package:flutter_web/foundation.dart';

import 'system_channels.dart';

export 'package:flutter_web/ui.dart' show Brightness;

enum DeviceOrientation {
  portraitUp,

  landscapeLeft,

  portraitDown,

  landscapeRight,
}

@immutable
class ApplicationSwitcherDescription {
  const ApplicationSwitcherDescription({this.label, this.primaryColor});

  final String label;

  final int primaryColor;
}

enum SystemUiOverlay {
  top,

  bottom,
}

class SystemUiOverlayStyle {
  const SystemUiOverlayStyle({
    this.systemNavigationBarColor,
    this.systemNavigationBarDividerColor,
    this.systemNavigationBarIconBrightness,
    this.statusBarColor,
    this.statusBarBrightness,
    this.statusBarIconBrightness,
  });

  final Color systemNavigationBarColor;

  final Color systemNavigationBarDividerColor;

  final Brightness systemNavigationBarIconBrightness;

  final Color statusBarColor;

  final Brightness statusBarBrightness;

  final Brightness statusBarIconBrightness;

  static const SystemUiOverlayStyle light = SystemUiOverlayStyle(
    systemNavigationBarColor: Color(0xFF000000),
    systemNavigationBarDividerColor: null,
    statusBarColor: null,
    systemNavigationBarIconBrightness: Brightness.light,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  );

  static const SystemUiOverlayStyle dark = SystemUiOverlayStyle(
    systemNavigationBarColor: Color(0xFF000000),
    systemNavigationBarDividerColor: null,
    statusBarColor: null,
    systemNavigationBarIconBrightness: Brightness.light,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  );

  Map<String, dynamic> _toMap() {
    return <String, dynamic>{
      'systemNavigationBarColor': systemNavigationBarColor?.value,
      'systemNavigationBarDividerColor': systemNavigationBarDividerColor?.value,
      'statusBarColor': statusBarColor?.value,
      'statusBarBrightness': statusBarBrightness?.toString(),
      'statusBarIconBrightness': statusBarIconBrightness?.toString(),
      'systemNavigationBarIconBrightness':
          systemNavigationBarIconBrightness?.toString(),
    };
  }

  @override
  String toString() => _toMap().toString();

  SystemUiOverlayStyle copyWith({
    Color systemNavigationBarColor,
    Color systemNavigationBarDividerColor,
    Color statusBarColor,
    Brightness statusBarBrightness,
    Brightness statusBarIconBrightness,
    Brightness systemNavigationBarIconBrightness,
  }) {
    return SystemUiOverlayStyle(
      systemNavigationBarColor:
          systemNavigationBarColor ?? this.systemNavigationBarColor,
      systemNavigationBarDividerColor: systemNavigationBarDividerColor ??
          this.systemNavigationBarDividerColor,
      statusBarColor: statusBarColor ?? this.statusBarColor,
      statusBarIconBrightness:
          statusBarIconBrightness ?? this.statusBarIconBrightness,
      statusBarBrightness: statusBarBrightness ?? this.statusBarBrightness,
      systemNavigationBarIconBrightness: systemNavigationBarIconBrightness ??
          this.systemNavigationBarIconBrightness,
    );
  }

  @override
  int get hashCode {
    return hashValues(
      systemNavigationBarColor,
      systemNavigationBarDividerColor,
      statusBarColor,
      statusBarBrightness,
      statusBarIconBrightness,
      systemNavigationBarIconBrightness,
    );
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) return false;
    final SystemUiOverlayStyle typedOther = other;
    return typedOther.systemNavigationBarColor == systemNavigationBarColor &&
        typedOther.systemNavigationBarDividerColor ==
            systemNavigationBarDividerColor &&
        typedOther.statusBarColor == statusBarColor &&
        typedOther.statusBarIconBrightness == statusBarIconBrightness &&
        typedOther.statusBarBrightness == statusBarBrightness &&
        typedOther.systemNavigationBarIconBrightness ==
            systemNavigationBarIconBrightness;
  }
}

List<String> _stringify(List<dynamic> list) {
  final List<String> result = <String>[];
  for (dynamic item in list) result.add(item.toString());
  return result;
}

class SystemChrome {
  SystemChrome._();

  static Future<void> setPreferredOrientations(
      List<DeviceOrientation> orientations) async {
    await SystemChannels.platform.invokeMethod<void>(
      'SystemChrome.setPreferredOrientations',
      _stringify(orientations),
    );
  }

  static Future<void> setApplicationSwitcherDescription(
      ApplicationSwitcherDescription description) async {
    await SystemChannels.platform.invokeMethod<void>(
      'SystemChrome.setApplicationSwitcherDescription',
      <String, dynamic>{
        'label': description.label,
        'primaryColor': description.primaryColor,
      },
    );
  }

  static Future<void> setEnabledSystemUIOverlays(
      List<SystemUiOverlay> overlays) async {
    await SystemChannels.platform.invokeMethod<void>(
      'SystemChrome.setEnabledSystemUIOverlays',
      _stringify(overlays),
    );
  }

  static Future<void> restoreSystemUIOverlays() async {
    await SystemChannels.platform.invokeMethod<void>(
      'SystemChrome.restoreSystemUIOverlays',
      null,
    );
  }

  static void setSystemUIOverlayStyle(SystemUiOverlayStyle style) {
    assert(style != null);
    if (_pendingStyle != null) {
      _pendingStyle = style;
      return;
    }
    if (style == _latestStyle) {
      return;
    }
    _pendingStyle = style;
    scheduleMicrotask(() {
      assert(_pendingStyle != null);
      if (_pendingStyle != _latestStyle) {
        SystemChannels.platform.invokeMethod<void>(
          'SystemChrome.setSystemUIOverlayStyle',
          _pendingStyle._toMap(),
        );
        _latestStyle = _pendingStyle;
      }
      _pendingStyle = null;
    });
  }

  static SystemUiOverlayStyle _pendingStyle;

  @visibleForTesting
  static SystemUiOverlayStyle get latestStyle => _latestStyle;
  static SystemUiOverlayStyle _latestStyle;
}

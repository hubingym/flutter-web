import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_web/ui.dart';

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/gestures.dart';

import 'message_codec.dart';
import 'system_channels.dart';

final PlatformViewsRegistry platformViewsRegistry =
    PlatformViewsRegistry._instance();

class PlatformViewsRegistry {
  PlatformViewsRegistry._instance();

  int _nextPlatformViewId = 0;

  int getNextPlatformViewId() => _nextPlatformViewId++;
}

typedef PlatformViewCreatedCallback = void Function(int id);

class PlatformViewsService {
  PlatformViewsService._() {
    SystemChannels.platform_views.setMethodCallHandler(_onMethodCall);
  }

  static PlatformViewsService _serviceInstance;

  static PlatformViewsService get _instance {
    _serviceInstance ??= PlatformViewsService._();
    return _serviceInstance;
  }

  Future<void> _onMethodCall(MethodCall call) {
    switch (call.method) {
      case 'viewFocused':
        final int id = call.arguments;
        if (_focusCallbacks.containsKey(id)) {
          _focusCallbacks[id]();
        }
        break;
      default:
        throw UnimplementedError(
            '${call.method} was invoked but isn\'t implemented by PlatformViewsService');
    }
    return null;
  }

  final Map<int, VoidCallback> _focusCallbacks = <int, VoidCallback>{};

  static AndroidViewController initAndroidView({
    @required int id,
    @required String viewType,
    @required TextDirection layoutDirection,
    dynamic creationParams,
    MessageCodec<dynamic> creationParamsCodec,
    VoidCallback onFocus,
  }) {
    assert(id != null);
    assert(viewType != null);
    assert(layoutDirection != null);
    assert(creationParams == null || creationParamsCodec != null);
    final AndroidViewController controller = AndroidViewController._(
      id,
      viewType,
      creationParams,
      creationParamsCodec,
      layoutDirection,
    );
    _instance._focusCallbacks[id] = onFocus ?? () {};
    return controller;
  }

  static Future<UiKitViewController> initUiKitView({
    @required int id,
    @required String viewType,
    @required TextDirection layoutDirection,
    dynamic creationParams,
    MessageCodec<dynamic> creationParamsCodec,
  }) async {
    assert(id != null);
    assert(viewType != null);
    assert(layoutDirection != null);
    assert(creationParams == null || creationParamsCodec != null);

    final Map<String, dynamic> args = <String, dynamic>{
      'id': id,
      'viewType': viewType,
    };
    if (creationParams != null) {
      final ByteData paramsByteData =
          creationParamsCodec.encodeMessage(creationParams);
      args['params'] = Uint8List.view(
        paramsByteData.buffer,
        0,
        paramsByteData.lengthInBytes,
      );
    }
    await SystemChannels.platform_views.invokeMethod<void>('create', args);
    return UiKitViewController._(id, layoutDirection);
  }
}

class AndroidPointerProperties {
  const AndroidPointerProperties({
    @required this.id,
    @required this.toolType,
  })  : assert(id != null),
        assert(toolType != null);

  final int id;

  final int toolType;

  static const int kToolTypeUnknown = 0;

  static const int kToolTypeFinger = 1;

  static const int kToolTypeStylus = 2;

  static const int kToolTypeMouse = 3;

  static const int kToolTypeEraser = 4;

  List<int> _asList() => <int>[id, toolType];

  @override
  String toString() {
    return 'AndroidPointerProperties(id: $id, toolType: $toolType)';
  }
}

class AndroidPointerCoords {
  const AndroidPointerCoords({
    @required this.orientation,
    @required this.pressure,
    @required this.size,
    @required this.toolMajor,
    @required this.toolMinor,
    @required this.touchMajor,
    @required this.touchMinor,
    @required this.x,
    @required this.y,
  })  : assert(orientation != null),
        assert(pressure != null),
        assert(size != null),
        assert(toolMajor != null),
        assert(toolMinor != null),
        assert(touchMajor != null),
        assert(touchMinor != null),
        assert(x != null),
        assert(y != null);

  final double orientation;

  final double pressure;

  final double size;

  final double toolMajor;

  final double toolMinor;

  final double touchMajor;

  final double touchMinor;

  final double x;

  final double y;

  List<double> _asList() {
    return <double>[
      orientation,
      pressure,
      size,
      toolMajor,
      toolMinor,
      touchMajor,
      touchMinor,
      x,
      y,
    ];
  }

  @override
  String toString() {
    return 'AndroidPointerCoords(orientation: $orientation, pressure: $pressure, size: $size, toolMajor: $toolMajor, toolMinor: $toolMinor, touchMajor: $touchMajor, touchMinor: $touchMinor, x: $x, y: $y)';
  }
}

class AndroidMotionEvent {
  AndroidMotionEvent({
    @required this.downTime,
    @required this.eventTime,
    @required this.action,
    @required this.pointerCount,
    @required this.pointerProperties,
    @required this.pointerCoords,
    @required this.metaState,
    @required this.buttonState,
    @required this.xPrecision,
    @required this.yPrecision,
    @required this.deviceId,
    @required this.edgeFlags,
    @required this.source,
    @required this.flags,
  })  : assert(downTime != null),
        assert(eventTime != null),
        assert(action != null),
        assert(pointerCount != null),
        assert(pointerProperties != null),
        assert(pointerCoords != null),
        assert(metaState != null),
        assert(buttonState != null),
        assert(xPrecision != null),
        assert(yPrecision != null),
        assert(deviceId != null),
        assert(edgeFlags != null),
        assert(source != null),
        assert(flags != null),
        assert(pointerProperties.length == pointerCount),
        assert(pointerCoords.length == pointerCount);

  final int downTime;

  final int eventTime;

  final int action;

  final int pointerCount;

  final List<AndroidPointerProperties> pointerProperties;

  final List<AndroidPointerCoords> pointerCoords;

  final int metaState;

  final int buttonState;

  final double xPrecision;

  final double yPrecision;

  final int deviceId;

  final int edgeFlags;

  final int source;

  final int flags;

  List<dynamic> _asList(int viewId) {
    return <dynamic>[
      viewId,
      downTime,
      eventTime,
      action,
      pointerCount,
      pointerProperties
          .map<List<int>>((AndroidPointerProperties p) => p._asList())
          .toList(),
      pointerCoords
          .map<List<double>>((AndroidPointerCoords p) => p._asList())
          .toList(),
      metaState,
      buttonState,
      xPrecision,
      yPrecision,
      deviceId,
      edgeFlags,
      source,
      flags,
    ];
  }

  @override
  String toString() {
    return 'AndroidPointerEvent(downTime: $downTime, eventTime: $eventTime, action: $action, pointerCount: $pointerCount, pointerProperties: $pointerProperties, pointerCoords: $pointerCoords, metaState: $metaState, buttonState: $buttonState, xPrecision: $xPrecision, yPrecision: $yPrecision, deviceId: $deviceId, edgeFlags: $edgeFlags, source: $source, flags: $flags)';
  }
}

enum _AndroidViewState {
  waitingForSize,
  creating,
  created,
  createFailed,
  disposed,
}

class AndroidViewController {
  AndroidViewController._(
    this.id,
    String viewType,
    dynamic creationParams,
    MessageCodec<dynamic> creationParamsCodec,
    TextDirection layoutDirection,
  )   : assert(id != null),
        assert(viewType != null),
        assert(layoutDirection != null),
        assert(creationParams == null || creationParamsCodec != null),
        _viewType = viewType,
        _creationParams = creationParams,
        _creationParamsCodec = creationParamsCodec,
        _layoutDirection = layoutDirection,
        _state = _AndroidViewState.waitingForSize;

  static const int kActionDown = 0;

  static const int kActionUp = 1;

  static const int kActionMove = 2;

  static const int kActionCancel = 3;

  static const int kActionPointerDown = 5;

  static const int kActionPointerUp = 6;

  static const int kAndroidLayoutDirectionLtr = 0;

  static const int kAndroidLayoutDirectionRtl = 1;

  final int id;

  final String _viewType;

  int _textureId;

  int get textureId => _textureId;

  TextDirection _layoutDirection;

  _AndroidViewState _state;

  final dynamic _creationParams;

  final MessageCodec<dynamic> _creationParamsCodec;

  final List<PlatformViewCreatedCallback> _platformViewCreatedCallbacks =
      <PlatformViewCreatedCallback>[];

  bool get isCreated => _state == _AndroidViewState.created;

  void addOnPlatformViewCreatedListener(PlatformViewCreatedCallback listener) {
    assert(listener != null);
    assert(_state != _AndroidViewState.disposed);
    _platformViewCreatedCallbacks.add(listener);
  }

  void removeOnPlatformViewCreatedListener(
      PlatformViewCreatedCallback listener) {
    assert(_state != _AndroidViewState.disposed);
    _platformViewCreatedCallbacks.remove(listener);
  }

  Future<void> dispose() async {
    if (_state == _AndroidViewState.creating ||
        _state == _AndroidViewState.created)
      await SystemChannels.platform_views.invokeMethod<void>('dispose', id);
    _platformViewCreatedCallbacks.clear();
    _state = _AndroidViewState.disposed;
  }

  Future<void> setSize(Size size) async {
    assert(_state != _AndroidViewState.disposed,
        'trying to size a disposed Android View. View id: $id');

    assert(size != null);
    assert(!size.isEmpty);

    if (_state == _AndroidViewState.waitingForSize) return _create(size);

    await SystemChannels.platform_views
        .invokeMethod<void>('resize', <String, dynamic>{
      'id': id,
      'width': size.width,
      'height': size.height,
    });
  }

  Future<void> setLayoutDirection(TextDirection layoutDirection) async {
    assert(_state != _AndroidViewState.disposed,
        'trying to set a layout direction for a disposed UIView. View id: $id');

    if (layoutDirection == _layoutDirection) return;

    assert(layoutDirection != null);
    _layoutDirection = layoutDirection;

    if (_state == _AndroidViewState.waitingForSize) return;

    await SystemChannels.platform_views
        .invokeMethod<void>('setDirection', <String, dynamic>{
      'id': id,
      'direction': _getAndroidDirection(layoutDirection),
    });
  }

  Future<void> clearFocus() {
    if (_state != _AndroidViewState.created) {
      return null;
    }
    return SystemChannels.platform_views.invokeMethod<void>('clearFocus', id);
  }

  static int _getAndroidDirection(TextDirection direction) {
    assert(direction != null);
    switch (direction) {
      case TextDirection.ltr:
        return kAndroidLayoutDirectionLtr;
      case TextDirection.rtl:
        return kAndroidLayoutDirectionRtl;
    }
    return null;
  }

  Future<void> sendMotionEvent(AndroidMotionEvent event) async {
    await SystemChannels.platform_views.invokeMethod<dynamic>(
      'touch',
      event._asList(id),
    );
  }

  static int pointerAction(int pointerId, int action) {
    return ((pointerId << 8) & 0xff00) | (action & 0xff);
  }

  Future<void> _create(Size size) async {
    final Map<String, dynamic> args = <String, dynamic>{
      'id': id,
      'viewType': _viewType,
      'width': size.width,
      'height': size.height,
      'direction': _getAndroidDirection(_layoutDirection),
    };
    if (_creationParams != null) {
      final ByteData paramsByteData =
          _creationParamsCodec.encodeMessage(_creationParams);
      args['params'] = Uint8List.view(
        paramsByteData.buffer,
        0,
        paramsByteData.lengthInBytes,
      );
    }
    _textureId =
        await SystemChannels.platform_views.invokeMethod('create', args);
    _state = _AndroidViewState.created;
    for (PlatformViewCreatedCallback callback
        in _platformViewCreatedCallbacks) {
      callback(id);
    }
  }
}

class UiKitViewController {
  UiKitViewController._(
    this.id,
    TextDirection layoutDirection,
  )   : assert(id != null),
        assert(layoutDirection != null),
        _layoutDirection = layoutDirection;

  final int id;

  bool _debugDisposed = false;

  TextDirection _layoutDirection;

  Future<void> setLayoutDirection(TextDirection layoutDirection) async {
    assert(!_debugDisposed,
        'trying to set a layout direction for a disposed iOS UIView. View id: $id');

    if (layoutDirection == _layoutDirection) return;

    assert(layoutDirection != null);
    _layoutDirection = layoutDirection;
  }

  Future<void> acceptGesture() {
    final Map<String, dynamic> args = <String, dynamic>{
      'id': id,
    };
    return SystemChannels.platform_views.invokeMethod('acceptGesture', args);
  }

  Future<void> rejectGesture() {
    final Map<String, dynamic> args = <String, dynamic>{
      'id': id,
    };
    return SystemChannels.platform_views.invokeMethod('rejectGesture', args);
  }

  Future<void> dispose() async {
    _debugDisposed = true;
    await SystemChannels.platform_views.invokeMethod<void>('dispose', id);
  }
}

abstract class PlatformViewController {
  int get viewId;

  void dispatchPointerEvent(PointerEvent event);

  void dispose();

  void clearFocus();
}

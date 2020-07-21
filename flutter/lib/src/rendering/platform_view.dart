import 'dart:async';

import 'package:flutter_web/ui.dart';

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/gestures.dart';
import 'package:flutter_web/semantics.dart';
import 'package:flutter_web/services.dart';

import 'box.dart';
import 'layer.dart';
import 'object.dart';

enum PlatformViewHitTestBehavior {
  opaque,

  translucent,

  transparent,
}

enum _PlatformViewState {
  uninitialized,
  resizing,
  ready,
}

bool _factoryTypesSetEquals<T>(Set<Factory<T>> a, Set<Factory<T>> b) {
  if (a == b) {
    return true;
  }
  if (a == null || b == null) {
    return false;
  }
  return setEquals(_factoriesTypeSet(a), _factoriesTypeSet(b));
}

Set<Type> _factoriesTypeSet<T>(Set<Factory<T>> factories) {
  return factories.map<Type>((Factory<T> factory) => factory.type).toSet();
}

class RenderAndroidView extends RenderBox with _PlatformViewGestureMixin {
  RenderAndroidView({
    @required AndroidViewController viewController,
    @required PlatformViewHitTestBehavior hitTestBehavior,
    @required Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers,
  })  : assert(viewController != null),
        assert(hitTestBehavior != null),
        assert(gestureRecognizers != null),
        _viewController = viewController {
    _motionEventsDispatcher =
        _MotionEventsDispatcher(globalToLocal, viewController);
    updateGestureRecognizers(gestureRecognizers);
    _viewController.addOnPlatformViewCreatedListener(_onPlatformViewCreated);
    this.hitTestBehavior = hitTestBehavior;
  }

  _PlatformViewState _state = _PlatformViewState.uninitialized;

  AndroidViewController get viewcontroller => _viewController;
  AndroidViewController _viewController;

  set viewController(AndroidViewController viewController) {
    assert(_viewController != null);
    assert(viewController != null);
    if (_viewController == viewController) return;
    _viewController.removeOnPlatformViewCreatedListener(_onPlatformViewCreated);
    _viewController = viewController;
    _sizePlatformView();
    if (_viewController.isCreated) {
      markNeedsSemanticsUpdate();
    }
    _viewController.addOnPlatformViewCreatedListener(_onPlatformViewCreated);
  }

  void _onPlatformViewCreated(int id) {
    markNeedsSemanticsUpdate();
  }

  void updateGestureRecognizers(
      Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers) {
    _updateGestureRecognizersWithCallBack(
        gestureRecognizers, _motionEventsDispatcher.handlePointerEvent);
  }

  @override
  bool get sizedByParent => true;

  @override
  bool get alwaysNeedsCompositing => true;

  @override
  bool get isRepaintBoundary => true;

  _MotionEventsDispatcher _motionEventsDispatcher;

  @override
  void performResize() {
    size = constraints.biggest;
    _sizePlatformView();
  }

  Size _currentAndroidViewSize;

  Future<void> _sizePlatformView() async {
    if (_state == _PlatformViewState.resizing || size.isEmpty) {
      return;
    }

    _state = _PlatformViewState.resizing;
    markNeedsPaint();

    Size targetSize;
    do {
      targetSize = size;
      await _viewController.setSize(targetSize);
      _currentAndroidViewSize = targetSize;
    } while (size != targetSize);

    _state = _PlatformViewState.ready;
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_viewController.textureId == null) return;

    if (size.width < _currentAndroidViewSize.width ||
        size.height < _currentAndroidViewSize.height) {
      context.pushClipRect(true, offset, offset & size, _paintTexture);
      return;
    }

    _paintTexture(context, offset);
  }

  void _paintTexture(PaintingContext context, Offset offset) {
    context.addLayer(TextureLayer(
      rect: offset & _currentAndroidViewSize,
      textureId: _viewController.textureId,
      freeze: _state == _PlatformViewState.resizing,
    ));
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);

    config.isSemanticBoundary = true;

    if (_viewController.isCreated) {
      config.platformViewId = _viewController.id;
    }
  }
}

class RenderUiKitView extends RenderBox {
  RenderUiKitView({
    @required UiKitViewController viewController,
    @required this.hitTestBehavior,
    @required Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers,
  })  : assert(viewController != null),
        assert(hitTestBehavior != null),
        assert(gestureRecognizers != null),
        _viewController = viewController {
    updateGestureRecognizers(gestureRecognizers);
  }

  UiKitViewController get viewController => _viewController;
  UiKitViewController _viewController;
  set viewController(UiKitViewController viewController) {
    assert(viewController != null);
    final bool needsSemanticsUpdate = _viewController.id != viewController.id;
    _viewController = viewController;
    markNeedsPaint();
    if (needsSemanticsUpdate) {
      markNeedsSemanticsUpdate();
    }
  }

  PlatformViewHitTestBehavior hitTestBehavior;

  void updateGestureRecognizers(
      Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers) {
    assert(gestureRecognizers != null);
    assert(
      _factoriesTypeSet(gestureRecognizers).length == gestureRecognizers.length,
      'There were multiple gesture recognizer factories for the same type, there must only be a single '
      'gesture recognizer factory for each gesture recognizer type.',
    );
    if (_factoryTypesSetEquals(
        gestureRecognizers, _gestureRecognizer?.gestureRecognizerFactories)) {
      return;
    }
    _gestureRecognizer?.dispose();
    _gestureRecognizer =
        _UiKitViewGestureRecognizer(viewController, gestureRecognizers);
  }

  @override
  bool get sizedByParent => true;

  @override
  bool get alwaysNeedsCompositing => true;

  @override
  bool get isRepaintBoundary => true;

  _UiKitViewGestureRecognizer _gestureRecognizer;

  PointerEvent _lastPointerDownEvent;

  @override
  void performResize() {
    size = constraints.biggest;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    context.addLayer(PlatformViewLayer(
      rect: offset & size,
      viewId: _viewController.id,
    ));
  }

  @override
  bool hitTest(BoxHitTestResult result, {Offset position}) {
    if (hitTestBehavior == PlatformViewHitTestBehavior.transparent ||
        !size.contains(position)) return false;
    result.add(BoxHitTestEntry(this, position));
    return hitTestBehavior == PlatformViewHitTestBehavior.opaque;
  }

  @override
  bool hitTestSelf(Offset position) =>
      hitTestBehavior != PlatformViewHitTestBehavior.transparent;

  @override
  void handleEvent(PointerEvent event, HitTestEntry entry) {
    if (event is! PointerDownEvent) {
      return;
    }
    _gestureRecognizer.addPointer(event);
    _lastPointerDownEvent = event.original ?? event;
  }

  void _handleGlobalPointerEvent(PointerEvent event) {
    if (event is! PointerDownEvent) {
      return;
    }
    if (!(Offset.zero & size).contains(event.localPosition)) {
      return;
    }
    if ((event.original ?? event) != _lastPointerDownEvent) {
      _viewController.rejectGesture();
    }
    _lastPointerDownEvent = null;
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config.isSemanticBoundary = true;
    config.platformViewId = _viewController.id;
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    GestureBinding.instance.pointerRouter
        .addGlobalRoute(_handleGlobalPointerEvent);
  }

  @override
  void detach() {
    GestureBinding.instance.pointerRouter
        .removeGlobalRoute(_handleGlobalPointerEvent);
    _gestureRecognizer.reset();
    super.detach();
  }
}

class _UiKitViewGestureRecognizer extends OneSequenceGestureRecognizer {
  _UiKitViewGestureRecognizer(
    this.controller,
    this.gestureRecognizerFactories, {
    PointerDeviceKind kind,
  }) : super(kind: kind) {
    team = GestureArenaTeam();
    team.captain = this;
    _gestureRecognizers = gestureRecognizerFactories.map(
      (Factory<OneSequenceGestureRecognizer> recognizerFactory) {
        return recognizerFactory.constructor()..team = team;
      },
    ).toSet();
  }

  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizerFactories;
  Set<OneSequenceGestureRecognizer> _gestureRecognizers;

  final UiKitViewController controller;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    startTrackingPointer(event.pointer, event.transform);
    for (OneSequenceGestureRecognizer recognizer in _gestureRecognizers) {
      recognizer.addPointer(event);
    }
  }

  @override
  String get debugDescription => 'UIKit view';

  @override
  void didStopTrackingLastPointer(int pointer) {}

  @override
  void handleEvent(PointerEvent event) {
    stopTrackingIfPointerNoLongerDown(event);
  }

  @override
  void acceptGesture(int pointer) {
    controller.acceptGesture();
  }

  @override
  void rejectGesture(int pointer) {
    controller.rejectGesture();
  }

  void reset() {
    resolve(GestureDisposition.rejected);
  }
}

typedef _HandlePointerEvent = void Function(PointerEvent event);

class _PlatformViewGestureRecognizer extends OneSequenceGestureRecognizer {
  _PlatformViewGestureRecognizer(
    _HandlePointerEvent handlePointerEvent,
    this.gestureRecognizerFactories, {
    PointerDeviceKind kind,
  }) : super(kind: kind) {
    team = GestureArenaTeam();
    team.captain = this;
    _gestureRecognizers = gestureRecognizerFactories.map(
      (Factory<OneSequenceGestureRecognizer> recognizerFactory) {
        return recognizerFactory.constructor()..team = team;
      },
    ).toSet();
    _handlePointerEvent = handlePointerEvent;
  }

  _HandlePointerEvent _handlePointerEvent;

  final Map<int, List<PointerEvent>> cachedEvents = <int, List<PointerEvent>>{};

  final Set<int> forwardedPointers = <int>{};

  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizerFactories;
  Set<OneSequenceGestureRecognizer> _gestureRecognizers;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    startTrackingPointer(event.pointer, event.transform);
    for (OneSequenceGestureRecognizer recognizer in _gestureRecognizers) {
      recognizer.addPointer(event);
    }
  }

  @override
  String get debugDescription => 'Platform view';

  @override
  void didStopTrackingLastPointer(int pointer) {}

  @override
  void handleEvent(PointerEvent event) {
    if (!forwardedPointers.contains(event.pointer)) {
      _cacheEvent(event);
    } else {
      _handlePointerEvent(event);
    }
    stopTrackingIfPointerNoLongerDown(event);
  }

  @override
  void acceptGesture(int pointer) {
    _flushPointerCache(pointer);
    forwardedPointers.add(pointer);
  }

  @override
  void rejectGesture(int pointer) {
    stopTrackingPointer(pointer);
    cachedEvents.remove(pointer);
  }

  void _cacheEvent(PointerEvent event) {
    if (!cachedEvents.containsKey(event.pointer)) {
      cachedEvents[event.pointer] = <PointerEvent>[];
    }
    cachedEvents[event.pointer].add(event);
  }

  void _flushPointerCache(int pointer) {
    cachedEvents.remove(pointer)?.forEach(_handlePointerEvent);
  }

  @override
  void stopTrackingPointer(int pointer) {
    super.stopTrackingPointer(pointer);
    forwardedPointers.remove(pointer);
  }

  void reset() {
    forwardedPointers.forEach(super.stopTrackingPointer);
    forwardedPointers.clear();
    cachedEvents.keys.forEach(super.stopTrackingPointer);
    cachedEvents.clear();
    resolve(GestureDisposition.rejected);
  }
}

typedef _GlobalToLocal = Offset Function(Offset point);

class _MotionEventsDispatcher {
  _MotionEventsDispatcher(this.globalToLocal, this.viewController);

  final Map<int, AndroidPointerCoords> pointerPositions =
      <int, AndroidPointerCoords>{};
  final Map<int, AndroidPointerProperties> pointerProperties =
      <int, AndroidPointerProperties>{};
  final _GlobalToLocal globalToLocal;
  final AndroidViewController viewController;

  int nextPointerId = 0;
  int downTimeMillis;

  void handlePointerEvent(PointerEvent event) {
    if (event is PointerDownEvent) {
      if (nextPointerId == 0) downTimeMillis = event.timeStamp.inMilliseconds;
      pointerProperties[event.pointer] = propertiesFor(event, nextPointerId++);
    }
    pointerPositions[event.pointer] = coordsFor(event);

    dispatchPointerEvent(event);

    if (event is PointerUpEvent) {
      pointerPositions.remove(event.pointer);
      pointerProperties.remove(event.pointer);
      if (pointerProperties.isEmpty) {
        nextPointerId = 0;
        downTimeMillis = null;
      }
    }
    if (event is PointerCancelEvent) {
      pointerPositions.clear();
      pointerProperties.clear();
      nextPointerId = 0;
      downTimeMillis = null;
    }
  }

  void dispatchPointerEvent(PointerEvent event) {
    final List<int> pointers = pointerPositions.keys.toList();
    final int pointerIdx = pointers.indexOf(event.pointer);
    final int numPointers = pointers.length;

    const int kPointerDataFlagBatched = 1;

    if (event.platformData == kPointerDataFlagBatched ||
        (isSinglePointerAction(event) && pointerIdx < numPointers - 1)) return;

    int action;
    switch (event.runtimeType) {
      case PointerDownEvent:
        action = numPointers == 1
            ? AndroidViewController.kActionDown
            : AndroidViewController.pointerAction(
                pointerIdx, AndroidViewController.kActionPointerDown);
        break;
      case PointerUpEvent:
        action = numPointers == 1
            ? AndroidViewController.kActionUp
            : AndroidViewController.pointerAction(
                pointerIdx, AndroidViewController.kActionPointerUp);
        break;
      case PointerMoveEvent:
        action = AndroidViewController.kActionMove;
        break;
      case PointerCancelEvent:
        action = AndroidViewController.kActionCancel;
        break;
      default:
        return;
    }

    final AndroidMotionEvent androidMotionEvent = AndroidMotionEvent(
      downTime: downTimeMillis,
      eventTime: event.timeStamp.inMilliseconds,
      action: action,
      pointerCount: pointerPositions.length,
      pointerProperties: pointers
          .map<AndroidPointerProperties>((int i) => pointerProperties[i])
          .toList(),
      pointerCoords: pointers
          .map<AndroidPointerCoords>((int i) => pointerPositions[i])
          .toList(),
      metaState: 0,
      buttonState: 0,
      xPrecision: 1.0,
      yPrecision: 1.0,
      deviceId: 0,
      edgeFlags: 0,
      source: 0,
      flags: 0,
    );
    viewController.sendMotionEvent(androidMotionEvent);
  }

  AndroidPointerCoords coordsFor(PointerEvent event) {
    final Offset position = globalToLocal(event.position);
    return AndroidPointerCoords(
      orientation: event.orientation,
      pressure: event.pressure,
      size: event.size,
      toolMajor: event.radiusMajor,
      toolMinor: event.radiusMinor,
      touchMajor: event.radiusMajor,
      touchMinor: event.radiusMinor,
      x: position.dx,
      y: position.dy,
    );
  }

  AndroidPointerProperties propertiesFor(PointerEvent event, int pointerId) {
    int toolType = AndroidPointerProperties.kToolTypeUnknown;
    switch (event.kind) {
      case PointerDeviceKind.touch:
        toolType = AndroidPointerProperties.kToolTypeFinger;
        break;
      case PointerDeviceKind.mouse:
        toolType = AndroidPointerProperties.kToolTypeMouse;
        break;
      case PointerDeviceKind.stylus:
        toolType = AndroidPointerProperties.kToolTypeStylus;
        break;
      case PointerDeviceKind.invertedStylus:
        toolType = AndroidPointerProperties.kToolTypeEraser;
        break;
      case PointerDeviceKind.unknown:
        toolType = AndroidPointerProperties.kToolTypeUnknown;
        break;
    }
    return AndroidPointerProperties(id: pointerId, toolType: toolType);
  }

  bool isSinglePointerAction(PointerEvent event) =>
      !(event is PointerDownEvent) && !(event is PointerUpEvent);
}

class PlatformViewRenderBox extends RenderBox with _PlatformViewGestureMixin {
  PlatformViewRenderBox({
    @required PlatformViewController controller,
    @required PlatformViewHitTestBehavior hitTestBehavior,
    @required Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers,
  })  : assert(controller != null &&
            controller.viewId != null &&
            controller.viewId > -1),
        assert(hitTestBehavior != null),
        assert(gestureRecognizers != null),
        _controller = controller {
    this.hitTestBehavior = hitTestBehavior;
    updateGestureRecognizers(gestureRecognizers);
  }

  set controller(PlatformViewController controller) {
    assert(controller != null);
    assert(controller.viewId != null && controller.viewId > -1);

    if (_controller == controller) {
      return;
    }
    final bool needsSemanticsUpdate = _controller.viewId != controller.viewId;
    _controller = controller;
    markNeedsPaint();
    if (needsSemanticsUpdate) {
      markNeedsSemanticsUpdate();
    }
  }

  void updateGestureRecognizers(
      Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers) {
    _updateGestureRecognizersWithCallBack(
        gestureRecognizers, _controller.dispatchPointerEvent);
  }

  PlatformViewController _controller;

  @override
  bool get sizedByParent => true;

  @override
  bool get alwaysNeedsCompositing => true;

  @override
  bool get isRepaintBoundary => true;

  @override
  void performResize() {
    size = constraints.biggest;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    assert(_controller.viewId != null);
    context.addLayer(
        PlatformViewLayer(rect: offset & size, viewId: _controller.viewId));
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    assert(_controller.viewId != null);
    config.isSemanticBoundary = true;
    config.platformViewId = _controller.viewId;
  }
}

mixin _PlatformViewGestureMixin on RenderBox {
  PlatformViewHitTestBehavior hitTestBehavior;

  void _updateGestureRecognizersWithCallBack(
      Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers,
      _HandlePointerEvent _handlePointerEvent) {
    assert(gestureRecognizers != null);
    assert(
      _factoriesTypeSet(gestureRecognizers).length == gestureRecognizers.length,
      'There were multiple gesture recognizer factories for the same type, there must only be a single '
      'gesture recognizer factory for each gesture recognizer type.',
    );
    if (_factoryTypesSetEquals(
        gestureRecognizers, _gestureRecognizer?.gestureRecognizerFactories)) {
      return;
    }
    _gestureRecognizer?.dispose();
    _gestureRecognizer =
        _PlatformViewGestureRecognizer(_handlePointerEvent, gestureRecognizers);
  }

  _PlatformViewGestureRecognizer _gestureRecognizer;

  @override
  bool hitTest(BoxHitTestResult result, {Offset position}) {
    if (hitTestBehavior == PlatformViewHitTestBehavior.transparent ||
        !size.contains(position)) {
      return false;
    }
    result.add(BoxHitTestEntry(this, position));
    return hitTestBehavior == PlatformViewHitTestBehavior.opaque;
  }

  @override
  bool hitTestSelf(Offset position) =>
      hitTestBehavior != PlatformViewHitTestBehavior.transparent;

  @override
  void handleEvent(PointerEvent event, HitTestEntry entry) {
    if (event is PointerDownEvent) {
      _gestureRecognizer.addPointer(event);
    }
  }

  @override
  void detach() {
    _gestureRecognizer.reset();
    super.detach();
  }
}

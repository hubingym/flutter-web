import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter_web/ui.dart'
    show AppLifecycleState, Locale, AccessibilityFeatures, webOnlyIsInitialized;

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/gestures.dart';
import 'package:flutter_web/rendering.dart';
import 'package:flutter_web/scheduler.dart';
import 'package:flutter_web/services.dart';

import 'app.dart';
import 'debug.dart';
import 'focus_manager.dart';
import 'framework.dart';
import 'widget_inspector.dart';

export 'package:flutter_web/ui.dart' show AppLifecycleState, Locale;

abstract class WidgetsBindingObserver {
  Future<bool> didPopRoute() => Future<bool>.value(false);

  Future<bool> didPushRoute(String route) => Future<bool>.value(false);

  void didChangeMetrics() {}

  void didChangeTextScaleFactor() {}

  void didChangePlatformBrightness() {}

  void didChangeLocales(List<Locale> locale) {}

  void didChangeAppLifecycleState(AppLifecycleState state) {}

  void didHaveMemoryPressure() {}

  void didChangeAccessibilityFeatures() {}
}

mixin WidgetsBinding
    on
        BindingBase,
        SchedulerBinding,
        GestureBinding,
        RendererBinding,
        SemanticsBinding {
  @override
  void initInstances() {
    super.initInstances();
    _instance = this;
    buildOwner.onBuildScheduled = _handleBuildScheduled;
    window.onLocaleChanged = handleLocaleChanged;
    window.onAccessibilityFeaturesChanged = handleAccessibilityFeaturesChanged;
    SystemChannels.navigation.setMethodCallHandler(_handleNavigationInvocation);
    SystemChannels.system.setMessageHandler(_handleSystemMessage);
  }

  static WidgetsBinding get instance => _instance;
  static WidgetsBinding _instance;

  @override
  void initServiceExtensions() {
    super.initServiceExtensions();

    profile(() {
      registerSignalServiceExtension(
        name: 'debugDumpApp',
        callback: () {
          debugDumpApp();
          return debugPrintDone;
        },
      );

      registerBoolServiceExtension(
        name: 'showPerformanceOverlay',
        getter: () =>
            Future<bool>.value(WidgetsApp.showPerformanceOverlayOverride),
        setter: (bool value) {
          if (WidgetsApp.showPerformanceOverlayOverride == value)
            return Future<void>.value();
          WidgetsApp.showPerformanceOverlayOverride = value;
          return _forceRebuild();
        },
      );

      registerServiceExtension(
        name: 'didSendFirstFrameEvent',
        callback: (_) async {
          return <String, dynamic>{
            'enabled': _needToReportFirstFrame ? 'false' : 'true',
          };
        },
      );
    });

    assert(() {
      registerBoolServiceExtension(
        name: 'debugAllowBanner',
        getter: () => Future<bool>.value(WidgetsApp.debugAllowBannerOverride),
        setter: (bool value) {
          if (WidgetsApp.debugAllowBannerOverride == value)
            return Future<void>.value();
          WidgetsApp.debugAllowBannerOverride = value;
          return _forceRebuild();
        },
      );

      registerBoolServiceExtension(
        name: 'profileWidgetBuilds',
        getter: () async => debugProfileBuildsEnabled,
        setter: (bool value) async {
          if (debugProfileBuildsEnabled != value)
            debugProfileBuildsEnabled = value;
        },
      );

      registerBoolServiceExtension(
        name: 'debugWidgetInspector',
        getter: () async => WidgetsApp.debugShowWidgetInspectorOverride,
        setter: (bool value) {
          if (WidgetsApp.debugShowWidgetInspectorOverride == value)
            return Future<void>.value();
          WidgetsApp.debugShowWidgetInspectorOverride = value;
          return _forceRebuild();
        },
      );

      WidgetInspectorService.instance
          .initServiceExtensions(registerServiceExtension);

      return true;
    }());
  }

  Future<void> _forceRebuild() {
    if (renderViewElement != null) {
      buildOwner.reassemble(renderViewElement);
      return endOfFrame;
    }
    return Future<void>.value();
  }

  BuildOwner get buildOwner => _buildOwner;
  final BuildOwner _buildOwner = BuildOwner();

  FocusManager get focusManager => _buildOwner.focusManager;

  final List<WidgetsBindingObserver> _observers = <WidgetsBindingObserver>[];

  void addObserver(WidgetsBindingObserver observer) => _observers.add(observer);

  bool removeObserver(WidgetsBindingObserver observer) =>
      _observers.remove(observer);

  @override
  void handleMetricsChanged() {
    super.handleMetricsChanged();
    for (WidgetsBindingObserver observer in _observers)
      observer.didChangeMetrics();
  }

  @override
  void handleTextScaleFactorChanged() {
    super.handleTextScaleFactorChanged();
    for (WidgetsBindingObserver observer in _observers)
      observer.didChangeTextScaleFactor();
  }

  @override
  void handlePlatformBrightnessChanged() {
    super.handlePlatformBrightnessChanged();
    for (WidgetsBindingObserver observer in _observers)
      observer.didChangePlatformBrightness();
  }

  @override
  void handleAccessibilityFeaturesChanged() {
    super.handleAccessibilityFeaturesChanged();
    for (WidgetsBindingObserver observer in _observers)
      observer.didChangeAccessibilityFeatures();
  }

  @protected
  @mustCallSuper
  void handleLocaleChanged() {
    dispatchLocalesChanged(window.locales);
  }

  @protected
  @mustCallSuper
  void dispatchLocalesChanged(List<Locale> locales) {
    for (WidgetsBindingObserver observer in _observers)
      observer.didChangeLocales(locales);
  }

  @protected
  @mustCallSuper
  void dispatchAccessibilityFeaturesChanged() {
    for (WidgetsBindingObserver observer in _observers)
      observer.didChangeAccessibilityFeatures();
  }

  @protected
  Future<void> handlePopRoute() async {
    for (WidgetsBindingObserver observer
        in List<WidgetsBindingObserver>.from(_observers)) {
      if (await observer.didPopRoute()) return;
    }
    SystemNavigator.pop();
  }

  @protected
  @mustCallSuper
  Future<void> handlePushRoute(String route) async {
    for (WidgetsBindingObserver observer
        in List<WidgetsBindingObserver>.from(_observers)) {
      if (await observer.didPushRoute(route)) return;
    }
  }

  Future<dynamic> _handleNavigationInvocation(MethodCall methodCall) {
    switch (methodCall.method) {
      case 'popRoute':
        return handlePopRoute();
      case 'pushRoute':
        return handlePushRoute(methodCall.arguments);
    }
    return Future<dynamic>.value();
  }

  @override
  void handleAppLifecycleStateChanged(AppLifecycleState state) {
    super.handleAppLifecycleStateChanged(state);
    for (WidgetsBindingObserver observer in _observers)
      observer.didChangeAppLifecycleState(state);
  }

  void handleMemoryPressure() {
    for (WidgetsBindingObserver observer in _observers)
      observer.didHaveMemoryPressure();
  }

  Future<void> _handleSystemMessage(Object systemMessage) async {
    final Map<String, dynamic> message = systemMessage;
    final String type = message['type'];
    switch (type) {
      case 'memoryPressure':
        handleMemoryPressure();
        break;
    }
    return;
  }

  bool _needToReportFirstFrame = true;
  int _deferFirstFrameReportCount = 0;
  bool get _reportFirstFrame => _deferFirstFrameReportCount == 0;

  bool get debugDidSendFirstFrameEvent => !_needToReportFirstFrame;

  void deferFirstFrameReport() {
    profile(() {
      assert(_deferFirstFrameReportCount >= 0);
      _deferFirstFrameReportCount += 1;
    });
  }

  void allowFirstFrameReport() {
    profile(() {
      assert(_deferFirstFrameReportCount >= 1);
      _deferFirstFrameReportCount -= 1;
    });
  }

  void _handleBuildScheduled() {
    assert(() {
      if (debugBuildingDirtyElements) {
        throw FlutterError('Build scheduled during frame.\n'
            'While the widget tree was being built, laid out, and painted, '
            'a new frame was scheduled to rebuild the widget tree. '
            'This might be because setState() was called from a layout or '
            'paint callback. '
            'If a change is needed to the widget tree, it should be applied '
            'as the tree is being built. Scheduling a change for the subsequent '
            'frame instead results in an interface that lags behind by one frame. '
            'If this was done to make your build dependent on a size measured at '
            'layout time, consider using a LayoutBuilder, CustomSingleChildLayout, '
            'or CustomMultiChildLayout. If, on the other hand, the one frame delay '
            'is the desired effect, for example because this is an '
            'animation, consider scheduling the frame in a post-frame callback '
            'using SchedulerBinding.addPostFrameCallback or '
            'using an AnimationController to trigger the animation.');
      }
      return true;
    }());
    ensureVisualUpdate();
  }

  @protected
  bool debugBuildingDirtyElements = false;

  @override
  void drawFrame() {
    assert(!debugBuildingDirtyElements);
    assert(() {
      debugBuildingDirtyElements = true;
      return true;
    }());
    try {
      if (renderViewElement != null) buildOwner.buildScope(renderViewElement);
      super.drawFrame();
      buildOwner.finalizeTree();
    } finally {
      assert(() {
        debugBuildingDirtyElements = false;
        return true;
      }());
    }
    profile(() {
      if (_needToReportFirstFrame && _reportFirstFrame) {
        developer.Timeline.instantSync('Widgets completed first useful frame');
        developer.postEvent('Flutter.FirstFrame', <String, dynamic>{});
        _needToReportFirstFrame = false;
      }
    });
  }

  Element get renderViewElement => _renderViewElement;
  Element _renderViewElement;

  void attachRootWidget(Widget rootWidget) {
    _renderViewElement = RenderObjectToWidgetAdapter<RenderBox>(
      container: renderView,
      debugShortDescription: '[root]',
      child: rootWidget,
    ).attachToRenderTree(buildOwner, renderViewElement);
  }

  bool get isRootWidgetAttached => _renderViewElement != null;

  @override
  Future<void> performReassemble() {
    assert(() {
      WidgetInspectorService.instance.performReassemble();
      return true;
    }());

    deferFirstFrameReport();
    if (renderViewElement != null) buildOwner.reassemble(renderViewElement);
    return super.performReassemble().then((void value) {
      allowFirstFrameReport();
    });
  }
}

void runApp(Widget app) {
  assert(
      webOnlyIsInitialized,
      'The platform has not been initialized. '
      'It is required to call `ui.webOnlyInitializePlatform()` before `runApp`.');
  WidgetsFlutterBinding.ensureInitialized()
    ..attachRootWidget(app)
    ..scheduleWarmUpFrame();
}

void debugDumpApp() {
  assert(WidgetsBinding.instance != null);
  String mode = 'RELEASE MODE';
  assert(() {
    mode = 'CHECKED MODE';
    return true;
  }());
  debugPrint('${WidgetsBinding.instance.runtimeType} - $mode');
  if (WidgetsBinding.instance.renderViewElement != null) {
    debugPrint(WidgetsBinding.instance.renderViewElement.toStringDeep());
  } else {
    debugPrint('<no tree currently mounted>');
  }
}

class RenderObjectToWidgetAdapter<T extends RenderObject>
    extends RenderObjectWidget {
  RenderObjectToWidgetAdapter({
    this.child,
    this.container,
    this.debugShortDescription,
  }) : super(key: GlobalObjectKey(container));

  final Widget child;

  final RenderObjectWithChildMixin<T> container;

  final String debugShortDescription;

  @override
  RenderObjectToWidgetElement<T> createElement() =>
      RenderObjectToWidgetElement<T>(this);

  @override
  RenderObjectWithChildMixin<T> createRenderObject(BuildContext context) =>
      container;

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {}

  RenderObjectToWidgetElement<T> attachToRenderTree(BuildOwner owner,
      [RenderObjectToWidgetElement<T> element]) {
    if (element == null) {
      owner.lockState(() {
        element = createElement();
        assert(element != null);
        element.assignOwner(owner);
      });
      owner.buildScope(element, () {
        element.mount(null, null);
      });
    } else {
      element._newWidget = this;
      element.markNeedsBuild();
    }
    return element;
  }

  @override
  String toStringShort() => debugShortDescription ?? super.toStringShort();
}

class RenderObjectToWidgetElement<T extends RenderObject>
    extends RootRenderObjectElement {
  RenderObjectToWidgetElement(RenderObjectToWidgetAdapter<T> widget)
      : super(widget);

  @override
  RenderObjectToWidgetAdapter<T> get widget => super.widget;

  Element _child;

  static const Object _rootChildSlot = Object();

  @override
  void visitChildren(ElementVisitor visitor) {
    if (_child != null) visitor(_child);
  }

  @override
  void forgetChild(Element child) {
    assert(child == _child);
    _child = null;
  }

  @override
  void mount(Element parent, dynamic newSlot) {
    assert(parent == null);
    super.mount(parent, newSlot);
    _rebuild();
  }

  @override
  void update(RenderObjectToWidgetAdapter<T> newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    _rebuild();
  }

  Widget _newWidget;

  @override
  void performRebuild() {
    if (_newWidget != null) {
      final Widget newWidget = _newWidget;
      _newWidget = null;
      update(newWidget);
    }
    super.performRebuild();
    assert(_newWidget == null);
  }

  void _rebuild() {
    try {
      _child = updateChild(_child, widget.child, _rootChildSlot);
      assert(_child != null);
    } catch (exception, stack) {
      final FlutterErrorDetails details = FlutterErrorDetails(
        exception: exception,
        stack: stack,
        library: 'widgets library',
        context: ErrorDescription('attaching to the render tree'),
      );
      FlutterError.reportError(details);
      final Widget error = ErrorWidget.builder(details);
      _child = updateChild(null, error, _rootChildSlot);
    }
  }

  @override
  RenderObjectWithChildMixin<T> get renderObject => super.renderObject;

  @override
  void insertChildRenderObject(RenderObject child, dynamic slot) {
    assert(slot == _rootChildSlot);
    assert(renderObject.debugValidateChild(child));
    renderObject.child = child;
  }

  @override
  void moveChildRenderObject(RenderObject child, dynamic slot) {
    assert(false);
  }

  @override
  void removeChildRenderObject(RenderObject child) {
    assert(renderObject.child == child);
    renderObject.child = null;
  }
}

class WidgetsFlutterBinding extends BindingBase
    with
        GestureBinding,
        ServicesBinding,
        SchedulerBinding,
        PaintingBinding,
        SemanticsBinding,
        RendererBinding,
        WidgetsBinding {
  static WidgetsBinding ensureInitialized() {
    if (WidgetsBinding.instance == null) WidgetsFlutterBinding();
    return WidgetsBinding.instance;
  }
}

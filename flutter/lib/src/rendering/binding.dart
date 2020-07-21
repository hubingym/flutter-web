import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/gestures.dart';
import 'package:flutter_web/scheduler.dart';
import 'package:flutter_web/semantics.dart';
import 'package:flutter_web/services.dart';

import 'box.dart';
import 'debug.dart';
import 'object.dart';
import 'view.dart';

export 'package:flutter_web/gestures.dart' show HitTestResult;

mixin RendererBinding
    on
        BindingBase,
        ServicesBinding,
        SchedulerBinding,
        GestureBinding,
        SemanticsBinding,
        HitTestable {
  @override
  void initInstances() {
    super.initInstances();
    _instance = this;
    _pipelineOwner = PipelineOwner(
      onNeedVisualUpdate: ensureVisualUpdate,
      onSemanticsOwnerCreated: _handleSemanticsOwnerCreated,
      onSemanticsOwnerDisposed: _handleSemanticsOwnerDisposed,
    );
    window
      ..onMetricsChanged = handleMetricsChanged
      ..onTextScaleFactorChanged = handleTextScaleFactorChanged
      ..onPlatformBrightnessChanged = handlePlatformBrightnessChanged
      ..onSemanticsEnabledChanged = _handleSemanticsEnabledChanged
      ..onSemanticsAction = _handleSemanticsAction;
    initRenderView();
    _handleSemanticsEnabledChanged();
    assert(renderView != null);
    addPersistentFrameCallback(_handlePersistentFrameCallback);
    _mouseTracker = _createMouseTracker();
  }

  static RendererBinding get instance => _instance;
  static RendererBinding _instance;

  @override
  void initServiceExtensions() {
    super.initServiceExtensions();

    assert(() {
      registerBoolServiceExtension(
        name: 'debugPaint',
        getter: () async => debugPaintSizeEnabled,
        setter: (bool value) {
          if (debugPaintSizeEnabled == value) return Future<void>.value();
          debugPaintSizeEnabled = value;
          return _forceRepaint();
        },
      );
      registerBoolServiceExtension(
        name: 'debugPaintBaselinesEnabled',
        getter: () async => debugPaintBaselinesEnabled,
        setter: (bool value) {
          if (debugPaintBaselinesEnabled == value) return Future<void>.value();
          debugPaintBaselinesEnabled = value;
          return _forceRepaint();
        },
      );

      registerBoolServiceExtension(
        name: 'repaintRainbow',
        getter: () async => debugRepaintRainbowEnabled,
        setter: (bool value) {
          final bool repaint = debugRepaintRainbowEnabled && !value;
          debugRepaintRainbowEnabled = value;
          if (repaint) return _forceRepaint();
          return Future<void>.value();
        },
      );

      registerSignalServiceExtension(
        name: 'debugDumpLayerTree',
        callback: () {
          debugDumpLayerTree();
          return debugPrintDone;
        },
      );
      return true;
    }());

    if (!kReleaseMode) {
      registerSignalServiceExtension(
        name: 'debugDumpRenderTree',
        callback: () {
          debugDumpRenderTree();
          return debugPrintDone;
        },
      );

      registerSignalServiceExtension(
        name: 'debugDumpSemanticsTreeInTraversalOrder',
        callback: () {
          debugDumpSemanticsTree(DebugSemanticsDumpOrder.traversalOrder);
          return debugPrintDone;
        },
      );

      registerSignalServiceExtension(
        name: 'debugDumpSemanticsTreeInInverseHitTestOrder',
        callback: () {
          debugDumpSemanticsTree(DebugSemanticsDumpOrder.inverseHitTest);
          return debugPrintDone;
        },
      );
    }
  }

  void initRenderView() {
    assert(renderView == null);
    renderView =
        RenderView(configuration: createViewConfiguration(), window: window);
    renderView.scheduleInitialFrame();
  }

  MouseTracker get mouseTracker => _mouseTracker;
  MouseTracker _mouseTracker;

  PipelineOwner get pipelineOwner => _pipelineOwner;
  PipelineOwner _pipelineOwner;

  RenderView get renderView => _pipelineOwner.rootNode;

  set renderView(RenderView value) {
    assert(value != null);
    _pipelineOwner.rootNode = value;
  }

  @protected
  void handleMetricsChanged() {
    assert(renderView != null);
    renderView.configuration = createViewConfiguration();
    scheduleForcedFrame();
  }

  @protected
  void handleTextScaleFactorChanged() {}

  @protected
  void handlePlatformBrightnessChanged() {}

  ViewConfiguration createViewConfiguration() {
    final double devicePixelRatio = window.devicePixelRatio;
    return ViewConfiguration(
      size: window.physicalSize / devicePixelRatio,
      devicePixelRatio: devicePixelRatio,
    );
  }

  SemanticsHandle _semanticsHandle;

  MouseTracker _createMouseTracker() {
    return MouseTracker(pointerRouter, (Offset offset) {
      return renderView.layer
          .findAll<MouseTrackerAnnotation>(offset * window.devicePixelRatio);
    });
  }

  void _handleSemanticsEnabledChanged() {
    setSemanticsEnabled(window.semanticsEnabled);
  }

  void setSemanticsEnabled(bool enabled) {
    if (enabled) {
      _semanticsHandle ??= _pipelineOwner.ensureSemantics();
    } else {
      _semanticsHandle?.dispose();
      _semanticsHandle = null;
    }
  }

  void _handleSemanticsAction(int id, SemanticsAction action, ByteData args) {
    _pipelineOwner.semanticsOwner?.performAction(
      id,
      action,
      args != null ? const StandardMessageCodec().decodeMessage(args) : null,
    );
  }

  void _handleSemanticsOwnerCreated() {
    renderView.scheduleInitialSemantics();
  }

  void _handleSemanticsOwnerDisposed() {
    renderView.clearSemantics();
  }

  void _handlePersistentFrameCallback(Duration timeStamp) {
    drawFrame();
  }

  @protected
  void drawFrame() {
    assert(renderView != null);
    pipelineOwner.flushLayout();
    pipelineOwner.flushCompositingBits();
    pipelineOwner.flushPaint();
    renderView.compositeFrame();
    pipelineOwner.flushSemantics();
  }

  @override
  Future<void> performReassemble() async {
    await super.performReassemble();
    Timeline.startSync('Dirty Render Tree',
        arguments: timelineWhitelistArguments);
    try {
      renderView.reassemble();
    } finally {
      Timeline.finishSync();
    }
    scheduleWarmUpFrame();
    await endOfFrame;
  }

  @override
  void hitTest(HitTestResult result, Offset position) {
    assert(renderView != null);
    renderView.hitTest(result, position: position);
    super.hitTest(result, position);
  }

  Future<void> _forceRepaint() {
    RenderObjectVisitor visitor;
    visitor = (RenderObject child) {
      child.markNeedsPaint();
      child.visitChildren(visitor);
    };
    instance?.renderView?.visitChildren(visitor);
    return endOfFrame;
  }
}

void debugDumpRenderTree() {
  debugPrint(RendererBinding.instance?.renderView?.toStringDeep() ??
      'Render tree unavailable.');
}

void debugDumpLayerTree() {
  debugPrint(RendererBinding.instance?.renderView?.debugLayer?.toStringDeep() ??
      'Layer tree unavailable.');
}

void debugDumpSemanticsTree(DebugSemanticsDumpOrder childOrder) {
  debugPrint(RendererBinding.instance?.renderView?.debugSemantics
          ?.toStringDeep(childOrder: childOrder) ??
      'Semantics not collected.');
}

class RenderingFlutterBinding extends BindingBase
    with
        GestureBinding,
        ServicesBinding,
        SchedulerBinding,
        SemanticsBinding,
        RendererBinding {
  RenderingFlutterBinding({RenderBox root}) {
    assert(renderView != null);
    renderView.child = root;
  }
}

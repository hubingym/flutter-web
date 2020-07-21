import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter_web/ui.dart' as ui
    show
        ClipOp,
        Image,
        ImageByteFormat,
        Paragraph,
        Picture,
        PictureRecorder,
        PointMode,
        SceneBuilder,
        Vertices;
import 'package:flutter_web/ui.dart' show Canvas, Offset;

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/painting.dart';
import 'package:flutter_web/rendering.dart';
import 'package:flutter_web/scheduler.dart';
import 'package:vector_math/vector_math_64.dart';

import 'app.dart';
import 'basic.dart';
import 'binding.dart';
import 'debug.dart';
import 'framework.dart';
import 'gesture_detector.dart';

typedef InspectorSelectButtonBuilder = Widget Function(
    BuildContext context, VoidCallback onPressed);

typedef _RegisterServiceExtensionCallback = void Function({
  @required String name,
  @required ServiceExtensionCallback callback,
});

class _ProxyLayer extends Layer {
  _ProxyLayer(this._layer);

  final Layer _layer;

  @override
  void addToScene(ui.SceneBuilder builder, [Offset layerOffset = Offset.zero]) {
    _layer.addToScene(builder, layerOffset);
  }

  @override
  S find<S>(Offset regionOffset) => _layer.find(regionOffset);

  @override
  Iterable<S> findAll<S>(Offset regionOffset) => <S>[];
}

class _MulticastCanvas implements Canvas {
  _MulticastCanvas({
    @required Canvas main,
    @required Canvas screenshot,
  })  : assert(main != null),
        assert(screenshot != null),
        _main = main,
        _screenshot = screenshot;

  final Canvas _main;
  final Canvas _screenshot;

  @override
  void clipPath(Path path, {bool doAntiAlias = true}) {
    _main.clipPath(path, doAntiAlias: doAntiAlias);
    _screenshot.clipPath(path, doAntiAlias: doAntiAlias);
  }

  @override
  void clipRRect(RRect rrect, {bool doAntiAlias = true}) {
    _main.clipRRect(rrect, doAntiAlias: doAntiAlias);
    _screenshot.clipRRect(rrect, doAntiAlias: doAntiAlias);
  }

  @override
  void clipRect(Rect rect,
      {ui.ClipOp clipOp = ui.ClipOp.intersect, bool doAntiAlias = true}) {
    _main.clipRect(rect, clipOp: clipOp, doAntiAlias: doAntiAlias);
    _screenshot.clipRect(rect, clipOp: clipOp, doAntiAlias: doAntiAlias);
  }

  @override
  void drawArc(Rect rect, double startAngle, double sweepAngle, bool useCenter,
      Paint paint) {
    _main.drawArc(rect, startAngle, sweepAngle, useCenter, paint);
    _screenshot.drawArc(rect, startAngle, sweepAngle, useCenter, paint);
  }

  @override
  void drawAtlas(ui.Image atlas, List<RSTransform> transforms, List<Rect> rects,
      List<Color> colors, BlendMode blendMode, Rect cullRect, Paint paint) {
    _main.drawAtlas(
        atlas, transforms, rects, colors, blendMode, cullRect, paint);
    _screenshot.drawAtlas(
        atlas, transforms, rects, colors, blendMode, cullRect, paint);
  }

  @override
  void drawCircle(Offset c, double radius, Paint paint) {
    _main.drawCircle(c, radius, paint);
    _screenshot.drawCircle(c, radius, paint);
  }

  @override
  void drawColor(Color color, BlendMode blendMode) {
    _main.drawColor(color, blendMode);
    _screenshot.drawColor(color, blendMode);
  }

  @override
  void drawDRRect(RRect outer, RRect inner, Paint paint) {
    _main.drawDRRect(outer, inner, paint);
    _screenshot.drawDRRect(outer, inner, paint);
  }

  @override
  void drawImage(ui.Image image, Offset p, Paint paint) {
    _main.drawImage(image, p, paint);
    _screenshot.drawImage(image, p, paint);
  }

  @override
  void drawImageNine(ui.Image image, Rect center, Rect dst, Paint paint) {
    _main.drawImageNine(image, center, dst, paint);
    _screenshot.drawImageNine(image, center, dst, paint);
  }

  @override
  void drawImageRect(ui.Image image, Rect src, Rect dst, Paint paint) {
    _main.drawImageRect(image, src, dst, paint);
    _screenshot.drawImageRect(image, src, dst, paint);
  }

  @override
  void drawLine(Offset p1, Offset p2, Paint paint) {
    _main.drawLine(p1, p2, paint);
    _screenshot.drawLine(p1, p2, paint);
  }

  @override
  void drawOval(Rect rect, Paint paint) {
    _main.drawOval(rect, paint);
    _screenshot.drawOval(rect, paint);
  }

  @override
  void drawPaint(Paint paint) {
    _main.drawPaint(paint);
    _screenshot.drawPaint(paint);
  }

  @override
  void drawParagraph(ui.Paragraph paragraph, Offset offset) {
    _main.drawParagraph(paragraph, offset);
    _screenshot.drawParagraph(paragraph, offset);
  }

  @override
  void drawPath(Path path, Paint paint) {
    _main.drawPath(path, paint);
    _screenshot.drawPath(path, paint);
  }

  @override
  void drawPicture(ui.Picture picture) {
    _main.drawPicture(picture);
    _screenshot.drawPicture(picture);
  }

  @override
  void drawPoints(ui.PointMode pointMode, List<Offset> points, Paint paint) {
    _main.drawPoints(pointMode, points, paint);
    _screenshot.drawPoints(pointMode, points, paint);
  }

  @override
  void drawRRect(RRect rrect, Paint paint) {
    _main.drawRRect(rrect, paint);
    _screenshot.drawRRect(rrect, paint);
  }

  @override
  void drawRawAtlas(
      ui.Image atlas,
      Float32List rstTransforms,
      Float32List rects,
      Int32List colors,
      BlendMode blendMode,
      Rect cullRect,
      Paint paint) {
    _main.drawRawAtlas(
        atlas, rstTransforms, rects, colors, blendMode, cullRect, paint);
    _screenshot.drawRawAtlas(
        atlas, rstTransforms, rects, colors, blendMode, cullRect, paint);
  }

  @override
  void drawRawPoints(ui.PointMode pointMode, Float32List points, Paint paint) {
    _main.drawRawPoints(pointMode, points, paint);
    _screenshot.drawRawPoints(pointMode, points, paint);
  }

  @override
  void drawRect(Rect rect, Paint paint) {
    _main.drawRect(rect, paint);
    _screenshot.drawRect(rect, paint);
  }

  @override
  void drawShadow(
      Path path, Color color, double elevation, bool transparentOccluder) {
    _main.drawShadow(path, color, elevation, transparentOccluder);
    _screenshot.drawShadow(path, color, elevation, transparentOccluder);
  }

  @override
  void drawVertices(ui.Vertices vertices, BlendMode blendMode, Paint paint) {
    _main.drawVertices(vertices, blendMode, paint);
    _screenshot.drawVertices(vertices, blendMode, paint);
  }

  @override
  int getSaveCount() {
    return _main.getSaveCount();
  }

  @override
  void restore() {
    _main.restore();
    _screenshot.restore();
  }

  @override
  void rotate(double radians) {
    _main.rotate(radians);
    _screenshot.rotate(radians);
  }

  @override
  void save() {
    _main.save();
    _screenshot.save();
  }

  @override
  void saveLayer(Rect bounds, Paint paint) {
    _main.saveLayer(bounds, paint);
    _screenshot.saveLayer(bounds, paint);
  }

  @override
  void scale(double sx, [double sy]) {
    _main.scale(sx, sy);
    _screenshot.scale(sx, sy);
  }

  @override
  void skew(double sx, double sy) {
    _main.skew(sx, sy);
    _screenshot.skew(sx, sy);
  }

  @override
  void transform(Float64List matrix4) {
    _main.transform(matrix4);
    _screenshot.transform(matrix4);
  }

  @override
  void translate(double dx, double dy) {
    _main.translate(dx, dy);
    _screenshot.translate(dx, dy);
  }
}

Rect _calculateSubtreeBoundsHelper(RenderObject object, Matrix4 transform) {
  Rect bounds = MatrixUtils.transformRect(transform, object.semanticBounds);

  object.visitChildren((RenderObject child) {
    final Matrix4 childTransform = transform.clone();
    object.applyPaintTransform(child, childTransform);
    Rect childBounds = _calculateSubtreeBoundsHelper(child, childTransform);
    final Rect paintClip = object.describeApproximatePaintClip(child);
    if (paintClip != null) {
      final Rect transformedPaintClip = MatrixUtils.transformRect(
        transform,
        paintClip,
      );
      childBounds = childBounds.intersect(transformedPaintClip);
    }

    if (childBounds.isFinite && !childBounds.isEmpty) {
      bounds =
          bounds.isEmpty ? childBounds : bounds.expandToInclude(childBounds);
    }
  });

  return bounds;
}

Rect _calculateSubtreeBounds(RenderObject object) {
  return _calculateSubtreeBoundsHelper(object, Matrix4.identity());
}

class _ScreenshotContainerLayer extends OffsetLayer {
  @override
  void addToScene(ui.SceneBuilder builder, [Offset layerOffset = Offset.zero]) {
    addChildrenToScene(builder, layerOffset);
  }
}

class _ScreenshotData {
  _ScreenshotData({
    @required this.target,
  })  : assert(target != null),
        containerLayer = _ScreenshotContainerLayer();

  final RenderObject target;

  final OffsetLayer containerLayer;

  bool foundTarget = false;

  bool includeInScreenshot = false;

  bool includeInRegularContext = true;

  Offset get screenshotOffset {
    assert(foundTarget);
    return containerLayer.offset;
  }

  set screenshotOffset(Offset offset) {
    containerLayer.offset = offset;
  }
}

class _ScreenshotPaintingContext extends PaintingContext {
  _ScreenshotPaintingContext({
    @required ContainerLayer containerLayer,
    @required Rect estimatedBounds,
    @required _ScreenshotData screenshotData,
  })  : _data = screenshotData,
        super(containerLayer, estimatedBounds);

  final _ScreenshotData _data;

  PictureLayer _screenshotCurrentLayer;
  ui.PictureRecorder _screenshotRecorder;
  Canvas _screenshotCanvas;
  _MulticastCanvas _multicastCanvas;

  @override
  Canvas get canvas {
    if (_data.includeInScreenshot) {
      if (_screenshotCanvas == null) {
        _startRecordingScreenshot();
      }
      assert(_screenshotCanvas != null);
      return _data.includeInRegularContext
          ? _multicastCanvas
          : _screenshotCanvas;
    } else {
      assert(_data.includeInRegularContext);
      return super.canvas;
    }
  }

  bool get _isScreenshotRecording {
    final bool hasScreenshotCanvas = _screenshotCanvas != null;
    assert(() {
      if (hasScreenshotCanvas) {
        assert(_screenshotCurrentLayer != null);
        assert(_screenshotRecorder != null);
        assert(_screenshotCanvas != null);
      } else {
        assert(_screenshotCurrentLayer == null);
        assert(_screenshotRecorder == null);
        assert(_screenshotCanvas == null);
      }
      return true;
    }());
    return hasScreenshotCanvas;
  }

  void _startRecordingScreenshot() {
    assert(_data.includeInScreenshot);
    assert(!_isScreenshotRecording);
    _screenshotCurrentLayer = PictureLayer(estimatedBounds);
    _screenshotRecorder = ui.PictureRecorder();
    _screenshotCanvas = Canvas(_screenshotRecorder);
    _data.containerLayer.append(_screenshotCurrentLayer);
    if (_data.includeInRegularContext) {
      _multicastCanvas = _MulticastCanvas(
        main: super.canvas,
        screenshot: _screenshotCanvas,
      );
    } else {
      _multicastCanvas = null;
    }
  }

  @override
  void stopRecordingIfNeeded() {
    super.stopRecordingIfNeeded();
    _stopRecordingScreenshotIfNeeded();
  }

  void _stopRecordingScreenshotIfNeeded() {
    if (!_isScreenshotRecording) return;

    _screenshotCurrentLayer.picture = _screenshotRecorder.endRecording();
    _screenshotCurrentLayer = null;
    _screenshotRecorder = null;
    _multicastCanvas = null;
    _screenshotCanvas = null;
  }

  @override
  void appendLayer(Layer layer) {
    if (_data.includeInRegularContext) {
      super.appendLayer(layer);
      if (_data.includeInScreenshot) {
        assert(!_isScreenshotRecording);

        _data.containerLayer.append(_ProxyLayer(layer));
      }
    } else {
      assert(!_isScreenshotRecording);
      assert(_data.includeInScreenshot);
      layer.remove();
      _data.containerLayer.append(layer);
      return;
    }
  }

  @override
  PaintingContext createChildContext(ContainerLayer childLayer, Rect bounds) {
    if (_data.foundTarget) {
      return super.createChildContext(childLayer, bounds);
    } else {
      return _ScreenshotPaintingContext(
        containerLayer: childLayer,
        estimatedBounds: bounds,
        screenshotData: _data,
      );
    }
  }

  @override
  void paintChild(RenderObject child, Offset offset) {
    final bool isScreenshotTarget = identical(child, _data.target);
    if (isScreenshotTarget) {
      assert(!_data.includeInScreenshot);
      assert(!_data.foundTarget);
      _data.foundTarget = true;
      _data.screenshotOffset = offset;
      _data.includeInScreenshot = true;
    }
    super.paintChild(child, offset);
    if (isScreenshotTarget) {
      _stopRecordingScreenshotIfNeeded();
      _data.includeInScreenshot = false;
    }
  }

  static Future<ui.Image> toImage(
    RenderObject renderObject,
    Rect renderBounds, {
    double pixelRatio = 1.0,
    bool debugPaint = false,
  }) {
    RenderObject repaintBoundary = renderObject;
    while (repaintBoundary != null && !repaintBoundary.isRepaintBoundary) {
      repaintBoundary = repaintBoundary.parent;
    }
    assert(repaintBoundary != null);
    final _ScreenshotData data = _ScreenshotData(target: renderObject);
    final _ScreenshotPaintingContext context = _ScreenshotPaintingContext(
      containerLayer: repaintBoundary.debugLayer,
      estimatedBounds: repaintBoundary.paintBounds,
      screenshotData: data,
    );

    if (identical(renderObject, repaintBoundary)) {
      data.containerLayer.append(_ProxyLayer(repaintBoundary.debugLayer));
      data.foundTarget = true;
      final OffsetLayer offsetLayer = repaintBoundary.debugLayer;
      data.screenshotOffset = offsetLayer.offset;
    } else {
      PaintingContext.debugInstrumentRepaintCompositedChild(
        repaintBoundary,
        customContext: context,
      );
    }

    if (debugPaint && !debugPaintSizeEnabled) {
      data.includeInRegularContext = false;

      context.stopRecordingIfNeeded();
      assert(data.foundTarget);
      data.includeInScreenshot = true;

      debugPaintSizeEnabled = true;
      try {
        renderObject.debugPaint(context, data.screenshotOffset);
      } finally {
        debugPaintSizeEnabled = false;
        context.stopRecordingIfNeeded();
      }
    }

    repaintBoundary.debugLayer.buildScene(ui.SceneBuilder());

    return data.containerLayer.toImage(renderBounds, pixelRatio: pixelRatio);
  }
}

class _DiagnosticsPathNode {
  _DiagnosticsPathNode({
    @required this.node,
    @required this.children,
    this.childIndex,
  })  : assert(node != null),
        assert(children != null);

  final DiagnosticsNode node;

  final List<DiagnosticsNode> children;

  final int childIndex;
}

List<_DiagnosticsPathNode> _followDiagnosticableChain(
  List<Diagnosticable> chain, {
  String name,
  DiagnosticsTreeStyle style,
}) {
  final List<_DiagnosticsPathNode> path = <_DiagnosticsPathNode>[];
  if (chain.isEmpty) return path;
  DiagnosticsNode diagnostic =
      chain.first.toDiagnosticsNode(name: name, style: style);
  for (int i = 1; i < chain.length; i += 1) {
    final Diagnosticable target = chain[i];
    bool foundMatch = false;
    final List<DiagnosticsNode> children = diagnostic.getChildren();
    for (int j = 0; j < children.length; j += 1) {
      final DiagnosticsNode child = children[j];
      if (child.value == target) {
        foundMatch = true;
        path.add(_DiagnosticsPathNode(
          node: diagnostic,
          children: children,
          childIndex: j,
        ));
        diagnostic = child;
        break;
      }
    }
    assert(foundMatch);
  }
  path.add(_DiagnosticsPathNode(
      node: diagnostic, children: diagnostic.getChildren()));
  return path;
}

typedef InspectorSelectionChangedCallback = void Function();

class _InspectorReferenceData {
  _InspectorReferenceData(this.object);

  final Object object;
  int count = 1;
}

class _WidgetInspectorService = Object with WidgetInspectorService;

mixin WidgetInspectorService {
  final List<String> _serializeRing = List<String>(20);
  int _serializeRingIndex = 0;

  static WidgetInspectorService get instance => _instance;
  static WidgetInspectorService _instance = _WidgetInspectorService();
  @protected
  static set instance(WidgetInspectorService instance) {
    _instance = instance;
  }

  static bool _debugServiceExtensionsRegistered = false;

  final InspectorSelection selection = InspectorSelection();

  InspectorSelectionChangedCallback selectionChangedCallback;

  final Map<String, Set<_InspectorReferenceData>> _groups =
      <String, Set<_InspectorReferenceData>>{};
  final Map<String, _InspectorReferenceData> _idToReferenceData =
      <String, _InspectorReferenceData>{};
  final Map<Object, String> _objectToId = Map<Object, String>.identity();
  int _nextId = 0;

  List<String> _pubRootDirectories;

  bool _trackRebuildDirtyWidgets = false;
  bool _trackRepaintWidgets = false;

  _RegisterServiceExtensionCallback _registerServiceExtensionCallback;

  @protected
  void registerServiceExtension({
    @required String name,
    @required ServiceExtensionCallback callback,
  }) {
    _registerServiceExtensionCallback(
      name: 'inspector.$name',
      callback: callback,
    );
  }

  void _registerSignalServiceExtension({
    @required String name,
    @required FutureOr<Object> callback(),
  }) {
    registerServiceExtension(
      name: name,
      callback: (Map<String, String> parameters) async {
        return <String, Object>{'result': await callback()};
      },
    );
  }

  void _registerObjectGroupServiceExtension({
    @required String name,
    @required FutureOr<Object> callback(String objectGroup),
  }) {
    registerServiceExtension(
      name: name,
      callback: (Map<String, String> parameters) async {
        return <String, Object>{
          'result': await callback(parameters['objectGroup'])
        };
      },
    );
  }

  void _registerBoolServiceExtension({
    @required String name,
    @required AsyncValueGetter<bool> getter,
    @required AsyncValueSetter<bool> setter,
  }) {
    assert(name != null);
    assert(getter != null);
    assert(setter != null);
    registerServiceExtension(
      name: name,
      callback: (Map<String, String> parameters) async {
        if (parameters.containsKey('enabled')) {
          final bool value = parameters['enabled'] == 'true';
          await setter(value);
          _postExtensionStateChangedEvent(name, value);
        }
        return <String, dynamic>{'enabled': await getter() ? 'true' : 'false'};
      },
    );
  }

  void _postExtensionStateChangedEvent(String name, dynamic value) {
    postEvent(
      'Flutter.ServiceExtensionStateChanged',
      <String, dynamic>{
        'extension': 'ext.flutter.inspector.$name',
        'value': value,
      },
    );
  }

  void _registerServiceExtensionWithArg({
    @required String name,
    @required FutureOr<Object> callback(String objectId, String objectGroup),
  }) {
    registerServiceExtension(
      name: name,
      callback: (Map<String, String> parameters) async {
        assert(parameters.containsKey('objectGroup'));
        return <String, Object>{
          'result':
              await callback(parameters['arg'], parameters['objectGroup']),
        };
      },
    );
  }

  void _registerServiceExtensionVarArgs({
    @required String name,
    @required FutureOr<Object> callback(List<String> args),
  }) {
    registerServiceExtension(
      name: name,
      callback: (Map<String, String> parameters) async {
        const String argPrefix = 'arg';
        final List<String> args = <String>[];
        parameters.forEach((String name, String value) {
          if (name.startsWith(argPrefix)) {
            final int index = int.parse(name.substring(argPrefix.length));
            if (index >= args.length) {
              args.length = index + 1;
            }
            args[index] = value;
          }
        });
        return <String, Object>{'result': await callback(args)};
      },
    );
  }

  @protected
  Future<void> forceRebuild() {
    final WidgetsBinding binding = WidgetsBinding.instance;
    if (binding.renderViewElement != null) {
      binding.buildOwner.reassemble(binding.renderViewElement);
      return binding.endOfFrame;
    }
    return Future<void>.value();
  }

  static const String _consoleObjectGroup = 'console-group';

  int _errorsSinceReload = 0;

  void _reportError(FlutterErrorDetails details) {
    final Map<String, Object> errorJson = _nodeToJson(
      details.toDiagnosticsNode(),
      _SerializationDelegate(
        groupName: _consoleObjectGroup,
        subtreeDepth: 5,
        includeProperties: true,
        expandPropertyValues: true,
        maxDescendentsTruncatableNode: 5,
        service: this,
      ),
    );

    errorJson['errorsSinceReload'] = _errorsSinceReload;
    _errorsSinceReload += 1;

    postEvent('Flutter.Error', errorJson);
  }

  void _resetErrorCount() {
    _errorsSinceReload = 0;
  }

  void initServiceExtensions(
      _RegisterServiceExtensionCallback registerServiceExtensionCallback) {
    _registerServiceExtensionCallback = registerServiceExtensionCallback;
    assert(!_debugServiceExtensionsRegistered);
    assert(() {
      _debugServiceExtensionsRegistered = true;
      return true;
    }());

    SchedulerBinding.instance.addPersistentFrameCallback(_onFrameStart);

    final FlutterExceptionHandler structuredExceptionHandler = _reportError;
    final FlutterExceptionHandler defaultExceptionHandler =
        FlutterError.onError;

    _registerBoolServiceExtension(
      name: 'structuredErrors',
      getter: () async => FlutterError.onError == structuredExceptionHandler,
      setter: (bool value) {
        FlutterError.onError =
            value ? structuredExceptionHandler : defaultExceptionHandler;
        return Future<void>.value();
      },
    );

    _registerBoolServiceExtension(
      name: 'show',
      getter: () async => WidgetsApp.debugShowWidgetInspectorOverride,
      setter: (bool value) {
        if (WidgetsApp.debugShowWidgetInspectorOverride == value) {
          return Future<void>.value();
        }
        WidgetsApp.debugShowWidgetInspectorOverride = value;
        return forceRebuild();
      },
    );

    if (isWidgetCreationTracked()) {
      _registerBoolServiceExtension(
        name: 'trackRebuildDirtyWidgets',
        getter: () async => _trackRebuildDirtyWidgets,
        setter: (bool value) async {
          if (value == _trackRebuildDirtyWidgets) {
            return;
          }
          _rebuildStats.resetCounts();
          _trackRebuildDirtyWidgets = value;
          if (value) {
            assert(debugOnRebuildDirtyWidget == null);
            debugOnRebuildDirtyWidget = _onRebuildWidget;

            await forceRebuild();
            return;
          } else {
            debugOnRebuildDirtyWidget = null;
            return;
          }
        },
      );

      _registerBoolServiceExtension(
        name: 'trackRepaintWidgets',
        getter: () async => _trackRepaintWidgets,
        setter: (bool value) async {
          if (value == _trackRepaintWidgets) {
            return;
          }
          _repaintStats.resetCounts();
          _trackRepaintWidgets = value;
          if (value) {
            assert(debugOnProfilePaint == null);
            debugOnProfilePaint = _onPaint;

            void markTreeNeedsPaint(RenderObject renderObject) {
              renderObject.markNeedsPaint();
              renderObject.visitChildren(markTreeNeedsPaint);
            }

            final RenderObject root = RendererBinding.instance.renderView;
            if (root != null) {
              markTreeNeedsPaint(root);
            }
          } else {
            debugOnProfilePaint = null;
          }
        },
      );
    }

    _registerSignalServiceExtension(
      name: 'disposeAllGroups',
      callback: disposeAllGroups,
    );
    _registerObjectGroupServiceExtension(
      name: 'disposeGroup',
      callback: disposeGroup,
    );
    _registerSignalServiceExtension(
      name: 'isWidgetTreeReady',
      callback: isWidgetTreeReady,
    );
    _registerServiceExtensionWithArg(
      name: 'disposeId',
      callback: disposeId,
    );
    _registerServiceExtensionVarArgs(
      name: 'setPubRootDirectories',
      callback: setPubRootDirectories,
    );
    _registerServiceExtensionWithArg(
      name: 'setSelectionById',
      callback: setSelectionById,
    );
    _registerServiceExtensionWithArg(
      name: 'getParentChain',
      callback: _getParentChain,
    );
    _registerServiceExtensionWithArg(
      name: 'getProperties',
      callback: _getProperties,
    );
    _registerServiceExtensionWithArg(
      name: 'getChildren',
      callback: _getChildren,
    );

    _registerServiceExtensionWithArg(
      name: 'getChildrenSummaryTree',
      callback: _getChildrenSummaryTree,
    );

    _registerServiceExtensionWithArg(
      name: 'getChildrenDetailsSubtree',
      callback: _getChildrenDetailsSubtree,
    );

    _registerObjectGroupServiceExtension(
      name: 'getRootWidget',
      callback: _getRootWidget,
    );
    _registerObjectGroupServiceExtension(
      name: 'getRootRenderObject',
      callback: _getRootRenderObject,
    );
    _registerObjectGroupServiceExtension(
      name: 'getRootWidgetSummaryTree',
      callback: _getRootWidgetSummaryTree,
    );
    _registerServiceExtensionWithArg(
      name: 'getDetailsSubtree',
      callback: _getDetailsSubtree,
    );
    _registerServiceExtensionWithArg(
      name: 'getSelectedRenderObject',
      callback: _getSelectedRenderObject,
    );
    _registerServiceExtensionWithArg(
      name: 'getSelectedWidget',
      callback: _getSelectedWidget,
    );
    _registerServiceExtensionWithArg(
      name: 'getSelectedSummaryWidget',
      callback: _getSelectedSummaryWidget,
    );

    _registerSignalServiceExtension(
      name: 'isWidgetCreationTracked',
      callback: isWidgetCreationTracked,
    );
    registerServiceExtension(
      name: 'screenshot',
      callback: (Map<String, String> parameters) async {
        assert(parameters.containsKey('id'));
        assert(parameters.containsKey('width'));
        assert(parameters.containsKey('height'));

        final ui.Image image = await screenshot(
          toObject(parameters['id']),
          width: double.parse(parameters['width']),
          height: double.parse(parameters['height']),
          margin: parameters.containsKey('margin')
              ? double.parse(parameters['margin'])
              : 0.0,
          maxPixelRatio: parameters.containsKey('maxPixelRatio')
              ? double.parse(parameters['maxPixelRatio'])
              : 1.0,
          debugPaint: parameters['debugPaint'] == 'true',
        );
        if (image == null) {
          return <String, Object>{'result': null};
        }
        final ByteData byteData =
            await image.toByteData(format: ui.ImageByteFormat.png);

        return <String, Object>{
          'result': base64.encoder.convert(Uint8List.view(byteData.buffer)),
        };
      },
    );
  }

  void _clearStats() {
    _rebuildStats.resetCounts();
    _repaintStats.resetCounts();
  }

  @protected
  void disposeAllGroups() {
    _groups.clear();
    _idToReferenceData.clear();
    _objectToId.clear();
    _nextId = 0;
  }

  @protected
  void disposeGroup(String name) {
    final Set<_InspectorReferenceData> references = _groups.remove(name);
    if (references == null) return;
    references.forEach(_decrementReferenceCount);
  }

  void _decrementReferenceCount(_InspectorReferenceData reference) {
    reference.count -= 1;
    assert(reference.count >= 0);
    if (reference.count == 0) {
      final String id = _objectToId.remove(reference.object);
      assert(id != null);
      _idToReferenceData.remove(id);
    }
  }

  @protected
  String toId(Object object, String groupName) {
    if (object == null) return null;

    final Set<_InspectorReferenceData> group = _groups.putIfAbsent(
        groupName, () => Set<_InspectorReferenceData>.identity());
    String id = _objectToId[object];
    _InspectorReferenceData referenceData;
    if (id == null) {
      id = 'inspector-$_nextId';
      _nextId += 1;
      _objectToId[object] = id;
      referenceData = _InspectorReferenceData(object);
      _idToReferenceData[id] = referenceData;
      group.add(referenceData);
    } else {
      referenceData = _idToReferenceData[id];
      if (group.add(referenceData)) referenceData.count += 1;
    }
    return id;
  }

  @protected
  bool isWidgetTreeReady([String groupName]) {
    return WidgetsBinding.instance != null &&
        WidgetsBinding.instance.debugDidSendFirstFrameEvent;
  }

  @protected
  Object toObject(String id, [String groupName]) {
    if (id == null) return null;

    final _InspectorReferenceData data = _idToReferenceData[id];
    if (data == null) {
      throw FlutterError.fromParts(
          <DiagnosticsNode>[ErrorSummary('Id does not exist.')]);
    }
    return data.object;
  }

  @protected
  Object toObjectForSourceLocation(String id, [String groupName]) {
    final Object object = toObject(id);
    if (object is Element) {
      return object.widget;
    }
    return object;
  }

  @protected
  void disposeId(String id, String groupName) {
    if (id == null) return;

    final _InspectorReferenceData referenceData = _idToReferenceData[id];
    if (referenceData == null)
      throw FlutterError.fromParts(
          <DiagnosticsNode>[ErrorSummary('Id does not exist')]);
    if (_groups[groupName]?.remove(referenceData) != true)
      throw FlutterError.fromParts(
          <DiagnosticsNode>[ErrorSummary('Id is not in group')]);
    _decrementReferenceCount(referenceData);
  }

  @protected
  void setPubRootDirectories(List<Object> pubRootDirectories) {
    _pubRootDirectories = pubRootDirectories
        .map<String>(
          (Object directory) => Uri.parse(directory).path,
        )
        .toList();
  }

  @protected
  bool setSelectionById(String id, [String groupName]) {
    return setSelection(toObject(id), groupName);
  }

  @protected
  bool setSelection(Object object, [String groupName]) {
    if (object is Element || object is RenderObject) {
      if (object is Element) {
        if (object == selection.currentElement) {
          return false;
        }
        selection.currentElement = object;
        developer.inspect(selection.currentElement);
      } else {
        if (object == selection.current) {
          return false;
        }
        selection.current = object;
        developer.inspect(selection.current);
      }
      if (selectionChangedCallback != null) {
        if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.idle) {
          selectionChangedCallback();
        } else {
          SchedulerBinding.instance.scheduleTask(
            selectionChangedCallback,
            Priority.touch,
          );
        }
      }
      return true;
    }
    return false;
  }

  @protected
  String getParentChain(String id, String groupName) {
    return _safeJsonEncode(_getParentChain(id, groupName));
  }

  List<Object> _getParentChain(String id, String groupName) {
    final Object value = toObject(id);
    List<_DiagnosticsPathNode> path;
    if (value is RenderObject)
      path = _getRenderObjectParentChain(value, groupName);
    else if (value is Element)
      path = _getElementParentChain(value, groupName);
    else
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary(
            'Cannot get parent chain for node of type ${value.runtimeType}')
      ]);

    return path
        .map<Object>((_DiagnosticsPathNode node) => _pathNodeToJson(
              node,
              _SerializationDelegate(groupName: groupName, service: this),
            ))
        .toList();
  }

  Map<String, Object> _pathNodeToJson(
      _DiagnosticsPathNode pathNode, _SerializationDelegate delegate) {
    if (pathNode == null) return null;
    return <String, Object>{
      'node': _nodeToJson(pathNode.node, delegate),
      'children':
          _nodesToJson(pathNode.children, delegate, parent: pathNode.node),
      'childIndex': pathNode.childIndex,
    };
  }

  List<Element> _getRawElementParentChain(Element element,
      {int numLocalParents}) {
    List<Element> elements = element?.debugGetDiagnosticChain();
    if (numLocalParents != null) {
      for (int i = 0; i < elements.length; i += 1) {
        if (_isValueCreatedByLocalProject(elements[i])) {
          numLocalParents--;
          if (numLocalParents <= 0) {
            elements = elements.take(i + 1).toList();
            break;
          }
        }
      }
    }
    return elements?.reversed?.toList();
  }

  List<_DiagnosticsPathNode> _getElementParentChain(
      Element element, String groupName,
      {int numLocalParents}) {
    return _followDiagnosticableChain(
          _getRawElementParentChain(element, numLocalParents: numLocalParents),
        ) ??
        const <_DiagnosticsPathNode>[];
  }

  List<_DiagnosticsPathNode> _getRenderObjectParentChain(
      RenderObject renderObject, String groupName,
      {int maxparents}) {
    final List<RenderObject> chain = <RenderObject>[];
    while (renderObject != null) {
      chain.add(renderObject);
      renderObject = renderObject.parent;
    }
    return _followDiagnosticableChain(chain.reversed.toList());
  }

  Map<String, Object> _nodeToJson(
    DiagnosticsNode node,
    _SerializationDelegate delegate,
  ) {
    return node?.toJsonMap(delegate);
  }

  bool _isValueCreatedByLocalProject(Object value) {
    final _Location creationLocation = _getCreationLocation(value);
    if (creationLocation == null) {
      return false;
    }
    return _isLocalCreationLocation(creationLocation);
  }

  bool _isLocalCreationLocation(_Location location) {
    if (location == null || location.file == null) {
      return false;
    }
    final String file = Uri.parse(location.file).path;

    if (_pubRootDirectories == null) {
      return !file.contains('packages/flutter/');
    }
    for (String directory in _pubRootDirectories) {
      if (file.startsWith(directory)) {
        return true;
      }
    }
    return false;
  }

  String _safeJsonEncode(Object object) {
    final String jsonString = json.encode(object);
    _serializeRing[_serializeRingIndex] = jsonString;
    _serializeRingIndex = (_serializeRingIndex + 1) % _serializeRing.length;
    return jsonString;
  }

  List<DiagnosticsNode> _truncateNodes(
      Iterable<DiagnosticsNode> nodes, int maxDescendentsTruncatableNode) {
    if (nodes.every((DiagnosticsNode node) => node.value is Element) &&
        isWidgetCreationTracked()) {
      final List<DiagnosticsNode> localNodes = nodes
          .where((DiagnosticsNode node) =>
              _isValueCreatedByLocalProject(node.value))
          .toList();
      if (localNodes.isNotEmpty) {
        return localNodes;
      }
    }
    return nodes.take(maxDescendentsTruncatableNode).toList();
  }

  List<Map<String, Object>> _nodesToJson(
    Iterable<DiagnosticsNode> nodes,
    _SerializationDelegate delegate, {
    @required DiagnosticsNode parent,
  }) {
    return DiagnosticsNode.toJsonList(nodes, parent, delegate);
  }

  @protected
  String getProperties(String diagnosticsNodeId, String groupName) {
    return _safeJsonEncode(_getProperties(diagnosticsNodeId, groupName));
  }

  List<Object> _getProperties(String diagnosticsNodeId, String groupName) {
    final DiagnosticsNode node = toObject(diagnosticsNodeId);
    return _nodesToJson(
        node == null ? const <DiagnosticsNode>[] : node.getProperties(),
        _SerializationDelegate(groupName: groupName, service: this),
        parent: node);
  }

  String getChildren(String diagnosticsNodeId, String groupName) {
    return _safeJsonEncode(_getChildren(diagnosticsNodeId, groupName));
  }

  List<Object> _getChildren(String diagnosticsNodeId, String groupName) {
    final DiagnosticsNode node = toObject(diagnosticsNodeId);
    final _SerializationDelegate delegate =
        _SerializationDelegate(groupName: groupName, service: this);
    return _nodesToJson(
        node == null
            ? const <DiagnosticsNode>[]
            : _getChildrenFiltered(node, delegate),
        delegate,
        parent: node);
  }

  String getChildrenSummaryTree(String diagnosticsNodeId, String groupName) {
    return _safeJsonEncode(
        _getChildrenSummaryTree(diagnosticsNodeId, groupName));
  }

  List<Object> _getChildrenSummaryTree(
      String diagnosticsNodeId, String groupName) {
    final DiagnosticsNode node = toObject(diagnosticsNodeId);
    final _SerializationDelegate delegate = _SerializationDelegate(
        groupName: groupName, summaryTree: true, service: this);
    return _nodesToJson(
        node == null
            ? const <DiagnosticsNode>[]
            : _getChildrenFiltered(node, delegate),
        delegate,
        parent: node);
  }

  String getChildrenDetailsSubtree(String diagnosticsNodeId, String groupName) {
    return _safeJsonEncode(
        _getChildrenDetailsSubtree(diagnosticsNodeId, groupName));
  }

  List<Object> _getChildrenDetailsSubtree(
      String diagnosticsNodeId, String groupName) {
    final DiagnosticsNode node = toObject(diagnosticsNodeId);

    final _SerializationDelegate delegate = _SerializationDelegate(
        groupName: groupName,
        subtreeDepth: 1,
        includeProperties: true,
        service: this);
    return _nodesToJson(
        node == null
            ? const <DiagnosticsNode>[]
            : _getChildrenFiltered(node, delegate),
        delegate,
        parent: node);
  }

  bool _shouldShowInSummaryTree(DiagnosticsNode node) {
    if (node.level == DiagnosticLevel.error) {
      return true;
    }
    final Object value = node.value;
    if (value is! Diagnosticable) {
      return true;
    }
    if (value is! Element || !isWidgetCreationTracked()) {
      return true;
    }
    return _isValueCreatedByLocalProject(value);
  }

  List<DiagnosticsNode> _getChildrenFiltered(
    DiagnosticsNode node,
    _SerializationDelegate delegate,
  ) {
    return _filterChildren(node.getChildren(), delegate);
  }

  List<DiagnosticsNode> _filterChildren(
    List<DiagnosticsNode> nodes,
    _SerializationDelegate delegate,
  ) {
    final List<DiagnosticsNode> children = <DiagnosticsNode>[
      for (DiagnosticsNode child in nodes)
        if (!delegate.summaryTree || _shouldShowInSummaryTree(child))
          child
        else
          ..._getChildrenFiltered(child, delegate),
    ];
    return children;
  }

  String getRootWidget(String groupName) {
    return _safeJsonEncode(_getRootWidget(groupName));
  }

  Map<String, Object> _getRootWidget(String groupName) {
    return _nodeToJson(
        WidgetsBinding.instance?.renderViewElement?.toDiagnosticsNode(),
        _SerializationDelegate(groupName: groupName, service: this));
  }

  String getRootWidgetSummaryTree(String groupName) {
    return _safeJsonEncode(_getRootWidgetSummaryTree(groupName));
  }

  Map<String, Object> _getRootWidgetSummaryTree(String groupName) {
    return _nodeToJson(
      WidgetsBinding.instance?.renderViewElement?.toDiagnosticsNode(),
      _SerializationDelegate(
          groupName: groupName,
          subtreeDepth: 1000000,
          summaryTree: true,
          service: this),
    );
  }

  @protected
  String getRootRenderObject(String groupName) {
    return _safeJsonEncode(_getRootRenderObject(groupName));
  }

  Map<String, Object> _getRootRenderObject(String groupName) {
    return _nodeToJson(
        RendererBinding.instance?.renderView?.toDiagnosticsNode(),
        _SerializationDelegate(groupName: groupName, service: this));
  }

  String getDetailsSubtree(String id, String groupName) {
    return _safeJsonEncode(_getDetailsSubtree(id, groupName));
  }

  Map<String, Object> _getDetailsSubtree(String id, String groupName) {
    final DiagnosticsNode root = toObject(id);
    if (root == null) {
      return null;
    }
    return _nodeToJson(
      root,
      _SerializationDelegate(
        groupName: groupName,
        summaryTree: false,
        subtreeDepth: 2,
        includeProperties: true,
        service: this,
      ),
    );
  }

  @protected
  String getSelectedRenderObject(String previousSelectionId, String groupName) {
    return _safeJsonEncode(
        _getSelectedRenderObject(previousSelectionId, groupName));
  }

  Map<String, Object> _getSelectedRenderObject(
      String previousSelectionId, String groupName) {
    final DiagnosticsNode previousSelection = toObject(previousSelectionId);
    final RenderObject current = selection?.current;
    return _nodeToJson(
        current == previousSelection?.value
            ? previousSelection
            : current?.toDiagnosticsNode(),
        _SerializationDelegate(groupName: groupName, service: this));
  }

  @protected
  String getSelectedWidget(String previousSelectionId, String groupName) {
    return _safeJsonEncode(_getSelectedWidget(previousSelectionId, groupName));
  }

  @protected
  Future<ui.Image> screenshot(
    Object object, {
    @required double width,
    @required double height,
    double margin = 0.0,
    double maxPixelRatio = 1.0,
    bool debugPaint = false,
  }) async {
    if (object is! Element && object is! RenderObject) {
      return null;
    }
    final RenderObject renderObject =
        object is Element ? object.renderObject : object;
    if (renderObject == null || !renderObject.attached) {
      return null;
    }

    if (renderObject.debugNeedsLayout) {
      final PipelineOwner owner = renderObject.owner;
      assert(owner != null);
      assert(!owner.debugDoingLayout);
      owner
        ..flushLayout()
        ..flushCompositingBits()
        ..flushPaint();

      if (renderObject.debugNeedsLayout) {
        return null;
      }
    }

    Rect renderBounds = _calculateSubtreeBounds(renderObject);
    if (margin != 0.0) {
      renderBounds = renderBounds.inflate(margin);
    }
    if (renderBounds.isEmpty) {
      return null;
    }

    final double pixelRatio = math.min(
      maxPixelRatio,
      math.min(
        width / renderBounds.width,
        height / renderBounds.height,
      ),
    );

    return _ScreenshotPaintingContext.toImage(
      renderObject,
      renderBounds,
      pixelRatio: pixelRatio,
      debugPaint: debugPaint,
    );
  }

  Map<String, Object> _getSelectedWidget(
      String previousSelectionId, String groupName) {
    final DiagnosticsNode previousSelection = toObject(previousSelectionId);
    final Element current = selection?.currentElement;
    return _nodeToJson(
        current == previousSelection?.value
            ? previousSelection
            : current?.toDiagnosticsNode(),
        _SerializationDelegate(groupName: groupName, service: this));
  }

  String getSelectedSummaryWidget(
      String previousSelectionId, String groupName) {
    return _safeJsonEncode(
        _getSelectedSummaryWidget(previousSelectionId, groupName));
  }

  Map<String, Object> _getSelectedSummaryWidget(
      String previousSelectionId, String groupName) {
    if (!isWidgetCreationTracked()) {
      return _getSelectedWidget(previousSelectionId, groupName);
    }
    final DiagnosticsNode previousSelection = toObject(previousSelectionId);
    Element current = selection?.currentElement;
    if (current != null && !_isValueCreatedByLocalProject(current)) {
      Element firstLocal;
      for (Element candidate in current.debugGetDiagnosticChain()) {
        if (_isValueCreatedByLocalProject(candidate)) {
          firstLocal = candidate;
          break;
        }
      }
      current = firstLocal;
    }
    return _nodeToJson(
        current == previousSelection?.value
            ? previousSelection
            : current?.toDiagnosticsNode(),
        _SerializationDelegate(groupName: groupName, service: this));
  }

  bool isWidgetCreationTracked() {
    _widgetCreationTracked ??= _WidgetForTypeTests() is _HasCreationLocation;
    return _widgetCreationTracked;
  }

  bool _widgetCreationTracked;

  Duration _frameStart;

  void _onFrameStart(Duration timeStamp) {
    _frameStart = timeStamp;
    SchedulerBinding.instance.addPostFrameCallback(_onFrameEnd);
  }

  void _onFrameEnd(Duration timeStamp) {
    if (_trackRebuildDirtyWidgets) {
      _postStatsEvent('Flutter.RebuiltWidgets', _rebuildStats);
    }
    if (_trackRepaintWidgets) {
      _postStatsEvent('Flutter.RepaintWidgets', _repaintStats);
    }
  }

  void _postStatsEvent(String eventName, _ElementLocationStatsTracker stats) {
    postEvent(eventName, stats.exportToJson(_frameStart));
  }

  @protected
  void postEvent(String eventKind, Map<Object, Object> eventData) {
    developer.postEvent(eventKind, eventData);
  }

  final _ElementLocationStatsTracker _rebuildStats =
      _ElementLocationStatsTracker();
  final _ElementLocationStatsTracker _repaintStats =
      _ElementLocationStatsTracker();

  void _onRebuildWidget(Element element, bool builtOnce) {
    _rebuildStats.add(element);
  }

  void _onPaint(RenderObject renderObject) {
    try {
      final Element element = renderObject.debugCreator?.element;
      if (element is! RenderObjectElement) {
        return;
      }
      _repaintStats.add(element);

      element.visitAncestorElements((Element ancestor) {
        if (ancestor is RenderObjectElement) {
          return false;
        }
        _repaintStats.add(ancestor);
        return true;
      });
    } catch (exception, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: exception,
          stack: stack,
        ),
      );
    }
  }

  void performReassemble() {
    _clearStats();
    _resetErrorCount();
  }
}

class _LocationCount {
  _LocationCount({
    @required this.location,
    @required this.id,
    @required this.local,
  });

  final int id;

  final bool local;

  final _Location location;

  int get count => _count;
  int _count = 0;

  void reset() {
    _count = 0;
  }

  void increment() {
    _count++;
  }
}

class _ElementLocationStatsTracker {
  final List<_LocationCount> _stats = <_LocationCount>[];

  final List<_LocationCount> active = <_LocationCount>[];

  final List<_LocationCount> newLocations = <_LocationCount>[];

  void add(Element element) {
    final Object widget = element.widget;
    if (widget is! _HasCreationLocation) {
      return;
    }
    final _HasCreationLocation creationLocationSource = widget;
    final _Location location = creationLocationSource._location;
    final int id = _toLocationId(location);

    _LocationCount entry;
    if (id >= _stats.length || _stats[id] == null) {
      while (id >= _stats.length) {
        _stats.add(null);
      }
      entry = _LocationCount(
        location: location,
        id: id,
        local:
            WidgetInspectorService.instance._isLocalCreationLocation(location),
      );
      if (entry.local) {
        newLocations.add(entry);
      }
      _stats[id] = entry;
    } else {
      entry = _stats[id];
    }

    if (entry.local) {
      if (entry.count == 0) {
        active.add(entry);
      }
      entry.increment();
    }
  }

  void resetCounts() {
    for (_LocationCount entry in active) {
      entry.reset();
    }
    active.clear();
  }

  Map<String, dynamic> exportToJson(Duration startTime) {
    final List<int> events = List<int>.filled(active.length * 2, 0);
    int j = 0;
    for (_LocationCount stat in active) {
      events[j++] = stat.id;
      events[j++] = stat.count;
    }

    final Map<String, dynamic> json = <String, dynamic>{
      'startTime': startTime.inMicroseconds,
      'events': events,
    };

    if (newLocations.isNotEmpty) {
      final Map<String, List<int>> locationsJson = <String, List<int>>{};
      for (_LocationCount entry in newLocations) {
        final _Location location = entry.location;
        final List<int> jsonForFile = locationsJson.putIfAbsent(
          location.file,
          () => <int>[],
        );
        jsonForFile..add(entry.id)..add(location.line)..add(location.column);
      }
      json['newLocations'] = locationsJson;
    }
    resetCounts();
    newLocations.clear();
    return json;
  }
}

class _WidgetForTypeTests extends Widget {
  @override
  Element createElement() => null;
}

class WidgetInspector extends StatefulWidget {
  const WidgetInspector({
    Key key,
    @required this.child,
    @required this.selectButtonBuilder,
  })  : assert(child != null),
        super(key: key);

  final Widget child;

  final InspectorSelectButtonBuilder selectButtonBuilder;

  @override
  _WidgetInspectorState createState() => _WidgetInspectorState();
}

class _WidgetInspectorState extends State<WidgetInspector>
    with WidgetsBindingObserver {
  _WidgetInspectorState()
      : selection = WidgetInspectorService.instance.selection;

  Offset _lastPointerLocation;

  final InspectorSelection selection;

  bool isSelectMode = true;

  final GlobalKey _ignorePointerKey = GlobalKey();

  static const double _edgeHitMargin = 2.0;

  InspectorSelectionChangedCallback _selectionChangedCallback;
  @override
  void initState() {
    super.initState();

    _selectionChangedCallback = () {
      setState(() {});
    };
    WidgetInspectorService.instance.selectionChangedCallback =
        _selectionChangedCallback;
  }

  @override
  void dispose() {
    if (WidgetInspectorService.instance.selectionChangedCallback ==
        _selectionChangedCallback) {
      WidgetInspectorService.instance.selectionChangedCallback = null;
    }
    super.dispose();
  }

  bool _hitTestHelper(
    List<RenderObject> hits,
    List<RenderObject> edgeHits,
    Offset position,
    RenderObject object,
    Matrix4 transform,
  ) {
    bool hit = false;
    final Matrix4 inverse = Matrix4.tryInvert(transform);
    if (inverse == null) {
      return false;
    }
    final Offset localPosition = MatrixUtils.transformPoint(inverse, position);

    final List<DiagnosticsNode> children = object.debugDescribeChildren();
    for (int i = children.length - 1; i >= 0; i -= 1) {
      final DiagnosticsNode diagnostics = children[i];
      assert(diagnostics != null);
      if (diagnostics.style == DiagnosticsTreeStyle.offstage ||
          diagnostics.value is! RenderObject) continue;
      final RenderObject child = diagnostics.value;
      final Rect paintClip = object.describeApproximatePaintClip(child);
      if (paintClip != null && !paintClip.contains(localPosition)) continue;

      final Matrix4 childTransform = transform.clone();
      object.applyPaintTransform(child, childTransform);
      if (_hitTestHelper(hits, edgeHits, position, child, childTransform))
        hit = true;
    }

    final Rect bounds = object.semanticBounds;
    if (bounds.contains(localPosition)) {
      hit = true;

      if (!bounds.deflate(_edgeHitMargin).contains(localPosition))
        edgeHits.add(object);
    }
    if (hit) hits.add(object);
    return hit;
  }

  List<RenderObject> hitTest(Offset position, RenderObject root) {
    final List<RenderObject> regularHits = <RenderObject>[];
    final List<RenderObject> edgeHits = <RenderObject>[];

    _hitTestHelper(
        regularHits, edgeHits, position, root, root.getTransformTo(null));

    double _area(RenderObject object) {
      final Size size = object.semanticBounds?.size;
      return size == null ? double.maxFinite : size.width * size.height;
    }

    regularHits
        .sort((RenderObject a, RenderObject b) => _area(a).compareTo(_area(b)));
    final Set<RenderObject> hits = <RenderObject>{
      ...edgeHits,
      ...regularHits,
    };
    return hits.toList();
  }

  void _inspectAt(Offset position) {
    if (!isSelectMode) return;

    final RenderIgnorePointer ignorePointer =
        _ignorePointerKey.currentContext.findRenderObject();
    final RenderObject userRender = ignorePointer.child;
    final List<RenderObject> selected = hitTest(position, userRender);

    setState(() {
      selection.candidates = selected;
    });
  }

  void _handlePanDown(DragDownDetails event) {
    _lastPointerLocation = event.globalPosition;
    _inspectAt(event.globalPosition);
  }

  void _handlePanUpdate(DragUpdateDetails event) {
    _lastPointerLocation = event.globalPosition;
    _inspectAt(event.globalPosition);
  }

  void _handlePanEnd(DragEndDetails details) {
    final Rect bounds = (Offset.zero &
            (WidgetsBinding.instance.window.physicalSize /
                WidgetsBinding.instance.window.devicePixelRatio))
        .deflate(_kOffScreenMargin);
    if (!bounds.contains(_lastPointerLocation)) {
      setState(() {
        selection.clear();
      });
    }
  }

  void _handleTap() {
    if (!isSelectMode) return;
    if (_lastPointerLocation != null) {
      _inspectAt(_lastPointerLocation);

      if (selection != null) {
        developer.inspect(selection.current);
      }
    }
    setState(() {
      if (widget.selectButtonBuilder != null) isSelectMode = false;
    });
  }

  void _handleEnableSelect() {
    setState(() {
      isSelectMode = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = <Widget>[];
    children.add(GestureDetector(
      onTap: _handleTap,
      onPanDown: _handlePanDown,
      onPanEnd: _handlePanEnd,
      onPanUpdate: _handlePanUpdate,
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      child: IgnorePointer(
        ignoring: isSelectMode,
        key: _ignorePointerKey,
        ignoringSemantics: false,
        child: widget.child,
      ),
    ));
    if (!isSelectMode && widget.selectButtonBuilder != null) {
      children.add(Positioned(
        left: _kInspectButtonMargin,
        bottom: _kInspectButtonMargin,
        child: widget.selectButtonBuilder(context, _handleEnableSelect),
      ));
    }
    children.add(_InspectorOverlay(selection: selection));
    return Stack(children: children);
  }
}

class InspectorSelection {
  List<RenderObject> get candidates => _candidates;
  List<RenderObject> _candidates = <RenderObject>[];
  set candidates(List<RenderObject> value) {
    _candidates = value;
    _index = 0;
    _computeCurrent();
  }

  int get index => _index;
  int _index = 0;
  set index(int value) {
    _index = value;
    _computeCurrent();
  }

  void clear() {
    _candidates = <RenderObject>[];
    _index = 0;
    _computeCurrent();
  }

  RenderObject get current => _current;
  RenderObject _current;
  set current(RenderObject value) {
    if (_current != value) {
      _current = value;
      _currentElement = value.debugCreator.element;
    }
  }

  Element get currentElement => _currentElement;
  Element _currentElement;
  set currentElement(Element element) {
    if (currentElement != element) {
      _currentElement = element;
      _current = element.findRenderObject();
    }
  }

  void _computeCurrent() {
    if (_index < candidates.length) {
      _current = candidates[index];
      _currentElement = _current.debugCreator.element;
    } else {
      _current = null;
      _currentElement = null;
    }
  }

  bool get active => _current != null && _current.attached;
}

class _InspectorOverlay extends LeafRenderObjectWidget {
  const _InspectorOverlay({
    Key key,
    @required this.selection,
  }) : super(key: key);

  final InspectorSelection selection;

  @override
  _RenderInspectorOverlay createRenderObject(BuildContext context) {
    return _RenderInspectorOverlay(selection: selection);
  }

  @override
  void updateRenderObject(
      BuildContext context, _RenderInspectorOverlay renderObject) {
    renderObject.selection = selection;
  }
}

class _RenderInspectorOverlay extends RenderBox {
  _RenderInspectorOverlay({@required InspectorSelection selection})
      : _selection = selection,
        assert(selection != null);

  InspectorSelection get selection => _selection;
  InspectorSelection _selection;
  set selection(InspectorSelection value) {
    if (value != _selection) {
      _selection = value;
    }
    markNeedsPaint();
  }

  @override
  bool get sizedByParent => true;

  @override
  bool get alwaysNeedsCompositing => true;

  @override
  void performResize() {
    size = constraints.constrain(const Size(double.infinity, double.infinity));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    assert(needsCompositing);
    context.addLayer(_InspectorOverlayLayer(
      overlayRect: Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height),
      selection: selection,
    ));
  }
}

class _TransformedRect {
  _TransformedRect(RenderObject object)
      : rect = object.semanticBounds,
        transform = object.getTransformTo(null);

  final Rect rect;
  final Matrix4 transform;

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) return false;
    final _TransformedRect typedOther = other;
    return rect == typedOther.rect && transform == typedOther.transform;
  }

  @override
  int get hashCode => hashValues(rect, transform);
}

class _InspectorOverlayRenderState {
  _InspectorOverlayRenderState({
    @required this.overlayRect,
    @required this.selected,
    @required this.candidates,
    @required this.tooltip,
    @required this.textDirection,
  });

  final Rect overlayRect;
  final _TransformedRect selected;
  final List<_TransformedRect> candidates;
  final String tooltip;
  final TextDirection textDirection;

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) return false;

    final _InspectorOverlayRenderState typedOther = other;
    return overlayRect == typedOther.overlayRect &&
        selected == typedOther.selected &&
        listEquals<_TransformedRect>(candidates, typedOther.candidates) &&
        tooltip == typedOther.tooltip;
  }

  @override
  int get hashCode =>
      hashValues(overlayRect, selected, hashList(candidates), tooltip);
}

const int _kMaxTooltipLines = 5;
const Color _kTooltipBackgroundColor = Color.fromARGB(230, 60, 60, 60);
const Color _kHighlightedRenderObjectFillColor =
    Color.fromARGB(128, 128, 128, 255);
const Color _kHighlightedRenderObjectBorderColor =
    Color.fromARGB(128, 64, 64, 128);

class _InspectorOverlayLayer extends Layer {
  _InspectorOverlayLayer({
    @required this.overlayRect,
    @required this.selection,
  })  : assert(overlayRect != null),
        assert(selection != null) {
    bool inDebugMode = false;
    assert(() {
      inDebugMode = true;
      return true;
    }());
    if (inDebugMode == false) {
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary(
            'The inspector should never be used in production mode due to the '
            'negative performance impact.')
      ]);
    }
  }

  InspectorSelection selection;

  final Rect overlayRect;

  _InspectorOverlayRenderState _lastState;

  ui.Picture _picture;

  TextPainter _textPainter;
  double _textPainterMaxWidth;

  @override
  void addToScene(ui.SceneBuilder builder, [Offset layerOffset = Offset.zero]) {
    if (!selection.active) return;

    final RenderObject selected = selection.current;
    final List<_TransformedRect> candidates = <_TransformedRect>[];
    for (RenderObject candidate in selection.candidates) {
      if (candidate == selected || !candidate.attached) continue;
      candidates.add(_TransformedRect(candidate));
    }

    final _InspectorOverlayRenderState state = _InspectorOverlayRenderState(
      overlayRect: overlayRect,
      selected: _TransformedRect(selected),
      tooltip: selection.currentElement.toStringShort(),
      textDirection: TextDirection.ltr,
      candidates: candidates,
    );

    if (state != _lastState) {
      _lastState = state;
      _picture = _buildPicture(state);
    }
    builder.addPicture(layerOffset, _picture);
  }

  ui.Picture _buildPicture(_InspectorOverlayRenderState state) {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder, state.overlayRect);
    final Size size = state.overlayRect.size;

    final Paint fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = _kHighlightedRenderObjectFillColor;

    final Paint borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = _kHighlightedRenderObjectBorderColor;

    final Rect selectedPaintRect = state.selected.rect.deflate(0.5);
    canvas
      ..save()
      ..transform(state.selected.transform.storage)
      ..drawRect(selectedPaintRect, fillPaint)
      ..drawRect(selectedPaintRect, borderPaint)
      ..restore();

    for (_TransformedRect transformedRect in state.candidates) {
      canvas
        ..save()
        ..transform(transformedRect.transform.storage)
        ..drawRect(transformedRect.rect.deflate(0.5), borderPaint)
        ..restore();
    }

    final Rect targetRect = MatrixUtils.transformRect(
        state.selected.transform, state.selected.rect);
    final Offset target = Offset(targetRect.left, targetRect.center.dy);
    const double offsetFromWidget = 9.0;
    final double verticalOffset = (targetRect.height) / 2 + offsetFromWidget;

    _paintDescription(canvas, state.tooltip, state.textDirection, target,
        verticalOffset, size, targetRect);

    return recorder.endRecording();
  }

  void _paintDescription(
    Canvas canvas,
    String message,
    TextDirection textDirection,
    Offset target,
    double verticalOffset,
    Size size,
    Rect targetRect,
  ) {
    canvas.save();
    final double maxWidth =
        size.width - 2 * (_kScreenEdgeMargin + _kTooltipPadding);
    final TextSpan textSpan = _textPainter?.text;
    if (_textPainter == null ||
        textSpan.text != message ||
        _textPainterMaxWidth != maxWidth) {
      _textPainterMaxWidth = maxWidth;
      _textPainter = TextPainter()
        ..maxLines = _kMaxTooltipLines
        ..ellipsis = '...'
        ..text = TextSpan(style: _messageStyle, text: message)
        ..textDirection = textDirection
        ..layout(maxWidth: maxWidth);
    }

    final Size tooltipSize = _textPainter.size +
        const Offset(_kTooltipPadding * 2, _kTooltipPadding * 2);
    final Offset tipOffset = positionDependentBox(
      size: size,
      childSize: tooltipSize,
      target: target,
      verticalOffset: verticalOffset,
      preferBelow: false,
    );

    final Paint tooltipBackground = Paint()
      ..style = PaintingStyle.fill
      ..color = _kTooltipBackgroundColor;
    canvas.drawRect(
      Rect.fromPoints(
        tipOffset,
        tipOffset.translate(tooltipSize.width, tooltipSize.height),
      ),
      tooltipBackground,
    );

    double wedgeY = tipOffset.dy;
    final bool tooltipBelow = tipOffset.dy > target.dy;
    if (!tooltipBelow) wedgeY += tooltipSize.height;

    const double wedgeSize = _kTooltipPadding * 2;
    double wedgeX = math.max(tipOffset.dx, target.dx) + wedgeSize * 2;
    wedgeX = math.min(wedgeX, tipOffset.dx + tooltipSize.width - wedgeSize * 2);
    final List<Offset> wedge = <Offset>[
      Offset(wedgeX - wedgeSize, wedgeY),
      Offset(wedgeX + wedgeSize, wedgeY),
      Offset(wedgeX, wedgeY + (tooltipBelow ? -wedgeSize : wedgeSize)),
    ];
    canvas.drawPath(
        Path()
          ..addPolygon(
            wedge,
            true,
          ),
        tooltipBackground);
    _textPainter.paint(
        canvas, tipOffset + const Offset(_kTooltipPadding, _kTooltipPadding));
    canvas.restore();
  }

  @override
  S find<S>(Offset regionOffset) => null;

  @override
  Iterable<S> findAll<S>(Offset regionOffset) => <S>[];
}

const double _kScreenEdgeMargin = 10.0;
const double _kTooltipPadding = 5.0;
const double _kInspectButtonMargin = 10.0;

const double _kOffScreenMargin = 1.0;

const TextStyle _messageStyle = TextStyle(
  color: Color(0xFFFFFFFF),
  fontSize: 10.0,
  height: 1.2,
);

abstract class _HasCreationLocation {
  _Location get _location;
}

class _Location {
  const _Location({
    this.file,
    this.line,
    this.column,
    this.name,
    this.parameterLocations,
  });

  final String file;

  final int line;

  final int column;

  final String name;

  final List<_Location> parameterLocations;

  Map<String, Object> toJsonMap() {
    final Map<String, Object> json = <String, Object>{
      'file': file,
      'line': line,
      'column': column,
    };
    if (name != null) {
      json['name'] = name;
    }
    if (parameterLocations != null) {
      json['parameterLocations'] = parameterLocations
          .map<Map<String, Object>>(
              (_Location location) => location.toJsonMap())
          .toList();
    }
    return json;
  }

  @override
  String toString() {
    final List<String> parts = <String>[];
    if (name != null) {
      parts.add(name);
    }
    if (file != null) {
      parts.add(file);
    }
    parts..add('$line')..add('$column');
    return parts.join(':');
  }
}

bool _isDebugCreator(DiagnosticsNode node) => node is DiagnosticsDebugCreator;

Iterable<DiagnosticsNode> transformDebugCreator(
    Iterable<DiagnosticsNode> properties) sync* {
  final List<DiagnosticsNode> pending = <DiagnosticsNode>[];
  bool foundStackTrace = false;
  for (DiagnosticsNode node in properties) {
    if (!foundStackTrace && node is DiagnosticsStackTrace)
      foundStackTrace = true;
    if (_isDebugCreator(node)) {
      yield* _parseDiagnosticsNode(node);
    } else {
      if (foundStackTrace) {
        pending.add(node);
      } else {
        yield node;
      }
    }
  }
  yield* pending;
}

Iterable<DiagnosticsNode> _parseDiagnosticsNode(DiagnosticsNode node) {
  if (!_isDebugCreator(node)) return null;
  final DebugCreator debugCreator = node.value;
  final Element element = debugCreator.element;
  return _describeRelevantUserCode(element);
}

Iterable<DiagnosticsNode> _describeRelevantUserCode(Element element) {
  if (!WidgetInspectorService.instance.isWidgetCreationTracked()) {
    return <DiagnosticsNode>[
      ErrorDescription(
        'Widget creation tracking is currently disabled. Enabling '
        'it enables improved error messages. It can be enabled by passing '
        '`--track-widget-creation` to `flutter run` or `flutter test`.',
      ),
      ErrorSpacer(),
    ];
  }
  final List<DiagnosticsNode> nodes = <DiagnosticsNode>[];
  element.visitAncestorElements((Element ancestor) {
    if (_isLocalCreationLocation(ancestor)) {
      nodes.add(DiagnosticsBlock(
        name: 'User-created ancestor of the error-causing widget was',
        children: <DiagnosticsNode>[
          ErrorDescription(
              '${ancestor.widget.toStringShort()} ${_describeCreationLocation(ancestor)}'),
        ],
      ));
      nodes.add(ErrorSpacer());
      return false;
    }
    return true;
  });
  return nodes;
}

bool _isLocalCreationLocation(Object object) {
  final _Location location = _getCreationLocation(object);
  if (location == null) return false;
  return WidgetInspectorService.instance._isLocalCreationLocation(location);
}

String _describeCreationLocation(Object object) {
  final _Location location = _getCreationLocation(object);
  return location?.toString();
}

_Location _getCreationLocation(Object object) {
  final Object candidate = object is Element ? object.widget : object;
  return candidate is _HasCreationLocation ? candidate._location : null;
}

final Map<_Location, int> _locationToId = <_Location, int>{};
final List<_Location> _locations = <_Location>[];

int _toLocationId(_Location location) {
  int id = _locationToId[location];
  if (id != null) {
    return id;
  }
  id = _locations.length;
  _locations.add(location);
  _locationToId[location] = id;
  return id;
}

class _SerializationDelegate implements DiagnosticsSerializationDelegate {
  _SerializationDelegate({
    this.groupName,
    this.summaryTree = false,
    this.maxDescendentsTruncatableNode = -1,
    this.expandPropertyValues = true,
    this.subtreeDepth = 1,
    this.includeProperties = false,
    @required this.service,
  });

  final WidgetInspectorService service;
  final String groupName;
  final bool summaryTree;
  final int maxDescendentsTruncatableNode;

  @override
  final bool includeProperties;

  @override
  final int subtreeDepth;

  @override
  final bool expandPropertyValues;

  final List<DiagnosticsNode> _nodesCreatedByLocalProject = <DiagnosticsNode>[];

  bool get interactive => groupName != null;

  @override
  Map<String, Object> additionalNodeProperties(DiagnosticsNode node) {
    final Map<String, Object> result = <String, Object>{};
    final Object value = node.value;
    if (interactive) {
      result['objectId'] = service.toId(node, groupName);
      result['valueId'] = service.toId(value, groupName);
    }
    if (summaryTree) {
      result['summaryTree'] = true;
    }
    final _Location creationLocation = _getCreationLocation(value);
    if (creationLocation != null) {
      result['locationId'] = _toLocationId(creationLocation);
      result['creationLocation'] = creationLocation.toJsonMap();
      if (service._isLocalCreationLocation(creationLocation)) {
        _nodesCreatedByLocalProject.add(node);
        result['createdByLocalProject'] = true;
      }
    }
    return result;
  }

  @override
  DiagnosticsSerializationDelegate delegateForNode(DiagnosticsNode node) {
    return summaryTree ||
            subtreeDepth > 1 ||
            service._shouldShowInSummaryTree(node)
        ? copyWith(subtreeDepth: subtreeDepth - 1)
        : this;
  }

  @override
  List<DiagnosticsNode> filterChildren(
      List<DiagnosticsNode> children, DiagnosticsNode owner) {
    return service._filterChildren(children, this);
  }

  @override
  List<DiagnosticsNode> filterProperties(
      List<DiagnosticsNode> properties, DiagnosticsNode owner) {
    final bool createdByLocalProject =
        _nodesCreatedByLocalProject.contains(owner);
    return properties.where((DiagnosticsNode node) {
      return !node.isFiltered(
          createdByLocalProject ? DiagnosticLevel.fine : DiagnosticLevel.info);
    }).toList();
  }

  @override
  List<DiagnosticsNode> truncateNodesList(
      List<DiagnosticsNode> nodes, DiagnosticsNode owner) {
    if (maxDescendentsTruncatableNode >= 0 &&
        owner?.allowTruncate == true &&
        nodes.length > maxDescendentsTruncatableNode) {
      nodes = service._truncateNodes(nodes, maxDescendentsTruncatableNode);
    }
    return nodes;
  }

  @override
  DiagnosticsSerializationDelegate copyWith(
      {int subtreeDepth, bool includeProperties}) {
    return _SerializationDelegate(
      groupName: groupName,
      summaryTree: summaryTree,
      maxDescendentsTruncatableNode: maxDescendentsTruncatableNode,
      expandPropertyValues: expandPropertyValues,
      subtreeDepth: subtreeDepth ?? this.subtreeDepth,
      includeProperties: includeProperties ?? this.includeProperties,
      service: service,
    );
  }
}

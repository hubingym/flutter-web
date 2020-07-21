import 'dart:async';
import 'dart:collection';
import 'package:flutter_web/ui.dart' as ui
    show
        EngineLayer,
        Image,
        ImageFilter,
        PathMetric,
        Picture,
        PictureRecorder,
        Scene,
        SceneBuilder;

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/gestures.dart';
import 'package:flutter_web/painting.dart';
import 'package:vector_math/vector_math_64.dart';

import 'debug.dart';

abstract class Layer extends AbstractNode with DiagnosticableTreeMixin {
  @override
  ContainerLayer get parent => super.parent;

  bool _needsAddToScene = true;

  @protected
  @visibleForTesting
  void markNeedsAddToScene() {
    assert(
      !alwaysNeedsAddToScene,
      '$runtimeType with alwaysNeedsAddToScene set called markNeedsAddToScene.\n'
      'The layer\'s alwaysNeedsAddToScene is set to true, and therefore it should not call markNeedsAddToScene.',
    );

    if (_needsAddToScene) {
      return;
    }

    _needsAddToScene = true;
  }

  @visibleForTesting
  void debugMarkClean() {
    assert(() {
      _needsAddToScene = false;
      return true;
    }());
  }

  @protected
  bool get alwaysNeedsAddToScene => false;

  @visibleForTesting
  bool get debugSubtreeNeedsAddToScene {
    bool result;
    assert(() {
      result = _needsAddToScene;
      return true;
    }());
    return result;
  }

  @protected
  ui.EngineLayer get engineLayer => _engineLayer;

  @protected
  set engineLayer(ui.EngineLayer value) {
    _engineLayer = value;
    if (!alwaysNeedsAddToScene) {
      if (parent != null && !parent.alwaysNeedsAddToScene) {
        parent.markNeedsAddToScene();
      }
    }
  }

  ui.EngineLayer _engineLayer;

  @protected
  @visibleForTesting
  void updateSubtreeNeedsAddToScene() {
    _needsAddToScene = _needsAddToScene || alwaysNeedsAddToScene;
  }

  Layer get nextSibling => _nextSibling;
  Layer _nextSibling;

  Layer get previousSibling => _previousSibling;
  Layer _previousSibling;

  @override
  void dropChild(AbstractNode child) {
    if (!alwaysNeedsAddToScene) {
      markNeedsAddToScene();
    }
    super.dropChild(child);
  }

  @override
  void adoptChild(AbstractNode child) {
    if (!alwaysNeedsAddToScene) {
      markNeedsAddToScene();
    }
    super.adoptChild(child);
  }

  @mustCallSuper
  void remove() {
    parent?._removeChild(this);
  }

  S find<S>(Offset regionOffset);

  Iterable<S> findAll<S>(Offset regionOffset);

  @protected
  void addToScene(ui.SceneBuilder builder, [Offset layerOffset = Offset.zero]);

  void _addToSceneWithRetainedRendering(ui.SceneBuilder builder) {
    if (!_needsAddToScene && _engineLayer != null) {
      builder.addRetained(_engineLayer);
      return;
    }
    addToScene(builder);

    _needsAddToScene = false;
  }

  dynamic debugCreator;

  @override
  String toStringShort() =>
      '${super.toStringShort()}${owner == null ? " DETACHED" : ""}';

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Object>('owner', owner,
        level: parent != null ? DiagnosticLevel.hidden : DiagnosticLevel.info,
        defaultValue: null));
    properties.add(DiagnosticsProperty<dynamic>('creator', debugCreator,
        defaultValue: null, level: DiagnosticLevel.debug));
  }
}

class PictureLayer extends Layer {
  PictureLayer(this.canvasBounds);

  final Rect canvasBounds;

  ui.Picture get picture => _picture;
  ui.Picture _picture;
  set picture(ui.Picture picture) {
    markNeedsAddToScene();
    _picture = picture;
  }

  bool get isComplexHint => _isComplexHint;
  bool _isComplexHint = false;
  set isComplexHint(bool value) {
    if (value != _isComplexHint) {
      _isComplexHint = value;
      markNeedsAddToScene();
    }
  }

  bool get willChangeHint => _willChangeHint;
  bool _willChangeHint = false;
  set willChangeHint(bool value) {
    if (value != _willChangeHint) {
      _willChangeHint = value;
      markNeedsAddToScene();
    }
  }

  @override
  void addToScene(ui.SceneBuilder builder, [Offset layerOffset = Offset.zero]) {
    builder.addPicture(layerOffset, picture,
        isComplexHint: isComplexHint, willChangeHint: willChangeHint);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Rect>('paint bounds', canvasBounds));
  }

  @override
  S find<S>(Offset regionOffset) => null;

  @override
  Iterable<S> findAll<S>(Offset regionOffset) => <S>[];
}

class TextureLayer extends Layer {
  TextureLayer({
    @required this.rect,
    @required this.textureId,
    this.freeze = false,
  })  : assert(rect != null),
        assert(textureId != null);

  final Rect rect;

  final int textureId;

  final bool freeze;

  @override
  void addToScene(ui.SceneBuilder builder, [Offset layerOffset = Offset.zero]) {
    final Rect shiftedRect =
        layerOffset == Offset.zero ? rect : rect.shift(layerOffset);
    builder.addTexture(
      textureId,
      offset: shiftedRect.topLeft,
      width: shiftedRect.width,
      height: shiftedRect.height,
      freeze: freeze,
    );
  }

  @override
  S find<S>(Offset regionOffset) => null;

  @override
  Iterable<S> findAll<S>(Offset regionOffset) => <S>[];
}

class PlatformViewLayer extends Layer {
  PlatformViewLayer({
    @required this.rect,
    @required this.viewId,
  })  : assert(rect != null),
        assert(viewId != null);

  final Rect rect;

  final int viewId;

  @override
  void addToScene(ui.SceneBuilder builder, [Offset layerOffset = Offset.zero]) {
    final Rect shiftedRect =
        layerOffset == Offset.zero ? rect : rect.shift(layerOffset);
    builder.addPlatformView(
      viewId,
      offset: shiftedRect.topLeft,
      width: shiftedRect.width,
      height: shiftedRect.height,
    );
  }

  @override
  S find<S>(Offset regionOffset) => null;

  @override
  Iterable<S> findAll<S>(Offset regionOffset) => <S>[];
}

class PerformanceOverlayLayer extends Layer {
  PerformanceOverlayLayer({
    @required Rect overlayRect,
    @required this.optionsMask,
    @required this.rasterizerThreshold,
    @required this.checkerboardRasterCacheImages,
    @required this.checkerboardOffscreenLayers,
  }) : _overlayRect = overlayRect;

  Rect get overlayRect => _overlayRect;
  Rect _overlayRect;
  set overlayRect(Rect value) {
    if (value != _overlayRect) {
      _overlayRect = value;
      markNeedsAddToScene();
    }
  }

  final int optionsMask;

  final int rasterizerThreshold;

  final bool checkerboardRasterCacheImages;

  final bool checkerboardOffscreenLayers;

  @override
  void addToScene(ui.SceneBuilder builder, [Offset layerOffset = Offset.zero]) {
    assert(optionsMask != null);
    final Rect shiftedOverlayRect = layerOffset == Offset.zero
        ? overlayRect
        : overlayRect.shift(layerOffset);
    builder.addPerformanceOverlay(optionsMask, shiftedOverlayRect);
    builder.setRasterizerTracingThreshold(rasterizerThreshold);
    builder.setCheckerboardRasterCacheImages(checkerboardRasterCacheImages);
    builder.setCheckerboardOffscreenLayers(checkerboardOffscreenLayers);
  }

  @override
  S find<S>(Offset regionOffset) => null;

  @override
  Iterable<S> findAll<S>(Offset regionOffset) => <S>[];
}

class ContainerLayer extends Layer {
  Layer get firstChild => _firstChild;
  Layer _firstChild;

  Layer get lastChild => _lastChild;
  Layer _lastChild;

  bool get hasChildren => _firstChild != null;

  ui.Scene buildScene(ui.SceneBuilder builder) {
    List<PictureLayer> temporaryLayers;
    assert(() {
      if (debugCheckElevationsEnabled) {
        temporaryLayers = _debugCheckElevations();
      }
      return true;
    }());
    updateSubtreeNeedsAddToScene();
    addToScene(builder);

    _needsAddToScene = false;
    final ui.Scene scene = builder.build();
    assert(() {
      if (temporaryLayers != null) {
        for (PictureLayer temporaryLayer in temporaryLayers) {
          temporaryLayer.remove();
        }
      }
      return true;
    }());
    return scene;
  }

  bool _debugUltimatePreviousSiblingOf(Layer child, {Layer equals}) {
    assert(child.attached == attached);
    while (child.previousSibling != null) {
      assert(child.previousSibling != child);
      child = child.previousSibling;
      assert(child.attached == attached);
    }
    return child == equals;
  }

  bool _debugUltimateNextSiblingOf(Layer child, {Layer equals}) {
    assert(child.attached == attached);
    while (child._nextSibling != null) {
      assert(child._nextSibling != child);
      child = child._nextSibling;
      assert(child.attached == attached);
    }
    return child == equals;
  }

  PictureLayer _highlightConflictingLayer(PhysicalModelLayer child) {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    canvas.drawPath(
      child.clipPath,
      Paint()
        ..color = const Color(0xFFAA0000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = child.elevation + 10.0,
    );
    final PictureLayer pictureLayer = PictureLayer(child.clipPath.getBounds())
      ..picture = recorder.endRecording()
      ..debugCreator = child;
    child.append(pictureLayer);
    return pictureLayer;
  }

  List<PictureLayer> _processConflictingPhysicalLayers(
      PhysicalModelLayer predecessor, PhysicalModelLayer child) {
    FlutterError.reportError(FlutterErrorDetails(
        exception: FlutterError(
            'Painting order is out of order with respect to elevation.\n'
            'See https://api.flutter.dev/flutter/rendering/debugCheckElevationsEnabled.html '
            'for more details.'),
        library: 'rendering library',
        context: ErrorDescription('during compositing'),
        informationCollector: () {
          return <DiagnosticsNode>[
            child.toDiagnosticsNode(
                name: 'Attempted to composite layer',
                style: DiagnosticsTreeStyle.errorProperty),
            predecessor.toDiagnosticsNode(
                name: 'after layer', style: DiagnosticsTreeStyle.errorProperty),
            ErrorDescription(
                'which occupies the same area at a higher elevation.'),
          ];
        }));
    return <PictureLayer>[
      _highlightConflictingLayer(predecessor),
      _highlightConflictingLayer(child),
    ];
  }

  List<PictureLayer> _debugCheckElevations() {
    final List<PhysicalModelLayer> physicalModelLayers =
        depthFirstIterateChildren().whereType<PhysicalModelLayer>().toList();
    final List<PictureLayer> addedLayers = <PictureLayer>[];

    for (int i = 0; i < physicalModelLayers.length; i++) {
      final PhysicalModelLayer physicalModelLayer = physicalModelLayers[i];
      assert(
        physicalModelLayer.lastChild?.debugCreator != physicalModelLayer,
        'debugCheckElevations has either already visited this layer or failed '
        'to remove the added picture from it.',
      );
      double accumulatedElevation = physicalModelLayer.elevation;
      Layer ancestor = physicalModelLayer.parent;
      while (ancestor != null) {
        if (ancestor is PhysicalModelLayer) {
          accumulatedElevation += ancestor.elevation;
        }
        ancestor = ancestor.parent;
      }
      for (int j = 0; j <= i; j++) {
        final PhysicalModelLayer predecessor = physicalModelLayers[j];
        double predecessorAccumulatedElevation = predecessor.elevation;
        ancestor = predecessor.parent;
        while (ancestor != null) {
          if (ancestor == predecessor) {
            continue;
          }
          if (ancestor is PhysicalModelLayer) {
            predecessorAccumulatedElevation += ancestor.elevation;
          }
          ancestor = ancestor.parent;
        }
        if (predecessorAccumulatedElevation <= accumulatedElevation) {
          continue;
        }
        final Path intersection = Path.combine(
          PathOperation.intersect,
          predecessor._debugTransformedClipPath,
          physicalModelLayer._debugTransformedClipPath,
        );
        if (intersection != null &&
            intersection
                .computeMetrics()
                .any((ui.PathMetric metric) => metric.length > 0)) {
          addedLayers.addAll(_processConflictingPhysicalLayers(
              predecessor, physicalModelLayer));
        }
      }
    }
    return addedLayers;
  }

  @override
  void updateSubtreeNeedsAddToScene() {
    super.updateSubtreeNeedsAddToScene();
    Layer child = firstChild;
    while (child != null) {
      child.updateSubtreeNeedsAddToScene();
      _needsAddToScene = _needsAddToScene || child._needsAddToScene;
      child = child.nextSibling;
    }
  }

  @override
  S find<S>(Offset regionOffset) {
    Layer current = lastChild;
    while (current != null) {
      final Object value = current.find<S>(regionOffset);
      if (value != null) {
        return value;
      }
      current = current.previousSibling;
    }
    return null;
  }

  @override
  Iterable<S> findAll<S>(Offset regionOffset) {
    Iterable<S> result = Iterable<S>.empty();
    if (firstChild == null) return result;
    Layer child = lastChild;
    while (true) {
      result = result.followedBy(child.findAll<S>(regionOffset));
      if (child == firstChild) break;
      child = child.previousSibling;
    }
    return result;
  }

  @override
  void attach(Object owner) {
    super.attach(owner);
    Layer child = firstChild;
    while (child != null) {
      child.attach(owner);
      child = child.nextSibling;
    }
  }

  @override
  void detach() {
    super.detach();
    Layer child = firstChild;
    while (child != null) {
      child.detach();
      child = child.nextSibling;
    }
  }

  void append(Layer child) {
    assert(child != this);
    assert(child != firstChild);
    assert(child != lastChild);
    assert(child.parent == null);
    assert(!child.attached);
    assert(child.nextSibling == null);
    assert(child.previousSibling == null);
    assert(() {
      Layer node = this;
      while (node.parent != null) node = node.parent;
      assert(node != child);
      return true;
    }());
    adoptChild(child);
    child._previousSibling = lastChild;
    if (lastChild != null) lastChild._nextSibling = child;
    _lastChild = child;
    _firstChild ??= child;
    assert(child.attached == attached);
  }

  void _removeChild(Layer child) {
    assert(child.parent == this);
    assert(child.attached == attached);
    assert(_debugUltimatePreviousSiblingOf(child, equals: firstChild));
    assert(_debugUltimateNextSiblingOf(child, equals: lastChild));
    if (child._previousSibling == null) {
      assert(_firstChild == child);
      _firstChild = child._nextSibling;
    } else {
      child._previousSibling._nextSibling = child.nextSibling;
    }
    if (child._nextSibling == null) {
      assert(lastChild == child);
      _lastChild = child.previousSibling;
    } else {
      child.nextSibling._previousSibling = child.previousSibling;
    }
    assert((firstChild == null) == (lastChild == null));
    assert(firstChild == null || firstChild.attached == attached);
    assert(lastChild == null || lastChild.attached == attached);
    assert(firstChild == null ||
        _debugUltimateNextSiblingOf(firstChild, equals: lastChild));
    assert(lastChild == null ||
        _debugUltimatePreviousSiblingOf(lastChild, equals: firstChild));
    child._previousSibling = null;
    child._nextSibling = null;
    dropChild(child);
    assert(!child.attached);
  }

  void removeAllChildren() {
    Layer child = firstChild;
    while (child != null) {
      final Layer next = child.nextSibling;
      child._previousSibling = null;
      child._nextSibling = null;
      assert(child.attached == attached);
      dropChild(child);
      child = next;
    }
    _firstChild = null;
    _lastChild = null;
  }

  @override
  void addToScene(ui.SceneBuilder builder, [Offset layerOffset = Offset.zero]) {
    addChildrenToScene(builder, layerOffset);
  }

  void addChildrenToScene(ui.SceneBuilder builder,
      [Offset childOffset = Offset.zero]) {
    Layer child = firstChild;
    while (child != null) {
      if (childOffset == Offset.zero) {
        child._addToSceneWithRetainedRendering(builder);
      } else {
        child.addToScene(builder, childOffset);
      }
      child = child.nextSibling;
    }
  }

  void applyTransform(Layer child, Matrix4 transform) {
    assert(child != null);
    assert(transform != null);
  }

  @visibleForTesting
  List<Layer> depthFirstIterateChildren() {
    if (firstChild == null) return <Layer>[];
    final List<Layer> children = <Layer>[];
    Layer child = firstChild;
    while (child != null) {
      children.add(child);
      if (child is ContainerLayer) {
        children.addAll(child.depthFirstIterateChildren());
      }
      child = child.nextSibling;
    }
    return children;
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    final List<DiagnosticsNode> children = <DiagnosticsNode>[];
    if (firstChild == null) return children;
    Layer child = firstChild;
    int count = 1;
    while (true) {
      children.add(child.toDiagnosticsNode(name: 'child $count'));
      if (child == lastChild) break;
      count += 1;
      child = child.nextSibling;
    }
    return children;
  }
}

class OffsetLayer extends ContainerLayer {
  OffsetLayer({Offset offset = Offset.zero}) : _offset = offset;

  Offset get offset => _offset;
  Offset _offset;
  set offset(Offset value) {
    if (value != _offset) {
      markNeedsAddToScene();
    }
    _offset = value;
  }

  @override
  S find<S>(Offset regionOffset) {
    return super.find<S>(regionOffset - offset);
  }

  @override
  Iterable<S> findAll<S>(Offset regionOffset) {
    return super.findAll<S>(regionOffset - offset);
  }

  @override
  void applyTransform(Layer child, Matrix4 transform) {
    assert(child != null);
    assert(transform != null);
    transform.multiply(Matrix4.translationValues(offset.dx, offset.dy, 0.0));
  }

  @override
  void addToScene(ui.SceneBuilder builder, [Offset layerOffset = Offset.zero]) {
    engineLayer = builder.pushOffset(
        layerOffset.dx + offset.dx, layerOffset.dy + offset.dy,
        oldLayer: _engineLayer);
    addChildrenToScene(builder);
    builder.pop();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Offset>('offset', offset));
  }

  Future<ui.Image> toImage(Rect bounds, {double pixelRatio = 1.0}) async {
    assert(bounds != null);
    assert(pixelRatio != null);
    final ui.SceneBuilder builder = ui.SceneBuilder();
    final Matrix4 transform = Matrix4.translationValues(
      (-bounds.left - offset.dx) * pixelRatio,
      (-bounds.top - offset.dy) * pixelRatio,
      0.0,
    );
    transform.scale(pixelRatio, pixelRatio);
    builder.pushTransform(transform.storage);
    final ui.Scene scene = buildScene(builder);

    try {
      return await scene.toImage(
        (pixelRatio * bounds.width).ceil(),
        (pixelRatio * bounds.height).ceil(),
      );
    } finally {
      scene.dispose();
    }
  }
}

class ClipRectLayer extends ContainerLayer {
  ClipRectLayer({
    Rect clipRect,
    Clip clipBehavior = Clip.hardEdge,
  })  : _clipRect = clipRect,
        _clipBehavior = clipBehavior,
        assert(clipBehavior != null),
        assert(clipBehavior != Clip.none);

  Rect get clipRect => _clipRect;
  Rect _clipRect;
  set clipRect(Rect value) {
    if (value != _clipRect) {
      _clipRect = value;
      markNeedsAddToScene();
    }
  }

  Clip get clipBehavior => _clipBehavior;
  Clip _clipBehavior;
  set clipBehavior(Clip value) {
    assert(value != null);
    assert(value != Clip.none);
    if (value != _clipBehavior) {
      _clipBehavior = value;
      markNeedsAddToScene();
    }
  }

  @override
  S find<S>(Offset regionOffset) {
    if (!clipRect.contains(regionOffset)) return null;
    return super.find<S>(regionOffset);
  }

  @override
  Iterable<S> findAll<S>(Offset regionOffset) {
    if (!clipRect.contains(regionOffset)) return Iterable<S>.empty();
    return super.findAll<S>(regionOffset);
  }

  @override
  void addToScene(ui.SceneBuilder builder, [Offset layerOffset = Offset.zero]) {
    assert(clipRect != null);
    assert(clipBehavior != null);
    bool enabled = true;
    assert(() {
      enabled = !debugDisableClipLayers;
      return true;
    }());
    if (enabled) {
      final Rect shiftedClipRect =
          layerOffset == Offset.zero ? clipRect : clipRect.shift(layerOffset);
      engineLayer = builder.pushClipRect(shiftedClipRect,
          clipBehavior: clipBehavior, oldLayer: _engineLayer);
    } else {
      engineLayer = null;
    }
    addChildrenToScene(builder, layerOffset);
    if (enabled) builder.pop();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Rect>('clipRect', clipRect));
  }
}

class ClipRRectLayer extends ContainerLayer {
  ClipRRectLayer({
    RRect clipRRect,
    Clip clipBehavior = Clip.antiAlias,
  })  : _clipRRect = clipRRect,
        _clipBehavior = clipBehavior,
        assert(clipBehavior != null),
        assert(clipBehavior != Clip.none);

  RRect get clipRRect => _clipRRect;
  RRect _clipRRect;
  set clipRRect(RRect value) {
    if (value != _clipRRect) {
      _clipRRect = value;
      markNeedsAddToScene();
    }
  }

  Clip get clipBehavior => _clipBehavior;
  Clip _clipBehavior;
  set clipBehavior(Clip value) {
    assert(value != null);
    assert(value != Clip.none);
    if (value != _clipBehavior) {
      _clipBehavior = value;
      markNeedsAddToScene();
    }
  }

  @override
  S find<S>(Offset regionOffset) {
    if (!clipRRect.contains(regionOffset)) return null;
    return super.find<S>(regionOffset);
  }

  @override
  Iterable<S> findAll<S>(Offset regionOffset) {
    if (!clipRRect.contains(regionOffset)) return Iterable<S>.empty();
    return super.findAll<S>(regionOffset);
  }

  @override
  void addToScene(ui.SceneBuilder builder, [Offset layerOffset = Offset.zero]) {
    assert(clipRRect != null);
    assert(clipBehavior != null);
    bool enabled = true;
    assert(() {
      enabled = !debugDisableClipLayers;
      return true;
    }());
    if (enabled) {
      final RRect shiftedClipRRect =
          layerOffset == Offset.zero ? clipRRect : clipRRect.shift(layerOffset);
      engineLayer = builder.pushClipRRect(shiftedClipRRect,
          clipBehavior: clipBehavior, oldLayer: _engineLayer);
    } else {
      engineLayer = null;
    }
    addChildrenToScene(builder, layerOffset);
    if (enabled) builder.pop();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<RRect>('clipRRect', clipRRect));
  }
}

class ClipPathLayer extends ContainerLayer {
  ClipPathLayer({
    Path clipPath,
    Clip clipBehavior = Clip.antiAlias,
  })  : _clipPath = clipPath,
        _clipBehavior = clipBehavior,
        assert(clipBehavior != null),
        assert(clipBehavior != Clip.none);

  Path get clipPath => _clipPath;
  Path _clipPath;
  set clipPath(Path value) {
    if (value != _clipPath) {
      _clipPath = value;
      markNeedsAddToScene();
    }
  }

  Clip get clipBehavior => _clipBehavior;
  Clip _clipBehavior;
  set clipBehavior(Clip value) {
    assert(value != null);
    assert(value != Clip.none);
    if (value != _clipBehavior) {
      _clipBehavior = value;
      markNeedsAddToScene();
    }
  }

  @override
  S find<S>(Offset regionOffset) {
    if (!clipPath.contains(regionOffset)) return null;
    return super.find<S>(regionOffset);
  }

  @override
  Iterable<S> findAll<S>(Offset regionOffset) {
    if (!clipPath.contains(regionOffset)) return Iterable<S>.empty();
    return super.findAll<S>(regionOffset);
  }

  @override
  void addToScene(ui.SceneBuilder builder, [Offset layerOffset = Offset.zero]) {
    assert(clipPath != null);
    assert(clipBehavior != null);
    bool enabled = true;
    assert(() {
      enabled = !debugDisableClipLayers;
      return true;
    }());
    if (enabled) {
      final Path shiftedPath =
          layerOffset == Offset.zero ? clipPath : clipPath.shift(layerOffset);
      engineLayer = builder.pushClipPath(shiftedPath,
          clipBehavior: clipBehavior, oldLayer: _engineLayer);
    } else {
      engineLayer = null;
    }
    addChildrenToScene(builder, layerOffset);
    if (enabled) builder.pop();
  }
}

class ColorFilterLayer extends ContainerLayer {
  ColorFilterLayer({
    ColorFilter colorFilter,
  }) : _colorFilter = colorFilter;

  ColorFilter get colorFilter => _colorFilter;
  ColorFilter _colorFilter;
  set colorFilter(ColorFilter value) {
    assert(value != null);
    if (value != _colorFilter) {
      _colorFilter = value;
      markNeedsAddToScene();
    }
  }

  @override
  void addToScene(ui.SceneBuilder builder, [Offset layerOffset = Offset.zero]) {
    assert(colorFilter != null);
    engineLayer = builder.pushColorFilter(colorFilter, oldLayer: _engineLayer);
    addChildrenToScene(builder, layerOffset);
    builder.pop();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(DiagnosticsProperty<ColorFilter>('colorFilter', colorFilter));
  }
}

class TransformLayer extends OffsetLayer {
  TransformLayer({Matrix4 transform, Offset offset = Offset.zero})
      : _transform = transform,
        super(offset: offset);

  Matrix4 get transform => _transform;
  Matrix4 _transform;
  set transform(Matrix4 value) {
    assert(value != null);
    assert(value.storage.every((double component) => component.isFinite));
    if (value == _transform) return;
    _transform = value;
    _inverseDirty = true;
    markNeedsAddToScene();
  }

  Matrix4 _lastEffectiveTransform;
  Matrix4 _invertedTransform;
  bool _inverseDirty = true;

  @override
  void addToScene(ui.SceneBuilder builder, [Offset layerOffset = Offset.zero]) {
    assert(transform != null);
    _lastEffectiveTransform = transform;
    final Offset totalOffset = offset + layerOffset;
    if (totalOffset != Offset.zero) {
      _lastEffectiveTransform =
          Matrix4.translationValues(totalOffset.dx, totalOffset.dy, 0.0)
            ..multiply(_lastEffectiveTransform);
    }
    engineLayer = builder.pushTransform(_lastEffectiveTransform.storage,
        oldLayer: _engineLayer);
    addChildrenToScene(builder);
    builder.pop();
  }

  Offset _transformOffset(Offset regionOffset) {
    if (_inverseDirty) {
      _invertedTransform =
          Matrix4.tryInvert(PointerEvent.removePerspectiveTransform(transform));
      _inverseDirty = false;
    }
    if (_invertedTransform == null) return null;
    final Vector4 vector = Vector4(regionOffset.dx, regionOffset.dy, 0.0, 1.0);
    final Vector4 result = _invertedTransform.transform(vector);
    return Offset(result[0], result[1]);
  }

  @override
  S find<S>(Offset regionOffset) {
    final Offset transformedOffset = _transformOffset(regionOffset);
    return transformedOffset == null ? null : super.find<S>(transformedOffset);
  }

  @override
  Iterable<S> findAll<S>(Offset regionOffset) {
    final Offset transformedOffset = _transformOffset(regionOffset);
    if (transformedOffset == null) {
      return Iterable<S>.empty();
    }
    return super.findAll<S>(transformedOffset);
  }

  @override
  void applyTransform(Layer child, Matrix4 transform) {
    assert(child != null);
    assert(transform != null);
    assert(_lastEffectiveTransform != null || this.transform != null);
    if (_lastEffectiveTransform == null) {
      transform.multiply(this.transform);
    } else {
      transform.multiply(_lastEffectiveTransform);
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(TransformProperty('transform', transform));
  }
}

class OpacityLayer extends ContainerLayer {
  OpacityLayer({
    int alpha,
    Offset offset = Offset.zero,
  })  : _alpha = alpha,
        _offset = offset;

  int get alpha => _alpha;
  int _alpha;
  set alpha(int value) {
    assert(value != null);
    if (value != _alpha) {
      _alpha = value;
      markNeedsAddToScene();
    }
  }

  Offset get offset => _offset;
  Offset _offset;
  set offset(Offset value) {
    if (value != _offset) {
      _offset = value;
      markNeedsAddToScene();
    }
  }

  @override
  void applyTransform(Layer child, Matrix4 transform) {
    assert(child != null);
    assert(transform != null);
    transform.translate(offset.dx, offset.dy);
  }

  @override
  void addToScene(ui.SceneBuilder builder, [Offset layerOffset = Offset.zero]) {
    assert(alpha != null);
    bool enabled = firstChild != null;
    assert(() {
      enabled = enabled && !debugDisableOpacityLayers;
      return true;
    }());

    if (enabled)
      engineLayer = builder.pushOpacity(alpha,
          offset: offset + layerOffset, oldLayer: _engineLayer);
    else
      engineLayer = null;
    addChildrenToScene(builder);
    if (enabled) builder.pop();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('alpha', alpha));
    properties.add(DiagnosticsProperty<Offset>('offset', offset));
  }
}

class ShaderMaskLayer extends ContainerLayer {
  ShaderMaskLayer({
    Shader shader,
    Rect maskRect,
    BlendMode blendMode,
  })  : _shader = shader,
        _maskRect = maskRect,
        _blendMode = blendMode;

  Shader get shader => _shader;
  Shader _shader;
  set shader(Shader value) {
    if (value != _shader) {
      _shader = value;
      markNeedsAddToScene();
    }
  }

  Rect get maskRect => _maskRect;
  Rect _maskRect;
  set maskRect(Rect value) {
    if (value != _maskRect) {
      _maskRect = value;
      markNeedsAddToScene();
    }
  }

  BlendMode get blendMode => _blendMode;
  BlendMode _blendMode;
  set blendMode(BlendMode value) {
    if (value != _blendMode) {
      _blendMode = value;
      markNeedsAddToScene();
    }
  }

  @override
  void addToScene(ui.SceneBuilder builder, [Offset layerOffset = Offset.zero]) {
    assert(shader != null);
    assert(maskRect != null);
    assert(blendMode != null);
    final Rect shiftedMaskRect =
        layerOffset == Offset.zero ? maskRect : maskRect.shift(layerOffset);
    engineLayer = builder.pushShaderMask(shader, shiftedMaskRect, blendMode,
        oldLayer: _engineLayer);
    addChildrenToScene(builder, layerOffset);
    builder.pop();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Shader>('shader', shader));
    properties.add(DiagnosticsProperty<Rect>('maskRect', maskRect));
    properties.add(DiagnosticsProperty<BlendMode>('blendMode', blendMode));
  }
}

class BackdropFilterLayer extends ContainerLayer {
  BackdropFilterLayer({ui.ImageFilter filter}) : _filter = filter;

  ui.ImageFilter get filter => _filter;
  ui.ImageFilter _filter;
  set filter(ui.ImageFilter value) {
    if (value != _filter) {
      _filter = value;
      markNeedsAddToScene();
    }
  }

  @override
  void addToScene(ui.SceneBuilder builder, [Offset layerOffset = Offset.zero]) {
    assert(filter != null);
    engineLayer = builder.pushBackdropFilter(filter, oldLayer: _engineLayer);
    addChildrenToScene(builder, layerOffset);
    builder.pop();
  }
}

class PhysicalModelLayer extends ContainerLayer {
  PhysicalModelLayer({
    Path clipPath,
    Clip clipBehavior = Clip.none,
    double elevation,
    Color color,
    Color shadowColor,
  })  : _clipPath = clipPath,
        _clipBehavior = clipBehavior,
        _elevation = elevation,
        _color = color,
        _shadowColor = shadowColor;

  Path get clipPath => _clipPath;
  Path _clipPath;
  set clipPath(Path value) {
    if (value != _clipPath) {
      _clipPath = value;
      markNeedsAddToScene();
    }
  }

  Path get _debugTransformedClipPath {
    ContainerLayer ancestor = parent;
    final Matrix4 matrix = Matrix4.identity();
    while (ancestor != null && ancestor.parent != null) {
      ancestor.applyTransform(this, matrix);
      ancestor = ancestor.parent;
    }
    return clipPath.transform(matrix.storage);
  }

  Clip get clipBehavior => _clipBehavior;
  Clip _clipBehavior;
  set clipBehavior(Clip value) {
    assert(value != null);
    if (value != _clipBehavior) {
      _clipBehavior = value;
      markNeedsAddToScene();
    }
  }

  double get elevation => _elevation;
  double _elevation;
  set elevation(double value) {
    if (value != _elevation) {
      _elevation = value;
      markNeedsAddToScene();
    }
  }

  Color get color => _color;
  Color _color;
  set color(Color value) {
    if (value != _color) {
      _color = value;
      markNeedsAddToScene();
    }
  }

  Color get shadowColor => _shadowColor;
  Color _shadowColor;
  set shadowColor(Color value) {
    if (value != _shadowColor) {
      _shadowColor = value;
      markNeedsAddToScene();
    }
  }

  @override
  S find<S>(Offset regionOffset) {
    if (!clipPath.contains(regionOffset)) return null;
    return super.find<S>(regionOffset);
  }

  @override
  Iterable<S> findAll<S>(Offset regionOffset) {
    if (!clipPath.contains(regionOffset)) return Iterable<S>.empty();
    return super.findAll<S>(regionOffset);
  }

  @override
  void addToScene(ui.SceneBuilder builder, [Offset layerOffset = Offset.zero]) {
    assert(clipPath != null);
    assert(clipBehavior != null);
    assert(elevation != null);
    assert(color != null);
    assert(shadowColor != null);

    bool enabled = true;
    assert(() {
      enabled = !debugDisablePhysicalShapeLayers;
      return true;
    }());
    if (enabled) {
      engineLayer = builder.pushPhysicalShape(
        path:
            layerOffset == Offset.zero ? clipPath : clipPath.shift(layerOffset),
        elevation: elevation,
        color: color,
        shadowColor: shadowColor,
        clipBehavior: clipBehavior,
        oldLayer: _engineLayer,
      );
    } else {
      engineLayer = null;
    }
    addChildrenToScene(builder, layerOffset);
    if (enabled) builder.pop();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('elevation', elevation));
    properties.add(ColorProperty('color', color));
  }
}

class LayerLink {
  LeaderLayer get leader => _leader;
  LeaderLayer _leader;

  @override
  String toString() =>
      '${describeIdentity(this)}(${_leader != null ? "<linked>" : "<dangling>"})';
}

class LeaderLayer extends ContainerLayer {
  LeaderLayer({@required LayerLink link, this.offset = Offset.zero})
      : assert(link != null),
        _link = link;

  LayerLink get link => _link;
  set link(LayerLink value) {
    assert(value != null);
    _link = value;
  }

  LayerLink _link;

  Offset offset;

  @override
  bool get alwaysNeedsAddToScene => true;

  @override
  void attach(Object owner) {
    super.attach(owner);
    assert(link.leader == null);
    _lastOffset = null;
    link._leader = this;
  }

  @override
  void detach() {
    assert(link.leader == this);
    link._leader = null;
    _lastOffset = null;
    super.detach();
  }

  Offset _lastOffset;

  @override
  S find<S>(Offset regionOffset) => super.find<S>(regionOffset - offset);

  @override
  Iterable<S> findAll<S>(Offset regionOffset) =>
      super.findAll<S>(regionOffset - offset);

  @override
  void addToScene(ui.SceneBuilder builder, [Offset layerOffset = Offset.zero]) {
    assert(offset != null);
    _lastOffset = offset + layerOffset;
    if (_lastOffset != Offset.zero)
      engineLayer = builder.pushTransform(
          Matrix4.translationValues(_lastOffset.dx, _lastOffset.dy, 0.0)
              .storage,
          oldLayer: _engineLayer);
    addChildrenToScene(builder);
    if (_lastOffset != Offset.zero) builder.pop();
  }

  @override
  void applyTransform(Layer child, Matrix4 transform) {
    assert(_lastOffset != null);
    if (_lastOffset != Offset.zero)
      transform.translate(_lastOffset.dx, _lastOffset.dy);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Offset>('offset', offset));
    properties.add(DiagnosticsProperty<LayerLink>('link', link));
  }
}

class FollowerLayer extends ContainerLayer {
  FollowerLayer({
    @required LayerLink link,
    this.showWhenUnlinked = true,
    this.unlinkedOffset = Offset.zero,
    this.linkedOffset = Offset.zero,
  })  : assert(link != null),
        _link = link;

  LayerLink get link => _link;
  set link(LayerLink value) {
    assert(value != null);
    _link = value;
  }

  LayerLink _link;

  bool showWhenUnlinked;

  Offset unlinkedOffset;

  Offset linkedOffset;

  Offset _lastOffset;
  Matrix4 _lastTransform;
  Matrix4 _invertedTransform;
  bool _inverseDirty = true;

  Offset _transformOffset<S>(Offset regionOffset) {
    if (_inverseDirty) {
      _invertedTransform = Matrix4.tryInvert(getLastTransform());
      _inverseDirty = false;
    }
    if (_invertedTransform == null) return null;
    final Vector4 vector = Vector4(regionOffset.dx, regionOffset.dy, 0.0, 1.0);
    final Vector4 result = _invertedTransform.transform(vector);
    return Offset(result[0] - linkedOffset.dx, result[1] - linkedOffset.dy);
  }

  @override
  S find<S>(Offset regionOffset) {
    if (link.leader == null) {
      return showWhenUnlinked
          ? super.find<S>(regionOffset - unlinkedOffset)
          : null;
    }
    final Offset transformedOffset = _transformOffset<S>(regionOffset);
    return transformedOffset == null ? null : super.find<S>(transformedOffset);
  }

  @override
  Iterable<S> findAll<S>(Offset regionOffset) {
    if (link.leader == null) {
      return showWhenUnlinked
          ? super.findAll<S>(regionOffset - unlinkedOffset)
          : <S>[];
    }
    final Offset transformedOffset = _transformOffset<S>(regionOffset);
    if (transformedOffset == null) {
      return <S>[];
    }
    return super.findAll<S>(transformedOffset);
  }

  Matrix4 getLastTransform() {
    if (_lastTransform == null) return null;
    final Matrix4 result =
        Matrix4.translationValues(-_lastOffset.dx, -_lastOffset.dy, 0.0);
    result.multiply(_lastTransform);
    return result;
  }

  Matrix4 _collectTransformForLayerChain(List<ContainerLayer> layers) {
    final Matrix4 result = Matrix4.identity();

    for (int index = layers.length - 1; index > 0; index -= 1)
      layers[index].applyTransform(layers[index - 1], result);
    return result;
  }

  void _establishTransform() {
    assert(link != null);
    _lastTransform = null;

    if (link.leader == null) return;

    assert(link.leader.owner == owner,
        'Linked LeaderLayer anchor is not in the same layer tree as the FollowerLayer.');
    assert(link.leader._lastOffset != null,
        'LeaderLayer anchor must come before FollowerLayer in paint order, but the reverse was true.');

    final Set<Layer> ancestors = HashSet<Layer>();
    Layer ancestor = parent;
    while (ancestor != null) {
      ancestors.add(ancestor);
      ancestor = ancestor.parent;
    }

    ContainerLayer layer = link.leader;
    final List<ContainerLayer> forwardLayers = <ContainerLayer>[null, layer];
    do {
      layer = layer.parent;
      forwardLayers.add(layer);
    } while (!ancestors.contains(layer));
    ancestor = layer;

    layer = this;
    final List<ContainerLayer> inverseLayers = <ContainerLayer>[layer];
    do {
      layer = layer.parent;
      inverseLayers.add(layer);
    } while (layer != ancestor);

    final Matrix4 forwardTransform =
        _collectTransformForLayerChain(forwardLayers);
    final Matrix4 inverseTransform =
        _collectTransformForLayerChain(inverseLayers);
    if (inverseTransform.invert() == 0.0) {
      return;
    }

    inverseTransform.multiply(forwardTransform);
    inverseTransform.translate(linkedOffset.dx, linkedOffset.dy);
    _lastTransform = inverseTransform;
    _inverseDirty = true;
  }

  @override
  bool get alwaysNeedsAddToScene => true;

  @override
  void addToScene(ui.SceneBuilder builder, [Offset layerOffset = Offset.zero]) {
    assert(link != null);
    assert(showWhenUnlinked != null);
    if (link.leader == null && !showWhenUnlinked) {
      _lastTransform = null;
      _lastOffset = null;
      _inverseDirty = true;
      engineLayer = null;
      return;
    }
    _establishTransform();
    if (_lastTransform != null) {
      engineLayer =
          builder.pushTransform(_lastTransform.storage, oldLayer: _engineLayer);
      addChildrenToScene(builder);
      builder.pop();
      _lastOffset = unlinkedOffset + layerOffset;
    } else {
      _lastOffset = null;
      final Matrix4 matrix =
          Matrix4.translationValues(unlinkedOffset.dx, unlinkedOffset.dy, .0);
      engineLayer =
          builder.pushTransform(matrix.storage, oldLayer: _engineLayer);
      addChildrenToScene(builder);
      builder.pop();
    }
    _inverseDirty = true;
  }

  @override
  void applyTransform(Layer child, Matrix4 transform) {
    assert(child != null);
    assert(transform != null);
    if (_lastTransform != null) {
      transform.multiply(_lastTransform);
    } else {
      transform.multiply(
          Matrix4.translationValues(unlinkedOffset.dx, unlinkedOffset.dy, .0));
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<LayerLink>('link', link));
    properties.add(
        TransformProperty('transform', getLastTransform(), defaultValue: null));
  }
}

class AnnotatedRegionLayer<T> extends ContainerLayer {
  AnnotatedRegionLayer(this.value, {this.size, Offset offset})
      : offset = offset ?? Offset.zero,
        assert(value != null);

  final T value;

  final Size size;

  final Offset offset;

  @override
  S find<S>(Offset regionOffset) {
    final S result = super.find<S>(regionOffset);
    if (result != null) return result;
    if (size != null && !(offset & size).contains(regionOffset)) return null;
    if (T == S) {
      final Object untypedResult = value;
      final S typedResult = untypedResult;
      return typedResult;
    }
    return null;
  }

  @override
  Iterable<S> findAll<S>(Offset regionOffset) {
    final Iterable<S> childResults = super.findAll<S>(regionOffset);
    if (size != null && !(offset & size).contains(regionOffset)) {
      return childResults;
    }
    if (T == S) {
      final Object untypedResult = value;
      final S typedResult = untypedResult;
      return childResults.followedBy(<S>[typedResult]);
    }
    return childResults;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<T>('value', value));
    properties.add(DiagnosticsProperty<Size>('size', size, defaultValue: null));
    properties
        .add(DiagnosticsProperty<Offset>('offset', offset, defaultValue: null));
  }
}

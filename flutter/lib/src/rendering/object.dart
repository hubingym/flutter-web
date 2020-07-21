import 'dart:developer';
import 'package:flutter_web/ui.dart' as ui show PictureRecorder, ImageFilter;

import 'package:flutter_web/animation.dart';
import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/gestures.dart';
import 'package:flutter_web/painting.dart';
import 'package:flutter_web/scheduler.dart';
import 'package:flutter_web/semantics.dart';
import 'package:vector_math/vector_math_64.dart';

import 'binding.dart';
import 'debug.dart';
import 'layer.dart';

export 'package:flutter_web/foundation.dart'
    show
        FlutterError,
        InformationCollector,
        DiagnosticsNode,
        DiagnosticsProperty,
        StringProperty,
        DoubleProperty,
        EnumProperty,
        FlagProperty,
        IntProperty,
        DiagnosticPropertiesBuilder;
export 'package:flutter_web/gestures.dart' show HitTestEntry, HitTestResult;
export 'package:flutter_web/painting.dart';

class ParentData {
  @protected
  @mustCallSuper
  void detach() {}

  @override
  String toString() => '<none>';
}

typedef PaintingContextCallback = void Function(
    PaintingContext context, Offset offset);

class PaintingContext extends ClipContext {
  @protected
  PaintingContext(this._containerLayer, this.estimatedBounds)
      : assert(_containerLayer != null),
        assert(estimatedBounds != null);

  final ContainerLayer _containerLayer;

  final Rect estimatedBounds;

  static void repaintCompositedChild(RenderObject child,
      {bool debugAlsoPaintedParent = false}) {
    assert(child._needsPaint);
    _repaintCompositedChild(
      child,
      debugAlsoPaintedParent: debugAlsoPaintedParent,
    );
  }

  static void _repaintCompositedChild(
    RenderObject child, {
    bool debugAlsoPaintedParent = false,
    PaintingContext childContext,
  }) {
    assert(child.isRepaintBoundary);
    assert(() {
      child.debugRegisterRepaintBoundaryPaint(
        includedParent: debugAlsoPaintedParent,
        includedChild: true,
      );
      return true;
    }());
    if (child._layer == null) {
      assert(debugAlsoPaintedParent);
      child._layer = OffsetLayer();
    } else {
      assert(child._layer is OffsetLayer);
      assert(debugAlsoPaintedParent || child._layer.attached);
      child._layer.removeAllChildren();
    }
    assert(child._layer is OffsetLayer);
    assert(() {
      child._layer.debugCreator = child.debugCreator ?? child.runtimeType;
      return true;
    }());
    childContext ??= PaintingContext(child._layer, child.paintBounds);
    child._paintWithContext(childContext, Offset.zero);
    childContext.stopRecordingIfNeeded();
    assert(child._layer is OffsetLayer);
  }

  static void debugInstrumentRepaintCompositedChild(
    RenderObject child, {
    bool debugAlsoPaintedParent = false,
    @required PaintingContext customContext,
  }) {
    assert(() {
      _repaintCompositedChild(
        child,
        debugAlsoPaintedParent: debugAlsoPaintedParent,
        childContext: customContext,
      );
      return true;
    }());
  }

  void paintChild(RenderObject child, Offset offset) {
    assert(() {
      if (debugProfilePaintsEnabled)
        Timeline.startSync('${child.runtimeType}',
            arguments: timelineWhitelistArguments);
      if (debugOnProfilePaint != null) debugOnProfilePaint(child);
      return true;
    }());

    if (child.isRepaintBoundary) {
      stopRecordingIfNeeded();
      _compositeChild(child, offset);
    } else {
      child._paintWithContext(this, offset);
    }

    assert(() {
      if (debugProfilePaintsEnabled) Timeline.finishSync();
      return true;
    }());
  }

  void _compositeChild(RenderObject child, Offset offset) {
    assert(!_isRecording);
    assert(child.isRepaintBoundary);
    assert(_canvas == null || _canvas.getSaveCount() == 1);

    if (child._needsPaint) {
      repaintCompositedChild(child, debugAlsoPaintedParent: true);
    } else {
      assert(() {
        child.debugRegisterRepaintBoundaryPaint(
          includedParent: true,
          includedChild: false,
        );
        child._layer.debugCreator = child.debugCreator ?? child;
        return true;
      }());
    }
    assert(child._layer is OffsetLayer);
    final OffsetLayer childOffsetLayer = child._layer;
    childOffsetLayer.offset = offset;
    appendLayer(child._layer);
  }

  @protected
  void appendLayer(Layer layer) {
    assert(!_isRecording);
    layer.remove();
    _containerLayer.append(layer);
  }

  bool get _isRecording {
    final bool hasCanvas = _canvas != null;
    assert(() {
      if (hasCanvas) {
        assert(_currentLayer != null);
        assert(_recorder != null);
        assert(_canvas != null);
      } else {
        assert(_currentLayer == null);
        assert(_recorder == null);
        assert(_canvas == null);
      }
      return true;
    }());
    return hasCanvas;
  }

  PictureLayer _currentLayer;
  ui.PictureRecorder _recorder;
  Canvas _canvas;

  @override
  Canvas get canvas {
    if (_canvas == null) _startRecording();
    return _canvas;
  }

  void _startRecording() {
    assert(!_isRecording);
    _currentLayer = PictureLayer(estimatedBounds);
    _recorder = ui.PictureRecorder();
    _canvas = Canvas(_recorder);
    _containerLayer.append(_currentLayer);
  }

  @protected
  @mustCallSuper
  void stopRecordingIfNeeded() {
    if (!_isRecording) return;
    assert(() {
      if (debugRepaintRainbowEnabled) {
        final Paint paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6.0
          ..color = debugCurrentRepaintColor.toColor();
        canvas.drawRect(estimatedBounds.deflate(3.0), paint);
      }
      if (debugPaintLayerBordersEnabled) {
        final Paint paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = const Color(0xFFFF9800);
        canvas.drawRect(estimatedBounds, paint);
      }
      return true;
    }());
    _currentLayer.picture = _recorder.endRecording();
    _currentLayer = null;
    _recorder = null;
    _canvas = null;
  }

  void setIsComplexHint() {
    _currentLayer?.isComplexHint = true;
  }

  void setWillChangeHint() {
    _currentLayer?.willChangeHint = true;
  }

  void addLayer(Layer layer) {
    stopRecordingIfNeeded();
    appendLayer(layer);
  }

  void pushLayer(
      ContainerLayer childLayer, PaintingContextCallback painter, Offset offset,
      {Rect childPaintBounds}) {
    assert(painter != null);

    if (childLayer.hasChildren) {
      childLayer.removeAllChildren();
    }
    stopRecordingIfNeeded();
    appendLayer(childLayer);
    final PaintingContext childContext =
        createChildContext(childLayer, childPaintBounds ?? estimatedBounds);
    painter(childContext, offset);
    childContext.stopRecordingIfNeeded();
  }

  @protected
  PaintingContext createChildContext(ContainerLayer childLayer, Rect bounds) {
    return PaintingContext(childLayer, bounds);
  }

  ClipRectLayer pushClipRect(bool needsCompositing, Offset offset,
      Rect clipRect, PaintingContextCallback painter,
      {Clip clipBehavior = Clip.hardEdge, ClipRectLayer oldLayer}) {
    final Rect offsetClipRect = clipRect.shift(offset);
    if (needsCompositing) {
      if (oldLayer == null) {
        oldLayer =
            ClipRectLayer(clipRect: offsetClipRect, clipBehavior: clipBehavior);
      } else {
        oldLayer
          ..clipRect = offsetClipRect
          ..clipBehavior = clipBehavior;
      }
      pushLayer(oldLayer, painter, offset, childPaintBounds: offsetClipRect);
      return oldLayer;
    } else {
      clipRectAndPaint(offsetClipRect, clipBehavior, offsetClipRect,
          () => painter(this, offset));
      return null;
    }
  }

  ClipRRectLayer pushClipRRect(bool needsCompositing, Offset offset,
      Rect bounds, RRect clipRRect, PaintingContextCallback painter,
      {Clip clipBehavior = Clip.antiAlias, ClipRRectLayer oldLayer}) {
    assert(clipBehavior != null);
    final Rect offsetBounds = bounds.shift(offset);
    final RRect offsetClipRRect = clipRRect.shift(offset);
    if (needsCompositing) {
      if (oldLayer == null) {
        oldLayer = ClipRRectLayer(
            clipRRect: offsetClipRRect, clipBehavior: clipBehavior);
      } else {
        oldLayer
          ..clipRRect = offsetClipRRect
          ..clipBehavior = clipBehavior;
      }
      pushLayer(oldLayer, painter, offset, childPaintBounds: offsetBounds);
      return oldLayer;
    } else {
      clipRRectAndPaint(offsetClipRRect, clipBehavior, offsetBounds,
          () => painter(this, offset));
      return null;
    }
  }

  ClipPathLayer pushClipPath(bool needsCompositing, Offset offset, Rect bounds,
      Path clipPath, PaintingContextCallback painter,
      {Clip clipBehavior = Clip.antiAlias, ClipPathLayer oldLayer}) {
    assert(clipBehavior != null);
    final Rect offsetBounds = bounds.shift(offset);
    final Path offsetClipPath = clipPath.shift(offset);
    if (needsCompositing) {
      if (oldLayer == null) {
        oldLayer =
            ClipPathLayer(clipPath: offsetClipPath, clipBehavior: clipBehavior);
      } else {
        oldLayer
          ..clipPath = offsetClipPath
          ..clipBehavior = clipBehavior;
      }
      pushLayer(oldLayer, painter, offset, childPaintBounds: offsetBounds);
      return oldLayer;
    } else {
      clipPathAndPaint(offsetClipPath, clipBehavior, offsetBounds,
          () => painter(this, offset));
      return null;
    }
  }

  ColorFilterLayer pushColorFilter(
      Offset offset, ColorFilter colorFilter, PaintingContextCallback painter,
      {ColorFilterLayer oldLayer}) {
    assert(colorFilter != null);
    oldLayer = ColorFilterLayer(colorFilter: colorFilter);
    pushLayer(oldLayer, painter, offset);
    return oldLayer;
  }

  TransformLayer pushTransform(bool needsCompositing, Offset offset,
      Matrix4 transform, PaintingContextCallback painter,
      {TransformLayer oldLayer}) {
    final Matrix4 effectiveTransform =
        Matrix4.translationValues(offset.dx, offset.dy, 0.0)
          ..multiply(transform)
          ..translate(-offset.dx, -offset.dy);
    if (needsCompositing) {
      if (oldLayer == null) {
        oldLayer = TransformLayer(transform: effectiveTransform);
      } else {
        oldLayer.transform = effectiveTransform;
      }
      pushLayer(
        oldLayer,
        painter,
        offset,
        childPaintBounds: MatrixUtils.inverseTransformRect(
            effectiveTransform, estimatedBounds),
      );
      return oldLayer;
    } else {
      canvas
        ..save()
        ..transform(effectiveTransform.storage);
      painter(this, offset);
      canvas..restore();
      return null;
    }
  }

  OpacityLayer pushOpacity(
      Offset offset, int alpha, PaintingContextCallback painter,
      {OpacityLayer oldLayer}) {
    if (oldLayer == null) {
      oldLayer = OpacityLayer(alpha: alpha, offset: offset);
    } else {
      oldLayer
        ..alpha = alpha
        ..offset = offset;
    }
    pushLayer(oldLayer, painter, Offset.zero);
    return oldLayer;
  }

  ShaderMaskLayer pushShaderMask(Offset offset, Shader shader, Rect maskRect,
      BlendMode blendMode, PaintingContextCallback painter,
      {ShaderMaskLayer oldLayer}) {
    if (oldLayer == null) {
      oldLayer = ShaderMaskLayer(
        shader: shader,
        maskRect: maskRect,
        blendMode: blendMode,
      );
    } else {
      oldLayer
        ..shader = shader
        ..maskRect = maskRect
        ..blendMode = blendMode;
    }
    pushLayer(oldLayer, painter, offset);
    return oldLayer;
  }

  BackdropFilterLayer pushBackdropFilter(
      Offset offset, ui.ImageFilter filter, PaintingContextCallback painter,
      {BackdropFilterLayer oldLayer}) {
    if (oldLayer == null) {
      oldLayer = BackdropFilterLayer(filter: filter);
    } else {
      oldLayer.filter = filter;
    }
    pushLayer(oldLayer, painter, offset);
    return oldLayer;
  }

  PhysicalModelLayer pushPhysicalModel(
      Offset offset,
      Path clipPath,
      Clip clipBehavior,
      double elevation,
      Color color,
      Color shadowColor,
      PaintingContextCallback painter,
      {PhysicalModelLayer oldLayer,
      Rect childPaintBounds}) {
    if (oldLayer == null) {
      oldLayer = PhysicalModelLayer(
        clipPath: clipPath,
        clipBehavior: clipBehavior,
        elevation: elevation,
        color: color,
        shadowColor: shadowColor,
      );
    } else {
      oldLayer
        ..clipPath = clipPath
        ..clipBehavior = clipBehavior
        ..elevation = elevation
        ..color = color
        ..shadowColor = shadowColor;
    }
    pushLayer(oldLayer, painter, offset, childPaintBounds: childPaintBounds);
    return oldLayer;
  }

  LeaderLayer pushLeader(
      Offset offset, LayerLink link, PaintingContextCallback painter,
      {LeaderLayer oldLayer}) {
    if (oldLayer == null) {
      oldLayer = LeaderLayer(link: link, offset: offset);
    } else {
      oldLayer
        ..link = link
        ..offset = offset;
    }
    pushLayer(oldLayer, painter, Offset.zero);
    return oldLayer;
  }

  FollowerLayer pushFollower(Offset linkedOffset, Offset unlinkedOffset,
      LayerLink link, bool showWhenUnlinked, PaintingContextCallback painter,
      {FollowerLayer oldLayer, Rect childPaintBounds}) {
    if (oldLayer == null) {
      oldLayer = FollowerLayer(
        link: link,
        showWhenUnlinked: showWhenUnlinked,
        linkedOffset: linkedOffset,
        unlinkedOffset: unlinkedOffset,
      );
    } else {
      oldLayer
        ..link = link
        ..showWhenUnlinked = showWhenUnlinked
        ..linkedOffset = linkedOffset
        ..unlinkedOffset = unlinkedOffset;
    }
    pushLayer(oldLayer, painter, Offset.zero,
        childPaintBounds: childPaintBounds);
    return oldLayer;
  }

  @override
  String toString() =>
      '$runtimeType#$hashCode(layer: $_containerLayer, canvas bounds: $estimatedBounds)';
}

@immutable
abstract class Constraints {
  const Constraints();

  bool get isTight;

  bool get isNormalized;

  bool debugAssertIsValid({
    bool isAppliedConstraint = false,
    InformationCollector informationCollector,
  }) {
    assert(isNormalized);
    return isNormalized;
  }
}

typedef RenderObjectVisitor = void Function(RenderObject child);

typedef LayoutCallback<T extends Constraints> = void Function(T constraints);

class SemanticsHandle {
  SemanticsHandle._(this._owner, this.listener) : assert(_owner != null) {
    if (listener != null) _owner.semanticsOwner.addListener(listener);
  }

  PipelineOwner _owner;

  final VoidCallback listener;

  @mustCallSuper
  void dispose() {
    assert(() {
      if (_owner == null) {
        throw FlutterError('SemanticsHandle has already been disposed.\n'
            'Each SemanticsHandle should be disposed exactly once.');
      }
      return true;
    }());
    if (_owner != null) {
      if (listener != null) _owner.semanticsOwner.removeListener(listener);
      _owner._didDisposeSemanticsHandle();
      _owner = null;
    }
  }
}

class PipelineOwner {
  PipelineOwner({
    this.onNeedVisualUpdate,
    this.onSemanticsOwnerCreated,
    this.onSemanticsOwnerDisposed,
  });

  final VoidCallback onNeedVisualUpdate;

  final VoidCallback onSemanticsOwnerCreated;

  final VoidCallback onSemanticsOwnerDisposed;

  void requestVisualUpdate() {
    if (onNeedVisualUpdate != null) onNeedVisualUpdate();
  }

  AbstractNode get rootNode => _rootNode;
  AbstractNode _rootNode;
  set rootNode(AbstractNode value) {
    if (_rootNode == value) return;
    _rootNode?.detach();
    _rootNode = value;
    _rootNode?.attach(this);
  }

  List<RenderObject> _nodesNeedingLayout = <RenderObject>[];

  bool get debugDoingLayout => _debugDoingLayout;
  bool _debugDoingLayout = false;

  void flushLayout() {
    if (!kReleaseMode) {
      Timeline.startSync('Layout', arguments: timelineWhitelistArguments);
    }
    assert(() {
      _debugDoingLayout = true;
      return true;
    }());
    try {
      while (_nodesNeedingLayout.isNotEmpty) {
        final List<RenderObject> dirtyNodes = _nodesNeedingLayout;
        _nodesNeedingLayout = <RenderObject>[];
        for (RenderObject node in dirtyNodes
          ..sort((RenderObject a, RenderObject b) => a.depth - b.depth)) {
          if (node._needsLayout && node.owner == this)
            node._layoutWithoutResize();
        }
      }
    } finally {
      assert(() {
        _debugDoingLayout = false;
        return true;
      }());
      if (!kReleaseMode) {
        Timeline.finishSync();
      }
    }
  }

  bool _debugAllowMutationsToDirtySubtrees = false;

  void _enableMutationsToDirtySubtrees(VoidCallback callback) {
    assert(_debugDoingLayout);
    bool oldState;
    assert(() {
      oldState = _debugAllowMutationsToDirtySubtrees;
      _debugAllowMutationsToDirtySubtrees = true;
      return true;
    }());
    try {
      callback();
    } finally {
      assert(() {
        _debugAllowMutationsToDirtySubtrees = oldState;
        return true;
      }());
    }
  }

  final List<RenderObject> _nodesNeedingCompositingBitsUpdate =
      <RenderObject>[];

  void flushCompositingBits() {
    if (!kReleaseMode) {
      Timeline.startSync('Compositing bits');
    }
    _nodesNeedingCompositingBitsUpdate
        .sort((RenderObject a, RenderObject b) => a.depth - b.depth);
    for (RenderObject node in _nodesNeedingCompositingBitsUpdate) {
      if (node._needsCompositingBitsUpdate && node.owner == this)
        node._updateCompositingBits();
    }
    _nodesNeedingCompositingBitsUpdate.clear();
    if (!kReleaseMode) {
      Timeline.finishSync();
    }
  }

  List<RenderObject> _nodesNeedingPaint = <RenderObject>[];

  bool get debugDoingPaint => _debugDoingPaint;
  bool _debugDoingPaint = false;

  void flushPaint() {
    if (!kReleaseMode) {
      Timeline.startSync('Paint', arguments: timelineWhitelistArguments);
    }
    assert(() {
      _debugDoingPaint = true;
      return true;
    }());
    try {
      final List<RenderObject> dirtyNodes = _nodesNeedingPaint;
      _nodesNeedingPaint = <RenderObject>[];

      for (RenderObject node in dirtyNodes
        ..sort((RenderObject a, RenderObject b) => b.depth - a.depth)) {
        assert(node._layer != null);
        if (node._needsPaint && node.owner == this) {
          if (node._layer.attached) {
            PaintingContext.repaintCompositedChild(node);
          } else {
            node._skippedPaintingOnLayer();
          }
        }
      }
      assert(_nodesNeedingPaint.isEmpty);
    } finally {
      assert(() {
        _debugDoingPaint = false;
        return true;
      }());
      if (!kReleaseMode) {
        Timeline.finishSync();
      }
    }
  }

  SemanticsOwner get semanticsOwner => _semanticsOwner;
  SemanticsOwner _semanticsOwner;

  int get debugOutstandingSemanticsHandles => _outstandingSemanticsHandles;
  int _outstandingSemanticsHandles = 0;

  SemanticsHandle ensureSemantics({VoidCallback listener}) {
    _outstandingSemanticsHandles += 1;
    if (_outstandingSemanticsHandles == 1) {
      assert(_semanticsOwner == null);
      _semanticsOwner = SemanticsOwner();
      if (onSemanticsOwnerCreated != null) onSemanticsOwnerCreated();
    }
    return SemanticsHandle._(this, listener);
  }

  void _didDisposeSemanticsHandle() {
    assert(_semanticsOwner != null);
    _outstandingSemanticsHandles -= 1;
    if (_outstandingSemanticsHandles == 0) {
      _semanticsOwner.dispose();
      _semanticsOwner = null;
      if (onSemanticsOwnerDisposed != null) onSemanticsOwnerDisposed();
    }
  }

  bool _debugDoingSemantics = false;
  final Set<RenderObject> _nodesNeedingSemantics = <RenderObject>{};

  void flushSemantics() {
    if (_semanticsOwner == null) return;
    if (!kReleaseMode) {
      Timeline.startSync('Semantics');
    }
    assert(_semanticsOwner != null);
    assert(() {
      _debugDoingSemantics = true;
      return true;
    }());
    try {
      final List<RenderObject> nodesToProcess = _nodesNeedingSemantics.toList()
        ..sort((RenderObject a, RenderObject b) => a.depth - b.depth);
      _nodesNeedingSemantics.clear();
      for (RenderObject node in nodesToProcess) {
        if (node._needsSemanticsUpdate && node.owner == this)
          node._updateSemantics();
      }
      _semanticsOwner.sendSemanticsUpdate();
    } finally {
      assert(_nodesNeedingSemantics.isEmpty);
      assert(() {
        _debugDoingSemantics = false;
        return true;
      }());
      if (!kReleaseMode) {
        Timeline.finishSync();
      }
    }
  }
}

abstract class RenderObject extends AbstractNode
    with DiagnosticableTreeMixin
    implements HitTestTarget {
  RenderObject() {
    _needsCompositing = isRepaintBoundary || alwaysNeedsCompositing;
  }

  void reassemble() {
    markNeedsLayout();
    markNeedsCompositingBitsUpdate();
    markNeedsPaint();
    markNeedsSemanticsUpdate();
    visitChildren((RenderObject child) {
      child.reassemble();
    });
  }

  ParentData parentData;

  void setupParentData(covariant RenderObject child) {
    assert(_debugCanPerformMutations);
    if (child.parentData is! ParentData) child.parentData = ParentData();
  }

  @override
  void adoptChild(RenderObject child) {
    assert(_debugCanPerformMutations);
    assert(child != null);
    setupParentData(child);
    markNeedsLayout();
    markNeedsCompositingBitsUpdate();
    markNeedsSemanticsUpdate();
    super.adoptChild(child);
  }

  @override
  void dropChild(RenderObject child) {
    assert(_debugCanPerformMutations);
    assert(child != null);
    assert(child.parentData != null);
    child._cleanRelayoutBoundary();
    child.parentData.detach();
    child.parentData = null;
    super.dropChild(child);
    markNeedsLayout();
    markNeedsCompositingBitsUpdate();
    markNeedsSemanticsUpdate();
  }

  void visitChildren(RenderObjectVisitor visitor) {}

  dynamic debugCreator;

  void _debugReportException(
      String method, dynamic exception, StackTrace stack) {
    FlutterError.reportError(FlutterErrorDetailsForRendering(
        exception: exception,
        stack: stack,
        library: 'rendering library',
        context: ErrorDescription('during $method()'),
        renderObject: this,
        informationCollector: () sync* {
          yield describeForError(
              'The following RenderObject was being processed when the exception was fired');

          yield describeForError('RenderObject',
              style: DiagnosticsTreeStyle.truncateChildren);
        }));
  }

  bool get debugDoingThisResize => _debugDoingThisResize;
  bool _debugDoingThisResize = false;

  bool get debugDoingThisLayout => _debugDoingThisLayout;
  bool _debugDoingThisLayout = false;

  static RenderObject get debugActiveLayout => _debugActiveLayout;
  static RenderObject _debugActiveLayout;

  bool get debugCanParentUseSize => _debugCanParentUseSize;
  bool _debugCanParentUseSize;

  bool _debugMutationsLocked = false;

  bool get _debugCanPerformMutations {
    bool result;
    assert(() {
      RenderObject node = this;
      while (true) {
        if (node._doingThisLayoutWithCallback) {
          result = true;
          break;
        }
        if (owner != null &&
            owner._debugAllowMutationsToDirtySubtrees &&
            node._needsLayout) {
          result = true;
          break;
        }
        if (node._debugMutationsLocked) {
          result = false;
          break;
        }
        if (node.parent is! RenderObject) {
          result = true;
          break;
        }
        node = node.parent;
      }
      return true;
    }());
    return result;
  }

  @override
  PipelineOwner get owner => super.owner;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);

    if (_needsLayout && _relayoutBoundary != null) {
      _needsLayout = false;
      markNeedsLayout();
    }
    if (_needsCompositingBitsUpdate) {
      _needsCompositingBitsUpdate = false;
      markNeedsCompositingBitsUpdate();
    }
    if (_needsPaint && _layer != null) {
      _needsPaint = false;
      markNeedsPaint();
    }
    if (_needsSemanticsUpdate && _semanticsConfiguration.isSemanticBoundary) {
      _needsSemanticsUpdate = false;
      markNeedsSemanticsUpdate();
    }
  }

  bool get debugNeedsLayout {
    bool result;
    assert(() {
      result = _needsLayout;
      return true;
    }());
    return result;
  }

  bool _needsLayout = true;

  RenderObject _relayoutBoundary;
  bool _doingThisLayoutWithCallback = false;

  @protected
  Constraints get constraints => _constraints;
  Constraints _constraints;

  @protected
  void debugAssertDoesMeetConstraints();

  static bool debugCheckingIntrinsics = false;
  bool _debugSubtreeRelayoutRootAlreadyMarkedNeedsLayout() {
    if (_relayoutBoundary == null) return true;
    RenderObject node = this;
    while (node != _relayoutBoundary) {
      assert(node._relayoutBoundary == _relayoutBoundary);
      assert(node.parent != null);
      node = node.parent;
      if ((!node._needsLayout) && (!node._debugDoingThisLayout)) return false;
    }
    assert(node._relayoutBoundary == node);
    return true;
  }

  void markNeedsLayout() {
    assert(_debugCanPerformMutations);
    if (_needsLayout) {
      assert(_debugSubtreeRelayoutRootAlreadyMarkedNeedsLayout());
      return;
    }
    assert(_relayoutBoundary != null);
    if (_relayoutBoundary != this) {
      markParentNeedsLayout();
    } else {
      _needsLayout = true;
      if (owner != null) {
        assert(() {
          if (debugPrintMarkNeedsLayoutStacks)
            debugPrintStack(label: 'markNeedsLayout() called for $this');
          return true;
        }());
        owner._nodesNeedingLayout.add(this);
        owner.requestVisualUpdate();
      }
    }
  }

  @protected
  void markParentNeedsLayout() {
    _needsLayout = true;
    final RenderObject parent = this.parent;
    if (!_doingThisLayoutWithCallback) {
      parent.markNeedsLayout();
    } else {
      assert(parent._debugDoingThisLayout);
    }
    assert(parent == this.parent);
  }

  void markNeedsLayoutForSizedByParentChange() {
    markNeedsLayout();
    markParentNeedsLayout();
  }

  void _cleanRelayoutBoundary() {
    if (_relayoutBoundary != this) {
      _relayoutBoundary = null;
      _needsLayout = true;
      visitChildren((RenderObject child) {
        child._cleanRelayoutBoundary();
      });
    }
  }

  void scheduleInitialLayout() {
    assert(attached);
    assert(parent is! RenderObject);
    assert(!owner._debugDoingLayout);
    assert(_relayoutBoundary == null);
    _relayoutBoundary = this;
    assert(() {
      _debugCanParentUseSize = false;
      return true;
    }());
    owner._nodesNeedingLayout.add(this);
  }

  void _layoutWithoutResize() {
    assert(_relayoutBoundary == this);
    RenderObject debugPreviousActiveLayout;
    assert(!_debugMutationsLocked);
    assert(!_doingThisLayoutWithCallback);
    assert(_debugCanParentUseSize != null);
    assert(() {
      _debugMutationsLocked = true;
      _debugDoingThisLayout = true;
      debugPreviousActiveLayout = _debugActiveLayout;
      _debugActiveLayout = this;
      if (debugPrintLayouts) debugPrint('Laying out (without resize) $this');
      return true;
    }());
    try {
      performLayout();
      markNeedsSemanticsUpdate();
    } catch (e, stack) {
      _debugReportException('performLayout', e, stack);
    }
    assert(() {
      _debugActiveLayout = debugPreviousActiveLayout;
      _debugDoingThisLayout = false;
      _debugMutationsLocked = false;
      return true;
    }());
    _needsLayout = false;
    markNeedsPaint();
  }

  void layout(Constraints constraints, {bool parentUsesSize = false}) {
    assert(constraints != null);
    assert(constraints.debugAssertIsValid(
      isAppliedConstraint: true,
      informationCollector: () sync* {
        final List<String> stack = StackTrace.current.toString().split('\n');
        int targetFrame;
        final Pattern layoutFramePattern =
            RegExp(r'^#[0-9]+ +RenderObject.layout \(');
        for (int i = 0; i < stack.length; i += 1) {
          if (layoutFramePattern.matchAsPrefix(stack[i]) != null) {
            targetFrame = i + 1;
            break;
          }
        }
        if (targetFrame != null && targetFrame < stack.length) {
          final Pattern targetFramePattern = RegExp(r'^#[0-9]+ +(.+)$');
          final Match targetFrameMatch =
              targetFramePattern.matchAsPrefix(stack[targetFrame]);
          final String problemFunction =
              (targetFrameMatch != null && targetFrameMatch.groupCount > 0)
                  ? targetFrameMatch.group(1)
                  : stack[targetFrame].trim();

          yield ErrorDescription(
              'These invalid constraints were provided to $runtimeType\'s layout() '
              'function by the following function, which probably computed the '
              'invalid constraints in question:\n'
              '  $problemFunction');
        }
      },
    ));
    assert(!_debugDoingThisResize);
    assert(!_debugDoingThisLayout);
    RenderObject relayoutBoundary;
    if (!parentUsesSize ||
        sizedByParent ||
        constraints.isTight ||
        parent is! RenderObject) {
      relayoutBoundary = this;
    } else {
      final RenderObject parent = this.parent;
      relayoutBoundary = parent._relayoutBoundary;
    }
    assert(() {
      _debugCanParentUseSize = parentUsesSize;
      return true;
    }());
    if (!_needsLayout &&
        constraints == _constraints &&
        relayoutBoundary == _relayoutBoundary) {
      assert(() {
        _debugDoingThisResize = sizedByParent;
        _debugDoingThisLayout = !sizedByParent;
        final RenderObject debugPreviousActiveLayout = _debugActiveLayout;
        _debugActiveLayout = this;
        debugResetSize();
        _debugActiveLayout = debugPreviousActiveLayout;
        _debugDoingThisLayout = false;
        _debugDoingThisResize = false;
        return true;
      }());
      return;
    }
    _constraints = constraints;
    _relayoutBoundary = relayoutBoundary;
    assert(!_debugMutationsLocked);
    assert(!_doingThisLayoutWithCallback);
    assert(() {
      _debugMutationsLocked = true;
      if (debugPrintLayouts)
        debugPrint(
            'Laying out (${sizedByParent ? "with separate resize" : "with resize allowed"}) $this');
      return true;
    }());
    if (sizedByParent) {
      assert(() {
        _debugDoingThisResize = true;
        return true;
      }());
      try {
        performResize();
        assert(() {
          debugAssertDoesMeetConstraints();
          return true;
        }());
      } catch (e, stack) {
        _debugReportException('performResize', e, stack);
      }
      assert(() {
        _debugDoingThisResize = false;
        return true;
      }());
    }
    RenderObject debugPreviousActiveLayout;
    assert(() {
      _debugDoingThisLayout = true;
      debugPreviousActiveLayout = _debugActiveLayout;
      _debugActiveLayout = this;
      return true;
    }());
    try {
      performLayout();
      markNeedsSemanticsUpdate();
      assert(() {
        debugAssertDoesMeetConstraints();
        return true;
      }());
    } catch (e, stack) {
      _debugReportException('performLayout', e, stack);
    }
    assert(() {
      _debugActiveLayout = debugPreviousActiveLayout;
      _debugDoingThisLayout = false;
      _debugMutationsLocked = false;
      return true;
    }());
    _needsLayout = false;
    markNeedsPaint();
  }

  @protected
  void debugResetSize() {}

  @protected
  bool get sizedByParent => false;

  @protected
  void performResize();

  @protected
  void performLayout();

  @protected
  void invokeLayoutCallback<T extends Constraints>(LayoutCallback<T> callback) {
    assert(_debugMutationsLocked);
    assert(_debugDoingThisLayout);
    assert(!_doingThisLayoutWithCallback);
    _doingThisLayoutWithCallback = true;
    try {
      owner._enableMutationsToDirtySubtrees(() {
        callback(constraints);
      });
    } finally {
      _doingThisLayoutWithCallback = false;
    }
  }

  void rotate({
    int oldAngle,
    int newAngle,
    Duration time,
  }) {}

  bool get debugDoingThisPaint => _debugDoingThisPaint;
  bool _debugDoingThisPaint = false;

  static RenderObject get debugActivePaint => _debugActivePaint;
  static RenderObject _debugActivePaint;

  bool get isRepaintBoundary => false;

  void debugRegisterRepaintBoundaryPaint(
      {bool includedParent = true, bool includedChild = false}) {}

  @protected
  bool get alwaysNeedsCompositing => false;

  ContainerLayer get layer => _layer;
  @protected
  set layer(ContainerLayer newLayer) {
    _layer = newLayer;
  }

  ContainerLayer _layer;

  ContainerLayer get debugLayer {
    ContainerLayer result;
    assert(() {
      result = _layer;
      return true;
    }());
    return result;
  }

  bool _needsCompositingBitsUpdate = false;

  void markNeedsCompositingBitsUpdate() {
    if (_needsCompositingBitsUpdate) return;
    _needsCompositingBitsUpdate = true;
    if (parent is RenderObject) {
      final RenderObject parent = this.parent;
      if (parent._needsCompositingBitsUpdate) return;
      if (!isRepaintBoundary && !parent.isRepaintBoundary) {
        parent.markNeedsCompositingBitsUpdate();
        return;
      }
    }
    assert(() {
      final AbstractNode parent = this.parent;
      if (parent is RenderObject) return parent._needsCompositing;
      return true;
    }());

    if (owner != null) owner._nodesNeedingCompositingBitsUpdate.add(this);
  }

  bool _needsCompositing;

  bool get needsCompositing {
    assert(!_needsCompositingBitsUpdate);
    return _needsCompositing;
  }

  void _updateCompositingBits() {
    if (!_needsCompositingBitsUpdate) return;
    final bool oldNeedsCompositing = _needsCompositing;
    _needsCompositing = false;
    visitChildren((RenderObject child) {
      child._updateCompositingBits();
      if (child.needsCompositing) _needsCompositing = true;
    });
    if (isRepaintBoundary || alwaysNeedsCompositing) _needsCompositing = true;
    if (oldNeedsCompositing != _needsCompositing) markNeedsPaint();
    _needsCompositingBitsUpdate = false;
  }

  bool get debugNeedsPaint {
    bool result;
    assert(() {
      result = _needsPaint;
      return true;
    }());
    return result;
  }

  bool _needsPaint = true;

  void markNeedsPaint() {
    assert(owner == null || !owner.debugDoingPaint);
    if (_needsPaint) return;
    _needsPaint = true;
    if (isRepaintBoundary) {
      assert(() {
        if (debugPrintMarkNeedsPaintStacks)
          debugPrintStack(label: 'markNeedsPaint() called for $this');
        return true;
      }());

      assert(_layer != null);
      if (owner != null) {
        owner._nodesNeedingPaint.add(this);
        owner.requestVisualUpdate();
      }
    } else if (parent is RenderObject) {
      final RenderObject parent = this.parent;
      parent.markNeedsPaint();
      assert(parent == this.parent);
    } else {
      assert(() {
        if (debugPrintMarkNeedsPaintStacks)
          debugPrintStack(
              label: 'markNeedsPaint() called for $this (root of render tree)');
        return true;
      }());

      if (owner != null) owner.requestVisualUpdate();
    }
  }

  void _skippedPaintingOnLayer() {
    assert(attached);
    assert(isRepaintBoundary);
    assert(_needsPaint);
    assert(_layer != null);
    assert(!_layer.attached);
    AbstractNode ancestor = parent;
    while (ancestor is RenderObject) {
      final RenderObject node = ancestor;
      if (node.isRepaintBoundary) {
        if (node._layer == null) break;
        if (node._layer.attached) break;
        node._needsPaint = true;
      }
      ancestor = node.parent;
    }
  }

  void scheduleInitialPaint(ContainerLayer rootLayer) {
    assert(rootLayer.attached);
    assert(attached);
    assert(parent is! RenderObject);
    assert(!owner._debugDoingPaint);
    assert(isRepaintBoundary);
    assert(_layer == null);
    _layer = rootLayer;
    assert(_needsPaint);
    owner._nodesNeedingPaint.add(this);
  }

  void replaceRootLayer(OffsetLayer rootLayer) {
    assert(rootLayer.attached);
    assert(attached);
    assert(parent is! RenderObject);
    assert(!owner._debugDoingPaint);
    assert(isRepaintBoundary);
    assert(_layer != null);
    _layer.detach();
    _layer = rootLayer;
    markNeedsPaint();
  }

  void _paintWithContext(PaintingContext context, Offset offset) {
    assert(() {
      if (_debugDoingThisPaint) {
        throw FlutterError('Tried to paint a RenderObject reentrantly.\n'
            'The following RenderObject was already being painted when it was '
            'painted again:\n'
            '  ${toStringShallow(joiner: "\n    ")}\n'
            'Since this typically indicates an infinite recursion, it is '
            'disallowed.');
      }
      return true;
    }());

    if (_needsLayout) return;
    assert(() {
      if (_needsCompositingBitsUpdate) {
        throw FlutterError(
            'Tried to paint a RenderObject before its compositing bits were '
            'updated.\n'
            'The following RenderObject was marked as having dirty compositing '
            'bits at the time that it was painted:\n'
            '  ${toStringShallow(joiner: "\n    ")}\n'
            'A RenderObject that still has dirty compositing bits cannot be '
            'painted because this indicates that the tree has not yet been '
            'properly configured for creating the layer tree.\n'
            'This usually indicates an error in the Flutter framework itself.');
      }
      return true;
    }());
    RenderObject debugLastActivePaint;
    assert(() {
      _debugDoingThisPaint = true;
      debugLastActivePaint = _debugActivePaint;
      _debugActivePaint = this;
      assert(!isRepaintBoundary || _layer != null);
      return true;
    }());
    _needsPaint = false;
    try {
      paint(context, offset);
      assert(!_needsLayout);
      assert(!_needsPaint);
    } catch (e, stack) {
      _debugReportException('paint', e, stack);
    }
    assert(() {
      debugPaint(context, offset);
      _debugActivePaint = debugLastActivePaint;
      _debugDoingThisPaint = false;
      return true;
    }());
  }

  Rect get paintBounds;

  void debugPaint(PaintingContext context, Offset offset) {}

  void paint(PaintingContext context, Offset offset) {}

  void applyPaintTransform(covariant RenderObject child, Matrix4 transform) {
    assert(child.parent == this);
  }

  Matrix4 getTransformTo(RenderObject ancestor) {
    assert(attached);
    if (ancestor == null) {
      final AbstractNode rootNode = owner.rootNode;
      if (rootNode is RenderObject) ancestor = rootNode;
    }
    final List<RenderObject> renderers = <RenderObject>[];
    for (RenderObject renderer = this;
        renderer != ancestor;
        renderer = renderer.parent) {
      assert(renderer != null);
      renderers.add(renderer);
    }
    final Matrix4 transform = Matrix4.identity();
    for (int index = renderers.length - 1; index > 0; index -= 1)
      renderers[index].applyPaintTransform(renderers[index - 1], transform);
    return transform;
  }

  Rect describeApproximatePaintClip(covariant RenderObject child) => null;

  Rect describeSemanticsClip(covariant RenderObject child) => null;

  void scheduleInitialSemantics() {
    assert(attached);
    assert(parent is! RenderObject);
    assert(!owner._debugDoingSemantics);
    assert(_semantics == null);
    assert(_needsSemanticsUpdate);
    assert(owner._semanticsOwner != null);
    owner._nodesNeedingSemantics.add(this);
    owner.requestVisualUpdate();
  }

  @protected
  void describeSemanticsConfiguration(SemanticsConfiguration config) {}

  void sendSemanticsEvent(SemanticsEvent semanticsEvent) {
    if (owner.semanticsOwner == null) return;
    if (_semantics != null && !_semantics.isMergedIntoParent) {
      _semantics.sendEvent(semanticsEvent);
    } else if (parent != null) {
      final RenderObject renderParent = parent;
      renderParent.sendSemanticsEvent(semanticsEvent);
    }
  }

  SemanticsConfiguration _cachedSemanticsConfiguration;

  SemanticsConfiguration get _semanticsConfiguration {
    if (_cachedSemanticsConfiguration == null) {
      _cachedSemanticsConfiguration = SemanticsConfiguration();
      describeSemanticsConfiguration(_cachedSemanticsConfiguration);
    }
    return _cachedSemanticsConfiguration;
  }

  Rect get semanticBounds;

  bool _needsSemanticsUpdate = true;
  SemanticsNode _semantics;

  SemanticsNode get debugSemantics {
    SemanticsNode result;
    assert(() {
      result = _semantics;
      return true;
    }());
    return result;
  }

  @mustCallSuper
  void clearSemantics() {
    _needsSemanticsUpdate = true;
    _semantics = null;
    visitChildren((RenderObject child) {
      child.clearSemantics();
    });
  }

  void markNeedsSemanticsUpdate() {
    assert(!attached || !owner._debugDoingSemantics);
    if (!attached || owner._semanticsOwner == null) {
      _cachedSemanticsConfiguration = null;
      return;
    }

    final bool wasSemanticsBoundary = _semantics != null &&
        _cachedSemanticsConfiguration?.isSemanticBoundary == true;
    _cachedSemanticsConfiguration = null;
    bool isEffectiveSemanticsBoundary =
        _semanticsConfiguration.isSemanticBoundary && wasSemanticsBoundary;
    RenderObject node = this;

    while (!isEffectiveSemanticsBoundary && node.parent is RenderObject) {
      if (node != this && node._needsSemanticsUpdate) break;
      node._needsSemanticsUpdate = true;

      node = node.parent;
      isEffectiveSemanticsBoundary =
          node._semanticsConfiguration.isSemanticBoundary;
      if (isEffectiveSemanticsBoundary && node._semantics == null) {
        return;
      }
    }
    if (node != this && _semantics != null && _needsSemanticsUpdate) {
      owner._nodesNeedingSemantics.remove(this);
    }
    if (!node._needsSemanticsUpdate) {
      node._needsSemanticsUpdate = true;
      if (owner != null) {
        assert(node._semanticsConfiguration.isSemanticBoundary ||
            node.parent is! RenderObject);
        owner._nodesNeedingSemantics.add(node);
        owner.requestVisualUpdate();
      }
    }
  }

  void _updateSemantics() {
    assert(
        _semanticsConfiguration.isSemanticBoundary || parent is! RenderObject);
    if (_needsLayout) {
      return;
    }
    final _SemanticsFragment fragment = _getSemanticsForParent(
      mergeIntoParent: _semantics?.parent?.isPartOfNodeMerging ?? false,
    );
    assert(fragment is _InterestingSemanticsFragment);
    final _InterestingSemanticsFragment interestingFragment = fragment;
    final SemanticsNode node = interestingFragment
        .compileChildren(
          parentSemanticsClipRect: _semantics?.parentSemanticsClipRect,
          parentPaintClipRect: _semantics?.parentPaintClipRect,
          elevationAdjustment: _semantics?.elevationAdjustment ?? 0.0,
        )
        .single;

    assert(interestingFragment.config == null && node == _semantics);
  }

  _SemanticsFragment _getSemanticsForParent({
    @required bool mergeIntoParent,
  }) {
    assert(mergeIntoParent != null);
    assert(!_needsLayout,
        'Updated layout information required for $this to calculate semantics.');

    final SemanticsConfiguration config = _semanticsConfiguration;
    bool dropSemanticsOfPreviousSiblings =
        config.isBlockingSemanticsOfPreviouslyPaintedNodes;

    final bool producesForkingFragment =
        !config.hasBeenAnnotated && !config.isSemanticBoundary;
    final List<_InterestingSemanticsFragment> fragments =
        <_InterestingSemanticsFragment>[];
    final Set<_InterestingSemanticsFragment> toBeMarkedExplicit =
        <_InterestingSemanticsFragment>{};
    final bool childrenMergeIntoParent =
        mergeIntoParent || config.isMergingSemanticsOfDescendants;

    bool abortWalk = false;

    visitChildrenForSemantics((RenderObject renderChild) {
      if (abortWalk || _needsLayout) {
        abortWalk = true;
        return;
      }
      final _SemanticsFragment parentFragment =
          renderChild._getSemanticsForParent(
        mergeIntoParent: childrenMergeIntoParent,
      );
      if (parentFragment.abortsWalk) {
        abortWalk = true;
        return;
      }
      if (parentFragment.dropsSemanticsOfPreviousSiblings) {
        fragments.clear();
        toBeMarkedExplicit.clear();
        if (!config.isSemanticBoundary) dropSemanticsOfPreviousSiblings = true;
      }

      for (_InterestingSemanticsFragment fragment
          in parentFragment.interestingFragments) {
        fragments.add(fragment);
        fragment.addAncestor(this);
        fragment.addTags(config.tagsForChildren);
        if (config.explicitChildNodes || parent is! RenderObject) {
          fragment.markAsExplicit();
          continue;
        }
        if (!fragment.hasConfigForParent || producesForkingFragment) continue;
        if (!config.isCompatibleWith(fragment.config))
          toBeMarkedExplicit.add(fragment);
        for (_InterestingSemanticsFragment siblingFragment
            in fragments.sublist(0, fragments.length - 1)) {
          if (!fragment.config.isCompatibleWith(siblingFragment.config)) {
            toBeMarkedExplicit.add(fragment);
            toBeMarkedExplicit.add(siblingFragment);
          }
        }
      }
    });

    if (abortWalk) {
      return _AbortingSemanticsFragment(owner: this);
    }

    for (_InterestingSemanticsFragment fragment in toBeMarkedExplicit)
      fragment.markAsExplicit();

    _needsSemanticsUpdate = false;

    _SemanticsFragment result;
    if (parent is! RenderObject) {
      assert(!config.hasBeenAnnotated);
      assert(!mergeIntoParent);
      result = _RootSemanticsFragment(
        owner: this,
        dropsSemanticsOfPreviousSiblings: dropSemanticsOfPreviousSiblings,
      );
    } else if (producesForkingFragment) {
      result = _ContainerSemanticsFragment(
        dropsSemanticsOfPreviousSiblings: dropSemanticsOfPreviousSiblings,
      );
    } else {
      result = _SwitchableSemanticsFragment(
        config: config,
        mergeIntoParent: mergeIntoParent,
        owner: this,
        dropsSemanticsOfPreviousSiblings: dropSemanticsOfPreviousSiblings,
      );
      if (config.isSemanticBoundary) {
        final _SwitchableSemanticsFragment fragment = result;
        fragment.markAsExplicit();
      }
    }

    result.addAll(fragments);

    return result;
  }

  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    visitChildren(visitor);
  }

  void assembleSemanticsNode(
    SemanticsNode node,
    SemanticsConfiguration config,
    Iterable<SemanticsNode> children,
  ) {
    assert(node == _semantics);
    node.updateWith(config: config, childrenInInversePaintOrder: children);
  }

  @override
  void handleEvent(PointerEvent event, covariant HitTestEntry entry) {}

  @override
  String toStringShort() {
    String header = describeIdentity(this);
    if (_relayoutBoundary != null && _relayoutBoundary != this) {
      int count = 1;
      RenderObject target = parent;
      while (target != null && target != _relayoutBoundary) {
        target = target.parent;
        count += 1;
      }
      header += ' relayoutBoundary=up$count';
    }
    if (_needsLayout) header += ' NEEDS-LAYOUT';
    if (_needsPaint) header += ' NEEDS-PAINT';
    if (_needsCompositingBitsUpdate) header += ' NEEDS-COMPOSITING-BITS-UPDATE';
    if (!attached) header += ' DETACHED';
    return header;
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.debug}) =>
      toStringShort();

  @override
  String toStringDeep({
    String prefixLineOne = '',
    String prefixOtherLines = '',
    DiagnosticLevel minLevel = DiagnosticLevel.debug,
  }) {
    RenderObject debugPreviousActiveLayout;
    assert(() {
      debugPreviousActiveLayout = _debugActiveLayout;
      _debugActiveLayout = null;
      return true;
    }());
    final String result = super.toStringDeep(
      prefixLineOne: prefixLineOne,
      prefixOtherLines: prefixOtherLines,
      minLevel: minLevel,
    );
    assert(() {
      _debugActiveLayout = debugPreviousActiveLayout;
      return true;
    }());
    return result;
  }

  @override
  String toStringShallow({
    String joiner = ', ',
    DiagnosticLevel minLevel = DiagnosticLevel.debug,
  }) {
    RenderObject debugPreviousActiveLayout;
    assert(() {
      debugPreviousActiveLayout = _debugActiveLayout;
      _debugActiveLayout = null;
      return true;
    }());
    final String result =
        super.toStringShallow(joiner: joiner, minLevel: minLevel);
    assert(() {
      _debugActiveLayout = debugPreviousActiveLayout;
      return true;
    }());
    return result;
  }

  @protected
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagProperty('needsCompositing',
        value: _needsCompositing, ifTrue: 'needs compositing'));
    properties.add(DiagnosticsProperty<dynamic>('creator', debugCreator,
        defaultValue: null, level: DiagnosticLevel.debug));
    properties.add(DiagnosticsProperty<ParentData>('parentData', parentData,
        tooltip: _debugCanParentUseSize == true ? 'can use size' : null,
        missingIfNull: true));
    properties.add(DiagnosticsProperty<Constraints>('constraints', constraints,
        missingIfNull: true));

    properties.add(DiagnosticsProperty<ContainerLayer>('layer', _layer,
        defaultValue: null));
    properties.add(DiagnosticsProperty<SemanticsNode>(
        'semantics node', _semantics,
        defaultValue: null));
    properties.add(FlagProperty(
      'isBlockingSemanticsOfPreviouslyPaintedNodes',
      value:
          _semanticsConfiguration.isBlockingSemanticsOfPreviouslyPaintedNodes,
      ifTrue:
          'blocks semantics of earlier render objects below the common boundary',
    ));
    properties.add(FlagProperty('isSemanticBoundary',
        value: _semanticsConfiguration.isSemanticBoundary,
        ifTrue: 'semantic boundary'));
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() => <DiagnosticsNode>[];

  void showOnScreen({
    RenderObject descendant,
    Rect rect,
    Duration duration = Duration.zero,
    Curve curve = Curves.ease,
  }) {
    if (parent is RenderObject) {
      final RenderObject renderParent = parent;
      renderParent.showOnScreen(
        descendant: descendant ?? this,
        rect: rect,
        duration: duration,
        curve: curve,
      );
    }
  }

  DiagnosticsNode describeForError(String name,
      {DiagnosticsTreeStyle style = DiagnosticsTreeStyle.shallow}) {
    return toDiagnosticsNode(name: name, style: style);
  }
}

mixin RenderObjectWithChildMixin<ChildType extends RenderObject>
    on RenderObject {
  bool debugValidateChild(RenderObject child) {
    assert(() {
      if (child is! ChildType) {
        throw FlutterError(
            'A $runtimeType expected a child of type $ChildType but received a '
            'child of type ${child.runtimeType}.\n'
            'RenderObjects expect specific types of children because they '
            'coordinate with their children during layout and paint. For '
            'example, a RenderSliver cannot be the child of a RenderBox because '
            'a RenderSliver does not understand the RenderBox layout protocol.\n'
            '\n'
            'The $runtimeType that expected a $ChildType child was created by:\n'
            '  $debugCreator\n'
            '\n'
            'The ${child.runtimeType} that did not match the expected child type '
            'was created by:\n'
            '  ${child.debugCreator}\n');
      }
      return true;
    }());
    return true;
  }

  ChildType _child;

  ChildType get child => _child;
  set child(ChildType value) {
    if (_child != null) dropChild(_child);
    _child = value;
    if (_child != null) adoptChild(_child);
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    if (_child != null) _child.attach(owner);
  }

  @override
  void detach() {
    super.detach();
    if (_child != null) _child.detach();
  }

  @override
  void redepthChildren() {
    if (_child != null) redepthChild(_child);
  }

  @override
  void visitChildren(RenderObjectVisitor visitor) {
    if (_child != null) visitor(_child);
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return child != null
        ? <DiagnosticsNode>[child.toDiagnosticsNode(name: 'child')]
        : <DiagnosticsNode>[];
  }
}

mixin ContainerParentDataMixin<ChildType extends RenderObject> on ParentData {
  ChildType previousSibling;

  ChildType nextSibling;

  @override
  void detach() {
    super.detach();
    if (previousSibling != null) {
      final ContainerParentDataMixin<ChildType> previousSiblingParentData =
          previousSibling.parentData;
      assert(previousSibling != this);
      assert(previousSiblingParentData.nextSibling == this);
      previousSiblingParentData.nextSibling = nextSibling;
    }
    if (nextSibling != null) {
      final ContainerParentDataMixin<ChildType> nextSiblingParentData =
          nextSibling.parentData;
      assert(nextSibling != this);
      assert(nextSiblingParentData.previousSibling == this);
      nextSiblingParentData.previousSibling = previousSibling;
    }
    previousSibling = null;
    nextSibling = null;
  }
}

mixin ContainerRenderObjectMixin<ChildType extends RenderObject,
        ParentDataType extends ContainerParentDataMixin<ChildType>>
    on RenderObject {
  bool _debugUltimatePreviousSiblingOf(ChildType child, {ChildType equals}) {
    ParentDataType childParentData = child.parentData;
    while (childParentData.previousSibling != null) {
      assert(childParentData.previousSibling != child);
      child = childParentData.previousSibling;
      childParentData = child.parentData;
    }
    return child == equals;
  }

  bool _debugUltimateNextSiblingOf(ChildType child, {ChildType equals}) {
    ParentDataType childParentData = child.parentData;
    while (childParentData.nextSibling != null) {
      assert(childParentData.nextSibling != child);
      child = childParentData.nextSibling;
      childParentData = child.parentData;
    }
    return child == equals;
  }

  int _childCount = 0;

  int get childCount => _childCount;

  bool debugValidateChild(RenderObject child) {
    assert(() {
      if (child is! ChildType) {
        throw FlutterError(
            'A $runtimeType expected a child of type $ChildType but received a '
            'child of type ${child.runtimeType}.\n'
            'RenderObjects expect specific types of children because they '
            'coordinate with their children during layout and paint. For '
            'example, a RenderSliver cannot be the child of a RenderBox because '
            'a RenderSliver does not understand the RenderBox layout protocol.\n'
            '\n'
            'The $runtimeType that expected a $ChildType child was created by:\n'
            '  $debugCreator\n'
            '\n'
            'The ${child.runtimeType} that did not match the expected child type '
            'was created by:\n'
            '  ${child.debugCreator}\n');
      }
      return true;
    }());
    return true;
  }

  ChildType _firstChild;
  ChildType _lastChild;
  void _insertIntoChildList(ChildType child, {ChildType after}) {
    final ParentDataType childParentData = child.parentData;
    assert(childParentData.nextSibling == null);
    assert(childParentData.previousSibling == null);
    _childCount += 1;
    assert(_childCount > 0);
    if (after == null) {
      childParentData.nextSibling = _firstChild;
      if (_firstChild != null) {
        final ParentDataType _firstChildParentData = _firstChild.parentData;
        _firstChildParentData.previousSibling = child;
      }
      _firstChild = child;
      _lastChild ??= child;
    } else {
      assert(_firstChild != null);
      assert(_lastChild != null);
      assert(_debugUltimatePreviousSiblingOf(after, equals: _firstChild));
      assert(_debugUltimateNextSiblingOf(after, equals: _lastChild));
      final ParentDataType afterParentData = after.parentData;
      if (afterParentData.nextSibling == null) {
        assert(after == _lastChild);
        childParentData.previousSibling = after;
        afterParentData.nextSibling = child;
        _lastChild = child;
      } else {
        childParentData.nextSibling = afterParentData.nextSibling;
        childParentData.previousSibling = after;

        final ParentDataType childPreviousSiblingParentData =
            childParentData.previousSibling.parentData;
        final ParentDataType childNextSiblingParentData =
            childParentData.nextSibling.parentData;
        childPreviousSiblingParentData.nextSibling = child;
        childNextSiblingParentData.previousSibling = child;
        assert(afterParentData.nextSibling == child);
      }
    }
  }

  void insert(ChildType child, {ChildType after}) {
    assert(child != this, 'A RenderObject cannot be inserted into itself.');
    assert(after != this,
        'A RenderObject cannot simultaneously be both the parent and the sibling of another RenderObject.');
    assert(child != after, 'A RenderObject cannot be inserted after itself.');
    assert(child != _firstChild);
    assert(child != _lastChild);
    adoptChild(child);
    _insertIntoChildList(child, after: after);
  }

  void add(ChildType child) {
    insert(child, after: _lastChild);
  }

  void addAll(List<ChildType> children) {
    children?.forEach(add);
  }

  void _removeFromChildList(ChildType child) {
    final ParentDataType childParentData = child.parentData;
    assert(_debugUltimatePreviousSiblingOf(child, equals: _firstChild));
    assert(_debugUltimateNextSiblingOf(child, equals: _lastChild));
    assert(_childCount >= 0);
    if (childParentData.previousSibling == null) {
      assert(_firstChild == child);
      _firstChild = childParentData.nextSibling;
    } else {
      final ParentDataType childPreviousSiblingParentData =
          childParentData.previousSibling.parentData;
      childPreviousSiblingParentData.nextSibling = childParentData.nextSibling;
    }
    if (childParentData.nextSibling == null) {
      assert(_lastChild == child);
      _lastChild = childParentData.previousSibling;
    } else {
      final ParentDataType childNextSiblingParentData =
          childParentData.nextSibling.parentData;
      childNextSiblingParentData.previousSibling =
          childParentData.previousSibling;
    }
    childParentData.previousSibling = null;
    childParentData.nextSibling = null;
    _childCount -= 1;
  }

  void remove(ChildType child) {
    _removeFromChildList(child);
    dropChild(child);
  }

  void removeAll() {
    ChildType child = _firstChild;
    while (child != null) {
      final ParentDataType childParentData = child.parentData;
      final ChildType next = childParentData.nextSibling;
      childParentData.previousSibling = null;
      childParentData.nextSibling = null;
      dropChild(child);
      child = next;
    }
    _firstChild = null;
    _lastChild = null;
    _childCount = 0;
  }

  void move(ChildType child, {ChildType after}) {
    assert(child != this);
    assert(after != this);
    assert(child != after);
    assert(child.parent == this);
    final ParentDataType childParentData = child.parentData;
    if (childParentData.previousSibling == after) return;
    _removeFromChildList(child);
    _insertIntoChildList(child, after: after);
    markNeedsLayout();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    ChildType child = _firstChild;
    while (child != null) {
      child.attach(owner);
      final ParentDataType childParentData = child.parentData;
      child = childParentData.nextSibling;
    }
  }

  @override
  void detach() {
    super.detach();
    ChildType child = _firstChild;
    while (child != null) {
      child.detach();
      final ParentDataType childParentData = child.parentData;
      child = childParentData.nextSibling;
    }
  }

  @override
  void redepthChildren() {
    ChildType child = _firstChild;
    while (child != null) {
      redepthChild(child);
      final ParentDataType childParentData = child.parentData;
      child = childParentData.nextSibling;
    }
  }

  @override
  void visitChildren(RenderObjectVisitor visitor) {
    ChildType child = _firstChild;
    while (child != null) {
      visitor(child);
      final ParentDataType childParentData = child.parentData;
      child = childParentData.nextSibling;
    }
  }

  ChildType get firstChild => _firstChild;

  ChildType get lastChild => _lastChild;

  ChildType childBefore(ChildType child) {
    assert(child != null);
    assert(child.parent == this);
    final ParentDataType childParentData = child.parentData;
    return childParentData.previousSibling;
  }

  ChildType childAfter(ChildType child) {
    assert(child != null);
    assert(child.parent == this);
    final ParentDataType childParentData = child.parentData;
    return childParentData.nextSibling;
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    final List<DiagnosticsNode> children = <DiagnosticsNode>[];
    if (firstChild != null) {
      ChildType child = firstChild;
      int count = 1;
      while (true) {
        children.add(child.toDiagnosticsNode(name: 'child $count'));
        if (child == lastChild) break;
        count += 1;
        final ParentDataType childParentData = child.parentData;
        child = childParentData.nextSibling;
      }
    }
    return children;
  }
}

class FlutterErrorDetailsForRendering extends FlutterErrorDetails {
  const FlutterErrorDetailsForRendering({
    dynamic exception,
    StackTrace stack,
    String library,
    DiagnosticsNode context,
    this.renderObject,
    InformationCollector informationCollector,
    bool silent = false,
  }) : super(
            exception: exception,
            stack: stack,
            library: library,
            context: context,
            informationCollector: informationCollector,
            silent: silent);

  final RenderObject renderObject;
}

abstract class _SemanticsFragment {
  _SemanticsFragment({@required this.dropsSemanticsOfPreviousSiblings})
      : assert(dropsSemanticsOfPreviousSiblings != null);

  void addAll(Iterable<_InterestingSemanticsFragment> fragments);

  final bool dropsSemanticsOfPreviousSiblings;

  Iterable<_InterestingSemanticsFragment> get interestingFragments;

  bool get abortsWalk => false;
}

class _ContainerSemanticsFragment extends _SemanticsFragment {
  _ContainerSemanticsFragment({@required bool dropsSemanticsOfPreviousSiblings})
      : super(
            dropsSemanticsOfPreviousSiblings: dropsSemanticsOfPreviousSiblings);

  @override
  void addAll(Iterable<_InterestingSemanticsFragment> fragments) {
    interestingFragments.addAll(fragments);
  }

  @override
  final List<_InterestingSemanticsFragment> interestingFragments =
      <_InterestingSemanticsFragment>[];
}

abstract class _InterestingSemanticsFragment extends _SemanticsFragment {
  _InterestingSemanticsFragment({
    @required RenderObject owner,
    @required bool dropsSemanticsOfPreviousSiblings,
  })  : assert(owner != null),
        _ancestorChain = <RenderObject>[owner],
        super(
            dropsSemanticsOfPreviousSiblings: dropsSemanticsOfPreviousSiblings);

  RenderObject get owner => _ancestorChain.first;

  final List<RenderObject> _ancestorChain;

  Iterable<SemanticsNode> compileChildren({
    @required Rect parentSemanticsClipRect,
    @required Rect parentPaintClipRect,
    @required double elevationAdjustment,
  });

  SemanticsConfiguration get config;

  void markAsExplicit();

  @override
  void addAll(Iterable<_InterestingSemanticsFragment> fragments);

  bool get hasConfigForParent => config != null;

  @override
  Iterable<_InterestingSemanticsFragment> get interestingFragments sync* {
    yield this;
  }

  Set<SemanticsTag> _tagsForChildren;

  void addTags(Iterable<SemanticsTag> tags) {
    if (tags == null || tags.isEmpty) return;
    _tagsForChildren ??= <SemanticsTag>{};
    _tagsForChildren.addAll(tags);
  }

  void addAncestor(RenderObject ancestor) {
    _ancestorChain.add(ancestor);
  }
}

class _RootSemanticsFragment extends _InterestingSemanticsFragment {
  _RootSemanticsFragment({
    @required RenderObject owner,
    @required bool dropsSemanticsOfPreviousSiblings,
  }) : super(
            owner: owner,
            dropsSemanticsOfPreviousSiblings: dropsSemanticsOfPreviousSiblings);

  @override
  Iterable<SemanticsNode> compileChildren(
      {Rect parentSemanticsClipRect,
      Rect parentPaintClipRect,
      double elevationAdjustment}) sync* {
    assert(_tagsForChildren == null || _tagsForChildren.isEmpty);
    assert(parentSemanticsClipRect == null);
    assert(parentPaintClipRect == null);
    assert(_ancestorChain.length == 1);
    assert(elevationAdjustment == 0.0);

    owner._semantics ??= SemanticsNode.root(
      showOnScreen: owner.showOnScreen,
      owner: owner.owner.semanticsOwner,
    );
    final SemanticsNode node = owner._semantics;
    assert(MatrixUtils.matrixEquals(node.transform, Matrix4.identity()));
    assert(node.parentSemanticsClipRect == null);
    assert(node.parentPaintClipRect == null);

    node.rect = owner.semanticBounds;

    final List<SemanticsNode> children = <SemanticsNode>[];
    for (_InterestingSemanticsFragment fragment in _children) {
      assert(fragment.config == null);
      children.addAll(fragment.compileChildren(
        parentSemanticsClipRect: parentSemanticsClipRect,
        parentPaintClipRect: parentPaintClipRect,
        elevationAdjustment: 0.0,
      ));
    }
    node.updateWith(config: null, childrenInInversePaintOrder: children);

    assert(!node.isInvisible || children.isEmpty);
    yield node;
  }

  @override
  SemanticsConfiguration get config => null;

  final List<_InterestingSemanticsFragment> _children =
      <_InterestingSemanticsFragment>[];

  @override
  void markAsExplicit() {}

  @override
  void addAll(Iterable<_InterestingSemanticsFragment> fragments) {
    _children.addAll(fragments);
  }
}

class _SwitchableSemanticsFragment extends _InterestingSemanticsFragment {
  _SwitchableSemanticsFragment({
    @required bool mergeIntoParent,
    @required SemanticsConfiguration config,
    @required RenderObject owner,
    @required bool dropsSemanticsOfPreviousSiblings,
  })  : _mergeIntoParent = mergeIntoParent,
        _config = config,
        assert(mergeIntoParent != null),
        assert(config != null),
        super(
            owner: owner,
            dropsSemanticsOfPreviousSiblings: dropsSemanticsOfPreviousSiblings);

  final bool _mergeIntoParent;
  SemanticsConfiguration _config;
  bool _isConfigWritable = false;
  final List<_InterestingSemanticsFragment> _children =
      <_InterestingSemanticsFragment>[];

  @override
  Iterable<SemanticsNode> compileChildren(
      {Rect parentSemanticsClipRect,
      Rect parentPaintClipRect,
      double elevationAdjustment}) sync* {
    if (!_isExplicit) {
      owner._semantics = null;
      for (_InterestingSemanticsFragment fragment in _children) {
        assert(_ancestorChain.first == fragment._ancestorChain.last);
        fragment._ancestorChain.addAll(_ancestorChain.sublist(1));
        yield* fragment.compileChildren(
          parentSemanticsClipRect: parentSemanticsClipRect,
          parentPaintClipRect: parentPaintClipRect,
          elevationAdjustment: elevationAdjustment + _config.elevation,
        );
      }
      return;
    }

    final _SemanticsGeometry geometry = _needsGeometryUpdate
        ? _SemanticsGeometry(
            parentSemanticsClipRect: parentSemanticsClipRect,
            parentPaintClipRect: parentPaintClipRect,
            ancestors: _ancestorChain)
        : null;

    if (!_mergeIntoParent && (geometry?.dropFromTree == true)) return;

    owner._semantics ??= SemanticsNode(showOnScreen: owner.showOnScreen);
    final SemanticsNode node = owner._semantics
      ..isMergedIntoParent = _mergeIntoParent
      ..tags = _tagsForChildren;

    node.elevationAdjustment = elevationAdjustment;
    if (elevationAdjustment != 0.0) {
      _ensureConfigIsWritable();
      _config.elevation += elevationAdjustment;
    }

    if (geometry != null) {
      assert(_needsGeometryUpdate);
      node
        ..rect = geometry.rect
        ..transform = geometry.transform
        ..parentSemanticsClipRect = geometry.semanticsClipRect
        ..parentPaintClipRect = geometry.paintClipRect;
      if (!_mergeIntoParent && geometry.markAsHidden) {
        _ensureConfigIsWritable();
        _config.isHidden = true;
      }
    }

    final List<SemanticsNode> children = <SemanticsNode>[];
    for (_InterestingSemanticsFragment fragment in _children) {
      children.addAll(fragment.compileChildren(
        parentSemanticsClipRect: node.parentSemanticsClipRect,
        parentPaintClipRect: node.parentPaintClipRect,
        elevationAdjustment: 0.0,
      ));
    }

    if (_config.isSemanticBoundary) {
      owner.assembleSemanticsNode(node, _config, children);
    } else {
      node.updateWith(config: _config, childrenInInversePaintOrder: children);
    }

    yield node;
  }

  @override
  SemanticsConfiguration get config {
    return _isExplicit ? null : _config;
  }

  @override
  void addAll(Iterable<_InterestingSemanticsFragment> fragments) {
    for (_InterestingSemanticsFragment fragment in fragments) {
      _children.add(fragment);
      if (fragment.config == null) continue;
      _ensureConfigIsWritable();
      _config.absorb(fragment.config);
    }
  }

  void _ensureConfigIsWritable() {
    if (!_isConfigWritable) {
      _config = _config.copy();
      _isConfigWritable = true;
    }
  }

  bool _isExplicit = false;

  @override
  void markAsExplicit() {
    _isExplicit = true;
  }

  bool get _needsGeometryUpdate => _ancestorChain.length > 1;
}

class _AbortingSemanticsFragment extends _InterestingSemanticsFragment {
  _AbortingSemanticsFragment({@required RenderObject owner})
      : super(owner: owner, dropsSemanticsOfPreviousSiblings: false);

  @override
  bool get abortsWalk => true;

  @override
  SemanticsConfiguration get config => null;

  @override
  void addAll(Iterable<_InterestingSemanticsFragment> fragments) {
    assert(false);
  }

  @override
  Iterable<SemanticsNode> compileChildren(
      {Rect parentSemanticsClipRect,
      Rect parentPaintClipRect,
      double elevationAdjustment}) sync* {
    yield owner._semantics;
  }

  @override
  void markAsExplicit() {}
}

class _SemanticsGeometry {
  _SemanticsGeometry({
    @required Rect parentSemanticsClipRect,
    @required Rect parentPaintClipRect,
    @required List<RenderObject> ancestors,
  }) {
    _computeValues(parentSemanticsClipRect, parentPaintClipRect, ancestors);
  }

  Rect _paintClipRect;
  Rect _semanticsClipRect;
  Matrix4 _transform;
  Rect _rect;

  Matrix4 get transform => _transform;

  Rect get semanticsClipRect => _semanticsClipRect;

  Rect get paintClipRect => _paintClipRect;

  Rect get rect => _rect;

  void _computeValues(Rect parentSemanticsClipRect, Rect parentPaintClipRect,
      List<RenderObject> ancestors) {
    assert(ancestors.length > 1);

    _transform = Matrix4.identity();
    _semanticsClipRect = parentSemanticsClipRect;
    _paintClipRect = parentPaintClipRect;
    for (int index = ancestors.length - 1; index > 0; index -= 1) {
      final RenderObject parent = ancestors[index];
      final RenderObject child = ancestors[index - 1];
      final Rect parentSemanticsClipRect = parent.describeSemanticsClip(child);
      if (parentSemanticsClipRect != null) {
        _semanticsClipRect = parentSemanticsClipRect;
        _paintClipRect = _intersectRects(
            _paintClipRect, parent.describeApproximatePaintClip(child));
      } else {
        _semanticsClipRect = _intersectRects(
            _semanticsClipRect, parent.describeApproximatePaintClip(child));
      }
      _temporaryTransformHolder.setIdentity();
      _applyIntermediatePaintTransforms(
          parent, child, _transform, _temporaryTransformHolder);
      _semanticsClipRect =
          _transformRect(_semanticsClipRect, _temporaryTransformHolder);
      _paintClipRect =
          _transformRect(_paintClipRect, _temporaryTransformHolder);
    }

    final RenderObject owner = ancestors.first;
    _rect = _semanticsClipRect == null
        ? owner.semanticBounds
        : _semanticsClipRect.intersect(owner.semanticBounds);
    if (_paintClipRect != null) {
      final Rect paintRect = _paintClipRect.intersect(_rect);
      _markAsHidden = paintRect.isEmpty && !_rect.isEmpty;
      if (!_markAsHidden) _rect = paintRect;
    }
  }

  static final Matrix4 _temporaryTransformHolder = Matrix4.zero();

  static Rect _transformRect(Rect rect, Matrix4 transform) {
    assert(transform != null);
    if (rect == null) return null;
    if (rect.isEmpty || transform.isZero()) return Rect.zero;
    return MatrixUtils.inverseTransformRect(transform, rect);
  }

  static void _applyIntermediatePaintTransforms(
    RenderObject ancestor,
    RenderObject child,
    Matrix4 transform,
    Matrix4 clipRectTransform,
  ) {
    assert(ancestor != null);
    assert(child != null);
    assert(transform != null);
    assert(clipRectTransform != null);
    assert(clipRectTransform.isIdentity());
    RenderObject intermediateParent = child.parent;
    assert(intermediateParent != null);
    while (intermediateParent != ancestor) {
      intermediateParent.applyPaintTransform(child, transform);
      intermediateParent = intermediateParent.parent;
      child = child.parent;
      assert(intermediateParent != null);
    }
    ancestor.applyPaintTransform(child, transform);
    ancestor.applyPaintTransform(child, clipRectTransform);
  }

  static Rect _intersectRects(Rect a, Rect b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.intersect(b);
  }

  bool get dropFromTree {
    return _rect.isEmpty;
  }

  bool get markAsHidden => _markAsHidden;
  bool _markAsHidden = false;
}

class DiagnosticsDebugCreator extends DiagnosticsProperty<Object> {
  DiagnosticsDebugCreator(Object value)
      : assert(value != null),
        super('debugCreator', value, level: DiagnosticLevel.hidden);
}

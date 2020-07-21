import 'dart:math' as math;

import 'package:flutter_web/animation.dart';
import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/gestures.dart';
import 'package:flutter_web/semantics.dart';
import 'package:vector_math/vector_math_64.dart';

import 'box.dart';
import 'object.dart';
import 'sliver.dart';
import 'viewport_offset.dart';

abstract class RenderAbstractViewport extends RenderObject {
  factory RenderAbstractViewport._() => null;

  static RenderAbstractViewport of(RenderObject object) {
    while (object != null) {
      if (object is RenderAbstractViewport) return object;
      object = object.parent;
    }
    return null;
  }

  RevealedOffset getOffsetToReveal(RenderObject target, double alignment,
      {Rect rect});

  @protected
  static const double defaultCacheExtent = 250.0;
}

class RevealedOffset {
  const RevealedOffset({
    @required this.offset,
    @required this.rect,
  })  : assert(offset != null),
        assert(rect != null);

  final double offset;

  final Rect rect;

  @override
  String toString() {
    return '$runtimeType(offset: $offset, rect: $rect)';
  }
}

abstract class RenderViewportBase<
        ParentDataClass extends ContainerParentDataMixin<RenderSliver>>
    extends RenderBox
    with ContainerRenderObjectMixin<RenderSliver, ParentDataClass>
    implements RenderAbstractViewport {
  RenderViewportBase({
    AxisDirection axisDirection = AxisDirection.down,
    @required AxisDirection crossAxisDirection,
    @required ViewportOffset offset,
    double cacheExtent,
  })  : assert(axisDirection != null),
        assert(crossAxisDirection != null),
        assert(offset != null),
        assert(axisDirectionToAxis(axisDirection) !=
            axisDirectionToAxis(crossAxisDirection)),
        _axisDirection = axisDirection,
        _crossAxisDirection = crossAxisDirection,
        _offset = offset,
        _cacheExtent = cacheExtent ?? RenderAbstractViewport.defaultCacheExtent;

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);

    config.addTagForChildren(RenderViewport.useTwoPaneSemantics);
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    childrenInPaintOrder
        .where((RenderSliver sliver) =>
            sliver.geometry.visible || sliver.geometry.cacheExtent > 0.0)
        .forEach(visitor);
  }

  AxisDirection get axisDirection => _axisDirection;
  AxisDirection _axisDirection;
  set axisDirection(AxisDirection value) {
    assert(value != null);
    if (value == _axisDirection) return;
    _axisDirection = value;
    markNeedsLayout();
  }

  AxisDirection get crossAxisDirection => _crossAxisDirection;
  AxisDirection _crossAxisDirection;
  set crossAxisDirection(AxisDirection value) {
    assert(value != null);
    if (value == _crossAxisDirection) return;
    _crossAxisDirection = value;
    markNeedsLayout();
  }

  Axis get axis => axisDirectionToAxis(axisDirection);

  ViewportOffset get offset => _offset;
  ViewportOffset _offset;
  set offset(ViewportOffset value) {
    assert(value != null);
    if (value == _offset) return;
    if (attached) _offset.removeListener(markNeedsLayout);
    _offset = value;
    if (attached) _offset.addListener(markNeedsLayout);

    markNeedsLayout();
  }

  double get cacheExtent => _cacheExtent;
  double _cacheExtent;
  set cacheExtent(double value) {
    value = value ?? RenderAbstractViewport.defaultCacheExtent;
    assert(value != null);
    if (value == _cacheExtent) return;
    _cacheExtent = value;
    markNeedsLayout();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _offset.addListener(markNeedsLayout);
  }

  @override
  void detach() {
    _offset.removeListener(markNeedsLayout);
    super.detach();
  }

  @protected
  bool debugThrowIfNotCheckingIntrinsics() {
    assert(() {
      if (!RenderObject.debugCheckingIntrinsics) {
        assert(this is! RenderShrinkWrappingViewport);
        throw FlutterError(
            '$runtimeType does not support returning intrinsic dimensions.\n'
            'Calculating the intrinsic dimensions would require instantiating every child of '
            'the viewport, which defeats the point of viewports being lazy.\n'
            'If you are merely trying to shrink-wrap the viewport in the main axis direction, '
            'consider a RenderShrinkWrappingViewport render object (ShrinkWrappingViewport widget), '
            'which achieves that effect without implementing the intrinsic dimension API.');
      }
      return true;
    }());
    return true;
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    assert(debugThrowIfNotCheckingIntrinsics());
    return 0.0;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    assert(debugThrowIfNotCheckingIntrinsics());
    return 0.0;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    assert(debugThrowIfNotCheckingIntrinsics());
    return 0.0;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    assert(debugThrowIfNotCheckingIntrinsics());
    return 0.0;
  }

  @override
  bool get isRepaintBoundary => true;

  @protected
  double layoutChildSequence({
    @required RenderSliver child,
    @required double scrollOffset,
    @required double overlap,
    @required double layoutOffset,
    @required double remainingPaintExtent,
    @required double mainAxisExtent,
    @required double crossAxisExtent,
    @required GrowthDirection growthDirection,
    @required RenderSliver advance(RenderSliver child),
    @required double remainingCacheExtent,
    @required double cacheOrigin,
  }) {
    assert(scrollOffset.isFinite);
    assert(scrollOffset >= 0.0);
    final double initialLayoutOffset = layoutOffset;
    final ScrollDirection adjustedUserScrollDirection =
        applyGrowthDirectionToScrollDirection(
            offset.userScrollDirection, growthDirection);
    assert(adjustedUserScrollDirection != null);
    double maxPaintOffset = layoutOffset + overlap;
    double precedingScrollExtent = 0.0;

    while (child != null) {
      final double sliverScrollOffset =
          scrollOffset <= 0.0 ? 0.0 : scrollOffset;

      final double correctedCacheOrigin =
          math.max(cacheOrigin, -sliverScrollOffset);
      final double cacheExtentCorrection = cacheOrigin - correctedCacheOrigin;

      assert(sliverScrollOffset >= correctedCacheOrigin.abs());
      assert(correctedCacheOrigin <= 0.0);
      assert(sliverScrollOffset >= 0.0);
      assert(cacheExtentCorrection <= 0.0);

      child.layout(
          SliverConstraints(
            axisDirection: axisDirection,
            growthDirection: growthDirection,
            userScrollDirection: adjustedUserScrollDirection,
            scrollOffset: sliverScrollOffset,
            precedingScrollExtent: precedingScrollExtent,
            overlap: maxPaintOffset - layoutOffset,
            remainingPaintExtent: math.max(
                0.0, remainingPaintExtent - layoutOffset + initialLayoutOffset),
            crossAxisExtent: crossAxisExtent,
            crossAxisDirection: crossAxisDirection,
            viewportMainAxisExtent: mainAxisExtent,
            remainingCacheExtent:
                math.max(0.0, remainingCacheExtent + cacheExtentCorrection),
            cacheOrigin: correctedCacheOrigin,
          ),
          parentUsesSize: true);

      final SliverGeometry childLayoutGeometry = child.geometry;
      assert(childLayoutGeometry.debugAssertIsValid());

      if (childLayoutGeometry.scrollOffsetCorrection != null)
        return childLayoutGeometry.scrollOffsetCorrection;

      final double effectiveLayoutOffset =
          layoutOffset + childLayoutGeometry.paintOrigin;

      if (childLayoutGeometry.visible || scrollOffset > 0) {
        updateChildLayoutOffset(child, effectiveLayoutOffset, growthDirection);
      } else {
        updateChildLayoutOffset(
            child, -scrollOffset + initialLayoutOffset, growthDirection);
      }

      maxPaintOffset = math.max(
          effectiveLayoutOffset + childLayoutGeometry.paintExtent,
          maxPaintOffset);
      scrollOffset -= childLayoutGeometry.scrollExtent;
      precedingScrollExtent += childLayoutGeometry.scrollExtent;
      layoutOffset += childLayoutGeometry.layoutExtent;
      if (childLayoutGeometry.cacheExtent != 0.0) {
        remainingCacheExtent -=
            childLayoutGeometry.cacheExtent - cacheExtentCorrection;
        cacheOrigin = math.min(
            correctedCacheOrigin + childLayoutGeometry.cacheExtent, 0.0);
      }

      updateOutOfBandData(growthDirection, childLayoutGeometry);

      child = advance(child);
    }

    return 0.0;
  }

  @override
  Rect describeApproximatePaintClip(RenderSliver child) {
    final Rect viewportClip = Offset.zero & size;
    if (child.constraints.overlap == 0) {
      return viewportClip;
    }

    double left = viewportClip.left;
    double right = viewportClip.right;
    double top = viewportClip.top;
    double bottom = viewportClip.bottom;
    final double startOfOverlap = child.constraints.viewportMainAxisExtent -
        child.constraints.remainingPaintExtent;
    final double overlapCorrection = startOfOverlap + child.constraints.overlap;
    switch (applyGrowthDirectionToAxisDirection(
        axisDirection, child.constraints.growthDirection)) {
      case AxisDirection.down:
        top += overlapCorrection;
        break;
      case AxisDirection.up:
        bottom -= overlapCorrection;
        break;
      case AxisDirection.right:
        left += overlapCorrection;
        break;
      case AxisDirection.left:
        right -= overlapCorrection;
        break;
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }

  @override
  Rect describeSemanticsClip(RenderSliver child) {
    assert(axis != null);
    switch (axis) {
      case Axis.vertical:
        return Rect.fromLTRB(
          semanticBounds.left,
          semanticBounds.top - cacheExtent,
          semanticBounds.right,
          semanticBounds.bottom + cacheExtent,
        );
      case Axis.horizontal:
        return Rect.fromLTRB(
          semanticBounds.left - cacheExtent,
          semanticBounds.top,
          semanticBounds.right + cacheExtent,
          semanticBounds.bottom,
        );
    }
    return null;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (firstChild == null) return;
    if (hasVisualOverflow) {
      context.pushClipRect(
          needsCompositing, offset, Offset.zero & size, _paintContents);
    } else {
      _paintContents(context, offset);
    }
  }

  void _paintContents(PaintingContext context, Offset offset) {
    for (RenderSliver child in childrenInPaintOrder) {
      if (child.geometry.visible)
        context.paintChild(child, offset + paintOffsetOf(child));
    }
  }

  @override
  void debugPaintSize(PaintingContext context, Offset offset) {
    assert(() {
      super.debugPaintSize(context, offset);
      final Paint paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = const Color(0xFF00FF00);
      final Canvas canvas = context.canvas;
      RenderSliver child = firstChild;
      while (child != null) {
        Size size;
        switch (axis) {
          case Axis.vertical:
            size = Size(
                child.constraints.crossAxisExtent, child.geometry.layoutExtent);
            break;
          case Axis.horizontal:
            size = Size(
                child.geometry.layoutExtent, child.constraints.crossAxisExtent);
            break;
        }
        assert(size != null);
        canvas.drawRect(
            ((offset + paintOffsetOf(child)) & size).deflate(0.5), paint);
        child = childAfter(child);
      }
      return true;
    }());
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {Offset position}) {
    double mainAxisPosition, crossAxisPosition;
    switch (axis) {
      case Axis.vertical:
        mainAxisPosition = position.dy;
        crossAxisPosition = position.dx;
        break;
      case Axis.horizontal:
        mainAxisPosition = position.dx;
        crossAxisPosition = position.dy;
        break;
    }
    assert(mainAxisPosition != null);
    assert(crossAxisPosition != null);
    final SliverHitTestResult sliverResult = SliverHitTestResult.wrap(result);
    for (RenderSliver child in childrenInHitTestOrder) {
      if (!child.geometry.visible) {
        continue;
      }
      final Matrix4 transform = Matrix4.identity();
      applyPaintTransform(child, transform);
      final bool isHit = result.addWithPaintTransform(
        transform: transform,
        position: null,
        hitTest: (BoxHitTestResult result, Offset _) {
          return child.hitTest(
            sliverResult,
            mainAxisPosition:
                computeChildMainAxisPosition(child, mainAxisPosition),
            crossAxisPosition: crossAxisPosition,
          );
        },
      );
      if (isHit) {
        return true;
      }
    }
    return false;
  }

  @override
  RevealedOffset getOffsetToReveal(RenderObject target, double alignment,
      {Rect rect}) {
    double leadingScrollOffset = 0.0;
    double targetMainAxisExtent;
    rect ??= target.paintBounds;

    RenderObject child = target;
    RenderBox pivot;
    bool onlySlivers = target is RenderSliver;
    while (child.parent != this) {
      assert(child.parent != null, '$target must be a descendant of $this');
      if (child is RenderBox) {
        pivot = child;
      }
      if (child.parent is RenderSliver) {
        final RenderSliver parent = child.parent;
        leadingScrollOffset += parent.childScrollOffset(child);
      } else {
        onlySlivers = false;
        leadingScrollOffset = 0.0;
      }
      child = child.parent;
    }

    if (pivot != null) {
      assert(pivot.parent != null);
      assert(pivot.parent != this);
      assert(pivot != this);
      assert(pivot.parent is RenderSliver);
      final RenderSliver pivotParent = pivot.parent;

      final Matrix4 transform = target.getTransformTo(pivot);
      final Rect bounds = MatrixUtils.transformRect(transform, rect);

      final GrowthDirection growthDirection =
          pivotParent.constraints.growthDirection;
      switch (
          applyGrowthDirectionToAxisDirection(axisDirection, growthDirection)) {
        case AxisDirection.up:
          double offset;
          switch (growthDirection) {
            case GrowthDirection.forward:
              offset = bounds.bottom;
              break;
            case GrowthDirection.reverse:
              offset = bounds.top;
              break;
          }
          leadingScrollOffset += pivot.size.height - offset;
          targetMainAxisExtent = bounds.height;
          break;
        case AxisDirection.right:
          leadingScrollOffset += bounds.left;
          targetMainAxisExtent = bounds.width;
          break;
        case AxisDirection.down:
          leadingScrollOffset += bounds.top;
          targetMainAxisExtent = bounds.height;
          break;
        case AxisDirection.left:
          double offset;
          switch (growthDirection) {
            case GrowthDirection.forward:
              offset = bounds.right;
              break;
            case GrowthDirection.reverse:
              offset = bounds.left;
              break;
          }
          leadingScrollOffset += pivot.size.width - offset;
          targetMainAxisExtent = bounds.width;
          break;
      }
    } else if (onlySlivers) {
      final RenderSliver targetSliver = target;
      targetMainAxisExtent = targetSliver.geometry.scrollExtent;
    } else {
      return RevealedOffset(offset: offset.pixels, rect: rect);
    }

    assert(child.parent == this);
    assert(child is RenderSliver);
    final RenderSliver sliver = child;
    final double extentOfPinnedSlivers =
        maxScrollObstructionExtentBefore(sliver);
    leadingScrollOffset = scrollOffsetOf(sliver, leadingScrollOffset);
    switch (sliver.constraints.growthDirection) {
      case GrowthDirection.forward:
        leadingScrollOffset -= extentOfPinnedSlivers;
        break;
      case GrowthDirection.reverse:
        break;
    }

    double mainAxisExtent;
    switch (axis) {
      case Axis.horizontal:
        mainAxisExtent = size.width - extentOfPinnedSlivers;
        break;
      case Axis.vertical:
        mainAxisExtent = size.height - extentOfPinnedSlivers;
        break;
    }

    final double targetOffset = leadingScrollOffset -
        (mainAxisExtent - targetMainAxisExtent) * alignment;
    final double offsetDifference = offset.pixels - targetOffset;

    final Matrix4 transform = target.getTransformTo(this);
    applyPaintTransform(child, transform);
    Rect targetRect = MatrixUtils.transformRect(transform, rect);

    switch (axisDirection) {
      case AxisDirection.down:
        targetRect = targetRect.translate(0.0, offsetDifference);
        break;
      case AxisDirection.right:
        targetRect = targetRect.translate(offsetDifference, 0.0);
        break;
      case AxisDirection.up:
        targetRect = targetRect.translate(0.0, -offsetDifference);
        break;
      case AxisDirection.left:
        targetRect = targetRect.translate(-offsetDifference, 0.0);
        break;
    }

    return RevealedOffset(offset: targetOffset, rect: targetRect);
  }

  @protected
  Offset computeAbsolutePaintOffset(RenderSliver child, double layoutOffset,
      GrowthDirection growthDirection) {
    assert(hasSize);
    assert(axisDirection != null);
    assert(growthDirection != null);
    assert(child != null);
    assert(child.geometry != null);
    switch (
        applyGrowthDirectionToAxisDirection(axisDirection, growthDirection)) {
      case AxisDirection.up:
        return Offset(
            0.0, size.height - (layoutOffset + child.geometry.paintExtent));
      case AxisDirection.right:
        return Offset(layoutOffset, 0.0);
      case AxisDirection.down:
        return Offset(0.0, layoutOffset);
      case AxisDirection.left:
        return Offset(
            size.width - (layoutOffset + child.geometry.paintExtent), 0.0);
    }
    return null;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<AxisDirection>('axisDirection', axisDirection));
    properties.add(
        EnumProperty<AxisDirection>('crossAxisDirection', crossAxisDirection));
    properties.add(DiagnosticsProperty<ViewportOffset>('offset', offset));
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    final List<DiagnosticsNode> children = <DiagnosticsNode>[];
    RenderSliver child = firstChild;
    if (child == null) return children;

    int count = indexOfFirstChild;
    while (true) {
      children.add(child.toDiagnosticsNode(name: labelForChild(count)));
      if (child == lastChild) break;
      count += 1;
      child = childAfter(child);
    }
    return children;
  }

  @protected
  bool get hasVisualOverflow;

  @protected
  void updateOutOfBandData(
      GrowthDirection growthDirection, SliverGeometry childLayoutGeometry);

  @protected
  void updateChildLayoutOffset(
      RenderSliver child, double layoutOffset, GrowthDirection growthDirection);

  @protected
  Offset paintOffsetOf(RenderSliver child);

  @protected
  double scrollOffsetOf(RenderSliver child, double scrollOffsetWithinChild);

  @protected
  double maxScrollObstructionExtentBefore(RenderSliver child);

  @protected
  double computeChildMainAxisPosition(
      RenderSliver child, double parentMainAxisPosition);

  @protected
  int get indexOfFirstChild;

  @protected
  String labelForChild(int index);

  @protected
  Iterable<RenderSliver> get childrenInPaintOrder;

  @protected
  Iterable<RenderSliver> get childrenInHitTestOrder;

  @override
  void showOnScreen({
    RenderObject descendant,
    Rect rect,
    Duration duration = Duration.zero,
    Curve curve = Curves.ease,
  }) {
    if (!offset.allowImplicitScrolling) {
      return super.showOnScreen(
        descendant: descendant,
        rect: rect,
        duration: duration,
        curve: curve,
      );
    }

    final Rect newRect = RenderViewportBase.showInViewport(
      descendant: descendant,
      viewport: this,
      offset: offset,
      rect: rect,
      duration: duration,
      curve: curve,
    );
    super.showOnScreen(
      rect: newRect,
      duration: duration,
      curve: curve,
    );
  }

  static Rect showInViewport({
    RenderObject descendant,
    Rect rect,
    @required RenderAbstractViewport viewport,
    @required ViewportOffset offset,
    Duration duration = Duration.zero,
    Curve curve = Curves.ease,
  }) {
    assert(viewport != null);
    assert(offset != null);
    if (descendant == null) {
      return rect;
    }
    final RevealedOffset leadingEdgeOffset =
        viewport.getOffsetToReveal(descendant, 0.0, rect: rect);
    final RevealedOffset trailingEdgeOffset =
        viewport.getOffsetToReveal(descendant, 1.0, rect: rect);
    final double currentOffset = offset.pixels;

    RevealedOffset targetOffset;
    if (leadingEdgeOffset.offset < trailingEdgeOffset.offset) {
      final double leadingEdgeDiff =
          (offset.pixels - leadingEdgeOffset.offset).abs();
      final double trailingEdgeDiff =
          (offset.pixels - trailingEdgeOffset.offset).abs();
      targetOffset = leadingEdgeDiff < trailingEdgeDiff
          ? leadingEdgeOffset
          : trailingEdgeOffset;
    } else if (currentOffset > leadingEdgeOffset.offset) {
      targetOffset = leadingEdgeOffset;
    } else if (currentOffset < trailingEdgeOffset.offset) {
      targetOffset = trailingEdgeOffset;
    } else {
      final Matrix4 transform = descendant.getTransformTo(viewport.parent);
      return MatrixUtils.transformRect(
          transform, rect ?? descendant.paintBounds);
    }

    assert(targetOffset != null);

    offset.moveTo(targetOffset.offset, duration: duration, curve: curve);
    return targetOffset.rect;
  }
}

class RenderViewport
    extends RenderViewportBase<SliverPhysicalContainerParentData> {
  RenderViewport({
    AxisDirection axisDirection = AxisDirection.down,
    @required AxisDirection crossAxisDirection,
    @required ViewportOffset offset,
    double anchor = 0.0,
    List<RenderSliver> children,
    RenderSliver center,
    double cacheExtent,
  })  : assert(anchor != null),
        assert(anchor >= 0.0 && anchor <= 1.0),
        _anchor = anchor,
        _center = center,
        super(
            axisDirection: axisDirection,
            crossAxisDirection: crossAxisDirection,
            offset: offset,
            cacheExtent: cacheExtent) {
    addAll(children);
    if (center == null && firstChild != null) _center = firstChild;
  }

  static const SemanticsTag useTwoPaneSemantics =
      SemanticsTag('RenderViewport.twoPane');

  static const SemanticsTag excludeFromScrolling =
      SemanticsTag('RenderViewport.excludeFromScrolling');

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! SliverPhysicalContainerParentData)
      child.parentData = SliverPhysicalContainerParentData();
  }

  double get anchor => _anchor;
  double _anchor;
  set anchor(double value) {
    assert(value != null);
    assert(value >= 0.0 && value <= 1.0);
    if (value == _anchor) return;
    _anchor = value;
    markNeedsLayout();
  }

  RenderSliver get center => _center;
  RenderSliver _center;
  set center(RenderSliver value) {
    if (value == _center) return;
    _center = value;
    markNeedsLayout();
  }

  @override
  bool get sizedByParent => true;

  @override
  void performResize() {
    assert(() {
      if (!constraints.hasBoundedHeight || !constraints.hasBoundedWidth) {
        switch (axis) {
          case Axis.vertical:
            if (!constraints.hasBoundedHeight) {
              throw FlutterError(
                  'Vertical viewport was given unbounded height.\n'
                  'Viewports expand in the scrolling direction to fill their container.'
                  'In this case, a vertical viewport was given an unlimited amount of '
                  'vertical space in which to expand. This situation typically happens '
                  'when a scrollable widget is nested inside another scrollable widget.\n'
                  'If this widget is always nested in a scrollable widget there '
                  'is no need to use a viewport because there will always be enough '
                  'vertical space for the children. In this case, consider using a '
                  'Column instead. Otherwise, consider using the "shrinkWrap" property '
                  '(or a ShrinkWrappingViewport) to size the height of the viewport '
                  'to the sum of the heights of its children.');
            }
            if (!constraints.hasBoundedWidth) {
              throw FlutterError(
                  'Vertical viewport was given unbounded width.\n'
                  'Viewports expand in the cross axis to fill their container and '
                  'constrain their children to match their extent in the cross axis. '
                  'In this case, a vertical viewport was given an unlimited amount of '
                  'horizontal space in which to expand.');
            }
            break;
          case Axis.horizontal:
            if (!constraints.hasBoundedWidth) {
              throw FlutterError(
                  'Horizontal viewport was given unbounded width.\n'
                  'Viewports expand in the scrolling direction to fill their container.'
                  'In this case, a horizontal viewport was given an unlimited amount of '
                  'horizontal space in which to expand. This situation typically happens '
                  'when a scrollable widget is nested inside another scrollable widget.\n'
                  'If this widget is always nested in a scrollable widget there '
                  'is no need to use a viewport because there will always be enough '
                  'horizontal space for the children. In this case, consider using a '
                  'Row instead. Otherwise, consider using the "shrinkWrap" property '
                  '(or a ShrinkWrappingViewport) to size the width of the viewport '
                  'to the sum of the widths of its children.');
            }
            if (!constraints.hasBoundedHeight) {
              throw FlutterError(
                  'Horizontal viewport was given unbounded height.\n'
                  'Viewports expand in the cross axis to fill their container and '
                  'constrain their children to match their extent in the cross axis. '
                  'In this case, a horizontal viewport was given an unlimited amount of '
                  'vertical space in which to expand.');
            }
            break;
        }
      }
      return true;
    }());
    size = constraints.biggest;

    switch (axis) {
      case Axis.vertical:
        offset.applyViewportDimension(size.height);
        break;
      case Axis.horizontal:
        offset.applyViewportDimension(size.width);
        break;
    }
  }

  static const int _maxLayoutCycles = 10;

  double _minScrollExtent;
  double _maxScrollExtent;
  bool _hasVisualOverflow = false;

  @override
  void performLayout() {
    if (center == null) {
      assert(firstChild == null);
      _minScrollExtent = 0.0;
      _maxScrollExtent = 0.0;
      _hasVisualOverflow = false;
      offset.applyContentDimensions(0.0, 0.0);
      return;
    }
    assert(center.parent == this);

    double mainAxisExtent;
    double crossAxisExtent;
    switch (axis) {
      case Axis.vertical:
        mainAxisExtent = size.height;
        crossAxisExtent = size.width;
        break;
      case Axis.horizontal:
        mainAxisExtent = size.width;
        crossAxisExtent = size.height;
        break;
    }

    final double centerOffsetAdjustment = center.centerOffsetAdjustment;

    double correction;
    int count = 0;
    do {
      assert(offset.pixels != null);
      correction = _attemptLayout(mainAxisExtent, crossAxisExtent,
          offset.pixels + centerOffsetAdjustment);
      if (correction != 0.0) {
        offset.correctBy(correction);
      } else {
        if (offset.applyContentDimensions(
          math.min(0.0, _minScrollExtent + mainAxisExtent * anchor),
          math.max(0.0, _maxScrollExtent - mainAxisExtent * (1.0 - anchor)),
        )) break;
      }
      count += 1;
    } while (count < _maxLayoutCycles);
    assert(() {
      if (count >= _maxLayoutCycles) {
        assert(count != 1);
        throw FlutterError(
            'A RenderViewport exceeded its maximum number of layout cycles.\n'
            'RenderViewport render objects, during layout, can retry if either their '
            'slivers or their ViewportOffset decide that the offset should be corrected '
            'to take into account information collected during that layout.\n'
            'In the case of this RenderViewport object, however, this happened $count '
            'times and still there was no consensus on the scroll offset. This usually '
            'indicates a bug. Specifically, it means that one of the following three '
            'problems is being experienced by the RenderViewport object:\n'
            ' * One of the RenderSliver children or the ViewportOffset have a bug such'
            ' that they always think that they need to correct the offset regardless.\n'
            ' * Some combination of the RenderSliver children and the ViewportOffset'
            ' have a bad interaction such that one applies a correction then another'
            ' applies a reverse correction, leading to an infinite loop of corrections.\n'
            ' * There is a pathological case that would eventually resolve, but it is'
            ' so complicated that it cannot be resolved in any reasonable number of'
            ' layout passes.');
      }
      return true;
    }());
  }

  double _attemptLayout(
      double mainAxisExtent, double crossAxisExtent, double correctedOffset) {
    assert(!mainAxisExtent.isNaN);
    assert(mainAxisExtent >= 0.0);
    assert(crossAxisExtent.isFinite);
    assert(crossAxisExtent >= 0.0);
    assert(correctedOffset.isFinite);
    _minScrollExtent = 0.0;
    _maxScrollExtent = 0.0;
    _hasVisualOverflow = false;

    final double centerOffset = mainAxisExtent * anchor - correctedOffset;
    final double reverseDirectionRemainingPaintExtent =
        centerOffset.clamp(0.0, mainAxisExtent);
    final double forwardDirectionRemainingPaintExtent =
        (mainAxisExtent - centerOffset).clamp(0.0, mainAxisExtent);

    final double fullCacheExtent = mainAxisExtent + 2 * cacheExtent;
    final double centerCacheOffset = centerOffset + cacheExtent;
    final double reverseDirectionRemainingCacheExtent =
        centerCacheOffset.clamp(0.0, fullCacheExtent);
    final double forwardDirectionRemainingCacheExtent =
        (fullCacheExtent - centerCacheOffset).clamp(0.0, fullCacheExtent);

    final RenderSliver leadingNegativeChild = childBefore(center);

    if (leadingNegativeChild != null) {
      final double result = layoutChildSequence(
        child: leadingNegativeChild,
        scrollOffset: math.max(mainAxisExtent, centerOffset) - mainAxisExtent,
        overlap: 0.0,
        layoutOffset: forwardDirectionRemainingPaintExtent,
        remainingPaintExtent: reverseDirectionRemainingPaintExtent,
        mainAxisExtent: mainAxisExtent,
        crossAxisExtent: crossAxisExtent,
        growthDirection: GrowthDirection.reverse,
        advance: childBefore,
        remainingCacheExtent: reverseDirectionRemainingCacheExtent,
        cacheOrigin: (mainAxisExtent - centerOffset).clamp(-cacheExtent, 0.0),
      );
      if (result != 0.0) return -result;
    }

    return layoutChildSequence(
      child: center,
      scrollOffset: math.max(0.0, -centerOffset),
      overlap:
          leadingNegativeChild == null ? math.min(0.0, -centerOffset) : 0.0,
      layoutOffset: centerOffset >= mainAxisExtent
          ? centerOffset
          : reverseDirectionRemainingPaintExtent,
      remainingPaintExtent: forwardDirectionRemainingPaintExtent,
      mainAxisExtent: mainAxisExtent,
      crossAxisExtent: crossAxisExtent,
      growthDirection: GrowthDirection.forward,
      advance: childAfter,
      remainingCacheExtent: forwardDirectionRemainingCacheExtent,
      cacheOrigin: centerOffset.clamp(-cacheExtent, 0.0),
    );
  }

  @override
  bool get hasVisualOverflow => _hasVisualOverflow;

  @override
  void updateOutOfBandData(
      GrowthDirection growthDirection, SliverGeometry childLayoutGeometry) {
    switch (growthDirection) {
      case GrowthDirection.forward:
        _maxScrollExtent += childLayoutGeometry.scrollExtent;
        break;
      case GrowthDirection.reverse:
        _minScrollExtent -= childLayoutGeometry.scrollExtent;
        break;
    }
    if (childLayoutGeometry.hasVisualOverflow) _hasVisualOverflow = true;
  }

  @override
  void updateChildLayoutOffset(RenderSliver child, double layoutOffset,
      GrowthDirection growthDirection) {
    final SliverPhysicalParentData childParentData = child.parentData;
    childParentData.paintOffset =
        computeAbsolutePaintOffset(child, layoutOffset, growthDirection);
  }

  @override
  Offset paintOffsetOf(RenderSliver child) {
    final SliverPhysicalParentData childParentData = child.parentData;
    return childParentData.paintOffset;
  }

  @override
  double scrollOffsetOf(RenderSliver child, double scrollOffsetWithinChild) {
    assert(child.parent == this);
    final GrowthDirection growthDirection = child.constraints.growthDirection;
    assert(growthDirection != null);
    switch (growthDirection) {
      case GrowthDirection.forward:
        double scrollOffsetToChild = 0.0;
        RenderSliver current = center;
        while (current != child) {
          scrollOffsetToChild += current.geometry.scrollExtent;
          current = childAfter(current);
        }
        return scrollOffsetToChild + scrollOffsetWithinChild;
      case GrowthDirection.reverse:
        double scrollOffsetToChild = 0.0;
        RenderSliver current = childBefore(center);
        while (current != child) {
          scrollOffsetToChild -= current.geometry.scrollExtent;
          current = childBefore(current);
        }
        return scrollOffsetToChild - scrollOffsetWithinChild;
    }
    return null;
  }

  @override
  double maxScrollObstructionExtentBefore(RenderSliver child) {
    assert(child.parent == this);
    final GrowthDirection growthDirection = child.constraints.growthDirection;
    assert(growthDirection != null);
    switch (growthDirection) {
      case GrowthDirection.forward:
        double pinnedExtent = 0.0;
        RenderSliver current = center;
        while (current != child) {
          pinnedExtent += current.geometry.maxScrollObstructionExtent;
          current = childAfter(current);
        }
        return pinnedExtent;
      case GrowthDirection.reverse:
        double pinnedExtent = 0.0;
        RenderSliver current = childBefore(center);
        while (current != child) {
          pinnedExtent += current.geometry.maxScrollObstructionExtent;
          current = childBefore(current);
        }
        return pinnedExtent;
    }
    return null;
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    assert(child != null);
    final SliverPhysicalParentData childParentData = child.parentData;
    childParentData.applyPaintTransform(transform);
  }

  @override
  double computeChildMainAxisPosition(
      RenderSliver child, double parentMainAxisPosition) {
    assert(child != null);
    assert(child.constraints != null);
    final SliverPhysicalParentData childParentData = child.parentData;
    switch (applyGrowthDirectionToAxisDirection(
        child.constraints.axisDirection, child.constraints.growthDirection)) {
      case AxisDirection.down:
        return parentMainAxisPosition - childParentData.paintOffset.dy;
      case AxisDirection.right:
        return parentMainAxisPosition - childParentData.paintOffset.dx;
      case AxisDirection.up:
        return child.geometry.paintExtent -
            (parentMainAxisPosition - childParentData.paintOffset.dy);
      case AxisDirection.left:
        return child.geometry.paintExtent -
            (parentMainAxisPosition - childParentData.paintOffset.dx);
    }
    return 0.0;
  }

  @override
  int get indexOfFirstChild {
    assert(center != null);
    assert(center.parent == this);
    assert(firstChild != null);
    int count = 0;
    RenderSliver child = center;
    while (child != firstChild) {
      count -= 1;
      child = childBefore(child);
    }
    return count;
  }

  @override
  String labelForChild(int index) {
    if (index == 0) return 'center child';
    return 'child $index';
  }

  @override
  Iterable<RenderSliver> get childrenInPaintOrder sync* {
    if (firstChild == null) return;
    RenderSliver child = firstChild;
    while (child != center) {
      yield child;
      child = childAfter(child);
    }
    child = lastChild;
    while (true) {
      yield child;
      if (child == center) return;
      child = childBefore(child);
    }
  }

  @override
  Iterable<RenderSliver> get childrenInHitTestOrder sync* {
    if (firstChild == null) return;
    RenderSliver child = center;
    while (child != null) {
      yield child;
      child = childAfter(child);
    }
    child = childBefore(center);
    while (child != null) {
      yield child;
      child = childBefore(child);
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('anchor', anchor));
  }
}

class RenderShrinkWrappingViewport
    extends RenderViewportBase<SliverLogicalContainerParentData> {
  RenderShrinkWrappingViewport({
    AxisDirection axisDirection = AxisDirection.down,
    @required AxisDirection crossAxisDirection,
    @required ViewportOffset offset,
    List<RenderSliver> children,
  }) : super(
            axisDirection: axisDirection,
            crossAxisDirection: crossAxisDirection,
            offset: offset) {
    addAll(children);
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! SliverLogicalContainerParentData)
      child.parentData = SliverLogicalContainerParentData();
  }

  @override
  bool debugThrowIfNotCheckingIntrinsics() {
    assert(() {
      if (!RenderObject.debugCheckingIntrinsics) {
        throw FlutterError(
            '$runtimeType does not support returning intrinsic dimensions.\n'
            'Calculating the intrinsic dimensions would require instantiating every child of '
            'the viewport, which defeats the point of viewports being lazy.\n'
            'If you are merely trying to shrink-wrap the viewport in the main axis direction, '
            'you should be able to achieve that effect by just giving the viewport loose '
            'constraints, without needing to measure its intrinsic dimensions.');
      }
      return true;
    }());
    return true;
  }

  double _maxScrollExtent;
  double _shrinkWrapExtent;
  bool _hasVisualOverflow = false;

  @override
  void performLayout() {
    if (firstChild == null) {
      switch (axis) {
        case Axis.vertical:
          assert(constraints.hasBoundedWidth);
          size = Size(constraints.maxWidth, constraints.minHeight);
          break;
        case Axis.horizontal:
          assert(constraints.hasBoundedHeight);
          size = Size(constraints.minWidth, constraints.maxHeight);
          break;
      }
      offset.applyViewportDimension(0.0);
      _maxScrollExtent = 0.0;
      _shrinkWrapExtent = 0.0;
      _hasVisualOverflow = false;
      offset.applyContentDimensions(0.0, 0.0);
      return;
    }

    double mainAxisExtent;
    double crossAxisExtent;
    switch (axis) {
      case Axis.vertical:
        assert(constraints.hasBoundedWidth);
        mainAxisExtent = constraints.maxHeight;
        crossAxisExtent = constraints.maxWidth;
        break;
      case Axis.horizontal:
        assert(constraints.hasBoundedHeight);
        mainAxisExtent = constraints.maxWidth;
        crossAxisExtent = constraints.maxHeight;
        break;
    }

    double correction;
    double effectiveExtent;
    do {
      assert(offset.pixels != null);
      correction =
          _attemptLayout(mainAxisExtent, crossAxisExtent, offset.pixels);
      if (correction != 0.0) {
        offset.correctBy(correction);
      } else {
        switch (axis) {
          case Axis.vertical:
            effectiveExtent = constraints.constrainHeight(_shrinkWrapExtent);
            break;
          case Axis.horizontal:
            effectiveExtent = constraints.constrainWidth(_shrinkWrapExtent);
            break;
        }
        final bool didAcceptViewportDimension =
            offset.applyViewportDimension(effectiveExtent);
        final bool didAcceptContentDimension = offset.applyContentDimensions(
            0.0, math.max(0.0, _maxScrollExtent - effectiveExtent));
        if (didAcceptViewportDimension && didAcceptContentDimension) break;
      }
    } while (true);
    switch (axis) {
      case Axis.vertical:
        size =
            constraints.constrainDimensions(crossAxisExtent, effectiveExtent);
        break;
      case Axis.horizontal:
        size =
            constraints.constrainDimensions(effectiveExtent, crossAxisExtent);
        break;
    }
  }

  double _attemptLayout(
      double mainAxisExtent, double crossAxisExtent, double correctedOffset) {
    assert(!mainAxisExtent.isNaN);
    assert(mainAxisExtent >= 0.0);
    assert(crossAxisExtent.isFinite);
    assert(crossAxisExtent >= 0.0);
    assert(correctedOffset.isFinite);
    _maxScrollExtent = 0.0;
    _shrinkWrapExtent = 0.0;
    _hasVisualOverflow = false;
    return layoutChildSequence(
      child: firstChild,
      scrollOffset: math.max(0.0, correctedOffset),
      overlap: math.min(0.0, correctedOffset),
      layoutOffset: 0.0,
      remainingPaintExtent: mainAxisExtent,
      mainAxisExtent: mainAxisExtent,
      crossAxisExtent: crossAxisExtent,
      growthDirection: GrowthDirection.forward,
      advance: childAfter,
      remainingCacheExtent: mainAxisExtent + 2 * cacheExtent,
      cacheOrigin: -cacheExtent,
    );
  }

  @override
  bool get hasVisualOverflow => _hasVisualOverflow;

  @override
  void updateOutOfBandData(
      GrowthDirection growthDirection, SliverGeometry childLayoutGeometry) {
    assert(growthDirection == GrowthDirection.forward);
    _maxScrollExtent += childLayoutGeometry.scrollExtent;
    if (childLayoutGeometry.hasVisualOverflow) _hasVisualOverflow = true;
    _shrinkWrapExtent += childLayoutGeometry.maxPaintExtent;
  }

  @override
  void updateChildLayoutOffset(RenderSliver child, double layoutOffset,
      GrowthDirection growthDirection) {
    assert(growthDirection == GrowthDirection.forward);
    final SliverLogicalParentData childParentData = child.parentData;
    childParentData.layoutOffset = layoutOffset;
  }

  @override
  Offset paintOffsetOf(RenderSliver child) {
    final SliverLogicalParentData childParentData = child.parentData;
    return computeAbsolutePaintOffset(
        child, childParentData.layoutOffset, GrowthDirection.forward);
  }

  @override
  double scrollOffsetOf(RenderSliver child, double scrollOffsetWithinChild) {
    assert(child.parent == this);
    assert(child.constraints.growthDirection == GrowthDirection.forward);
    double scrollOffsetToChild = 0.0;
    RenderSliver current = firstChild;
    while (current != child) {
      scrollOffsetToChild += current.geometry.scrollExtent;
      current = childAfter(current);
    }
    return scrollOffsetToChild + scrollOffsetWithinChild;
  }

  @override
  double maxScrollObstructionExtentBefore(RenderSliver child) {
    assert(child.parent == this);
    assert(child.constraints.growthDirection == GrowthDirection.forward);
    double pinnedExtent = 0.0;
    RenderSliver current = firstChild;
    while (current != child) {
      pinnedExtent += current.geometry.maxScrollObstructionExtent;
      current = childAfter(current);
    }
    return pinnedExtent;
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    assert(child != null);
    final Offset offset = paintOffsetOf(child);
    transform.translate(offset.dx, offset.dy);
  }

  @override
  double computeChildMainAxisPosition(
      RenderSliver child, double parentMainAxisPosition) {
    assert(child != null);
    assert(child.constraints != null);
    assert(hasSize);
    final SliverLogicalParentData childParentData = child.parentData;
    switch (applyGrowthDirectionToAxisDirection(
        child.constraints.axisDirection, child.constraints.growthDirection)) {
      case AxisDirection.down:
      case AxisDirection.right:
        return parentMainAxisPosition - childParentData.layoutOffset;
      case AxisDirection.up:
        return (size.height - parentMainAxisPosition) -
            childParentData.layoutOffset;
      case AxisDirection.left:
        return (size.width - parentMainAxisPosition) -
            childParentData.layoutOffset;
    }
    return 0.0;
  }

  @override
  int get indexOfFirstChild => 0;

  @override
  String labelForChild(int index) => 'child $index';

  @override
  Iterable<RenderSliver> get childrenInPaintOrder sync* {
    RenderSliver child = firstChild;
    while (child != null) {
      yield child;
      child = childAfter(child);
    }
  }

  @override
  Iterable<RenderSliver> get childrenInHitTestOrder sync* {
    RenderSliver child = lastChild;
    while (child != null) {
      yield child;
      child = childBefore(child);
    }
  }
}

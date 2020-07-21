import 'dart:math' as math;

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/gestures.dart';
import 'package:vector_math/vector_math_64.dart';

import 'debug.dart';
import 'object.dart';
import 'sliver.dart';

class RenderSliverPadding extends RenderSliver
    with RenderObjectWithChildMixin<RenderSliver> {
  RenderSliverPadding({
    @required EdgeInsetsGeometry padding,
    TextDirection textDirection,
    RenderSliver child,
  })  : assert(padding != null),
        assert(padding.isNonNegative),
        _padding = padding,
        _textDirection = textDirection {
    this.child = child;
  }

  EdgeInsets _resolvedPadding;

  void _resolve() {
    if (_resolvedPadding != null) return;
    _resolvedPadding = padding.resolve(textDirection);
    assert(_resolvedPadding.isNonNegative);
  }

  void _markNeedResolution() {
    _resolvedPadding = null;
    markNeedsLayout();
  }

  EdgeInsetsGeometry get padding => _padding;
  EdgeInsetsGeometry _padding;
  set padding(EdgeInsetsGeometry value) {
    assert(value != null);
    assert(padding.isNonNegative);
    if (_padding == value) return;
    _padding = value;
    _markNeedResolution();
  }

  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (_textDirection == value) return;
    _textDirection = value;
    _markNeedResolution();
  }

  double get beforePadding {
    assert(constraints != null);
    assert(constraints.axisDirection != null);
    assert(constraints.growthDirection != null);
    assert(_resolvedPadding != null);
    switch (applyGrowthDirectionToAxisDirection(
        constraints.axisDirection, constraints.growthDirection)) {
      case AxisDirection.up:
        return _resolvedPadding.bottom;
      case AxisDirection.right:
        return _resolvedPadding.left;
      case AxisDirection.down:
        return _resolvedPadding.top;
      case AxisDirection.left:
        return _resolvedPadding.right;
    }
    return null;
  }

  double get afterPadding {
    assert(constraints != null);
    assert(constraints.axisDirection != null);
    assert(constraints.growthDirection != null);
    assert(_resolvedPadding != null);
    switch (applyGrowthDirectionToAxisDirection(
        constraints.axisDirection, constraints.growthDirection)) {
      case AxisDirection.up:
        return _resolvedPadding.top;
      case AxisDirection.right:
        return _resolvedPadding.right;
      case AxisDirection.down:
        return _resolvedPadding.bottom;
      case AxisDirection.left:
        return _resolvedPadding.left;
    }
    return null;
  }

  double get mainAxisPadding {
    assert(constraints != null);
    assert(constraints.axis != null);
    assert(_resolvedPadding != null);
    return _resolvedPadding.along(constraints.axis);
  }

  double get crossAxisPadding {
    assert(constraints != null);
    assert(constraints.axis != null);
    assert(_resolvedPadding != null);
    switch (constraints.axis) {
      case Axis.horizontal:
        return _resolvedPadding.vertical;
      case Axis.vertical:
        return _resolvedPadding.horizontal;
    }
    return null;
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! SliverPhysicalParentData)
      child.parentData = SliverPhysicalParentData();
  }

  @override
  void performLayout() {
    _resolve();
    assert(_resolvedPadding != null);
    final double beforePadding = this.beforePadding;
    final double afterPadding = this.afterPadding;
    final double mainAxisPadding = this.mainAxisPadding;
    final double crossAxisPadding = this.crossAxisPadding;
    if (child == null) {
      geometry = SliverGeometry(
        scrollExtent: mainAxisPadding,
        paintExtent:
            math.min(mainAxisPadding, constraints.remainingPaintExtent),
        maxPaintExtent: mainAxisPadding,
      );
      return;
    }
    child.layout(
      constraints.copyWith(
        scrollOffset: math.max(0.0, constraints.scrollOffset - beforePadding),
        cacheOrigin: math.min(0.0, constraints.cacheOrigin + beforePadding),
        overlap: 0.0,
        remainingPaintExtent: constraints.remainingPaintExtent -
            calculatePaintOffset(constraints, from: 0.0, to: beforePadding),
        remainingCacheExtent: constraints.remainingCacheExtent -
            calculateCacheOffset(constraints, from: 0.0, to: beforePadding),
        crossAxisExtent:
            math.max(0.0, constraints.crossAxisExtent - crossAxisPadding),
      ),
      parentUsesSize: true,
    );
    final SliverGeometry childLayoutGeometry = child.geometry;
    if (childLayoutGeometry.scrollOffsetCorrection != null) {
      geometry = SliverGeometry(
        scrollOffsetCorrection: childLayoutGeometry.scrollOffsetCorrection,
      );
      return;
    }
    final double beforePaddingPaintExtent = calculatePaintOffset(
      constraints,
      from: 0.0,
      to: beforePadding,
    );
    final double afterPaddingPaintExtent = calculatePaintOffset(
      constraints,
      from: beforePadding + childLayoutGeometry.scrollExtent,
      to: mainAxisPadding + childLayoutGeometry.scrollExtent,
    );
    final double mainAxisPaddingPaintExtent =
        beforePaddingPaintExtent + afterPaddingPaintExtent;
    final double beforePaddingCacheExtent = calculateCacheOffset(
      constraints,
      from: 0.0,
      to: beforePadding,
    );
    final double afterPaddingCacheExtent = calculateCacheOffset(
      constraints,
      from: beforePadding + childLayoutGeometry.scrollExtent,
      to: mainAxisPadding + childLayoutGeometry.scrollExtent,
    );
    final double mainAxisPaddingCacheExtent =
        afterPaddingCacheExtent + beforePaddingCacheExtent;
    final double paintExtent = math.min(
      beforePaddingPaintExtent +
          math.max(childLayoutGeometry.paintExtent,
              childLayoutGeometry.layoutExtent + afterPaddingPaintExtent),
      constraints.remainingPaintExtent,
    );
    geometry = SliverGeometry(
      scrollExtent: mainAxisPadding + childLayoutGeometry.scrollExtent,
      paintExtent: paintExtent,
      layoutExtent: math.min(
          mainAxisPaddingPaintExtent + childLayoutGeometry.layoutExtent,
          paintExtent),
      cacheExtent: math.min(
          mainAxisPaddingCacheExtent + childLayoutGeometry.cacheExtent,
          constraints.remainingCacheExtent),
      maxPaintExtent: mainAxisPadding + childLayoutGeometry.maxPaintExtent,
      hitTestExtent: math.max(
        mainAxisPaddingPaintExtent + childLayoutGeometry.paintExtent,
        beforePaddingPaintExtent + childLayoutGeometry.hitTestExtent,
      ),
      hasVisualOverflow: childLayoutGeometry.hasVisualOverflow,
    );

    final SliverPhysicalParentData childParentData = child.parentData;
    assert(constraints.axisDirection != null);
    assert(constraints.growthDirection != null);
    switch (applyGrowthDirectionToAxisDirection(
        constraints.axisDirection, constraints.growthDirection)) {
      case AxisDirection.up:
        childParentData.paintOffset = Offset(
            _resolvedPadding.left,
            calculatePaintOffset(constraints,
                from:
                    _resolvedPadding.bottom + childLayoutGeometry.scrollExtent,
                to: _resolvedPadding.bottom +
                    childLayoutGeometry.scrollExtent +
                    _resolvedPadding.top));
        break;
      case AxisDirection.right:
        childParentData.paintOffset = Offset(
            calculatePaintOffset(constraints,
                from: 0.0, to: _resolvedPadding.left),
            _resolvedPadding.top);
        break;
      case AxisDirection.down:
        childParentData.paintOffset = Offset(
            _resolvedPadding.left,
            calculatePaintOffset(constraints,
                from: 0.0, to: _resolvedPadding.top));
        break;
      case AxisDirection.left:
        childParentData.paintOffset = Offset(
            calculatePaintOffset(constraints,
                from: _resolvedPadding.right + childLayoutGeometry.scrollExtent,
                to: _resolvedPadding.right +
                    childLayoutGeometry.scrollExtent +
                    _resolvedPadding.left),
            _resolvedPadding.top);
        break;
    }
    assert(childParentData.paintOffset != null);
    assert(beforePadding == this.beforePadding);
    assert(afterPadding == this.afterPadding);
    assert(mainAxisPadding == this.mainAxisPadding);
    assert(crossAxisPadding == this.crossAxisPadding);
  }

  @override
  bool hitTestChildren(SliverHitTestResult result,
      {@required double mainAxisPosition, @required double crossAxisPosition}) {
    if (child != null && child.geometry.hitTestExtent > 0.0) {
      final SliverPhysicalParentData childParentData = child.parentData;
      result.addWithAxisOffset(
        mainAxisPosition: mainAxisPosition,
        crossAxisPosition: crossAxisPosition,
        mainAxisOffset: childMainAxisPosition(child),
        crossAxisOffset: childCrossAxisPosition(child),
        paintOffset: childParentData.paintOffset,
        hitTest: child.hitTest,
      );
    }
    return false;
  }

  @override
  double childMainAxisPosition(RenderSliver child) {
    assert(child != null);
    assert(child == this.child);
    return calculatePaintOffset(constraints, from: 0.0, to: beforePadding);
  }

  @override
  double childCrossAxisPosition(RenderSliver child) {
    assert(child != null);
    assert(child == this.child);
    assert(constraints != null);
    assert(constraints.axisDirection != null);
    assert(constraints.growthDirection != null);
    assert(_resolvedPadding != null);
    switch (applyGrowthDirectionToAxisDirection(
        constraints.axisDirection, constraints.growthDirection)) {
      case AxisDirection.up:
      case AxisDirection.down:
        return _resolvedPadding.left;
      case AxisDirection.left:
      case AxisDirection.right:
        return _resolvedPadding.top;
    }
    return null;
  }

  @override
  double childScrollOffset(RenderObject child) {
    assert(child.parent == this);
    return beforePadding;
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    assert(child != null);
    assert(child == this.child);
    final SliverPhysicalParentData childParentData = child.parentData;
    childParentData.applyPaintTransform(transform);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null && child.geometry.visible) {
      final SliverPhysicalParentData childParentData = child.parentData;
      context.paintChild(child, offset + childParentData.paintOffset);
    }
  }

  @override
  void debugPaint(PaintingContext context, Offset offset) {
    super.debugPaint(context, offset);
    assert(() {
      if (debugPaintSizeEnabled) {
        final Size parentSize = getAbsoluteSizeRelativeToOrigin();
        final Rect outerRect = offset & parentSize;
        Size childSize;
        Rect innerRect;
        if (child != null) {
          childSize = child.getAbsoluteSizeRelativeToOrigin();
          final SliverPhysicalParentData childParentData = child.parentData;
          innerRect = (offset + childParentData.paintOffset) & childSize;
          assert(innerRect.top >= outerRect.top);
          assert(innerRect.left >= outerRect.left);
          assert(innerRect.right <= outerRect.right);
          assert(innerRect.bottom <= outerRect.bottom);
        }
        debugPaintPadding(context.canvas, outerRect, innerRect);
      }
      return true;
    }());
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('padding', padding));
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection,
        defaultValue: null));
  }
}

import 'dart:math' as math;

import 'package:flutter_web/animation.dart';
import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/gestures.dart';
import 'package:flutter_web/scheduler.dart';
import 'package:flutter_web/semantics.dart';
import 'package:vector_math/vector_math_64.dart';

import 'box.dart';
import 'object.dart';
import 'sliver.dart';
import 'viewport.dart';
import 'viewport_offset.dart';

abstract class RenderSliverPersistentHeader extends RenderSliver
    with RenderObjectWithChildMixin<RenderBox>, RenderSliverHelpers {
  RenderSliverPersistentHeader({RenderBox child}) {
    this.child = child;
  }

  double get maxExtent;

  double get minExtent;

  @protected
  double get childExtent {
    if (child == null) return 0.0;
    assert(child.hasSize);
    assert(constraints.axis != null);
    switch (constraints.axis) {
      case Axis.vertical:
        return child.size.height;
      case Axis.horizontal:
        return child.size.width;
    }
    return null;
  }

  bool _needsUpdateChild = true;
  double _lastShrinkOffset = 0.0;
  bool _lastOverlapsContent = false;

  @protected
  void updateChild(double shrinkOffset, bool overlapsContent) {}

  @override
  void markNeedsLayout() {
    _needsUpdateChild = true;
    super.markNeedsLayout();
  }

  @protected
  void layoutChild(double scrollOffset, double maxExtent,
      {bool overlapsContent = false}) {
    assert(maxExtent != null);
    final double shrinkOffset = math.min(scrollOffset, maxExtent);
    if (_needsUpdateChild ||
        _lastShrinkOffset != shrinkOffset ||
        _lastOverlapsContent != overlapsContent) {
      invokeLayoutCallback<SliverConstraints>((SliverConstraints constraints) {
        assert(constraints == this.constraints);
        updateChild(shrinkOffset, overlapsContent);
      });
      _lastShrinkOffset = shrinkOffset;
      _lastOverlapsContent = overlapsContent;
      _needsUpdateChild = false;
    }
    assert(minExtent != null);
    assert(() {
      if (minExtent <= maxExtent) return true;
      throw FlutterError(
          'The maxExtent for this $runtimeType is less than its minExtent.\n'
          'The specified maxExtent was: ${maxExtent.toStringAsFixed(1)}\n'
          'The specified minExtent was: ${minExtent.toStringAsFixed(1)}\n');
    }());
    child?.layout(
      constraints.asBoxConstraints(
          maxExtent: math.max(minExtent, maxExtent - shrinkOffset)),
      parentUsesSize: true,
    );
  }

  @override
  double childMainAxisPosition(covariant RenderObject child) =>
      super.childMainAxisPosition(child);

  @override
  bool hitTestChildren(SliverHitTestResult result,
      {@required double mainAxisPosition, @required double crossAxisPosition}) {
    assert(geometry.hitTestExtent > 0.0);
    if (child != null)
      return hitTestBoxChild(BoxHitTestResult.wrap(result), child,
          mainAxisPosition: mainAxisPosition,
          crossAxisPosition: crossAxisPosition);
    return false;
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    assert(child != null);
    assert(child == this.child);
    applyPaintTransformForBoxChild(child, transform);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null && geometry.visible) {
      assert(constraints.axisDirection != null);
      switch (applyGrowthDirectionToAxisDirection(
          constraints.axisDirection, constraints.growthDirection)) {
        case AxisDirection.up:
          offset += Offset(
              0.0,
              geometry.paintExtent -
                  childMainAxisPosition(child) -
                  childExtent);
          break;
        case AxisDirection.down:
          offset += Offset(0.0, childMainAxisPosition(child));
          break;
        case AxisDirection.left:
          offset += Offset(
              geometry.paintExtent - childMainAxisPosition(child) - childExtent,
              0.0);
          break;
        case AxisDirection.right:
          offset += Offset(childMainAxisPosition(child), 0.0);
          break;
      }
      context.paintChild(child, offset);
    }
  }

  @protected
  bool get excludeFromSemanticsScrolling => _excludeFromSemanticsScrolling;
  bool _excludeFromSemanticsScrolling = false;
  set excludeFromSemanticsScrolling(bool value) {
    if (_excludeFromSemanticsScrolling == value) return;
    _excludeFromSemanticsScrolling = value;
    markNeedsSemanticsUpdate();
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);

    if (_excludeFromSemanticsScrolling)
      config.addTagForChildren(RenderViewport.excludeFromScrolling);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty.lazy('maxExtent', () => maxExtent));
    properties.add(DoubleProperty.lazy(
        'child position', () => childMainAxisPosition(child)));
  }
}

abstract class RenderSliverScrollingPersistentHeader
    extends RenderSliverPersistentHeader {
  RenderSliverScrollingPersistentHeader({
    RenderBox child,
  }) : super(child: child);

  double _childPosition;

  @override
  void performLayout() {
    final double maxExtent = this.maxExtent;
    layoutChild(constraints.scrollOffset, maxExtent);
    final double paintExtent = maxExtent - constraints.scrollOffset;
    geometry = SliverGeometry(
      scrollExtent: maxExtent,
      paintOrigin: math.min(constraints.overlap, 0.0),
      paintExtent: paintExtent.clamp(0.0, constraints.remainingPaintExtent),
      maxPaintExtent: maxExtent,
      hasVisualOverflow: true,
    );
    _childPosition = math.min(0.0, paintExtent - childExtent);
  }

  @override
  double childMainAxisPosition(RenderBox child) {
    assert(child == this.child);
    return _childPosition;
  }
}

abstract class RenderSliverPinnedPersistentHeader
    extends RenderSliverPersistentHeader {
  RenderSliverPinnedPersistentHeader({
    RenderBox child,
  }) : super(child: child);

  @override
  void performLayout() {
    final double maxExtent = this.maxExtent;
    final bool overlapsContent = constraints.overlap > 0.0;
    excludeFromSemanticsScrolling =
        overlapsContent || (constraints.scrollOffset > maxExtent - minExtent);
    layoutChild(constraints.scrollOffset, maxExtent,
        overlapsContent: overlapsContent);
    final double layoutExtent = (maxExtent - constraints.scrollOffset)
        .clamp(0.0, constraints.remainingPaintExtent);
    geometry = SliverGeometry(
      scrollExtent: maxExtent,
      paintOrigin: constraints.overlap,
      paintExtent: math.min(childExtent, constraints.remainingPaintExtent),
      layoutExtent: layoutExtent,
      maxPaintExtent: maxExtent,
      maxScrollObstructionExtent: minExtent,
      cacheExtent: layoutExtent > 0.0
          ? -constraints.cacheOrigin + layoutExtent
          : layoutExtent,
      hasVisualOverflow: true,
    );
  }

  @override
  double childMainAxisPosition(RenderBox child) => 0.0;
}

class FloatingHeaderSnapConfiguration {
  FloatingHeaderSnapConfiguration({
    @required this.vsync,
    this.curve = Curves.ease,
    this.duration = const Duration(milliseconds: 300),
  })  : assert(vsync != null),
        assert(curve != null),
        assert(duration != null);

  final TickerProvider vsync;

  final Curve curve;

  final Duration duration;
}

abstract class RenderSliverFloatingPersistentHeader
    extends RenderSliverPersistentHeader {
  RenderSliverFloatingPersistentHeader({
    RenderBox child,
    FloatingHeaderSnapConfiguration snapConfiguration,
  })  : _snapConfiguration = snapConfiguration,
        super(child: child);

  AnimationController _controller;
  Animation<double> _animation;
  double _lastActualScrollOffset;
  double _effectiveScrollOffset;

  double _childPosition;

  @override
  void detach() {
    _controller?.dispose();
    _controller = null;
    super.detach();
  }

  FloatingHeaderSnapConfiguration get snapConfiguration => _snapConfiguration;
  FloatingHeaderSnapConfiguration _snapConfiguration;
  set snapConfiguration(FloatingHeaderSnapConfiguration value) {
    if (value == _snapConfiguration) return;
    if (value == null) {
      _controller?.dispose();
      _controller = null;
    } else {
      if (_snapConfiguration != null && value.vsync != _snapConfiguration.vsync)
        _controller?.resync(value.vsync);
    }
    _snapConfiguration = value;
  }

  @protected
  double updateGeometry() {
    final double maxExtent = this.maxExtent;
    final double paintExtent = maxExtent - _effectiveScrollOffset;
    final double layoutExtent = maxExtent - constraints.scrollOffset;
    geometry = SliverGeometry(
      scrollExtent: maxExtent,
      paintOrigin: math.min(constraints.overlap, 0.0),
      paintExtent: paintExtent.clamp(0.0, constraints.remainingPaintExtent),
      layoutExtent: layoutExtent.clamp(0.0, constraints.remainingPaintExtent),
      maxPaintExtent: maxExtent,
      maxScrollObstructionExtent: maxExtent,
      hasVisualOverflow: true,
    );
    return math.min(0.0, paintExtent - childExtent);
  }

  void maybeStartSnapAnimation(ScrollDirection direction) {
    if (snapConfiguration == null) return;
    if (direction == ScrollDirection.forward && _effectiveScrollOffset <= 0.0)
      return;
    if (direction == ScrollDirection.reverse &&
        _effectiveScrollOffset >= maxExtent) return;

    final TickerProvider vsync = snapConfiguration.vsync;
    final Duration duration = snapConfiguration.duration;
    _controller ??= AnimationController(vsync: vsync, duration: duration)
      ..addListener(() {
        if (_effectiveScrollOffset == _animation.value) return;
        _effectiveScrollOffset = _animation.value;
        markNeedsLayout();
      });

    _animation = _controller.drive(
      Tween<double>(
        begin: _effectiveScrollOffset,
        end: direction == ScrollDirection.forward ? 0.0 : maxExtent,
      ).chain(CurveTween(
        curve: snapConfiguration.curve,
      )),
    );

    _controller.forward(from: 0.0);
  }

  void maybeStopSnapAnimation(ScrollDirection direction) {
    _controller?.stop();
  }

  @override
  void performLayout() {
    final double maxExtent = this.maxExtent;
    if (_lastActualScrollOffset != null &&
        ((constraints.scrollOffset < _lastActualScrollOffset) ||
            (_effectiveScrollOffset < maxExtent))) {
      double delta = _lastActualScrollOffset - constraints.scrollOffset;
      final bool allowFloatingExpansion =
          constraints.userScrollDirection == ScrollDirection.forward;
      if (allowFloatingExpansion) {
        if (_effectiveScrollOffset > maxExtent)
          _effectiveScrollOffset = maxExtent;
      } else {
        if (delta > 0.0) delta = 0.0;
      }
      _effectiveScrollOffset =
          (_effectiveScrollOffset - delta).clamp(0.0, constraints.scrollOffset);
    } else {
      _effectiveScrollOffset = constraints.scrollOffset;
    }
    final bool overlapsContent =
        _effectiveScrollOffset < constraints.scrollOffset;
    excludeFromSemanticsScrolling = overlapsContent;
    layoutChild(_effectiveScrollOffset, maxExtent,
        overlapsContent: overlapsContent);
    _childPosition = updateGeometry();
    _lastActualScrollOffset = constraints.scrollOffset;
  }

  @override
  double childMainAxisPosition(RenderBox child) {
    assert(child == this.child);
    return _childPosition;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(DoubleProperty('effective scroll offset', _effectiveScrollOffset));
  }
}

abstract class RenderSliverFloatingPinnedPersistentHeader
    extends RenderSliverFloatingPersistentHeader {
  RenderSliverFloatingPinnedPersistentHeader({
    RenderBox child,
    FloatingHeaderSnapConfiguration snapConfiguration,
  }) : super(child: child, snapConfiguration: snapConfiguration);

  @override
  double updateGeometry() {
    final double minExtent = this.minExtent;
    final double minAllowedExtent = constraints.remainingPaintExtent > minExtent
        ? minExtent
        : constraints.remainingPaintExtent;
    final double maxExtent = this.maxExtent;
    final double paintExtent = maxExtent - _effectiveScrollOffset;
    final double clampedPaintExtent =
        paintExtent.clamp(minAllowedExtent, constraints.remainingPaintExtent);
    final double layoutExtent = maxExtent - constraints.scrollOffset;
    geometry = SliverGeometry(
      scrollExtent: maxExtent,
      paintOrigin: math.min(constraints.overlap, 0.0),
      paintExtent: clampedPaintExtent,
      layoutExtent: layoutExtent.clamp(0.0, clampedPaintExtent),
      maxPaintExtent: maxExtent,
      maxScrollObstructionExtent: maxExtent,
      hasVisualOverflow: true,
    );
    return 0.0;
  }
}

import 'dart:math' as math;

import 'package:flutter_web/foundation.dart';

import 'box.dart';
import 'sliver.dart';
import 'sliver_fixed_extent_list.dart';
import 'sliver_multi_box_adaptor.dart';

class RenderSliverFillViewport extends RenderSliverFixedExtentBoxAdaptor {
  RenderSliverFillViewport({
    @required RenderSliverBoxChildManager childManager,
    double viewportFraction = 1.0,
  })  : assert(viewportFraction != null),
        assert(viewportFraction > 0.0),
        _viewportFraction = viewportFraction,
        super(childManager: childManager);

  @override
  double get itemExtent =>
      constraints.viewportMainAxisExtent * viewportFraction;

  double get viewportFraction => _viewportFraction;
  double _viewportFraction;
  set viewportFraction(double value) {
    assert(value != null);
    if (_viewportFraction == value) return;
    _viewportFraction = value;
    markNeedsLayout();
  }

  double get _padding =>
      (1.0 - viewportFraction) * constraints.viewportMainAxisExtent * 0.5;

  @override
  double indexToLayoutOffset(double itemExtent, int index) {
    return _padding + super.indexToLayoutOffset(itemExtent, index);
  }

  @override
  int getMinChildIndexForScrollOffset(double scrollOffset, double itemExtent) {
    return super.getMinChildIndexForScrollOffset(
        math.max(scrollOffset - _padding, 0.0), itemExtent);
  }

  @override
  int getMaxChildIndexForScrollOffset(double scrollOffset, double itemExtent) {
    return super.getMaxChildIndexForScrollOffset(
        math.max(scrollOffset - _padding, 0.0), itemExtent);
  }

  @override
  double estimateMaxScrollOffset(
    SliverConstraints constraints, {
    int firstIndex,
    int lastIndex,
    double leadingScrollOffset,
    double trailingScrollOffset,
  }) {
    final double padding = _padding;
    return childManager.estimateMaxScrollOffset(
          constraints,
          firstIndex: firstIndex,
          lastIndex: lastIndex,
          leadingScrollOffset: leadingScrollOffset - padding,
          trailingScrollOffset: trailingScrollOffset - padding,
        ) +
        padding +
        padding;
  }
}

class RenderSliverFillRemaining extends RenderSliverSingleBoxAdapter {
  RenderSliverFillRemaining({
    RenderBox child,
  }) : super(child: child);

  @override
  void performLayout() {
    final double extent =
        constraints.remainingPaintExtent - math.min(constraints.overlap, 0.0);
    if (child != null)
      child.layout(
          constraints.asBoxConstraints(minExtent: extent, maxExtent: extent),
          parentUsesSize: true);
    final double paintedChildSize =
        calculatePaintOffset(constraints, from: 0.0, to: extent);
    assert(paintedChildSize.isFinite);
    assert(paintedChildSize >= 0.0);
    geometry = SliverGeometry(
      scrollExtent: constraints.viewportMainAxisExtent,
      paintExtent: paintedChildSize,
      maxPaintExtent: paintedChildSize,
      hasVisualOverflow: extent > constraints.remainingPaintExtent ||
          constraints.scrollOffset > 0.0,
    );
    if (child != null) setChildParentData(child, constraints, geometry);
  }
}

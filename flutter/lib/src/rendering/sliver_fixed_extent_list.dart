import 'dart:math' as math;

import 'package:flutter_web/foundation.dart';

import 'box.dart';
import 'sliver.dart';
import 'sliver_multi_box_adaptor.dart';

abstract class RenderSliverFixedExtentBoxAdaptor
    extends RenderSliverMultiBoxAdaptor {
  RenderSliverFixedExtentBoxAdaptor({
    @required RenderSliverBoxChildManager childManager,
  }) : super(childManager: childManager);

  double get itemExtent;

  @protected
  double indexToLayoutOffset(double itemExtent, int index) =>
      itemExtent * index;

  @protected
  int getMinChildIndexForScrollOffset(double scrollOffset, double itemExtent) {
    return itemExtent > 0.0 ? math.max(0, scrollOffset ~/ itemExtent) : 0;
  }

  @protected
  int getMaxChildIndexForScrollOffset(double scrollOffset, double itemExtent) {
    return itemExtent > 0.0
        ? math.max(0, (scrollOffset / itemExtent).ceil() - 1)
        : 0;
  }

  @protected
  double estimateMaxScrollOffset(
    SliverConstraints constraints, {
    int firstIndex,
    int lastIndex,
    double leadingScrollOffset,
    double trailingScrollOffset,
  }) {
    return childManager.estimateMaxScrollOffset(
      constraints,
      firstIndex: firstIndex,
      lastIndex: lastIndex,
      leadingScrollOffset: leadingScrollOffset,
      trailingScrollOffset: trailingScrollOffset,
    );
  }

  @protected
  double computeMaxScrollOffset(
      SliverConstraints constraints, double itemExtent) {
    return childManager.childCount * itemExtent;
  }

  @override
  void performLayout() {
    childManager.didStartLayout();
    childManager.setDidUnderflow(false);

    final double itemExtent = this.itemExtent;

    final double scrollOffset =
        constraints.scrollOffset + constraints.cacheOrigin;
    assert(scrollOffset >= 0.0);
    final double remainingExtent = constraints.remainingCacheExtent;
    assert(remainingExtent >= 0.0);
    final double targetEndScrollOffset = scrollOffset + remainingExtent;

    final BoxConstraints childConstraints = constraints.asBoxConstraints(
      minExtent: itemExtent,
      maxExtent: itemExtent,
    );

    final int firstIndex =
        getMinChildIndexForScrollOffset(scrollOffset, itemExtent);
    final int targetLastIndex = targetEndScrollOffset.isFinite
        ? getMaxChildIndexForScrollOffset(targetEndScrollOffset, itemExtent)
        : null;

    if (firstChild != null) {
      final int oldFirstIndex = indexOf(firstChild);
      final int oldLastIndex = indexOf(lastChild);
      final int leadingGarbage =
          (firstIndex - oldFirstIndex).clamp(0, childCount);
      final int trailingGarbage = targetLastIndex == null
          ? 0
          : (oldLastIndex - targetLastIndex).clamp(0, childCount);
      collectGarbage(leadingGarbage, trailingGarbage);
    } else {
      collectGarbage(0, 0);
    }

    if (firstChild == null) {
      if (!addInitialChild(
          index: firstIndex,
          layoutOffset: indexToLayoutOffset(itemExtent, firstIndex))) {
        final double max = computeMaxScrollOffset(constraints, itemExtent);
        geometry = SliverGeometry(
          scrollExtent: max,
          maxPaintExtent: max,
        );
        childManager.didFinishLayout();
        return;
      }
    }

    RenderBox trailingChildWithLayout;

    for (int index = indexOf(firstChild) - 1; index >= firstIndex; --index) {
      final RenderBox child = insertAndLayoutLeadingChild(childConstraints);
      if (child == null) {
        geometry = SliverGeometry(scrollOffsetCorrection: index * itemExtent);
        return;
      }
      final SliverMultiBoxAdaptorParentData childParentData = child.parentData;
      childParentData.layoutOffset = indexToLayoutOffset(itemExtent, index);
      assert(childParentData.index == index);
      trailingChildWithLayout ??= child;
    }

    if (trailingChildWithLayout == null) {
      firstChild.layout(childConstraints);
      final SliverMultiBoxAdaptorParentData childParentData =
          firstChild.parentData;
      childParentData.layoutOffset =
          indexToLayoutOffset(itemExtent, firstIndex);
      trailingChildWithLayout = firstChild;
    }

    while (targetLastIndex == null ||
        indexOf(trailingChildWithLayout) < targetLastIndex) {
      RenderBox child = childAfter(trailingChildWithLayout);
      if (child == null) {
        child = insertAndLayoutChild(childConstraints,
            after: trailingChildWithLayout);
        if (child == null) {
          break;
        }
      } else {
        child.layout(childConstraints);
      }
      trailingChildWithLayout = child;
      assert(child != null);
      final SliverMultiBoxAdaptorParentData childParentData = child.parentData;
      childParentData.layoutOffset =
          indexToLayoutOffset(itemExtent, childParentData.index);
    }

    final int lastIndex = indexOf(lastChild);
    final double leadingScrollOffset =
        indexToLayoutOffset(itemExtent, firstIndex);
    final double trailingScrollOffset =
        indexToLayoutOffset(itemExtent, lastIndex + 1);

    assert(firstIndex == 0 || childScrollOffset(firstChild) <= scrollOffset);
    assert(debugAssertChildListIsNonEmptyAndContiguous());
    assert(indexOf(firstChild) == firstIndex);
    assert(targetLastIndex == null || lastIndex <= targetLastIndex);

    final double estimatedMaxScrollOffset = estimateMaxScrollOffset(
      constraints,
      firstIndex: firstIndex,
      lastIndex: lastIndex,
      leadingScrollOffset: leadingScrollOffset,
      trailingScrollOffset: trailingScrollOffset,
    );

    final double paintExtent = calculatePaintOffset(
      constraints,
      from: leadingScrollOffset,
      to: trailingScrollOffset,
    );

    final double cacheExtent = calculateCacheOffset(
      constraints,
      from: leadingScrollOffset,
      to: trailingScrollOffset,
    );

    final double targetEndScrollOffsetForPaint =
        constraints.scrollOffset + constraints.remainingPaintExtent;
    final int targetLastIndexForPaint = targetEndScrollOffsetForPaint.isFinite
        ? getMaxChildIndexForScrollOffset(
            targetEndScrollOffsetForPaint, itemExtent)
        : null;
    geometry = SliverGeometry(
      scrollExtent: estimatedMaxScrollOffset,
      paintExtent: paintExtent,
      cacheExtent: cacheExtent,
      maxPaintExtent: estimatedMaxScrollOffset,
      hasVisualOverflow: (targetLastIndexForPaint != null &&
              lastIndex >= targetLastIndexForPaint) ||
          constraints.scrollOffset > 0.0,
    );

    if (estimatedMaxScrollOffset == trailingScrollOffset)
      childManager.setDidUnderflow(true);
    childManager.didFinishLayout();
  }
}

class RenderSliverFixedExtentList extends RenderSliverFixedExtentBoxAdaptor {
  RenderSliverFixedExtentList({
    @required RenderSliverBoxChildManager childManager,
    double itemExtent,
  })  : _itemExtent = itemExtent,
        super(childManager: childManager);

  @override
  double get itemExtent => _itemExtent;
  double _itemExtent;
  set itemExtent(double value) {
    assert(value != null);
    if (_itemExtent == value) return;
    _itemExtent = value;
    markNeedsLayout();
  }
}

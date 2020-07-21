import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/gestures.dart';
import 'package:vector_math/vector_math_64.dart';

import 'box.dart';
import 'object.dart';
import 'sliver.dart';

abstract class RenderSliverBoxChildManager {
  void createChild(int index, {@required RenderBox after});

  void removeChild(RenderBox child);

  double estimateMaxScrollOffset(
    SliverConstraints constraints, {
    int firstIndex,
    int lastIndex,
    double leadingScrollOffset,
    double trailingScrollOffset,
  });

  int get childCount;

  void didAdoptChild(RenderBox child);

  void setDidUnderflow(bool value);

  void didStartLayout() {}

  void didFinishLayout() {}

  bool debugAssertChildListLocked() => true;
}

mixin KeepAliveParentDataMixin implements ParentData {
  bool keepAlive = false;

  bool get keptAlive;
}

mixin RenderSliverWithKeepAliveMixin implements RenderSliver {
  @override
  void setupParentData(RenderObject child) {
    assert(child.parentData is KeepAliveParentDataMixin);
  }
}

class SliverMultiBoxAdaptorParentData extends SliverLogicalParentData
    with ContainerParentDataMixin<RenderBox>, KeepAliveParentDataMixin {
  int index;

  @override
  bool get keptAlive => _keptAlive;
  bool _keptAlive = false;

  @override
  String toString() =>
      'index=$index; ${keepAlive == true ? "keepAlive; " : ""}${super.toString()}';
}

abstract class RenderSliverMultiBoxAdaptor extends RenderSliver
    with
        ContainerRenderObjectMixin<RenderBox, SliverMultiBoxAdaptorParentData>,
        RenderSliverHelpers,
        RenderSliverWithKeepAliveMixin {
  RenderSliverMultiBoxAdaptor({
    @required RenderSliverBoxChildManager childManager,
  })  : assert(childManager != null),
        _childManager = childManager {
    assert(() {
      _debugDanglingKeepAlives = <RenderBox>[];
      return true;
    }());
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! SliverMultiBoxAdaptorParentData)
      child.parentData = SliverMultiBoxAdaptorParentData();
  }

  @protected
  RenderSliverBoxChildManager get childManager => _childManager;
  final RenderSliverBoxChildManager _childManager;

  final Map<int, RenderBox> _keepAliveBucket = <int, RenderBox>{};

  List<RenderBox> _debugDanglingKeepAlives;

  bool get debugChildIntegrityEnabled => _debugChildIntegrityEnabled;
  bool _debugChildIntegrityEnabled = true;
  set debugChildIntegrityEnabled(bool enabled) {
    assert(enabled != null);
    assert(() {
      _debugChildIntegrityEnabled = enabled;
      return _debugVerifyChildOrder() &&
          (!_debugChildIntegrityEnabled || _debugDanglingKeepAlives.isEmpty);
    }());
  }

  @override
  void adoptChild(RenderObject child) {
    super.adoptChild(child);
    final SliverMultiBoxAdaptorParentData childParentData = child.parentData;
    if (!childParentData._keptAlive) childManager.didAdoptChild(child);
  }

  bool _debugAssertChildListLocked() =>
      childManager.debugAssertChildListLocked();

  bool _debugVerifyChildOrder() {
    if (_debugChildIntegrityEnabled) {
      RenderBox child = firstChild;
      int index;
      while (child != null) {
        index = indexOf(child);
        child = childAfter(child);
        assert(child == null || indexOf(child) > index);
      }
    }
    return true;
  }

  @override
  void insert(RenderBox child, {RenderBox after}) {
    assert(!_keepAliveBucket.containsValue(child));
    super.insert(child, after: after);
    assert(firstChild != null);
    assert(_debugVerifyChildOrder());
  }

  @override
  void move(RenderBox child, {RenderBox after}) {
    final SliverMultiBoxAdaptorParentData childParentData = child.parentData;
    if (!childParentData.keptAlive) {
      super.move(child, after: after);
      childManager.didAdoptChild(child);

      markNeedsLayout();
    } else {
      if (_keepAliveBucket[childParentData.index] == child) {
        _keepAliveBucket.remove(childParentData.index);
      }
      assert(() {
        _debugDanglingKeepAlives.remove(child);
        return true;
      }());

      childManager.didAdoptChild(child);

      assert(() {
        if (_keepAliveBucket.containsKey(childParentData.index))
          _debugDanglingKeepAlives.add(_keepAliveBucket[childParentData.index]);
        return true;
      }());
      _keepAliveBucket[childParentData.index] = child;
    }
  }

  @override
  void remove(RenderBox child) {
    final SliverMultiBoxAdaptorParentData childParentData = child.parentData;
    if (!childParentData._keptAlive) {
      super.remove(child);
      return;
    }
    assert(_keepAliveBucket[childParentData.index] == child);
    assert(() {
      _debugDanglingKeepAlives.remove(child);
      return true;
    }());
    _keepAliveBucket.remove(childParentData.index);
    dropChild(child);
  }

  @override
  void removeAll() {
    super.removeAll();
    _keepAliveBucket.values.forEach(dropChild);
    _keepAliveBucket.clear();
  }

  void _createOrObtainChild(int index, {RenderBox after}) {
    invokeLayoutCallback<SliverConstraints>((SliverConstraints constraints) {
      assert(constraints == this.constraints);
      if (_keepAliveBucket.containsKey(index)) {
        final RenderBox child = _keepAliveBucket.remove(index);
        final SliverMultiBoxAdaptorParentData childParentData =
            child.parentData;
        assert(childParentData._keptAlive);
        dropChild(child);
        child.parentData = childParentData;
        insert(child, after: after);
        childParentData._keptAlive = false;
      } else {
        _childManager.createChild(index, after: after);
      }
    });
  }

  void _destroyOrCacheChild(RenderBox child) {
    final SliverMultiBoxAdaptorParentData childParentData = child.parentData;
    if (childParentData.keepAlive) {
      assert(!childParentData._keptAlive);
      remove(child);
      _keepAliveBucket[childParentData.index] = child;
      child.parentData = childParentData;
      super.adoptChild(child);
      childParentData._keptAlive = true;
    } else {
      assert(child.parent == this);
      _childManager.removeChild(child);
      assert(child.parent == null);
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    for (RenderBox child in _keepAliveBucket.values) child.attach(owner);
  }

  @override
  void detach() {
    super.detach();
    for (RenderBox child in _keepAliveBucket.values) child.detach();
  }

  @override
  void redepthChildren() {
    super.redepthChildren();
    _keepAliveBucket.values.forEach(redepthChild);
  }

  @override
  void visitChildren(RenderObjectVisitor visitor) {
    super.visitChildren(visitor);
    _keepAliveBucket.values.forEach(visitor);
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    super.visitChildren(visitor);
  }

  @protected
  bool addInitialChild({int index = 0, double layoutOffset = 0.0}) {
    assert(_debugAssertChildListLocked());
    assert(firstChild == null);
    _createOrObtainChild(index, after: null);
    if (firstChild != null) {
      assert(firstChild == lastChild);
      assert(indexOf(firstChild) == index);
      final SliverMultiBoxAdaptorParentData firstChildParentData =
          firstChild.parentData;
      firstChildParentData.layoutOffset = layoutOffset;
      return true;
    }
    childManager.setDidUnderflow(true);
    return false;
  }

  @protected
  RenderBox insertAndLayoutLeadingChild(
    BoxConstraints childConstraints, {
    bool parentUsesSize = false,
  }) {
    assert(_debugAssertChildListLocked());
    final int index = indexOf(firstChild) - 1;
    _createOrObtainChild(index, after: null);
    if (indexOf(firstChild) == index) {
      firstChild.layout(childConstraints, parentUsesSize: parentUsesSize);
      return firstChild;
    }
    childManager.setDidUnderflow(true);
    return null;
  }

  @protected
  RenderBox insertAndLayoutChild(
    BoxConstraints childConstraints, {
    @required RenderBox after,
    bool parentUsesSize = false,
  }) {
    assert(_debugAssertChildListLocked());
    assert(after != null);
    final int index = indexOf(after) + 1;
    _createOrObtainChild(index, after: after);
    final RenderBox child = childAfter(after);
    if (child != null && indexOf(child) == index) {
      child.layout(childConstraints, parentUsesSize: parentUsesSize);
      return child;
    }
    childManager.setDidUnderflow(true);
    return null;
  }

  @protected
  void collectGarbage(int leadingGarbage, int trailingGarbage) {
    assert(_debugAssertChildListLocked());
    assert(childCount >= leadingGarbage + trailingGarbage);
    invokeLayoutCallback<SliverConstraints>((SliverConstraints constraints) {
      while (leadingGarbage > 0) {
        _destroyOrCacheChild(firstChild);
        leadingGarbage -= 1;
      }
      while (trailingGarbage > 0) {
        _destroyOrCacheChild(lastChild);
        trailingGarbage -= 1;
      }

      _keepAliveBucket.values
          .where((RenderBox child) {
            final SliverMultiBoxAdaptorParentData childParentData =
                child.parentData;
            return !childParentData.keepAlive;
          })
          .toList()
          .forEach(_childManager.removeChild);
      assert(_keepAliveBucket.values.where((RenderBox child) {
        final SliverMultiBoxAdaptorParentData childParentData =
            child.parentData;
        return !childParentData.keepAlive;
      }).isEmpty);
    });
  }

  int indexOf(RenderBox child) {
    assert(child != null);
    final SliverMultiBoxAdaptorParentData childParentData = child.parentData;
    assert(childParentData.index != null);
    return childParentData.index;
  }

  @protected
  double paintExtentOf(RenderBox child) {
    assert(child != null);
    assert(child.hasSize);
    switch (constraints.axis) {
      case Axis.horizontal:
        return child.size.width;
      case Axis.vertical:
        return child.size.height;
    }
    return null;
  }

  @override
  bool hitTestChildren(SliverHitTestResult result,
      {@required double mainAxisPosition, @required double crossAxisPosition}) {
    RenderBox child = lastChild;
    final BoxHitTestResult boxResult = BoxHitTestResult.wrap(result);
    while (child != null) {
      if (hitTestBoxChild(boxResult, child,
          mainAxisPosition: mainAxisPosition,
          crossAxisPosition: crossAxisPosition)) return true;
      child = childBefore(child);
    }
    return false;
  }

  @override
  double childMainAxisPosition(RenderBox child) {
    return childScrollOffset(child) - constraints.scrollOffset;
  }

  @override
  double childScrollOffset(RenderObject child) {
    assert(child != null);
    assert(child.parent == this);
    final SliverMultiBoxAdaptorParentData childParentData = child.parentData;
    assert(childParentData.layoutOffset != null);
    return childParentData.layoutOffset;
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    applyPaintTransformForBoxChild(child, transform);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (firstChild == null) return;

    Offset mainAxisUnit, crossAxisUnit, originOffset;
    bool addExtent;
    switch (applyGrowthDirectionToAxisDirection(
        constraints.axisDirection, constraints.growthDirection)) {
      case AxisDirection.up:
        mainAxisUnit = const Offset(0.0, -1.0);
        crossAxisUnit = const Offset(1.0, 0.0);
        originOffset = offset + Offset(0.0, geometry.paintExtent);
        addExtent = true;
        break;
      case AxisDirection.right:
        mainAxisUnit = const Offset(1.0, 0.0);
        crossAxisUnit = const Offset(0.0, 1.0);
        originOffset = offset;
        addExtent = false;
        break;
      case AxisDirection.down:
        mainAxisUnit = const Offset(0.0, 1.0);
        crossAxisUnit = const Offset(1.0, 0.0);
        originOffset = offset;
        addExtent = false;
        break;
      case AxisDirection.left:
        mainAxisUnit = const Offset(-1.0, 0.0);
        crossAxisUnit = const Offset(0.0, 1.0);
        originOffset = offset + Offset(geometry.paintExtent, 0.0);
        addExtent = true;
        break;
    }
    assert(mainAxisUnit != null);
    assert(addExtent != null);
    RenderBox child = firstChild;
    while (child != null) {
      final double mainAxisDelta = childMainAxisPosition(child);
      final double crossAxisDelta = childCrossAxisPosition(child);
      Offset childOffset = Offset(
        originOffset.dx +
            mainAxisUnit.dx * mainAxisDelta +
            crossAxisUnit.dx * crossAxisDelta,
        originOffset.dy +
            mainAxisUnit.dy * mainAxisDelta +
            crossAxisUnit.dy * crossAxisDelta,
      );
      if (addExtent) childOffset += mainAxisUnit * paintExtentOf(child);

      if (mainAxisDelta < constraints.remainingPaintExtent &&
          mainAxisDelta + paintExtentOf(child) > 0)
        context.paintChild(child, childOffset);

      child = childAfter(child);
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsNode.message(firstChild != null
        ? 'currently live children: ${indexOf(firstChild)} to ${indexOf(lastChild)}'
        : 'no children current live'));
  }

  bool debugAssertChildListIsNonEmptyAndContiguous() {
    assert(() {
      assert(firstChild != null);
      int index = indexOf(firstChild);
      RenderBox child = childAfter(firstChild);
      while (child != null) {
        index += 1;
        assert(indexOf(child) == index);
        child = childAfter(child);
      }
      return true;
    }());
    return true;
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    final List<DiagnosticsNode> children = <DiagnosticsNode>[];
    if (firstChild != null) {
      RenderBox child = firstChild;
      while (true) {
        final SliverMultiBoxAdaptorParentData childParentData =
            child.parentData;
        children.add(child.toDiagnosticsNode(
            name: 'child with index ${childParentData.index}'));
        if (child == lastChild) break;
        child = childParentData.nextSibling;
      }
    }
    if (_keepAliveBucket.isNotEmpty) {
      final List<int> indices = _keepAliveBucket.keys.toList()..sort();
      for (int index in indices) {
        children.add(_keepAliveBucket[index].toDiagnosticsNode(
          name: 'child with index $index (kept alive but not laid out)',
          style: DiagnosticsTreeStyle.offstage,
        ));
      }
    }
    return children;
  }
}

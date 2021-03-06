import 'package:flutter_web/foundation.dart';

import 'box.dart';
import 'object.dart';

class MultiChildLayoutParentData extends ContainerBoxParentData<RenderBox> {
  Object id;

  @override
  String toString() => '${super.toString()}; id=$id';
}

abstract class MultiChildLayoutDelegate {
  Map<Object, RenderBox> _idToChild;
  Set<RenderBox> _debugChildrenNeedingLayout;

  bool hasChild(Object childId) => _idToChild[childId] != null;

  Size layoutChild(Object childId, BoxConstraints constraints) {
    final RenderBox child = _idToChild[childId];
    assert(() {
      if (child == null) {
        throw FlutterError(
            'The $this custom multichild layout delegate tried to lay out a non-existent child.\n'
            'There is no child with the id "$childId".');
      }
      if (!_debugChildrenNeedingLayout.remove(child)) {
        throw FlutterError(
            'The $this custom multichild layout delegate tried to lay out the child with id "$childId" more than once.\n'
            'Each child must be laid out exactly once.');
      }
      try {
        assert(constraints.debugAssertIsValid(isAppliedConstraint: true));
      } on AssertionError catch (exception) {
        throw FlutterError(
            'The $this custom multichild layout delegate provided invalid box constraints for the child with id "$childId".\n'
            '$exception\n'
            'The minimum width and height must be greater than or equal to zero.\n'
            'The maximum width must be greater than or equal to the minimum width.\n'
            'The maximum height must be greater than or equal to the minimum height.');
      }
      return true;
    }());
    child.layout(constraints, parentUsesSize: true);
    return child.size;
  }

  void positionChild(Object childId, Offset offset) {
    final RenderBox child = _idToChild[childId];
    assert(() {
      if (child == null) {
        throw FlutterError(
            'The $this custom multichild layout delegate tried to position out a non-existent child:\n'
            'There is no child with the id "$childId".');
      }
      if (offset == null) {
        throw FlutterError(
            'The $this custom multichild layout delegate provided a null position for the child with id "$childId".');
      }
      return true;
    }());
    final MultiChildLayoutParentData childParentData = child.parentData;
    childParentData.offset = offset;
  }

  String _debugDescribeChild(RenderBox child) {
    final MultiChildLayoutParentData childParentData = child.parentData;
    return '${childParentData.id}: $child';
  }

  void _callPerformLayout(Size size, RenderBox firstChild) {
    final Map<Object, RenderBox> previousIdToChild = _idToChild;

    Set<RenderBox> debugPreviousChildrenNeedingLayout;
    assert(() {
      debugPreviousChildrenNeedingLayout = _debugChildrenNeedingLayout;
      _debugChildrenNeedingLayout = <RenderBox>{};
      return true;
    }());

    try {
      _idToChild = <Object, RenderBox>{};
      RenderBox child = firstChild;
      while (child != null) {
        final MultiChildLayoutParentData childParentData = child.parentData;
        assert(() {
          if (childParentData.id == null) {
            throw FlutterError('The following child has no ID:\n'
                '  $child\n'
                'Every child of a RenderCustomMultiChildLayoutBox must have an ID in its parent data.');
          }
          return true;
        }());
        _idToChild[childParentData.id] = child;
        assert(() {
          _debugChildrenNeedingLayout.add(child);
          return true;
        }());
        child = childParentData.nextSibling;
      }
      performLayout(size);
      assert(() {
        if (_debugChildrenNeedingLayout.isNotEmpty) {
          if (_debugChildrenNeedingLayout.length > 1) {
            throw FlutterError(
                'The $this custom multichild layout delegate forgot to lay out the following children:\n'
                '  ${_debugChildrenNeedingLayout.map<String>(_debugDescribeChild).join("\n  ")}\n'
                'Each child must be laid out exactly once.');
          } else {
            throw FlutterError(
                'The $this custom multichild layout delegate forgot to lay out the following child:\n'
                '  ${_debugDescribeChild(_debugChildrenNeedingLayout.single)}\n'
                'Each child must be laid out exactly once.');
          }
        }
        return true;
      }());
    } finally {
      _idToChild = previousIdToChild;
      assert(() {
        _debugChildrenNeedingLayout = debugPreviousChildrenNeedingLayout;
        return true;
      }());
    }
  }

  Size getSize(BoxConstraints constraints) => constraints.biggest;

  void performLayout(Size size);

  bool shouldRelayout(covariant MultiChildLayoutDelegate oldDelegate);

  @override
  String toString() => '$runtimeType';
}

class RenderCustomMultiChildLayoutBox extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, MultiChildLayoutParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, MultiChildLayoutParentData> {
  RenderCustomMultiChildLayoutBox({
    List<RenderBox> children,
    @required MultiChildLayoutDelegate delegate,
  })  : assert(delegate != null),
        _delegate = delegate {
    addAll(children);
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! MultiChildLayoutParentData)
      child.parentData = MultiChildLayoutParentData();
  }

  MultiChildLayoutDelegate get delegate => _delegate;
  MultiChildLayoutDelegate _delegate;
  set delegate(MultiChildLayoutDelegate value) {
    assert(value != null);
    if (_delegate == value) return;
    if (value.runtimeType != _delegate.runtimeType ||
        value.shouldRelayout(_delegate)) markNeedsLayout();
    _delegate = value;
  }

  Size _getSize(BoxConstraints constraints) {
    assert(constraints.debugAssertIsValid());
    return constraints.constrain(_delegate.getSize(constraints));
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    final double width =
        _getSize(BoxConstraints.tightForFinite(height: height)).width;
    if (width.isFinite) return width;
    return 0.0;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    final double width =
        _getSize(BoxConstraints.tightForFinite(height: height)).width;
    if (width.isFinite) return width;
    return 0.0;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    final double height =
        _getSize(BoxConstraints.tightForFinite(width: width)).height;
    if (height.isFinite) return height;
    return 0.0;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    final double height =
        _getSize(BoxConstraints.tightForFinite(width: width)).height;
    if (height.isFinite) return height;
    return 0.0;
  }

  @override
  void performLayout() {
    size = _getSize(constraints);
    delegate._callPerformLayout(size, firstChild);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }
}

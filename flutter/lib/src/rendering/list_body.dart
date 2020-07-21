import 'dart:math' as math;

import 'box.dart';
import 'object.dart';

class ListBodyParentData extends ContainerBoxParentData<RenderBox> {}

typedef _ChildSizingFunction = double Function(RenderBox child);

class RenderListBody extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, ListBodyParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, ListBodyParentData> {
  RenderListBody({
    List<RenderBox> children,
    AxisDirection axisDirection = AxisDirection.down,
  })  : assert(axisDirection != null),
        _axisDirection = axisDirection {
    addAll(children);
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! ListBodyParentData)
      child.parentData = ListBodyParentData();
  }

  AxisDirection get axisDirection => _axisDirection;
  AxisDirection _axisDirection;
  set axisDirection(AxisDirection value) {
    assert(value != null);
    if (_axisDirection == value) return;
    _axisDirection = value;
    markNeedsLayout();
  }

  Axis get mainAxis => axisDirectionToAxis(axisDirection);

  @override
  void performLayout() {
    assert(() {
      switch (mainAxis) {
        case Axis.horizontal:
          if (!constraints.hasBoundedWidth) return true;
          break;
        case Axis.vertical:
          if (!constraints.hasBoundedHeight) return true;
          break;
      }
      throw FlutterError(
          'RenderListBody must have unlimited space along its main axis.\n'
          'RenderListBody does not clip or resize its children, so it must be '
          'placed in a parent that does not constrain the main '
          'axis. You probably want to put the RenderListBody inside a '
          'RenderViewport with a matching main axis.');
    }());
    assert(() {
      switch (mainAxis) {
        case Axis.horizontal:
          if (constraints.hasBoundedHeight) return true;
          break;
        case Axis.vertical:
          if (constraints.hasBoundedWidth) return true;
          break;
      }

      throw FlutterError(
          'RenderListBody must have a bounded constraint for its cross axis.\n'
          'RenderListBody forces its children to expand to fit the RenderListBody\'s container, '
          'so it must be placed in a parent that constrains the cross '
          'axis to a finite dimension. If you are attempting to nest a RenderListBody with '
          'one direction inside one of another direction, you will want to '
          'wrap the inner one inside a box that fixes the dimension in that direction, '
          'for example, a RenderIntrinsicWidth or RenderIntrinsicHeight object. '
          'This is relatively expensive, however.');
    }());
    double mainAxisExtent = 0.0;
    RenderBox child = firstChild;
    switch (axisDirection) {
      case AxisDirection.right:
        final BoxConstraints innerConstraints =
            BoxConstraints.tightFor(height: constraints.maxHeight);
        while (child != null) {
          child.layout(innerConstraints, parentUsesSize: true);
          final ListBodyParentData childParentData = child.parentData;
          childParentData.offset = Offset(mainAxisExtent, 0.0);
          mainAxisExtent += child.size.width;
          assert(child.parentData == childParentData);
          child = childParentData.nextSibling;
        }
        size =
            constraints.constrain(Size(mainAxisExtent, constraints.maxHeight));
        break;
      case AxisDirection.left:
        final BoxConstraints innerConstraints =
            BoxConstraints.tightFor(height: constraints.maxHeight);
        while (child != null) {
          child.layout(innerConstraints, parentUsesSize: true);
          final ListBodyParentData childParentData = child.parentData;
          mainAxisExtent += child.size.width;
          assert(child.parentData == childParentData);
          child = childParentData.nextSibling;
        }
        double position = 0.0;
        child = firstChild;
        while (child != null) {
          final ListBodyParentData childParentData = child.parentData;
          position += child.size.width;
          childParentData.offset = Offset(mainAxisExtent - position, 0.0);
          assert(child.parentData == childParentData);
          child = childParentData.nextSibling;
        }
        size =
            constraints.constrain(Size(mainAxisExtent, constraints.maxHeight));
        break;
      case AxisDirection.down:
        final BoxConstraints innerConstraints =
            BoxConstraints.tightFor(width: constraints.maxWidth);
        while (child != null) {
          child.layout(innerConstraints, parentUsesSize: true);
          final ListBodyParentData childParentData = child.parentData;
          childParentData.offset = Offset(0.0, mainAxisExtent);
          mainAxisExtent += child.size.height;
          assert(child.parentData == childParentData);
          child = childParentData.nextSibling;
        }
        size =
            constraints.constrain(Size(constraints.maxWidth, mainAxisExtent));
        break;
      case AxisDirection.up:
        final BoxConstraints innerConstraints =
            BoxConstraints.tightFor(width: constraints.maxWidth);
        while (child != null) {
          child.layout(innerConstraints, parentUsesSize: true);
          final ListBodyParentData childParentData = child.parentData;
          mainAxisExtent += child.size.height;
          assert(child.parentData == childParentData);
          child = childParentData.nextSibling;
        }
        double position = 0.0;
        child = firstChild;
        while (child != null) {
          final ListBodyParentData childParentData = child.parentData;
          position += child.size.height;
          childParentData.offset = Offset(0.0, mainAxisExtent - position);
          assert(child.parentData == childParentData);
          child = childParentData.nextSibling;
        }
        size =
            constraints.constrain(Size(constraints.maxWidth, mainAxisExtent));
        break;
    }
    assert(size.isFinite);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<AxisDirection>('axisDirection', axisDirection));
  }

  double _getIntrinsicCrossAxis(_ChildSizingFunction childSize) {
    double extent = 0.0;
    RenderBox child = firstChild;
    while (child != null) {
      extent = math.max(extent, childSize(child));
      final ListBodyParentData childParentData = child.parentData;
      child = childParentData.nextSibling;
    }
    return extent;
  }

  double _getIntrinsicMainAxis(_ChildSizingFunction childSize) {
    double extent = 0.0;
    RenderBox child = firstChild;
    while (child != null) {
      extent += childSize(child);
      final ListBodyParentData childParentData = child.parentData;
      child = childParentData.nextSibling;
    }
    return extent;
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    assert(mainAxis != null);
    switch (mainAxis) {
      case Axis.horizontal:
        return _getIntrinsicMainAxis(
            (RenderBox child) => child.getMinIntrinsicWidth(height));
      case Axis.vertical:
        return _getIntrinsicCrossAxis(
            (RenderBox child) => child.getMinIntrinsicWidth(height));
    }
    return null;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    assert(mainAxis != null);
    switch (mainAxis) {
      case Axis.horizontal:
        return _getIntrinsicMainAxis(
            (RenderBox child) => child.getMaxIntrinsicWidth(height));
      case Axis.vertical:
        return _getIntrinsicCrossAxis(
            (RenderBox child) => child.getMaxIntrinsicWidth(height));
    }
    return null;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    assert(mainAxis != null);
    switch (mainAxis) {
      case Axis.horizontal:
        return _getIntrinsicMainAxis(
            (RenderBox child) => child.getMinIntrinsicHeight(width));
      case Axis.vertical:
        return _getIntrinsicCrossAxis(
            (RenderBox child) => child.getMinIntrinsicHeight(width));
    }
    return null;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    assert(mainAxis != null);
    switch (mainAxis) {
      case Axis.horizontal:
        return _getIntrinsicMainAxis(
            (RenderBox child) => child.getMaxIntrinsicHeight(width));
      case Axis.vertical:
        return _getIntrinsicCrossAxis(
            (RenderBox child) => child.getMaxIntrinsicHeight(width));
    }
    return null;
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    return defaultComputeDistanceToFirstActualBaseline(baseline);
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

import 'package:flutter_web/foundation.dart';

import 'package:vector_math/vector_math_64.dart';

import 'box.dart';
import 'object.dart';

abstract class FlowPaintingContext {
  Size get size;

  int get childCount;

  Size getChildSize(int i);

  void paintChild(int i, {Matrix4 transform, double opacity = 1.0});
}

abstract class FlowDelegate {
  const FlowDelegate({Listenable repaint}) : _repaint = repaint;

  final Listenable _repaint;

  Size getSize(BoxConstraints constraints) => constraints.biggest;

  BoxConstraints getConstraintsForChild(int i, BoxConstraints constraints) =>
      constraints;

  void paintChildren(FlowPaintingContext context);

  bool shouldRelayout(covariant FlowDelegate oldDelegate) => false;

  bool shouldRepaint(covariant FlowDelegate oldDelegate);

  @override
  String toString() => '$runtimeType';
}

int _getAlphaFromOpacity(double opacity) => (opacity * 255).round();

class FlowParentData extends ContainerBoxParentData<RenderBox> {
  Matrix4 _transform;
}

class RenderFlow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, FlowParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, FlowParentData>
    implements FlowPaintingContext {
  RenderFlow({
    List<RenderBox> children,
    @required FlowDelegate delegate,
  })  : assert(delegate != null),
        _delegate = delegate {
    addAll(children);
  }

  @override
  void setupParentData(RenderBox child) {
    final ParentData childParentData = child.parentData;
    if (childParentData is FlowParentData)
      childParentData._transform = null;
    else
      child.parentData = FlowParentData();
  }

  FlowDelegate get delegate => _delegate;
  FlowDelegate _delegate;

  set delegate(FlowDelegate newDelegate) {
    assert(newDelegate != null);
    if (_delegate == newDelegate) return;
    final FlowDelegate oldDelegate = _delegate;
    _delegate = newDelegate;

    if (newDelegate.runtimeType != oldDelegate.runtimeType ||
        newDelegate.shouldRelayout(oldDelegate))
      markNeedsLayout();
    else if (newDelegate.shouldRepaint(oldDelegate)) markNeedsPaint();

    if (attached) {
      oldDelegate._repaint?.removeListener(markNeedsPaint);
      newDelegate._repaint?.addListener(markNeedsPaint);
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _delegate._repaint?.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _delegate._repaint?.removeListener(markNeedsPaint);
    super.detach();
  }

  Size _getSize(BoxConstraints constraints) {
    assert(constraints.debugAssertIsValid());
    return constraints.constrain(_delegate.getSize(constraints));
  }

  @override
  bool get isRepaintBoundary => true;

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
    int i = 0;
    _randomAccessChildren.clear();
    RenderBox child = firstChild;
    while (child != null) {
      _randomAccessChildren.add(child);
      final BoxConstraints innerConstraints =
          _delegate.getConstraintsForChild(i, constraints);
      child.layout(innerConstraints, parentUsesSize: true);
      final FlowParentData childParentData = child.parentData;
      childParentData.offset = Offset.zero;
      child = childParentData.nextSibling;
      i += 1;
    }
  }

  final List<RenderBox> _randomAccessChildren = <RenderBox>[];

  final List<int> _lastPaintOrder = <int>[];

  PaintingContext _paintingContext;
  Offset _paintingOffset;

  @override
  Size getChildSize(int i) {
    if (i < 0 || i >= _randomAccessChildren.length) return null;
    return _randomAccessChildren[i].size;
  }

  @override
  void paintChild(int i, {Matrix4 transform, double opacity = 1.0}) {
    transform ??= Matrix4.identity();
    final RenderBox child = _randomAccessChildren[i];
    final FlowParentData childParentData = child.parentData;
    assert(() {
      if (childParentData._transform != null) {
        throw FlutterError('Cannot call paintChild twice for the same child.\n'
            'The flow delegate of type ${_delegate.runtimeType} attempted to '
            'paint child $i multiple times, which is not permitted.');
      }
      return true;
    }());
    _lastPaintOrder.add(i);
    childParentData._transform = transform;

    if (opacity == 0.0) return;

    void painter(PaintingContext context, Offset offset) {
      context.paintChild(child, offset);
    }

    if (opacity == 1.0) {
      _paintingContext.pushTransform(
          needsCompositing, _paintingOffset, transform, painter);
    } else {
      _paintingContext
          .pushOpacity(_paintingOffset, _getAlphaFromOpacity(opacity),
              (PaintingContext context, Offset offset) {
        context.pushTransform(needsCompositing, offset, transform, painter);
      });
    }
  }

  void _paintWithDelegate(PaintingContext context, Offset offset) {
    _lastPaintOrder.clear();
    _paintingContext = context;
    _paintingOffset = offset;
    for (RenderBox child in _randomAccessChildren) {
      final FlowParentData childParentData = child.parentData;
      childParentData._transform = null;
    }
    try {
      _delegate.paintChildren(this);
    } finally {
      _paintingContext = null;
      _paintingOffset = null;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    context.pushClipRect(
        needsCompositing, offset, Offset.zero & size, _paintWithDelegate);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {Offset position}) {
    final List<RenderBox> children = getChildrenAsList();
    for (int i = _lastPaintOrder.length - 1; i >= 0; --i) {
      final int childIndex = _lastPaintOrder[i];
      if (childIndex >= children.length) continue;
      final RenderBox child = children[childIndex];
      final FlowParentData childParentData = child.parentData;
      final Matrix4 transform = childParentData._transform;
      if (transform == null) continue;
      final bool absorbed = result.addWithPaintTransform(
        transform: transform,
        position: position,
        hitTest: (BoxHitTestResult result, Offset position) {
          return child.hitTest(result, position: position);
        },
      );
      if (absorbed) return true;
    }
    return false;
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final FlowParentData childParentData = child.parentData;
    if (childParentData._transform != null)
      transform.multiply(childParentData._transform);
    super.applyPaintTransform(child, transform);
  }
}

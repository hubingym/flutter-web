import 'dart:math' as math;

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/gestures.dart';
import 'package:flutter_web/painting.dart';
import 'package:vector_math/vector_math_64.dart';

import 'box.dart';
import 'object.dart';

const double _kQuarterTurnsInRadians = math.pi / 2.0;

class RenderRotatedBox extends RenderBox
    with RenderObjectWithChildMixin<RenderBox> {
  RenderRotatedBox({
    @required int quarterTurns,
    RenderBox child,
  })  : assert(quarterTurns != null),
        _quarterTurns = quarterTurns {
    this.child = child;
  }

  int get quarterTurns => _quarterTurns;
  int _quarterTurns;
  set quarterTurns(int value) {
    assert(value != null);
    if (_quarterTurns == value) return;
    _quarterTurns = value;
    markNeedsLayout();
  }

  bool get _isVertical => quarterTurns % 2 == 1;

  @override
  double computeMinIntrinsicWidth(double height) {
    if (child == null) return 0.0;
    return _isVertical
        ? child.getMinIntrinsicHeight(height)
        : child.getMinIntrinsicWidth(height);
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    if (child == null) return 0.0;
    return _isVertical
        ? child.getMaxIntrinsicHeight(height)
        : child.getMaxIntrinsicWidth(height);
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    if (child == null) return 0.0;
    return _isVertical
        ? child.getMinIntrinsicWidth(width)
        : child.getMinIntrinsicHeight(width);
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    if (child == null) return 0.0;
    return _isVertical
        ? child.getMaxIntrinsicWidth(width)
        : child.getMaxIntrinsicHeight(width);
  }

  Matrix4 _paintTransform;

  @override
  void performLayout() {
    _paintTransform = null;
    if (child != null) {
      child.layout(_isVertical ? constraints.flipped : constraints,
          parentUsesSize: true);
      size =
          _isVertical ? Size(child.size.height, child.size.width) : child.size;
      _paintTransform = Matrix4.identity()
        ..translate(size.width / 2.0, size.height / 2.0)
        ..rotateZ(_kQuarterTurnsInRadians * (quarterTurns % 4))
        ..translate(-child.size.width / 2.0, -child.size.height / 2.0);
    } else {
      performResize();
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {Offset position}) {
    assert(_paintTransform != null || debugNeedsLayout || child == null);
    if (child == null || _paintTransform == null) return false;
    return result.addWithPaintTransform(
      transform: _paintTransform,
      position: position,
      hitTest: (BoxHitTestResult result, Offset position) {
        return child.hitTest(result, position: position);
      },
    );
  }

  void _paintChild(PaintingContext context, Offset offset) {
    context.paintChild(child, offset);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null)
      context.pushTransform(
          needsCompositing, offset, _paintTransform, _paintChild);
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    if (_paintTransform != null) transform.multiply(_paintTransform);
    super.applyPaintTransform(child, transform);
  }
}

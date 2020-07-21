import 'dart:math' as math;

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/gestures.dart';
import 'package:flutter_web/ui.dart';
import 'package:meta/meta.dart';

import 'box.dart';
import 'debug.dart';
import 'debug_overflow_indicator.dart';
import 'object.dart';
import 'stack.dart' show RelativeRect;

abstract class RenderShiftedBox extends RenderBox
    with RenderObjectWithChildMixin<RenderBox> {
  RenderShiftedBox(RenderBox child) {
    this.child = child;
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    if (child != null) return child.getMinIntrinsicWidth(height);
    return 0.0;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    if (child != null) return child.getMaxIntrinsicWidth(height);
    return 0.0;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    if (child != null) return child.getMinIntrinsicHeight(width);
    return 0.0;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    if (child != null) return child.getMaxIntrinsicHeight(width);
    return 0.0;
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    double result;
    if (child != null) {
      assert(!debugNeedsLayout);
      result = child.getDistanceToActualBaseline(baseline);
      final BoxParentData childParentData = child.parentData;
      if (result != null) result += childParentData.offset.dy;
    } else {
      result = super.computeDistanceToActualBaseline(baseline);
    }
    return result;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      final BoxParentData childParentData = child.parentData;
      context.paintChild(child, childParentData.offset + offset);
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {Offset position}) {
    if (child != null) {
      final BoxParentData childParentData = child.parentData;
      return result.addWithPaintOffset(
        offset: childParentData.offset,
        position: position,
        hitTest: (BoxHitTestResult result, Offset transformed) {
          assert(transformed == position - childParentData.offset);
          return child.hitTest(result, position: transformed);
        },
      );
    }
    return false;
  }
}

class RenderPadding extends RenderShiftedBox {
  RenderPadding({
    @required EdgeInsetsGeometry padding,
    TextDirection textDirection,
    RenderBox child,
  })  : assert(padding != null),
        assert(padding.isNonNegative),
        _textDirection = textDirection,
        _padding = padding,
        super(child);

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
    assert(value.isNonNegative);
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

  @override
  double computeMinIntrinsicWidth(double height) {
    _resolve();
    final double totalHorizontalPadding =
        _resolvedPadding.left + _resolvedPadding.right;
    final double totalVerticalPadding =
        _resolvedPadding.top + _resolvedPadding.bottom;
    if (child != null)
      return child.getMinIntrinsicWidth(
              math.max(0.0, height - totalVerticalPadding)) +
          totalHorizontalPadding;
    return totalHorizontalPadding;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    _resolve();
    final double totalHorizontalPadding =
        _resolvedPadding.left + _resolvedPadding.right;
    final double totalVerticalPadding =
        _resolvedPadding.top + _resolvedPadding.bottom;
    if (child != null)
      return child.getMaxIntrinsicWidth(
              math.max(0.0, height - totalVerticalPadding)) +
          totalHorizontalPadding;
    return totalHorizontalPadding;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    _resolve();
    final double totalHorizontalPadding =
        _resolvedPadding.left + _resolvedPadding.right;
    final double totalVerticalPadding =
        _resolvedPadding.top + _resolvedPadding.bottom;
    if (child != null)
      return child.getMinIntrinsicHeight(
              math.max(0.0, width - totalHorizontalPadding)) +
          totalVerticalPadding;
    return totalVerticalPadding;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    _resolve();
    final double totalHorizontalPadding =
        _resolvedPadding.left + _resolvedPadding.right;
    final double totalVerticalPadding =
        _resolvedPadding.top + _resolvedPadding.bottom;
    if (child != null)
      return child.getMaxIntrinsicHeight(
              math.max(0.0, width - totalHorizontalPadding)) +
          totalVerticalPadding;
    return totalVerticalPadding;
  }

  @override
  void performLayout() {
    _resolve();
    assert(_resolvedPadding != null);
    if (child == null) {
      size = constraints.constrain(Size(
        _resolvedPadding.left + _resolvedPadding.right,
        _resolvedPadding.top + _resolvedPadding.bottom,
      ));
      return;
    }
    final BoxConstraints innerConstraints =
        constraints.deflate(_resolvedPadding);
    child.layout(innerConstraints, parentUsesSize: true);
    final BoxParentData childParentData = child.parentData;
    childParentData.offset =
        Offset(_resolvedPadding.left, _resolvedPadding.top);
    size = constraints.constrain(Size(
      _resolvedPadding.left + child.size.width + _resolvedPadding.right,
      _resolvedPadding.top + child.size.height + _resolvedPadding.bottom,
    ));
  }

  @override
  void debugPaintSize(PaintingContext context, Offset offset) {
    super.debugPaintSize(context, offset);
    assert(() {
      final Rect outerRect = offset & size;
      debugPaintPadding(context.canvas, outerRect,
          child != null ? _resolvedPadding.deflateRect(outerRect) : null);
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

abstract class RenderAligningShiftedBox extends RenderShiftedBox {
  RenderAligningShiftedBox({
    AlignmentGeometry alignment = Alignment.center,
    @required TextDirection textDirection,
    RenderBox child,
  })  : assert(alignment != null),
        _alignment = alignment,
        _textDirection = textDirection,
        super(child);

  @protected
  RenderAligningShiftedBox.mixin(
      AlignmentGeometry alignment, TextDirection textDirection, RenderBox child)
      : this(alignment: alignment, textDirection: textDirection, child: child);

  Alignment _resolvedAlignment;

  void _resolve() {
    if (_resolvedAlignment != null) return;
    _resolvedAlignment = alignment.resolve(textDirection);
  }

  void _markNeedResolution() {
    _resolvedAlignment = null;
    markNeedsLayout();
  }

  AlignmentGeometry get alignment => _alignment;
  AlignmentGeometry _alignment;

  set alignment(AlignmentGeometry value) {
    assert(value != null);
    if (_alignment == value) return;
    _alignment = value;
    _markNeedResolution();
  }

  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (_textDirection == value) return;
    _textDirection = value;
    _markNeedResolution();
  }

  @protected
  void alignChild() {
    _resolve();
    assert(child != null);
    assert(!child.debugNeedsLayout);
    assert(child.hasSize);
    assert(hasSize);
    assert(_resolvedAlignment != null);
    final BoxParentData childParentData = child.parentData;
    childParentData.offset = _resolvedAlignment.alongOffset(size - child.size);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(DiagnosticsProperty<AlignmentGeometry>('alignment', alignment));
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection,
        defaultValue: null));
  }
}

class RenderPositionedBox extends RenderAligningShiftedBox {
  RenderPositionedBox({
    RenderBox child,
    double widthFactor,
    double heightFactor,
    AlignmentGeometry alignment = Alignment.center,
    TextDirection textDirection,
  })  : assert(widthFactor == null || widthFactor >= 0.0),
        assert(heightFactor == null || heightFactor >= 0.0),
        _widthFactor = widthFactor,
        _heightFactor = heightFactor,
        super(child: child, alignment: alignment, textDirection: textDirection);

  double get widthFactor => _widthFactor;
  double _widthFactor;
  set widthFactor(double value) {
    assert(value == null || value >= 0.0);
    if (_widthFactor == value) return;
    _widthFactor = value;
    markNeedsLayout();
  }

  double get heightFactor => _heightFactor;
  double _heightFactor;
  set heightFactor(double value) {
    assert(value == null || value >= 0.0);
    if (_heightFactor == value) return;
    _heightFactor = value;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    final bool shrinkWrapWidth =
        _widthFactor != null || constraints.maxWidth == double.infinity;
    final bool shrinkWrapHeight =
        _heightFactor != null || constraints.maxHeight == double.infinity;

    if (child != null) {
      child.layout(constraints.loosen(), parentUsesSize: true);
      size = constraints.constrain(Size(
          shrinkWrapWidth
              ? child.size.width * (_widthFactor ?? 1.0)
              : double.infinity,
          shrinkWrapHeight
              ? child.size.height * (_heightFactor ?? 1.0)
              : double.infinity));
      alignChild();
    } else {
      size = constraints.constrain(Size(shrinkWrapWidth ? 0.0 : double.infinity,
          shrinkWrapHeight ? 0.0 : double.infinity));
    }
  }

  @override
  void debugPaintSize(PaintingContext context, Offset offset) {
    super.debugPaintSize(context, offset);
    assert(() {
      Paint paint;
      if (child != null && !child.size.isEmpty) {
        Path path;
        paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = const Color(0xFFFFFF00);
        path = Path();
        final BoxParentData childParentData = child.parentData;
        if (childParentData.offset.dy > 0.0) {
          final double headSize =
              math.min(childParentData.offset.dy * 0.2, 10.0);
          path
            ..moveTo(offset.dx + size.width / 2.0, offset.dy)
            ..relativeLineTo(0.0, childParentData.offset.dy - headSize)
            ..relativeLineTo(headSize, 0.0)
            ..relativeLineTo(-headSize, headSize)
            ..relativeLineTo(-headSize, -headSize)
            ..relativeLineTo(headSize, 0.0)
            ..moveTo(offset.dx + size.width / 2.0, offset.dy + size.height)
            ..relativeLineTo(0.0, -childParentData.offset.dy + headSize)
            ..relativeLineTo(headSize, 0.0)
            ..relativeLineTo(-headSize, -headSize)
            ..relativeLineTo(-headSize, headSize)
            ..relativeLineTo(headSize, 0.0);
          context.canvas.drawPath(path, paint);
        }
        if (childParentData.offset.dx > 0.0) {
          final double headSize =
              math.min(childParentData.offset.dx * 0.2, 10.0);
          path
            ..moveTo(offset.dx, offset.dy + size.height / 2.0)
            ..relativeLineTo(childParentData.offset.dx - headSize, 0.0)
            ..relativeLineTo(0.0, headSize)
            ..relativeLineTo(headSize, -headSize)
            ..relativeLineTo(-headSize, -headSize)
            ..relativeLineTo(0.0, headSize)
            ..moveTo(offset.dx + size.width, offset.dy + size.height / 2.0)
            ..relativeLineTo(-childParentData.offset.dx + headSize, 0.0)
            ..relativeLineTo(0.0, headSize)
            ..relativeLineTo(-headSize, -headSize)
            ..relativeLineTo(headSize, -headSize)
            ..relativeLineTo(0.0, headSize);
          context.canvas.drawPath(path, paint);
        }
      } else {
        paint = Paint()..color = const Color(0x90909090);
        context.canvas.drawRect(offset & size, paint);
      }
      return true;
    }());
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(DoubleProperty('widthFactor', _widthFactor, ifNull: 'expand'));
    properties
        .add(DoubleProperty('heightFactor', _heightFactor, ifNull: 'expand'));
  }
}

class RenderConstrainedOverflowBox extends RenderAligningShiftedBox {
  RenderConstrainedOverflowBox({
    RenderBox child,
    double minWidth,
    double maxWidth,
    double minHeight,
    double maxHeight,
    AlignmentGeometry alignment = Alignment.center,
    TextDirection textDirection,
  })  : _minWidth = minWidth,
        _maxWidth = maxWidth,
        _minHeight = minHeight,
        _maxHeight = maxHeight,
        super(child: child, alignment: alignment, textDirection: textDirection);

  double get minWidth => _minWidth;
  double _minWidth;
  set minWidth(double value) {
    if (_minWidth == value) return;
    _minWidth = value;
    markNeedsLayout();
  }

  double get maxWidth => _maxWidth;
  double _maxWidth;
  set maxWidth(double value) {
    if (_maxWidth == value) return;
    _maxWidth = value;
    markNeedsLayout();
  }

  double get minHeight => _minHeight;
  double _minHeight;
  set minHeight(double value) {
    if (_minHeight == value) return;
    _minHeight = value;
    markNeedsLayout();
  }

  double get maxHeight => _maxHeight;
  double _maxHeight;
  set maxHeight(double value) {
    if (_maxHeight == value) return;
    _maxHeight = value;
    markNeedsLayout();
  }

  BoxConstraints _getInnerConstraints(BoxConstraints constraints) {
    return BoxConstraints(
      minWidth: _minWidth ?? constraints.minWidth,
      maxWidth: _maxWidth ?? constraints.maxWidth,
      minHeight: _minHeight ?? constraints.minHeight,
      maxHeight: _maxHeight ?? constraints.maxHeight,
    );
  }

  @override
  bool get sizedByParent => true;

  @override
  void performResize() {
    size = constraints.biggest;
  }

  @override
  void performLayout() {
    if (child != null) {
      child.layout(_getInnerConstraints(constraints), parentUsesSize: true);
      alignChild();
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('minWidth', minWidth,
        ifNull: 'use parent minWidth constraint'));
    properties.add(DoubleProperty('maxWidth', maxWidth,
        ifNull: 'use parent maxWidth constraint'));
    properties.add(DoubleProperty('minHeight', minHeight,
        ifNull: 'use parent minHeight constraint'));
    properties.add(DoubleProperty('maxHeight', maxHeight,
        ifNull: 'use parent maxHeight constraint'));
  }
}

class RenderUnconstrainedBox extends RenderAligningShiftedBox
    with DebugOverflowIndicatorMixin {
  RenderUnconstrainedBox({
    @required AlignmentGeometry alignment,
    @required TextDirection textDirection,
    Axis constrainedAxis,
    RenderBox child,
  })  : assert(alignment != null),
        _constrainedAxis = constrainedAxis,
        super.mixin(alignment, textDirection, child);

  Axis get constrainedAxis => _constrainedAxis;
  Axis _constrainedAxis;
  set constrainedAxis(Axis value) {
    if (_constrainedAxis == value) return;
    _constrainedAxis = value;
    markNeedsLayout();
  }

  Rect _overflowContainerRect = Rect.zero;
  Rect _overflowChildRect = Rect.zero;
  bool _isOverflowing = false;

  @override
  void performLayout() {
    if (child != null) {
      BoxConstraints childConstraints;
      if (constrainedAxis != null) {
        switch (constrainedAxis) {
          case Axis.horizontal:
            childConstraints = BoxConstraints(
                maxWidth: constraints.maxWidth, minWidth: constraints.minWidth);
            break;
          case Axis.vertical:
            childConstraints = BoxConstraints(
                maxHeight: constraints.maxHeight,
                minHeight: constraints.minHeight);
            break;
        }
      } else {
        childConstraints = const BoxConstraints();
      }
      child.layout(childConstraints, parentUsesSize: true);
      size = constraints.constrain(child.size);
      alignChild();
      final BoxParentData childParentData = child.parentData;
      _overflowContainerRect = Offset.zero & size;
      _overflowChildRect = childParentData.offset & child.size;
    } else {
      size = constraints.smallest;
      _overflowContainerRect = Rect.zero;
      _overflowChildRect = Rect.zero;
    }
    _isOverflowing =
        RelativeRect.fromRect(_overflowContainerRect, _overflowChildRect)
            .hasInsets;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null || size.isEmpty) return;

    if (!_isOverflowing) {
      super.paint(context, offset);
      return;
    }

    context.pushClipRect(
        needsCompositing, offset, Offset.zero & size, super.paint);

    assert(() {
      paintOverflowIndicator(
          context, offset, _overflowContainerRect, _overflowChildRect);
      return true;
    }());
  }

  @override
  Rect describeApproximatePaintClip(RenderObject child) {
    return _isOverflowing ? Offset.zero & size : null;
  }

  @override
  String toStringShort() {
    String header = super.toStringShort();
    if (_isOverflowing) header += ' OVERFLOWING';
    return header;
  }
}

class RenderSizedOverflowBox extends RenderAligningShiftedBox {
  RenderSizedOverflowBox({
    RenderBox child,
    @required Size requestedSize,
    AlignmentGeometry alignment = Alignment.center,
    TextDirection textDirection,
  })  : assert(requestedSize != null),
        _requestedSize = requestedSize,
        super(child: child, alignment: alignment, textDirection: textDirection);

  Size get requestedSize => _requestedSize;
  Size _requestedSize;
  set requestedSize(Size value) {
    assert(value != null);
    if (_requestedSize == value) return;
    _requestedSize = value;
    markNeedsLayout();
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    return _requestedSize.width;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return _requestedSize.width;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return _requestedSize.height;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return _requestedSize.height;
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    if (child != null) return child.getDistanceToActualBaseline(baseline);
    return super.computeDistanceToActualBaseline(baseline);
  }

  @override
  void performLayout() {
    size = constraints.constrain(_requestedSize);
    if (child != null) {
      child.layout(constraints, parentUsesSize: true);
      alignChild();
    }
  }
}

class RenderFractionallySizedOverflowBox extends RenderAligningShiftedBox {
  RenderFractionallySizedOverflowBox({
    RenderBox child,
    double widthFactor,
    double heightFactor,
    AlignmentGeometry alignment = Alignment.center,
    TextDirection textDirection,
  })  : _widthFactor = widthFactor,
        _heightFactor = heightFactor,
        super(
            child: child, alignment: alignment, textDirection: textDirection) {
    assert(_widthFactor == null || _widthFactor >= 0.0);
    assert(_heightFactor == null || _heightFactor >= 0.0);
  }

  double get widthFactor => _widthFactor;
  double _widthFactor;
  set widthFactor(double value) {
    assert(value == null || value >= 0.0);
    if (_widthFactor == value) return;
    _widthFactor = value;
    markNeedsLayout();
  }

  double get heightFactor => _heightFactor;
  double _heightFactor;
  set heightFactor(double value) {
    assert(value == null || value >= 0.0);
    if (_heightFactor == value) return;
    _heightFactor = value;
    markNeedsLayout();
  }

  BoxConstraints _getInnerConstraints(BoxConstraints constraints) {
    double minWidth = constraints.minWidth;
    double maxWidth = constraints.maxWidth;
    if (_widthFactor != null) {
      final double width = maxWidth * _widthFactor;
      minWidth = width;
      maxWidth = width;
    }
    double minHeight = constraints.minHeight;
    double maxHeight = constraints.maxHeight;
    if (_heightFactor != null) {
      final double height = maxHeight * _heightFactor;
      minHeight = height;
      maxHeight = height;
    }
    return BoxConstraints(
      minWidth: minWidth,
      maxWidth: maxWidth,
      minHeight: minHeight,
      maxHeight: maxHeight,
    );
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    double result;
    if (child == null) {
      result = super.computeMinIntrinsicWidth(height);
    } else {
      result = child.getMinIntrinsicWidth(height * (_heightFactor ?? 1.0));
    }
    assert(result.isFinite);
    return result / (_widthFactor ?? 1.0);
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    double result;
    if (child == null) {
      result = super.computeMaxIntrinsicWidth(height);
    } else {
      result = child.getMaxIntrinsicWidth(height * (_heightFactor ?? 1.0));
    }
    assert(result.isFinite);
    return result / (_widthFactor ?? 1.0);
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    double result;
    if (child == null) {
      result = super.computeMinIntrinsicHeight(width);
    } else {
      result = child.getMinIntrinsicHeight(width * (_widthFactor ?? 1.0));
    }
    assert(result.isFinite);
    return result / (_heightFactor ?? 1.0);
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    double result;
    if (child == null) {
      result = super.computeMaxIntrinsicHeight(width);
    } else {
      result = child.getMaxIntrinsicHeight(width * (_widthFactor ?? 1.0));
    }
    assert(result.isFinite);
    return result / (_heightFactor ?? 1.0);
  }

  @override
  void performLayout() {
    if (child != null) {
      child.layout(_getInnerConstraints(constraints), parentUsesSize: true);
      size = constraints.constrain(child.size);
      alignChild();
    } else {
      size = constraints
          .constrain(_getInnerConstraints(constraints).constrain(Size.zero));
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
        DoubleProperty('widthFactor', _widthFactor, ifNull: 'pass-through'));
    properties.add(
        DoubleProperty('heightFactor', _heightFactor, ifNull: 'pass-through'));
  }
}

abstract class SingleChildLayoutDelegate {
  const SingleChildLayoutDelegate({Listenable relayout}) : _relayout = relayout;

  final Listenable _relayout;

  Size getSize(BoxConstraints constraints) => constraints.biggest;

  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints;

  Offset getPositionForChild(Size size, Size childSize) => Offset.zero;

  bool shouldRelayout(covariant SingleChildLayoutDelegate oldDelegate);
}

class RenderCustomSingleChildLayoutBox extends RenderShiftedBox {
  RenderCustomSingleChildLayoutBox({
    RenderBox child,
    @required SingleChildLayoutDelegate delegate,
  })  : assert(delegate != null),
        _delegate = delegate,
        super(child);

  SingleChildLayoutDelegate get delegate => _delegate;
  SingleChildLayoutDelegate _delegate;
  set delegate(SingleChildLayoutDelegate newDelegate) {
    assert(newDelegate != null);
    if (_delegate == newDelegate) return;
    final SingleChildLayoutDelegate oldDelegate = _delegate;
    if (newDelegate.runtimeType != oldDelegate.runtimeType ||
        newDelegate.shouldRelayout(oldDelegate)) markNeedsLayout();
    _delegate = newDelegate;
    if (attached) {
      oldDelegate?._relayout?.removeListener(markNeedsLayout);
      newDelegate?._relayout?.addListener(markNeedsLayout);
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _delegate?._relayout?.addListener(markNeedsLayout);
  }

  @override
  void detach() {
    _delegate?._relayout?.removeListener(markNeedsLayout);
    super.detach();
  }

  Size _getSize(BoxConstraints constraints) {
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
    if (child != null) {
      final BoxConstraints childConstraints =
          delegate.getConstraintsForChild(constraints);
      assert(childConstraints.debugAssertIsValid(isAppliedConstraint: true));
      child.layout(childConstraints, parentUsesSize: !childConstraints.isTight);
      final BoxParentData childParentData = child.parentData;
      childParentData.offset = delegate.getPositionForChild(size,
          childConstraints.isTight ? childConstraints.smallest : child.size);
    }
  }
}

class RenderBaseline extends RenderShiftedBox {
  RenderBaseline({
    RenderBox child,
    @required double baseline,
    @required TextBaseline baselineType,
  })  : assert(baseline != null),
        assert(baselineType != null),
        _baseline = baseline,
        _baselineType = baselineType,
        super(child);

  double get baseline => _baseline;
  double _baseline;
  set baseline(double value) {
    assert(value != null);
    if (_baseline == value) return;
    _baseline = value;
    markNeedsLayout();
  }

  TextBaseline get baselineType => _baselineType;
  TextBaseline _baselineType;
  set baselineType(TextBaseline value) {
    assert(value != null);
    if (_baselineType == value) return;
    _baselineType = value;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    if (child != null) {
      child.layout(constraints.loosen(), parentUsesSize: true);
      final double childBaseline = child.getDistanceToBaseline(baselineType);
      final double actualBaseline = baseline;
      final double top = actualBaseline - childBaseline;
      final BoxParentData childParentData = child.parentData;
      childParentData.offset = Offset(0.0, top);
      final Size childSize = child.size;
      size =
          constraints.constrain(Size(childSize.width, top + childSize.height));
    } else {
      performResize();
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('baseline', baseline));
    properties.add(EnumProperty<TextBaseline>('baselineType', baselineType));
  }
}

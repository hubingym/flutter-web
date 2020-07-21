import 'dart:math' as math;
import 'package:flutter_web/ui.dart' show lerpDouble, hashValues;

import 'package:flutter_web/foundation.dart';

import 'box.dart';
import 'object.dart';

@immutable
class RelativeRect {
  const RelativeRect.fromLTRB(this.left, this.top, this.right, this.bottom)
      : assert(left != null && top != null && right != null && bottom != null);

  factory RelativeRect.fromSize(Rect rect, Size container) {
    return RelativeRect.fromLTRB(rect.left, rect.top,
        container.width - rect.right, container.height - rect.bottom);
  }

  factory RelativeRect.fromRect(Rect rect, Rect container) {
    return RelativeRect.fromLTRB(
      rect.left - container.left,
      rect.top - container.top,
      container.right - rect.right,
      container.bottom - rect.bottom,
    );
  }

  static const RelativeRect fill = RelativeRect.fromLTRB(0.0, 0.0, 0.0, 0.0);

  final double left;

  final double top;

  final double right;

  final double bottom;

  bool get hasInsets => left > 0.0 || top > 0.0 || right > 0.0 || bottom > 0.0;

  RelativeRect shift(Offset offset) {
    return RelativeRect.fromLTRB(left + offset.dx, top + offset.dy,
        right - offset.dx, bottom - offset.dy);
  }

  RelativeRect inflate(double delta) {
    return RelativeRect.fromLTRB(
        left - delta, top - delta, right - delta, bottom - delta);
  }

  RelativeRect deflate(double delta) {
    return inflate(-delta);
  }

  RelativeRect intersect(RelativeRect other) {
    return RelativeRect.fromLTRB(
      math.max(left, other.left),
      math.max(top, other.top),
      math.max(right, other.right),
      math.max(bottom, other.bottom),
    );
  }

  Rect toRect(Rect container) {
    return Rect.fromLTRB(
        left, top, container.width - right, container.height - bottom);
  }

  Size toSize(Size container) {
    return Size(
        container.width - left - right, container.height - top - bottom);
  }

  static RelativeRect lerp(RelativeRect a, RelativeRect b, double t) {
    assert(t != null);
    if (a == null && b == null) return null;
    if (a == null)
      return RelativeRect.fromLTRB(
          b.left * t, b.top * t, b.right * t, b.bottom * t);
    if (b == null) {
      final double k = 1.0 - t;
      return RelativeRect.fromLTRB(
          b.left * k, b.top * k, b.right * k, b.bottom * k);
    }
    return RelativeRect.fromLTRB(
      lerpDouble(a.left, b.left, t),
      lerpDouble(a.top, b.top, t),
      lerpDouble(a.right, b.right, t),
      lerpDouble(a.bottom, b.bottom, t),
    );
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (other is! RelativeRect) return false;
    final RelativeRect typedOther = other;
    return left == typedOther.left &&
        top == typedOther.top &&
        right == typedOther.right &&
        bottom == typedOther.bottom;
  }

  @override
  int get hashCode => hashValues(left, top, right, bottom);

  @override
  String toString() =>
      'RelativeRect.fromLTRB(${left?.toStringAsFixed(1)}, ${top?.toStringAsFixed(1)}, ${right?.toStringAsFixed(1)}, ${bottom?.toStringAsFixed(1)})';
}

class StackParentData extends ContainerBoxParentData<RenderBox> {
  double top;

  double right;

  double bottom;

  double left;

  double width;

  double height;

  RelativeRect get rect => RelativeRect.fromLTRB(left, top, right, bottom);
  set rect(RelativeRect value) {
    top = value.top;
    right = value.right;
    bottom = value.bottom;
    left = value.left;
  }

  bool get isPositioned =>
      top != null ||
      right != null ||
      bottom != null ||
      left != null ||
      width != null ||
      height != null;

  @override
  String toString() {
    final List<String> values = <String>[];
    if (top != null) values.add('top=${debugFormatDouble(top)}');
    if (right != null) values.add('right=${debugFormatDouble(right)}');
    if (bottom != null) values.add('bottom=${debugFormatDouble(bottom)}');
    if (left != null) values.add('left=${debugFormatDouble(left)}');
    if (width != null) values.add('width=${debugFormatDouble(width)}');
    if (height != null) values.add('height=${debugFormatDouble(height)}');
    if (values.isEmpty) values.add('not positioned');
    values.add(super.toString());
    return values.join('; ');
  }
}

enum StackFit {
  loose,

  expand,

  passthrough,
}

enum Overflow {
  visible,

  clip,
}

class RenderStack extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, StackParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, StackParentData> {
  RenderStack({
    List<RenderBox> children,
    AlignmentGeometry alignment = AlignmentDirectional.topStart,
    TextDirection textDirection,
    StackFit fit = StackFit.loose,
    Overflow overflow = Overflow.clip,
  })  : assert(alignment != null),
        assert(fit != null),
        assert(overflow != null),
        _alignment = alignment,
        _textDirection = textDirection,
        _fit = fit,
        _overflow = overflow {
    addAll(children);
  }

  bool _hasVisualOverflow = false;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! StackParentData)
      child.parentData = StackParentData();
  }

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

  StackFit get fit => _fit;
  StackFit _fit;
  set fit(StackFit value) {
    assert(value != null);
    if (_fit != value) {
      _fit = value;
      markNeedsLayout();
    }
  }

  Overflow get overflow => _overflow;
  Overflow _overflow;
  set overflow(Overflow value) {
    assert(value != null);
    if (_overflow != value) {
      _overflow = value;
      markNeedsPaint();
    }
  }

  double _getIntrinsicDimension(double mainChildSizeGetter(RenderBox child)) {
    double extent = 0.0;
    RenderBox child = firstChild;
    while (child != null) {
      final StackParentData childParentData = child.parentData;
      if (!childParentData.isPositioned)
        extent = math.max(extent, mainChildSizeGetter(child));
      assert(child.parentData == childParentData);
      child = childParentData.nextSibling;
    }
    return extent;
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    return _getIntrinsicDimension(
        (RenderBox child) => child.getMinIntrinsicWidth(height));
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return _getIntrinsicDimension(
        (RenderBox child) => child.getMaxIntrinsicWidth(height));
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return _getIntrinsicDimension(
        (RenderBox child) => child.getMinIntrinsicHeight(width));
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return _getIntrinsicDimension(
        (RenderBox child) => child.getMaxIntrinsicHeight(width));
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    return defaultComputeDistanceToHighestActualBaseline(baseline);
  }

  @override
  void performLayout() {
    _resolve();
    assert(_resolvedAlignment != null);
    _hasVisualOverflow = false;
    bool hasNonPositionedChildren = false;
    if (childCount == 0) {
      size = constraints.biggest;
      assert(size.isFinite);
      return;
    }

    double width = constraints.minWidth;
    double height = constraints.minHeight;

    BoxConstraints nonPositionedConstraints;
    assert(fit != null);
    switch (fit) {
      case StackFit.loose:
        nonPositionedConstraints = constraints.loosen();
        break;
      case StackFit.expand:
        nonPositionedConstraints = BoxConstraints.tight(constraints.biggest);
        break;
      case StackFit.passthrough:
        nonPositionedConstraints = constraints;
        break;
    }
    assert(nonPositionedConstraints != null);

    RenderBox child = firstChild;
    while (child != null) {
      final StackParentData childParentData = child.parentData;

      if (!childParentData.isPositioned) {
        hasNonPositionedChildren = true;

        child.layout(nonPositionedConstraints, parentUsesSize: true);

        final Size childSize = child.size;
        width = math.max(width, childSize.width);
        height = math.max(height, childSize.height);
      }

      child = childParentData.nextSibling;
    }

    if (hasNonPositionedChildren) {
      size = Size(width, height);
      assert(size.width == constraints.constrainWidth(width));
      assert(size.height == constraints.constrainHeight(height));
    } else {
      size = constraints.biggest;
    }

    assert(size.isFinite);

    child = firstChild;
    while (child != null) {
      final StackParentData childParentData = child.parentData;

      if (!childParentData.isPositioned) {
        childParentData.offset =
            _resolvedAlignment.alongOffset(size - child.size);
      } else {
        BoxConstraints childConstraints = const BoxConstraints();

        if (childParentData.left != null && childParentData.right != null)
          childConstraints = childConstraints.tighten(
              width: size.width - childParentData.right - childParentData.left);
        else if (childParentData.width != null)
          childConstraints =
              childConstraints.tighten(width: childParentData.width);

        if (childParentData.top != null && childParentData.bottom != null)
          childConstraints = childConstraints.tighten(
              height:
                  size.height - childParentData.bottom - childParentData.top);
        else if (childParentData.height != null)
          childConstraints =
              childConstraints.tighten(height: childParentData.height);

        child.layout(childConstraints, parentUsesSize: true);

        double x;
        if (childParentData.left != null) {
          x = childParentData.left;
        } else if (childParentData.right != null) {
          x = size.width - childParentData.right - child.size.width;
        } else {
          x = _resolvedAlignment.alongOffset(size - child.size).dx;
        }

        if (x < 0.0 || x + child.size.width > size.width)
          _hasVisualOverflow = true;

        double y;
        if (childParentData.top != null) {
          y = childParentData.top;
        } else if (childParentData.bottom != null) {
          y = size.height - childParentData.bottom - child.size.height;
        } else {
          y = _resolvedAlignment.alongOffset(size - child.size).dy;
        }

        if (y < 0.0 || y + child.size.height > size.height)
          _hasVisualOverflow = true;

        childParentData.offset = Offset(x, y);
      }

      assert(child.parentData == childParentData);
      child = childParentData.nextSibling;
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  @protected
  void paintStack(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_overflow == Overflow.clip && _hasVisualOverflow) {
      context.pushClipRect(
          needsCompositing, offset, Offset.zero & size, paintStack);
    } else {
      paintStack(context, offset);
    }
  }

  @override
  Rect describeApproximatePaintClip(RenderObject child) =>
      _hasVisualOverflow ? Offset.zero & size : null;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(DiagnosticsProperty<AlignmentGeometry>('alignment', alignment));
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection));
    properties.add(EnumProperty<StackFit>('fit', fit));
    properties.add(EnumProperty<Overflow>('overflow', overflow));
  }
}

class RenderIndexedStack extends RenderStack {
  RenderIndexedStack({
    List<RenderBox> children,
    AlignmentGeometry alignment = AlignmentDirectional.topStart,
    TextDirection textDirection,
    int index = 0,
  })  : _index = index,
        super(
          children: children,
          alignment: alignment,
          textDirection: textDirection,
        );

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    if (index != null && firstChild != null) visitor(_childAtIndex());
  }

  int get index => _index;
  int _index;
  set index(int value) {
    if (_index != value) {
      _index = value;
      markNeedsLayout();
    }
  }

  RenderBox _childAtIndex() {
    assert(index != null);
    RenderBox child = firstChild;
    int i = 0;
    while (child != null && i < index) {
      final StackParentData childParentData = child.parentData;
      child = childParentData.nextSibling;
      i += 1;
    }
    assert(i == index);
    assert(child != null);
    return child;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {@required Offset position}) {
    if (firstChild == null || index == null) return false;
    assert(position != null);
    final RenderBox child = _childAtIndex();
    final StackParentData childParentData = child.parentData;
    return result.addWithPaintOffset(
      offset: childParentData.offset,
      position: position,
      hitTest: (BoxHitTestResult result, Offset transformed) {
        assert(transformed == position - childParentData.offset);
        return child.hitTest(result, position: transformed);
      },
    );
  }

  @override
  void paintStack(PaintingContext context, Offset offset) {
    if (firstChild == null || index == null) return;
    final RenderBox child = _childAtIndex();
    final StackParentData childParentData = child.parentData;
    context.paintChild(child, childParentData.offset + offset);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('index', index));
  }
}

import 'dart:math' as math;

import 'package:flutter_web/animation.dart';
import 'package:flutter_web/foundation.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4;

import 'box.dart';
import 'object.dart';
import 'viewport.dart';
import 'viewport_offset.dart';

typedef _ChildSizingFunction = double Function(RenderBox child);

abstract class ListWheelChildManager {
  int get childCount;

  bool childExistsAt(int index);

  void createChild(int index, {@required RenderBox after});

  void removeChild(RenderBox child);
}

class ListWheelParentData extends ContainerBoxParentData<RenderBox> {
  int index;
}

class RenderListWheelViewport extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, ListWheelParentData>
    implements RenderAbstractViewport {
  RenderListWheelViewport({
    @required this.childManager,
    @required ViewportOffset offset,
    double diameterRatio = defaultDiameterRatio,
    double perspective = defaultPerspective,
    double offAxisFraction = 0,
    bool useMagnifier = false,
    double magnification = 1,
    @required double itemExtent,
    double squeeze = 1,
    bool clipToSize = true,
    bool renderChildrenOutsideViewport = false,
    List<RenderBox> children,
  })  : assert(childManager != null),
        assert(offset != null),
        assert(diameterRatio != null),
        assert(diameterRatio > 0, diameterRatioZeroMessage),
        assert(perspective != null),
        assert(perspective > 0),
        assert(perspective <= 0.01, perspectiveTooHighMessage),
        assert(offAxisFraction != null),
        assert(useMagnifier != null),
        assert(magnification != null),
        assert(magnification > 0),
        assert(itemExtent != null),
        assert(squeeze != null),
        assert(squeeze > 0),
        assert(itemExtent > 0),
        assert(clipToSize != null),
        assert(renderChildrenOutsideViewport != null),
        assert(
          !renderChildrenOutsideViewport || !clipToSize,
          clipToSizeAndRenderChildrenOutsideViewportConflict,
        ),
        _offset = offset,
        _diameterRatio = diameterRatio,
        _perspective = perspective,
        _offAxisFraction = offAxisFraction,
        _useMagnifier = useMagnifier,
        _magnification = magnification,
        _itemExtent = itemExtent,
        _squeeze = squeeze,
        _clipToSize = clipToSize,
        _renderChildrenOutsideViewport = renderChildrenOutsideViewport {
    addAll(children);
  }

  static const double defaultDiameterRatio = 2.0;

  static const double defaultPerspective = 0.003;

  static const String diameterRatioZeroMessage =
      "You can't set a diameterRatio "
      'of 0 or of a negative number. It would imply a cylinder of 0 in diameter '
      'in which case nothing will be drawn.';

  static const String perspectiveTooHighMessage = 'A perspective too high will '
      'be clipped in the z-axis and therefore not renderable. Value must be '
      'between 0 and 0.01.';

  static const String clipToSizeAndRenderChildrenOutsideViewportConflict =
      'Cannot renderChildrenOutsideViewport and clipToSize since children '
      'rendered outside will be clipped anyway.';

  final ListWheelChildManager childManager;

  ViewportOffset get offset => _offset;
  ViewportOffset _offset;
  set offset(ViewportOffset value) {
    assert(value != null);
    if (value == _offset) return;
    if (attached) _offset.removeListener(_hasScrolled);
    _offset = value;
    if (attached) _offset.addListener(_hasScrolled);
    markNeedsLayout();
  }

  double get diameterRatio => _diameterRatio;
  double _diameterRatio;
  set diameterRatio(double value) {
    assert(value != null);
    assert(
      value > 0,
      diameterRatioZeroMessage,
    );
    if (value == _diameterRatio) return;
    _diameterRatio = value;
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  double get perspective => _perspective;
  double _perspective;
  set perspective(double value) {
    assert(value != null);
    assert(value > 0);
    assert(
      value <= 0.01,
      perspectiveTooHighMessage,
    );
    if (value == _perspective) return;
    _perspective = value;
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  double get offAxisFraction => _offAxisFraction;
  double _offAxisFraction = 0.0;
  set offAxisFraction(double value) {
    assert(value != null);
    if (value == _offAxisFraction) return;
    _offAxisFraction = value;
    markNeedsPaint();
  }

  bool get useMagnifier => _useMagnifier;
  bool _useMagnifier = false;
  set useMagnifier(bool value) {
    assert(value != null);
    if (value == _useMagnifier) return;
    _useMagnifier = value;
    markNeedsPaint();
  }

  double get magnification => _magnification;
  double _magnification = 1.0;
  set magnification(double value) {
    assert(value != null);
    assert(value > 0);
    if (value == _magnification) return;
    _magnification = value;
    markNeedsPaint();
  }

  double get itemExtent => _itemExtent;
  double _itemExtent;
  set itemExtent(double value) {
    assert(value != null);
    assert(value > 0);
    if (value == _itemExtent) return;
    _itemExtent = value;
    markNeedsLayout();
  }

  double get squeeze => _squeeze;
  double _squeeze;
  set squeeze(double value) {
    assert(value != null);
    assert(value > 0);
    if (value == _squeeze) return;
    _squeeze = value;
    markNeedsLayout();
    markNeedsSemanticsUpdate();
  }

  bool get clipToSize => _clipToSize;
  bool _clipToSize;
  set clipToSize(bool value) {
    assert(value != null);
    assert(
      !renderChildrenOutsideViewport || !clipToSize,
      clipToSizeAndRenderChildrenOutsideViewportConflict,
    );
    if (value == _clipToSize) return;
    _clipToSize = value;
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  bool get renderChildrenOutsideViewport => _renderChildrenOutsideViewport;
  bool _renderChildrenOutsideViewport;
  set renderChildrenOutsideViewport(bool value) {
    assert(value != null);
    assert(
      !renderChildrenOutsideViewport || !clipToSize,
      clipToSizeAndRenderChildrenOutsideViewportConflict,
    );
    if (value == _renderChildrenOutsideViewport) return;
    _renderChildrenOutsideViewport = value;
    markNeedsLayout();
    markNeedsSemanticsUpdate();
  }

  void _hasScrolled() {
    markNeedsLayout();
    markNeedsSemanticsUpdate();
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! ListWheelParentData)
      child.parentData = ListWheelParentData();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _offset.addListener(_hasScrolled);
  }

  @override
  void detach() {
    _offset.removeListener(_hasScrolled);
    super.detach();
  }

  @override
  bool get isRepaintBoundary => true;

  double get _viewportExtent {
    assert(hasSize);
    return size.height;
  }

  double get _minEstimatedScrollExtent {
    assert(hasSize);
    if (childManager.childCount == null) return double.negativeInfinity;
    return 0.0;
  }

  double get _maxEstimatedScrollExtent {
    assert(hasSize);
    if (childManager.childCount == null) return double.infinity;

    return math.max(0.0, (childManager.childCount - 1) * _itemExtent);
  }

  double get _topScrollMarginExtent {
    assert(hasSize);

    return -size.height / 2.0 + _itemExtent / 2.0;
  }

  double _getUntransformedPaintingCoordinateY(double layoutCoordinateY) {
    return layoutCoordinateY - _topScrollMarginExtent - offset.pixels;
  }

  double get _maxVisibleRadian {
    if (_diameterRatio < 1.0) return math.pi / 2.0;
    return math.asin(1.0 / _diameterRatio);
  }

  double _getIntrinsicCrossAxis(_ChildSizingFunction childSize) {
    double extent = 0.0;
    RenderBox child = firstChild;
    while (child != null) {
      extent = math.max(extent, childSize(child));
      child = childAfter(child);
    }
    return extent;
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    return _getIntrinsicCrossAxis(
        (RenderBox child) => child.getMinIntrinsicWidth(height));
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return _getIntrinsicCrossAxis(
        (RenderBox child) => child.getMaxIntrinsicWidth(height));
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    if (childManager.childCount == null) return 0.0;
    return childManager.childCount * _itemExtent;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    if (childManager.childCount == null) return 0.0;
    return childManager.childCount * _itemExtent;
  }

  @override
  bool get sizedByParent => true;

  @override
  void performResize() {
    size = constraints.biggest;
  }

  int indexOf(RenderBox child) {
    assert(child != null);
    final ListWheelParentData childParentData = child.parentData;
    assert(childParentData.index != null);
    return childParentData.index;
  }

  int scrollOffsetToIndex(double scrollOffset) =>
      (scrollOffset / itemExtent).floor();

  double indexToScrollOffset(int index) => index * itemExtent;

  void _createChild(int index, {RenderBox after}) {
    invokeLayoutCallback<BoxConstraints>((BoxConstraints constraints) {
      assert(constraints == this.constraints);
      childManager.createChild(index, after: after);
    });
  }

  void _destroyChild(RenderBox child) {
    invokeLayoutCallback<BoxConstraints>((BoxConstraints constraints) {
      assert(constraints == this.constraints);
      childManager.removeChild(child);
    });
  }

  void _layoutChild(RenderBox child, BoxConstraints constraints, int index) {
    child.layout(constraints, parentUsesSize: true);
    final ListWheelParentData childParentData = child.parentData;

    final double crossPosition = size.width / 2.0 - child.size.width / 2.0;
    childParentData.offset = Offset(crossPosition, indexToScrollOffset(index));
  }

  @override
  void performLayout() {
    final BoxConstraints childConstraints = constraints.copyWith(
      minHeight: _itemExtent,
      maxHeight: _itemExtent,
      minWidth: 0.0,
    );

    double visibleHeight = size.height * _squeeze;

    if (renderChildrenOutsideViewport) visibleHeight *= 2;

    final double firstVisibleOffset =
        offset.pixels + _itemExtent / 2 - visibleHeight / 2;
    final double lastVisibleOffset = firstVisibleOffset + visibleHeight;

    int targetFirstIndex = scrollOffsetToIndex(firstVisibleOffset);
    int targetLastIndex = scrollOffsetToIndex(lastVisibleOffset);

    if (targetLastIndex * _itemExtent == lastVisibleOffset) targetLastIndex--;

    while (!childManager.childExistsAt(targetFirstIndex) &&
        targetFirstIndex <= targetLastIndex) targetFirstIndex++;
    while (!childManager.childExistsAt(targetLastIndex) &&
        targetFirstIndex <= targetLastIndex) targetLastIndex--;

    if (targetFirstIndex > targetLastIndex) {
      while (firstChild != null) _destroyChild(firstChild);
      return;
    }

    if (childCount > 0 &&
        (indexOf(firstChild) > targetLastIndex ||
            indexOf(lastChild) < targetFirstIndex)) {
      while (firstChild != null) _destroyChild(firstChild);
    }

    if (childCount == 0) {
      _createChild(targetFirstIndex);
      _layoutChild(firstChild, childConstraints, targetFirstIndex);
    }

    int currentFirstIndex = indexOf(firstChild);
    int currentLastIndex = indexOf(lastChild);

    while (currentFirstIndex < targetFirstIndex) {
      _destroyChild(firstChild);
      currentFirstIndex++;
    }
    while (currentLastIndex > targetLastIndex) {
      _destroyChild(lastChild);
      currentLastIndex--;
    }

    RenderBox child = firstChild;
    while (child != null) {
      child.layout(childConstraints, parentUsesSize: true);
      child = childAfter(child);
    }

    while (currentFirstIndex > targetFirstIndex) {
      _createChild(currentFirstIndex - 1);
      _layoutChild(firstChild, childConstraints, --currentFirstIndex);
    }
    while (currentLastIndex < targetLastIndex) {
      _createChild(currentLastIndex + 1, after: lastChild);
      _layoutChild(lastChild, childConstraints, ++currentLastIndex);
    }

    offset.applyViewportDimension(_viewportExtent);

    final double minScrollExtent =
        childManager.childExistsAt(targetFirstIndex - 1)
            ? _minEstimatedScrollExtent
            : indexToScrollOffset(targetFirstIndex);
    final double maxScrollExtent =
        childManager.childExistsAt(targetLastIndex + 1)
            ? _maxEstimatedScrollExtent
            : indexToScrollOffset(targetLastIndex);
    offset.applyContentDimensions(minScrollExtent, maxScrollExtent);
  }

  bool _shouldClipAtCurrentOffset() {
    final double highestUntransformedPaintY =
        _getUntransformedPaintingCoordinateY(0.0);
    return highestUntransformedPaintY < 0.0 ||
        size.height <
            highestUntransformedPaintY +
                _maxEstimatedScrollExtent +
                _itemExtent;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (childCount > 0) {
      if (_clipToSize && _shouldClipAtCurrentOffset()) {
        context.pushClipRect(
          needsCompositing,
          offset,
          Offset.zero & size,
          _paintVisibleChildren,
        );
      } else {
        _paintVisibleChildren(context, offset);
      }
    }
  }

  void _paintVisibleChildren(PaintingContext context, Offset offset) {
    RenderBox childToPaint = firstChild;
    ListWheelParentData childParentData = childToPaint?.parentData;

    while (childParentData != null) {
      _paintTransformedChild(
          childToPaint, context, offset, childParentData.offset);
      childToPaint = childAfter(childToPaint);
      childParentData = childToPaint?.parentData;
    }
  }

  void _paintTransformedChild(
    RenderBox child,
    PaintingContext context,
    Offset offset,
    Offset layoutOffset,
  ) {
    final Offset untransformedPaintingCoordinates = offset +
        Offset(
          layoutOffset.dx,
          _getUntransformedPaintingCoordinateY(layoutOffset.dy),
        );

    final double fractionalY =
        (untransformedPaintingCoordinates.dy + _itemExtent / 2.0) / size.height;
    final double angle =
        -(fractionalY - 0.5) * 2.0 * _maxVisibleRadian / squeeze;

    if (angle > math.pi / 2.0 || angle < -math.pi / 2.0) return;

    final Matrix4 transform = MatrixUtils.createCylindricalProjectionTransform(
      radius: size.height * _diameterRatio / 2.0,
      angle: angle,
      perspective: _perspective,
    );

    final Offset offsetToCenter =
        Offset(untransformedPaintingCoordinates.dx, -_topScrollMarginExtent);

    if (!useMagnifier)
      _paintChildCylindrically(
          context, offset, child, transform, offsetToCenter);
    else
      _paintChildWithMagnifier(
        context,
        offset,
        child,
        transform,
        offsetToCenter,
        untransformedPaintingCoordinates,
      );
  }

  void _paintChildWithMagnifier(
    PaintingContext context,
    Offset offset,
    RenderBox child,
    Matrix4 cylindricalTransform,
    Offset offsetToCenter,
    Offset untransformedPaintingCoordinates,
  ) {
    final double magnifierTopLinePosition =
        size.height / 2 - _itemExtent * _magnification / 2;
    final double magnifierBottomLinePosition =
        size.height / 2 + _itemExtent * _magnification / 2;

    final bool isAfterMagnifierTopLine = untransformedPaintingCoordinates.dy >=
        magnifierTopLinePosition - _itemExtent * _magnification;
    final bool isBeforeMagnifierBottomLine =
        untransformedPaintingCoordinates.dy <= magnifierBottomLinePosition;

    if (isAfterMagnifierTopLine && isBeforeMagnifierBottomLine) {
      final Rect centerRect = Rect.fromLTWH(0.0, magnifierTopLinePosition,
          size.width, _itemExtent * _magnification);
      final Rect topHalfRect =
          Rect.fromLTWH(0.0, 0.0, size.width, magnifierTopLinePosition);
      final Rect bottomHalfRect = Rect.fromLTWH(0.0,
          magnifierBottomLinePosition, size.width, magnifierTopLinePosition);

      context.pushClipRect(false, offset, centerRect,
          (PaintingContext context, Offset offset) {
        context.pushTransform(false, offset, _magnifyTransform(),
            (PaintingContext context, Offset offset) {
          context.paintChild(child, offset + untransformedPaintingCoordinates);
        });
      });

      context.pushClipRect(
        false,
        offset,
        untransformedPaintingCoordinates.dy <= magnifierTopLinePosition
            ? topHalfRect
            : bottomHalfRect,
        (PaintingContext context, Offset offset) {
          _paintChildCylindrically(
              context, offset, child, cylindricalTransform, offsetToCenter);
        },
      );
    } else {
      _paintChildCylindrically(
          context, offset, child, cylindricalTransform, offsetToCenter);
    }
  }

  void _paintChildCylindrically(
    PaintingContext context,
    Offset offset,
    RenderBox child,
    Matrix4 cylindricalTransform,
    Offset offsetToCenter,
  ) {
    context.pushTransform(
      false,
      offset,
      _centerOriginTransform(cylindricalTransform),
      (PaintingContext context, Offset offset) {
        context.paintChild(
          child,
          offset + offsetToCenter,
        );
      },
    );
  }

  Matrix4 _magnifyTransform() {
    final Matrix4 magnify = Matrix4.identity();
    magnify.translate(size.width * (-_offAxisFraction + 0.5), size.height / 2);
    magnify.scale(_magnification, _magnification, _magnification);
    magnify.translate(
        -size.width * (-_offAxisFraction + 0.5), -size.height / 2);
    return magnify;
  }

  Matrix4 _centerOriginTransform(Matrix4 originalMatrix) {
    final Matrix4 result = Matrix4.identity();
    final Offset centerOriginTranslation = Alignment.center.alongSize(size);
    result.translate(centerOriginTranslation.dx * (-_offAxisFraction * 2 + 1),
        centerOriginTranslation.dy);
    result.multiply(originalMatrix);
    result.translate(-centerOriginTranslation.dx * (-_offAxisFraction * 2 + 1),
        -centerOriginTranslation.dy);
    return result;
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final ListWheelParentData parentData = child?.parentData;
    transform.translate(
        0.0, _getUntransformedPaintingCoordinateY(parentData.offset.dy));
  }

  @override
  Rect describeApproximatePaintClip(RenderObject child) {
    if (child != null && _shouldClipAtCurrentOffset()) {
      return Offset.zero & size;
    }
    return null;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {Offset position}) {
    return false;
  }

  @override
  RevealedOffset getOffsetToReveal(RenderObject target, double alignment,
      {Rect rect}) {
    rect ??= target.paintBounds;

    RenderObject child = target;
    while (child.parent != this) child = child.parent;

    final ListWheelParentData parentData = child.parentData;
    final double targetOffset = parentData.offset.dy;

    final Matrix4 transform = target.getTransformTo(this);
    final Rect bounds = MatrixUtils.transformRect(transform, rect);
    final Rect targetRect =
        bounds.translate(0.0, (size.height - itemExtent) / 2);

    return RevealedOffset(offset: targetOffset, rect: targetRect);
  }

  @override
  void showOnScreen({
    RenderObject descendant,
    Rect rect,
    Duration duration = Duration.zero,
    Curve curve = Curves.ease,
  }) {
    if (descendant != null) {
      final RevealedOffset revealedOffset =
          getOffsetToReveal(descendant, 0.5, rect: rect);
      if (duration == Duration.zero) {
        offset.jumpTo(revealedOffset.offset);
      } else {
        offset.animateTo(revealedOffset.offset,
            duration: duration, curve: curve);
      }
      rect = revealedOffset.rect;
    }

    super.showOnScreen(
      rect: rect,
      duration: duration,
      curve: curve,
    );
  }
}

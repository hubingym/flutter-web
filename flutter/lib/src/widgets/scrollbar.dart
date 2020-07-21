import 'dart:math' as math;

import 'package:flutter_web/animation.dart';
import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/rendering.dart';

import 'scroll_metrics.dart';

const double _kMinThumbExtent = 18.0;
const double _kMinInteractiveSize = 48.0;

class ScrollbarPainter extends ChangeNotifier implements CustomPainter {
  ScrollbarPainter({
    @required this.color,
    @required this.textDirection,
    @required this.thickness,
    @required this.fadeoutOpacityAnimation,
    this.padding = EdgeInsets.zero,
    this.mainAxisMargin = 0.0,
    this.crossAxisMargin = 0.0,
    this.radius,
    this.minLength = _kMinThumbExtent,
    double minOverscrollLength,
  })  : assert(color != null),
        assert(textDirection != null),
        assert(thickness != null),
        assert(fadeoutOpacityAnimation != null),
        assert(mainAxisMargin != null),
        assert(crossAxisMargin != null),
        assert(minLength != null),
        assert(minLength >= 0),
        assert(minOverscrollLength == null || minOverscrollLength <= minLength),
        assert(minOverscrollLength == null || minOverscrollLength >= 0),
        assert(padding != null),
        assert(padding.isNonNegative),
        minOverscrollLength = minOverscrollLength ?? minLength {
    fadeoutOpacityAnimation.addListener(notifyListeners);
  }

  final Color color;

  final TextDirection textDirection;

  double thickness;

  final Animation<double> fadeoutOpacityAnimation;

  final double mainAxisMargin;

  final double crossAxisMargin;

  Radius radius;

  final EdgeInsets padding;

  final double minLength;

  final double minOverscrollLength;

  ScrollMetrics _lastMetrics;
  AxisDirection _lastAxisDirection;
  Rect _thumbRect;

  void update(
    ScrollMetrics metrics,
    AxisDirection axisDirection,
  ) {
    _lastMetrics = metrics;
    _lastAxisDirection = axisDirection;
    notifyListeners();
  }

  void updateThickness(double nextThickness, Radius nextRadius) {
    thickness = nextThickness;
    radius = nextRadius;
    notifyListeners();
  }

  Paint get _paint {
    return Paint()
      ..color =
          color.withOpacity(color.opacity * fadeoutOpacityAnimation.value);
  }

  void _paintThumbCrossAxis(Canvas canvas, Size size, double thumbOffset,
      double thumbExtent, AxisDirection direction) {
    double x, y;
    Size thumbSize;

    switch (direction) {
      case AxisDirection.down:
        thumbSize = Size(thickness, thumbExtent);
        x = textDirection == TextDirection.rtl
            ? crossAxisMargin + padding.left
            : size.width - thickness - crossAxisMargin - padding.right;
        y = thumbOffset;
        break;
      case AxisDirection.up:
        thumbSize = Size(thickness, thumbExtent);
        x = textDirection == TextDirection.rtl
            ? crossAxisMargin + padding.left
            : size.width - thickness - crossAxisMargin - padding.right;
        y = thumbOffset;
        break;
      case AxisDirection.left:
        thumbSize = Size(thumbExtent, thickness);
        x = thumbOffset;
        y = size.height - thickness - crossAxisMargin - padding.bottom;
        break;
      case AxisDirection.right:
        thumbSize = Size(thumbExtent, thickness);
        x = thumbOffset;
        y = size.height - thickness - crossAxisMargin - padding.bottom;
        break;
    }

    _thumbRect = Offset(x, y) & thumbSize;
    if (radius == null)
      canvas.drawRect(_thumbRect, _paint);
    else
      canvas.drawRRect(RRect.fromRectAndRadius(_thumbRect, radius), _paint);
  }

  double _thumbExtent() {
    final double fractionVisible =
        ((_lastMetrics.extentInside - _mainAxisPadding) /
                (_totalContentExtent - _mainAxisPadding))
            .clamp(0.0, 1.0);

    final double thumbExtent = math.max(
        math.min(_trackExtent, minOverscrollLength),
        _trackExtent * fractionVisible);

    final double fractionOverscrolled =
        1.0 - _lastMetrics.extentInside / _lastMetrics.viewportDimension;
    final double safeMinLength = math.min(minLength, _trackExtent);
    final double newMinLength = (_beforeExtent > 0 && _afterExtent > 0)
        ? safeMinLength
        : safeMinLength * (1.0 - fractionOverscrolled.clamp(0.0, 0.2) / 0.2);

    return thumbExtent.clamp(newMinLength, _trackExtent);
  }

  @override
  void dispose() {
    fadeoutOpacityAnimation.removeListener(notifyListeners);
    super.dispose();
  }

  bool get _isVertical =>
      _lastAxisDirection == AxisDirection.down ||
      _lastAxisDirection == AxisDirection.up;
  bool get _isReversed =>
      _lastAxisDirection == AxisDirection.up ||
      _lastAxisDirection == AxisDirection.left;

  double get _beforeExtent =>
      _isReversed ? _lastMetrics.extentAfter : _lastMetrics.extentBefore;
  double get _afterExtent =>
      _isReversed ? _lastMetrics.extentBefore : _lastMetrics.extentAfter;

  double get _mainAxisPadding =>
      _isVertical ? padding.vertical : padding.horizontal;

  double get _trackExtent =>
      _lastMetrics.viewportDimension - 2 * mainAxisMargin - _mainAxisPadding;

  double get _totalContentExtent {
    return _lastMetrics.maxScrollExtent -
        _lastMetrics.minScrollExtent +
        _lastMetrics.viewportDimension;
  }

  double getTrackToScroll(double thumbOffsetLocal) {
    assert(thumbOffsetLocal != null);
    final double scrollableExtent =
        _lastMetrics.maxScrollExtent - _lastMetrics.minScrollExtent;
    final double thumbMovableExtent = _trackExtent - _thumbExtent();

    return scrollableExtent * thumbOffsetLocal / thumbMovableExtent;
  }

  double _getScrollToTrack(ScrollMetrics metrics, double thumbExtent) {
    final double scrollableExtent =
        metrics.maxScrollExtent - metrics.minScrollExtent;

    final double fractionPast = (scrollableExtent > 0)
        ? ((metrics.pixels - metrics.minScrollExtent) / scrollableExtent)
            .clamp(0.0, 1.0)
        : 0;

    return (_isReversed ? 1 - fractionPast : fractionPast) *
        (_trackExtent - thumbExtent);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (_lastAxisDirection == null ||
        _lastMetrics == null ||
        fadeoutOpacityAnimation.value == 0.0) return;

    if (_lastMetrics.viewportDimension <= _mainAxisPadding ||
        _trackExtent <= 0) {
      return;
    }

    final double beforePadding = _isVertical ? padding.top : padding.left;
    final double thumbExtent = _thumbExtent();
    final double thumbOffsetLocal =
        _getScrollToTrack(_lastMetrics, thumbExtent);
    final double thumbOffset =
        thumbOffsetLocal + mainAxisMargin + beforePadding;

    return _paintThumbCrossAxis(
        canvas, size, thumbOffset, thumbExtent, _lastAxisDirection);
  }

  bool hitTestInteractive(Offset position) {
    if (_thumbRect == null) {
      return false;
    }

    if (fadeoutOpacityAnimation.value == 0.0) {
      return false;
    }
    final Rect interactiveThumbRect = _thumbRect.expandToInclude(
      Rect.fromCircle(
          center: _thumbRect.center, radius: _kMinInteractiveSize / 2),
    );
    return interactiveThumbRect.contains(position);
  }

  @override
  bool hitTest(Offset position) {
    if (_thumbRect == null) {
      return null;
    }

    if (fadeoutOpacityAnimation.value == 0.0) {
      return false;
    }
    return _thumbRect.contains(position);
  }

  @override
  bool shouldRepaint(ScrollbarPainter old) {
    return color != old.color ||
        textDirection != old.textDirection ||
        thickness != old.thickness ||
        fadeoutOpacityAnimation != old.fadeoutOpacityAnimation ||
        mainAxisMargin != old.mainAxisMargin ||
        crossAxisMargin != old.crossAxisMargin ||
        radius != old.radius ||
        minLength != old.minLength ||
        padding != old.padding;
  }

  @override
  bool shouldRebuildSemantics(CustomPainter oldDelegate) => false;

  @override
  SemanticsBuilderCallback get semanticsBuilder => null;
}

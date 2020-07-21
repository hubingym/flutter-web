import 'package:flutter_web/animation.dart';
import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/scheduler.dart';

import 'box.dart';
import 'object.dart';
import 'shifted_box.dart';

@visibleForTesting
enum RenderAnimatedSizeState {
  start,

  stable,

  changed,

  unstable,
}

class RenderAnimatedSize extends RenderAligningShiftedBox {
  RenderAnimatedSize({
    @required TickerProvider vsync,
    @required Duration duration,
    Duration reverseDuration,
    Curve curve = Curves.linear,
    AlignmentGeometry alignment = Alignment.center,
    TextDirection textDirection,
    RenderBox child,
  })  : assert(vsync != null),
        assert(duration != null),
        assert(curve != null),
        _vsync = vsync,
        super(
            child: child, alignment: alignment, textDirection: textDirection) {
    _controller = AnimationController(
      vsync: vsync,
      duration: duration,
      reverseDuration: reverseDuration,
    )..addListener(() {
        if (_controller.value != _lastValue) markNeedsLayout();
      });
    _animation = CurvedAnimation(
      parent: _controller,
      curve: curve,
    );
  }

  AnimationController _controller;
  CurvedAnimation _animation;
  final SizeTween _sizeTween = SizeTween();
  bool _hasVisualOverflow;
  double _lastValue;

  @visibleForTesting
  RenderAnimatedSizeState get state => _state;
  RenderAnimatedSizeState _state = RenderAnimatedSizeState.start;

  Duration get duration => _controller.duration;
  set duration(Duration value) {
    assert(value != null);
    if (value == _controller.duration) return;
    _controller.duration = value;
  }

  Duration get reverseDuration => _controller.reverseDuration;
  set reverseDuration(Duration value) {
    if (value == _controller.reverseDuration) return;
    _controller.reverseDuration = value;
  }

  Curve get curve => _animation.curve;
  set curve(Curve value) {
    assert(value != null);
    if (value == _animation.curve) return;
    _animation.curve = value;
  }

  bool get isAnimating => _controller.isAnimating;

  TickerProvider get vsync => _vsync;
  TickerProvider _vsync;
  set vsync(TickerProvider value) {
    assert(value != null);
    if (value == _vsync) return;
    _vsync = value;
    _controller.resync(vsync);
  }

  @override
  void detach() {
    _controller.stop();
    super.detach();
  }

  Size get _animatedSize {
    return _sizeTween.evaluate(_animation);
  }

  @override
  void performLayout() {
    _lastValue = _controller.value;
    _hasVisualOverflow = false;

    if (child == null || constraints.isTight) {
      _controller.stop();
      size = _sizeTween.begin = _sizeTween.end = constraints.smallest;
      _state = RenderAnimatedSizeState.start;
      child?.layout(constraints);
      return;
    }

    child.layout(constraints, parentUsesSize: true);

    assert(_state != null);
    switch (_state) {
      case RenderAnimatedSizeState.start:
        _layoutStart();
        break;
      case RenderAnimatedSizeState.stable:
        _layoutStable();
        break;
      case RenderAnimatedSizeState.changed:
        _layoutChanged();
        break;
      case RenderAnimatedSizeState.unstable:
        _layoutUnstable();
        break;
    }

    size = constraints.constrain(_animatedSize);
    alignChild();

    if (size.width < _sizeTween.end.width ||
        size.height < _sizeTween.end.height) _hasVisualOverflow = true;
  }

  void _restartAnimation() {
    _lastValue = 0.0;
    _controller.forward(from: 0.0);
  }

  void _layoutStart() {
    _sizeTween.begin = _sizeTween.end = debugAdoptSize(child.size);
    _state = RenderAnimatedSizeState.stable;
  }

  void _layoutStable() {
    if (_sizeTween.end != child.size) {
      _sizeTween.begin = size;
      _sizeTween.end = debugAdoptSize(child.size);
      _restartAnimation();
      _state = RenderAnimatedSizeState.changed;
    } else if (_controller.value == _controller.upperBound) {
      _sizeTween.begin = _sizeTween.end = debugAdoptSize(child.size);
    } else if (!_controller.isAnimating) {
      _controller.forward();
    }
  }

  void _layoutChanged() {
    if (_sizeTween.end != child.size) {
      _sizeTween.begin = _sizeTween.end = debugAdoptSize(child.size);
      _restartAnimation();
      _state = RenderAnimatedSizeState.unstable;
    } else {
      _state = RenderAnimatedSizeState.stable;
      if (!_controller.isAnimating) _controller.forward();
    }
  }

  void _layoutUnstable() {
    if (_sizeTween.end != child.size) {
      _sizeTween.begin = _sizeTween.end = debugAdoptSize(child.size);
      _restartAnimation();
    } else {
      _controller.stop();
      _state = RenderAnimatedSizeState.stable;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null && _hasVisualOverflow) {
      final Rect rect = Offset.zero & size;
      context.pushClipRect(needsCompositing, offset, rect, super.paint);
    } else {
      super.paint(context, offset);
    }
  }
}

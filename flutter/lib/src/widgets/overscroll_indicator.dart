import 'dart:async' show Timer;
import 'dart:math' as math;

import 'package:flutter_web/animation.dart';
import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/physics.dart';
import 'package:flutter_web/rendering.dart';
import 'package:flutter_web/scheduler.dart';

import 'basic.dart';
import 'framework.dart';
import 'notification_listener.dart';
import 'scroll_notification.dart';
import 'ticker_provider.dart';

class GlowingOverscrollIndicator extends StatefulWidget {
  const GlowingOverscrollIndicator({
    Key key,
    this.showLeading = true,
    this.showTrailing = true,
    @required this.axisDirection,
    @required this.color,
    this.notificationPredicate = defaultScrollNotificationPredicate,
    this.child,
  })  : assert(showLeading != null),
        assert(showTrailing != null),
        assert(axisDirection != null),
        assert(color != null),
        assert(notificationPredicate != null),
        super(key: key);

  final bool showLeading;

  final bool showTrailing;

  final AxisDirection axisDirection;

  Axis get axis => axisDirectionToAxis(axisDirection);

  final Color color;

  final ScrollNotificationPredicate notificationPredicate;

  final Widget child;

  @override
  _GlowingOverscrollIndicatorState createState() =>
      new _GlowingOverscrollIndicatorState();
}

class _GlowingOverscrollIndicatorState extends State<GlowingOverscrollIndicator>
    with TickerProviderStateMixin {
  _GlowController _leadingController;
  _GlowController _trailingController;
  Listenable _leadingAndTrailingListener;

  @override
  void initState() {
    super.initState();
    _leadingController = new _GlowController(
        vsync: this, color: widget.color, axis: widget.axis);
    _trailingController = new _GlowController(
        vsync: this, color: widget.color, axis: widget.axis);
    _leadingAndTrailingListener = new Listenable.merge(
        <Listenable>[_leadingController, _trailingController]);
  }

  @override
  void didUpdateWidget(GlowingOverscrollIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.color != widget.color || oldWidget.axis != widget.axis) {
      _leadingController.color = widget.color;
      _leadingController.axis = widget.axis;
      _trailingController.color = widget.color;
      _trailingController.axis = widget.axis;
    }
  }

  Type _lastNotificationType;
  final Map<bool, bool> _accepted = <bool, bool>{false: true, true: true};

  bool _handleScrollNotification(ScrollNotification notification) {
    if (!widget.notificationPredicate(notification)) return false;
    if (notification is OverscrollNotification) {
      _GlowController controller;
      if (notification.overscroll < 0.0) {
        controller = _leadingController;
      } else if (notification.overscroll > 0.0) {
        controller = _trailingController;
      } else {
        assert(false);
      }
      final bool isLeading = controller == _leadingController;
      if (_lastNotificationType != OverscrollNotification) {
        final OverscrollIndicatorNotification confirmationNotification =
            new OverscrollIndicatorNotification(leading: isLeading);
        confirmationNotification.dispatch(context);
        _accepted[isLeading] = confirmationNotification._accepted;
      }
      assert(controller != null);
      assert(notification.metrics.axis == widget.axis);
      if (_accepted[isLeading]) {
        if (notification.velocity != 0.0) {
          assert(notification.dragDetails == null);
          controller.absorbImpact(notification.velocity.abs());
        } else {
          assert(notification.overscroll != 0.0);
          if (notification.dragDetails != null) {
            assert(notification.dragDetails.globalPosition != null);
            final RenderBox renderer = notification.context.findRenderObject();
            assert(renderer != null);
            assert(renderer.hasSize);
            final Size size = renderer.size;
            final Offset position =
                renderer.globalToLocal(notification.dragDetails.globalPosition);
            switch (notification.metrics.axis) {
              case Axis.horizontal:
                controller.pull(notification.overscroll.abs(), size.width,
                    position.dy.clamp(0.0, size.height), size.height);
                break;
              case Axis.vertical:
                controller.pull(notification.overscroll.abs(), size.height,
                    position.dx.clamp(0.0, size.width), size.width);
                break;
            }
          }
        }
      }
    } else if (notification is ScrollEndNotification ||
        notification is ScrollUpdateNotification) {
      if ((notification as dynamic).dragDetails != null) {
        _leadingController.scrollEnd();
        _trailingController.scrollEnd();
      }
    }
    _lastNotificationType = notification.runtimeType;
    return false;
  }

  @override
  void dispose() {
    _leadingController.dispose();
    _trailingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return new NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: new RepaintBoundary(
        child: new CustomPaint(
          foregroundPainter: new _GlowingOverscrollIndicatorPainter(
            leadingController: widget.showLeading ? _leadingController : null,
            trailingController:
                widget.showTrailing ? _trailingController : null,
            axisDirection: widget.axisDirection,
            repaint: _leadingAndTrailingListener,
          ),
          child: new RepaintBoundary(
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

enum _GlowState { idle, absorb, pull, recede }

class _GlowController extends ChangeNotifier {
  _GlowController({
    @required TickerProvider vsync,
    @required Color color,
    @required Axis axis,
  })  : assert(vsync != null),
        assert(color != null),
        assert(axis != null),
        _color = color,
        _axis = axis {
    _glowController = new AnimationController(vsync: vsync)
      ..addStatusListener(_changePhase);
    final Animation<double> decelerator = new CurvedAnimation(
      parent: _glowController,
      curve: Curves.decelerate,
    )..addListener(notifyListeners);
    _glowOpacity = _glowOpacityTween.animate(decelerator);
    _glowSize = _glowSizeTween.animate(decelerator);
    _displacementTicker = vsync.createTicker(_tickDisplacement);
  }

  _GlowState _state = _GlowState.idle;
  AnimationController _glowController;
  Timer _pullRecedeTimer;

  final Tween<double> _glowOpacityTween =
      new Tween<double>(begin: 0.0, end: 0.0);
  Animation<double> _glowOpacity;
  final Tween<double> _glowSizeTween = new Tween<double>(begin: 0.0, end: 0.0);
  Animation<double> _glowSize;

  Ticker _displacementTicker;
  Duration _displacementTickerLastElapsed;
  double _displacementTarget = 0.5;
  double _displacement = 0.5;

  double _pullDistance = 0.0;

  Color get color => _color;
  Color _color;
  set color(Color value) {
    assert(color != null);
    if (color == value) return;
    _color = value;
    notifyListeners();
  }

  Axis get axis => _axis;
  Axis _axis;
  set axis(Axis value) {
    assert(axis != null);
    if (axis == value) return;
    _axis = value;
    notifyListeners();
  }

  static const Duration _recedeTime = const Duration(milliseconds: 600);
  static const Duration _pullTime = const Duration(milliseconds: 167);
  static const Duration _pullHoldTime = const Duration(milliseconds: 167);
  static const Duration _pullDecayTime = const Duration(milliseconds: 2000);
  static final Duration _crossAxisHalfTime = new Duration(
      microseconds: (Duration.microsecondsPerSecond / 60.0).round());

  static const double _maxOpacity = 0.5;
  static const double _pullOpacityGlowFactor = 0.8;
  static const double _velocityGlowFactor = 0.00006;
  static const double _sqrt3 = 1.73205080757;
  static const double _widthToHeightFactor = (3.0 / 4.0) * (2.0 - _sqrt3);

  static const double _minVelocity = 100.0;
  static const double _maxVelocity = 10000.0;

  @override
  void dispose() {
    _glowController.dispose();
    _displacementTicker.dispose();
    _pullRecedeTimer?.cancel();
    super.dispose();
  }

  void absorbImpact(double velocity) {
    assert(velocity >= 0.0);
    _pullRecedeTimer?.cancel();
    _pullRecedeTimer = null;
    velocity = velocity.clamp(_minVelocity, _maxVelocity);
    _glowOpacityTween.begin =
        _state == _GlowState.idle ? 0.3 : _glowOpacity.value;
    _glowOpacityTween.end = (velocity * _velocityGlowFactor)
        .clamp(_glowOpacityTween.begin, _maxOpacity);
    _glowSizeTween.begin = _glowSize.value;
    _glowSizeTween.end = math.min(0.025 + 7.5e-7 * velocity * velocity, 1.0);
    _glowController.duration =
        new Duration(milliseconds: (0.15 + velocity * 0.02).round());
    _glowController.forward(from: 0.0);
    _displacement = 0.5;
    _state = _GlowState.absorb;
  }

  void pull(double overscroll, double extent, double crossAxisOffset,
      double crossExtent) {
    _pullRecedeTimer?.cancel();

    _pullDistance += overscroll / 200.0;
    _glowOpacityTween.begin = _glowOpacity.value;
    _glowOpacityTween.end = math.min(
        _glowOpacity.value + overscroll / extent * _pullOpacityGlowFactor,
        _maxOpacity);
    final double height = math.min(extent, crossExtent * _widthToHeightFactor);
    _glowSizeTween.begin = _glowSize.value;
    _glowSizeTween.end = math.max(
        1.0 - 1.0 / (0.7 * math.sqrt(_pullDistance * height)), _glowSize.value);
    _displacementTarget = crossAxisOffset / crossExtent;
    if (_displacementTarget != _displacement) {
      if (!_displacementTicker.isTicking) {
        assert(_displacementTickerLastElapsed == null);
        _displacementTicker.start();
      }
    } else {
      _displacementTicker.stop();
      _displacementTickerLastElapsed = null;
    }
    _glowController.duration = _pullTime;
    if (_state != _GlowState.pull) {
      _glowController.forward(from: 0.0);
      _state = _GlowState.pull;
    } else {
      if (!_glowController.isAnimating) {
        assert(_glowController.value == 1.0);
        notifyListeners();
      }
    }
    _pullRecedeTimer = new Timer(_pullHoldTime, () => _recede(_pullDecayTime));
  }

  void scrollEnd() {
    if (_state == _GlowState.pull) {
      _recede(_recedeTime);
    }
  }

  void _changePhase(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    switch (_state) {
      case _GlowState.absorb:
        _recede(_recedeTime);
        break;
      case _GlowState.recede:
        _state = _GlowState.idle;
        _pullDistance = 0.0;
        break;
      case _GlowState.pull:
      case _GlowState.idle:
        break;
    }
  }

  void _recede(Duration duration) {
    if (_state == _GlowState.recede || _state == _GlowState.idle) {
      return;
    }
    _pullRecedeTimer?.cancel();
    _pullRecedeTimer = null;
    _glowOpacityTween.begin = _glowOpacity.value;
    _glowOpacityTween.end = 0.0;
    _glowSizeTween.begin = _glowSize.value;
    _glowSizeTween.end = 0.0;
    _glowController.duration = duration;
    _glowController.forward(from: 0.0);
    _state = _GlowState.recede;
  }

  void _tickDisplacement(Duration elapsed) {
    if (_displacementTickerLastElapsed != null) {
      final double t = (elapsed.inMicroseconds -
              _displacementTickerLastElapsed.inMicroseconds)
          .toDouble();
      _displacement = _displacementTarget -
          (_displacementTarget - _displacement) *
              math.pow(2.0, -t / _crossAxisHalfTime.inMicroseconds);
      notifyListeners();
    }
    if (nearEqual(_displacementTarget, _displacement,
        Tolerance.defaultTolerance.distance)) {
      _displacementTicker.stop();
      _displacementTickerLastElapsed = null;
    } else {
      _displacementTickerLastElapsed = elapsed;
    }
  }

  void paint(Canvas canvas, Size size) {
    if (_glowOpacity.value == 0.0) return;
    final double baseGlowScale =
        size.width > size.height ? size.height / size.width : 1.0;
    final double radius = size.width * 3.0 / 2.0;
    final double height =
        math.min(size.height, size.width * _widthToHeightFactor);
    final double scaleY = _glowSize.value * baseGlowScale;
    final Rect rect = new Rect.fromLTWH(0.0, 0.0, size.width, height);
    final Offset center =
        new Offset((size.width / 2.0) * (0.5 + _displacement), height - radius);
    final Paint paint = new Paint()
      ..color = color.withOpacity(_glowOpacity.value);
    canvas.save();
    canvas.scale(1.0, scaleY);
    canvas.clipRect(rect);
    canvas.drawCircle(center, radius, paint);
    canvas.restore();
  }
}

class _GlowingOverscrollIndicatorPainter extends CustomPainter {
  _GlowingOverscrollIndicatorPainter({
    this.leadingController,
    this.trailingController,
    this.axisDirection,
    Listenable repaint,
  }) : super(
          repaint: repaint,
        );

  final _GlowController leadingController;

  final _GlowController trailingController;

  final AxisDirection axisDirection;

  static const double piOver2 = math.pi / 2.0;

  void _paintSide(Canvas canvas, Size size, _GlowController controller,
      AxisDirection axisDirection, GrowthDirection growthDirection) {
    if (controller == null) return;
    switch (
        applyGrowthDirectionToAxisDirection(axisDirection, growthDirection)) {
      case AxisDirection.up:
        controller.paint(canvas, size);
        break;
      case AxisDirection.down:
        canvas.save();
        canvas.translate(0.0, size.height);
        canvas.scale(1.0, -1.0);
        controller.paint(canvas, size);
        canvas.restore();
        break;
      case AxisDirection.left:
        canvas.save();
        canvas.rotate(piOver2);
        canvas.scale(1.0, -1.0);
        controller.paint(canvas, new Size(size.height, size.width));
        canvas.restore();
        break;
      case AxisDirection.right:
        canvas.save();
        canvas.translate(size.width, 0.0);
        canvas.rotate(piOver2);
        controller.paint(canvas, new Size(size.height, size.width));
        canvas.restore();
        break;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    _paintSide(canvas, size, leadingController, axisDirection,
        GrowthDirection.reverse);
    _paintSide(canvas, size, trailingController, axisDirection,
        GrowthDirection.forward);
  }

  @override
  bool shouldRepaint(_GlowingOverscrollIndicatorPainter oldDelegate) {
    return oldDelegate.leadingController != leadingController ||
        oldDelegate.trailingController != trailingController;
  }
}

class OverscrollIndicatorNotification extends Notification
    with ViewportNotificationMixin {
  OverscrollIndicatorNotification({
    @required this.leading,
  });

  final bool leading;

  bool _accepted = true;

  void disallowGlow() {
    _accepted = false;
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('side: ${leading ? "leading edge" : "trailing edge"}');
  }
}

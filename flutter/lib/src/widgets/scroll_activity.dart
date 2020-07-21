import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_web/animation.dart';
import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/gestures.dart';
import 'package:flutter_web/physics.dart';
import 'package:flutter_web/rendering.dart';
import 'package:flutter_web/scheduler.dart';

import 'framework.dart';
import 'scroll_metrics.dart';
import 'scroll_notification.dart';

abstract class ScrollActivityDelegate {
  AxisDirection get axisDirection;

  double setPixels(double pixels);

  void applyUserOffset(double delta);

  void goIdle();

  void goBallistic(double velocity);
}

abstract class ScrollActivity {
  ScrollActivity(this._delegate);

  ScrollActivityDelegate get delegate => _delegate;
  ScrollActivityDelegate _delegate;

  void updateDelegate(ScrollActivityDelegate value) {
    assert(_delegate != value);
    _delegate = value;
  }

  void resetActivity() {}

  void dispatchScrollStartNotification(
      ScrollMetrics metrics, BuildContext context) {
    ScrollStartNotification(metrics: metrics, context: context)
        .dispatch(context);
  }

  void dispatchScrollUpdateNotification(
      ScrollMetrics metrics, BuildContext context, double scrollDelta) {
    ScrollUpdateNotification(
            metrics: metrics, context: context, scrollDelta: scrollDelta)
        .dispatch(context);
  }

  void dispatchOverscrollNotification(
      ScrollMetrics metrics, BuildContext context, double overscroll) {
    OverscrollNotification(
            metrics: metrics, context: context, overscroll: overscroll)
        .dispatch(context);
  }

  void dispatchScrollEndNotification(
      ScrollMetrics metrics, BuildContext context) {
    ScrollEndNotification(metrics: metrics, context: context).dispatch(context);
  }

  void applyNewDimensions() {}

  bool get shouldIgnorePointer;

  bool get isScrolling;

  double get velocity;

  @mustCallSuper
  void dispose() {
    _delegate = null;
  }

  @override
  String toString() => describeIdentity(this);
}

class IdleScrollActivity extends ScrollActivity {
  IdleScrollActivity(ScrollActivityDelegate delegate) : super(delegate);

  @override
  void applyNewDimensions() {
    delegate.goBallistic(0.0);
  }

  @override
  bool get shouldIgnorePointer => false;

  @override
  bool get isScrolling => false;

  @override
  double get velocity => 0.0;
}

abstract class ScrollHoldController {
  void cancel();
}

class HoldScrollActivity extends ScrollActivity
    implements ScrollHoldController {
  HoldScrollActivity({
    @required ScrollActivityDelegate delegate,
    this.onHoldCanceled,
  }) : super(delegate);

  final VoidCallback onHoldCanceled;

  @override
  bool get shouldIgnorePointer => false;

  @override
  bool get isScrolling => false;

  @override
  double get velocity => 0.0;

  @override
  void cancel() {
    delegate.goBallistic(0.0);
  }

  @override
  void dispose() {
    if (onHoldCanceled != null) onHoldCanceled();
    super.dispose();
  }
}

class ScrollDragController implements Drag {
  ScrollDragController({
    @required ScrollActivityDelegate delegate,
    @required DragStartDetails details,
    this.onDragCanceled,
    this.carriedVelocity,
    this.motionStartDistanceThreshold,
  })  : assert(delegate != null),
        assert(details != null),
        assert(
            motionStartDistanceThreshold == null ||
                motionStartDistanceThreshold > 0.0,
            'motionStartDistanceThreshold must be a positive number or null'),
        _delegate = delegate,
        _lastDetails = details,
        _retainMomentum = carriedVelocity != null && carriedVelocity != 0.0,
        _lastNonStationaryTimestamp = details.sourceTimeStamp,
        _offsetSinceLastStop =
            motionStartDistanceThreshold == null ? null : 0.0;

  ScrollActivityDelegate get delegate => _delegate;
  ScrollActivityDelegate _delegate;

  final VoidCallback onDragCanceled;

  final double carriedVelocity;

  final double motionStartDistanceThreshold;

  Duration _lastNonStationaryTimestamp;
  bool _retainMomentum;

  double _offsetSinceLastStop;

  static const Duration momentumRetainStationaryDurationThreshold =
      const Duration(milliseconds: 20);

  static const Duration motionStoppedDurationThreshold =
      const Duration(milliseconds: 50);

  static const double _bigThresholdBreakDistance = 24.0;

  bool get _reversed => axisDirectionIsReversed(delegate.axisDirection);

  void updateDelegate(ScrollActivityDelegate value) {
    assert(_delegate != value);
    _delegate = value;
  }

  void _maybeLoseMomentum(double offset, Duration timestamp) {
    if (_retainMomentum &&
        offset == 0.0 &&
        (timestamp == null ||
            timestamp - _lastNonStationaryTimestamp >
                momentumRetainStationaryDurationThreshold)) {
      _retainMomentum = false;
    }
  }

  double _adjustForScrollStartThreshold(double offset, Duration timestamp) {
    if (timestamp == null) {
      return offset;
    }

    if (offset == 0.0) {
      if (motionStartDistanceThreshold != null &&
          _offsetSinceLastStop == null &&
          timestamp - _lastNonStationaryTimestamp >
              motionStoppedDurationThreshold) {
        _offsetSinceLastStop = 0.0;
      }

      return 0.0;
    } else {
      if (_offsetSinceLastStop == null) {
        return offset;
      } else {
        _offsetSinceLastStop += offset;
        if (_offsetSinceLastStop.abs() > motionStartDistanceThreshold) {
          _offsetSinceLastStop = null;
          if (offset.abs() > _bigThresholdBreakDistance) {
            return offset;
          } else {
            return math.min(motionStartDistanceThreshold / 3.0, offset.abs()) *
                offset.sign;
          }
        } else {
          return 0.0;
        }
      }
    }
  }

  @override
  void update(DragUpdateDetails details) {
    assert(details.primaryDelta != null);
    _lastDetails = details;
    double offset = details.primaryDelta;
    if (offset != 0.0) {
      _lastNonStationaryTimestamp = details.sourceTimeStamp;
    }

    _maybeLoseMomentum(offset, details.sourceTimeStamp);
    offset = _adjustForScrollStartThreshold(offset, details.sourceTimeStamp);
    if (offset == 0.0) {
      return;
    }
    if (_reversed) offset = -offset;
    delegate.applyUserOffset(offset);
  }

  @override
  void end(DragEndDetails details) {
    assert(details.primaryVelocity != null);

    double velocity = -details.primaryVelocity;
    if (_reversed) velocity = -velocity;
    _lastDetails = details;

    if (_retainMomentum && velocity.sign == carriedVelocity.sign)
      velocity += carriedVelocity;
    delegate.goBallistic(velocity);
  }

  @override
  void cancel() {
    delegate.goBallistic(0.0);
  }

  @mustCallSuper
  void dispose() {
    _lastDetails = null;
    if (onDragCanceled != null) onDragCanceled();
  }

  dynamic get lastDetails => _lastDetails;
  dynamic _lastDetails;
}

class DragScrollActivity extends ScrollActivity {
  DragScrollActivity(
    ScrollActivityDelegate delegate,
    ScrollDragController controller,
  )   : _controller = controller,
        super(delegate);

  ScrollDragController _controller;

  @override
  void dispatchScrollStartNotification(
      ScrollMetrics metrics, BuildContext context) {
    final dynamic lastDetails = _controller.lastDetails;
    assert(lastDetails is DragStartDetails);
    new ScrollStartNotification(
            metrics: metrics, context: context, dragDetails: lastDetails)
        .dispatch(context);
  }

  @override
  void dispatchScrollUpdateNotification(
      ScrollMetrics metrics, BuildContext context, double scrollDelta) {
    final dynamic lastDetails = _controller.lastDetails;
    assert(lastDetails is DragUpdateDetails);
    new ScrollUpdateNotification(
            metrics: metrics,
            context: context,
            scrollDelta: scrollDelta,
            dragDetails: lastDetails)
        .dispatch(context);
  }

  @override
  void dispatchOverscrollNotification(
      ScrollMetrics metrics, BuildContext context, double overscroll) {
    final dynamic lastDetails = _controller.lastDetails;
    assert(lastDetails is DragUpdateDetails);
    new OverscrollNotification(
            metrics: metrics,
            context: context,
            overscroll: overscroll,
            dragDetails: lastDetails)
        .dispatch(context);
  }

  @override
  void dispatchScrollEndNotification(
      ScrollMetrics metrics, BuildContext context) {
    final dynamic lastDetails = _controller.lastDetails;
    new ScrollEndNotification(
            metrics: metrics,
            context: context,
            dragDetails: lastDetails is DragEndDetails ? lastDetails : null)
        .dispatch(context);
  }

  @override
  bool get shouldIgnorePointer => true;

  @override
  bool get isScrolling => true;

  @override
  double get velocity => 0.0;

  @override
  void dispose() {
    _controller = null;
    super.dispose();
  }
}

class BallisticScrollActivity extends ScrollActivity {
  BallisticScrollActivity(
    ScrollActivityDelegate delegate,
    Simulation simulation,
    TickerProvider vsync,
  ) : super(delegate) {
    _controller = new AnimationController.unbounded(
      debugLabel: kDebugMode ? '$runtimeType' : null,
      vsync: vsync,
    )
      ..addListener(_tick)
      ..animateWith(simulation).whenComplete(_end);
  }

  @override
  double get velocity => _controller.velocity;

  AnimationController _controller;

  @override
  void resetActivity() {
    delegate.goBallistic(velocity);
  }

  @override
  void applyNewDimensions() {
    delegate.goBallistic(velocity);
  }

  void _tick() {
    if (!applyMoveTo(_controller.value)) delegate.goIdle();
  }

  @protected
  bool applyMoveTo(double value) {
    return delegate.setPixels(value) == 0.0;
  }

  void _end() {
    delegate?.goBallistic(0.0);
  }

  @override
  void dispatchOverscrollNotification(
      ScrollMetrics metrics, BuildContext context, double overscroll) {
    new OverscrollNotification(
            metrics: metrics,
            context: context,
            overscroll: overscroll,
            velocity: velocity)
        .dispatch(context);
  }

  @override
  bool get shouldIgnorePointer => true;

  @override
  bool get isScrolling => true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class DrivenScrollActivity extends ScrollActivity {
  DrivenScrollActivity(
    ScrollActivityDelegate delegate, {
    @required double from,
    @required double to,
    @required Duration duration,
    @required Curve curve,
    @required TickerProvider vsync,
  })  : assert(from != null),
        assert(to != null),
        assert(duration != null),
        assert(duration > Duration.zero),
        assert(curve != null),
        super(delegate) {
    _completer = new Completer<Null>();
    _controller = new AnimationController.unbounded(
      value: from,
      debugLabel: '$runtimeType',
      vsync: vsync,
    )
      ..addListener(_tick)
      ..animateTo(to, duration: duration, curve: curve).whenComplete(_end);
  }

  Completer<Null> _completer;
  AnimationController _controller;

  Future<void> get done => _completer.future;

  @override
  double get velocity => _controller.velocity;

  void _tick() {
    if (delegate.setPixels(_controller.value) != 0.0) delegate.goIdle();
  }

  void _end() {
    delegate?.goBallistic(velocity);
  }

  @override
  void dispatchOverscrollNotification(
      ScrollMetrics metrics, BuildContext context, double overscroll) {
    new OverscrollNotification(
            metrics: metrics,
            context: context,
            overscroll: overscroll,
            velocity: velocity)
        .dispatch(context);
  }

  @override
  bool get shouldIgnorePointer => true;

  @override
  bool get isScrolling => true;

  @override
  void dispose() {
    _completer.complete();
    _controller.dispose();
    super.dispose();
  }
}

import 'arena.dart';
import 'constants.dart';
import 'events.dart';
import 'recognizer.dart';
import 'velocity_tracker.dart';

typedef GestureLongPressCallback = void Function();

typedef GestureLongPressUpCallback = void Function();

typedef GestureLongPressStartCallback = void Function(
    LongPressStartDetails details);

typedef GestureLongPressMoveUpdateCallback = void Function(
    LongPressMoveUpdateDetails details);

typedef GestureLongPressEndCallback = void Function(
    LongPressEndDetails details);

class LongPressStartDetails {
  const LongPressStartDetails({
    this.globalPosition = Offset.zero,
    Offset localPosition,
  })  : assert(globalPosition != null),
        localPosition = localPosition ?? globalPosition;

  final Offset globalPosition;

  final Offset localPosition;
}

class LongPressMoveUpdateDetails {
  const LongPressMoveUpdateDetails({
    this.globalPosition = Offset.zero,
    Offset localPosition,
    this.offsetFromOrigin = Offset.zero,
    Offset localOffsetFromOrigin,
  })  : assert(globalPosition != null),
        assert(offsetFromOrigin != null),
        localPosition = localPosition ?? globalPosition,
        localOffsetFromOrigin = localOffsetFromOrigin ?? offsetFromOrigin;

  final Offset globalPosition;

  final Offset localPosition;

  final Offset offsetFromOrigin;

  final Offset localOffsetFromOrigin;
}

class LongPressEndDetails {
  const LongPressEndDetails({
    this.globalPosition = Offset.zero,
    Offset localPosition,
    this.velocity = Velocity.zero,
  })  : assert(globalPosition != null),
        localPosition = localPosition ?? globalPosition;

  final Offset globalPosition;

  final Offset localPosition;

  final Velocity velocity;
}

class LongPressGestureRecognizer extends PrimaryPointerGestureRecognizer {
  LongPressGestureRecognizer({
    double postAcceptSlopTolerance,
    PointerDeviceKind kind,
    Object debugOwner,
  }) : super(
          deadline: kLongPressTimeout,
          postAcceptSlopTolerance: postAcceptSlopTolerance,
          kind: kind,
          debugOwner: debugOwner,
        );

  bool _longPressAccepted = false;
  OffsetPair _longPressOrigin;

  int _initialButtons;

  GestureLongPressCallback onLongPress;

  GestureLongPressStartCallback onLongPressStart;

  GestureLongPressMoveUpdateCallback onLongPressMoveUpdate;

  GestureLongPressUpCallback onLongPressUp;

  GestureLongPressEndCallback onLongPressEnd;

  VelocityTracker _velocityTracker;

  @override
  bool isPointerAllowed(PointerDownEvent event) {
    switch (event.buttons) {
      case kPrimaryButton:
        if (onLongPressStart == null &&
            onLongPress == null &&
            onLongPressMoveUpdate == null &&
            onLongPressEnd == null &&
            onLongPressUp == null) return false;
        break;
      default:
        return false;
    }
    return super.isPointerAllowed(event);
  }

  @override
  void didExceedDeadline() {
    resolve(GestureDisposition.accepted);
    _longPressAccepted = true;
    super.acceptGesture(primaryPointer);
    _checkLongPressStart();
  }

  @override
  void handlePrimaryPointer(PointerEvent event) {
    if (!event.synthesized) {
      if (event is PointerDownEvent) {
        _velocityTracker = VelocityTracker();
        _velocityTracker.addPosition(event.timeStamp, event.localPosition);
      }
      if (event is PointerMoveEvent) {
        assert(_velocityTracker != null);
        _velocityTracker.addPosition(event.timeStamp, event.localPosition);
      }
    }

    if (event is PointerUpEvent) {
      if (_longPressAccepted == true) {
        _checkLongPressEnd(event);
      } else {
        resolve(GestureDisposition.rejected);
      }
      _reset();
    } else if (event is PointerCancelEvent) {
      _reset();
    } else if (event is PointerDownEvent) {
      _longPressOrigin = OffsetPair.fromEventPosition(event);
      _initialButtons = event.buttons;
    } else if (event is PointerMoveEvent) {
      if (event.buttons != _initialButtons) {
        resolve(GestureDisposition.rejected);
        stopTrackingPointer(primaryPointer);
      } else if (_longPressAccepted) {
        _checkLongPressMoveUpdate(event);
      }
    }
  }

  void _checkLongPressStart() {
    assert(_initialButtons == kPrimaryButton);
    if (onLongPressStart != null) {
      final LongPressStartDetails details = LongPressStartDetails(
        globalPosition: _longPressOrigin.global,
        localPosition: _longPressOrigin.local,
      );
      invokeCallback<void>('onLongPressStart', () => onLongPressStart(details));
    }
    if (onLongPress != null) invokeCallback<void>('onLongPress', onLongPress);
  }

  void _checkLongPressMoveUpdate(PointerEvent event) {
    assert(_initialButtons == kPrimaryButton);
    final LongPressMoveUpdateDetails details = LongPressMoveUpdateDetails(
      globalPosition: event.position,
      localPosition: event.localPosition,
      offsetFromOrigin: event.position - _longPressOrigin.global,
      localOffsetFromOrigin: event.localPosition - _longPressOrigin.local,
    );
    if (onLongPressMoveUpdate != null)
      invokeCallback<void>(
          'onLongPressMoveUpdate', () => onLongPressMoveUpdate(details));
  }

  void _checkLongPressEnd(PointerEvent event) {
    assert(_initialButtons == kPrimaryButton);

    final VelocityEstimate estimate = _velocityTracker.getVelocityEstimate();
    final Velocity velocity = estimate == null
        ? Velocity.zero
        : Velocity(pixelsPerSecond: estimate.pixelsPerSecond);
    final LongPressEndDetails details = LongPressEndDetails(
      globalPosition: event.position,
      localPosition: event.localPosition,
      velocity: velocity,
    );

    _velocityTracker = null;
    if (onLongPressEnd != null)
      invokeCallback<void>('onLongPressEnd', () => onLongPressEnd(details));
    if (onLongPressUp != null)
      invokeCallback<void>('onLongPressUp', onLongPressUp);
  }

  void _reset() {
    _longPressAccepted = false;
    _longPressOrigin = null;
    _initialButtons = null;
    _velocityTracker = null;
  }

  @override
  void resolve(GestureDisposition disposition) {
    if (_longPressAccepted && disposition == GestureDisposition.rejected) {
      _reset();
    }
    super.resolve(disposition);
  }

  @override
  void acceptGesture(int pointer) {}

  @override
  String get debugDescription => 'long press';
}

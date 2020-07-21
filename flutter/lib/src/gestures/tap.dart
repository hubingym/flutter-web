import 'package:flutter_web/foundation.dart';

import 'arena.dart';
import 'constants.dart';
import 'events.dart';
import 'recognizer.dart';

class TapDownDetails {
  TapDownDetails({
    this.globalPosition = Offset.zero,
    Offset localPosition,
    this.kind,
  })  : assert(globalPosition != null),
        localPosition = localPosition ?? globalPosition;

  final Offset globalPosition;

  final PointerDeviceKind kind;

  final Offset localPosition;
}

typedef GestureTapDownCallback = void Function(TapDownDetails details);

class TapUpDetails {
  TapUpDetails({
    this.globalPosition = Offset.zero,
    Offset localPosition,
  })  : assert(globalPosition != null),
        localPosition = localPosition ?? globalPosition;

  final Offset globalPosition;

  final Offset localPosition;
}

typedef GestureTapUpCallback = void Function(TapUpDetails details);

typedef GestureTapCallback = void Function();

typedef GestureTapCancelCallback = void Function();

class TapGestureRecognizer extends PrimaryPointerGestureRecognizer {
  TapGestureRecognizer({Object debugOwner})
      : super(deadline: kPressTimeout, debugOwner: debugOwner);

  GestureTapDownCallback onTapDown;

  GestureTapUpCallback onTapUp;

  GestureTapCallback onTap;

  GestureTapCancelCallback onTapCancel;

  GestureTapDownCallback onSecondaryTapDown;

  GestureTapUpCallback onSecondaryTapUp;

  GestureTapCancelCallback onSecondaryTapCancel;

  bool _sentTapDown = false;
  bool _wonArenaForPrimaryPointer = false;
  OffsetPair _finalPosition;

  int _initialButtons;

  @override
  bool isPointerAllowed(PointerDownEvent event) {
    switch (event.buttons) {
      case kPrimaryButton:
        if (onTapDown == null &&
            onTap == null &&
            onTapUp == null &&
            onTapCancel == null) return false;
        break;
      case kSecondaryButton:
        if (onSecondaryTapDown == null &&
            onSecondaryTapUp == null &&
            onSecondaryTapCancel == null) return false;
        break;
      default:
        return false;
    }
    return super.isPointerAllowed(event);
  }

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);

    _initialButtons = event.buttons;
  }

  @override
  void handlePrimaryPointer(PointerEvent event) {
    if (event is PointerUpEvent) {
      _finalPosition =
          OffsetPair(global: event.position, local: event.localPosition);
      _checkUp();
    } else if (event is PointerCancelEvent) {
      resolve(GestureDisposition.rejected);
      if (_sentTapDown) {
        _checkCancel('');
      }
      _reset();
    } else if (event.buttons != _initialButtons) {
      resolve(GestureDisposition.rejected);
      stopTrackingPointer(primaryPointer);
    }
  }

  @override
  void resolve(GestureDisposition disposition) {
    if (_wonArenaForPrimaryPointer &&
        disposition == GestureDisposition.rejected) {
      assert(_sentTapDown);
      _checkCancel('spontaneous ');
      _reset();
    }
    super.resolve(disposition);
  }

  @override
  void didExceedDeadlineWithEvent(PointerDownEvent event) {
    _checkDown(event.pointer);
  }

  @override
  void acceptGesture(int pointer) {
    super.acceptGesture(pointer);
    if (pointer == primaryPointer) {
      _checkDown(pointer);
      _wonArenaForPrimaryPointer = true;
      _checkUp();
    }
  }

  @override
  void rejectGesture(int pointer) {
    super.rejectGesture(pointer);
    if (pointer == primaryPointer) {
      assert(state != GestureRecognizerState.possible);
      if (_sentTapDown) _checkCancel('forced ');
      _reset();
    }
  }

  void _checkDown(int pointer) {
    if (_sentTapDown) {
      return;
    }
    final TapDownDetails details = TapDownDetails(
      globalPosition: initialPosition.global,
      localPosition: initialPosition.local,
      kind: getKindForPointer(pointer),
    );
    switch (_initialButtons) {
      case kPrimaryButton:
        if (onTapDown != null)
          invokeCallback<void>('onTapDown', () => onTapDown(details));
        break;
      case kSecondaryButton:
        if (onSecondaryTapDown != null)
          invokeCallback<void>(
              'onSecondaryTapDown', () => onSecondaryTapDown(details));
        break;
      default:
    }
    _sentTapDown = true;
  }

  void _checkUp() {
    if (!_wonArenaForPrimaryPointer || _finalPosition == null) {
      return;
    }
    final TapUpDetails details = TapUpDetails(
      globalPosition: _finalPosition.global,
      localPosition: _finalPosition.local,
    );
    switch (_initialButtons) {
      case kPrimaryButton:
        if (onTapUp != null)
          invokeCallback<void>('onTapUp', () => onTapUp(details));
        if (onTap != null) invokeCallback<void>('onTap', onTap);
        break;
      case kSecondaryButton:
        if (onSecondaryTapUp != null)
          invokeCallback<void>(
              'onSecondaryTapUp', () => onSecondaryTapUp(details));
        break;
      default:
    }
    _reset();
  }

  void _checkCancel(String note) {
    switch (_initialButtons) {
      case kPrimaryButton:
        if (onTapCancel != null)
          invokeCallback<void>('${note}onTapCancel', onTapCancel);
        break;
      case kSecondaryButton:
        if (onSecondaryTapCancel != null)
          invokeCallback<void>(
              '${note}onSecondaryTapCancel', onSecondaryTapCancel);
        break;
      default:
    }
  }

  void _reset() {
    _sentTapDown = false;
    _wonArenaForPrimaryPointer = false;
    _finalPosition = null;
    _initialButtons = null;
  }

  @override
  String get debugDescription => 'tap';

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagProperty('wonArenaForPrimaryPointer',
        value: _wonArenaForPrimaryPointer, ifTrue: 'won arena'));
    properties.add(DiagnosticsProperty<Offset>(
        'finalPosition', _finalPosition?.global,
        defaultValue: null));
    properties.add(DiagnosticsProperty<Offset>(
        'finalLocalPosition', _finalPosition?.local,
        defaultValue: _finalPosition?.global));
    properties.add(FlagProperty('sentTapDown',
        value: _sentTapDown, ifTrue: 'sent tap down'));
  }
}

import 'package:flutter_web/ui.dart' as ui
    show PointerData, PointerChange, PointerSignalKind;

import 'package:flutter_web/foundation.dart' show visibleForTesting;

import 'events.dart';

class _PointerState {
  _PointerState(this.lastPosition);

  int get pointer => _pointer;
  int _pointer;
  static int _pointerCount = 0;
  void startNewPointer() {
    _pointerCount += 1;
    _pointer = _pointerCount;
  }

  bool get down => _down;
  bool _down = false;
  void setDown() {
    assert(!_down);
    _down = true;
  }

  void setUp() {
    assert(_down);
    _down = false;
  }

  Offset lastPosition;

  Offset deltaTo(Offset to) => to - lastPosition;

  @override
  String toString() {
    return '_PointerState(pointer: $pointer, down: $down, lastPosition: $lastPosition)';
  }
}

int _synthesiseDownButtons(int buttons, PointerDeviceKind kind) {
  switch (kind) {
    case PointerDeviceKind.mouse:
      return buttons;
    case PointerDeviceKind.touch:
    case PointerDeviceKind.stylus:
    case PointerDeviceKind.invertedStylus:
      return buttons | kPrimaryButton;
    default:
      return buttons == 0 ? kPrimaryButton : buttons;
  }
}

class PointerEventConverter {
  PointerEventConverter._();

  @visibleForTesting
  static void clearPointers() => _pointers.clear();

  static final Map<int, _PointerState> _pointers = <int, _PointerState>{};

  static _PointerState _ensureStateForPointer(
      ui.PointerData datum, Offset position) {
    return _pointers.putIfAbsent(
      datum.device,
      () => _PointerState(position),
    );
  }

  static Iterable<PointerEvent> expand(
      Iterable<ui.PointerData> data, double devicePixelRatio) sync* {
    for (ui.PointerData datum in data) {
      final Offset position =
          Offset(datum.physicalX, datum.physicalY) / devicePixelRatio;
      final double radiusMinor =
          _toLogicalPixels(datum.radiusMinor, devicePixelRatio);
      final double radiusMajor =
          _toLogicalPixels(datum.radiusMajor, devicePixelRatio);
      final double radiusMin =
          _toLogicalPixels(datum.radiusMin, devicePixelRatio);
      final double radiusMax =
          _toLogicalPixels(datum.radiusMax, devicePixelRatio);
      final Duration timeStamp = datum.timeStamp;
      final PointerDeviceKind kind = datum.kind;
      assert(datum.change != null);
      if (datum.signalKind == null ||
          datum.signalKind == ui.PointerSignalKind.none) {
        switch (datum.change) {
          case ui.PointerChange.add:
            assert(!_pointers.containsKey(datum.device));
            final _PointerState state = _ensureStateForPointer(datum, position);
            assert(state.lastPosition == position);
            yield PointerAddedEvent(
              timeStamp: timeStamp,
              kind: kind,
              device: datum.device,
              position: position,
              obscured: datum.obscured,
              pressureMin: datum.pressureMin,
              pressureMax: datum.pressureMax,
              distance: datum.distance,
              distanceMax: datum.distanceMax,
              radiusMin: radiusMin,
              radiusMax: radiusMax,
              orientation: datum.orientation,
              tilt: datum.tilt,
            );
            break;
          case ui.PointerChange.hover:
            final bool alreadyAdded = _pointers.containsKey(datum.device);
            final _PointerState state = _ensureStateForPointer(datum, position);
            assert(!state.down);
            if (!alreadyAdded) {
              assert(state.lastPosition == position);
              yield PointerAddedEvent(
                timeStamp: timeStamp,
                kind: kind,
                device: datum.device,
                position: position,
                obscured: datum.obscured,
                pressureMin: datum.pressureMin,
                pressureMax: datum.pressureMax,
                distance: datum.distance,
                distanceMax: datum.distanceMax,
                radiusMin: radiusMin,
                radiusMax: radiusMax,
                orientation: datum.orientation,
                tilt: datum.tilt,
              );
            }
            yield PointerHoverEvent(
              timeStamp: timeStamp,
              kind: kind,
              device: datum.device,
              position: position,
              delta: state.deltaTo(position),
              buttons: datum.buttons,
              obscured: datum.obscured,
              pressureMin: datum.pressureMin,
              pressureMax: datum.pressureMax,
              distance: datum.distance,
              distanceMax: datum.distanceMax,
              size: datum.size,
              radiusMajor: radiusMajor,
              radiusMinor: radiusMinor,
              radiusMin: radiusMin,
              radiusMax: radiusMax,
              orientation: datum.orientation,
              tilt: datum.tilt,
            );
            state.lastPosition = position;
            break;
          case ui.PointerChange.down:
            final bool alreadyAdded = _pointers.containsKey(datum.device);
            final _PointerState state = _ensureStateForPointer(datum, position);
            assert(!state.down);
            if (!alreadyAdded) {
              assert(state.lastPosition == position);
              yield PointerAddedEvent(
                timeStamp: timeStamp,
                kind: kind,
                device: datum.device,
                position: position,
                obscured: datum.obscured,
                pressureMin: datum.pressureMin,
                pressureMax: datum.pressureMax,
                distance: datum.distance,
                distanceMax: datum.distanceMax,
                radiusMin: radiusMin,
                radiusMax: radiusMax,
                orientation: datum.orientation,
                tilt: datum.tilt,
              );
            }
            if (state.lastPosition != position) {
              yield PointerHoverEvent(
                timeStamp: timeStamp,
                kind: kind,
                device: datum.device,
                position: position,
                delta: state.deltaTo(position),
                buttons: datum.buttons,
                obscured: datum.obscured,
                pressureMin: datum.pressureMin,
                pressureMax: datum.pressureMax,
                distance: datum.distance,
                distanceMax: datum.distanceMax,
                size: datum.size,
                radiusMajor: radiusMajor,
                radiusMinor: radiusMinor,
                radiusMin: radiusMin,
                radiusMax: radiusMax,
                orientation: datum.orientation,
                tilt: datum.tilt,
                synthesized: true,
              );
              state.lastPosition = position;
            }
            state.startNewPointer();
            state.setDown();
            yield PointerDownEvent(
              timeStamp: timeStamp,
              pointer: state.pointer,
              kind: kind,
              device: datum.device,
              position: position,
              buttons: _synthesiseDownButtons(datum.buttons, kind),
              obscured: datum.obscured,
              pressure: datum.pressure,
              pressureMin: datum.pressureMin,
              pressureMax: datum.pressureMax,
              distanceMax: datum.distanceMax,
              size: datum.size,
              radiusMajor: radiusMajor,
              radiusMinor: radiusMinor,
              radiusMin: radiusMin,
              radiusMax: radiusMax,
              orientation: datum.orientation,
              tilt: datum.tilt,
            );
            break;
          case ui.PointerChange.move:
            assert(_pointers.containsKey(datum.device));
            final _PointerState state = _pointers[datum.device];
            assert(state.down);
            yield PointerMoveEvent(
              timeStamp: timeStamp,
              pointer: state.pointer,
              kind: kind,
              device: datum.device,
              position: position,
              delta: state.deltaTo(position),
              buttons: _synthesiseDownButtons(datum.buttons, kind),
              obscured: datum.obscured,
              pressure: datum.pressure,
              pressureMin: datum.pressureMin,
              pressureMax: datum.pressureMax,
              distanceMax: datum.distanceMax,
              size: datum.size,
              radiusMajor: radiusMajor,
              radiusMinor: radiusMinor,
              radiusMin: radiusMin,
              radiusMax: radiusMax,
              orientation: datum.orientation,
              tilt: datum.tilt,
              platformData: datum.platformData,
            );
            state.lastPosition = position;
            break;
          case ui.PointerChange.up:
          case ui.PointerChange.cancel:
            assert(_pointers.containsKey(datum.device));
            final _PointerState state = _pointers[datum.device];
            assert(state.down);
            if (position != state.lastPosition) {
              yield PointerMoveEvent(
                timeStamp: timeStamp,
                pointer: state.pointer,
                kind: kind,
                device: datum.device,
                position: position,
                delta: state.deltaTo(position),
                buttons: _synthesiseDownButtons(datum.buttons, kind),
                obscured: datum.obscured,
                pressure: datum.pressure,
                pressureMin: datum.pressureMin,
                pressureMax: datum.pressureMax,
                distanceMax: datum.distanceMax,
                size: datum.size,
                radiusMajor: radiusMajor,
                radiusMinor: radiusMinor,
                radiusMin: radiusMin,
                radiusMax: radiusMax,
                orientation: datum.orientation,
                tilt: datum.tilt,
                synthesized: true,
              );
              state.lastPosition = position;
            }
            assert(position == state.lastPosition);
            state.setUp();
            if (datum.change == ui.PointerChange.up) {
              yield PointerUpEvent(
                timeStamp: timeStamp,
                pointer: state.pointer,
                kind: kind,
                device: datum.device,
                position: position,
                buttons: datum.buttons,
                obscured: datum.obscured,
                pressure: datum.pressure,
                pressureMin: datum.pressureMin,
                pressureMax: datum.pressureMax,
                distance: datum.distance,
                distanceMax: datum.distanceMax,
                size: datum.size,
                radiusMajor: radiusMajor,
                radiusMinor: radiusMinor,
                radiusMin: radiusMin,
                radiusMax: radiusMax,
                orientation: datum.orientation,
                tilt: datum.tilt,
              );
            } else {
              yield PointerCancelEvent(
                timeStamp: timeStamp,
                pointer: state.pointer,
                kind: kind,
                device: datum.device,
                position: position,
                buttons: datum.buttons,
                obscured: datum.obscured,
                pressureMin: datum.pressureMin,
                pressureMax: datum.pressureMax,
                distance: datum.distance,
                distanceMax: datum.distanceMax,
                size: datum.size,
                radiusMajor: radiusMajor,
                radiusMinor: radiusMinor,
                radiusMin: radiusMin,
                radiusMax: radiusMax,
                orientation: datum.orientation,
                tilt: datum.tilt,
              );
            }
            break;
          case ui.PointerChange.remove:
            assert(_pointers.containsKey(datum.device));
            final _PointerState state = _pointers[datum.device];
            if (state.down) {
              yield PointerCancelEvent(
                timeStamp: timeStamp,
                pointer: state.pointer,
                kind: kind,
                device: datum.device,
                position: state.lastPosition,
                buttons: datum.buttons,
                obscured: datum.obscured,
                pressureMin: datum.pressureMin,
                pressureMax: datum.pressureMax,
                distance: datum.distance,
                distanceMax: datum.distanceMax,
                size: datum.size,
                radiusMajor: radiusMajor,
                radiusMinor: radiusMinor,
                radiusMin: radiusMin,
                radiusMax: radiusMax,
                orientation: datum.orientation,
                tilt: datum.tilt,
              );
            }
            if (position != state.lastPosition) {
              yield PointerHoverEvent(
                timeStamp: timeStamp,
                kind: kind,
                device: datum.device,
                position: position,
                delta: state.deltaTo(position),
                buttons: datum.buttons,
                obscured: datum.obscured,
                pressureMin: datum.pressureMin,
                pressureMax: datum.pressureMax,
                distance: datum.distance,
                distanceMax: datum.distanceMax,
                size: datum.size,
                radiusMajor: radiusMajor,
                radiusMinor: radiusMinor,
                radiusMin: radiusMin,
                radiusMax: radiusMax,
                orientation: datum.orientation,
                tilt: datum.tilt,
                synthesized: true,
              );
            }
            _pointers.remove(datum.device);
            yield PointerRemovedEvent(
              timeStamp: timeStamp,
              kind: kind,
              device: datum.device,
              position: position,
              obscured: datum.obscured,
              pressureMin: datum.pressureMin,
              pressureMax: datum.pressureMax,
              distanceMax: datum.distanceMax,
              radiusMin: radiusMin,
              radiusMax: radiusMax,
            );
            break;
        }
      } else {
        switch (datum.signalKind) {
          case ui.PointerSignalKind.scroll:
            assert(_pointers.containsKey(datum.device));
            final _PointerState state = _ensureStateForPointer(datum, position);
            if (state.lastPosition != position) {
              if (state.down) {
                yield PointerMoveEvent(
                  timeStamp: timeStamp,
                  pointer: state.pointer,
                  kind: kind,
                  device: datum.device,
                  position: position,
                  delta: state.deltaTo(position),
                  buttons: _synthesiseDownButtons(datum.buttons, kind),
                  obscured: datum.obscured,
                  pressure: datum.pressure,
                  pressureMin: datum.pressureMin,
                  pressureMax: datum.pressureMax,
                  distanceMax: datum.distanceMax,
                  size: datum.size,
                  radiusMajor: radiusMajor,
                  radiusMinor: radiusMinor,
                  radiusMin: radiusMin,
                  radiusMax: radiusMax,
                  orientation: datum.orientation,
                  tilt: datum.tilt,
                  synthesized: true,
                );
              } else {
                yield PointerHoverEvent(
                  timeStamp: timeStamp,
                  kind: kind,
                  device: datum.device,
                  position: position,
                  delta: state.deltaTo(position),
                  buttons: datum.buttons,
                  obscured: datum.obscured,
                  pressureMin: datum.pressureMin,
                  pressureMax: datum.pressureMax,
                  distance: datum.distance,
                  distanceMax: datum.distanceMax,
                  size: datum.size,
                  radiusMajor: radiusMajor,
                  radiusMinor: radiusMinor,
                  radiusMin: radiusMin,
                  radiusMax: radiusMax,
                  orientation: datum.orientation,
                  tilt: datum.tilt,
                  synthesized: true,
                );
              }
              state.lastPosition = position;
            }
            final Offset scrollDelta =
                Offset(datum.scrollDeltaX, datum.scrollDeltaY) /
                    devicePixelRatio;
            yield PointerScrollEvent(
              timeStamp: timeStamp,
              kind: kind,
              device: datum.device,
              position: position,
              scrollDelta: scrollDelta,
            );
            break;
          case ui.PointerSignalKind.none:
            assert(false);
            break;
          case ui.PointerSignalKind.unknown:
            break;
        }
      }
    }
  }

  static double _toLogicalPixels(
          double physicalPixels, double devicePixelRatio) =>
      physicalPixels == null ? null : physicalPixels / devicePixelRatio;
}

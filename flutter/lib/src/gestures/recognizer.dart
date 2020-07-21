import 'dart:async';
import 'dart:collection';

import 'package:vector_math/vector_math_64.dart';
import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/ui.dart' show Offset;
import 'arena.dart';
import 'binding.dart';
import 'constants.dart';
import 'debug.dart';
import 'events.dart';
import 'pointer_router.dart';
import 'team.dart';

export 'pointer_router.dart' show PointerRouter;

typedef RecognizerCallback<T> = T Function();

enum DragStartBehavior {
  down,

  start,
}

abstract class GestureRecognizer extends GestureArenaMember
    with DiagnosticableTreeMixin {
  GestureRecognizer({this.debugOwner, PointerDeviceKind kind})
      : _kindFilter = kind;

  final Object debugOwner;

  final PointerDeviceKind _kindFilter;

  final Map<int, PointerDeviceKind> _pointerToKind = <int, PointerDeviceKind>{};

  void addPointer(PointerDownEvent event) {
    _pointerToKind[event.pointer] = event.kind;
    if (isPointerAllowed(event)) {
      addAllowedPointer(event);
    } else {
      handleNonAllowedPointer(event);
    }
  }

  @protected
  void addAllowedPointer(PointerDownEvent event) {}

  @protected
  void handleNonAllowedPointer(PointerDownEvent event) {}

  @protected
  bool isPointerAllowed(PointerDownEvent event) {
    return _kindFilter == null || _kindFilter == event.kind;
  }

  @protected
  PointerDeviceKind getKindForPointer(int pointer) {
    assert(_pointerToKind.containsKey(pointer));
    return _pointerToKind[pointer];
  }

  @mustCallSuper
  void dispose() {}

  String get debugDescription;

  @protected
  T invokeCallback<T>(String name, RecognizerCallback<T> callback,
      {String debugReport()}) {
    assert(callback != null);
    T result;
    try {
      assert(() {
        if (debugPrintRecognizerCallbacksTrace) {
          final String report = debugReport != null ? debugReport() : null;

          final String prefix =
              debugPrintGestureArenaDiagnostics ? ' ' * 19 + '❙ ' : '';
          debugPrint(
              '$prefix$this calling $name callback.${report?.isNotEmpty == true ? " $report" : ""}');
        }
        return true;
      }());
      result = callback();
    } catch (exception, stack) {
      FlutterError.reportError(FlutterErrorDetails(
          exception: exception,
          stack: stack,
          library: 'gesture',
          context: ErrorDescription('while handling a gesture'),
          informationCollector: () sync* {
            yield StringProperty('Handler', name);
            yield DiagnosticsProperty<GestureRecognizer>('Recognizer', this,
                style: DiagnosticsTreeStyle.errorProperty);
          }));
    }
    return result;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Object>('debugOwner', debugOwner,
        defaultValue: null));
  }
}

abstract class OneSequenceGestureRecognizer extends GestureRecognizer {
  OneSequenceGestureRecognizer({
    Object debugOwner,
    PointerDeviceKind kind,
  }) : super(debugOwner: debugOwner, kind: kind);

  final Map<int, GestureArenaEntry> _entries = <int, GestureArenaEntry>{};
  final Set<int> _trackedPointers = HashSet<int>();

  @override
  void handleNonAllowedPointer(PointerDownEvent event) {
    resolve(GestureDisposition.rejected);
  }

  @protected
  void handleEvent(PointerEvent event);

  @override
  void acceptGesture(int pointer) {}

  @override
  void rejectGesture(int pointer) {}

  @protected
  void didStopTrackingLastPointer(int pointer);

  @protected
  @mustCallSuper
  void resolve(GestureDisposition disposition) {
    final List<GestureArenaEntry> localEntries =
        List<GestureArenaEntry>.from(_entries.values);
    _entries.clear();
    for (GestureArenaEntry entry in localEntries) entry.resolve(disposition);
  }

  @override
  void dispose() {
    resolve(GestureDisposition.rejected);
    for (int pointer in _trackedPointers)
      GestureBinding.instance.pointerRouter.removeRoute(pointer, handleEvent);
    _trackedPointers.clear();
    assert(_entries.isEmpty);
    super.dispose();
  }

  GestureArenaTeam get team => _team;
  GestureArenaTeam _team;

  set team(GestureArenaTeam value) {
    assert(value != null);
    assert(_entries.isEmpty);
    assert(_trackedPointers.isEmpty);
    assert(_team == null);
    _team = value;
  }

  GestureArenaEntry _addPointerToArena(int pointer) {
    if (_team != null) return _team.add(pointer, this);
    return GestureBinding.instance.gestureArena.add(pointer, this);
  }

  @protected
  void startTrackingPointer(int pointer, [Matrix4 transform]) {
    GestureBinding.instance.pointerRouter
        .addRoute(pointer, handleEvent, transform);
    _trackedPointers.add(pointer);
    assert(!_entries.containsValue(pointer));
    _entries[pointer] = _addPointerToArena(pointer);
  }

  @protected
  void stopTrackingPointer(int pointer) {
    if (_trackedPointers.contains(pointer)) {
      GestureBinding.instance.pointerRouter.removeRoute(pointer, handleEvent);
      _trackedPointers.remove(pointer);
      if (_trackedPointers.isEmpty) didStopTrackingLastPointer(pointer);
    }
  }

  @protected
  void stopTrackingIfPointerNoLongerDown(PointerEvent event) {
    if (event is PointerUpEvent || event is PointerCancelEvent)
      stopTrackingPointer(event.pointer);
  }
}

enum GestureRecognizerState {
  ready,

  possible,

  defunct,
}

abstract class PrimaryPointerGestureRecognizer
    extends OneSequenceGestureRecognizer {
  PrimaryPointerGestureRecognizer({
    this.deadline,
    this.preAcceptSlopTolerance = kTouchSlop,
    this.postAcceptSlopTolerance = kTouchSlop,
    Object debugOwner,
    PointerDeviceKind kind,
  })  : assert(
          preAcceptSlopTolerance == null || preAcceptSlopTolerance >= 0,
          'The preAcceptSlopTolerance must be positive or null',
        ),
        assert(
          postAcceptSlopTolerance == null || postAcceptSlopTolerance >= 0,
          'The postAcceptSlopTolerance must be positive or null',
        ),
        super(debugOwner: debugOwner, kind: kind);

  final Duration deadline;

  final double preAcceptSlopTolerance;

  final double postAcceptSlopTolerance;

  GestureRecognizerState state = GestureRecognizerState.ready;

  int primaryPointer;

  OffsetPair initialPosition;

  bool _gestureAccepted = false;
  Timer _timer;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    startTrackingPointer(event.pointer, event.transform);
    if (state == GestureRecognizerState.ready) {
      state = GestureRecognizerState.possible;
      primaryPointer = event.pointer;
      initialPosition =
          OffsetPair(local: event.localPosition, global: event.position);
      if (deadline != null)
        _timer = Timer(deadline, () => didExceedDeadlineWithEvent(event));
    }
  }

  @override
  void handleEvent(PointerEvent event) {
    assert(state != GestureRecognizerState.ready);
    if (state == GestureRecognizerState.possible &&
        event.pointer == primaryPointer) {
      final bool isPreAcceptSlopPastTolerance = !_gestureAccepted &&
          preAcceptSlopTolerance != null &&
          _getGlobalDistance(event) > preAcceptSlopTolerance;
      final bool isPostAcceptSlopPastTolerance = _gestureAccepted &&
          postAcceptSlopTolerance != null &&
          _getGlobalDistance(event) > postAcceptSlopTolerance;

      if (event is PointerMoveEvent &&
          (isPreAcceptSlopPastTolerance || isPostAcceptSlopPastTolerance)) {
        resolve(GestureDisposition.rejected);
        stopTrackingPointer(primaryPointer);
      } else {
        handlePrimaryPointer(event);
      }
    }
    stopTrackingIfPointerNoLongerDown(event);
  }

  @protected
  void handlePrimaryPointer(PointerEvent event);

  @protected
  void didExceedDeadline() {
    assert(deadline == null);
  }

  @protected
  void didExceedDeadlineWithEvent(PointerDownEvent event) {
    didExceedDeadline();
  }

  @override
  void acceptGesture(int pointer) {
    _gestureAccepted = true;
  }

  @override
  void rejectGesture(int pointer) {
    if (pointer == primaryPointer && state == GestureRecognizerState.possible) {
      _stopTimer();
      state = GestureRecognizerState.defunct;
    }
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    assert(state != GestureRecognizerState.ready);
    _stopTimer();
    state = GestureRecognizerState.ready;
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  void _stopTimer() {
    if (_timer != null) {
      _timer.cancel();
      _timer = null;
    }
  }

  double _getGlobalDistance(PointerEvent event) {
    final Offset offset = event.position - initialPosition.global;
    return offset.distance;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<GestureRecognizerState>('state', state));
  }
}

class OffsetPair {
  const OffsetPair({
    @required this.local,
    @required this.global,
  });

  factory OffsetPair.fromEventPosition(PointerEvent event) {
    return OffsetPair(local: event.localPosition, global: event.position);
  }

  factory OffsetPair.fromEventDelta(PointerEvent event) {
    return OffsetPair(local: event.localDelta, global: event.delta);
  }

  static const OffsetPair zero =
      OffsetPair(local: Offset.zero, global: Offset.zero);

  final Offset local;

  final Offset global;

  OffsetPair operator +(OffsetPair other) {
    return OffsetPair(
      local: local + other.local,
      global: global + other.global,
    );
  }

  OffsetPair operator -(OffsetPair other) {
    return OffsetPair(
      local: local - other.local,
      global: global - other.global,
    );
  }

  @override
  String toString() => '$runtimeType(local: $local, global: $global)';
}

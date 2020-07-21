import 'dart:async';
import 'dart:collection';
import 'package:flutter_web/ui.dart' as ui show PointerDataPacket;

import 'package:flutter_web/foundation.dart';

import 'arena.dart';
import 'converter.dart';
import 'debug.dart';
import 'events.dart';
import 'hit_test.dart';
import 'pointer_router.dart';
import 'pointer_signal_resolver.dart';

mixin GestureBinding on BindingBase
    implements HitTestable, HitTestDispatcher, HitTestTarget {
  @override
  void initInstances() {
    super.initInstances();
    _instance = this;
    window.onPointerDataPacket = _handlePointerDataPacket;
  }

  @override
  void unlocked() {
    super.unlocked();
    _flushPointerEventQueue();
  }

  static GestureBinding get instance => _instance;
  static GestureBinding _instance;

  final Queue<PointerEvent> _pendingPointerEvents = Queue<PointerEvent>();

  void _handlePointerDataPacket(ui.PointerDataPacket packet) {
    _pendingPointerEvents.addAll(
        PointerEventConverter.expand(packet.data, window.devicePixelRatio));
    if (!locked) _flushPointerEventQueue();
  }

  void cancelPointer(int pointer) {
    if (_pendingPointerEvents.isEmpty && !locked)
      scheduleMicrotask(_flushPointerEventQueue);
    _pendingPointerEvents.addFirst(PointerCancelEvent(pointer: pointer));
  }

  void _flushPointerEventQueue() {
    assert(!locked);
    while (_pendingPointerEvents.isNotEmpty)
      _handlePointerEvent(_pendingPointerEvents.removeFirst());
  }

  final PointerRouter pointerRouter = PointerRouter();

  final GestureArenaManager gestureArena = GestureArenaManager();

  final PointerSignalResolver pointerSignalResolver = PointerSignalResolver();

  final Map<int, HitTestResult> _hitTests = <int, HitTestResult>{};

  void _handlePointerEvent(PointerEvent event) {
    assert(!locked);
    HitTestResult hitTestResult;
    if (event is PointerDownEvent || event is PointerSignalEvent) {
      assert(!_hitTests.containsKey(event.pointer));
      hitTestResult = HitTestResult();
      hitTest(hitTestResult, event.position);
      if (event is PointerDownEvent) {
        _hitTests[event.pointer] = hitTestResult;
      }
      assert(() {
        if (debugPrintHitTestResults) debugPrint('$event: $hitTestResult');
        return true;
      }());
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      hitTestResult = _hitTests.remove(event.pointer);
    } else if (event.down) {
      hitTestResult = _hitTests[event.pointer];
    }
    assert(() {
      if (debugPrintMouseHoverEvents && event is PointerHoverEvent)
        debugPrint('$event');
      return true;
    }());
    if (hitTestResult != null ||
        event is PointerHoverEvent ||
        event is PointerAddedEvent ||
        event is PointerRemovedEvent) {
      dispatchEvent(event, hitTestResult);
    }
  }

  @override
  void hitTest(HitTestResult result, Offset position) {
    result.add(HitTestEntry(this));
  }

  @override
  void dispatchEvent(PointerEvent event, HitTestResult hitTestResult) {
    assert(!locked);

    if (hitTestResult == null) {
      assert(event is PointerHoverEvent ||
          event is PointerAddedEvent ||
          event is PointerRemovedEvent);
      try {
        pointerRouter.route(event);
      } catch (exception, stack) {
        FlutterError.reportError(FlutterErrorDetailsForPointerEventDispatcher(
          exception: exception,
          stack: stack,
          library: 'gesture library',
          context: ErrorDescription(
              'while dispatching a non-hit-tested pointer event'),
          event: event,
          hitTestEntry: null,
          informationCollector: () sync* {
            yield DiagnosticsProperty<PointerEvent>('Event', event,
                style: DiagnosticsTreeStyle.errorProperty);
          },
        ));
      }
      return;
    }
    for (HitTestEntry entry in hitTestResult.path) {
      try {
        entry.target.handleEvent(event.transformed(entry.transform), entry);
      } catch (exception, stack) {
        FlutterError.reportError(FlutterErrorDetailsForPointerEventDispatcher(
          exception: exception,
          stack: stack,
          library: 'gesture library',
          context: ErrorDescription('while dispatching a pointer event'),
          event: event,
          hitTestEntry: entry,
          informationCollector: () sync* {
            yield DiagnosticsProperty<PointerEvent>('Event', event,
                style: DiagnosticsTreeStyle.errorProperty);
            yield DiagnosticsProperty<HitTestTarget>('Target', entry.target,
                style: DiagnosticsTreeStyle.errorProperty);
          },
        ));
      }
    }
  }

  @override
  void handleEvent(PointerEvent event, HitTestEntry entry) {
    pointerRouter.route(event);
    if (event is PointerDownEvent) {
      gestureArena.close(event.pointer);
    } else if (event is PointerUpEvent) {
      gestureArena.sweep(event.pointer);
    } else if (event is PointerSignalEvent) {
      pointerSignalResolver.resolve(event);
    }
  }
}

class FlutterErrorDetailsForPointerEventDispatcher extends FlutterErrorDetails {
  const FlutterErrorDetailsForPointerEventDispatcher({
    dynamic exception,
    StackTrace stack,
    String library,
    DiagnosticsNode context,
    this.event,
    this.hitTestEntry,
    InformationCollector informationCollector,
    bool silent = false,
  }) : super(
            exception: exception,
            stack: stack,
            library: library,
            context: context,
            informationCollector: informationCollector,
            silent: silent);

  final PointerEvent event;

  final HitTestEntry hitTestEntry;
}

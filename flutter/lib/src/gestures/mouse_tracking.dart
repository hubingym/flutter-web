import 'package:flutter_web/ui.dart';

import 'package:flutter_web/foundation.dart'
    show visibleForTesting, ChangeNotifier;
import 'package:flutter_web/scheduler.dart';

import 'events.dart';
import 'pointer_router.dart';

typedef PointerEnterEventListener = void Function(PointerEnterEvent event);

typedef PointerExitEventListener = void Function(PointerExitEvent event);

typedef PointerHoverEventListener = void Function(PointerHoverEvent event);

class MouseTrackerAnnotation {
  const MouseTrackerAnnotation({this.onEnter, this.onHover, this.onExit});

  final PointerEnterEventListener onEnter;

  final PointerHoverEventListener onHover;

  final PointerExitEventListener onExit;

  @override
  String toString() {
    final String none =
        (onEnter == null && onExit == null && onHover == null) ? ' <none>' : '';
    return '[$runtimeType${hashCode.toRadixString(16)}$none'
        '${onEnter == null ? '' : ' onEnter'}'
        '${onHover == null ? '' : ' onHover'}'
        '${onExit == null ? '' : ' onExit'}]';
  }
}

class _TrackedAnnotation {
  _TrackedAnnotation(this.annotation);

  final MouseTrackerAnnotation annotation;

  Set<int> activeDevices = <int>{};
}

typedef MouseDetectorAnnotationFinder = Iterable<MouseTrackerAnnotation>
    Function(Offset offset);

class MouseTracker extends ChangeNotifier {
  MouseTracker(PointerRouter router, this.annotationFinder)
      : assert(router != null),
        assert(annotationFinder != null) {
    router.addGlobalRoute(_handleEvent);
  }

  final MouseDetectorAnnotationFinder annotationFinder;

  final Map<MouseTrackerAnnotation, _TrackedAnnotation> _trackedAnnotations =
      <MouseTrackerAnnotation, _TrackedAnnotation>{};

  void attachAnnotation(MouseTrackerAnnotation annotation) {
    _trackedAnnotations[annotation] = _TrackedAnnotation(annotation);

    _scheduleMousePositionCheck();
  }

  void detachAnnotation(MouseTrackerAnnotation annotation) {
    final _TrackedAnnotation trackedAnnotation = _findAnnotation(annotation);
    for (int deviceId in trackedAnnotation.activeDevices) {
      if (annotation.onExit != null) {
        final PointerEvent event =
            _lastMouseEvent[deviceId] ?? _pendingRemovals[deviceId];
        assert(event != null);
        annotation.onExit(PointerExitEvent.fromMouseEvent(event));
      }
    }
    _trackedAnnotations.remove(annotation);
  }

  bool _postFrameCheckScheduled = false;
  void _scheduleMousePositionCheck() {
    if (_trackedAnnotations.isNotEmpty && !_postFrameCheckScheduled) {
      _postFrameCheckScheduled = true;
      SchedulerBinding.instance.addPostFrameCallback((Duration _) {
        _postFrameCheckScheduled = false;
        collectMousePositions();
      });
      SchedulerBinding.instance.scheduleFrame();
    }
  }

  void _handleEvent(PointerEvent event) {
    if (event.kind != PointerDeviceKind.mouse) {
      return;
    }
    final int deviceId = event.device;
    if (event is PointerAddedEvent) {
      _pendingRemovals.remove(deviceId);
      _addMouseEvent(deviceId, event);
      return;
    }
    if (event is PointerRemovedEvent) {
      _removeMouseEvent(deviceId, event);

      _scheduleMousePositionCheck();
    } else {
      if (event is PointerMoveEvent ||
          event is PointerHoverEvent ||
          event is PointerDownEvent) {
        if (!_lastMouseEvent.containsKey(deviceId) ||
            _lastMouseEvent[deviceId].position != event.position) {
          _scheduleMousePositionCheck();
        }
        _addMouseEvent(deviceId, event);
      }
    }
  }

  _TrackedAnnotation _findAnnotation(MouseTrackerAnnotation annotation) {
    final _TrackedAnnotation trackedAnnotation =
        _trackedAnnotations[annotation];
    assert(
        trackedAnnotation != null,
        'Unable to find annotation $annotation in tracked annotations. '
        'Check that attachAnnotation has been called for all annotated layers.');
    return trackedAnnotation;
  }

  @visibleForTesting
  bool isAnnotationAttached(MouseTrackerAnnotation annotation) {
    return _trackedAnnotations.containsKey(annotation);
  }

  @visibleForTesting
  void collectMousePositions() {
    void exitAnnotation(_TrackedAnnotation trackedAnnotation, int deviceId) {
      if (trackedAnnotation.annotation?.onExit != null &&
          trackedAnnotation.activeDevices.contains(deviceId)) {
        final PointerEvent event =
            _lastMouseEvent[deviceId] ?? _pendingRemovals[deviceId];
        assert(event != null);
        trackedAnnotation.annotation
            .onExit(PointerExitEvent.fromMouseEvent(event));
        trackedAnnotation.activeDevices.remove(deviceId);
      }
    }

    void exitAllDevices(_TrackedAnnotation trackedAnnotation) {
      if (trackedAnnotation.activeDevices.isNotEmpty) {
        final Set<int> deviceIds = trackedAnnotation.activeDevices.toSet();
        for (int deviceId in deviceIds) {
          exitAnnotation(trackedAnnotation, deviceId);
        }
      }
    }

    try {
      if (!mouseIsConnected) {
        _trackedAnnotations.values.forEach(exitAllDevices);
        return;
      }

      for (int deviceId in _lastMouseEvent.keys) {
        final PointerEvent lastEvent = _lastMouseEvent[deviceId];
        final Iterable<MouseTrackerAnnotation> hits =
            annotationFinder(lastEvent.position);

        if (hits.isEmpty) {
          for (_TrackedAnnotation trackedAnnotation
              in _trackedAnnotations.values) {
            exitAnnotation(trackedAnnotation, deviceId);
          }
          continue;
        }

        final Set<_TrackedAnnotation> hitAnnotations = hits
            .map<_TrackedAnnotation>(
                (MouseTrackerAnnotation hit) => _findAnnotation(hit))
            .toSet();
        for (_TrackedAnnotation hitAnnotation in hitAnnotations) {
          if (!hitAnnotation.activeDevices.contains(deviceId)) {
            hitAnnotation.activeDevices.add(deviceId);
            if (hitAnnotation.annotation?.onEnter != null) {
              hitAnnotation.annotation
                  .onEnter(PointerEnterEvent.fromMouseEvent(lastEvent));
            }
          }
          if (hitAnnotation.annotation?.onHover != null &&
              lastEvent is PointerHoverEvent) {
            hitAnnotation.annotation.onHover(lastEvent);
          }

          for (_TrackedAnnotation trackedAnnotation
              in _trackedAnnotations.values) {
            if (hitAnnotations.contains(trackedAnnotation)) {
              continue;
            }
            if (trackedAnnotation.activeDevices.contains(deviceId)) {
              if (trackedAnnotation.annotation?.onExit != null) {
                trackedAnnotation.annotation
                    .onExit(PointerExitEvent.fromMouseEvent(lastEvent));
              }
              trackedAnnotation.activeDevices.remove(deviceId);
            }
          }
        }
      }
    } finally {
      _pendingRemovals.clear();
    }
  }

  void _addMouseEvent(int deviceId, PointerEvent event) {
    final bool wasConnected = mouseIsConnected;
    if (event is PointerAddedEvent) {
      _pendingRemovals.remove(deviceId);
    }
    _lastMouseEvent[deviceId] = event;
    if (mouseIsConnected != wasConnected) {
      notifyListeners();
    }
  }

  void _removeMouseEvent(int deviceId, PointerEvent event) {
    final bool wasConnected = mouseIsConnected;
    assert(event is PointerRemovedEvent);
    _pendingRemovals[deviceId] = event;
    _lastMouseEvent.remove(deviceId);
    if (mouseIsConnected != wasConnected) {
      notifyListeners();
    }
  }

  final Map<int, PointerRemovedEvent> _pendingRemovals =
      <int, PointerRemovedEvent>{};

  final Map<int, PointerEvent> _lastMouseEvent = <int, PointerEvent>{};

  bool get mouseIsConnected => _lastMouseEvent.isNotEmpty;
}

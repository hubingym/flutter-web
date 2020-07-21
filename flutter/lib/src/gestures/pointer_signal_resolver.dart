import 'package:flutter_web/foundation.dart';

import 'events.dart';

typedef PointerSignalResolvedCallback = void Function(PointerSignalEvent event);

class PointerSignalResolver {
  PointerSignalResolvedCallback _firstRegisteredCallback;

  PointerSignalEvent _currentEvent;

  void register(
      PointerSignalEvent event, PointerSignalResolvedCallback callback) {
    assert(event != null);
    assert(callback != null);
    assert(_currentEvent == null || _currentEvent == event);
    if (_firstRegisteredCallback != null) {
      return;
    }
    _currentEvent = event;
    _firstRegisteredCallback = callback;
  }

  void resolve(PointerSignalEvent event) {
    if (_firstRegisteredCallback == null) {
      assert(_currentEvent == null);
      return;
    }
    assert((_currentEvent.original ?? _currentEvent) == event);
    try {
      _firstRegisteredCallback(_currentEvent);
    } catch (exception, stack) {
      FlutterError.reportError(FlutterErrorDetails(
        exception: exception,
        stack: stack,
        library: 'gesture library',
        context: ErrorDescription('while resolving a PointerSignalEvent'),
        informationCollector: () sync* {
          yield DiagnosticsProperty<PointerSignalEvent>('Event', event,
              style: DiagnosticsTreeStyle.errorProperty);
        },
      ));
    }
    _firstRegisteredCallback = null;
    _currentEvent = null;
  }
}

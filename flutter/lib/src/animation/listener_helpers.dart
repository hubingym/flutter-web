import 'package:flutter_web/ui.dart' show VoidCallback;

import 'package:flutter_web/foundation.dart';

import 'animation.dart';

mixin AnimationLazyListenerMixin {
  int _listenerCounter = 0;

  void didRegisterListener() {
    assert(_listenerCounter >= 0);
    if (_listenerCounter == 0) didStartListening();
    _listenerCounter += 1;
  }

  void didUnregisterListener() {
    assert(_listenerCounter >= 1);
    _listenerCounter -= 1;
    if (_listenerCounter == 0) didStopListening();
  }

  @protected
  void didStartListening();

  @protected
  void didStopListening();

  bool get isListening => _listenerCounter > 0;
}

mixin AnimationEagerListenerMixin {
  void didRegisterListener() {}

  void didUnregisterListener() {}

  @mustCallSuper
  void dispose() {}
}

mixin AnimationLocalListenersMixin {
  final ObserverList<VoidCallback> _listeners = ObserverList<VoidCallback>();

  void didRegisterListener();

  void didUnregisterListener();

  void addListener(VoidCallback listener) {
    didRegisterListener();
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    final bool removed = _listeners.remove(listener);
    if (removed) {
      didUnregisterListener();
    }
  }

  void notifyListeners() {
    final List<VoidCallback> localListeners =
        List<VoidCallback>.from(_listeners);
    for (VoidCallback listener in localListeners) {
      try {
        if (_listeners.contains(listener)) listener();
      } catch (exception, stack) {
        FlutterError.reportError(FlutterErrorDetails(
          exception: exception,
          stack: stack,
          library: 'animation library',
          context:
              ErrorDescription('while notifying listeners for $runtimeType'),
          informationCollector: () sync* {
            yield DiagnosticsProperty<AnimationLocalListenersMixin>(
              'The $runtimeType notifying listeners was',
              this,
              style: DiagnosticsTreeStyle.errorProperty,
            );
          },
        ));
      }
    }
  }
}

mixin AnimationLocalStatusListenersMixin {
  final ObserverList<AnimationStatusListener> _statusListeners =
      ObserverList<AnimationStatusListener>();

  void didRegisterListener();

  void didUnregisterListener();

  void addStatusListener(AnimationStatusListener listener) {
    didRegisterListener();
    _statusListeners.add(listener);
  }

  void removeStatusListener(AnimationStatusListener listener) {
    final bool removed = _statusListeners.remove(listener);
    if (removed) {
      didUnregisterListener();
    }
  }

  void notifyStatusListeners(AnimationStatus status) {
    final List<AnimationStatusListener> localListeners =
        List<AnimationStatusListener>.from(_statusListeners);
    for (AnimationStatusListener listener in localListeners) {
      try {
        if (_statusListeners.contains(listener)) listener(status);
      } catch (exception, stack) {
        FlutterError.reportError(FlutterErrorDetails(
          exception: exception,
          stack: stack,
          library: 'animation library',
          context: ErrorDescription(
              'while notifying status listeners for $runtimeType'),
          informationCollector: () sync* {
            yield DiagnosticsProperty<AnimationLocalStatusListenersMixin>(
              'The $runtimeType notifying status listeners was',
              this,
              style: DiagnosticsTreeStyle.errorProperty,
            );
          },
        ));
      }
    }
  }
}

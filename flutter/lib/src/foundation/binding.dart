import 'dart:async';
import 'dart:convert' show json;
import 'dart:developer' as developer;
import 'package:flutter_web/io.dart' show exit;

import 'package:flutter_web/ui.dart' as ui
    show saveCompilationTrace, Window, window, isWeb;

import 'package:meta/meta.dart';

import 'assertions.dart';
import 'basic_types.dart';
import 'constants.dart';
import 'debug.dart';
import 'platform.dart';
import 'print.dart';

typedef ServiceExtensionCallback = Future<Map<String, dynamic>> Function(
    Map<String, String> parameters);

abstract class BindingBase {
  BindingBase() {
    developer.Timeline.startSync('Framework initialization');

    assert(!_debugInitialized);
    initInstances();
    assert(_debugInitialized);

    assert(!_debugServiceExtensionsRegistered);
    initServiceExtensions();
    assert(_debugServiceExtensionsRegistered);

    developer.postEvent('Flutter.FrameworkInitialization', <String, String>{});

    developer.Timeline.finishSync();
  }

  static bool _debugInitialized = false;
  static bool _debugServiceExtensionsRegistered = false;

  ui.Window get window => ui.window;

  @protected
  @mustCallSuper
  void initInstances() {
    assert(!_debugInitialized);
    assert(() {
      _debugInitialized = true;
      return true;
    }());
  }

  @protected
  @mustCallSuper
  void initServiceExtensions() {
    assert(!_debugServiceExtensionsRegistered);

    assert(() {
      registerSignalServiceExtension(
        name: 'reassemble',
        callback: reassembleApplication,
      );
      return true;
    }());

    if (!kReleaseMode && !ui.isWeb) {
      registerSignalServiceExtension(
        name: 'exit',
        callback: _exitApplication,
      );
      registerServiceExtension(
        name: 'saveCompilationTrace',
        callback: (Map<String, String> parameters) async {
          return <String, dynamic>{
            'value': ui.saveCompilationTrace(),
          };
        },
      );
    }

    assert(() {
      if (ui.isWeb) return true;
      const String platformOverrideExtensionName = 'platformOverride';
      registerServiceExtension(
        name: platformOverrideExtensionName,
        callback: (Map<String, String> parameters) async {
          if (parameters.containsKey('value')) {
            switch (parameters['value']) {
              case 'android':
                debugDefaultTargetPlatformOverride = TargetPlatform.android;
                break;
              case 'iOS':
                debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
                break;
              case 'fuchsia':
                debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
                break;
              case 'default':
              default:
                debugDefaultTargetPlatformOverride = null;
            }
            _postExtensionStateChangedEvent(
              platformOverrideExtensionName,
              defaultTargetPlatform
                  .toString()
                  .substring('$TargetPlatform.'.length),
            );
            await reassembleApplication();
          }
          return <String, dynamic>{
            'value': defaultTargetPlatform
                .toString()
                .substring('$TargetPlatform.'.length),
          };
        },
      );
      return true;
    }());
    assert(() {
      _debugServiceExtensionsRegistered = true;
      return true;
    }());
  }

  @protected
  bool get locked => _lockCount > 0;
  int _lockCount = 0;

  @protected
  Future<void> lockEvents(Future<void> callback()) {
    developer.Timeline.startSync('Lock events');

    assert(callback != null);
    _lockCount += 1;
    final Future<void> future = callback();
    assert(future != null,
        'The lockEvents() callback returned null; it should return a Future<void> that completes when the lock is to expire.');
    future.whenComplete(() {
      _lockCount -= 1;
      if (!locked) {
        developer.Timeline.finishSync();
        unlocked();
      }
    });
    return future;
  }

  @protected
  @mustCallSuper
  void unlocked() {
    assert(!locked);
  }

  Future<void> reassembleApplication() {
    return lockEvents(performReassemble);
  }

  @mustCallSuper
  @protected
  Future<void> performReassemble() {
    FlutterError.resetErrorCount();
    return Future<void>.value();
  }

  @protected
  void registerSignalServiceExtension({
    @required String name,
    @required AsyncCallback callback,
  }) {
    assert(name != null);
    assert(callback != null);
    registerServiceExtension(
      name: name,
      callback: (Map<String, String> parameters) async {
        await callback();
        return <String, dynamic>{};
      },
    );
  }

  @protected
  void registerBoolServiceExtension({
    @required String name,
    @required AsyncValueGetter<bool> getter,
    @required AsyncValueSetter<bool> setter,
  }) {
    assert(name != null);
    assert(getter != null);
    assert(setter != null);
    registerServiceExtension(
      name: name,
      callback: (Map<String, String> parameters) async {
        if (parameters.containsKey('enabled')) {
          await setter(parameters['enabled'] == 'true');
          _postExtensionStateChangedEvent(
              name, await getter() ? 'true' : 'false');
        }
        return <String, dynamic>{'enabled': await getter() ? 'true' : 'false'};
      },
    );
  }

  @protected
  void registerNumericServiceExtension({
    @required String name,
    @required AsyncValueGetter<double> getter,
    @required AsyncValueSetter<double> setter,
  }) {
    assert(name != null);
    assert(getter != null);
    assert(setter != null);
    registerServiceExtension(
      name: name,
      callback: (Map<String, String> parameters) async {
        if (parameters.containsKey(name)) {
          await setter(double.parse(parameters[name]));
          _postExtensionStateChangedEvent(name, (await getter()).toString());
        }
        return <String, dynamic>{name: (await getter()).toString()};
      },
    );
  }

  void _postExtensionStateChangedEvent(String name, dynamic value) {
    postEvent(
      'Flutter.ServiceExtensionStateChanged',
      <String, dynamic>{
        'extension': 'ext.flutter.$name',
        'value': value,
      },
    );
  }

  @protected
  void postEvent(String eventKind, Map<String, dynamic> eventData) {
    developer.postEvent(eventKind, eventData);
  }

  @protected
  void registerStringServiceExtension({
    @required String name,
    @required AsyncValueGetter<String> getter,
    @required AsyncValueSetter<String> setter,
  }) {
    assert(name != null);
    assert(getter != null);
    assert(setter != null);
    registerServiceExtension(
      name: name,
      callback: (Map<String, String> parameters) async {
        if (parameters.containsKey('value')) {
          await setter(parameters['value']);
          _postExtensionStateChangedEvent(name, await getter());
        }
        return <String, dynamic>{'value': await getter()};
      },
    );
  }

  @protected
  void registerServiceExtension({
    @required String name,
    @required ServiceExtensionCallback callback,
  }) {
    assert(name != null);
    assert(callback != null);
    final String methodName = 'ext.flutter.$name';
    developer.registerExtension(methodName,
        (String method, Map<String, String> parameters) async {
      assert(method == methodName);
      assert(() {
        if (debugInstrumentationEnabled)
          debugPrint('service extension method received: $method($parameters)');
        return true;
      }());

      await debugInstrumentAction<void>('Wait for outer event loop', () {
        return Future<void>.delayed(Duration.zero);
      });

      dynamic caughtException;
      StackTrace caughtStack;
      Map<String, dynamic> result;
      try {
        result = await callback(parameters);
      } catch (exception, stack) {
        caughtException = exception;
        caughtStack = stack;
      }
      if (caughtException == null) {
        result['type'] = '_extensionType';
        result['method'] = method;
        return developer.ServiceExtensionResponse.result(json.encode(result));
      } else {
        FlutterError.reportError(FlutterErrorDetails(
          exception: caughtException,
          stack: caughtStack,
          context: ErrorDescription(
              'during a service extension callback for "$method"'),
        ));
        return developer.ServiceExtensionResponse.error(
          developer.ServiceExtensionResponse.extensionError,
          json.encode(<String, String>{
            'exception': caughtException.toString(),
            'stack': caughtStack.toString(),
            'method': method,
          }),
        );
      }
    });
  }

  @override
  String toString() => '<$runtimeType>';
}

Future<void> _exitApplication() async {
  exit(0);
}

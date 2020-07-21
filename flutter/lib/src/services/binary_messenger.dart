import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_web/ui.dart' as ui;
import 'package:flutter_web/foundation.dart';

import 'binding.dart';

typedef MessageHandler = Future<ByteData> Function(ByteData message);

abstract class BinaryMessenger {
  const BinaryMessenger();

  Future<void> handlePlatformMessage(String channel, ByteData data,
      ui.PlatformMessageResponseCallback callback);

  Future<ByteData> send(String channel, ByteData message);

  void setMessageHandler(
      String channel, Future<ByteData> handler(ByteData message));

  void setMockMessageHandler(
      String channel, Future<ByteData> handler(ByteData message));
}

@Deprecated('Use ServicesBinding.instance.defaultBinaryMessenger instead.')
BinaryMessenger get defaultBinaryMessenger {
  assert(() {
    if (ServicesBinding.instance == null) {
      throw FlutterError(
          'ServicesBinding.defaultBinaryMessenger was accessed before the '
          'binding was initialized.\n'
          'If you\'re running an application and need to access the binary '
          'messenger before `runApp()` has been called (for example, during '
          'plugin initialization), then you need to explicitly call the '
          '`WidgetsFlutterBinding.ensureInitialized()` first.\n'
          'If you\'re running a test, you can call the '
          '`TestWidgetsFlutterBinding.ensureInitialized()` as the first line in '
          'your test\'s `main()` method to initialize the binding.');
    }
    return true;
  }());
  return ServicesBinding.instance.defaultBinaryMessenger;
}

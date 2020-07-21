import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_web/ui.dart' as ui;

import 'package:flutter_web/foundation.dart';

import 'platform_channel.dart';

typedef Future<ByteData> _MessageHandler(ByteData message);

class BinaryMessages {
  BinaryMessages._();

  static final Map<String, _MessageHandler> _handlers =
      <String, _MessageHandler>{};

  static final Map<String, _MessageHandler> _mockHandlers =
      <String, _MessageHandler>{};

  static Future<ByteData> _sendPlatformMessage(
      String channel, ByteData message) {
    final Completer<ByteData> completer = new Completer<ByteData>();
    ui.window.sendPlatformMessage(channel, message, (ByteData reply) {
      try {
        completer.complete(reply);
      } catch (exception, stack) {
        FlutterError.reportError(new FlutterErrorDetails(
          exception: exception,
          stack: stack,
          library: 'services library',
          context:
              ErrorDescription('during a platform message response callback'),
        ));
      }
    });
    return completer.future;
  }

  static Future<void> handlePlatformMessage(String channel, ByteData data,
      ui.PlatformMessageResponseCallback callback) async {
    ByteData response;
    try {
      final _MessageHandler handler = _handlers[channel];
      if (handler != null) {
        response = await handler(data);
      }
    } catch (exception, stack) {
      FlutterError.reportError(new FlutterErrorDetails(
        exception: exception,
        stack: stack,
        library: 'services library',
        context: ErrorDescription('during a platform message callback'),
      ));
    } finally {
      callback(response);
    }
  }

  static Future<ByteData> send(String channel, ByteData message) {
    final _MessageHandler handler = _mockHandlers[channel];
    if (handler != null) return handler(message);
    return _sendPlatformMessage(channel, message);
  }

  static void setMessageHandler(
      String channel, Future<ByteData> handler(ByteData message)) {
    if (handler == null)
      _handlers.remove(channel);
    else
      _handlers[channel] = handler;
  }

  static void setMockMessageHandler(
      String channel, Future<ByteData> handler(ByteData message)) {
    if (handler == null)
      _mockHandlers.remove(channel);
    else
      _mockHandlers[channel] = handler;
  }
}

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_web/foundation.dart';

import 'message_codec.dart';
import 'message_codecs.dart';
import 'platform_messages.dart';

class BasicMessageChannel<T> {
  const BasicMessageChannel(this.name, this.codec);

  final String name;

  final MessageCodec<T> codec;

  Future<T> send(T message) async {
    return codec.decodeMessage(
        await BinaryMessages.send(name, codec.encodeMessage(message)));
  }

  void setMessageHandler(Future<T> handler(T message)) {
    if (handler == null) {
      BinaryMessages.setMessageHandler(name, null);
    } else {
      BinaryMessages.setMessageHandler(name, (ByteData message) async {
        return codec.encodeMessage(await handler(codec.decodeMessage(message)));
      });
    }
  }

  void setMockMessageHandler(Future<T> handler(T message)) {
    if (handler == null) {
      BinaryMessages.setMockMessageHandler(name, null);
    } else {
      BinaryMessages.setMockMessageHandler(name, (ByteData message) async {
        return codec.encodeMessage(await handler(codec.decodeMessage(message)));
      });
    }
  }
}

class MethodChannel {
  const MethodChannel(this.name, [this.codec = const StandardMethodCodec()]);

  final String name;

  final MethodCodec codec;

  @optionalTypeArgs
  Future<T> invokeMethod<T>(String method, [dynamic arguments]) async {
    assert(method != null);
    final ByteData result = await BinaryMessages.send(
      name,
      codec.encodeMethodCall(MethodCall(method, arguments)),
    );
    if (result == null) {
      throw MissingPluginException(
          'No implementation found for method $method on channel $name');
    }
    final T typedResult = codec.decodeEnvelope(result);
    return typedResult;
  }

  Future<List<T>> invokeListMethod<T>(String method,
      [dynamic arguments]) async {
    final List<dynamic> result =
        await invokeMethod<List<dynamic>>(method, arguments);
    return result.cast<T>();
  }

  Future<Map<K, V>> invokeMapMethod<K, V>(String method,
      [dynamic arguments]) async {
    final Map<dynamic, dynamic> result =
        await invokeMethod<Map<dynamic, dynamic>>(method, arguments);
    return result.cast<K, V>();
  }

  void setMethodCallHandler(Future<dynamic> handler(MethodCall call)) {
    BinaryMessages.setMessageHandler(
      name,
      handler == null
          ? null
          : (ByteData message) => _handleAsMethodCall(message, handler),
    );
  }

  void setMockMethodCallHandler(Future<dynamic> handler(MethodCall call)) {
    BinaryMessages.setMockMessageHandler(
      name,
      handler == null
          ? null
          : (ByteData message) => _handleAsMethodCall(message, handler),
    );
  }

  Future<ByteData> _handleAsMethodCall(
      ByteData message, Future<dynamic> handler(MethodCall call)) async {
    final MethodCall call = codec.decodeMethodCall(message);
    try {
      return codec.encodeSuccessEnvelope(await handler(call));
    } on PlatformException catch (e) {
      return codec.encodeErrorEnvelope(
        code: e.code,
        message: e.message,
        details: e.details,
      );
    } on MissingPluginException {
      return null;
    } catch (e) {
      return codec.encodeErrorEnvelope(
          code: 'error', message: e.toString(), details: null);
    }
  }
}

class OptionalMethodChannel extends MethodChannel {
  const OptionalMethodChannel(String name,
      [MethodCodec codec = const StandardMethodCodec()])
      : super(name, codec);

  @override
  Future<T> invokeMethod<T>(String method, [dynamic arguments]) async {
    try {
      final T result = await super.invokeMethod<T>(method, arguments);
      return result;
    } on MissingPluginException {
      return null;
    }
  }

  @override
  Future<List<T>> invokeListMethod<T>(String method,
      [dynamic arguments]) async {
    final List<dynamic> result =
        await invokeMethod<List<dynamic>>(method, arguments);
    return result.cast<T>();
  }

  @override
  Future<Map<K, V>> invokeMapMethod<K, V>(String method,
      [dynamic arguments]) async {
    final Map<dynamic, dynamic> result =
        await invokeMethod<Map<dynamic, dynamic>>(method, arguments);
    return result.cast<K, V>();
  }
}

class EventChannel {
  const EventChannel(this.name, [this.codec = const StandardMethodCodec()]);

  final String name;

  final MethodCodec codec;

  Stream<dynamic> receiveBroadcastStream([dynamic arguments]) {
    final MethodChannel methodChannel = new MethodChannel(name, codec);
    StreamController<dynamic> controller;
    controller = new StreamController<dynamic>.broadcast(onListen: () async {
      BinaryMessages.setMessageHandler(name, (ByteData reply) async {
        if (reply == null) {
          controller.close();
        } else {
          try {
            controller.add(codec.decodeEnvelope(reply));
          } on PlatformException catch (e) {
            controller.addError(e);
          }
        }
        return Future<dynamic>.value(null);
      });
      try {
        await methodChannel.invokeMethod('listen', arguments);
      } catch (exception, stack) {
        FlutterError.reportError(new FlutterErrorDetails(
          exception: exception,
          stack: stack,
          library: 'services library',
          context: ErrorDescription(
              'while activating platform stream on channel $name'),
        ));
      }
    }, onCancel: () async {
      BinaryMessages.setMessageHandler(name, null);
      try {
        await methodChannel.invokeMethod('cancel', arguments);
      } catch (exception, stack) {
        FlutterError.reportError(new FlutterErrorDetails(
          exception: exception,
          stack: stack,
          library: 'services library',
          context: ErrorDescription(
              'while de-activating platform stream on channel $name'),
        ));
      }
    });
    return controller.stream;
  }
}

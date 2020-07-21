import 'dart:typed_data';

import 'package:flutter_web/foundation.dart';

import 'platform_channel.dart';

export 'dart:typed_data' show ByteData;

abstract class MessageCodec<T> {
  ByteData encodeMessage(T message);

  T decodeMessage(ByteData message);
}

@immutable
class MethodCall {
  const MethodCall(this.method, [this.arguments]) : assert(method != null);

  final String method;

  final dynamic arguments;

  @override
  String toString() => '$runtimeType($method, $arguments)';
}

abstract class MethodCodec {
  ByteData encodeMethodCall(MethodCall methodCall);

  MethodCall decodeMethodCall(ByteData methodCall);

  dynamic decodeEnvelope(ByteData envelope);

  ByteData encodeSuccessEnvelope(dynamic result);

  ByteData encodeErrorEnvelope(
      {@required String code, String message, dynamic details});
}

class PlatformException implements Exception {
  PlatformException({
    @required this.code,
    this.message,
    this.details,
  }) : assert(code != null);

  final String code;

  final String message;

  final dynamic details;

  @override
  String toString() => 'PlatformException($code, $message, $details)';
}

class MissingPluginException implements Exception {
  MissingPluginException([this.message]);

  final String message;

  @override
  String toString() => 'MissingPluginException($message)';
}

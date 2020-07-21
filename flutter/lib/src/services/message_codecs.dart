import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_web/foundation.dart'
    show ReadBuffer, WriteBuffer, required;

import 'message_codec.dart';

class BinaryCodec implements MessageCodec<ByteData> {
  const BinaryCodec();

  @override
  ByteData decodeMessage(ByteData message) => message;

  @override
  ByteData encodeMessage(ByteData message) => message;
}

class StringCodec implements MessageCodec<String> {
  const StringCodec();

  @override
  String decodeMessage(ByteData message) {
    if (message == null) return null;
    return utf8.decoder.convert(message.buffer
        .asUint8List(message.offsetInBytes, message.lengthInBytes));
  }

  @override
  ByteData encodeMessage(String message) {
    if (message == null) return null;
    final Uint8List encoded = utf8.encoder.convert(message);
    return encoded.buffer.asByteData();
  }
}

class JSONMessageCodec implements MessageCodec<dynamic> {
  const JSONMessageCodec();

  @override
  ByteData encodeMessage(dynamic message) {
    if (message == null) return null;
    return const StringCodec().encodeMessage(json.encode(message));
  }

  @override
  dynamic decodeMessage(ByteData message) {
    if (message == null) return message;
    return json.decode(const StringCodec().decodeMessage(message));
  }
}

class JSONMethodCodec implements MethodCodec {
  const JSONMethodCodec();

  @override
  ByteData encodeMethodCall(MethodCall call) {
    return const JSONMessageCodec().encodeMessage(<String, dynamic>{
      'method': call.method,
      'args': call.arguments,
    });
  }

  @override
  MethodCall decodeMethodCall(ByteData methodCall) {
    final dynamic decoded = const JSONMessageCodec().decodeMessage(methodCall);
    if (decoded is! Map)
      throw FormatException('Expected method call Map, got $decoded');
    final dynamic method = decoded['method'];
    final dynamic arguments = decoded['args'];
    if (method is String) return MethodCall(method, arguments);
    throw FormatException('Invalid method call: $decoded');
  }

  @override
  dynamic decodeEnvelope(ByteData envelope) {
    final dynamic decoded = const JSONMessageCodec().decodeMessage(envelope);
    if (decoded is! List)
      throw FormatException('Expected envelope List, got $decoded');
    if (decoded.length == 1) return decoded[0];
    if (decoded.length == 3 &&
        decoded[0] is String &&
        (decoded[1] == null || decoded[1] is String))
      throw PlatformException(
        code: decoded[0],
        message: decoded[1],
        details: decoded[2],
      );
    throw FormatException('Invalid envelope: $decoded');
  }

  @override
  ByteData encodeSuccessEnvelope(dynamic result) {
    return const JSONMessageCodec().encodeMessage(<dynamic>[result]);
  }

  @override
  ByteData encodeErrorEnvelope(
      {@required String code, String message, dynamic details}) {
    assert(code != null);
    return const JSONMessageCodec()
        .encodeMessage(<dynamic>[code, message, details]);
  }
}

class StandardMessageCodec implements MessageCodec<dynamic> {
  const StandardMessageCodec();

  static const int _valueNull = 0;
  static const int _valueTrue = 1;
  static const int _valueFalse = 2;
  static const int _valueInt32 = 3;
  static const int _valueInt64 = 4;
  static const int _valueLargeInt = 5;
  static const int _valueFloat64 = 6;
  static const int _valueString = 7;
  static const int _valueUint8List = 8;
  static const int _valueInt32List = 9;
  static const int _valueInt64List = 10;
  static const int _valueFloat64List = 11;
  static const int _valueList = 12;
  static const int _valueMap = 13;

  @override
  ByteData encodeMessage(dynamic message) {
    if (message == null) return null;
    final WriteBuffer buffer = WriteBuffer();
    writeValue(buffer, message);
    return buffer.done();
  }

  @override
  dynamic decodeMessage(ByteData message) {
    if (message == null) return null;
    final ReadBuffer buffer = ReadBuffer(message);
    final dynamic result = readValue(buffer);
    if (buffer.hasRemaining) throw const FormatException('Message corrupted');
    return result;
  }

  void writeValue(WriteBuffer buffer, dynamic value) {
    if (value == null) {
      buffer.putUint8(_valueNull);
    } else if (value is bool) {
      buffer.putUint8(value ? _valueTrue : _valueFalse);
    } else if (value is double) {
      buffer.putUint8(_valueFloat64);
      buffer.putFloat64(value);
    } else if (value is int) {
      if (-0x7fffffff - 1 <= value && value <= 0x7fffffff) {
        buffer.putUint8(_valueInt32);
        buffer.putInt32(value);
      } else {
        buffer.putUint8(_valueInt64);
        buffer.putInt64(value);
      }
    } else if (value is String) {
      buffer.putUint8(_valueString);
      final List<int> bytes = utf8.encoder.convert(value);
      writeSize(buffer, bytes.length);
      buffer.putUint8List(bytes);
    } else if (value is Uint8List) {
      buffer.putUint8(_valueUint8List);
      writeSize(buffer, value.length);
      buffer.putUint8List(value);
    } else if (value is Int32List) {
      buffer.putUint8(_valueInt32List);
      writeSize(buffer, value.length);
      buffer.putInt32List(value);
    } else if (value is Int64List) {
      buffer.putUint8(_valueInt64List);
      writeSize(buffer, value.length);
      buffer.putInt64List(value);
    } else if (value is Float64List) {
      buffer.putUint8(_valueFloat64List);
      writeSize(buffer, value.length);
      buffer.putFloat64List(value);
    } else if (value is List) {
      buffer.putUint8(_valueList);
      writeSize(buffer, value.length);
      for (final dynamic item in value) {
        writeValue(buffer, item);
      }
    } else if (value is Map) {
      buffer.putUint8(_valueMap);
      writeSize(buffer, value.length);
      value.forEach((dynamic key, dynamic value) {
        writeValue(buffer, key);
        writeValue(buffer, value);
      });
    } else {
      throw ArgumentError.value(value);
    }
  }

  dynamic readValue(ReadBuffer buffer) {
    if (!buffer.hasRemaining) throw const FormatException('Message corrupted');
    final int type = buffer.getUint8();
    return readValueOfType(type, buffer);
  }

  dynamic readValueOfType(int type, ReadBuffer buffer) {
    switch (type) {
      case _valueNull:
        return null;
      case _valueTrue:
        return true;
      case _valueFalse:
        return false;
      case _valueInt32:
        return buffer.getInt32();
      case _valueInt64:
        return buffer.getInt64();
      case _valueFloat64:
        return buffer.getFloat64();
      case _valueLargeInt:
      case _valueString:
        final int length = readSize(buffer);
        return utf8.decoder.convert(buffer.getUint8List(length));
      case _valueUint8List:
        final int length = readSize(buffer);
        return buffer.getUint8List(length);
      case _valueInt32List:
        final int length = readSize(buffer);
        return buffer.getInt32List(length);
      case _valueInt64List:
        final int length = readSize(buffer);
        return buffer.getInt64List(length);
      case _valueFloat64List:
        final int length = readSize(buffer);
        return buffer.getFloat64List(length);
      case _valueList:
        final int length = readSize(buffer);
        final dynamic result = List<dynamic>(length);
        for (int i = 0; i < length; i++) result[i] = readValue(buffer);
        return result;
      case _valueMap:
        final int length = readSize(buffer);
        final dynamic result = <dynamic, dynamic>{};
        for (int i = 0; i < length; i++)
          result[readValue(buffer)] = readValue(buffer);
        return result;
      default:
        throw const FormatException('Message corrupted');
    }
  }

  void writeSize(WriteBuffer buffer, int value) {
    assert(0 <= value && value <= 0xffffffff);
    if (value < 254) {
      buffer.putUint8(value);
    } else if (value <= 0xffff) {
      buffer.putUint8(254);
      buffer.putUint16(value);
    } else {
      buffer.putUint8(255);
      buffer.putUint32(value);
    }
  }

  int readSize(ReadBuffer buffer) {
    final int value = buffer.getUint8();
    switch (value) {
      case 254:
        return buffer.getUint16();
      case 255:
        return buffer.getUint32();
      default:
        return value;
    }
  }
}

class StandardMethodCodec implements MethodCodec {
  const StandardMethodCodec([this.messageCodec = const StandardMessageCodec()]);

  final StandardMessageCodec messageCodec;

  @override
  ByteData encodeMethodCall(MethodCall call) {
    final WriteBuffer buffer = WriteBuffer();
    messageCodec.writeValue(buffer, call.method);
    messageCodec.writeValue(buffer, call.arguments);
    return buffer.done();
  }

  @override
  MethodCall decodeMethodCall(ByteData methodCall) {
    final ReadBuffer buffer = ReadBuffer(methodCall);
    final dynamic method = messageCodec.readValue(buffer);
    final dynamic arguments = messageCodec.readValue(buffer);
    if (method is String && !buffer.hasRemaining)
      return MethodCall(method, arguments);
    else
      throw const FormatException('Invalid method call');
  }

  @override
  ByteData encodeSuccessEnvelope(dynamic result) {
    final WriteBuffer buffer = WriteBuffer();
    buffer.putUint8(0);
    messageCodec.writeValue(buffer, result);
    return buffer.done();
  }

  @override
  ByteData encodeErrorEnvelope(
      {@required String code, String message, dynamic details}) {
    final WriteBuffer buffer = WriteBuffer();
    buffer.putUint8(1);
    messageCodec.writeValue(buffer, code);
    messageCodec.writeValue(buffer, message);
    messageCodec.writeValue(buffer, details);
    return buffer.done();
  }

  @override
  dynamic decodeEnvelope(ByteData envelope) {
    if (envelope.lengthInBytes == 0)
      throw const FormatException('Expected envelope, got nothing');
    final ReadBuffer buffer = ReadBuffer(envelope);
    if (buffer.getUint8() == 0) return messageCodec.readValue(buffer);
    final dynamic errorCode = messageCodec.readValue(buffer);
    final dynamic errorMessage = messageCodec.readValue(buffer);
    final dynamic errorDetails = messageCodec.readValue(buffer);
    if (errorCode is String &&
        (errorMessage == null || errorMessage is String) &&
        !buffer.hasRemaining)
      throw PlatformException(
          code: errorCode, message: errorMessage, details: errorDetails);
    else
      throw const FormatException('Invalid envelope');
  }
}

import 'dart:async';
import 'dart:html' show HttpRequest;
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/services.dart';

abstract class AssetBundle {
  Future<ByteData> load(String key);

  Future<String> loadString(String key, {bool cache = true}) async {
    final ByteData data = await load(key);
    if (data == null) throw new FlutterError('Unable to load asset: $key');
    if (data.lengthInBytes < 20 * 1024) {
      return utf8.decode(data.buffer.asUint8List());
    }

    return compute(_utf8decode, data, debugLabel: 'UTF8 decode for "$key"');
  }

  static String _utf8decode(ByteData data) {
    return utf8.decode(data.buffer.asUint8List());
  }

  Future<T> loadStructuredData<T>(String key, Future<T> parser(String value));

  void evict(String key) {}

  @override
  String toString() => '${describeIdentity(this)}()';
}

class NetworkAssetBundle extends AssetBundle {
  NetworkAssetBundle(Uri baseUrl) : _baseUrl = baseUrl;

  final Uri _baseUrl;

  Uri _urlFromKey(String key) => _baseUrl.resolve(key);

  @override
  Future<ByteData> load(String key) async {
    final HttpRequest request =
        await HttpRequest.request(_urlFromKey(key).toString(), method: 'GET');
    final ByteBuffer buffer = request.response;
    return buffer.asByteData();
  }

  @override
  Future<T> loadStructuredData<T>(
      String key, Future<T> parser(String value)) async {
    assert(key != null);
    assert(parser != null);
    return parser(await loadString(key));
  }
}

abstract class CachingAssetBundle extends AssetBundle {
  final Map<String, Future<String>> _stringCache = <String, Future<String>>{};
  final Map<String, Future<dynamic>> _structuredDataCache =
      <String, Future<dynamic>>{};

  @override
  Future<String> loadString(String key, {bool cache = true}) {
    if (cache)
      return _stringCache.putIfAbsent(key, () => super.loadString(key));
    return super.loadString(key);
  }

  @override
  Future<T> loadStructuredData<T>(String key, Future<T> parser(String value)) {
    assert(key != null);
    assert(parser != null);
    if (_structuredDataCache.containsKey(key)) return _structuredDataCache[key];
    Completer<T> completer;
    Future<T> result;
    loadString(key, cache: false).then<T>(parser).then<void>((T value) {
      result = new SynchronousFuture<T>(value);
      _structuredDataCache[key] = result;
      if (completer != null) {
        completer.complete(value);
      }
    });
    if (result != null) {
      return result;
    }

    completer = new Completer<T>();
    _structuredDataCache[key] = completer.future;
    return completer.future;
  }

  @override
  void evict(String key) {
    _stringCache.remove(key);
    _structuredDataCache.remove(key);
  }
}

class PlatformAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final Uint8List encoded =
        utf8.encoder.convert(new Uri(path: Uri.encodeFull(key)).path);
    final ByteData asset = await BinaryMessages.send(
        'flutter/assets', encoded.buffer.asByteData());
    if (asset == null) throw new FlutterError('Unable to load asset: $key');
    return asset;
  }
}

AssetBundle _initRootBundle() {
  return new PlatformAssetBundle();
}

final AssetBundle rootBundle = _initRootBundle();

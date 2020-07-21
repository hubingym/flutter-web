import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:flutter_web/ui.dart' show hashValues;

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/services.dart';

import 'image_provider.dart';

const String _kAssetManifestFileName = 'AssetManifest.json';

class AssetImage extends AssetBundleImageProvider {
  const AssetImage(
    this.assetName, {
    this.bundle,
    this.package,
  }) : assert(assetName != null);

  final String assetName;

  String get keyName =>
      package == null ? assetName : 'packages/$package/$assetName';

  final AssetBundle bundle;

  final String package;

  static const double _naturalResolution = 1.0;

  @override
  Future<AssetBundleImageKey> obtainKey(ImageConfiguration configuration) {
    final AssetBundle chosenBundle =
        bundle ?? configuration.bundle ?? rootBundle;
    Completer<AssetBundleImageKey> completer;
    Future<AssetBundleImageKey> result;

    chosenBundle
        .loadStructuredData<Map<String, List<String>>>(
            _kAssetManifestFileName, _manifestParser)
        .then<void>((Map<String, List<String>> manifest) {
      final String chosenName = _chooseVariant(
          keyName, configuration, manifest == null ? null : manifest[keyName]);
      final double chosenScale = _parseScale(chosenName);
      final AssetBundleImageKey key = AssetBundleImageKey(
          bundle: chosenBundle, name: chosenName, scale: chosenScale);
      if (completer != null) {
        completer.complete(key);
      } else {
        result = SynchronousFuture<AssetBundleImageKey>(key);
      }
    }).catchError((dynamic error, StackTrace stack) {
      assert(completer != null);
      assert(result == null);
      completer.completeError(error, stack);
    });
    if (result != null) {
      return result;
    }

    completer = Completer<AssetBundleImageKey>();
    return completer.future;
  }

  static Future<Map<String, List<String>>> _manifestParser(String jsonData) {
    if (jsonData == null) return null;

    final Map<String, dynamic> parsedJson = json.decode(jsonData);
    final Iterable<String> keys = parsedJson.keys;
    final Map<String, List<String>> parsedManifest =
        Map<String, List<String>>.fromIterables(
            keys,
            keys.map<List<String>>(
                (String key) => List<String>.from(parsedJson[key])));

    return SynchronousFuture<Map<String, List<String>>>(parsedManifest);
  }

  String _chooseVariant(
      String main, ImageConfiguration config, List<String> candidates) {
    if (config.devicePixelRatio == null ||
        candidates == null ||
        candidates.isEmpty) return main;

    final SplayTreeMap<double, String> mapping = SplayTreeMap<double, String>();
    for (String candidate in candidates)
      mapping[_parseScale(candidate)] = candidate;

    return _findNearest(mapping, config.devicePixelRatio);
  }

  String _findNearest(SplayTreeMap<double, String> candidates, double value) {
    if (candidates.containsKey(value)) return candidates[value];
    final double lower = candidates.lastKeyBefore(value);
    final double upper = candidates.firstKeyAfter(value);
    if (lower == null) return candidates[upper];
    if (upper == null) return candidates[lower];
    if (value > (lower + upper) / 2)
      return candidates[upper];
    else
      return candidates[lower];
  }

  static final RegExp _extractRatioRegExp = RegExp(r'/?(\d+(\.\d*)?)x$');

  double _parseScale(String key) {
    if (key == assetName) {
      return _naturalResolution;
    }

    final assetDir = key.substring(0, key.lastIndexOf('/'));

    final Match match = _extractRatioRegExp.firstMatch(assetDir);
    if (match != null && match.groupCount > 0)
      return double.parse(match.group(1));
    return _naturalResolution;
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) return false;
    final AssetImage typedOther = other;
    return keyName == typedOther.keyName && bundle == typedOther.bundle;
  }

  @override
  int get hashCode => hashValues(keyName, bundle);

  @override
  String toString() => '$runtimeType(bundle: $bundle, name: "$keyName")';
}

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_web/ui.dart' as ui
    show webOnlyInstantiateImageCodecFromUrl, Codec;
import 'package:flutter_web/ui.dart'
    show Size, Locale, TextDirection, hashValues;

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/services.dart';

import 'binding.dart';
import 'image_cache.dart';
import 'image_stream.dart';

@immutable
class ImageConfiguration {
  const ImageConfiguration({
    this.bundle,
    this.devicePixelRatio,
    this.locale,
    this.textDirection,
    this.size,
    this.platform,
  });

  ImageConfiguration copyWith({
    AssetBundle bundle,
    double devicePixelRatio,
    Locale locale,
    TextDirection textDirection,
    Size size,
    String platform,
  }) {
    return ImageConfiguration(
      bundle: bundle ?? this.bundle,
      devicePixelRatio: devicePixelRatio ?? this.devicePixelRatio,
      locale: locale ?? this.locale,
      textDirection: textDirection ?? this.textDirection,
      size: size ?? this.size,
      platform: platform ?? this.platform,
    );
  }

  final AssetBundle bundle;

  final double devicePixelRatio;

  final Locale locale;

  final TextDirection textDirection;

  final Size size;

  final TargetPlatform platform;

  static const ImageConfiguration empty = ImageConfiguration();

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) return false;
    final ImageConfiguration typedOther = other;
    return typedOther.bundle == bundle &&
        typedOther.devicePixelRatio == devicePixelRatio &&
        typedOther.locale == locale &&
        typedOther.textDirection == textDirection &&
        typedOther.size == size &&
        typedOther.platform == platform;
  }

  @override
  int get hashCode =>
      hashValues(bundle, devicePixelRatio, locale, size, platform);

  @override
  String toString() {
    final StringBuffer result = StringBuffer();
    result.write('ImageConfiguration(');
    bool hasArguments = false;
    if (bundle != null) {
      if (hasArguments) result.write(', ');
      result.write('bundle: $bundle');
      hasArguments = true;
    }
    if (devicePixelRatio != null) {
      if (hasArguments) result.write(', ');
      result.write('devicePixelRatio: ${devicePixelRatio.toStringAsFixed(1)}');
      hasArguments = true;
    }
    if (locale != null) {
      if (hasArguments) result.write(', ');
      result.write('locale: $locale');
      hasArguments = true;
    }
    if (textDirection != null) {
      if (hasArguments) result.write(', ');
      result.write('textDirection: $textDirection');
      hasArguments = true;
    }
    if (size != null) {
      if (hasArguments) result.write(', ');
      result.write('size: $size');
      hasArguments = true;
    }
    if (platform != null) {
      if (hasArguments) result.write(', ');
      result.write('platform: ${describeEnum(platform)}');
      hasArguments = true;
    }
    result.write(')');
    return result.toString();
  }
}

@optionalTypeArgs
abstract class ImageProvider<T> {
  const ImageProvider();

  ImageStream resolve(ImageConfiguration configuration) {
    assert(configuration != null);
    final ImageStream stream = ImageStream();
    T obtainedKey;
    obtainKey(configuration).then<void>((T key) {
      obtainedKey = key;
      stream.setCompleter(PaintingBinding.instance.imageCache
          .putIfAbsent(key, () => load(key)));
    }).catchError((dynamic exception, StackTrace stack) async {
      FlutterError.reportError(FlutterErrorDetails(
        exception: exception,
        stack: stack,
        library: 'services library',
        context: ErrorDescription('while resolving an image'),
        silent: true,
        informationCollector: () sync* {
          yield DiagnosticsProperty<ImageProvider>('Image provider', this);
          yield DiagnosticsProperty<ImageConfiguration>(
              'Image configuration', configuration);
          yield DiagnosticsProperty<T>('Image key', obtainedKey,
              defaultValue: null);
        },
      ));
      return null;
    });
    return stream;
  }

  Future<bool> evict(
      {ImageCache cache,
      ImageConfiguration configuration = ImageConfiguration.empty}) async {
    cache ??= imageCache;
    final T key = await obtainKey(configuration);
    return cache.evict(key);
  }

  @protected
  Future<T> obtainKey(ImageConfiguration configuration);

  @protected
  ImageStreamCompleter load(T key);

  @override
  String toString() => '$runtimeType()';
}

@immutable
class AssetBundleImageKey {
  const AssetBundleImageKey(
      {@required this.bundle, @required this.name, @required this.scale})
      : assert(bundle != null),
        assert(name != null),
        assert(scale != null);

  final AssetBundle bundle;

  final String name;

  final double scale;

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) return false;
    final AssetBundleImageKey typedOther = other;
    return bundle == typedOther.bundle &&
        name == typedOther.name &&
        scale == typedOther.scale;
  }

  @override
  int get hashCode => hashValues(bundle, name, scale);

  @override
  String toString() =>
      '$runtimeType(bundle: $bundle, name: "$name", scale: $scale)';
}

abstract class AssetBundleImageProvider
    extends ImageProvider<AssetBundleImageKey> {
  const AssetBundleImageProvider();

  @override
  ImageStreamCompleter load(AssetBundleImageKey key) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key),
      scale: key.scale,
      informationCollector: () sync* {
        yield DiagnosticsProperty<ImageProvider>('Image provider', this);
        yield DiagnosticsProperty<AssetBundleImageKey>('Image key', key);
      },
    );
  }

  @protected
  Future<ui.Codec> _loadAsync(AssetBundleImageKey key) async {
    final ByteData data = await key.bundle.load(key.name);
    if (data == null) throw 'Unable to read data';
    return await PaintingBinding.instance
        .instantiateImageCodec(data.buffer.asUint8List());
  }
}

class NetworkImage extends ImageProvider<NetworkImage> {
  const NetworkImage(this.url, {this.scale = 1.0, this.headers})
      : assert(url != null),
        assert(scale != null);

  final String url;

  final double scale;

  final Map<String, String> headers;

  @override
  Future<NetworkImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<NetworkImage>(this);
  }

  @override
  ImageStreamCompleter load(NetworkImage key) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key),
      scale: key.scale,
      informationCollector: () sync* {
        yield DiagnosticsProperty<ImageProvider>('Image provider', this);
        yield DiagnosticsProperty<NetworkImage>('Image key', key);
      },
    );
  }

  Future<ui.Codec> _loadAsync(NetworkImage key) async {
    assert(key == this);

    final Uri resolved = Uri.base.resolve(key.url);
    return ui.webOnlyInstantiateImageCodecFromUrl(resolved);
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) return false;
    final NetworkImage typedOther = other;
    return url == typedOther.url && scale == typedOther.scale;
  }

  @override
  int get hashCode => hashValues(url, scale);

  @override
  String toString() => '$runtimeType("$url", scale: $scale)';
}

class MemoryImage extends ImageProvider<MemoryImage> {
  const MemoryImage(this.bytes, {this.scale = 1.0})
      : assert(bytes != null),
        assert(scale != null);

  final Uint8List bytes;

  final double scale;

  @override
  Future<MemoryImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<MemoryImage>(this);
  }

  @override
  ImageStreamCompleter load(MemoryImage key) {
    return MultiFrameImageStreamCompleter(
        codec: _loadAsync(key), scale: key.scale);
  }

  Future<ui.Codec> _loadAsync(MemoryImage key) {
    assert(key == this);

    return PaintingBinding.instance.instantiateImageCodec(bytes);
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) return false;
    final MemoryImage typedOther = other;
    return bytes == typedOther.bytes && scale == typedOther.scale;
  }

  @override
  int get hashCode => hashValues(bytes.hashCode, scale);

  @override
  String toString() =>
      '$runtimeType(${describeIdentity(bytes)}, scale: $scale)';
}

class ExactAssetImage extends AssetBundleImageProvider {
  const ExactAssetImage(
    this.assetName, {
    this.scale = 1.0,
    this.bundle,
    this.package,
  })  : assert(assetName != null),
        assert(scale != null);

  final String assetName;

  String get keyName =>
      package == null ? assetName : 'packages/$package/$assetName';

  final double scale;

  final AssetBundle bundle;

  final String package;

  @override
  Future<AssetBundleImageKey> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<AssetBundleImageKey>(AssetBundleImageKey(
        bundle: bundle ?? configuration.bundle ?? rootBundle,
        name: keyName,
        scale: scale));
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) return false;
    final ExactAssetImage typedOther = other;
    return keyName == typedOther.keyName &&
        scale == typedOther.scale &&
        bundle == typedOther.bundle;
  }

  @override
  int get hashCode => hashValues(keyName, scale, bundle);

  @override
  String toString() =>
      '$runtimeType(name: "$keyName", scale: $scale, bundle: $bundle)';
}

import 'dart:typed_data' show Uint8List;
import 'package:flutter_web/ui.dart' as ui show instantiateImageCodec, Codec;
import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/services.dart' show ServicesBinding;

import 'image_cache.dart';

const double _kDefaultDecodedCacheRatioCap = 25.0;

mixin PaintingBinding on BindingBase, ServicesBinding {
  @override
  void initInstances() {
    super.initInstances();
    _instance = this;
    _imageCache = createImageCache();
  }

  static PaintingBinding get instance => _instance;
  static PaintingBinding _instance;

  ImageCache get imageCache => _imageCache;
  ImageCache _imageCache;

  @protected
  ImageCache createImageCache() => ImageCache();

  double get decodedCacheRatioCap => _kDecodedCacheRatioCap;
  double _kDecodedCacheRatioCap = _kDefaultDecodedCacheRatioCap;

  set decodedCacheRatioCap(double value) {
    assert(value != null);
    assert(value >= 0.0);
    _kDecodedCacheRatioCap = value;
  }

  Future<ui.Codec> instantiateImageCodec(Uint8List list) {
    return ui.instantiateImageCodec(list,
        decodedCacheRatioCap: decodedCacheRatioCap);
  }

  @override
  void evict(String asset) {
    super.evict(asset);
    imageCache.clear();
  }
}

ImageCache get imageCache => PaintingBinding.instance.imageCache;

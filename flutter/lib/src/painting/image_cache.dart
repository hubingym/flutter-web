import 'image_stream.dart';

const int _kDefaultSize = 1000;
const int _kDefaultSizeBytes = 100 << 20;

class ImageCache {
  final Map<Object, ImageStreamCompleter> _pendingImages =
      <Object, ImageStreamCompleter>{};
  final Map<Object, _CachedImage> _cache = <Object, _CachedImage>{};

  int get maximumSize => _maximumSize;
  int _maximumSize = _kDefaultSize;

  set maximumSize(int value) {
    assert(value != null);
    assert(value >= 0);
    if (value == maximumSize) return;
    _maximumSize = value;
    if (maximumSize == 0) {
      _cache.clear();
      _currentSizeBytes = 0;
    } else {
      _checkCacheSize();
    }
  }

  int get currentSize => _cache.length;

  int get maximumSizeBytes => _maximumSizeBytes;
  int _maximumSizeBytes = _kDefaultSizeBytes;

  set maximumSizeBytes(int value) {
    assert(value != null);
    assert(value >= 0);
    if (value == _maximumSizeBytes) return;
    _maximumSizeBytes = value;
    if (_maximumSizeBytes == 0) {
      _cache.clear();
      _currentSizeBytes = 0;
    } else {
      _checkCacheSize();
    }
  }

  int get currentSizeBytes => _currentSizeBytes;
  int _currentSizeBytes = 0;

  void clear() {
    _cache.clear();
    _currentSizeBytes = 0;
  }

  bool evict(Object key) {
    final _CachedImage image = _cache.remove(key);
    if (image != null) {
      _currentSizeBytes -= image.sizeBytes;
      return true;
    }
    return false;
  }

  ImageStreamCompleter putIfAbsent(Object key, ImageStreamCompleter loader()) {
    assert(key != null);
    assert(loader != null);
    ImageStreamCompleter result = _pendingImages[key];

    if (result != null) return result;

    final _CachedImage image = _cache.remove(key);
    if (image != null) {
      _cache[key] = image;
      return image.completer;
    }
    result = loader();
    void listener(ImageInfo info, bool syncCall) {
      final int imageSize =
          info?.image == null ? 0 : info.image.height * info.image.width * 4;
      final _CachedImage image = _CachedImage(result, imageSize);

      if (maximumSizeBytes > 0 && imageSize > maximumSizeBytes) {
        _maximumSizeBytes = imageSize + 1000;
      }
      _currentSizeBytes += imageSize;
      _pendingImages.remove(key);
      _cache[key] = image;
      result.removeListener(listener);
      _checkCacheSize();
    }

    if (maximumSize > 0 && maximumSizeBytes > 0) {
      _pendingImages[key] = result;
      result.addListener(listener);
    }
    return result;
  }

  void _checkCacheSize() {
    while (
        _currentSizeBytes > _maximumSizeBytes || _cache.length > _maximumSize) {
      final Object key = _cache.keys.first;
      final _CachedImage image = _cache[key];
      _currentSizeBytes -= image.sizeBytes;
      _cache.remove(key);
    }
    assert(_currentSizeBytes >= 0);
    assert(_cache.length <= maximumSize);
    assert(_currentSizeBytes <= maximumSizeBytes);
  }
}

class _CachedImage {
  _CachedImage(this.completer, this.sizeBytes);

  final ImageStreamCompleter completer;
  final int sizeBytes;
}

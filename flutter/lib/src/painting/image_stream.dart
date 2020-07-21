import 'dart:async';
import 'package:flutter_web/ui.dart' as ui show Image, Codec, FrameInfo;
import 'package:flutter_web/ui.dart' show hashValues;

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/scheduler.dart';

@immutable
class ImageInfo {
  const ImageInfo({@required this.image, this.scale = 1.0})
      : assert(image != null),
        assert(scale != null);

  final ui.Image image;

  final double scale;

  @override
  String toString() => '$image @ ${scale.toStringAsFixed(1)}x';

  @override
  int get hashCode => hashValues(image, scale);

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    final ImageInfo typedOther = other;
    return typedOther.image == image && typedOther.scale == scale;
  }
}

typedef ImageListener = void Function(ImageInfo image, bool synchronousCall);

typedef ImageErrorListener = void Function(
    dynamic exception, StackTrace stackTrace);

class _ImageListenerPair {
  _ImageListenerPair(this.listener, this.errorListener);
  final ImageListener listener;
  final ImageErrorListener errorListener;
}

class ImageStream extends Diagnosticable {
  ImageStream();

  ImageStreamCompleter get completer => _completer;
  ImageStreamCompleter _completer;

  List<_ImageListenerPair> _listeners;

  void setCompleter(ImageStreamCompleter value) {
    assert(_completer == null);
    _completer = value;
    if (_listeners != null) {
      final List<_ImageListenerPair> initialListeners = _listeners;
      _listeners = null;
      for (_ImageListenerPair listenerPair in initialListeners) {
        _completer.addListener(
          listenerPair.listener,
          onError: listenerPair.errorListener,
        );
      }
    }
  }

  void addListener(ImageListener listener, {ImageErrorListener onError}) {
    if (_completer != null)
      return _completer.addListener(listener, onError: onError);
    _listeners ??= <_ImageListenerPair>[];
    _listeners.add(_ImageListenerPair(listener, onError));
  }

  void removeListener(ImageListener listener) {
    if (_completer != null) return _completer.removeListener(listener);
    assert(_listeners != null);
    for (int i = 0; i < _listeners.length; ++i) {
      if (_listeners[i].listener == listener) {
        _listeners.removeAt(i);
        continue;
      }
    }
  }

  Object get key => _completer != null ? _completer : this;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ObjectFlagProperty<ImageStreamCompleter>(
      'completer',
      _completer,
      ifPresent: _completer?.toStringShort(),
      ifNull: 'unresolved',
    ));
    properties.add(ObjectFlagProperty<List<_ImageListenerPair>>(
      'listeners',
      _listeners,
      ifPresent:
          '${_listeners?.length} listener${_listeners?.length == 1 ? "" : "s"}',
      ifNull: 'no listeners',
      level: _completer != null ? DiagnosticLevel.hidden : DiagnosticLevel.info,
    ));
    _completer?.debugFillProperties(properties);
  }
}

abstract class ImageStreamCompleter extends Diagnosticable {
  final List<_ImageListenerPair> _listeners = <_ImageListenerPair>[];
  ImageInfo _currentImage;
  FlutterErrorDetails _currentError;

  void addListener(ImageListener listener, {ImageErrorListener onError}) {
    _listeners.add(_ImageListenerPair(listener, onError));
    if (_currentImage != null) {
      try {
        listener(_currentImage, true);
      } catch (exception, stack) {
        reportError(
          context: 'by a synchronously-called image listener',
          exception: exception,
          stack: stack,
        );
      }
    }
    if (_currentError != null && onError != null) {
      try {
        onError(_currentError.exception, _currentError.stack);
      } catch (exception, stack) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: exception,
            library: 'image resource service',
            context: ErrorDescription(
                'by a synchronously-called image error listener'),
            stack: stack,
          ),
        );
      }
    }
  }

  void removeListener(ImageListener listener) {
    for (int i = 0; i < _listeners.length; ++i) {
      if (_listeners[i].listener == listener) {
        _listeners.removeAt(i);
        continue;
      }
    }
  }

  @protected
  void setImage(ImageInfo image) {
    _currentImage = image;
    if (_listeners.isEmpty) return;
    final List<ImageListener> localListeners = _listeners
        .map<ImageListener>(
            (_ImageListenerPair listenerPair) => listenerPair.listener)
        .toList();
    for (ImageListener listener in localListeners) {
      try {
        listener(image, false);
      } catch (exception, stack) {
        reportError(
          context: 'by an image listener',
          exception: exception,
          stack: stack,
        );
      }
    }
  }

  @protected
  void reportError({
    String context,
    dynamic exception,
    StackTrace stack,
    InformationCollector informationCollector,
    bool silent = false,
  }) {
    _currentError = FlutterErrorDetails(
      exception: exception,
      stack: stack,
      library: 'image resource service',
      context: ErrorDescription(context),
      informationCollector: informationCollector,
      silent: silent,
    );

    final List<ImageErrorListener> localErrorListeners = _listeners
        .map<ImageErrorListener>(
            (_ImageListenerPair listenerPair) => listenerPair.errorListener)
        .where((ImageErrorListener errorListener) => errorListener != null)
        .toList();

    if (localErrorListeners.isEmpty) {
      FlutterError.reportError(_currentError);
    } else {
      for (ImageErrorListener errorListener in localErrorListeners) {
        try {
          errorListener(exception, stack);
        } catch (exception, stack) {
          FlutterError.reportError(
            FlutterErrorDetails(
              context: ErrorDescription('by an image error listener'),
              library: 'image resource service',
              exception: exception,
              stack: stack,
            ),
          );
        }
      }
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(DiagnosticsProperty<ImageInfo>('current', _currentImage,
        ifNull: 'unresolved', showName: false));
    description.add(ObjectFlagProperty<List<_ImageListenerPair>>(
      'listeners',
      _listeners,
      ifPresent:
          '${_listeners?.length} listener${_listeners?.length == 1 ? "" : "s"}',
    ));
  }
}

class OneFrameImageStreamCompleter extends ImageStreamCompleter {
  OneFrameImageStreamCompleter(Future<ImageInfo> image,
      {InformationCollector informationCollector})
      : assert(image != null) {
    image.then<void>(setImage, onError: (dynamic error, StackTrace stack) {
      reportError(
        context: 'resolving a single-frame image stream',
        exception: error,
        stack: stack,
        informationCollector: informationCollector,
        silent: true,
      );
    });
  }
}

class MultiFrameImageStreamCompleter extends ImageStreamCompleter {
  MultiFrameImageStreamCompleter(
      {@required Future<ui.Codec> codec,
      @required double scale,
      InformationCollector informationCollector})
      : assert(codec != null),
        _informationCollector = informationCollector,
        _scale = scale,
        _framesEmitted = 0,
        _timer = null {
    codec.then<void>(_handleCodecReady,
        onError: (dynamic error, StackTrace stack) {
      reportError(
        context: 'resolving an image codec',
        exception: error,
        stack: stack,
        informationCollector: informationCollector,
        silent: true,
      );
    });
  }

  ui.Codec _codec;
  final double _scale;
  final InformationCollector _informationCollector;
  ui.FrameInfo _nextFrame;

  Duration _shownTimestamp;

  Duration _frameDuration;

  int _framesEmitted;
  Timer _timer;

  void _handleCodecReady(ui.Codec codec) {
    _codec = codec;
    assert(_codec != null);

    _decodeNextFrameAndSchedule();
  }

  void _handleAppFrame(Duration timestamp) {
    if (!_hasActiveListeners) return;
    if (_isFirstFrame() || _hasFrameDurationPassed(timestamp)) {
      _emitFrame(ImageInfo(image: _nextFrame.image, scale: _scale));
      _shownTimestamp = timestamp;
      _frameDuration = _nextFrame.duration;
      _nextFrame = null;
      final int completedCycles = _framesEmitted ~/ _codec.frameCount;
      if (_codec.repetitionCount == -1 ||
          completedCycles <= _codec.repetitionCount) {
        _decodeNextFrameAndSchedule();
      }
      return;
    }
    final Duration delay = _frameDuration - (timestamp - _shownTimestamp);
    _timer = Timer(delay * timeDilation, () {
      SchedulerBinding.instance.scheduleFrameCallback(_handleAppFrame);
    });
  }

  bool _isFirstFrame() {
    return _frameDuration == null;
  }

  bool _hasFrameDurationPassed(Duration timestamp) {
    assert(_shownTimestamp != null);
    return timestamp - _shownTimestamp >= _frameDuration;
  }

  Future<void> _decodeNextFrameAndSchedule() async {
    try {
      _nextFrame = await _codec.getNextFrame();
    } catch (exception, stack) {
      reportError(
        context: 'resolving an image frame',
        exception: exception,
        stack: stack,
        informationCollector: _informationCollector,
        silent: true,
      );
      return;
    }
    if (_codec.frameCount == 1) {
      _emitFrame(ImageInfo(image: _nextFrame.image, scale: _scale));
      return;
    }
    SchedulerBinding.instance.scheduleFrameCallback(_handleAppFrame);
  }

  void _emitFrame(ImageInfo imageInfo) {
    setImage(imageInfo);
    _framesEmitted += 1;
  }

  bool get _hasActiveListeners => _listeners.isNotEmpty;

  @override
  void addListener(ImageListener listener, {ImageErrorListener onError}) {
    if (!_hasActiveListeners && _codec != null) {
      _decodeNextFrameAndSchedule();
    }
    super.addListener(listener, onError: onError);
  }

  @override
  void removeListener(ImageListener listener) {
    super.removeListener(listener);
    if (!_hasActiveListeners) {
      _timer?.cancel();
      _timer = null;
    }
  }
}

import 'dart:typed_data';

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/services.dart';

import 'basic.dart';
import 'framework.dart';
import 'image.dart';
import 'ticker_provider.dart';

class FadeInImage extends StatefulWidget {
  const FadeInImage({
    Key key,
    @required this.placeholder,
    @required this.image,
    this.fadeOutDuration = const Duration(milliseconds: 300),
    this.fadeOutCurve = Curves.easeOut,
    this.fadeInDuration = const Duration(milliseconds: 700),
    this.fadeInCurve = Curves.easeIn,
    this.width,
    this.height,
    this.fit,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.matchTextDirection = false,
  })  : assert(placeholder != null),
        assert(image != null),
        assert(fadeOutDuration != null),
        assert(fadeOutCurve != null),
        assert(fadeInDuration != null),
        assert(fadeInCurve != null),
        assert(alignment != null),
        assert(repeat != null),
        assert(matchTextDirection != null),
        super(key: key);

  FadeInImage.memoryNetwork({
    Key key,
    @required Uint8List placeholder,
    @required String image,
    double placeholderScale = 1.0,
    double imageScale = 1.0,
    this.fadeOutDuration = const Duration(milliseconds: 300),
    this.fadeOutCurve = Curves.easeOut,
    this.fadeInDuration = const Duration(milliseconds: 700),
    this.fadeInCurve = Curves.easeIn,
    this.width,
    this.height,
    this.fit,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.matchTextDirection = false,
  })  : assert(placeholder != null),
        assert(image != null),
        assert(placeholderScale != null),
        assert(imageScale != null),
        assert(fadeOutDuration != null),
        assert(fadeOutCurve != null),
        assert(fadeInDuration != null),
        assert(fadeInCurve != null),
        assert(alignment != null),
        assert(repeat != null),
        assert(matchTextDirection != null),
        placeholder = MemoryImage(placeholder, scale: placeholderScale),
        image = NetworkImage(image, scale: imageScale),
        super(key: key);

  FadeInImage.assetNetwork({
    Key key,
    @required String placeholder,
    @required String image,
    AssetBundle bundle,
    double placeholderScale,
    double imageScale = 1.0,
    this.fadeOutDuration = const Duration(milliseconds: 300),
    this.fadeOutCurve = Curves.easeOut,
    this.fadeInDuration = const Duration(milliseconds: 700),
    this.fadeInCurve = Curves.easeIn,
    this.width,
    this.height,
    this.fit,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.matchTextDirection = false,
  })  : assert(placeholder != null),
        assert(image != null),
        placeholder = placeholderScale != null
            ? ExactAssetImage(placeholder,
                bundle: bundle, scale: placeholderScale)
            : AssetImage(placeholder, bundle: bundle),
        assert(imageScale != null),
        assert(fadeOutDuration != null),
        assert(fadeOutCurve != null),
        assert(fadeInDuration != null),
        assert(fadeInCurve != null),
        assert(alignment != null),
        assert(repeat != null),
        assert(matchTextDirection != null),
        image = NetworkImage(image, scale: imageScale),
        super(key: key);

  final ImageProvider placeholder;

  final ImageProvider image;

  final Duration fadeOutDuration;

  final Curve fadeOutCurve;

  final Duration fadeInDuration;

  final Curve fadeInCurve;

  final double width;

  final double height;

  final BoxFit fit;

  final AlignmentGeometry alignment;

  final ImageRepeat repeat;

  final bool matchTextDirection;

  @override
  State<StatefulWidget> createState() => _FadeInImageState();
}

@visibleForTesting
enum FadeInImagePhase {
  start,

  waiting,

  fadeOut,

  fadeIn,

  completed,
}

typedef _ImageProviderResolverListener = void Function();

class _ImageProviderResolver {
  _ImageProviderResolver({
    @required this.state,
    @required this.listener,
  });

  final _FadeInImageState state;
  final _ImageProviderResolverListener listener;

  FadeInImage get widget => state.widget;

  ImageStream _imageStream;
  ImageInfo _imageInfo;

  void resolve(ImageProvider provider) {
    final ImageStream oldImageStream = _imageStream;
    _imageStream = provider.resolve(createLocalImageConfiguration(state.context,
        size: widget.width != null && widget.height != null
            ? Size(widget.width, widget.height)
            : null));
    assert(_imageStream != null);

    if (_imageStream.key != oldImageStream?.key) {
      oldImageStream?.removeListener(_handleImageChanged);
      _imageStream.addListener(_handleImageChanged);
    }
  }

  void _handleImageChanged(ImageInfo imageInfo, bool synchronousCall) {
    _imageInfo = imageInfo;
    listener();
  }

  void stopListening() {
    _imageStream?.removeListener(_handleImageChanged);
  }
}

class _FadeInImageState extends State<FadeInImage>
    with TickerProviderStateMixin {
  _ImageProviderResolver _imageResolver;
  _ImageProviderResolver _placeholderResolver;

  AnimationController _controller;
  Animation<double> _animation;

  FadeInImagePhase _phase = FadeInImagePhase.start;
  FadeInImagePhase get phase => _phase;

  @override
  void initState() {
    _imageResolver =
        _ImageProviderResolver(state: this, listener: _updatePhase);
    _placeholderResolver = _ImageProviderResolver(
        state: this,
        listener: () {
          setState(() {});
        });
    _controller = AnimationController(
      value: 1.0,
      vsync: this,
    );
    _controller.addListener(() {
      setState(() {});
    });
    _controller.addStatusListener((AnimationStatus status) {
      _updatePhase();
    });
    super.initState();
  }

  @override
  void didChangeDependencies() {
    _resolveImage();
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(FadeInImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.image != oldWidget.image ||
        widget.placeholder != oldWidget.placeholder) _resolveImage();
  }

  @override
  void reassemble() {
    _resolveImage();
    super.reassemble();
  }

  void _resolveImage() {
    _imageResolver.resolve(widget.image);

    if (_isShowingPlaceholder) _placeholderResolver.resolve(widget.placeholder);

    if (_phase == FadeInImagePhase.start) _updatePhase();
  }

  void _updatePhase() {
    setState(() {
      switch (_phase) {
        case FadeInImagePhase.start:
          if (_imageResolver._imageInfo != null)
            _phase = FadeInImagePhase.completed;
          else
            _phase = FadeInImagePhase.waiting;
          break;
        case FadeInImagePhase.waiting:
          if (_imageResolver._imageInfo != null) {
            _controller.duration = widget.fadeOutDuration;
            _animation = CurvedAnimation(
              parent: _controller,
              curve: widget.fadeOutCurve,
            );
            _phase = FadeInImagePhase.fadeOut;
            _controller.reverse(from: 1.0);
          }
          break;
        case FadeInImagePhase.fadeOut:
          if (_controller.status == AnimationStatus.dismissed) {
            _controller.duration = widget.fadeInDuration;
            _animation = CurvedAnimation(
              parent: _controller,
              curve: widget.fadeInCurve,
            );
            _phase = FadeInImagePhase.fadeIn;
            _placeholderResolver.stopListening();
            _controller.forward(from: 0.0);
          }
          break;
        case FadeInImagePhase.fadeIn:
          if (_controller.status == AnimationStatus.completed) {
            _phase = FadeInImagePhase.completed;
          }
          break;
        case FadeInImagePhase.completed:
          break;
      }
    });
  }

  @override
  void dispose() {
    _imageResolver.stopListening();
    _placeholderResolver.stopListening();
    _controller.dispose();
    super.dispose();
  }

  bool get _isShowingPlaceholder {
    assert(_phase != null);
    switch (_phase) {
      case FadeInImagePhase.start:
      case FadeInImagePhase.waiting:
      case FadeInImagePhase.fadeOut:
        return true;
      case FadeInImagePhase.fadeIn:
      case FadeInImagePhase.completed:
        return false;
    }

    return null;
  }

  ImageInfo get _imageInfo {
    return _isShowingPlaceholder
        ? _placeholderResolver._imageInfo
        : _imageResolver._imageInfo;
  }

  @override
  Widget build(BuildContext context) {
    assert(_phase != FadeInImagePhase.start);
    final ImageInfo imageInfo = _imageInfo;
    return RawImage(
      image: imageInfo?.image,
      width: widget.width,
      height: widget.height,
      scale: imageInfo?.scale ?? 1.0,
      color: Color.fromRGBO(255, 255, 255, _animation?.value ?? 1.0),
      colorBlendMode: BlendMode.modulate,
      fit: widget.fit,
      alignment: widget.alignment,
      repeat: widget.repeat,
      matchTextDirection: widget.matchTextDirection,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(EnumProperty<FadeInImagePhase>('phase', _phase));
    description.add(DiagnosticsProperty<ImageInfo>('pixels', _imageInfo));
    description.add(DiagnosticsProperty<ImageStream>(
        'image stream', _imageResolver._imageStream));
    description.add(DiagnosticsProperty<ImageStream>(
        'placeholder stream', _placeholderResolver._imageStream));
  }
}

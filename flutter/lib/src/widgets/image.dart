import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/painting.dart';
import 'package:flutter_web/services.dart';
import 'package:flutter_web/semantics.dart';

import 'basic.dart';
import 'framework.dart';
import 'localizations.dart';
import 'media_query.dart';
import 'ticker_provider.dart';

export 'package:flutter_web/painting.dart'
    show
        AssetImage,
        ExactAssetImage,
        ImageConfiguration,
        ImageInfo,
        ImageStream,
        ImageProvider,
        MemoryImage,
        NetworkImage;

ImageConfiguration createLocalImageConfiguration(BuildContext context,
    {Size size}) {
  return ImageConfiguration(
    bundle: DefaultAssetBundle.of(context),
    devicePixelRatio:
        MediaQuery.of(context, nullOk: true)?.devicePixelRatio ?? 1.0,
    locale: Localizations.localeOf(context, nullOk: true),
    textDirection: Directionality.of(context),
    size: size,
    platform: defaultTargetPlatform,
  );
}

Future<Null> precacheImage(
  ImageProvider provider,
  BuildContext context, {
  Size size,
  ImageErrorListener onError,
}) {
  final ImageConfiguration config =
      createLocalImageConfiguration(context, size: size);
  final Completer<Null> completer = Completer<Null>();
  final ImageStream stream = provider.resolve(config);
  void listener(ImageInfo image, bool sync) {
    completer.complete();
  }

  void errorListener(dynamic exception, StackTrace stackTrace) {
    completer.complete();
    if (onError != null) {
      onError(exception, stackTrace);
    } else {
      FlutterError.reportError(FlutterErrorDetails(
        context: ErrorDescription('image failed to precache'),
        library: 'image resource service',
        exception: exception,
        stack: stackTrace,
        silent: true,
      ));
    }
  }

  stream.addListener(listener, onError: errorListener);
  completer.future.then<void>((Null _) {
    stream.removeListener(listener);
  });
  return completer.future;
}

class Image extends StatefulWidget {
  const Image({
    Key key,
    @required this.image,
    this.semanticLabel,
    this.excludeFromSemantics = false,
    this.width,
    this.height,
    this.color,
    this.colorBlendMode,
    this.fit,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.centerSlice,
    this.matchTextDirection = false,
    this.gaplessPlayback = false,
  })  : assert(image != null),
        assert(alignment != null),
        assert(repeat != null),
        assert(matchTextDirection != null),
        super(key: key);

  Image.network(
    String src, {
    Key key,
    double scale = 1.0,
    this.semanticLabel,
    this.excludeFromSemantics = false,
    this.width,
    this.height,
    this.color,
    this.colorBlendMode,
    this.fit,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.centerSlice,
    this.matchTextDirection = false,
    this.gaplessPlayback = false,
    Map<String, String> headers,
  })  : image = NetworkImage(src, scale: scale, headers: headers),
        assert(alignment != null),
        assert(repeat != null),
        assert(matchTextDirection != null),
        super(key: key);

  Image.asset(
    String name, {
    Key key,
    AssetBundle bundle,
    this.semanticLabel,
    this.excludeFromSemantics = false,
    double scale,
    this.width,
    this.height,
    this.color,
    this.colorBlendMode,
    this.fit,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.centerSlice,
    this.matchTextDirection = false,
    this.gaplessPlayback = false,
    String package,
  })  : image = scale != null
            ? ExactAssetImage(name,
                bundle: bundle, scale: scale, package: package)
            : AssetImage(name, bundle: bundle, package: package),
        assert(alignment != null),
        assert(repeat != null),
        assert(matchTextDirection != null),
        super(key: key);

  Image.memory(
    Uint8List bytes, {
    Key key,
    double scale = 1.0,
    this.semanticLabel,
    this.excludeFromSemantics = false,
    this.width,
    this.height,
    this.color,
    this.colorBlendMode,
    this.fit,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.centerSlice,
    this.matchTextDirection = false,
    this.gaplessPlayback = false,
  })  : image = MemoryImage(bytes, scale: scale),
        assert(alignment != null),
        assert(repeat != null),
        assert(matchTextDirection != null),
        super(key: key);

  final ImageProvider image;

  final double width;

  final double height;

  final Color color;

  final BlendMode colorBlendMode;

  final BoxFit fit;

  final AlignmentGeometry alignment;

  final ImageRepeat repeat;

  final Rect centerSlice;

  final bool matchTextDirection;

  final bool gaplessPlayback;

  final String semanticLabel;

  final bool excludeFromSemantics;

  @override
  _ImageState createState() => _ImageState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ImageProvider>('image', image));
    properties.add(DoubleProperty('width', width, defaultValue: null));
    properties.add(DoubleProperty('height', height, defaultValue: null));
    properties
        .add(DiagnosticsProperty<Color>('color', color, defaultValue: null));
    properties.add(EnumProperty<BlendMode>('colorBlendMode', colorBlendMode,
        defaultValue: null));
    properties.add(EnumProperty<BoxFit>('fit', fit, defaultValue: null));
    properties.add(DiagnosticsProperty<AlignmentGeometry>(
        'alignment', alignment,
        defaultValue: null));
    properties.add(EnumProperty<ImageRepeat>('repeat', repeat,
        defaultValue: ImageRepeat.noRepeat));
    properties.add(DiagnosticsProperty<Rect>('centerSlice', centerSlice,
        defaultValue: null));
    properties.add(FlagProperty('matchTextDirection',
        value: matchTextDirection, ifTrue: 'match text direction'));
    properties.add(
        StringProperty('semanticLabel', semanticLabel, defaultValue: null));
    properties.add(DiagnosticsProperty<bool>(
        'this.excludeFromSemantics', excludeFromSemantics));
  }
}

class _ImageState extends State<Image> {
  ImageStream _imageStream;
  ImageInfo _imageInfo;
  bool _isListeningToStream = false;
  bool _invertColors;

  @override
  void didChangeDependencies() {
    _invertColors = MediaQuery.of(context, nullOk: true)?.invertColors ??
        SemanticsBinding.instance.accessibilityFeatures.invertColors;
    _resolveImage();

    if (TickerMode.of(context))
      _listenToStream();
    else
      _stopListeningToStream();

    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(Image oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.image != oldWidget.image) _resolveImage();
  }

  @override
  void reassemble() {
    _resolveImage();
    super.reassemble();
  }

  void _resolveImage() {
    final ImageStream newStream = widget.image.resolve(
        createLocalImageConfiguration(context,
            size: widget.width != null && widget.height != null
                ? Size(widget.width, widget.height)
                : null));
    assert(newStream != null);
    _updateSourceStream(newStream);
  }

  void _handleImageChanged(ImageInfo imageInfo, bool synchronousCall) {
    setState(() {
      _imageInfo = imageInfo;
    });
  }

  void _updateSourceStream(ImageStream newStream) {
    if (_imageStream?.key == newStream?.key) return;

    if (_isListeningToStream) _imageStream.removeListener(_handleImageChanged);

    if (!widget.gaplessPlayback)
      setState(() {
        _imageInfo = null;
      });

    _imageStream = newStream;
    if (_isListeningToStream) _imageStream.addListener(_handleImageChanged);
  }

  void _listenToStream() {
    if (_isListeningToStream) return;
    _imageStream.addListener(_handleImageChanged);
    _isListeningToStream = true;
  }

  void _stopListeningToStream() {
    if (!_isListeningToStream) return;
    _imageStream.removeListener(_handleImageChanged);
    _isListeningToStream = false;
  }

  @override
  void dispose() {
    assert(_imageStream != null);
    _stopListeningToStream();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final RawImage image = RawImage(
      image: _imageInfo?.image,
      width: widget.width,
      height: widget.height,
      scale: _imageInfo?.scale ?? 1.0,
      color: widget.color,
      colorBlendMode: widget.colorBlendMode,
      fit: widget.fit,
      alignment: widget.alignment,
      repeat: widget.repeat,
      centerSlice: widget.centerSlice,
      matchTextDirection: widget.matchTextDirection,
      invertColors: _invertColors,
    );
    if (widget.excludeFromSemantics) return image;
    return Semantics(
      container: widget.semanticLabel != null,
      image: true,
      label: widget.semanticLabel == null ? '' : widget.semanticLabel,
      child: image,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(DiagnosticsProperty<ImageStream>('stream', _imageStream));
    description.add(DiagnosticsProperty<ImageInfo>('pixels', _imageInfo));
  }
}

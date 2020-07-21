import 'package:flutter_web/ui.dart' as ui show Image;

import 'package:flutter_web/foundation.dart';

import 'alignment.dart';
import 'basic_types.dart';
import 'borders.dart';
import 'box_fit.dart';
import 'image_provider.dart';
import 'image_stream.dart';

enum ImageRepeat {
  repeat,

  repeatX,

  repeatY,

  noRepeat,
}

@immutable
class DecorationImage {
  const DecorationImage({
    @required this.image,
    this.colorFilter,
    this.fit,
    this.alignment = Alignment.center,
    this.centerSlice,
    this.repeat = ImageRepeat.noRepeat,
    this.matchTextDirection = false,
  })  : assert(image != null),
        assert(alignment != null),
        assert(repeat != null),
        assert(matchTextDirection != null);

  final ImageProvider image;

  final ColorFilter colorFilter;

  final BoxFit fit;

  final AlignmentGeometry alignment;

  final Rect centerSlice;

  final ImageRepeat repeat;

  final bool matchTextDirection;

  DecorationImagePainter createPainter(VoidCallback onChanged) {
    assert(onChanged != null);
    return DecorationImagePainter._(this, onChanged);
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final DecorationImage typedOther = other;
    return image == typedOther.image &&
        colorFilter == typedOther.colorFilter &&
        fit == typedOther.fit &&
        alignment == typedOther.alignment &&
        centerSlice == typedOther.centerSlice &&
        repeat == typedOther.repeat &&
        matchTextDirection == typedOther.matchTextDirection;
  }

  @override
  int get hashCode => hashValues(image, colorFilter, fit, alignment,
      centerSlice, repeat, matchTextDirection);

  @override
  String toString() {
    final List<String> properties = <String>[];
    properties.add('$image');
    if (colorFilter != null) properties.add('$colorFilter');
    if (fit != null &&
        !(fit == BoxFit.fill && centerSlice != null) &&
        !(fit == BoxFit.scaleDown && centerSlice == null))
      properties.add('$fit');
    properties.add('$alignment');
    if (centerSlice != null) properties.add('centerSlice: $centerSlice');
    if (repeat != ImageRepeat.noRepeat) properties.add('$repeat');
    if (matchTextDirection) properties.add('match text direction');
    return '$runtimeType(${properties.join(", ")})';
  }
}

class DecorationImagePainter {
  DecorationImagePainter._(this._details, this._onChanged)
      : assert(_details != null);

  final DecorationImage _details;
  final VoidCallback _onChanged;

  ImageStream _imageStream;
  ImageInfo _image;

  void paint(Canvas canvas, Rect rect, Path clipPath,
      ImageConfiguration configuration) {
    assert(canvas != null);
    assert(rect != null);
    assert(configuration != null);

    bool flipHorizontally = false;
    if (_details.matchTextDirection) {
      assert(() {
        if (configuration.textDirection == null) {
          throw FlutterError(
              'ImageDecoration.matchTextDirection can only be used when a TextDirection is available.\n'
              'When DecorationImagePainter.paint() was called, there was no text direction provided '
              'in the ImageConfiguration object to match.\n'
              'The DecorationImage was:\n'
              '  $_details\n'
              'The ImageConfiguration was:\n'
              '  $configuration');
        }
        return true;
      }());
      if (configuration.textDirection == TextDirection.rtl)
        flipHorizontally = true;
    }

    final ImageStream newImageStream = _details.image.resolve(configuration);
    if (newImageStream.key != _imageStream?.key) {
      _imageStream?.removeListener(_imageListener);
      _imageStream = newImageStream;
      _imageStream.addListener(_imageListener);
    }
    if (_image == null) return;

    if (clipPath != null) {
      canvas.save();
      canvas.clipPath(clipPath);
    }

    paintImage(
        canvas: canvas,
        rect: rect,
        image: _image.image,
        scale: _image.scale,
        colorFilter: _details.colorFilter,
        fit: _details.fit,
        alignment: _details.alignment.resolve(configuration.textDirection),
        centerSlice: _details.centerSlice,
        repeat: _details.repeat,
        flipHorizontally: flipHorizontally,
        filterQuality: FilterQuality.low);

    if (clipPath != null) canvas.restore();
  }

  void _imageListener(ImageInfo value, bool synchronousCall) {
    if (_image == value) return;
    _image = value;
    assert(_onChanged != null);
    if (!synchronousCall) _onChanged();
  }

  @mustCallSuper
  void dispose() {
    _imageStream?.removeListener(_imageListener);
  }

  @override
  String toString() {
    return '$runtimeType(stream: $_imageStream, image: $_image) for $_details';
  }
}

void paintImage(
    {@required Canvas canvas,
    @required Rect rect,
    @required ui.Image image,
    double scale = 1.0,
    ColorFilter colorFilter,
    BoxFit fit,
    Alignment alignment = Alignment.center,
    Rect centerSlice,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    bool flipHorizontally = false,
    bool invertColors = false,
    FilterQuality filterQuality = FilterQuality.low}) {
  assert(canvas != null);
  assert(image != null);
  assert(alignment != null);
  assert(repeat != null);
  assert(flipHorizontally != null);
  if (rect.isEmpty) return;
  Size outputSize = rect.size;
  Size inputSize = Size(image.width.toDouble(), image.height.toDouble());
  Offset sliceBorder;
  if (centerSlice != null) {
    sliceBorder = Offset(centerSlice.left + inputSize.width - centerSlice.right,
        centerSlice.top + inputSize.height - centerSlice.bottom);
    outputSize -= sliceBorder;
    inputSize -= sliceBorder;
  }
  fit ??= centerSlice == null ? BoxFit.scaleDown : BoxFit.fill;
  assert(centerSlice == null || (fit != BoxFit.none && fit != BoxFit.cover));
  final FittedSizes fittedSizes =
      applyBoxFit(fit, inputSize / scale, outputSize);
  final Size sourceSize = fittedSizes.source * scale;
  Size destinationSize = fittedSizes.destination;
  if (centerSlice != null) {
    outputSize += sliceBorder;
    destinationSize += sliceBorder;

    assert(sourceSize == inputSize,
        'centerSlice was used with a BoxFit that does not guarantee that the image is fully visible.');
  }
  if (repeat != ImageRepeat.noRepeat && destinationSize == outputSize) {
    repeat = ImageRepeat.noRepeat;
  }
  final Paint paint = Paint()..isAntiAlias = false;
  if (colorFilter != null) paint.colorFilter = colorFilter;
  if (sourceSize != destinationSize) {
    paint.filterQuality = filterQuality;
  }

  final double halfWidthDelta =
      (outputSize.width - destinationSize.width) / 2.0;
  final double halfHeightDelta =
      (outputSize.height - destinationSize.height) / 2.0;
  final double dx = halfWidthDelta +
      (flipHorizontally ? -alignment.x : alignment.x) * halfWidthDelta;
  final double dy = halfHeightDelta + alignment.y * halfHeightDelta;
  final Offset destinationPosition = rect.topLeft.translate(dx, dy);
  final Rect destinationRect = destinationPosition & destinationSize;
  final bool needSave = repeat != ImageRepeat.noRepeat || flipHorizontally;
  if (needSave) canvas.save();
  if (repeat != ImageRepeat.noRepeat) canvas.clipRect(rect);
  if (flipHorizontally) {
    final double dx = -(rect.left + rect.width / 2.0);
    canvas.translate(-dx, 0.0);
    canvas.scale(-1.0, 1.0);
    canvas.translate(dx, 0.0);
  }
  if (centerSlice == null) {
    final Rect sourceRect =
        alignment.inscribe(sourceSize, Offset.zero & inputSize);
    for (Rect tileRect
        in _generateImageTileRects(rect, destinationRect, repeat))
      canvas.drawImageRect(image, sourceRect, tileRect, paint);
  } else {
    for (Rect tileRect
        in _generateImageTileRects(rect, destinationRect, repeat))
      canvas.drawImageNine(image, centerSlice, tileRect, paint);
  }
  if (needSave) canvas.restore();
}

Iterable<Rect> _generateImageTileRects(
    Rect outputRect, Rect fundamentalRect, ImageRepeat repeat) sync* {
  if (repeat == ImageRepeat.noRepeat) {
    yield fundamentalRect;
    return;
  }

  int startX = 0;
  int startY = 0;
  int stopX = 0;
  int stopY = 0;
  final double strideX = fundamentalRect.width;
  final double strideY = fundamentalRect.height;

  if (repeat == ImageRepeat.repeat || repeat == ImageRepeat.repeatX) {
    startX = ((outputRect.left - fundamentalRect.left) / strideX).floor();
    stopX = ((outputRect.right - fundamentalRect.right) / strideX).ceil();
  }

  if (repeat == ImageRepeat.repeat || repeat == ImageRepeat.repeatY) {
    startY = ((outputRect.top - fundamentalRect.top) / strideY).floor();
    stopY = ((outputRect.bottom - fundamentalRect.bottom) / strideY).ceil();
  }

  for (int i = startX; i <= stopX; ++i) {
    for (int j = startY; j <= stopY; ++j)
      yield fundamentalRect.shift(Offset(i * strideX, j * strideY));
  }
}

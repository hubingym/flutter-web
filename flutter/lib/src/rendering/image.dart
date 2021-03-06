import 'package:flutter_web/ui.dart' as ui show Image;

import 'box.dart';
import 'object.dart';

export 'package:flutter_web/painting.dart' show BoxFit, ImageRepeat;

class RenderImage extends RenderBox {
  RenderImage(
      {ui.Image image,
      double width,
      double height,
      double scale = 1.0,
      Color color,
      BlendMode colorBlendMode,
      BoxFit fit,
      AlignmentGeometry alignment = Alignment.center,
      ImageRepeat repeat = ImageRepeat.noRepeat,
      Rect centerSlice,
      bool matchTextDirection = false,
      TextDirection textDirection,
      bool invertColors = false,
      FilterQuality filterQuality = FilterQuality.low})
      : assert(scale != null),
        assert(repeat != null),
        assert(alignment != null),
        assert(filterQuality != null),
        assert(matchTextDirection != null),
        _image = image,
        _width = width,
        _height = height,
        _scale = scale,
        _color = color,
        _colorBlendMode = colorBlendMode,
        _fit = fit,
        _alignment = alignment,
        _repeat = repeat,
        _centerSlice = centerSlice,
        _matchTextDirection = matchTextDirection,
        _invertColors = invertColors,
        _textDirection = textDirection,
        _filterQuality = filterQuality {
    _updateColorFilter();
  }

  Alignment _resolvedAlignment;
  bool _flipHorizontally;

  void _resolve() {
    if (_resolvedAlignment != null) return;
    _resolvedAlignment = alignment.resolve(textDirection);
    _flipHorizontally =
        matchTextDirection && textDirection == TextDirection.rtl;
  }

  void _markNeedResolution() {
    _resolvedAlignment = null;
    _flipHorizontally = null;
    markNeedsPaint();
  }

  ui.Image get image => _image;
  ui.Image _image;
  set image(ui.Image value) {
    if (value == _image) return;
    _image = value;
    markNeedsPaint();
    if (_width == null || _height == null) markNeedsLayout();
  }

  double get width => _width;
  double _width;
  set width(double value) {
    if (value == _width) return;
    _width = value;
    markNeedsLayout();
  }

  double get height => _height;
  double _height;
  set height(double value) {
    if (value == _height) return;
    _height = value;
    markNeedsLayout();
  }

  double get scale => _scale;
  double _scale;
  set scale(double value) {
    assert(value != null);
    if (value == _scale) return;
    _scale = value;
    markNeedsLayout();
  }

  ColorFilter _colorFilter;

  void _updateColorFilter() {
    if (_color == null)
      _colorFilter = null;
    else
      _colorFilter =
          ColorFilter.mode(_color, _colorBlendMode ?? BlendMode.srcIn);
  }

  Color get color => _color;
  Color _color;
  set color(Color value) {
    if (value == _color) return;
    _color = value;
    _updateColorFilter();
    markNeedsPaint();
  }

  FilterQuality get filterQuality => _filterQuality;
  FilterQuality _filterQuality;
  set filterQuality(FilterQuality value) {
    assert(value != null);
    if (value == _filterQuality) return;
    _filterQuality = value;
    markNeedsPaint();
  }

  BlendMode get colorBlendMode => _colorBlendMode;
  BlendMode _colorBlendMode;
  set colorBlendMode(BlendMode value) {
    if (value == _colorBlendMode) return;
    _colorBlendMode = value;
    _updateColorFilter();
    markNeedsPaint();
  }

  BoxFit get fit => _fit;
  BoxFit _fit;
  set fit(BoxFit value) {
    if (value == _fit) return;
    _fit = value;
    markNeedsPaint();
  }

  AlignmentGeometry get alignment => _alignment;
  AlignmentGeometry _alignment;
  set alignment(AlignmentGeometry value) {
    assert(value != null);
    if (value == _alignment) return;
    _alignment = value;
    _markNeedResolution();
  }

  ImageRepeat get repeat => _repeat;
  ImageRepeat _repeat;
  set repeat(ImageRepeat value) {
    assert(value != null);
    if (value == _repeat) return;
    _repeat = value;
    markNeedsPaint();
  }

  Rect get centerSlice => _centerSlice;
  Rect _centerSlice;
  set centerSlice(Rect value) {
    if (value == _centerSlice) return;
    _centerSlice = value;
    markNeedsPaint();
  }

  bool get invertColors => _invertColors;
  bool _invertColors;
  set invertColors(bool value) {
    if (value == _invertColors) return;
    _invertColors = value;
    markNeedsPaint();
  }

  bool get matchTextDirection => _matchTextDirection;
  bool _matchTextDirection;
  set matchTextDirection(bool value) {
    assert(value != null);
    if (value == _matchTextDirection) return;
    _matchTextDirection = value;
    _markNeedResolution();
  }

  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (_textDirection == value) return;
    _textDirection = value;
    _markNeedResolution();
  }

  Size _sizeForConstraints(BoxConstraints constraints) {
    constraints = BoxConstraints.tightFor(width: _width, height: _height)
        .enforce(constraints);

    if (_image == null) return constraints.smallest;

    return constraints.constrainSizeAndAttemptToPreserveAspectRatio(Size(
        _image.width.toDouble() / _scale, _image.height.toDouble() / _scale));
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    assert(height >= 0.0);
    if (_width == null && _height == null) return 0.0;
    return _sizeForConstraints(BoxConstraints.tightForFinite(height: height))
        .width;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    assert(height >= 0.0);
    return _sizeForConstraints(BoxConstraints.tightForFinite(height: height))
        .width;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    assert(width >= 0.0);
    if (_width == null && _height == null) return 0.0;
    return _sizeForConstraints(BoxConstraints.tightForFinite(width: width))
        .height;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    assert(width >= 0.0);
    return _sizeForConstraints(BoxConstraints.tightForFinite(width: width))
        .height;
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void performLayout() {
    size = _sizeForConstraints(constraints);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_image == null) return;
    _resolve();
    assert(_resolvedAlignment != null);
    assert(_flipHorizontally != null);
    paintImage(
        canvas: context.canvas,
        rect: offset & size,
        image: _image,
        scale: _scale,
        colorFilter: _colorFilter,
        fit: _fit,
        alignment: _resolvedAlignment,
        centerSlice: _centerSlice,
        repeat: _repeat,
        flipHorizontally: _flipHorizontally,
        invertColors: invertColors,
        filterQuality: _filterQuality);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ui.Image>('image', image));
    properties.add(DoubleProperty('width', width, defaultValue: null));
    properties.add(DoubleProperty('height', height, defaultValue: null));
    properties.add(DoubleProperty('scale', scale, defaultValue: 1.0));
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
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection,
        defaultValue: null));
    properties.add(DiagnosticsProperty<bool>('invertColors', invertColors));
    properties.add(EnumProperty<FilterQuality>('filterQuality', filterQuality));
  }
}

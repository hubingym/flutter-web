import 'package:flutter_web/rendering.dart';
import 'package:flutter_web/widgets.dart';

import 'debug.dart';
import 'material.dart';

class Ink extends StatefulWidget {
  Ink({
    Key key,
    this.padding,
    Color color,
    Decoration decoration,
    this.width,
    this.height,
    this.child,
  })  : assert(padding == null || padding.isNonNegative),
        assert(decoration == null || decoration.debugAssertIsValid()),
        assert(
            color == null || decoration == null,
            'Cannot provide both a color and a decoration\n'
            'The color argument is just a shorthand for "decoration: new BoxDecoration(color: color)".'),
        decoration =
            decoration ?? (color != null ? BoxDecoration(color: color) : null),
        super(key: key);

  Ink.image({
    Key key,
    this.padding,
    @required ImageProvider image,
    ColorFilter colorFilter,
    BoxFit fit,
    AlignmentGeometry alignment = Alignment.center,
    Rect centerSlice,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    bool matchTextDirection = false,
    this.width,
    this.height,
    this.child,
  })  : assert(padding == null || padding.isNonNegative),
        assert(image != null),
        assert(alignment != null),
        assert(repeat != null),
        assert(matchTextDirection != null),
        decoration = BoxDecoration(
          image: DecorationImage(
            image: image,
            colorFilter: colorFilter,
            fit: fit,
            alignment: alignment,
            centerSlice: centerSlice,
            repeat: repeat,
            matchTextDirection: matchTextDirection,
          ),
        ),
        super(key: key);

  final Widget child;

  final EdgeInsetsGeometry padding;

  final Decoration decoration;

  final double width;

  final double height;

  EdgeInsetsGeometry get _paddingIncludingDecoration {
    if (decoration == null || decoration.padding == null) return padding;
    final EdgeInsetsGeometry decorationPadding = decoration.padding;
    if (padding == null) return decorationPadding;
    return padding.add(decorationPadding);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('padding', padding,
        defaultValue: null));
    properties.add(
        DiagnosticsProperty<Decoration>('bg', decoration, defaultValue: null));
  }

  @override
  _InkState createState() => _InkState();
}

class _InkState extends State<Ink> {
  InkDecoration _ink;

  void _handleRemoved() {
    _ink = null;
  }

  @override
  void deactivate() {
    _ink?.dispose();
    assert(_ink == null);
    super.deactivate();
  }

  Widget _build(BuildContext context, BoxConstraints constraints) {
    if (_ink == null) {
      _ink = InkDecoration(
        decoration: widget.decoration,
        configuration: createLocalImageConfiguration(context),
        controller: Material.of(context),
        referenceBox: context.findRenderObject(),
        onRemoved: _handleRemoved,
      );
    } else {
      _ink.decoration = widget.decoration;
      _ink.configuration = createLocalImageConfiguration(context);
    }
    Widget current = widget.child;
    final EdgeInsetsGeometry effectivePadding =
        widget._paddingIncludingDecoration;
    if (effectivePadding != null)
      current = Padding(padding: effectivePadding, child: current);
    return current;
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    Widget result = LayoutBuilder(
      builder: _build,
    );
    if (widget.width != null || widget.height != null) {
      result = SizedBox(
        width: widget.width,
        height: widget.height,
        child: result,
      );
    }
    return result;
  }
}

class InkDecoration extends InkFeature {
  InkDecoration({
    @required Decoration decoration,
    @required ImageConfiguration configuration,
    @required MaterialInkController controller,
    @required RenderBox referenceBox,
    VoidCallback onRemoved,
  })  : assert(configuration != null),
        _configuration = configuration,
        super(
            controller: controller,
            referenceBox: referenceBox,
            onRemoved: onRemoved) {
    this.decoration = decoration;
    controller.addInkFeature(this);
  }

  BoxPainter _painter;

  Decoration get decoration => _decoration;
  Decoration _decoration;
  set decoration(Decoration value) {
    if (value == _decoration) return;
    _decoration = value;
    _painter?.dispose();
    _painter = _decoration?.createBoxPainter(_handleChanged);
    controller.markNeedsPaint();
  }

  ImageConfiguration get configuration => _configuration;
  ImageConfiguration _configuration;
  set configuration(ImageConfiguration value) {
    assert(value != null);
    if (value == _configuration) return;
    _configuration = value;
    controller.markNeedsPaint();
  }

  void _handleChanged() {
    controller.markNeedsPaint();
  }

  @override
  void dispose() {
    _painter?.dispose();
    super.dispose();
  }

  @override
  void paintFeature(Canvas canvas, Matrix4 transform) {
    if (_painter == null) return;
    final Offset originOffset = MatrixUtils.getAsTranslation(transform);
    final ImageConfiguration sizedConfiguration = configuration.copyWith(
      size: referenceBox.size,
    );
    if (originOffset == null) {
      canvas.save();
      canvas.transform(transform.storage);
      _painter.paint(canvas, Offset.zero, sizedConfiguration);
      canvas.restore();
    } else {
      _painter.paint(canvas, originOffset, sizedConfiguration);
    }
  }
}

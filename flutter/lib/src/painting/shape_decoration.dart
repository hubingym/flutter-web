import 'package:flutter_web/foundation.dart';

import 'basic_types.dart';
import 'borders.dart';
import 'box_border.dart';
import 'box_decoration.dart';
import 'box_shadow.dart';
import 'circle_border.dart';
import 'decoration.dart';
import 'decoration_image.dart';
import 'edge_insets.dart';
import 'gradient.dart';
import 'image_provider.dart';
import 'rounded_rectangle_border.dart';

class ShapeDecoration extends Decoration {
  const ShapeDecoration({
    this.color,
    this.image,
    this.gradient,
    this.shadows,
    @required this.shape,
  })  : assert(!(color != null && gradient != null)),
        assert(shape != null);

  factory ShapeDecoration.fromBoxDecoration(BoxDecoration source) {
    ShapeBorder shape;
    assert(source.shape != null);
    switch (source.shape) {
      case BoxShape.circle:
        if (source.border != null) {
          assert(source.border.isUniform);
          shape = new CircleBorder(side: source.border.top);
        } else {
          shape = const CircleBorder();
        }
        break;
      case BoxShape.rectangle:
        if (source.borderRadius != null) {
          assert(source.border == null || source.border.isUniform);
          shape = new RoundedRectangleBorder(
            side: source.border?.top ?? BorderSide.none,
            borderRadius: source.borderRadius,
          );
        } else {
          shape = source.border ?? const Border();
        }
        break;
    }
    return new ShapeDecoration(
      color: source.color,
      image: source.image,
      gradient: source.gradient,
      shadows: source.boxShadow,
      shape: shape,
    );
  }

  final Color color;

  final Gradient gradient;

  final DecorationImage image;

  final List<BoxShadow> shadows;

  final ShapeBorder shape;

  @override
  EdgeInsets get padding => shape.dimensions;

  @override
  bool get isComplex => shadows != null;

  @override
  ShapeDecoration lerpFrom(Decoration a, double t) {
    if (a is BoxDecoration) {
      return ShapeDecoration.lerp(
          new ShapeDecoration.fromBoxDecoration(a), this, t);
    } else if (a == null || a is ShapeDecoration) {
      return ShapeDecoration.lerp(a, this, t);
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeDecoration lerpTo(Decoration b, double t) {
    if (b is BoxDecoration) {
      return ShapeDecoration.lerp(
          this, new ShapeDecoration.fromBoxDecoration(b), t);
    } else if (b == null || b is ShapeDecoration) {
      return ShapeDecoration.lerp(this, b, t);
    }
    return super.lerpTo(b, t);
  }

  static ShapeDecoration lerp(ShapeDecoration a, ShapeDecoration b, double t) {
    assert(t != null);
    if (a == null && b == null) return null;
    if (a != null && b != null) {
      if (t == 0.0) return a;
      if (t == 1.0) return b;
    }
    return new ShapeDecoration(
      color: Color.lerp(a?.color, b?.color, t),
      gradient: Gradient.lerp(a?.gradient, b?.gradient, t),
      image: t < 0.5 ? a.image : b.image,
      shadows: BoxShadow.lerpList(a?.shadows, b?.shadows, t),
      shape: ShapeBorder.lerp(a?.shape, b?.shape, t),
    );
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final ShapeDecoration typedOther = other;
    return color == typedOther.color &&
        gradient == typedOther.gradient &&
        image == typedOther.image &&
        shadows == typedOther.shadows &&
        shape == typedOther.shape;
  }

  @override
  int get hashCode {
    return hashValues(
      color,
      gradient,
      image,
      shape,
      shadows,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.defaultDiagnosticsTreeStyle = DiagnosticsTreeStyle.whitespace;
    properties.add(
        new DiagnosticsProperty<Color>('color', color, defaultValue: null));
    properties.add(new DiagnosticsProperty<Gradient>('gradient', gradient,
        defaultValue: null));
    properties.add(new DiagnosticsProperty<DecorationImage>('image', image,
        defaultValue: null));
    properties.add(new IterableProperty<BoxShadow>('shadows', shadows,
        defaultValue: null, style: DiagnosticsTreeStyle.whitespace));
    properties.add(new DiagnosticsProperty<ShapeBorder>('shape', shape));
  }

  @override
  bool hitTest(Size size, Offset position, {TextDirection textDirection}) {
    return shape
        .getOuterPath(Offset.zero & size, textDirection: textDirection)
        .contains(position);
  }

  @override
  _ShapeDecorationPainter createBoxPainter([VoidCallback onChanged]) {
    assert(onChanged != null || image == null);
    return new _ShapeDecorationPainter(this, onChanged);
  }
}

class _ShapeDecorationPainter extends BoxPainter {
  _ShapeDecorationPainter(this._decoration, VoidCallback onChanged)
      : assert(_decoration != null),
        super(onChanged);

  final ShapeDecoration _decoration;

  Rect _lastRect;
  TextDirection _lastTextDirection;
  Path _outerPath;
  Path _innerPath;
  Paint _interiorPaint;
  int _shadowCount;
  List<Path> _shadowPaths;
  List<Paint> _shadowPaints;

  void _precache(Rect rect, TextDirection textDirection) {
    assert(rect != null);
    if (rect == _lastRect && textDirection == _lastTextDirection) return;

    if (_interiorPaint == null &&
        (_decoration.color != null || _decoration.gradient != null)) {
      _interiorPaint = new Paint();
      if (_decoration.color != null) _interiorPaint.color = _decoration.color;
    }
    if (_decoration.gradient != null)
      _interiorPaint.shader = _decoration.gradient.createShader(rect);
    if (_decoration.shadows != null) {
      if (_shadowCount == null) {
        _shadowCount = _decoration.shadows.length;
        _shadowPaths = new List<Path>(_shadowCount);
        _shadowPaints = new List<Paint>(_shadowCount);
        for (int index = 0; index < _shadowCount; index += 1)
          _shadowPaints[index] = _decoration.shadows[index].toPaint();
      }
      for (int index = 0; index < _shadowCount; index += 1) {
        final BoxShadow shadow = _decoration.shadows[index];
        _shadowPaths[index] = _decoration.shape.getOuterPath(
            rect.shift(shadow.offset).inflate(shadow.spreadRadius),
            textDirection: textDirection);
      }
    }
    if (_interiorPaint != null || _shadowCount != null)
      _outerPath =
          _decoration.shape.getOuterPath(rect, textDirection: textDirection);
    if (_decoration.image != null)
      _innerPath =
          _decoration.shape.getInnerPath(rect, textDirection: textDirection);

    _lastRect = rect;
    _lastTextDirection = textDirection;
  }

  void _paintShadows(Canvas canvas) {
    if (_shadowCount != null) {
      for (int index = 0; index < _shadowCount; index += 1)
        canvas.drawPath(_shadowPaths[index], _shadowPaints[index]);
    }
  }

  void _paintInterior(Canvas canvas) {
    if (_interiorPaint != null) canvas.drawPath(_outerPath, _interiorPaint);
  }

  DecorationImagePainter _imagePainter;
  void _paintImage(Canvas canvas, ImageConfiguration configuration) {
    if (_decoration.image == null) return;
    _imagePainter ??= _decoration.image.createPainter(onChanged);
    _imagePainter.paint(canvas, _lastRect, _innerPath, configuration);
  }

  @override
  void dispose() {
    _imagePainter?.dispose();
    super.dispose();
  }

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    assert(configuration != null);
    assert(configuration.size != null);
    final Rect rect = offset & configuration.size;
    final TextDirection textDirection = configuration.textDirection;
    _precache(rect, textDirection);
    _paintShadows(canvas);
    _paintInterior(canvas);
    _paintImage(canvas, configuration);
    _decoration.shape.paint(canvas, rect, textDirection: textDirection);
  }
}

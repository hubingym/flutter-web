import 'dart:async';

import 'package:flutter_web/ui.dart' as ui show ImageFilter, Gradient, Image;

import 'package:flutter_web/animation.dart';
import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/gestures.dart';
import 'package:flutter_web/painting.dart';
import 'package:flutter_web/semantics.dart';

import 'package:vector_math/vector_math_64.dart';

import 'binding.dart';
import 'box.dart';
import 'layer.dart';
import 'object.dart';

export 'package:flutter_web/gestures.dart'
    show
        PointerEvent,
        PointerDownEvent,
        PointerMoveEvent,
        PointerUpEvent,
        PointerCancelEvent;

class RenderProxyBox extends RenderBox
    with RenderObjectWithChildMixin<RenderBox>, RenderProxyBoxMixin<RenderBox> {
  RenderProxyBox([RenderBox child]) {
    this.child = child;
  }
}

@optionalTypeArgs
mixin RenderProxyBoxMixin<T extends RenderBox>
    on RenderBox, RenderObjectWithChildMixin<T> {
  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! ParentData) child.parentData = ParentData();
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    if (child != null) return child.getMinIntrinsicWidth(height);
    return 0.0;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    if (child != null) return child.getMaxIntrinsicWidth(height);
    return 0.0;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    if (child != null) return child.getMinIntrinsicHeight(width);
    return 0.0;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    if (child != null) return child.getMaxIntrinsicHeight(width);
    return 0.0;
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    if (child != null) return child.getDistanceToActualBaseline(baseline);
    return super.computeDistanceToActualBaseline(baseline);
  }

  @override
  void performLayout() {
    if (child != null) {
      child.layout(constraints, parentUsesSize: true);
      size = child.size;
    } else {
      performResize();
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {Offset position}) {
    return child?.hitTest(result, position: position) ?? false;
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {}

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) context.paintChild(child, offset);
  }
}

enum HitTestBehavior {
  deferToChild,

  opaque,

  translucent,
}

abstract class RenderProxyBoxWithHitTestBehavior extends RenderProxyBox {
  RenderProxyBoxWithHitTestBehavior({
    this.behavior = HitTestBehavior.deferToChild,
    RenderBox child,
  }) : super(child);

  HitTestBehavior behavior;

  @override
  bool hitTest(BoxHitTestResult result, {Offset position}) {
    bool hitTarget = false;
    if (size.contains(position)) {
      hitTarget =
          hitTestChildren(result, position: position) || hitTestSelf(position);
      if (hitTarget || behavior == HitTestBehavior.translucent)
        result.add(BoxHitTestEntry(this, position));
    }
    return hitTarget;
  }

  @override
  bool hitTestSelf(Offset position) => behavior == HitTestBehavior.opaque;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<HitTestBehavior>('behavior', behavior,
        defaultValue: null));
  }
}

class RenderConstrainedBox extends RenderProxyBox {
  RenderConstrainedBox({
    RenderBox child,
    @required BoxConstraints additionalConstraints,
  })  : assert(additionalConstraints != null),
        assert(additionalConstraints.debugAssertIsValid()),
        _additionalConstraints = additionalConstraints,
        super(child);

  BoxConstraints get additionalConstraints => _additionalConstraints;
  BoxConstraints _additionalConstraints;
  set additionalConstraints(BoxConstraints value) {
    assert(value != null);
    assert(value.debugAssertIsValid());
    if (_additionalConstraints == value) return;
    _additionalConstraints = value;
    markNeedsLayout();
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    if (_additionalConstraints.hasBoundedWidth &&
        _additionalConstraints.hasTightWidth)
      return _additionalConstraints.minWidth;
    final double width = super.computeMinIntrinsicWidth(height);
    assert(width.isFinite);
    if (!_additionalConstraints.hasInfiniteWidth)
      return _additionalConstraints.constrainWidth(width);
    return width;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    if (_additionalConstraints.hasBoundedWidth &&
        _additionalConstraints.hasTightWidth)
      return _additionalConstraints.minWidth;
    final double width = super.computeMaxIntrinsicWidth(height);
    assert(width.isFinite);
    if (!_additionalConstraints.hasInfiniteWidth)
      return _additionalConstraints.constrainWidth(width);
    return width;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    if (_additionalConstraints.hasBoundedHeight &&
        _additionalConstraints.hasTightHeight)
      return _additionalConstraints.minHeight;
    final double height = super.computeMinIntrinsicHeight(width);
    assert(height.isFinite);
    if (!_additionalConstraints.hasInfiniteHeight)
      return _additionalConstraints.constrainHeight(height);
    return height;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    if (_additionalConstraints.hasBoundedHeight &&
        _additionalConstraints.hasTightHeight)
      return _additionalConstraints.minHeight;
    final double height = super.computeMaxIntrinsicHeight(width);
    assert(height.isFinite);
    if (!_additionalConstraints.hasInfiniteHeight)
      return _additionalConstraints.constrainHeight(height);
    return height;
  }

  @override
  void performLayout() {
    if (child != null) {
      child.layout(_additionalConstraints.enforce(constraints),
          parentUsesSize: true);
      size = child.size;
    } else {
      size = _additionalConstraints.enforce(constraints).constrain(Size.zero);
    }
  }

  @override
  void debugPaintSize(PaintingContext context, Offset offset) {
    super.debugPaintSize(context, offset);
    assert(() {
      Paint paint;
      if (child == null || child.size.isEmpty) {
        paint = Paint()..color = const Color(0x90909090);
        context.canvas.drawRect(offset & size, paint);
      }
      return true;
    }());
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<BoxConstraints>(
        'additionalConstraints', additionalConstraints));
  }
}

class RenderLimitedBox extends RenderProxyBox {
  RenderLimitedBox({
    RenderBox child,
    double maxWidth = double.infinity,
    double maxHeight = double.infinity,
  })  : assert(maxWidth != null && maxWidth >= 0.0),
        assert(maxHeight != null && maxHeight >= 0.0),
        _maxWidth = maxWidth,
        _maxHeight = maxHeight,
        super(child);

  double get maxWidth => _maxWidth;
  double _maxWidth;
  set maxWidth(double value) {
    assert(value != null && value >= 0.0);
    if (_maxWidth == value) return;
    _maxWidth = value;
    markNeedsLayout();
  }

  double get maxHeight => _maxHeight;
  double _maxHeight;
  set maxHeight(double value) {
    assert(value != null && value >= 0.0);
    if (_maxHeight == value) return;
    _maxHeight = value;
    markNeedsLayout();
  }

  BoxConstraints _limitConstraints(BoxConstraints constraints) {
    return BoxConstraints(
      minWidth: constraints.minWidth,
      maxWidth: constraints.hasBoundedWidth
          ? constraints.maxWidth
          : constraints.constrainWidth(maxWidth),
      minHeight: constraints.minHeight,
      maxHeight: constraints.hasBoundedHeight
          ? constraints.maxHeight
          : constraints.constrainHeight(maxHeight),
    );
  }

  @override
  void performLayout() {
    if (child != null) {
      child.layout(_limitConstraints(constraints), parentUsesSize: true);
      size = constraints.constrain(child.size);
    } else {
      size = _limitConstraints(constraints).constrain(Size.zero);
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
        DoubleProperty('maxWidth', maxWidth, defaultValue: double.infinity));
    properties.add(
        DoubleProperty('maxHeight', maxHeight, defaultValue: double.infinity));
  }
}

class RenderAspectRatio extends RenderProxyBox {
  RenderAspectRatio({
    RenderBox child,
    @required double aspectRatio,
  })  : assert(aspectRatio != null),
        assert(aspectRatio > 0.0),
        assert(aspectRatio.isFinite),
        _aspectRatio = aspectRatio,
        super(child);

  double get aspectRatio => _aspectRatio;
  double _aspectRatio;
  set aspectRatio(double value) {
    assert(value != null);
    assert(value > 0.0);
    assert(value.isFinite);
    if (_aspectRatio == value) return;
    _aspectRatio = value;
    markNeedsLayout();
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    if (height.isFinite) return height * _aspectRatio;
    if (child != null) return child.getMinIntrinsicWidth(height);
    return 0.0;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    if (height.isFinite) return height * _aspectRatio;
    if (child != null) return child.getMaxIntrinsicWidth(height);
    return 0.0;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    if (width.isFinite) return width / _aspectRatio;
    if (child != null) return child.getMinIntrinsicHeight(width);
    return 0.0;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    if (width.isFinite) return width / _aspectRatio;
    if (child != null) return child.getMaxIntrinsicHeight(width);
    return 0.0;
  }

  Size _applyAspectRatio(BoxConstraints constraints) {
    assert(constraints.debugAssertIsValid());
    assert(() {
      if (!constraints.hasBoundedWidth && !constraints.hasBoundedHeight) {
        throw FlutterError('$runtimeType has unbounded constraints.\n'
            'This $runtimeType was given an aspect ratio of $aspectRatio but was given '
            'both unbounded width and unbounded height constraints. Because both '
            'constraints were unbounded, this render object doesn\'t know how much '
            'size to consume.');
      }
      return true;
    }());

    if (constraints.isTight) return constraints.smallest;

    double width = constraints.maxWidth;
    double height;

    if (width.isFinite) {
      height = width / _aspectRatio;
    } else {
      height = constraints.maxHeight;
      width = height * _aspectRatio;
    }

    if (width > constraints.maxWidth) {
      width = constraints.maxWidth;
      height = width / _aspectRatio;
    }

    if (height > constraints.maxHeight) {
      height = constraints.maxHeight;
      width = height * _aspectRatio;
    }

    if (width < constraints.minWidth) {
      width = constraints.minWidth;
      height = width / _aspectRatio;
    }

    if (height < constraints.minHeight) {
      height = constraints.minHeight;
      width = height * _aspectRatio;
    }

    return constraints.constrain(Size(width, height));
  }

  @override
  void performLayout() {
    size = _applyAspectRatio(constraints);
    if (child != null) child.layout(BoxConstraints.tight(size));
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('aspectRatio', aspectRatio));
  }
}

class RenderIntrinsicWidth extends RenderProxyBox {
  RenderIntrinsicWidth({
    double stepWidth,
    double stepHeight,
    RenderBox child,
  })  : assert(stepWidth == null || stepWidth > 0.0),
        assert(stepHeight == null || stepHeight > 0.0),
        _stepWidth = stepWidth,
        _stepHeight = stepHeight,
        super(child);

  double get stepWidth => _stepWidth;
  double _stepWidth;
  set stepWidth(double value) {
    assert(value == null || value > 0.0);
    if (value == _stepWidth) return;
    _stepWidth = value;
    markNeedsLayout();
  }

  double get stepHeight => _stepHeight;
  double _stepHeight;
  set stepHeight(double value) {
    assert(value == null || value > 0.0);
    if (value == _stepHeight) return;
    _stepHeight = value;
    markNeedsLayout();
  }

  static double _applyStep(double input, double step) {
    assert(input.isFinite);
    if (step == null) return input;
    return (input / step).ceil() * step;
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    return computeMaxIntrinsicWidth(height);
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    if (child == null) return 0.0;
    final double width = child.getMaxIntrinsicWidth(height);
    return _applyStep(width, _stepWidth);
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    if (child == null) return 0.0;
    if (!width.isFinite) width = computeMaxIntrinsicWidth(double.infinity);
    assert(width.isFinite);
    final double height = child.getMinIntrinsicHeight(width);
    return _applyStep(height, _stepHeight);
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    if (child == null) return 0.0;
    if (!width.isFinite) width = computeMaxIntrinsicWidth(double.infinity);
    assert(width.isFinite);
    final double height = child.getMaxIntrinsicHeight(width);
    return _applyStep(height, _stepHeight);
  }

  @override
  void performLayout() {
    if (child != null) {
      BoxConstraints childConstraints = constraints;
      if (!childConstraints.hasTightWidth) {
        final double width =
            child.getMaxIntrinsicWidth(childConstraints.maxHeight);
        assert(width.isFinite);
        childConstraints =
            childConstraints.tighten(width: _applyStep(width, _stepWidth));
      }
      if (_stepHeight != null) {
        final double height =
            child.getMaxIntrinsicHeight(childConstraints.maxWidth);
        assert(height.isFinite);
        childConstraints =
            childConstraints.tighten(height: _applyStep(height, _stepHeight));
      }
      child.layout(childConstraints, parentUsesSize: true);
      size = child.size;
    } else {
      performResize();
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('stepWidth', stepWidth));
    properties.add(DoubleProperty('stepHeight', stepHeight));
  }
}

class RenderIntrinsicHeight extends RenderProxyBox {
  RenderIntrinsicHeight({
    RenderBox child,
  }) : super(child);

  @override
  double computeMinIntrinsicWidth(double height) {
    if (child == null) return 0.0;
    if (!height.isFinite) height = child.getMaxIntrinsicHeight(double.infinity);
    assert(height.isFinite);
    return child.getMinIntrinsicWidth(height);
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    if (child == null) return 0.0;
    if (!height.isFinite) height = child.getMaxIntrinsicHeight(double.infinity);
    assert(height.isFinite);
    return child.getMaxIntrinsicWidth(height);
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return computeMaxIntrinsicHeight(width);
  }

  @override
  void performLayout() {
    if (child != null) {
      BoxConstraints childConstraints = constraints;
      if (!childConstraints.hasTightHeight) {
        final double height =
            child.getMaxIntrinsicHeight(childConstraints.maxWidth);
        assert(height.isFinite);
        childConstraints = childConstraints.tighten(height: height);
      }
      child.layout(childConstraints, parentUsesSize: true);
      size = child.size;
    } else {
      performResize();
    }
  }
}

int _getAlphaFromOpacity(double opacity) => (opacity * 255).round();

class RenderOpacity extends RenderProxyBox {
  RenderOpacity({
    double opacity = 1.0,
    bool alwaysIncludeSemantics = false,
    RenderBox child,
  })  : assert(opacity != null),
        assert(opacity >= 0.0 && opacity <= 1.0),
        assert(alwaysIncludeSemantics != null),
        _opacity = opacity,
        _alwaysIncludeSemantics = alwaysIncludeSemantics,
        _alpha = _getAlphaFromOpacity(opacity),
        super(child);

  @override
  bool get alwaysNeedsCompositing =>
      child != null && (_alpha != 0 && _alpha != 255);

  int _alpha;

  double get opacity => _opacity;
  double _opacity;
  set opacity(double value) {
    assert(value != null);
    assert(value >= 0.0 && value <= 1.0);
    if (_opacity == value) return;
    final bool didNeedCompositing = alwaysNeedsCompositing;
    final bool wasVisible = _alpha != 0;
    _opacity = value;
    _alpha = _getAlphaFromOpacity(_opacity);
    if (didNeedCompositing != alwaysNeedsCompositing)
      markNeedsCompositingBitsUpdate();
    markNeedsPaint();
    if (wasVisible != (_alpha != 0)) markNeedsSemanticsUpdate();
  }

  bool get alwaysIncludeSemantics => _alwaysIncludeSemantics;
  bool _alwaysIncludeSemantics;
  set alwaysIncludeSemantics(bool value) {
    if (value == _alwaysIncludeSemantics) return;
    _alwaysIncludeSemantics = value;
    markNeedsSemanticsUpdate();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      if (_alpha == 0) {
        layer = null;
        return;
      }
      if (_alpha == 255) {
        layer = null;
        context.paintChild(child, offset);
        return;
      }
      assert(needsCompositing);
      layer = context.pushOpacity(offset, _alpha, super.paint, oldLayer: layer);
    }
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    if (child != null && (_alpha != 0 || alwaysIncludeSemantics))
      visitor(child);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('opacity', opacity));
    properties.add(FlagProperty('alwaysIncludeSemantics',
        value: alwaysIncludeSemantics, ifTrue: 'alwaysIncludeSemantics'));
  }
}

class RenderAnimatedOpacity extends RenderProxyBox {
  RenderAnimatedOpacity({
    @required Animation<double> opacity,
    bool alwaysIncludeSemantics = false,
    RenderBox child,
  })  : assert(opacity != null),
        assert(alwaysIncludeSemantics != null),
        _alwaysIncludeSemantics = alwaysIncludeSemantics,
        super(child) {
    this.opacity = opacity;
  }

  int _alpha;

  @override
  bool get alwaysNeedsCompositing =>
      child != null && _currentlyNeedsCompositing;
  bool _currentlyNeedsCompositing;

  Animation<double> get opacity => _opacity;
  Animation<double> _opacity;
  set opacity(Animation<double> value) {
    assert(value != null);
    if (_opacity == value) return;
    if (attached && _opacity != null) _opacity.removeListener(_updateOpacity);
    _opacity = value;
    if (attached) _opacity.addListener(_updateOpacity);
    _updateOpacity();
  }

  bool get alwaysIncludeSemantics => _alwaysIncludeSemantics;
  bool _alwaysIncludeSemantics;
  set alwaysIncludeSemantics(bool value) {
    if (value == _alwaysIncludeSemantics) return;
    _alwaysIncludeSemantics = value;
    markNeedsSemanticsUpdate();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _opacity.addListener(_updateOpacity);
    _updateOpacity();
  }

  @override
  void detach() {
    _opacity.removeListener(_updateOpacity);
    super.detach();
  }

  void _updateOpacity() {
    final int oldAlpha = _alpha;
    _alpha = _getAlphaFromOpacity(_opacity.value.clamp(0.0, 1.0));
    if (oldAlpha != _alpha) {
      final bool didNeedCompositing = _currentlyNeedsCompositing;
      _currentlyNeedsCompositing = _alpha > 0 && _alpha < 255;
      if (child != null && didNeedCompositing != _currentlyNeedsCompositing)
        markNeedsCompositingBitsUpdate();
      markNeedsPaint();
      if (oldAlpha == 0 || _alpha == 0) markNeedsSemanticsUpdate();
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      if (_alpha == 0) {
        layer = null;
        return;
      }
      if (_alpha == 255) {
        layer = null;
        context.paintChild(child, offset);
        return;
      }
      assert(needsCompositing);
      layer = context.pushOpacity(offset, _alpha, super.paint, oldLayer: layer);
    }
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    if (child != null && (_alpha != 0 || alwaysIncludeSemantics))
      visitor(child);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Animation<double>>('opacity', opacity));
    properties.add(FlagProperty('alwaysIncludeSemantics',
        value: alwaysIncludeSemantics, ifTrue: 'alwaysIncludeSemantics'));
  }
}

typedef ShaderCallback = Shader Function(Rect bounds);

class RenderShaderMask extends RenderProxyBox {
  RenderShaderMask({
    RenderBox child,
    @required ShaderCallback shaderCallback,
    BlendMode blendMode = BlendMode.modulate,
  })  : assert(shaderCallback != null),
        assert(blendMode != null),
        _shaderCallback = shaderCallback,
        _blendMode = blendMode,
        super(child);

  @override
  ShaderMaskLayer get layer => super.layer;

  ShaderCallback get shaderCallback => _shaderCallback;
  ShaderCallback _shaderCallback;
  set shaderCallback(ShaderCallback value) {
    assert(value != null);
    if (_shaderCallback == value) return;
    _shaderCallback = value;
    markNeedsPaint();
  }

  BlendMode get blendMode => _blendMode;
  BlendMode _blendMode;
  set blendMode(BlendMode value) {
    assert(value != null);
    if (_blendMode == value) return;
    _blendMode = value;
    markNeedsPaint();
  }

  @override
  bool get alwaysNeedsCompositing => child != null;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      assert(needsCompositing);
      layer ??= ShaderMaskLayer();
      layer
        ..shader = _shaderCallback(offset & size)
        ..maskRect = offset & size
        ..blendMode = _blendMode;
      context.pushLayer(layer, super.paint, offset);
    } else {
      layer = null;
    }
  }
}

class RenderBackdropFilter extends RenderProxyBox {
  RenderBackdropFilter({RenderBox child, @required ui.ImageFilter filter})
      : assert(filter != null),
        _filter = filter,
        super(child);

  @override
  BackdropFilterLayer get layer => super.layer;

  ui.ImageFilter get filter => _filter;
  ui.ImageFilter _filter;
  set filter(ui.ImageFilter value) {
    assert(value != null);
    if (_filter == value) return;
    _filter = value;
    markNeedsPaint();
  }

  @override
  bool get alwaysNeedsCompositing => child != null;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      assert(needsCompositing);
      layer ??= BackdropFilterLayer();
      layer.filter = _filter;
      context.pushLayer(layer, super.paint, offset);
    } else {
      layer = null;
    }
  }
}

abstract class CustomClipper<T> {
  const CustomClipper({Listenable reclip}) : _reclip = reclip;

  final Listenable _reclip;

  T getClip(Size size);

  Rect getApproximateClipRect(Size size) => Offset.zero & size;

  bool shouldReclip(covariant CustomClipper<T> oldClipper);

  @override
  String toString() => '$runtimeType';
}

class ShapeBorderClipper extends CustomClipper<Path> {
  const ShapeBorderClipper({
    @required this.shape,
    this.textDirection,
  }) : assert(shape != null);

  final ShapeBorder shape;

  final TextDirection textDirection;

  @override
  Path getClip(Size size) {
    return shape.getOuterPath(Offset.zero & size, textDirection: textDirection);
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    if (oldClipper.runtimeType != ShapeBorderClipper) return true;
    final ShapeBorderClipper typedOldClipper = oldClipper;
    return typedOldClipper.shape != shape ||
        typedOldClipper.textDirection != textDirection;
  }
}

abstract class _RenderCustomClip<T> extends RenderProxyBox {
  _RenderCustomClip({
    RenderBox child,
    CustomClipper<T> clipper,
    Clip clipBehavior = Clip.antiAlias,
  })  : assert(clipBehavior != null),
        _clipper = clipper,
        _clipBehavior = clipBehavior,
        super(child);

  CustomClipper<T> get clipper => _clipper;
  CustomClipper<T> _clipper;
  set clipper(CustomClipper<T> newClipper) {
    if (_clipper == newClipper) return;
    final CustomClipper<T> oldClipper = _clipper;
    _clipper = newClipper;
    assert(newClipper != null || oldClipper != null);
    if (newClipper == null ||
        oldClipper == null ||
        newClipper.runtimeType != oldClipper.runtimeType ||
        newClipper.shouldReclip(oldClipper)) {
      _markNeedsClip();
    }
    if (attached) {
      oldClipper?._reclip?.removeListener(_markNeedsClip);
      newClipper?._reclip?.addListener(_markNeedsClip);
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _clipper?._reclip?.addListener(_markNeedsClip);
  }

  @override
  void detach() {
    _clipper?._reclip?.removeListener(_markNeedsClip);
    super.detach();
  }

  void _markNeedsClip() {
    _clip = null;
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  T get _defaultClip;
  T _clip;

  Clip get clipBehavior => _clipBehavior;
  set clipBehavior(Clip value) {
    if (value != _clipBehavior) {
      _clipBehavior = value;
      markNeedsPaint();
    }
  }

  Clip _clipBehavior;

  @override
  void performLayout() {
    final Size oldSize = hasSize ? size : null;
    super.performLayout();
    if (oldSize != size) _clip = null;
  }

  void _updateClip() {
    _clip ??= _clipper?.getClip(size) ?? _defaultClip;
  }

  @override
  Rect describeApproximatePaintClip(RenderObject child) {
    return _clipper?.getApproximateClipRect(size) ?? Offset.zero & size;
  }

  Paint _debugPaint;
  TextPainter _debugText;
  @override
  void debugPaintSize(PaintingContext context, Offset offset) {
    assert(() {
      _debugPaint ??= Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0.0, 0.0),
          const Offset(10.0, 10.0),
          <Color>[
            const Color(0x00000000),
            const Color(0xFFFF00FF),
            const Color(0xFFFF00FF),
            const Color(0x00000000)
          ],
          <double>[0.25, 0.25, 0.75, 0.75],
          TileMode.repeated,
        )
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      _debugText ??= TextPainter(
        text: const TextSpan(
          text: '✂',
          style: TextStyle(
            color: Color(0xFFFF00FF),
            fontSize: 14.0,
          ),
        ),
        textDirection: TextDirection.rtl,
      )..layout();
      return true;
    }());
  }
}

class RenderClipRect extends _RenderCustomClip<Rect> {
  RenderClipRect({
    RenderBox child,
    CustomClipper<Rect> clipper,
    Clip clipBehavior = Clip.antiAlias,
  })  : assert(clipBehavior != null),
        assert(clipBehavior != Clip.none),
        super(child: child, clipper: clipper, clipBehavior: clipBehavior);

  @override
  Rect get _defaultClip => Offset.zero & size;

  @override
  bool hitTest(BoxHitTestResult result, {Offset position}) {
    if (_clipper != null) {
      _updateClip();
      assert(_clip != null);
      if (!_clip.contains(position)) return false;
    }
    return super.hitTest(result, position: position);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      _updateClip();
      layer = context.pushClipRect(needsCompositing, offset, _clip, super.paint,
          clipBehavior: clipBehavior, oldLayer: layer);
    } else {
      layer = null;
    }
  }

  @override
  void debugPaintSize(PaintingContext context, Offset offset) {
    assert(() {
      if (child != null) {
        super.debugPaintSize(context, offset);
        context.canvas.drawRect(_clip.shift(offset), _debugPaint);
        _debugText.paint(
            context.canvas,
            offset +
                Offset(
                    _clip.width / 8.0, -_debugText.text.style.fontSize * 1.1));
      }
      return true;
    }());
  }
}

class RenderClipRRect extends _RenderCustomClip<RRect> {
  RenderClipRRect({
    RenderBox child,
    BorderRadius borderRadius = BorderRadius.zero,
    CustomClipper<RRect> clipper,
    Clip clipBehavior = Clip.antiAlias,
  })  : assert(clipBehavior != null),
        assert(clipBehavior != Clip.none),
        _borderRadius = borderRadius,
        super(child: child, clipper: clipper, clipBehavior: clipBehavior) {
    assert(_borderRadius != null || clipper != null);
  }

  BorderRadius get borderRadius => _borderRadius;
  BorderRadius _borderRadius;
  set borderRadius(BorderRadius value) {
    assert(value != null);
    if (_borderRadius == value) return;
    _borderRadius = value;
    _markNeedsClip();
  }

  @override
  RRect get _defaultClip => _borderRadius.toRRect(Offset.zero & size);

  @override
  bool hitTest(BoxHitTestResult result, {Offset position}) {
    if (_clipper != null) {
      _updateClip();
      assert(_clip != null);
      if (!_clip.contains(position)) return false;
    }
    return super.hitTest(result, position: position);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      _updateClip();
      layer = context.pushClipRRect(
          needsCompositing, offset, _clip.outerRect, _clip, super.paint,
          clipBehavior: clipBehavior, oldLayer: layer);
    } else {
      layer = null;
    }
  }

  @override
  void debugPaintSize(PaintingContext context, Offset offset) {
    assert(() {
      if (child != null) {
        super.debugPaintSize(context, offset);
        context.canvas.drawRRect(_clip.shift(offset), _debugPaint);
        _debugText.paint(
            context.canvas,
            offset +
                Offset(_clip.tlRadiusX, -_debugText.text.style.fontSize * 1.1));
      }
      return true;
    }());
  }
}

class RenderClipOval extends _RenderCustomClip<Rect> {
  RenderClipOval({
    RenderBox child,
    CustomClipper<Rect> clipper,
    Clip clipBehavior = Clip.antiAlias,
  })  : assert(clipBehavior != null),
        assert(clipBehavior != Clip.none),
        super(child: child, clipper: clipper, clipBehavior: clipBehavior);

  Rect _cachedRect;
  Path _cachedPath;

  Path _getClipPath(Rect rect) {
    if (rect != _cachedRect) {
      _cachedRect = rect;
      _cachedPath = Path()..addOval(_cachedRect);
    }
    return _cachedPath;
  }

  @override
  Rect get _defaultClip => Offset.zero & size;

  @override
  bool hitTest(BoxHitTestResult result, {Offset position}) {
    _updateClip();
    assert(_clip != null);
    final Offset center = _clip.center;

    final Offset offset = Offset((position.dx - center.dx) / _clip.width,
        (position.dy - center.dy) / _clip.height);

    if (offset.distanceSquared > 0.25) return false;
    return super.hitTest(result, position: position);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      _updateClip();
      layer = context.pushClipPath(
          needsCompositing, offset, _clip, _getClipPath(_clip), super.paint,
          clipBehavior: clipBehavior, oldLayer: layer);
    } else {
      layer = null;
    }
  }

  @override
  void debugPaintSize(PaintingContext context, Offset offset) {
    assert(() {
      if (child != null) {
        super.debugPaintSize(context, offset);
        context.canvas.drawPath(_getClipPath(_clip).shift(offset), _debugPaint);
        _debugText.paint(
            context.canvas,
            offset +
                Offset((_clip.width - _debugText.width) / 2.0,
                    -_debugText.text.style.fontSize * 1.1));
      }
      return true;
    }());
  }
}

class RenderClipPath extends _RenderCustomClip<Path> {
  RenderClipPath({
    RenderBox child,
    CustomClipper<Path> clipper,
    Clip clipBehavior = Clip.antiAlias,
  })  : assert(clipBehavior != null),
        assert(clipBehavior != Clip.none),
        super(child: child, clipper: clipper, clipBehavior: clipBehavior);

  @override
  Path get _defaultClip => Path()..addRect(Offset.zero & size);

  @override
  bool hitTest(BoxHitTestResult result, {Offset position}) {
    if (_clipper != null) {
      _updateClip();
      assert(_clip != null);
      if (!_clip.contains(position)) return false;
    }
    return super.hitTest(result, position: position);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      _updateClip();
      layer = context.pushClipPath(
          needsCompositing, offset, Offset.zero & size, _clip, super.paint,
          clipBehavior: clipBehavior, oldLayer: layer);
    } else {
      layer = null;
    }
  }

  @override
  void debugPaintSize(PaintingContext context, Offset offset) {
    assert(() {
      if (child != null) {
        super.debugPaintSize(context, offset);
        context.canvas.drawPath(_clip.shift(offset), _debugPaint);
        _debugText.paint(context.canvas, offset);
      }
      return true;
    }());
  }
}

abstract class _RenderPhysicalModelBase<T> extends _RenderCustomClip<T> {
  _RenderPhysicalModelBase({
    @required RenderBox child,
    @required double elevation,
    @required Color color,
    @required Color shadowColor,
    Clip clipBehavior = Clip.none,
    CustomClipper<T> clipper,
  })  : assert(elevation != null && elevation >= 0.0),
        assert(color != null),
        assert(shadowColor != null),
        assert(clipBehavior != null),
        _elevation = elevation,
        _color = color,
        _shadowColor = shadowColor,
        super(child: child, clipBehavior: clipBehavior, clipper: clipper);

  double get elevation => _elevation;
  double _elevation;
  set elevation(double value) {
    assert(value != null && value >= 0.0);
    if (elevation == value) return;
    final bool didNeedCompositing = alwaysNeedsCompositing;
    _elevation = value;
    if (didNeedCompositing != alwaysNeedsCompositing)
      markNeedsCompositingBitsUpdate();
    markNeedsPaint();
  }

  Color get shadowColor => _shadowColor;
  Color _shadowColor;
  set shadowColor(Color value) {
    assert(value != null);
    if (shadowColor == value) return;
    _shadowColor = value;
    markNeedsPaint();
  }

  Color get color => _color;
  Color _color;
  set color(Color value) {
    assert(value != null);
    if (color == value) return;
    _color = value;
    markNeedsPaint();
  }

  @override
  bool get alwaysNeedsCompositing => true;

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config.elevation = elevation;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(DoubleProperty('elevation', elevation));
    description.add(ColorProperty('color', color));
    description.add(ColorProperty('shadowColor', color));
  }
}

class RenderPhysicalModel extends _RenderPhysicalModelBase<RRect> {
  RenderPhysicalModel({
    RenderBox child,
    BoxShape shape = BoxShape.rectangle,
    Clip clipBehavior = Clip.none,
    BorderRadius borderRadius,
    double elevation = 0.0,
    @required Color color,
    Color shadowColor = const Color(0xFF000000),
  })  : assert(shape != null),
        assert(clipBehavior != null),
        assert(elevation != null && elevation >= 0.0),
        assert(color != null),
        assert(shadowColor != null),
        _shape = shape,
        _borderRadius = borderRadius,
        super(
            clipBehavior: clipBehavior,
            child: child,
            elevation: elevation,
            color: color,
            shadowColor: shadowColor);

  @override
  PhysicalModelLayer get layer => super.layer;

  BoxShape get shape => _shape;
  BoxShape _shape;
  set shape(BoxShape value) {
    assert(value != null);
    if (shape == value) return;
    _shape = value;
    _markNeedsClip();
  }

  BorderRadius get borderRadius => _borderRadius;
  BorderRadius _borderRadius;
  set borderRadius(BorderRadius value) {
    if (borderRadius == value) return;
    _borderRadius = value;
    _markNeedsClip();
  }

  @override
  RRect get _defaultClip {
    assert(hasSize);
    assert(_shape != null);
    switch (_shape) {
      case BoxShape.rectangle:
        return (borderRadius ?? BorderRadius.zero).toRRect(Offset.zero & size);
      case BoxShape.circle:
        final Rect rect = Offset.zero & size;
        return RRect.fromRectXY(rect, rect.width / 2, rect.height / 2);
    }
    return null;
  }

  @override
  bool hitTest(BoxHitTestResult result, {Offset position}) {
    if (_clipper != null) {
      _updateClip();
      assert(_clip != null);
      if (!_clip.contains(position)) return false;
    }
    return super.hitTest(result, position: position);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      _updateClip();
      final RRect offsetRRect = _clip.shift(offset);
      final Rect offsetBounds = offsetRRect.outerRect;
      final Path offsetRRectAsPath = Path()..addRRect(offsetRRect);
      bool paintShadows = true;
      assert(() {
        if (debugDisableShadows) {
          if (elevation > 0.0) {
            context.canvas.drawRRect(
              offsetRRect,
              Paint()
                ..color = shadowColor
                ..style = PaintingStyle.stroke
                ..strokeWidth = elevation * 2.0,
            );
          }
          paintShadows = false;
        }
        return true;
      }());
      layer ??= PhysicalModelLayer();
      layer
        ..clipPath = offsetRRectAsPath
        ..clipBehavior = clipBehavior
        ..elevation = paintShadows ? elevation : 0.0
        ..color = color
        ..shadowColor = shadowColor;
      context.pushLayer(layer, super.paint, offset,
          childPaintBounds: offsetBounds);
      assert(() {
        layer.debugCreator = debugCreator;
        return true;
      }());
    } else {
      layer = null;
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(DiagnosticsProperty<BoxShape>('shape', shape));
    description
        .add(DiagnosticsProperty<BorderRadius>('borderRadius', borderRadius));
  }
}

class RenderPhysicalShape extends _RenderPhysicalModelBase<Path> {
  RenderPhysicalShape({
    RenderBox child,
    @required CustomClipper<Path> clipper,
    Clip clipBehavior = Clip.none,
    double elevation = 0.0,
    @required Color color,
    Color shadowColor = const Color(0xFF000000),
  })  : assert(clipper != null),
        assert(elevation != null && elevation >= 0.0),
        assert(color != null),
        assert(shadowColor != null),
        super(
            child: child,
            elevation: elevation,
            color: color,
            shadowColor: shadowColor,
            clipper: clipper,
            clipBehavior: clipBehavior);

  @override
  PhysicalModelLayer get layer => super.layer;

  @override
  Path get _defaultClip => Path()..addRect(Offset.zero & size);

  @override
  bool hitTest(BoxHitTestResult result, {Offset position}) {
    if (_clipper != null) {
      _updateClip();
      assert(_clip != null);
      if (!_clip.contains(position)) return false;
    }
    return super.hitTest(result, position: position);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      _updateClip();
      final Rect offsetBounds = offset & size;
      final Path offsetPath = _clip.shift(offset);
      bool paintShadows = true;
      assert(() {
        if (debugDisableShadows) {
          if (elevation > 0.0) {
            context.canvas.drawPath(
              offsetPath,
              Paint()
                ..color = shadowColor
                ..style = PaintingStyle.stroke
                ..strokeWidth = elevation * 2.0,
            );
          }
          paintShadows = false;
        }
        return true;
      }());
      layer ??= PhysicalModelLayer();
      layer
        ..clipPath = offsetPath
        ..clipBehavior = clipBehavior
        ..elevation = paintShadows ? elevation : 0.0
        ..color = color
        ..shadowColor = shadowColor;
      context.pushLayer(layer, super.paint, offset,
          childPaintBounds: offsetBounds);
      assert(() {
        layer.debugCreator = debugCreator;
        return true;
      }());
    } else {
      layer = null;
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description
        .add(DiagnosticsProperty<CustomClipper<Path>>('clipper', clipper));
  }
}

enum DecorationPosition {
  background,

  foreground,
}

class RenderDecoratedBox extends RenderProxyBox {
  RenderDecoratedBox({
    @required Decoration decoration,
    DecorationPosition position = DecorationPosition.background,
    ImageConfiguration configuration = ImageConfiguration.empty,
    RenderBox child,
  })  : assert(decoration != null),
        assert(position != null),
        assert(configuration != null),
        _decoration = decoration,
        _position = position,
        _configuration = configuration,
        super(child);

  BoxPainter _painter;

  Decoration get decoration => _decoration;
  Decoration _decoration;
  set decoration(Decoration value) {
    assert(value != null);
    if (value == _decoration) return;
    _painter?.dispose();
    _painter = null;
    _decoration = value;
    markNeedsPaint();
  }

  DecorationPosition get position => _position;
  DecorationPosition _position;
  set position(DecorationPosition value) {
    assert(value != null);
    if (value == _position) return;
    _position = value;
    markNeedsPaint();
  }

  ImageConfiguration get configuration => _configuration;
  ImageConfiguration _configuration;
  set configuration(ImageConfiguration value) {
    assert(value != null);
    if (value == _configuration) return;
    _configuration = value;
    markNeedsPaint();
  }

  @override
  void detach() {
    _painter?.dispose();
    _painter = null;
    super.detach();

    markNeedsPaint();
  }

  @override
  bool hitTestSelf(Offset position) {
    return _decoration.hitTest(size, position,
        textDirection: configuration.textDirection);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    assert(size.width != null);
    assert(size.height != null);
    _painter ??= _decoration.createBoxPainter(markNeedsPaint);
    final ImageConfiguration filledConfiguration =
        configuration.copyWith(size: size);
    if (position == DecorationPosition.background) {
      int debugSaveCount;
      assert(() {
        debugSaveCount = context.canvas.getSaveCount();
        return true;
      }());
      _painter.paint(context.canvas, offset, filledConfiguration);
      assert(() {
        if (debugSaveCount != context.canvas.getSaveCount()) {
          throw FlutterError(
              '${_decoration.runtimeType} painter had mismatching save and restore calls.\n'
              'Before painting the decoration, the canvas save count was $debugSaveCount. '
              'After painting it, the canvas save count was ${context.canvas.getSaveCount()}. '
              'Every call to save() or saveLayer() must be matched by a call to restore().\n'
              'The decoration was:\n'
              '  $decoration\n'
              'The painter was:\n'
              '  $_painter');
        }
        return true;
      }());
      if (decoration.isComplex) context.setIsComplexHint();
    }
    super.paint(context, offset);
    if (position == DecorationPosition.foreground) {
      _painter.paint(context.canvas, offset, filledConfiguration);
      if (decoration.isComplex) context.setIsComplexHint();
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(_decoration.toDiagnosticsNode(name: 'decoration'));
    properties.add(DiagnosticsProperty<ImageConfiguration>(
        'configuration', configuration));
  }
}

class RenderTransform extends RenderProxyBox {
  RenderTransform({
    @required Matrix4 transform,
    Offset origin,
    AlignmentGeometry alignment,
    TextDirection textDirection,
    this.transformHitTests = true,
    RenderBox child,
  })  : assert(transform != null),
        super(child) {
    this.transform = transform;
    this.alignment = alignment;
    this.textDirection = textDirection;
    this.origin = origin;
  }

  Offset get origin => _origin;
  Offset _origin;
  set origin(Offset value) {
    if (_origin == value) return;
    _origin = value;
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  AlignmentGeometry get alignment => _alignment;
  AlignmentGeometry _alignment;
  set alignment(AlignmentGeometry value) {
    if (_alignment == value) return;
    _alignment = value;
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (_textDirection == value) return;
    _textDirection = value;
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  bool transformHitTests;

  Matrix4 _transform;

  set transform(Matrix4 value) {
    assert(value != null);
    if (_transform == value) return;
    _transform = Matrix4.copy(value);
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  void setIdentity() {
    _transform.setIdentity();
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  void rotateX(double radians) {
    _transform.rotateX(radians);
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  void rotateY(double radians) {
    _transform.rotateY(radians);
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  void rotateZ(double radians) {
    _transform.rotateZ(radians);
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  void translate(double x, [double y = 0.0, double z = 0.0]) {
    _transform.translate(x, y, z);
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  void scale(double x, [double y, double z]) {
    _transform.scale(x, y, z);
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  Matrix4 get _effectiveTransform {
    final Alignment resolvedAlignment = alignment?.resolve(textDirection);
    if (_origin == null && resolvedAlignment == null) return _transform;
    final Matrix4 result = Matrix4.identity();
    if (_origin != null) result.translate(_origin.dx, _origin.dy);
    Offset translation;
    if (resolvedAlignment != null) {
      translation = resolvedAlignment.alongSize(size);
      result.translate(translation.dx, translation.dy);
    }
    result.multiply(_transform);
    if (resolvedAlignment != null)
      result.translate(-translation.dx, -translation.dy);
    if (_origin != null) result.translate(-_origin.dx, -_origin.dy);
    return result;
  }

  @override
  bool hitTest(BoxHitTestResult result, {Offset position}) {
    return hitTestChildren(result, position: position);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {Offset position}) {
    assert(!transformHitTests || _effectiveTransform != null);
    return result.addWithPaintTransform(
      transform: transformHitTests ? _effectiveTransform : null,
      position: position,
      hitTest: (BoxHitTestResult result, Offset position) {
        return super.hitTestChildren(result, position: position);
      },
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      final Matrix4 transform = _effectiveTransform;
      final Offset childOffset = MatrixUtils.getAsTranslation(transform);
      if (childOffset == null) {
        layer = context.pushTransform(
            needsCompositing, offset, transform, super.paint,
            oldLayer: layer);
      } else {
        super.paint(context, offset + childOffset);
        layer = null;
      }
    }
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.multiply(_effectiveTransform);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(TransformProperty('transform matrix', _transform));
    properties.add(DiagnosticsProperty<Offset>('origin', origin));
    properties.add(DiagnosticsProperty<Alignment>('alignment', alignment));
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection,
        defaultValue: null));
    properties
        .add(DiagnosticsProperty<bool>('transformHitTests', transformHitTests));
  }
}

class RenderFittedBox extends RenderProxyBox {
  RenderFittedBox({
    BoxFit fit = BoxFit.contain,
    AlignmentGeometry alignment = Alignment.center,
    TextDirection textDirection,
    RenderBox child,
  })  : assert(fit != null),
        assert(alignment != null),
        _fit = fit,
        _alignment = alignment,
        _textDirection = textDirection,
        super(child);

  Alignment _resolvedAlignment;

  void _resolve() {
    if (_resolvedAlignment != null) return;
    _resolvedAlignment = alignment.resolve(textDirection);
  }

  void _markNeedResolution() {
    _resolvedAlignment = null;
    markNeedsPaint();
  }

  BoxFit get fit => _fit;
  BoxFit _fit;
  set fit(BoxFit value) {
    assert(value != null);
    if (_fit == value) return;
    _fit = value;
    _clearPaintData();
    markNeedsPaint();
  }

  AlignmentGeometry get alignment => _alignment;
  AlignmentGeometry _alignment;
  set alignment(AlignmentGeometry value) {
    assert(value != null);
    if (_alignment == value) return;
    _alignment = value;
    _clearPaintData();
    _markNeedResolution();
  }

  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (_textDirection == value) return;
    _textDirection = value;
    _clearPaintData();
    _markNeedResolution();
  }

  @override
  void performLayout() {
    if (child != null) {
      child.layout(const BoxConstraints(), parentUsesSize: true);
      size =
          constraints.constrainSizeAndAttemptToPreserveAspectRatio(child.size);
      _clearPaintData();
    } else {
      size = constraints.smallest;
    }
  }

  bool _hasVisualOverflow;
  Matrix4 _transform;

  void _clearPaintData() {
    _hasVisualOverflow = null;
    _transform = null;
  }

  void _updatePaintData() {
    if (_transform != null) return;

    if (child == null) {
      _hasVisualOverflow = false;
      _transform = Matrix4.identity();
    } else {
      _resolve();
      final Size childSize = child.size;
      final FittedSizes sizes = applyBoxFit(_fit, childSize, size);
      final double scaleX = sizes.destination.width / sizes.source.width;
      final double scaleY = sizes.destination.height / sizes.source.height;
      final Rect sourceRect =
          _resolvedAlignment.inscribe(sizes.source, Offset.zero & childSize);
      final Rect destinationRect =
          _resolvedAlignment.inscribe(sizes.destination, Offset.zero & size);
      _hasVisualOverflow = sourceRect.width < childSize.width ||
          sourceRect.height < childSize.height;
      assert(scaleX.isFinite && scaleY.isFinite);
      _transform = Matrix4.translationValues(
          destinationRect.left, destinationRect.top, 0.0)
        ..scale(scaleX, scaleY, 1.0)
        ..translate(-sourceRect.left, -sourceRect.top);
      assert(_transform.storage.every((double value) => value.isFinite));
    }
  }

  TransformLayer _paintChildWithTransform(
      PaintingContext context, Offset offset) {
    final Offset childOffset = MatrixUtils.getAsTranslation(_transform);
    if (childOffset == null)
      return context.pushTransform(
          needsCompositing, offset, _transform, super.paint,
          oldLayer: layer is TransformLayer ? layer : null);
    else
      super.paint(context, offset + childOffset);
    return null;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (size.isEmpty || child.size.isEmpty) return;
    _updatePaintData();
    if (child != null) {
      if (_hasVisualOverflow)
        layer = context.pushClipRect(needsCompositing, offset,
            Offset.zero & size, _paintChildWithTransform,
            oldLayer: layer is ClipRectLayer ? layer : null);
      else
        layer = _paintChildWithTransform(context, offset);
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {Offset position}) {
    if (size.isEmpty || child?.size?.isEmpty == true) return false;
    _updatePaintData();
    return result.addWithPaintTransform(
      transform: _transform,
      position: position,
      hitTest: (BoxHitTestResult result, Offset position) {
        return super.hitTestChildren(result, position: position);
      },
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    if (size.isEmpty || child.size.isEmpty) {
      transform.setZero();
    } else {
      _updatePaintData();
      transform.multiply(_transform);
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<BoxFit>('fit', fit));
    properties.add(DiagnosticsProperty<Alignment>('alignment', alignment));
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection,
        defaultValue: null));
  }
}

class RenderFractionalTranslation extends RenderProxyBox {
  RenderFractionalTranslation({
    @required Offset translation,
    this.transformHitTests = true,
    RenderBox child,
  })  : assert(translation != null),
        _translation = translation,
        super(child);

  Offset get translation => _translation;
  Offset _translation;
  set translation(Offset value) {
    assert(value != null);
    if (_translation == value) return;
    _translation = value;
    markNeedsPaint();
  }

  @override
  bool hitTest(BoxHitTestResult result, {Offset position}) {
    return hitTestChildren(result, position: position);
  }

  bool transformHitTests;

  @override
  bool hitTestChildren(BoxHitTestResult result, {Offset position}) {
    assert(!debugNeedsLayout);
    return result.addWithPaintOffset(
      offset: transformHitTests
          ? Offset(translation.dx * size.width, translation.dy * size.height)
          : null,
      position: position,
      hitTest: (BoxHitTestResult result, Offset position) {
        return super.hitTestChildren(result, position: position);
      },
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    assert(!debugNeedsLayout);
    if (child != null) {
      super.paint(
          context,
          Offset(
            offset.dx + translation.dx * size.width,
            offset.dy + translation.dy * size.height,
          ));
    }
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.translate(
      translation.dx * size.width,
      translation.dy * size.height,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Offset>('translation', translation));
    properties
        .add(DiagnosticsProperty<bool>('transformHitTests', transformHitTests));
  }
}

typedef PointerDownEventListener = void Function(PointerDownEvent event);

typedef PointerMoveEventListener = void Function(PointerMoveEvent event);

typedef PointerUpEventListener = void Function(PointerUpEvent event);

typedef PointerCancelEventListener = void Function(PointerCancelEvent event);

typedef PointerSignalEventListener = void Function(PointerSignalEvent event);

class RenderPointerListener extends RenderProxyBoxWithHitTestBehavior {
  RenderPointerListener({
    this.onPointerDown,
    this.onPointerMove,
    this.onPointerUp,
    this.onPointerCancel,
    this.onPointerSignal,
    HitTestBehavior behavior = HitTestBehavior.deferToChild,
    RenderBox child,
  }) : super(behavior: behavior, child: child);

  PointerDownEventListener onPointerDown;

  PointerMoveEventListener onPointerMove;

  PointerUpEventListener onPointerUp;

  PointerCancelEventListener onPointerCancel;

  PointerSignalEventListener onPointerSignal;

  @override
  void performResize() {
    size = constraints.biggest;
  }

  @override
  void handleEvent(PointerEvent event, HitTestEntry entry) {
    assert(debugHandleEvent(event, entry));
    if (onPointerDown != null && event is PointerDownEvent)
      return onPointerDown(event);
    if (onPointerMove != null && event is PointerMoveEvent)
      return onPointerMove(event);
    if (onPointerUp != null && event is PointerUpEvent)
      return onPointerUp(event);
    if (onPointerCancel != null && event is PointerCancelEvent)
      return onPointerCancel(event);
    if (onPointerSignal != null && event is PointerSignalEvent)
      return onPointerSignal(event);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    final List<String> listeners = <String>[];
    if (onPointerDown != null) listeners.add('down');
    if (onPointerMove != null) listeners.add('move');
    if (onPointerUp != null) listeners.add('up');
    if (onPointerCancel != null) listeners.add('cancel');
    if (onPointerSignal != null) listeners.add('signal');
    if (listeners.isEmpty) listeners.add('<none>');
    properties.add(IterableProperty<String>('listeners', listeners));
  }
}

class RenderMouseRegion extends RenderProxyBox {
  RenderMouseRegion({
    PointerEnterEventListener onEnter,
    PointerHoverEventListener onHover,
    PointerExitEventListener onExit,
    RenderBox child,
  })  : _onEnter = onEnter,
        _onHover = onHover,
        _onExit = onExit,
        _annotationIsActive = false,
        super(child) {
    _hoverAnnotation = MouseTrackerAnnotation(
      onEnter: _handleEnter,
      onHover: _handleHover,
      onExit: _handleExit,
    );
  }

  PointerEnterEventListener get onEnter => _onEnter;
  set onEnter(PointerEnterEventListener value) {
    if (_onEnter != value) {
      _onEnter = value;
      _updateAnnotations();
    }
  }

  PointerEnterEventListener _onEnter;
  void _handleEnter(PointerEnterEvent event) {
    if (_onEnter != null) _onEnter(event);
  }

  PointerHoverEventListener get onHover => _onHover;
  set onHover(PointerHoverEventListener value) {
    if (_onHover != value) {
      _onHover = value;
      _updateAnnotations();
    }
  }

  PointerHoverEventListener _onHover;
  void _handleHover(PointerHoverEvent event) {
    if (_onHover != null) _onHover(event);
  }

  PointerExitEventListener get onExit => _onExit;
  set onExit(PointerExitEventListener value) {
    if (_onExit != value) {
      _onExit = value;
      _updateAnnotations();
    }
  }

  PointerExitEventListener _onExit;
  void _handleExit(PointerExitEvent event) {
    if (_onExit != null) _onExit(event);
  }

  MouseTrackerAnnotation _hoverAnnotation;

  @visibleForTesting
  MouseTrackerAnnotation get hoverAnnotation => _hoverAnnotation;

  void _updateAnnotations() {
    final bool annotationWasActive = _annotationIsActive;
    final bool annotationWillBeActive =
        (_onEnter != null || _onHover != null || _onExit != null) &&
            RendererBinding.instance.mouseTracker.mouseIsConnected;
    if (annotationWasActive != annotationWillBeActive) {
      markNeedsPaint();
      markNeedsCompositingBitsUpdate();
      if (annotationWillBeActive) {
        RendererBinding.instance.mouseTracker
            .attachAnnotation(_hoverAnnotation);
      } else {
        RendererBinding.instance.mouseTracker
            .detachAnnotation(_hoverAnnotation);
      }
      _annotationIsActive = annotationWillBeActive;
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);

    RendererBinding.instance.mouseTracker.addListener(_updateAnnotations);
    _updateAnnotations();
  }

  void postActivate() {
    if (_annotationIsActive)
      RendererBinding.instance.mouseTracker.attachAnnotation(_hoverAnnotation);
  }

  void preDeactivate() {
    if (_annotationIsActive)
      RendererBinding.instance.mouseTracker.detachAnnotation(_hoverAnnotation);
  }

  @override
  void detach() {
    RendererBinding.instance.mouseTracker.removeListener(_updateAnnotations);
    super.detach();
  }

  bool _annotationIsActive;

  @override
  bool get needsCompositing => super.needsCompositing || _annotationIsActive;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_annotationIsActive) {
      final AnnotatedRegionLayer<MouseTrackerAnnotation> layer =
          AnnotatedRegionLayer<MouseTrackerAnnotation>(
        _hoverAnnotation,
        size: size,
        offset: offset,
      );
      context.pushLayer(layer, super.paint, offset);
    } else {
      super.paint(context, offset);
    }
  }

  @override
  void performResize() {
    size = constraints.biggest;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    final List<String> listeners = <String>[];
    if (onEnter != null) listeners.add('enter');
    if (onHover != null) listeners.add('hover');
    if (onExit != null) listeners.add('exit');
    if (listeners.isEmpty) listeners.add('<none>');
    properties.add(IterableProperty<String>('listeners', listeners));
  }
}

class RenderRepaintBoundary extends RenderProxyBox {
  RenderRepaintBoundary({RenderBox child}) : super(child);

  @override
  bool get isRepaintBoundary => true;

  Future<ui.Image> toImage({double pixelRatio = 1.0}) {
    assert(!debugNeedsPaint);
    final OffsetLayer offsetLayer = layer;
    return offsetLayer.toImage(Offset.zero & size, pixelRatio: pixelRatio);
  }

  int get debugSymmetricPaintCount => _debugSymmetricPaintCount;
  int _debugSymmetricPaintCount = 0;

  int get debugAsymmetricPaintCount => _debugAsymmetricPaintCount;
  int _debugAsymmetricPaintCount = 0;

  void debugResetMetrics() {
    assert(() {
      _debugSymmetricPaintCount = 0;
      _debugAsymmetricPaintCount = 0;
      return true;
    }());
  }

  @override
  void debugRegisterRepaintBoundaryPaint(
      {bool includedParent = true, bool includedChild = false}) {
    assert(() {
      if (includedParent && includedChild)
        _debugSymmetricPaintCount += 1;
      else
        _debugAsymmetricPaintCount += 1;
      return true;
    }());
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    bool inReleaseMode = true;
    assert(() {
      inReleaseMode = false;
      if (debugSymmetricPaintCount + debugAsymmetricPaintCount == 0) {
        properties.add(MessageProperty(
            'usefulness ratio', 'no metrics collected yet (never painted)'));
      } else {
        final double fraction = debugAsymmetricPaintCount /
            (debugSymmetricPaintCount + debugAsymmetricPaintCount);
        String diagnosis;
        if (debugSymmetricPaintCount + debugAsymmetricPaintCount < 5) {
          diagnosis =
              'insufficient data to draw conclusion (less than five repaints)';
        } else if (fraction > 0.9) {
          diagnosis =
              'this is an outstandingly useful repaint boundary and should definitely be kept';
        } else if (fraction > 0.5) {
          diagnosis = 'this is a useful repaint boundary and should be kept';
        } else if (fraction > 0.30) {
          diagnosis =
              'this repaint boundary is probably useful, but maybe it would be more useful in tandem with adding more repaint boundaries elsewhere';
        } else if (fraction > 0.1) {
          diagnosis =
              'this repaint boundary does sometimes show value, though currently not that often';
        } else if (debugAsymmetricPaintCount == 0) {
          diagnosis =
              'this repaint boundary is astoundingly ineffectual and should be removed';
        } else {
          diagnosis =
              'this repaint boundary is not very effective and should probably be removed';
        }
        properties.add(PercentProperty('metrics', fraction,
            unit: 'useful',
            tooltip:
                '$debugSymmetricPaintCount bad vs $debugAsymmetricPaintCount good'));
        properties.add(MessageProperty('diagnosis', diagnosis));
      }
      return true;
    }());
    if (inReleaseMode)
      properties.add(DiagnosticsNode.message(
          '(run in checked mode to collect repaint boundary statistics)'));
  }
}

class RenderIgnorePointer extends RenderProxyBox {
  RenderIgnorePointer({
    RenderBox child,
    bool ignoring = true,
    bool ignoringSemantics,
  })  : _ignoring = ignoring,
        _ignoringSemantics = ignoringSemantics,
        super(child) {
    assert(_ignoring != null);
  }

  bool get ignoring => _ignoring;
  bool _ignoring;
  set ignoring(bool value) {
    assert(value != null);
    if (value == _ignoring) return;
    _ignoring = value;
    if (ignoringSemantics == null) markNeedsSemanticsUpdate();
  }

  bool get ignoringSemantics => _ignoringSemantics;
  bool _ignoringSemantics;
  set ignoringSemantics(bool value) {
    if (value == _ignoringSemantics) return;
    final bool oldEffectiveValue = _effectiveIgnoringSemantics;
    _ignoringSemantics = value;
    if (oldEffectiveValue != _effectiveIgnoringSemantics)
      markNeedsSemanticsUpdate();
  }

  bool get _effectiveIgnoringSemantics => ignoringSemantics ?? ignoring;

  @override
  bool hitTest(BoxHitTestResult result, {Offset position}) {
    return !ignoring && super.hitTest(result, position: position);
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    if (child != null && !_effectiveIgnoringSemantics) visitor(child);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('ignoring', ignoring));
    properties.add(DiagnosticsProperty<bool>(
      'ignoringSemantics',
      _effectiveIgnoringSemantics,
      description: ignoringSemantics == null
          ? 'implicitly $_effectiveIgnoringSemantics'
          : null,
    ));
  }
}

class RenderOffstage extends RenderProxyBox {
  RenderOffstage({
    bool offstage = true,
    RenderBox child,
  })  : assert(offstage != null),
        _offstage = offstage,
        super(child);

  bool get offstage => _offstage;
  bool _offstage;
  set offstage(bool value) {
    assert(value != null);
    if (value == _offstage) return;
    _offstage = value;
    markNeedsLayoutForSizedByParentChange();
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    if (offstage) return 0.0;
    return super.computeMinIntrinsicWidth(height);
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    if (offstage) return 0.0;
    return super.computeMaxIntrinsicWidth(height);
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    if (offstage) return 0.0;
    return super.computeMinIntrinsicHeight(width);
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    if (offstage) return 0.0;
    return super.computeMaxIntrinsicHeight(width);
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    if (offstage) return null;
    return super.computeDistanceToActualBaseline(baseline);
  }

  @override
  bool get sizedByParent => offstage;

  @override
  void performResize() {
    assert(offstage);
    size = constraints.smallest;
  }

  @override
  void performLayout() {
    if (offstage) {
      child?.layout(constraints);
    } else {
      super.performLayout();
    }
  }

  @override
  bool hitTest(BoxHitTestResult result, {Offset position}) {
    return !offstage && super.hitTest(result, position: position);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (offstage) return;
    super.paint(context, offset);
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    if (offstage) return;
    super.visitChildrenForSemantics(visitor);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('offstage', offstage));
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    if (child == null) return <DiagnosticsNode>[];
    return <DiagnosticsNode>[
      child.toDiagnosticsNode(
        name: 'child',
        style: offstage
            ? DiagnosticsTreeStyle.offstage
            : DiagnosticsTreeStyle.sparse,
      ),
    ];
  }
}

class RenderAbsorbPointer extends RenderProxyBox {
  RenderAbsorbPointer({
    RenderBox child,
    bool absorbing = true,
    bool ignoringSemantics,
  })  : assert(absorbing != null),
        _absorbing = absorbing,
        _ignoringSemantics = ignoringSemantics,
        super(child);

  bool get absorbing => _absorbing;
  bool _absorbing;
  set absorbing(bool value) {
    if (_absorbing == value) return;
    _absorbing = value;
    if (ignoringSemantics == null) markNeedsSemanticsUpdate();
  }

  bool get ignoringSemantics => _ignoringSemantics;
  bool _ignoringSemantics;
  set ignoringSemantics(bool value) {
    if (value == _ignoringSemantics) return;
    final bool oldEffectiveValue = _effectiveIgnoringSemantics;
    _ignoringSemantics = value;
    if (oldEffectiveValue != _effectiveIgnoringSemantics)
      markNeedsSemanticsUpdate();
  }

  bool get _effectiveIgnoringSemantics => ignoringSemantics ?? absorbing;

  @override
  bool hitTest(BoxHitTestResult result, {Offset position}) {
    return absorbing
        ? size.contains(position)
        : super.hitTest(result, position: position);
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    if (child != null && !_effectiveIgnoringSemantics) visitor(child);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('absorbing', absorbing));
    properties.add(
      DiagnosticsProperty<bool>(
        'ignoringSemantics',
        _effectiveIgnoringSemantics,
        description: ignoringSemantics == null
            ? 'implicitly $_effectiveIgnoringSemantics'
            : null,
      ),
    );
  }
}

class RenderMetaData extends RenderProxyBoxWithHitTestBehavior {
  RenderMetaData({
    this.metaData,
    HitTestBehavior behavior = HitTestBehavior.deferToChild,
    RenderBox child,
  }) : super(behavior: behavior, child: child);

  dynamic metaData;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<dynamic>('metaData', metaData));
  }
}

class RenderSemanticsGestureHandler extends RenderProxyBox {
  RenderSemanticsGestureHandler({
    RenderBox child,
    GestureTapCallback onTap,
    GestureLongPressCallback onLongPress,
    GestureDragUpdateCallback onHorizontalDragUpdate,
    GestureDragUpdateCallback onVerticalDragUpdate,
    this.scrollFactor = 0.8,
  })  : assert(scrollFactor != null),
        _onTap = onTap,
        _onLongPress = onLongPress,
        _onHorizontalDragUpdate = onHorizontalDragUpdate,
        _onVerticalDragUpdate = onVerticalDragUpdate,
        super(child);

  Set<SemanticsAction> get validActions => _validActions;
  Set<SemanticsAction> _validActions;
  set validActions(Set<SemanticsAction> value) {
    if (setEquals<SemanticsAction>(value, _validActions)) return;
    _validActions = value;
    markNeedsSemanticsUpdate();
  }

  GestureTapCallback get onTap => _onTap;
  GestureTapCallback _onTap;
  set onTap(GestureTapCallback value) {
    if (_onTap == value) return;
    final bool hadHandler = _onTap != null;
    _onTap = value;
    if ((value != null) != hadHandler) markNeedsSemanticsUpdate();
  }

  GestureLongPressCallback get onLongPress => _onLongPress;
  GestureLongPressCallback _onLongPress;
  set onLongPress(GestureLongPressCallback value) {
    if (_onLongPress == value) return;
    final bool hadHandler = _onLongPress != null;
    _onLongPress = value;
    if ((value != null) != hadHandler) markNeedsSemanticsUpdate();
  }

  GestureDragUpdateCallback get onHorizontalDragUpdate =>
      _onHorizontalDragUpdate;
  GestureDragUpdateCallback _onHorizontalDragUpdate;
  set onHorizontalDragUpdate(GestureDragUpdateCallback value) {
    if (_onHorizontalDragUpdate == value) return;
    final bool hadHandler = _onHorizontalDragUpdate != null;
    _onHorizontalDragUpdate = value;
    if ((value != null) != hadHandler) markNeedsSemanticsUpdate();
  }

  GestureDragUpdateCallback get onVerticalDragUpdate => _onVerticalDragUpdate;
  GestureDragUpdateCallback _onVerticalDragUpdate;
  set onVerticalDragUpdate(GestureDragUpdateCallback value) {
    if (_onVerticalDragUpdate == value) return;
    final bool hadHandler = _onVerticalDragUpdate != null;
    _onVerticalDragUpdate = value;
    if ((value != null) != hadHandler) markNeedsSemanticsUpdate();
  }

  double scrollFactor;

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);

    if (onTap != null && _isValidAction(SemanticsAction.tap))
      config.onTap = onTap;
    if (onLongPress != null && _isValidAction(SemanticsAction.longPress))
      config.onLongPress = onLongPress;
    if (onHorizontalDragUpdate != null) {
      if (_isValidAction(SemanticsAction.scrollRight))
        config.onScrollRight = _performSemanticScrollRight;
      if (_isValidAction(SemanticsAction.scrollLeft))
        config.onScrollLeft = _performSemanticScrollLeft;
    }
    if (onVerticalDragUpdate != null) {
      if (_isValidAction(SemanticsAction.scrollUp))
        config.onScrollUp = _performSemanticScrollUp;
      if (_isValidAction(SemanticsAction.scrollDown))
        config.onScrollDown = _performSemanticScrollDown;
    }
  }

  bool _isValidAction(SemanticsAction action) {
    return validActions == null || validActions.contains(action);
  }

  void _performSemanticScrollLeft() {
    if (onHorizontalDragUpdate != null) {
      final double primaryDelta = size.width * -scrollFactor;
      onHorizontalDragUpdate(DragUpdateDetails(
        delta: Offset(primaryDelta, 0.0),
        primaryDelta: primaryDelta,
        globalPosition: localToGlobal(size.center(Offset.zero)),
      ));
    }
  }

  void _performSemanticScrollRight() {
    if (onHorizontalDragUpdate != null) {
      final double primaryDelta = size.width * scrollFactor;
      onHorizontalDragUpdate(DragUpdateDetails(
        delta: Offset(primaryDelta, 0.0),
        primaryDelta: primaryDelta,
        globalPosition: localToGlobal(size.center(Offset.zero)),
      ));
    }
  }

  void _performSemanticScrollUp() {
    if (onVerticalDragUpdate != null) {
      final double primaryDelta = size.height * -scrollFactor;
      onVerticalDragUpdate(DragUpdateDetails(
        delta: Offset(0.0, primaryDelta),
        primaryDelta: primaryDelta,
        globalPosition: localToGlobal(size.center(Offset.zero)),
      ));
    }
  }

  void _performSemanticScrollDown() {
    if (onVerticalDragUpdate != null) {
      final double primaryDelta = size.height * scrollFactor;
      onVerticalDragUpdate(DragUpdateDetails(
        delta: Offset(0.0, primaryDelta),
        primaryDelta: primaryDelta,
        globalPosition: localToGlobal(size.center(Offset.zero)),
      ));
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    final List<String> gestures = <String>[];
    if (onTap != null) gestures.add('tap');
    if (onLongPress != null) gestures.add('long press');
    if (onHorizontalDragUpdate != null) gestures.add('horizontal scroll');
    if (onVerticalDragUpdate != null) gestures.add('vertical scroll');
    if (gestures.isEmpty) gestures.add('<none>');
    properties.add(IterableProperty<String>('gestures', gestures));
  }
}

class RenderSemanticsAnnotations extends RenderProxyBox {
  RenderSemanticsAnnotations({
    RenderBox child,
    bool container = false,
    bool explicitChildNodes,
    bool excludeSemantics = false,
    bool enabled,
    bool checked,
    bool toggled,
    bool selected,
    bool button,
    bool header,
    bool textField,
    bool readOnly,
    bool focused,
    bool inMutuallyExclusiveGroup,
    bool obscured,
    bool multiline,
    bool scopesRoute,
    bool namesRoute,
    bool hidden,
    bool image,
    bool liveRegion,
    String label,
    String value,
    String increasedValue,
    String decreasedValue,
    String hint,
    SemanticsHintOverrides hintOverrides,
    TextDirection textDirection,
    SemanticsSortKey sortKey,
    VoidCallback onTap,
    VoidCallback onDismiss,
    VoidCallback onLongPress,
    VoidCallback onScrollLeft,
    VoidCallback onScrollRight,
    VoidCallback onScrollUp,
    VoidCallback onScrollDown,
    VoidCallback onIncrease,
    VoidCallback onDecrease,
    VoidCallback onCopy,
    VoidCallback onCut,
    VoidCallback onPaste,
    MoveCursorHandler onMoveCursorForwardByCharacter,
    MoveCursorHandler onMoveCursorBackwardByCharacter,
    MoveCursorHandler onMoveCursorForwardByWord,
    MoveCursorHandler onMoveCursorBackwardByWord,
    SetSelectionHandler onSetSelection,
    VoidCallback onDidGainAccessibilityFocus,
    VoidCallback onDidLoseAccessibilityFocus,
    Map<CustomSemanticsAction, VoidCallback> customSemanticsActions,
  })  : assert(container != null),
        _container = container,
        _explicitChildNodes = explicitChildNodes,
        _excludeSemantics = excludeSemantics,
        _enabled = enabled,
        _checked = checked,
        _toggled = toggled,
        _selected = selected,
        _button = button,
        _header = header,
        _textField = textField,
        _readOnly = readOnly,
        _focused = focused,
        _inMutuallyExclusiveGroup = inMutuallyExclusiveGroup,
        _obscured = obscured,
        _multiline = multiline,
        _scopesRoute = scopesRoute,
        _namesRoute = namesRoute,
        _liveRegion = liveRegion,
        _hidden = hidden,
        _image = image,
        _onDismiss = onDismiss,
        _label = label,
        _value = value,
        _increasedValue = increasedValue,
        _decreasedValue = decreasedValue,
        _hint = hint,
        _hintOverrides = hintOverrides,
        _textDirection = textDirection,
        _sortKey = sortKey,
        _onTap = onTap,
        _onLongPress = onLongPress,
        _onScrollLeft = onScrollLeft,
        _onScrollRight = onScrollRight,
        _onScrollUp = onScrollUp,
        _onScrollDown = onScrollDown,
        _onIncrease = onIncrease,
        _onDecrease = onDecrease,
        _onCopy = onCopy,
        _onCut = onCut,
        _onPaste = onPaste,
        _onMoveCursorForwardByCharacter = onMoveCursorForwardByCharacter,
        _onMoveCursorBackwardByCharacter = onMoveCursorBackwardByCharacter,
        _onMoveCursorForwardByWord = onMoveCursorForwardByWord,
        _onMoveCursorBackwardByWord = onMoveCursorBackwardByWord,
        _onSetSelection = onSetSelection,
        _onDidGainAccessibilityFocus = onDidGainAccessibilityFocus,
        _onDidLoseAccessibilityFocus = onDidLoseAccessibilityFocus,
        _customSemanticsActions = customSemanticsActions,
        super(child);

  bool get container => _container;
  bool _container;
  set container(bool value) {
    assert(value != null);
    if (container == value) return;
    _container = value;
    markNeedsSemanticsUpdate();
  }

  bool get explicitChildNodes => _explicitChildNodes;
  bool _explicitChildNodes;
  set explicitChildNodes(bool value) {
    assert(value != null);
    if (_explicitChildNodes == value) return;
    _explicitChildNodes = value;
    markNeedsSemanticsUpdate();
  }

  bool get excludeSemantics => _excludeSemantics;
  bool _excludeSemantics;
  set excludeSemantics(bool value) {
    assert(value != null);
    if (_excludeSemantics == value) return;
    _excludeSemantics = value;
    markNeedsSemanticsUpdate();
  }

  bool get checked => _checked;
  bool _checked;
  set checked(bool value) {
    if (checked == value) return;
    _checked = value;
    markNeedsSemanticsUpdate();
  }

  bool get enabled => _enabled;
  bool _enabled;
  set enabled(bool value) {
    if (enabled == value) return;
    _enabled = value;
    markNeedsSemanticsUpdate();
  }

  bool get selected => _selected;
  bool _selected;
  set selected(bool value) {
    if (selected == value) return;
    _selected = value;
    markNeedsSemanticsUpdate();
  }

  bool get button => _button;
  bool _button;
  set button(bool value) {
    if (button == value) return;
    _button = value;
    markNeedsSemanticsUpdate();
  }

  bool get header => _header;
  bool _header;
  set header(bool value) {
    if (header == value) return;
    _header = value;
    markNeedsSemanticsUpdate();
  }

  bool get textField => _textField;
  bool _textField;
  set textField(bool value) {
    if (textField == value) return;
    _textField = value;
    markNeedsSemanticsUpdate();
  }

  bool get readOnly => _readOnly;
  bool _readOnly;
  set readOnly(bool value) {
    if (readOnly == value) return;
    _readOnly = value;
    markNeedsSemanticsUpdate();
  }

  bool get focused => _focused;
  bool _focused;
  set focused(bool value) {
    if (focused == value) return;
    _focused = value;
    markNeedsSemanticsUpdate();
  }

  bool get inMutuallyExclusiveGroup => _inMutuallyExclusiveGroup;
  bool _inMutuallyExclusiveGroup;
  set inMutuallyExclusiveGroup(bool value) {
    if (inMutuallyExclusiveGroup == value) return;
    _inMutuallyExclusiveGroup = value;
    markNeedsSemanticsUpdate();
  }

  bool get obscured => _obscured;
  bool _obscured;
  set obscured(bool value) {
    if (obscured == value) return;
    _obscured = value;
    markNeedsSemanticsUpdate();
  }

  bool get multiline => _multiline;
  bool _multiline;
  set multiline(bool value) {
    if (multiline == value) return;
    _multiline = value;
    markNeedsSemanticsUpdate();
  }

  bool get scopesRoute => _scopesRoute;
  bool _scopesRoute;
  set scopesRoute(bool value) {
    if (scopesRoute == value) return;
    _scopesRoute = value;
    markNeedsSemanticsUpdate();
  }

  bool get namesRoute => _namesRoute;
  bool _namesRoute;
  set namesRoute(bool value) {
    if (_namesRoute == value) return;
    _namesRoute = value;
    markNeedsSemanticsUpdate();
  }

  bool get hidden => _hidden;
  bool _hidden;
  set hidden(bool value) {
    if (hidden == value) return;
    _hidden = value;
    markNeedsSemanticsUpdate();
  }

  bool get image => _image;
  bool _image;
  set image(bool value) {
    if (_image == value) return;
    _image = value;
  }

  bool get liveRegion => _liveRegion;
  bool _liveRegion;
  set liveRegion(bool value) {
    if (_liveRegion == value) return;
    _liveRegion = value;
    markNeedsSemanticsUpdate();
  }

  bool get toggled => _toggled;
  bool _toggled;
  set toggled(bool value) {
    if (_toggled == value) return;
    _toggled = value;
    markNeedsSemanticsUpdate();
  }

  String get label => _label;
  String _label;
  set label(String value) {
    if (_label == value) return;
    _label = value;
    markNeedsSemanticsUpdate();
  }

  String get value => _value;
  String _value;
  set value(String value) {
    if (_value == value) return;
    _value = value;
    markNeedsSemanticsUpdate();
  }

  String get increasedValue => _increasedValue;
  String _increasedValue;
  set increasedValue(String value) {
    if (_increasedValue == value) return;
    _increasedValue = value;
    markNeedsSemanticsUpdate();
  }

  String get decreasedValue => _decreasedValue;
  String _decreasedValue;
  set decreasedValue(String value) {
    if (_decreasedValue == value) return;
    _decreasedValue = value;
    markNeedsSemanticsUpdate();
  }

  String get hint => _hint;
  String _hint;
  set hint(String value) {
    if (_hint == value) return;
    _hint = value;
    markNeedsSemanticsUpdate();
  }

  SemanticsHintOverrides get hintOverrides => _hintOverrides;
  SemanticsHintOverrides _hintOverrides;
  set hintOverrides(SemanticsHintOverrides value) {
    if (_hintOverrides == value) return;
    _hintOverrides = value;
    markNeedsSemanticsUpdate();
  }

  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (textDirection == value) return;
    _textDirection = value;
    markNeedsSemanticsUpdate();
  }

  SemanticsSortKey get sortKey => _sortKey;
  SemanticsSortKey _sortKey;
  set sortKey(SemanticsSortKey value) {
    if (sortKey == value) return;
    _sortKey = value;
    markNeedsSemanticsUpdate();
  }

  VoidCallback get onTap => _onTap;
  VoidCallback _onTap;
  set onTap(VoidCallback handler) {
    if (_onTap == handler) return;
    final bool hadValue = _onTap != null;
    _onTap = handler;
    if ((handler != null) == hadValue) markNeedsSemanticsUpdate();
  }

  VoidCallback get onDismiss => _onDismiss;
  VoidCallback _onDismiss;
  set onDismiss(VoidCallback handler) {
    if (_onDismiss == handler) return;
    final bool hadValue = _onDismiss != null;
    _onDismiss = handler;
    if ((handler != null) == hadValue) markNeedsSemanticsUpdate();
  }

  VoidCallback get onLongPress => _onLongPress;
  VoidCallback _onLongPress;
  set onLongPress(VoidCallback handler) {
    if (_onLongPress == handler) return;
    final bool hadValue = _onLongPress != null;
    _onLongPress = handler;
    if ((handler != null) != hadValue) markNeedsSemanticsUpdate();
  }

  VoidCallback get onScrollLeft => _onScrollLeft;
  VoidCallback _onScrollLeft;
  set onScrollLeft(VoidCallback handler) {
    if (_onScrollLeft == handler) return;
    final bool hadValue = _onScrollLeft != null;
    _onScrollLeft = handler;
    if ((handler != null) != hadValue) markNeedsSemanticsUpdate();
  }

  VoidCallback get onScrollRight => _onScrollRight;
  VoidCallback _onScrollRight;
  set onScrollRight(VoidCallback handler) {
    if (_onScrollRight == handler) return;
    final bool hadValue = _onScrollRight != null;
    _onScrollRight = handler;
    if ((handler != null) != hadValue) markNeedsSemanticsUpdate();
  }

  VoidCallback get onScrollUp => _onScrollUp;
  VoidCallback _onScrollUp;
  set onScrollUp(VoidCallback handler) {
    if (_onScrollUp == handler) return;
    final bool hadValue = _onScrollUp != null;
    _onScrollUp = handler;
    if ((handler != null) != hadValue) markNeedsSemanticsUpdate();
  }

  VoidCallback get onScrollDown => _onScrollDown;
  VoidCallback _onScrollDown;
  set onScrollDown(VoidCallback handler) {
    if (_onScrollDown == handler) return;
    final bool hadValue = _onScrollDown != null;
    _onScrollDown = handler;
    if ((handler != null) != hadValue) markNeedsSemanticsUpdate();
  }

  VoidCallback get onIncrease => _onIncrease;
  VoidCallback _onIncrease;
  set onIncrease(VoidCallback handler) {
    if (_onIncrease == handler) return;
    final bool hadValue = _onIncrease != null;
    _onIncrease = handler;
    if ((handler != null) != hadValue) markNeedsSemanticsUpdate();
  }

  VoidCallback get onDecrease => _onDecrease;
  VoidCallback _onDecrease;
  set onDecrease(VoidCallback handler) {
    if (_onDecrease == handler) return;
    final bool hadValue = _onDecrease != null;
    _onDecrease = handler;
    if ((handler != null) != hadValue) markNeedsSemanticsUpdate();
  }

  VoidCallback get onCopy => _onCopy;
  VoidCallback _onCopy;
  set onCopy(VoidCallback handler) {
    if (_onCopy == handler) return;
    final bool hadValue = _onCopy != null;
    _onCopy = handler;
    if ((handler != null) != hadValue) markNeedsSemanticsUpdate();
  }

  VoidCallback get onCut => _onCut;
  VoidCallback _onCut;
  set onCut(VoidCallback handler) {
    if (_onCut == handler) return;
    final bool hadValue = _onCut != null;
    _onCut = handler;
    if ((handler != null) != hadValue) markNeedsSemanticsUpdate();
  }

  VoidCallback get onPaste => _onPaste;
  VoidCallback _onPaste;
  set onPaste(VoidCallback handler) {
    if (_onPaste == handler) return;
    final bool hadValue = _onPaste != null;
    _onPaste = handler;
    if ((handler != null) != hadValue) markNeedsSemanticsUpdate();
  }

  MoveCursorHandler get onMoveCursorForwardByCharacter =>
      _onMoveCursorForwardByCharacter;
  MoveCursorHandler _onMoveCursorForwardByCharacter;
  set onMoveCursorForwardByCharacter(MoveCursorHandler handler) {
    if (_onMoveCursorForwardByCharacter == handler) return;
    final bool hadValue = _onMoveCursorForwardByCharacter != null;
    _onMoveCursorForwardByCharacter = handler;
    if ((handler != null) != hadValue) markNeedsSemanticsUpdate();
  }

  MoveCursorHandler get onMoveCursorBackwardByCharacter =>
      _onMoveCursorBackwardByCharacter;
  MoveCursorHandler _onMoveCursorBackwardByCharacter;
  set onMoveCursorBackwardByCharacter(MoveCursorHandler handler) {
    if (_onMoveCursorBackwardByCharacter == handler) return;
    final bool hadValue = _onMoveCursorBackwardByCharacter != null;
    _onMoveCursorBackwardByCharacter = handler;
    if ((handler != null) != hadValue) markNeedsSemanticsUpdate();
  }

  MoveCursorHandler get onMoveCursorForwardByWord => _onMoveCursorForwardByWord;
  MoveCursorHandler _onMoveCursorForwardByWord;
  set onMoveCursorForwardByWord(MoveCursorHandler handler) {
    if (_onMoveCursorForwardByWord == handler) return;
    final bool hadValue = _onMoveCursorForwardByWord != null;
    _onMoveCursorForwardByWord = handler;
    if ((handler != null) != hadValue) markNeedsSemanticsUpdate();
  }

  MoveCursorHandler get onMoveCursorBackwardByWord =>
      _onMoveCursorBackwardByWord;
  MoveCursorHandler _onMoveCursorBackwardByWord;
  set onMoveCursorBackwardByWord(MoveCursorHandler handler) {
    if (_onMoveCursorBackwardByWord == handler) return;
    final bool hadValue = _onMoveCursorBackwardByWord != null;
    _onMoveCursorBackwardByWord = handler;
    if ((handler != null) != hadValue) markNeedsSemanticsUpdate();
  }

  SetSelectionHandler get onSetSelection => _onSetSelection;
  SetSelectionHandler _onSetSelection;
  set onSetSelection(SetSelectionHandler handler) {
    if (_onSetSelection == handler) return;
    final bool hadValue = _onSetSelection != null;
    _onSetSelection = handler;
    if ((handler != null) != hadValue) markNeedsSemanticsUpdate();
  }

  VoidCallback get onDidGainAccessibilityFocus => _onDidGainAccessibilityFocus;
  VoidCallback _onDidGainAccessibilityFocus;
  set onDidGainAccessibilityFocus(VoidCallback handler) {
    if (_onDidGainAccessibilityFocus == handler) return;
    final bool hadValue = _onDidGainAccessibilityFocus != null;
    _onDidGainAccessibilityFocus = handler;
    if ((handler != null) != hadValue) markNeedsSemanticsUpdate();
  }

  VoidCallback get onDidLoseAccessibilityFocus => _onDidLoseAccessibilityFocus;
  VoidCallback _onDidLoseAccessibilityFocus;
  set onDidLoseAccessibilityFocus(VoidCallback handler) {
    if (_onDidLoseAccessibilityFocus == handler) return;
    final bool hadValue = _onDidLoseAccessibilityFocus != null;
    _onDidLoseAccessibilityFocus = handler;
    if ((handler != null) != hadValue) markNeedsSemanticsUpdate();
  }

  Map<CustomSemanticsAction, VoidCallback> get customSemanticsActions =>
      _customSemanticsActions;
  Map<CustomSemanticsAction, VoidCallback> _customSemanticsActions;
  set customSemanticsActions(Map<CustomSemanticsAction, VoidCallback> value) {
    if (_customSemanticsActions == value) return;
    _customSemanticsActions = value;
    markNeedsSemanticsUpdate();
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    if (excludeSemantics) return;
    super.visitChildrenForSemantics(visitor);
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config.isSemanticBoundary = container;
    config.explicitChildNodes = explicitChildNodes;
    assert(
        (scopesRoute == true && explicitChildNodes == true) ||
            scopesRoute != true,
        'explicitChildNodes must be set to true if scopes route is true');
    assert(!(toggled == true && checked == true),
        'A semantics node cannot be toggled and checked at the same time');

    if (enabled != null) config.isEnabled = enabled;
    if (checked != null) config.isChecked = checked;
    if (toggled != null) config.isToggled = toggled;
    if (selected != null) config.isSelected = selected;
    if (button != null) config.isButton = button;
    if (header != null) config.isHeader = header;
    if (textField != null) config.isTextField = textField;
    if (readOnly != null) config.isReadOnly = readOnly;
    if (focused != null) config.isFocused = focused;
    if (inMutuallyExclusiveGroup != null)
      config.isInMutuallyExclusiveGroup = inMutuallyExclusiveGroup;
    if (obscured != null) config.isObscured = obscured;
    if (multiline != null) config.isMultiline = multiline;
    if (hidden != null) config.isHidden = hidden;
    if (image != null) config.isImage = image;
    if (label != null) config.label = label;
    if (value != null) config.value = value;
    if (increasedValue != null) config.increasedValue = increasedValue;
    if (decreasedValue != null) config.decreasedValue = decreasedValue;
    if (hint != null) config.hint = hint;
    if (hintOverrides != null && hintOverrides.isNotEmpty)
      config.hintOverrides = hintOverrides;
    if (scopesRoute != null) config.scopesRoute = scopesRoute;
    if (namesRoute != null) config.namesRoute = namesRoute;
    if (liveRegion != null) config.liveRegion = liveRegion;
    if (textDirection != null) config.textDirection = textDirection;
    if (sortKey != null) config.sortKey = sortKey;

    if (onTap != null) config.onTap = _performTap;
    if (onLongPress != null) config.onLongPress = _performLongPress;
    if (onDismiss != null) config.onDismiss = _performDismiss;
    if (onScrollLeft != null) config.onScrollLeft = _performScrollLeft;
    if (onScrollRight != null) config.onScrollRight = _performScrollRight;
    if (onScrollUp != null) config.onScrollUp = _performScrollUp;
    if (onScrollDown != null) config.onScrollDown = _performScrollDown;
    if (onIncrease != null) config.onIncrease = _performIncrease;
    if (onDecrease != null) config.onDecrease = _performDecrease;
    if (onCopy != null) config.onCopy = _performCopy;
    if (onCut != null) config.onCut = _performCut;
    if (onPaste != null) config.onPaste = _performPaste;
    if (onMoveCursorForwardByCharacter != null)
      config.onMoveCursorForwardByCharacter =
          _performMoveCursorForwardByCharacter;
    if (onMoveCursorBackwardByCharacter != null)
      config.onMoveCursorBackwardByCharacter =
          _performMoveCursorBackwardByCharacter;
    if (onMoveCursorForwardByWord != null)
      config.onMoveCursorForwardByWord = _performMoveCursorForwardByWord;
    if (onMoveCursorBackwardByWord != null)
      config.onMoveCursorBackwardByWord = _performMoveCursorBackwardByWord;
    if (onSetSelection != null) config.onSetSelection = _performSetSelection;
    if (onDidGainAccessibilityFocus != null)
      config.onDidGainAccessibilityFocus = _performDidGainAccessibilityFocus;
    if (onDidLoseAccessibilityFocus != null)
      config.onDidLoseAccessibilityFocus = _performDidLoseAccessibilityFocus;
    if (customSemanticsActions != null)
      config.customSemanticsActions = _customSemanticsActions;
  }

  void _performTap() {
    if (onTap != null) onTap();
  }

  void _performLongPress() {
    if (onLongPress != null) onLongPress();
  }

  void _performDismiss() {
    if (onDismiss != null) onDismiss();
  }

  void _performScrollLeft() {
    if (onScrollLeft != null) onScrollLeft();
  }

  void _performScrollRight() {
    if (onScrollRight != null) onScrollRight();
  }

  void _performScrollUp() {
    if (onScrollUp != null) onScrollUp();
  }

  void _performScrollDown() {
    if (onScrollDown != null) onScrollDown();
  }

  void _performIncrease() {
    if (onIncrease != null) onIncrease();
  }

  void _performDecrease() {
    if (onDecrease != null) onDecrease();
  }

  void _performCopy() {
    if (onCopy != null) onCopy();
  }

  void _performCut() {
    if (onCut != null) onCut();
  }

  void _performPaste() {
    if (onPaste != null) onPaste();
  }

  void _performMoveCursorForwardByCharacter(bool extendSelection) {
    if (onMoveCursorForwardByCharacter != null)
      onMoveCursorForwardByCharacter(extendSelection);
  }

  void _performMoveCursorBackwardByCharacter(bool extendSelection) {
    if (onMoveCursorBackwardByCharacter != null)
      onMoveCursorBackwardByCharacter(extendSelection);
  }

  void _performMoveCursorForwardByWord(bool extendSelection) {
    if (onMoveCursorForwardByWord != null)
      onMoveCursorForwardByWord(extendSelection);
  }

  void _performMoveCursorBackwardByWord(bool extendSelection) {
    if (onMoveCursorBackwardByWord != null)
      onMoveCursorBackwardByWord(extendSelection);
  }

  void _performSetSelection(TextSelection selection) {
    if (onSetSelection != null) onSetSelection(selection);
  }

  void _performDidGainAccessibilityFocus() {
    if (onDidGainAccessibilityFocus != null) onDidGainAccessibilityFocus();
  }

  void _performDidLoseAccessibilityFocus() {
    if (onDidLoseAccessibilityFocus != null) onDidLoseAccessibilityFocus();
  }
}

class RenderBlockSemantics extends RenderProxyBox {
  RenderBlockSemantics({
    RenderBox child,
    bool blocking = true,
  })  : _blocking = blocking,
        super(child);

  bool get blocking => _blocking;
  bool _blocking;
  set blocking(bool value) {
    assert(value != null);
    if (value == _blocking) return;
    _blocking = value;
    markNeedsSemanticsUpdate();
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config.isBlockingSemanticsOfPreviouslyPaintedNodes = blocking;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('blocking', blocking));
  }
}

class RenderMergeSemantics extends RenderProxyBox {
  RenderMergeSemantics({RenderBox child}) : super(child);

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config
      ..isSemanticBoundary = true
      ..isMergingSemanticsOfDescendants = true;
  }
}

class RenderExcludeSemantics extends RenderProxyBox {
  RenderExcludeSemantics({
    RenderBox child,
    bool excluding = true,
  })  : _excluding = excluding,
        super(child) {
    assert(_excluding != null);
  }

  bool get excluding => _excluding;
  bool _excluding;
  set excluding(bool value) {
    assert(value != null);
    if (value == _excluding) return;
    _excluding = value;
    markNeedsSemanticsUpdate();
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    if (excluding) return;
    super.visitChildrenForSemantics(visitor);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('excluding', excluding));
  }
}

class RenderIndexedSemantics extends RenderProxyBox {
  RenderIndexedSemantics({
    RenderBox child,
    @required int index,
  })  : assert(index != null),
        _index = index,
        super(child);

  int get index => _index;
  int _index;
  set index(int value) {
    if (value == index) return;
    _index = value;
    markNeedsSemanticsUpdate();
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config.isSemanticBoundary = true;
    config.indexInParent = index;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<int>('index', index));
  }
}

class RenderLeaderLayer extends RenderProxyBox {
  RenderLeaderLayer({
    @required LayerLink link,
    RenderBox child,
  })  : assert(link != null),
        super(child) {
    this.link = link;
  }

  LayerLink get link => _link;
  LayerLink _link;
  set link(LayerLink value) {
    assert(value != null);
    if (_link == value) return;
    _link = value;
    markNeedsPaint();
  }

  @override
  bool get alwaysNeedsCompositing => true;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (layer == null) {
      layer = LeaderLayer(link: link, offset: offset);
    } else {
      final LeaderLayer leaderLayer = layer;
      leaderLayer
        ..link = link
        ..offset = offset;
    }
    context.pushLayer(layer, super.paint, Offset.zero);
    assert(layer != null);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<LayerLink>('link', link));
  }
}

class RenderFollowerLayer extends RenderProxyBox {
  RenderFollowerLayer({
    @required LayerLink link,
    bool showWhenUnlinked = true,
    Offset offset = Offset.zero,
    RenderBox child,
  })  : assert(link != null),
        assert(showWhenUnlinked != null),
        assert(offset != null),
        super(child) {
    this.link = link;
    this.showWhenUnlinked = showWhenUnlinked;
    this.offset = offset;
  }

  LayerLink get link => _link;
  LayerLink _link;
  set link(LayerLink value) {
    assert(value != null);
    if (_link == value) return;
    _link = value;
    markNeedsPaint();
  }

  bool get showWhenUnlinked => _showWhenUnlinked;
  bool _showWhenUnlinked;
  set showWhenUnlinked(bool value) {
    assert(value != null);
    if (_showWhenUnlinked == value) return;
    _showWhenUnlinked = value;
    markNeedsPaint();
  }

  Offset get offset => _offset;
  Offset _offset;
  set offset(Offset value) {
    assert(value != null);
    if (_offset == value) return;
    _offset = value;
    markNeedsPaint();
  }

  @override
  void detach() {
    layer = null;
    super.detach();
  }

  @override
  bool get alwaysNeedsCompositing => true;

  @override
  FollowerLayer get layer => super.layer;

  Matrix4 getCurrentTransform() {
    return layer?.getLastTransform() ?? Matrix4.identity();
  }

  @override
  bool hitTest(BoxHitTestResult result, {Offset position}) {
    return hitTestChildren(result, position: position);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {Offset position}) {
    return result.addWithPaintTransform(
      transform: getCurrentTransform(),
      position: position,
      hitTest: (BoxHitTestResult result, Offset position) {
        return super.hitTestChildren(result, position: position);
      },
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    assert(showWhenUnlinked != null);
    if (layer == null) {
      layer = FollowerLayer(
        link: link,
        showWhenUnlinked: showWhenUnlinked,
        linkedOffset: this.offset,
        unlinkedOffset: offset,
      );
    } else {
      layer
        ..link = link
        ..showWhenUnlinked = showWhenUnlinked
        ..linkedOffset = this.offset
        ..unlinkedOffset = offset;
    }
    context.pushLayer(
      layer,
      super.paint,
      Offset.zero,
      childPaintBounds: const Rect.fromLTRB(
        double.negativeInfinity,
        double.negativeInfinity,
        double.infinity,
        double.infinity,
      ),
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.multiply(getCurrentTransform());
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<LayerLink>('link', link));
    properties
        .add(DiagnosticsProperty<bool>('showWhenUnlinked', showWhenUnlinked));
    properties.add(DiagnosticsProperty<Offset>('offset', offset));
    properties.add(
        TransformProperty('current transform matrix', getCurrentTransform()));
  }
}

class RenderAnnotatedRegion<T> extends RenderProxyBox {
  RenderAnnotatedRegion({
    @required T value,
    @required bool sized,
    RenderBox child,
  })  : assert(value != null),
        assert(sized != null),
        _value = value,
        _sized = sized,
        super(child);

  T get value => _value;
  T _value;
  set value(T newValue) {
    if (_value == newValue) return;
    _value = newValue;
    markNeedsPaint();
  }

  bool get sized => _sized;
  bool _sized;
  set sized(bool value) {
    if (_sized == value) return;
    _sized = value;
    markNeedsPaint();
  }

  @override
  final bool alwaysNeedsCompositing = true;

  @override
  void paint(PaintingContext context, Offset offset) {
    final AnnotatedRegionLayer<T> layer = AnnotatedRegionLayer<T>(
      value,
      size: sized ? size : null,
      offset: sized ? offset : null,
    );
    context.pushLayer(layer, super.paint, offset);
  }
}

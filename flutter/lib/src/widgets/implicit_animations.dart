import 'package:flutter_web/animation.dart';
import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/rendering.dart';
import 'package:vector_math/vector_math_64.dart';

import 'basic.dart';
import 'container.dart';
import 'debug.dart';
import 'framework.dart';
import 'text.dart';
import 'ticker_provider.dart';
import 'transitions.dart';

class BoxConstraintsTween extends Tween<BoxConstraints> {
  BoxConstraintsTween({BoxConstraints begin, BoxConstraints end})
      : super(begin: begin, end: end);

  @override
  BoxConstraints lerp(double t) => BoxConstraints.lerp(begin, end, t);
}

class DecorationTween extends Tween<Decoration> {
  DecorationTween({Decoration begin, Decoration end})
      : super(begin: begin, end: end);

  @override
  Decoration lerp(double t) => Decoration.lerp(begin, end, t);
}

class EdgeInsetsTween extends Tween<EdgeInsets> {
  EdgeInsetsTween({EdgeInsets begin, EdgeInsets end})
      : super(begin: begin, end: end);

  @override
  EdgeInsets lerp(double t) => EdgeInsets.lerp(begin, end, t);
}

class EdgeInsetsGeometryTween extends Tween<EdgeInsetsGeometry> {
  EdgeInsetsGeometryTween({EdgeInsetsGeometry begin, EdgeInsetsGeometry end})
      : super(begin: begin, end: end);

  @override
  EdgeInsetsGeometry lerp(double t) => EdgeInsetsGeometry.lerp(begin, end, t);
}

class BorderRadiusTween extends Tween<BorderRadius> {
  BorderRadiusTween({BorderRadius begin, BorderRadius end})
      : super(begin: begin, end: end);

  @override
  BorderRadius lerp(double t) => BorderRadius.lerp(begin, end, t);
}

class BorderTween extends Tween<Border> {
  BorderTween({Border begin, Border end}) : super(begin: begin, end: end);

  @override
  Border lerp(double t) => Border.lerp(begin, end, t);
}

class Matrix4Tween extends Tween<Matrix4> {
  Matrix4Tween({Matrix4 begin, Matrix4 end}) : super(begin: begin, end: end);

  @override
  Matrix4 lerp(double t) {
    assert(begin != null);
    assert(end != null);
    final Vector3 beginTranslation = Vector3.zero();
    final Vector3 endTranslation = Vector3.zero();
    final Quaternion beginRotation = Quaternion.identity();
    final Quaternion endRotation = Quaternion.identity();
    final Vector3 beginScale = Vector3.zero();
    final Vector3 endScale = Vector3.zero();
    begin.decompose(beginTranslation, beginRotation, beginScale);
    end.decompose(endTranslation, endRotation, endScale);
    final Vector3 lerpTranslation =
        beginTranslation * (1.0 - t) + endTranslation * t;

    final Quaternion lerpRotation =
        (beginRotation.scaled(1.0 - t) + endRotation.scaled(t)).normalized();
    final Vector3 lerpScale = beginScale * (1.0 - t) + endScale * t;
    return Matrix4.compose(lerpTranslation, lerpRotation, lerpScale);
  }
}

class TextStyleTween extends Tween<TextStyle> {
  TextStyleTween({TextStyle begin, TextStyle end})
      : super(begin: begin, end: end);

  @override
  TextStyle lerp(double t) => TextStyle.lerp(begin, end, t);
}

abstract class ImplicitlyAnimatedWidget extends StatefulWidget {
  const ImplicitlyAnimatedWidget({
    Key key,
    this.curve = Curves.linear,
    @required this.duration,
  })  : assert(curve != null),
        assert(duration != null),
        super(key: key);

  final Curve curve;

  final Duration duration;

  @override
  ImplicitlyAnimatedWidgetState<ImplicitlyAnimatedWidget> createState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(IntProperty('duration', duration.inMilliseconds, unit: 'ms'));
  }
}

typedef TweenConstructor<T> = Tween<T> Function(T targetValue);

typedef TweenVisitor<T> = Tween<T> Function(
    Tween<T> tween, T targetValue, TweenConstructor<T> constructor);

abstract class ImplicitlyAnimatedWidgetState<T extends ImplicitlyAnimatedWidget>
    extends State<T> with SingleTickerProviderStateMixin<T> {
  @protected
  AnimationController get controller => _controller;
  AnimationController _controller;

  Animation<double> get animation => _animation;
  Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      debugLabel: kDebugMode ? '${widget.toStringShort()}' : null,
      vsync: this,
    );
    _updateCurve();
    _constructTweens();
    didUpdateTweens();
  }

  @override
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.curve != oldWidget.curve) _updateCurve();
    _controller.duration = widget.duration;
    if (_constructTweens()) {
      forEachTween((Tween<dynamic> tween, dynamic targetValue,
          TweenConstructor<dynamic> constructor) {
        _updateTween(tween, targetValue);
        return tween;
      });
      _controller
        ..value = 0.0
        ..forward();
      didUpdateTweens();
    }
  }

  void _updateCurve() {
    if (widget.curve != null)
      _animation = CurvedAnimation(parent: _controller, curve: widget.curve);
    else
      _animation = _controller;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _shouldAnimateTween(Tween<dynamic> tween, dynamic targetValue) {
    return targetValue != (tween.end ?? tween.begin);
  }

  void _updateTween(Tween<dynamic> tween, dynamic targetValue) {
    if (tween == null) return;
    tween
      ..begin = tween.evaluate(_animation)
      ..end = targetValue;
  }

  bool _constructTweens() {
    bool shouldStartAnimation = false;
    forEachTween((Tween<dynamic> tween, dynamic targetValue,
        TweenConstructor<dynamic> constructor) {
      if (targetValue != null) {
        tween ??= constructor(targetValue);
        if (_shouldAnimateTween(tween, targetValue))
          shouldStartAnimation = true;
      } else {
        tween = null;
      }
      return tween;
    });
    return shouldStartAnimation;
  }

  @protected
  void forEachTween(TweenVisitor<dynamic> visitor);

  @protected
  void didUpdateTweens() {}
}

abstract class AnimatedWidgetBaseState<T extends ImplicitlyAnimatedWidget>
    extends ImplicitlyAnimatedWidgetState<T> {
  @override
  void initState() {
    super.initState();
    controller.addListener(_handleAnimationChanged);
  }

  void _handleAnimationChanged() {
    setState(() {});
  }
}

class AnimatedContainer extends ImplicitlyAnimatedWidget {
  AnimatedContainer({
    Key key,
    this.alignment,
    this.padding,
    Color color,
    Decoration decoration,
    this.foregroundDecoration,
    double width,
    double height,
    BoxConstraints constraints,
    this.margin,
    this.transform,
    this.child,
    Curve curve = Curves.linear,
    @required Duration duration,
  })  : assert(margin == null || margin.isNonNegative),
        assert(padding == null || padding.isNonNegative),
        assert(decoration == null || decoration.debugAssertIsValid()),
        assert(constraints == null || constraints.debugAssertIsValid()),
        assert(
            color == null || decoration == null,
            'Cannot provide both a color and a decoration\n'
            'The color argument is just a shorthand for "decoration: new BoxDecoration(backgroundColor: color)".'),
        decoration =
            decoration ?? (color != null ? BoxDecoration(color: color) : null),
        constraints = (width != null || height != null)
            ? constraints?.tighten(width: width, height: height) ??
                BoxConstraints.tightFor(width: width, height: height)
            : constraints,
        super(key: key, curve: curve, duration: duration);

  final Widget child;

  final AlignmentGeometry alignment;

  final EdgeInsetsGeometry padding;

  final Decoration decoration;

  final Decoration foregroundDecoration;

  final BoxConstraints constraints;

  final EdgeInsetsGeometry margin;

  final Matrix4 transform;

  @override
  _AnimatedContainerState createState() => _AnimatedContainerState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<AlignmentGeometry>(
        'alignment', alignment,
        showName: false, defaultValue: null));
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('padding', padding,
        defaultValue: null));
    properties.add(
        DiagnosticsProperty<Decoration>('bg', decoration, defaultValue: null));
    properties.add(DiagnosticsProperty<Decoration>('fg', foregroundDecoration,
        defaultValue: null));
    properties.add(DiagnosticsProperty<BoxConstraints>(
        'constraints', constraints,
        defaultValue: null, showName: false));
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('margin', margin,
        defaultValue: null));
    properties.add(ObjectFlagProperty<Matrix4>.has('transform', transform));
  }
}

class _AnimatedContainerState
    extends AnimatedWidgetBaseState<AnimatedContainer> {
  AlignmentGeometryTween _alignment;
  EdgeInsetsGeometryTween _padding;
  DecorationTween _decoration;
  DecorationTween _foregroundDecoration;
  BoxConstraintsTween _constraints;
  EdgeInsetsGeometryTween _margin;
  Matrix4Tween _transform;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _alignment = visitor(_alignment, widget.alignment,
        (dynamic value) => AlignmentGeometryTween(begin: value));
    _padding = visitor(_padding, widget.padding,
        (dynamic value) => EdgeInsetsGeometryTween(begin: value));
    _decoration = visitor(_decoration, widget.decoration,
        (dynamic value) => DecorationTween(begin: value));
    _foregroundDecoration = visitor(
        _foregroundDecoration,
        widget.foregroundDecoration,
        (dynamic value) => DecorationTween(begin: value));
    _constraints = visitor(_constraints, widget.constraints,
        (dynamic value) => BoxConstraintsTween(begin: value));
    _margin = visitor(_margin, widget.margin,
        (dynamic value) => EdgeInsetsGeometryTween(begin: value));
    _transform = visitor(_transform, widget.transform,
        (dynamic value) => Matrix4Tween(begin: value));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: widget.child,
      alignment: _alignment?.evaluate(animation),
      padding: _padding?.evaluate(animation),
      decoration: _decoration?.evaluate(animation),
      foregroundDecoration: _foregroundDecoration?.evaluate(animation),
      constraints: _constraints?.evaluate(animation),
      margin: _margin?.evaluate(animation),
      transform: _transform?.evaluate(animation),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(DiagnosticsProperty<AlignmentGeometryTween>(
        'alignment', _alignment,
        showName: false, defaultValue: null));
    description.add(DiagnosticsProperty<EdgeInsetsGeometryTween>(
        'padding', _padding,
        defaultValue: null));
    description.add(DiagnosticsProperty<DecorationTween>('bg', _decoration,
        defaultValue: null));
    description.add(DiagnosticsProperty<DecorationTween>(
        'fg', _foregroundDecoration,
        defaultValue: null));
    description.add(DiagnosticsProperty<BoxConstraintsTween>(
        'constraints', _constraints,
        showName: false, defaultValue: null));
    description.add(DiagnosticsProperty<EdgeInsetsGeometryTween>(
        'margin', _margin,
        defaultValue: null));
    description
        .add(ObjectFlagProperty<Matrix4Tween>.has('transform', _transform));
  }
}

class AnimatedPadding extends ImplicitlyAnimatedWidget {
  AnimatedPadding({
    Key key,
    @required this.padding,
    this.child,
    Curve curve = Curves.linear,
    @required Duration duration,
  })  : assert(padding != null),
        assert(padding.isNonNegative),
        super(key: key, curve: curve, duration: duration);

  final EdgeInsetsGeometry padding;

  final Widget child;

  @override
  _AnimatedPaddingState createState() => _AnimatedPaddingState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('padding', padding));
  }
}

class _AnimatedPaddingState extends AnimatedWidgetBaseState<AnimatedPadding> {
  EdgeInsetsGeometryTween _padding;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _padding = visitor(_padding, widget.padding,
        (dynamic value) => EdgeInsetsGeometryTween(begin: value));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: _padding.evaluate(animation),
      child: widget.child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(DiagnosticsProperty<EdgeInsetsGeometryTween>(
        'padding', _padding,
        defaultValue: null));
  }
}

class AnimatedAlign extends ImplicitlyAnimatedWidget {
  const AnimatedAlign({
    Key key,
    @required this.alignment,
    this.child,
    Curve curve = Curves.linear,
    @required Duration duration,
  })  : assert(alignment != null),
        super(key: key, curve: curve, duration: duration);

  final AlignmentGeometry alignment;

  final Widget child;

  @override
  _AnimatedAlignState createState() => _AnimatedAlignState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(DiagnosticsProperty<AlignmentGeometry>('alignment', alignment));
  }
}

class _AnimatedAlignState extends AnimatedWidgetBaseState<AnimatedAlign> {
  AlignmentGeometryTween _alignment;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _alignment = visitor(_alignment, widget.alignment,
        (dynamic value) => AlignmentGeometryTween(begin: value));
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: _alignment.evaluate(animation),
      child: widget.child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(DiagnosticsProperty<AlignmentGeometryTween>(
        'alignment', _alignment,
        defaultValue: null));
  }
}

class AnimatedPositioned extends ImplicitlyAnimatedWidget {
  const AnimatedPositioned({
    Key key,
    @required this.child,
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.width,
    this.height,
    Curve curve = Curves.linear,
    @required Duration duration,
  })  : assert(left == null || right == null || width == null),
        assert(top == null || bottom == null || height == null),
        super(key: key, curve: curve, duration: duration);

  AnimatedPositioned.fromRect({
    Key key,
    this.child,
    Rect rect,
    Curve curve = Curves.linear,
    @required Duration duration,
  })  : left = rect.left,
        top = rect.top,
        width = rect.width,
        height = rect.height,
        right = null,
        bottom = null,
        super(key: key, curve: curve, duration: duration);

  final Widget child;

  final double left;

  final double top;

  final double right;

  final double bottom;

  final double width;

  final double height;

  @override
  _AnimatedPositionedState createState() => _AnimatedPositionedState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('left', left, defaultValue: null));
    properties.add(DoubleProperty('top', top, defaultValue: null));
    properties.add(DoubleProperty('right', right, defaultValue: null));
    properties.add(DoubleProperty('bottom', bottom, defaultValue: null));
    properties.add(DoubleProperty('width', width, defaultValue: null));
    properties.add(DoubleProperty('height', height, defaultValue: null));
  }
}

class _AnimatedPositionedState
    extends AnimatedWidgetBaseState<AnimatedPositioned> {
  Tween<double> _left;
  Tween<double> _top;
  Tween<double> _right;
  Tween<double> _bottom;
  Tween<double> _width;
  Tween<double> _height;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _left = visitor(
        _left, widget.left, (dynamic value) => Tween<double>(begin: value));
    _top = visitor(
        _top, widget.top, (dynamic value) => Tween<double>(begin: value));
    _right = visitor(
        _right, widget.right, (dynamic value) => Tween<double>(begin: value));
    _bottom = visitor(
        _bottom, widget.bottom, (dynamic value) => Tween<double>(begin: value));
    _width = visitor(
        _width, widget.width, (dynamic value) => Tween<double>(begin: value));
    _height = visitor(
        _height, widget.height, (dynamic value) => Tween<double>(begin: value));
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      child: widget.child,
      left: _left?.evaluate(animation),
      top: _top?.evaluate(animation),
      right: _right?.evaluate(animation),
      bottom: _bottom?.evaluate(animation),
      width: _width?.evaluate(animation),
      height: _height?.evaluate(animation),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(ObjectFlagProperty<Tween<double>>.has('left', _left));
    description.add(ObjectFlagProperty<Tween<double>>.has('top', _top));
    description.add(ObjectFlagProperty<Tween<double>>.has('right', _right));
    description.add(ObjectFlagProperty<Tween<double>>.has('bottom', _bottom));
    description.add(ObjectFlagProperty<Tween<double>>.has('width', _width));
    description.add(ObjectFlagProperty<Tween<double>>.has('height', _height));
  }
}

class AnimatedPositionedDirectional extends ImplicitlyAnimatedWidget {
  const AnimatedPositionedDirectional({
    Key key,
    @required this.child,
    this.start,
    this.top,
    this.end,
    this.bottom,
    this.width,
    this.height,
    Curve curve = Curves.linear,
    @required Duration duration,
  })  : assert(start == null || end == null || width == null),
        assert(top == null || bottom == null || height == null),
        super(key: key, curve: curve, duration: duration);

  final Widget child;

  final double start;

  final double top;

  final double end;

  final double bottom;

  final double width;

  final double height;

  @override
  _AnimatedPositionedDirectionalState createState() =>
      _AnimatedPositionedDirectionalState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('start', start, defaultValue: null));
    properties.add(DoubleProperty('top', top, defaultValue: null));
    properties.add(DoubleProperty('end', end, defaultValue: null));
    properties.add(DoubleProperty('bottom', bottom, defaultValue: null));
    properties.add(DoubleProperty('width', width, defaultValue: null));
    properties.add(DoubleProperty('height', height, defaultValue: null));
  }
}

class _AnimatedPositionedDirectionalState
    extends AnimatedWidgetBaseState<AnimatedPositionedDirectional> {
  Tween<double> _start;
  Tween<double> _top;
  Tween<double> _end;
  Tween<double> _bottom;
  Tween<double> _width;
  Tween<double> _height;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _start = visitor(
        _start, widget.start, (dynamic value) => Tween<double>(begin: value));
    _top = visitor(
        _top, widget.top, (dynamic value) => Tween<double>(begin: value));
    _end = visitor(
        _end, widget.end, (dynamic value) => Tween<double>(begin: value));
    _bottom = visitor(
        _bottom, widget.bottom, (dynamic value) => Tween<double>(begin: value));
    _width = visitor(
        _width, widget.width, (dynamic value) => Tween<double>(begin: value));
    _height = visitor(
        _height, widget.height, (dynamic value) => Tween<double>(begin: value));
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasDirectionality(context));
    return Positioned.directional(
      textDirection: Directionality.of(context),
      child: widget.child,
      start: _start?.evaluate(animation),
      top: _top?.evaluate(animation),
      end: _end?.evaluate(animation),
      bottom: _bottom?.evaluate(animation),
      width: _width?.evaluate(animation),
      height: _height?.evaluate(animation),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(ObjectFlagProperty<Tween<double>>.has('start', _start));
    description.add(ObjectFlagProperty<Tween<double>>.has('top', _top));
    description.add(ObjectFlagProperty<Tween<double>>.has('end', _end));
    description.add(ObjectFlagProperty<Tween<double>>.has('bottom', _bottom));
    description.add(ObjectFlagProperty<Tween<double>>.has('width', _width));
    description.add(ObjectFlagProperty<Tween<double>>.has('height', _height));
  }
}

class AnimatedOpacity extends ImplicitlyAnimatedWidget {
  const AnimatedOpacity({
    Key key,
    this.child,
    @required this.opacity,
    Curve curve = Curves.linear,
    @required Duration duration,
  })  : assert(opacity != null && opacity >= 0.0 && opacity <= 1.0),
        super(key: key, curve: curve, duration: duration);

  final Widget child;

  final double opacity;

  @override
  _AnimatedOpacityState createState() => _AnimatedOpacityState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('opacity', opacity));
  }
}

class _AnimatedOpacityState
    extends ImplicitlyAnimatedWidgetState<AnimatedOpacity> {
  Tween<double> _opacity;
  Animation<double> _opacityAnimation;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _opacity = visitor(_opacity, widget.opacity,
        (dynamic value) => Tween<double>(begin: value));
  }

  @override
  void didUpdateTweens() {
    _opacityAnimation = animation.drive(_opacity);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _opacityAnimation, child: widget.child);
  }
}

class AnimatedDefaultTextStyle extends ImplicitlyAnimatedWidget {
  const AnimatedDefaultTextStyle({
    Key key,
    @required this.child,
    @required this.style,
    this.textAlign,
    this.softWrap = true,
    this.overflow = TextOverflow.clip,
    this.maxLines,
    Curve curve = Curves.linear,
    @required Duration duration,
  })  : assert(style != null),
        assert(child != null),
        assert(softWrap != null),
        assert(overflow != null),
        assert(maxLines == null || maxLines > 0),
        super(key: key, curve: curve, duration: duration);

  final Widget child;

  final TextStyle style;

  final TextAlign textAlign;

  final bool softWrap;

  final TextOverflow overflow;

  final int maxLines;

  @override
  _AnimatedDefaultTextStyleState createState() =>
      _AnimatedDefaultTextStyleState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    style?.debugFillProperties(properties);
    properties.add(
        EnumProperty<TextAlign>('textAlign', textAlign, defaultValue: null));
    properties.add(FlagProperty('softWrap',
        value: softWrap,
        ifTrue: 'wrapping at box width',
        ifFalse: 'no wrapping except at line break characters',
        showName: true));
    properties.add(
        EnumProperty<TextOverflow>('overflow', overflow, defaultValue: null));
    properties.add(IntProperty('maxLines', maxLines, defaultValue: null));
  }
}

class _AnimatedDefaultTextStyleState
    extends AnimatedWidgetBaseState<AnimatedDefaultTextStyle> {
  TextStyleTween _style;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _style = visitor(
        _style, widget.style, (dynamic value) => TextStyleTween(begin: value));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: _style.evaluate(animation),
      textAlign: widget.textAlign,
      softWrap: widget.softWrap,
      overflow: widget.overflow,
      maxLines: widget.maxLines,
      child: widget.child,
    );
  }
}

class AnimatedPhysicalModel extends ImplicitlyAnimatedWidget {
  const AnimatedPhysicalModel({
    Key key,
    @required this.child,
    @required this.shape,
    this.clipBehavior = Clip.none,
    this.borderRadius = BorderRadius.zero,
    @required this.elevation,
    @required this.color,
    this.animateColor = true,
    @required this.shadowColor,
    this.animateShadowColor = true,
    Curve curve = Curves.linear,
    @required Duration duration,
  })  : assert(child != null),
        assert(shape != null),
        assert(clipBehavior != null),
        assert(borderRadius != null),
        assert(elevation != null),
        assert(color != null),
        assert(shadowColor != null),
        assert(animateColor != null),
        assert(animateShadowColor != null),
        super(key: key, curve: curve, duration: duration);

  final Widget child;

  final BoxShape shape;

  final Clip clipBehavior;

  final BorderRadius borderRadius;

  final double elevation;

  final Color color;

  final bool animateColor;

  final Color shadowColor;

  final bool animateShadowColor;

  @override
  _AnimatedPhysicalModelState createState() => _AnimatedPhysicalModelState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<BoxShape>('shape', shape));
    properties
        .add(DiagnosticsProperty<BorderRadius>('borderRadius', borderRadius));
    properties.add(DoubleProperty('elevation', elevation));
    properties.add(DiagnosticsProperty<Color>('color', color));
    properties.add(DiagnosticsProperty<bool>('animateColor', animateColor));
    properties.add(DiagnosticsProperty<Color>('shadowColor', shadowColor));
    properties.add(
        DiagnosticsProperty<bool>('animateShadowColor', animateShadowColor));
  }
}

class _AnimatedPhysicalModelState
    extends AnimatedWidgetBaseState<AnimatedPhysicalModel> {
  BorderRadiusTween _borderRadius;
  Tween<double> _elevation;
  ColorTween _color;
  ColorTween _shadowColor;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _borderRadius = visitor(_borderRadius, widget.borderRadius,
        (dynamic value) => BorderRadiusTween(begin: value));
    _elevation = visitor(_elevation, widget.elevation,
        (dynamic value) => Tween<double>(begin: value));
    _color = visitor(
        _color, widget.color, (dynamic value) => ColorTween(begin: value));
    _shadowColor = visitor(_shadowColor, widget.shadowColor,
        (dynamic value) => ColorTween(begin: value));
  }

  @override
  Widget build(BuildContext context) {
    return PhysicalModel(
      child: widget.child,
      shape: widget.shape,
      clipBehavior: widget.clipBehavior,
      borderRadius: _borderRadius.evaluate(animation),
      elevation: _elevation.evaluate(animation),
      color: widget.animateColor ? _color.evaluate(animation) : widget.color,
      shadowColor: widget.animateShadowColor
          ? _shadowColor.evaluate(animation)
          : widget.shadowColor,
    );
  }
}

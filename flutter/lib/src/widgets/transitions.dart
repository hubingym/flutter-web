import 'dart:math' as math;

import 'package:flutter_web/animation.dart';
import 'package:flutter_web/rendering.dart';
import 'package:flutter_web/widgets.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4;

import 'container.dart';
import 'framework.dart';

export 'package:flutter_web/rendering.dart' show RelativeRect;

abstract class AnimatedWidget extends StatefulWidget {
  const AnimatedWidget({Key key, @required this.listenable})
      : assert(listenable != null),
        super(key: key);

  final Listenable listenable;

  @protected
  Widget build(BuildContext context);

  @override
  _AnimatedState createState() => new _AnimatedState();
}

class _AnimatedState extends State<AnimatedWidget> {
  @override
  void initState() {
    super.initState();
    widget.listenable.addListener(_handleChange);
  }

  @override
  void didUpdateWidget(AnimatedWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.listenable != oldWidget.listenable) {
      oldWidget.listenable.removeListener(_handleChange);
      widget.listenable.addListener(_handleChange);
    }
  }

  @override
  void dispose() {
    widget.listenable.removeListener(_handleChange);
    super.dispose();
  }

  void _handleChange() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => widget.build(context);
}

class SlideTransition extends AnimatedWidget {
  const SlideTransition({
    Key key,
    @required Animation<Offset> position,
    this.transformHitTests = true,
    this.textDirection,
    this.child,
  })  : assert(position != null),
        super(key: key, listenable: position);

  Animation<Offset> get position => listenable;

  final TextDirection textDirection;

  final bool transformHitTests;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    Offset offset = position.value;
    if (textDirection == TextDirection.rtl)
      offset = new Offset(-offset.dx, offset.dy);
    return new FractionalTranslation(
      translation: offset,
      transformHitTests: transformHitTests,
      child: child,
    );
  }
}

class ScaleTransition extends AnimatedWidget {
  const ScaleTransition({
    Key key,
    @required Animation<double> scale,
    this.alignment = Alignment.center,
    this.child,
  }) : super(key: key, listenable: scale);

  Animation<double> get scale => listenable;

  final Alignment alignment;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final double scaleValue = scale.value;
    final Matrix4 transform = new Matrix4.identity()
      ..scale(scaleValue, scaleValue, 1.0);
    return new Transform(
      transform: transform,
      alignment: alignment,
      child: child,
    );
  }
}

class RotationTransition extends AnimatedWidget {
  const RotationTransition({
    Key key,
    @required Animation<double> turns,
    this.alignment = Alignment.center,
    this.child,
  }) : super(key: key, listenable: turns);

  Animation<double> get turns => listenable;

  final Alignment alignment;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final double turnsValue = turns.value;
    final Matrix4 transform = Matrix4.rotationZ(turnsValue * math.pi * 2.0);
    return Transform(
      transform: transform,
      alignment: alignment,
      child: child,
    );
  }
}

class SizeTransition extends AnimatedWidget {
  const SizeTransition({
    Key key,
    this.axis = Axis.vertical,
    @required Animation<double> sizeFactor,
    this.axisAlignment = 0.0,
    this.child,
  })  : assert(axis != null),
        super(key: key, listenable: sizeFactor);

  final Axis axis;

  Animation<double> get sizeFactor => listenable;

  final double axisAlignment;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    AlignmentDirectional alignment;
    if (axis == Axis.vertical)
      alignment = new AlignmentDirectional(-1.0, axisAlignment);
    else
      alignment = new AlignmentDirectional(axisAlignment, -1.0);
    return new ClipRect(
        child: new Align(
      alignment: alignment,
      heightFactor:
          axis == Axis.vertical ? math.max(sizeFactor.value, 0.0) : null,
      widthFactor:
          axis == Axis.horizontal ? math.max(sizeFactor.value, 0.0) : null,
      child: child,
    ));
  }
}

class FadeTransition extends SingleChildRenderObjectWidget {
  const FadeTransition({
    Key key,
    @required this.opacity,
    this.alwaysIncludeSemantics = false,
    Widget child,
  }) : super(key: key, child: child);

  final Animation<double> opacity;

  final bool alwaysIncludeSemantics;

  @override
  RenderAnimatedOpacity createRenderObject(BuildContext context) {
    return RenderAnimatedOpacity(
      opacity: opacity,
      alwaysIncludeSemantics: alwaysIncludeSemantics,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderAnimatedOpacity renderObject) {
    renderObject
      ..opacity = opacity
      ..alwaysIncludeSemantics = alwaysIncludeSemantics;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Animation<double>>('opacity', opacity));
    properties.add(FlagProperty('alwaysIncludeSemantics',
        value: alwaysIncludeSemantics, ifTrue: 'alwaysIncludeSemantics'));
  }
}

class RelativeRectTween extends Tween<RelativeRect> {
  RelativeRectTween({RelativeRect begin, RelativeRect end})
      : super(begin: begin, end: end);

  @override
  RelativeRect lerp(double t) => RelativeRect.lerp(begin, end, t);
}

class PositionedTransition extends AnimatedWidget {
  const PositionedTransition({
    Key key,
    @required Animation<RelativeRect> rect,
    @required this.child,
  }) : super(key: key, listenable: rect);

  Animation<RelativeRect> get rect => listenable;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return new Positioned.fromRelativeRect(
      rect: rect.value,
      child: child,
    );
  }
}

class RelativePositionedTransition extends AnimatedWidget {
  const RelativePositionedTransition({
    Key key,
    @required Animation<Rect> rect,
    @required this.size,
    @required this.child,
  }) : super(key: key, listenable: rect);

  Animation<Rect> get rect => listenable;

  final Size size;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final RelativeRect offsets = new RelativeRect.fromSize(rect.value, size);
    return new Positioned(
      top: offsets.top,
      right: offsets.right,
      bottom: offsets.bottom,
      left: offsets.left,
      child: child,
    );
  }
}

class DecoratedBoxTransition extends AnimatedWidget {
  const DecoratedBoxTransition({
    Key key,
    @required this.decoration,
    this.position = DecorationPosition.background,
    @required this.child,
  }) : super(key: key, listenable: decoration);

  final Animation<Decoration> decoration;

  final DecorationPosition position;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return new DecoratedBox(
      decoration: decoration.value,
      position: position,
      child: child,
    );
  }
}

class AlignTransition extends AnimatedWidget {
  const AlignTransition({
    Key key,
    @required Animation<AlignmentGeometry> alignment,
    @required this.child,
    this.widthFactor,
    this.heightFactor,
  }) : super(key: key, listenable: alignment);

  Animation<AlignmentGeometry> get alignment => listenable;

  final double widthFactor;

  final double heightFactor;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return new Align(
      alignment: alignment.value,
      widthFactor: widthFactor,
      heightFactor: heightFactor,
      child: child,
    );
  }
}

class DefaultTextStyleTransition extends AnimatedWidget {
  const DefaultTextStyleTransition({
    Key key,
    @required Animation<TextStyle> style,
    @required this.child,
    this.textAlign,
    this.softWrap = true,
    this.overflow = TextOverflow.clip,
    this.maxLines,
  }) : super(key: key, listenable: style);

  Animation<TextStyle> get style => listenable;

  final TextAlign textAlign;

  final bool softWrap;

  final TextOverflow overflow;

  final int maxLines;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: style.value,
      textAlign: textAlign,
      softWrap: softWrap,
      overflow: overflow,
      maxLines: maxLines,
      child: child,
    );
  }
}

class AnimatedBuilder extends AnimatedWidget {
  const AnimatedBuilder({
    Key key,
    @required Listenable animation,
    @required this.builder,
    this.child,
  })  : assert(builder != null),
        super(key: key, listenable: animation);

  final TransitionBuilder builder;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}

import 'package:flutter_web/ui.dart' as ui show Image, ImageFilter;

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/gestures.dart';
import 'package:flutter_web/rendering.dart';
import 'package:flutter_web/services.dart';

import 'debug.dart';
import 'framework.dart';
import 'localizations.dart';
import 'widget_span.dart';

export 'package:flutter_web/animation.dart';
export 'package:flutter_web/foundation.dart'
    show
        ChangeNotifier,
        FlutterErrorDetails,
        Listenable,
        TargetPlatform,
        ValueNotifier;
export 'package:flutter_web/painting.dart';
export 'package:flutter_web/rendering.dart'
    show
        AlignmentTween,
        AlignmentGeometryTween,
        Axis,
        BoxConstraints,
        CrossAxisAlignment,
        CustomClipper,
        CustomPainter,
        CustomPainterSemantics,
        DecorationPosition,
        FlexFit,
        FlowDelegate,
        FlowPaintingContext,
        FractionalOffsetTween,
        HitTestBehavior,
        LayerLink,
        MainAxisAlignment,
        MainAxisSize,
        MultiChildLayoutDelegate,
        Overflow,
        PaintingContext,
        PointerCancelEvent,
        PointerCancelEventListener,
        PointerDownEvent,
        PointerDownEventListener,
        PointerEvent,
        PointerMoveEvent,
        PointerMoveEventListener,
        PointerUpEvent,
        PointerUpEventListener,
        RelativeRect,
        SemanticsBuilderCallback,
        ShaderCallback,
        ShapeBorderClipper,
        SingleChildLayoutDelegate,
        StackFit,
        TextOverflow,
        ValueChanged,
        ValueGetter,
        WrapAlignment,
        WrapCrossAlignment;

class Directionality extends InheritedWidget {
  const Directionality({
    Key key,
    @required this.textDirection,
    @required Widget child,
  })  : assert(textDirection != null),
        assert(child != null),
        super(key: key, child: child);

  final TextDirection textDirection;

  static TextDirection of(BuildContext context) {
    final Directionality widget =
        context.inheritFromWidgetOfExactType(Directionality);
    return widget?.textDirection;
  }

  @override
  bool updateShouldNotify(Directionality oldWidget) =>
      textDirection != oldWidget.textDirection;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection));
  }
}

class Opacity extends SingleChildRenderObjectWidget {
  const Opacity({
    Key key,
    @required this.opacity,
    this.alwaysIncludeSemantics = false,
    Widget child,
  })  : assert(opacity != null && opacity >= 0.0 && opacity <= 1.0),
        assert(alwaysIncludeSemantics != null),
        super(key: key, child: child);

  final double opacity;

  final bool alwaysIncludeSemantics;

  @override
  RenderOpacity createRenderObject(BuildContext context) {
    return RenderOpacity(
      opacity: opacity,
      alwaysIncludeSemantics: alwaysIncludeSemantics,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderOpacity renderObject) {
    renderObject
      ..opacity = opacity
      ..alwaysIncludeSemantics = alwaysIncludeSemantics;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('opacity', opacity));
    properties.add(FlagProperty('alwaysIncludeSemantics',
        value: alwaysIncludeSemantics, ifTrue: 'alwaysIncludeSemantics'));
  }
}

class ShaderMask extends SingleChildRenderObjectWidget {
  const ShaderMask({
    Key key,
    @required this.shaderCallback,
    this.blendMode = BlendMode.modulate,
    Widget child,
  })  : assert(shaderCallback != null),
        assert(blendMode != null),
        super(key: key, child: child);

  final ShaderCallback shaderCallback;

  final BlendMode blendMode;

  @override
  RenderShaderMask createRenderObject(BuildContext context) {
    return RenderShaderMask(
      shaderCallback: shaderCallback,
      blendMode: blendMode,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderShaderMask renderObject) {
    renderObject
      ..shaderCallback = shaderCallback
      ..blendMode = blendMode;
  }
}

class BackdropFilter extends SingleChildRenderObjectWidget {
  const BackdropFilter({
    Key key,
    @required this.filter,
    Widget child,
  })  : assert(filter != null),
        super(key: key, child: child);

  final ui.ImageFilter filter;

  @override
  RenderBackdropFilter createRenderObject(BuildContext context) {
    return RenderBackdropFilter(filter: filter);
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderBackdropFilter renderObject) {
    renderObject.filter = filter;
  }
}

class CustomPaint extends SingleChildRenderObjectWidget {
  const CustomPaint({
    Key key,
    this.painter,
    this.foregroundPainter,
    this.size = Size.zero,
    this.isComplex = false,
    this.willChange = false,
    Widget child,
  })  : assert(size != null),
        assert(isComplex != null),
        assert(willChange != null),
        super(key: key, child: child);

  final CustomPainter painter;

  final CustomPainter foregroundPainter;

  final Size size;

  final bool isComplex;

  final bool willChange;

  @override
  RenderCustomPaint createRenderObject(BuildContext context) {
    return RenderCustomPaint(
      painter: painter,
      foregroundPainter: foregroundPainter,
      preferredSize: size,
      isComplex: isComplex,
      willChange: willChange,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderCustomPaint renderObject) {
    renderObject
      ..painter = painter
      ..foregroundPainter = foregroundPainter
      ..preferredSize = size
      ..isComplex = isComplex
      ..willChange = willChange;
  }

  @override
  void didUnmountRenderObject(RenderCustomPaint renderObject) {
    renderObject
      ..painter = null
      ..foregroundPainter = null;
  }
}

class ClipRect extends SingleChildRenderObjectWidget {
  const ClipRect(
      {Key key, this.clipper, this.clipBehavior = Clip.hardEdge, Widget child})
      : super(key: key, child: child);

  final CustomClipper<Rect> clipper;

  final Clip clipBehavior;

  @override
  RenderClipRect createRenderObject(BuildContext context) =>
      RenderClipRect(clipper: clipper, clipBehavior: clipBehavior);

  @override
  void updateRenderObject(BuildContext context, RenderClipRect renderObject) {
    renderObject
      ..clipper = clipper
      ..clipBehavior = clipBehavior;
  }

  @override
  void didUnmountRenderObject(RenderClipRect renderObject) {
    renderObject.clipper = null;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<CustomClipper<Rect>>('clipper', clipper,
        defaultValue: null));
  }
}

class ClipRRect extends SingleChildRenderObjectWidget {
  const ClipRRect({
    Key key,
    this.borderRadius,
    this.clipper,
    this.clipBehavior = Clip.antiAlias,
    Widget child,
  })  : assert(borderRadius != null || clipper != null),
        assert(clipBehavior != null),
        super(key: key, child: child);

  final BorderRadius borderRadius;

  final CustomClipper<RRect> clipper;

  final Clip clipBehavior;

  @override
  RenderClipRRect createRenderObject(BuildContext context) => RenderClipRRect(
      borderRadius: borderRadius, clipper: clipper, clipBehavior: clipBehavior);

  @override
  void updateRenderObject(BuildContext context, RenderClipRRect renderObject) {
    renderObject
      ..borderRadius = borderRadius
      ..clipBehavior = clipBehavior
      ..clipper = clipper;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<BorderRadius>(
        'borderRadius', borderRadius,
        showName: false, defaultValue: null));
    properties.add(DiagnosticsProperty<CustomClipper<RRect>>('clipper', clipper,
        defaultValue: null));
  }
}

class ClipOval extends SingleChildRenderObjectWidget {
  const ClipOval(
      {Key key, this.clipper, this.clipBehavior = Clip.antiAlias, Widget child})
      : super(key: key, child: child);

  final CustomClipper<Rect> clipper;

  final Clip clipBehavior;

  @override
  RenderClipOval createRenderObject(BuildContext context) =>
      RenderClipOval(clipper: clipper, clipBehavior: clipBehavior);

  @override
  void updateRenderObject(BuildContext context, RenderClipOval renderObject) {
    renderObject
      ..clipper = clipper
      ..clipBehavior = clipBehavior;
  }

  @override
  void didUnmountRenderObject(RenderClipOval renderObject) {
    renderObject.clipper = null;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<CustomClipper<Rect>>('clipper', clipper,
        defaultValue: null));
  }
}

class ClipPath extends SingleChildRenderObjectWidget {
  const ClipPath({
    Key key,
    this.clipper,
    this.clipBehavior = Clip.antiAlias,
    Widget child,
  }) : super(key: key, child: child);

  static Widget shape({
    Key key,
    @required ShapeBorder shape,
    Clip clipBehavior = Clip.antiAlias,
    Widget child,
  }) {
    assert(shape != null);
    return Builder(
      key: key,
      builder: (BuildContext context) {
        return ClipPath(
          clipper: ShapeBorderClipper(
            shape: shape,
            textDirection: Directionality.of(context),
          ),
          clipBehavior: clipBehavior,
          child: child,
        );
      },
    );
  }

  final CustomClipper<Path> clipper;

  final Clip clipBehavior;

  @override
  RenderClipPath createRenderObject(BuildContext context) =>
      RenderClipPath(clipper: clipper, clipBehavior: clipBehavior);

  @override
  void updateRenderObject(BuildContext context, RenderClipPath renderObject) {
    renderObject
      ..clipper = clipper
      ..clipBehavior = clipBehavior;
  }

  @override
  void didUnmountRenderObject(RenderClipPath renderObject) {
    renderObject.clipper = null;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<CustomClipper<Path>>('clipper', clipper,
        defaultValue: null));
  }
}

class PhysicalModel extends SingleChildRenderObjectWidget {
  const PhysicalModel({
    Key key,
    this.shape = BoxShape.rectangle,
    this.clipBehavior = Clip.none,
    this.borderRadius,
    this.elevation = 0.0,
    @required this.color,
    this.shadowColor = const Color(0xFF000000),
    Widget child,
  })  : assert(shape != null),
        assert(elevation != null && elevation >= 0.0),
        assert(color != null),
        assert(shadowColor != null),
        super(key: key, child: child);

  final BoxShape shape;

  final Clip clipBehavior;

  final BorderRadius borderRadius;

  final double elevation;

  final Color color;

  final Color shadowColor;

  @override
  RenderPhysicalModel createRenderObject(BuildContext context) {
    return RenderPhysicalModel(
      shape: shape,
      clipBehavior: clipBehavior,
      borderRadius: borderRadius,
      elevation: elevation,
      color: color,
      shadowColor: shadowColor,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderPhysicalModel renderObject) {
    renderObject
      ..shape = shape
      ..clipBehavior = clipBehavior
      ..borderRadius = borderRadius
      ..elevation = elevation
      ..color = color
      ..shadowColor = shadowColor;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<BoxShape>('shape', shape));
    properties
        .add(DiagnosticsProperty<BorderRadius>('borderRadius', borderRadius));
    properties.add(DoubleProperty('elevation', elevation));
    properties.add(ColorProperty('color', color));
    properties.add(ColorProperty('shadowColor', shadowColor));
  }
}

class PhysicalShape extends SingleChildRenderObjectWidget {
  const PhysicalShape({
    Key key,
    @required this.clipper,
    this.clipBehavior = Clip.none,
    this.elevation = 0.0,
    @required this.color,
    this.shadowColor = const Color(0xFF000000),
    Widget child,
  })  : assert(clipper != null),
        assert(clipBehavior != null),
        assert(elevation != null && elevation >= 0.0),
        assert(color != null),
        assert(shadowColor != null),
        super(key: key, child: child);

  final CustomClipper<Path> clipper;

  final Clip clipBehavior;

  final double elevation;

  final Color color;

  final Color shadowColor;

  @override
  RenderPhysicalShape createRenderObject(BuildContext context) {
    return RenderPhysicalShape(
      clipper: clipper,
      clipBehavior: clipBehavior,
      elevation: elevation,
      color: color,
      shadowColor: shadowColor,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderPhysicalShape renderObject) {
    renderObject
      ..clipper = clipper
      ..clipBehavior = clipBehavior
      ..elevation = elevation
      ..color = color
      ..shadowColor = shadowColor;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(DiagnosticsProperty<CustomClipper<Path>>('clipper', clipper));
    properties.add(DoubleProperty('elevation', elevation));
    properties.add(ColorProperty('color', color));
    properties.add(ColorProperty('shadowColor', shadowColor));
  }
}

class Transform extends SingleChildRenderObjectWidget {
  const Transform({
    Key key,
    @required this.transform,
    this.origin,
    this.alignment,
    this.transformHitTests = true,
    Widget child,
  })  : assert(transform != null),
        super(key: key, child: child);

  Transform.rotate({
    Key key,
    @required double angle,
    this.origin,
    this.alignment = Alignment.center,
    this.transformHitTests = true,
    Widget child,
  })  : transform = Matrix4.rotationZ(angle),
        super(key: key, child: child);

  Transform.translate({
    Key key,
    @required Offset offset,
    this.transformHitTests = true,
    Widget child,
  })  : transform = Matrix4.translationValues(offset.dx, offset.dy, 0.0),
        origin = null,
        alignment = null,
        super(key: key, child: child);

  Transform.scale({
    Key key,
    @required double scale,
    this.origin,
    this.alignment = Alignment.center,
    this.transformHitTests = true,
    Widget child,
  })  : transform = Matrix4.diagonal3Values(scale, scale, 1.0),
        super(key: key, child: child);

  final Matrix4 transform;

  final Offset origin;

  final AlignmentGeometry alignment;

  final bool transformHitTests;

  @override
  RenderTransform createRenderObject(BuildContext context) {
    return RenderTransform(
      transform: transform,
      origin: origin,
      alignment: alignment,
      textDirection: Directionality.of(context),
      transformHitTests: transformHitTests,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderTransform renderObject) {
    renderObject
      ..transform = transform
      ..origin = origin
      ..alignment = alignment
      ..textDirection = Directionality.of(context)
      ..transformHitTests = transformHitTests;
  }
}

class CompositedTransformTarget extends SingleChildRenderObjectWidget {
  const CompositedTransformTarget({
    Key key,
    @required this.link,
    Widget child,
  })  : assert(link != null),
        super(key: key, child: child);

  final LayerLink link;

  @override
  RenderLeaderLayer createRenderObject(BuildContext context) {
    return RenderLeaderLayer(
      link: link,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderLeaderLayer renderObject) {
    renderObject..link = link;
  }
}

class CompositedTransformFollower extends SingleChildRenderObjectWidget {
  const CompositedTransformFollower({
    Key key,
    @required this.link,
    this.showWhenUnlinked = true,
    this.offset = Offset.zero,
    Widget child,
  })  : assert(link != null),
        assert(showWhenUnlinked != null),
        assert(offset != null),
        super(key: key, child: child);

  final LayerLink link;

  final bool showWhenUnlinked;

  final Offset offset;

  @override
  RenderFollowerLayer createRenderObject(BuildContext context) {
    return RenderFollowerLayer(
      link: link,
      showWhenUnlinked: showWhenUnlinked,
      offset: offset,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderFollowerLayer renderObject) {
    renderObject
      ..link = link
      ..showWhenUnlinked = showWhenUnlinked
      ..offset = offset;
  }
}

class FittedBox extends SingleChildRenderObjectWidget {
  const FittedBox({
    Key key,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    Widget child,
  })  : assert(fit != null),
        assert(alignment != null),
        super(key: key, child: child);

  final BoxFit fit;

  final AlignmentGeometry alignment;

  @override
  RenderFittedBox createRenderObject(BuildContext context) {
    return RenderFittedBox(
      fit: fit,
      alignment: alignment,
      textDirection: Directionality.of(context),
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderFittedBox renderObject) {
    renderObject
      ..fit = fit
      ..alignment = alignment
      ..textDirection = Directionality.of(context);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<BoxFit>('fit', fit));
    properties
        .add(DiagnosticsProperty<AlignmentGeometry>('alignment', alignment));
  }
}

class FractionalTranslation extends SingleChildRenderObjectWidget {
  const FractionalTranslation({
    Key key,
    @required this.translation,
    this.transformHitTests = true,
    Widget child,
  })  : assert(translation != null),
        super(key: key, child: child);

  final Offset translation;

  final bool transformHitTests;

  @override
  RenderFractionalTranslation createRenderObject(BuildContext context) {
    return RenderFractionalTranslation(
      translation: translation,
      transformHitTests: transformHitTests,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderFractionalTranslation renderObject) {
    renderObject
      ..translation = translation
      ..transformHitTests = transformHitTests;
  }
}

class RotatedBox extends SingleChildRenderObjectWidget {
  const RotatedBox({
    Key key,
    @required this.quarterTurns,
    Widget child,
  })  : assert(quarterTurns != null),
        super(key: key, child: child);

  final int quarterTurns;

  @override
  RenderRotatedBox createRenderObject(BuildContext context) =>
      RenderRotatedBox(quarterTurns: quarterTurns);

  @override
  void updateRenderObject(BuildContext context, RenderRotatedBox renderObject) {
    renderObject.quarterTurns = quarterTurns;
  }
}

class Padding extends SingleChildRenderObjectWidget {
  const Padding({
    Key key,
    @required this.padding,
    Widget child,
  })  : assert(padding != null),
        super(key: key, child: child);

  final EdgeInsetsGeometry padding;

  @override
  RenderPadding createRenderObject(BuildContext context) {
    return RenderPadding(
      padding: padding,
      textDirection: Directionality.of(context),
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderPadding renderObject) {
    renderObject
      ..padding = padding
      ..textDirection = Directionality.of(context);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('padding', padding));
  }
}

class Align extends SingleChildRenderObjectWidget {
  const Align({
    Key key,
    this.alignment = Alignment.center,
    this.widthFactor,
    this.heightFactor,
    Widget child,
  })  : assert(alignment != null),
        assert(widthFactor == null || widthFactor >= 0.0),
        assert(heightFactor == null || heightFactor >= 0.0),
        super(key: key, child: child);

  final AlignmentGeometry alignment;

  final double widthFactor;

  final double heightFactor;

  @override
  RenderPositionedBox createRenderObject(BuildContext context) {
    return RenderPositionedBox(
      alignment: alignment,
      widthFactor: widthFactor,
      heightFactor: heightFactor,
      textDirection: Directionality.of(context),
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderPositionedBox renderObject) {
    renderObject
      ..alignment = alignment
      ..widthFactor = widthFactor
      ..heightFactor = heightFactor
      ..textDirection = Directionality.of(context);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(DiagnosticsProperty<AlignmentGeometry>('alignment', alignment));
    properties
        .add(DoubleProperty('widthFactor', widthFactor, defaultValue: null));
    properties
        .add(DoubleProperty('heightFactor', heightFactor, defaultValue: null));
  }
}

class Center extends Align {
  const Center({Key key, double widthFactor, double heightFactor, Widget child})
      : super(
            key: key,
            widthFactor: widthFactor,
            heightFactor: heightFactor,
            child: child);
}

class CustomSingleChildLayout extends SingleChildRenderObjectWidget {
  const CustomSingleChildLayout({
    Key key,
    @required this.delegate,
    Widget child,
  })  : assert(delegate != null),
        super(key: key, child: child);

  final SingleChildLayoutDelegate delegate;

  @override
  RenderCustomSingleChildLayoutBox createRenderObject(BuildContext context) {
    return RenderCustomSingleChildLayoutBox(delegate: delegate);
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderCustomSingleChildLayoutBox renderObject) {
    renderObject.delegate = delegate;
  }
}

class LayoutId extends ParentDataWidget<CustomMultiChildLayout> {
  LayoutId({
    Key key,
    @required this.id,
    @required Widget child,
  })  : assert(child != null),
        assert(id != null),
        super(key: key ?? ValueKey<Object>(id), child: child);

  final Object id;

  @override
  void applyParentData(RenderObject renderObject) {
    assert(renderObject.parentData is MultiChildLayoutParentData);
    final MultiChildLayoutParentData parentData = renderObject.parentData;
    if (parentData.id != id) {
      parentData.id = id;
      final AbstractNode targetParent = renderObject.parent;
      if (targetParent is RenderObject) targetParent.markNeedsLayout();
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Object>('id', id));
  }
}

class CustomMultiChildLayout extends MultiChildRenderObjectWidget {
  CustomMultiChildLayout({
    Key key,
    @required this.delegate,
    List<Widget> children = const <Widget>[],
  })  : assert(delegate != null),
        super(key: key, children: children);

  final MultiChildLayoutDelegate delegate;

  @override
  RenderCustomMultiChildLayoutBox createRenderObject(BuildContext context) {
    return RenderCustomMultiChildLayoutBox(delegate: delegate);
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderCustomMultiChildLayoutBox renderObject) {
    renderObject.delegate = delegate;
  }
}

class SizedBox extends SingleChildRenderObjectWidget {
  const SizedBox({Key key, this.width, this.height, Widget child})
      : super(key: key, child: child);

  const SizedBox.expand({Key key, Widget child})
      : width = double.infinity,
        height = double.infinity,
        super(key: key, child: child);

  const SizedBox.shrink({Key key, Widget child})
      : width = 0.0,
        height = 0.0,
        super(key: key, child: child);

  SizedBox.fromSize({Key key, Widget child, Size size})
      : width = size?.width,
        height = size?.height,
        super(key: key, child: child);

  final double width;

  final double height;

  @override
  RenderConstrainedBox createRenderObject(BuildContext context) {
    return RenderConstrainedBox(
      additionalConstraints: _additionalConstraints,
    );
  }

  BoxConstraints get _additionalConstraints {
    return BoxConstraints.tightFor(width: width, height: height);
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderConstrainedBox renderObject) {
    renderObject.additionalConstraints = _additionalConstraints;
  }

  @override
  String toStringShort() {
    String type;
    if (width == double.infinity && height == double.infinity) {
      type = '$runtimeType.expand';
    } else if (width == 0.0 && height == 0.0) {
      type = '$runtimeType.shrink';
    } else {
      type = '$runtimeType';
    }
    return key == null ? '$type' : '$type-$key';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    DiagnosticLevel level;
    if ((width == double.infinity && height == double.infinity) ||
        (width == 0.0 && height == 0.0)) {
      level = DiagnosticLevel.hidden;
    } else {
      level = DiagnosticLevel.info;
    }
    properties
        .add(DoubleProperty('width', width, defaultValue: null, level: level));
    properties.add(
        DoubleProperty('height', height, defaultValue: null, level: level));
  }
}

class ConstrainedBox extends SingleChildRenderObjectWidget {
  ConstrainedBox({
    Key key,
    @required this.constraints,
    Widget child,
  })  : assert(constraints != null),
        assert(constraints.debugAssertIsValid()),
        super(key: key, child: child);

  final BoxConstraints constraints;

  @override
  RenderConstrainedBox createRenderObject(BuildContext context) {
    return RenderConstrainedBox(additionalConstraints: constraints);
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderConstrainedBox renderObject) {
    renderObject.additionalConstraints = constraints;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<BoxConstraints>(
        'constraints', constraints,
        showName: false));
  }
}

class UnconstrainedBox extends SingleChildRenderObjectWidget {
  const UnconstrainedBox({
    Key key,
    Widget child,
    this.textDirection,
    this.alignment = Alignment.center,
    this.constrainedAxis,
  })  : assert(alignment != null),
        super(key: key, child: child);

  final TextDirection textDirection;

  final AlignmentGeometry alignment;

  final Axis constrainedAxis;

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderUnconstrainedBox renderObject) {
    renderObject
      ..textDirection = textDirection ?? Directionality.of(context)
      ..alignment = alignment
      ..constrainedAxis = constrainedAxis;
  }

  @override
  RenderUnconstrainedBox createRenderObject(BuildContext context) =>
      RenderUnconstrainedBox(
        textDirection: textDirection ?? Directionality.of(context),
        alignment: alignment,
        constrainedAxis: constrainedAxis,
      );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(DiagnosticsProperty<AlignmentGeometry>('alignment', alignment));
    properties.add(EnumProperty<Axis>('constrainedAxis', constrainedAxis,
        defaultValue: null));
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection,
        defaultValue: null));
  }
}

class FractionallySizedBox extends SingleChildRenderObjectWidget {
  const FractionallySizedBox({
    Key key,
    this.alignment = Alignment.center,
    this.widthFactor,
    this.heightFactor,
    Widget child,
  })  : assert(alignment != null),
        assert(widthFactor == null || widthFactor >= 0.0),
        assert(heightFactor == null || heightFactor >= 0.0),
        super(key: key, child: child);

  final double widthFactor;

  final double heightFactor;

  final AlignmentGeometry alignment;

  @override
  RenderFractionallySizedOverflowBox createRenderObject(BuildContext context) {
    return RenderFractionallySizedOverflowBox(
      alignment: alignment,
      widthFactor: widthFactor,
      heightFactor: heightFactor,
      textDirection: Directionality.of(context),
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderFractionallySizedOverflowBox renderObject) {
    renderObject
      ..alignment = alignment
      ..widthFactor = widthFactor
      ..heightFactor = heightFactor
      ..textDirection = Directionality.of(context);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(DiagnosticsProperty<AlignmentGeometry>('alignment', alignment));
    properties
        .add(DoubleProperty('widthFactor', widthFactor, defaultValue: null));
    properties
        .add(DoubleProperty('heightFactor', heightFactor, defaultValue: null));
  }
}

class LimitedBox extends SingleChildRenderObjectWidget {
  const LimitedBox({
    Key key,
    this.maxWidth = double.infinity,
    this.maxHeight = double.infinity,
    Widget child,
  })  : assert(maxWidth != null && maxWidth >= 0.0),
        assert(maxHeight != null && maxHeight >= 0.0),
        super(key: key, child: child);

  final double maxWidth;

  final double maxHeight;

  @override
  RenderLimitedBox createRenderObject(BuildContext context) {
    return RenderLimitedBox(
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderLimitedBox renderObject) {
    renderObject
      ..maxWidth = maxWidth
      ..maxHeight = maxHeight;
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

class OverflowBox extends SingleChildRenderObjectWidget {
  const OverflowBox({
    Key key,
    this.alignment = Alignment.center,
    this.minWidth,
    this.maxWidth,
    this.minHeight,
    this.maxHeight,
    Widget child,
  }) : super(key: key, child: child);

  final AlignmentGeometry alignment;

  final double minWidth;

  final double maxWidth;

  final double minHeight;

  final double maxHeight;

  @override
  RenderConstrainedOverflowBox createRenderObject(BuildContext context) {
    return RenderConstrainedOverflowBox(
      alignment: alignment,
      minWidth: minWidth,
      maxWidth: maxWidth,
      minHeight: minHeight,
      maxHeight: maxHeight,
      textDirection: Directionality.of(context),
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderConstrainedOverflowBox renderObject) {
    renderObject
      ..alignment = alignment
      ..minWidth = minWidth
      ..maxWidth = maxWidth
      ..minHeight = minHeight
      ..maxHeight = maxHeight
      ..textDirection = Directionality.of(context);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(DiagnosticsProperty<AlignmentGeometry>('alignment', alignment));
    properties.add(DoubleProperty('minWidth', minWidth, defaultValue: null));
    properties.add(DoubleProperty('maxWidth', maxWidth, defaultValue: null));
    properties.add(DoubleProperty('minHeight', minHeight, defaultValue: null));
    properties.add(DoubleProperty('maxHeight', maxHeight, defaultValue: null));
  }
}

class SizedOverflowBox extends SingleChildRenderObjectWidget {
  const SizedOverflowBox({
    Key key,
    @required this.size,
    this.alignment = Alignment.center,
    Widget child,
  })  : assert(size != null),
        assert(alignment != null),
        super(key: key, child: child);

  final AlignmentGeometry alignment;

  final Size size;

  @override
  RenderSizedOverflowBox createRenderObject(BuildContext context) {
    return RenderSizedOverflowBox(
      alignment: alignment,
      requestedSize: size,
      textDirection: Directionality.of(context),
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderSizedOverflowBox renderObject) {
    renderObject
      ..alignment = alignment
      ..requestedSize = size
      ..textDirection = Directionality.of(context);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(DiagnosticsProperty<AlignmentGeometry>('alignment', alignment));
    properties.add(DiagnosticsProperty<Size>('size', size, defaultValue: null));
  }
}

class Offstage extends SingleChildRenderObjectWidget {
  const Offstage({Key key, this.offstage = true, Widget child})
      : assert(offstage != null),
        super(key: key, child: child);

  final bool offstage;

  @override
  RenderOffstage createRenderObject(BuildContext context) =>
      RenderOffstage(offstage: offstage);

  @override
  void updateRenderObject(BuildContext context, RenderOffstage renderObject) {
    renderObject.offstage = offstage;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('offstage', offstage));
  }

  @override
  _OffstageElement createElement() => _OffstageElement(this);
}

class _OffstageElement extends SingleChildRenderObjectElement {
  _OffstageElement(Offstage widget) : super(widget);

  @override
  Offstage get widget => super.widget;

  @override
  void debugVisitOnstageChildren(ElementVisitor visitor) {
    if (!widget.offstage) super.debugVisitOnstageChildren(visitor);
  }
}

class AspectRatio extends SingleChildRenderObjectWidget {
  const AspectRatio({
    Key key,
    @required this.aspectRatio,
    Widget child,
  })  : assert(aspectRatio != null),
        super(key: key, child: child);

  final double aspectRatio;

  @override
  RenderAspectRatio createRenderObject(BuildContext context) =>
      RenderAspectRatio(aspectRatio: aspectRatio);

  @override
  void updateRenderObject(
      BuildContext context, RenderAspectRatio renderObject) {
    renderObject.aspectRatio = aspectRatio;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('aspectRatio', aspectRatio));
  }
}

class IntrinsicWidth extends SingleChildRenderObjectWidget {
  const IntrinsicWidth({Key key, this.stepWidth, this.stepHeight, Widget child})
      : assert(stepWidth == null || stepWidth >= 0.0),
        assert(stepHeight == null || stepHeight >= 0.0),
        super(key: key, child: child);

  final double stepWidth;

  final double stepHeight;

  double get _stepWidth => stepWidth == 0.0 ? null : stepWidth;
  double get _stepHeight => stepHeight == 0.0 ? null : stepHeight;

  @override
  RenderIntrinsicWidth createRenderObject(BuildContext context) {
    return RenderIntrinsicWidth(stepWidth: _stepWidth, stepHeight: _stepHeight);
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderIntrinsicWidth renderObject) {
    renderObject
      ..stepWidth = _stepWidth
      ..stepHeight = _stepHeight;
  }
}

class IntrinsicHeight extends SingleChildRenderObjectWidget {
  const IntrinsicHeight({Key key, Widget child})
      : super(key: key, child: child);

  @override
  RenderIntrinsicHeight createRenderObject(BuildContext context) =>
      RenderIntrinsicHeight();
}

class Baseline extends SingleChildRenderObjectWidget {
  const Baseline({
    Key key,
    @required this.baseline,
    @required this.baselineType,
    Widget child,
  })  : assert(baseline != null),
        assert(baselineType != null),
        super(key: key, child: child);

  final double baseline;

  final TextBaseline baselineType;

  @override
  RenderBaseline createRenderObject(BuildContext context) {
    return RenderBaseline(baseline: baseline, baselineType: baselineType);
  }

  @override
  void updateRenderObject(BuildContext context, RenderBaseline renderObject) {
    renderObject
      ..baseline = baseline
      ..baselineType = baselineType;
  }
}

class SliverToBoxAdapter extends SingleChildRenderObjectWidget {
  const SliverToBoxAdapter({
    Key key,
    Widget child,
  }) : super(key: key, child: child);

  @override
  RenderSliverToBoxAdapter createRenderObject(BuildContext context) =>
      RenderSliverToBoxAdapter();
}

class SliverPadding extends SingleChildRenderObjectWidget {
  const SliverPadding({
    Key key,
    @required this.padding,
    Widget sliver,
  })  : assert(padding != null),
        super(key: key, child: sliver);

  final EdgeInsetsGeometry padding;

  @override
  RenderSliverPadding createRenderObject(BuildContext context) {
    return RenderSliverPadding(
      padding: padding,
      textDirection: Directionality.of(context),
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderSliverPadding renderObject) {
    renderObject
      ..padding = padding
      ..textDirection = Directionality.of(context);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('padding', padding));
  }
}

AxisDirection getAxisDirectionFromAxisReverseAndDirectionality(
  BuildContext context,
  Axis axis,
  bool reverse,
) {
  switch (axis) {
    case Axis.horizontal:
      assert(debugCheckHasDirectionality(context));
      final TextDirection textDirection = Directionality.of(context);
      final AxisDirection axisDirection =
          textDirectionToAxisDirection(textDirection);
      return reverse ? flipAxisDirection(axisDirection) : axisDirection;
    case Axis.vertical:
      return reverse ? AxisDirection.up : AxisDirection.down;
  }
  return null;
}

class ListBody extends MultiChildRenderObjectWidget {
  ListBody({
    Key key,
    this.mainAxis = Axis.vertical,
    this.reverse = false,
    List<Widget> children = const <Widget>[],
  })  : assert(mainAxis != null),
        super(key: key, children: children);

  final Axis mainAxis;

  final bool reverse;

  AxisDirection _getDirection(BuildContext context) {
    return getAxisDirectionFromAxisReverseAndDirectionality(
        context, mainAxis, reverse);
  }

  @override
  RenderListBody createRenderObject(BuildContext context) {
    return RenderListBody(axisDirection: _getDirection(context));
  }

  @override
  void updateRenderObject(BuildContext context, RenderListBody renderObject) {
    renderObject.axisDirection = _getDirection(context);
  }
}

class Stack extends MultiChildRenderObjectWidget {
  Stack({
    Key key,
    this.alignment = AlignmentDirectional.topStart,
    this.textDirection,
    this.fit = StackFit.loose,
    this.overflow = Overflow.clip,
    List<Widget> children = const <Widget>[],
  }) : super(key: key, children: children);

  final AlignmentGeometry alignment;

  final TextDirection textDirection;

  final StackFit fit;

  final Overflow overflow;

  @override
  RenderStack createRenderObject(BuildContext context) {
    return RenderStack(
      alignment: alignment,
      textDirection: textDirection ?? Directionality.of(context),
      fit: fit,
      overflow: overflow,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderStack renderObject) {
    renderObject
      ..alignment = alignment
      ..textDirection = textDirection ?? Directionality.of(context)
      ..fit = fit
      ..overflow = overflow;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(DiagnosticsProperty<AlignmentGeometry>('alignment', alignment));
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection,
        defaultValue: null));
    properties.add(EnumProperty<StackFit>('fit', fit));
    properties.add(EnumProperty<Overflow>('overflow', overflow));
  }
}

class IndexedStack extends Stack {
  IndexedStack({
    Key key,
    AlignmentGeometry alignment = AlignmentDirectional.topStart,
    TextDirection textDirection,
    StackFit sizing = StackFit.loose,
    this.index = 0,
    List<Widget> children = const <Widget>[],
  }) : super(
            key: key,
            alignment: alignment,
            textDirection: textDirection,
            fit: sizing,
            children: children);

  final int index;

  @override
  RenderIndexedStack createRenderObject(BuildContext context) {
    return RenderIndexedStack(
      index: index,
      alignment: alignment,
      textDirection: textDirection ?? Directionality.of(context),
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderIndexedStack renderObject) {
    renderObject
      ..index = index
      ..alignment = alignment
      ..textDirection = textDirection ?? Directionality.of(context);
  }
}

class Positioned extends ParentDataWidget<Stack> {
  const Positioned({
    Key key,
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.width,
    this.height,
    @required Widget child,
  })  : assert(left == null || right == null || width == null),
        assert(top == null || bottom == null || height == null),
        super(key: key, child: child);

  Positioned.fromRect({
    Key key,
    Rect rect,
    @required Widget child,
  })  : left = rect.left,
        top = rect.top,
        width = rect.width,
        height = rect.height,
        right = null,
        bottom = null,
        super(key: key, child: child);

  Positioned.fromRelativeRect({
    Key key,
    RelativeRect rect,
    @required Widget child,
  })  : left = rect.left,
        top = rect.top,
        right = rect.right,
        bottom = rect.bottom,
        width = null,
        height = null,
        super(key: key, child: child);

  const Positioned.fill({
    Key key,
    this.left = 0.0,
    this.top = 0.0,
    this.right = 0.0,
    this.bottom = 0.0,
    @required Widget child,
  })  : width = null,
        height = null,
        super(key: key, child: child);

  factory Positioned.directional({
    Key key,
    @required TextDirection textDirection,
    double start,
    double top,
    double end,
    double bottom,
    double width,
    double height,
    @required Widget child,
  }) {
    assert(textDirection != null);
    double left;
    double right;
    switch (textDirection) {
      case TextDirection.rtl:
        left = end;
        right = start;
        break;
      case TextDirection.ltr:
        left = start;
        right = end;
        break;
    }
    return Positioned(
      key: key,
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      width: width,
      height: height,
      child: child,
    );
  }

  final double left;

  final double top;

  final double right;

  final double bottom;

  final double width;

  final double height;

  @override
  void applyParentData(RenderObject renderObject) {
    assert(renderObject.parentData is StackParentData);
    final StackParentData parentData = renderObject.parentData;
    bool needsLayout = false;

    if (parentData.left != left) {
      parentData.left = left;
      needsLayout = true;
    }

    if (parentData.top != top) {
      parentData.top = top;
      needsLayout = true;
    }

    if (parentData.right != right) {
      parentData.right = right;
      needsLayout = true;
    }

    if (parentData.bottom != bottom) {
      parentData.bottom = bottom;
      needsLayout = true;
    }

    if (parentData.width != width) {
      parentData.width = width;
      needsLayout = true;
    }

    if (parentData.height != height) {
      parentData.height = height;
      needsLayout = true;
    }

    if (needsLayout) {
      final AbstractNode targetParent = renderObject.parent;
      if (targetParent is RenderObject) targetParent.markNeedsLayout();
    }
  }

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

class PositionedDirectional extends StatelessWidget {
  const PositionedDirectional({
    Key key,
    this.start,
    this.top,
    this.end,
    this.bottom,
    this.width,
    this.height,
    @required this.child,
  }) : super(key: key);

  final double start;

  final double top;

  final double end;

  final double bottom;

  final double width;

  final double height;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned.directional(
      textDirection: Directionality.of(context),
      start: start,
      top: top,
      end: end,
      bottom: bottom,
      width: width,
      height: height,
      child: child,
    );
  }
}

class Flex extends MultiChildRenderObjectWidget {
  Flex({
    Key key,
    @required this.direction,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.textDirection,
    this.verticalDirection = VerticalDirection.down,
    this.textBaseline,
    List<Widget> children = const <Widget>[],
  })  : assert(direction != null),
        assert(mainAxisAlignment != null),
        assert(mainAxisSize != null),
        assert(crossAxisAlignment != null),
        assert(verticalDirection != null),
        assert(crossAxisAlignment != CrossAxisAlignment.baseline ||
            textBaseline != null),
        super(key: key, children: children);

  final Axis direction;

  final MainAxisAlignment mainAxisAlignment;

  final MainAxisSize mainAxisSize;

  final CrossAxisAlignment crossAxisAlignment;

  final TextDirection textDirection;

  final VerticalDirection verticalDirection;

  final TextBaseline textBaseline;

  bool get _needTextDirection {
    assert(direction != null);
    switch (direction) {
      case Axis.horizontal:
        return true;
      case Axis.vertical:
        assert(crossAxisAlignment != null);
        return crossAxisAlignment == CrossAxisAlignment.start ||
            crossAxisAlignment == CrossAxisAlignment.end;
    }
    return null;
  }

  @protected
  TextDirection getEffectiveTextDirection(BuildContext context) {
    return textDirection ??
        (_needTextDirection ? Directionality.of(context) : null);
  }

  @override
  RenderFlex createRenderObject(BuildContext context) {
    return RenderFlex(
      direction: direction,
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      crossAxisAlignment: crossAxisAlignment,
      textDirection: getEffectiveTextDirection(context),
      verticalDirection: verticalDirection,
      textBaseline: textBaseline,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderFlex renderObject) {
    renderObject
      ..direction = direction
      ..mainAxisAlignment = mainAxisAlignment
      ..mainAxisSize = mainAxisSize
      ..crossAxisAlignment = crossAxisAlignment
      ..textDirection = getEffectiveTextDirection(context)
      ..verticalDirection = verticalDirection
      ..textBaseline = textBaseline;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<Axis>('direction', direction));
    properties.add(EnumProperty<MainAxisAlignment>(
        'mainAxisAlignment', mainAxisAlignment));
    properties.add(EnumProperty<MainAxisSize>('mainAxisSize', mainAxisSize,
        defaultValue: MainAxisSize.max));
    properties.add(EnumProperty<CrossAxisAlignment>(
        'crossAxisAlignment', crossAxisAlignment));
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection,
        defaultValue: null));
    properties.add(EnumProperty<VerticalDirection>(
        'verticalDirection', verticalDirection,
        defaultValue: VerticalDirection.down));
    properties.add(EnumProperty<TextBaseline>('textBaseline', textBaseline,
        defaultValue: null));
  }
}

class Row extends Flex {
  Row({
    Key key,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    MainAxisSize mainAxisSize = MainAxisSize.max,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    TextDirection textDirection,
    VerticalDirection verticalDirection = VerticalDirection.down,
    TextBaseline textBaseline,
    List<Widget> children = const <Widget>[],
  }) : super(
          children: children,
          key: key,
          direction: Axis.horizontal,
          mainAxisAlignment: mainAxisAlignment,
          mainAxisSize: mainAxisSize,
          crossAxisAlignment: crossAxisAlignment,
          textDirection: textDirection,
          verticalDirection: verticalDirection,
          textBaseline: textBaseline,
        );
}

class Column extends Flex {
  Column({
    Key key,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    MainAxisSize mainAxisSize = MainAxisSize.max,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    TextDirection textDirection,
    VerticalDirection verticalDirection = VerticalDirection.down,
    TextBaseline textBaseline,
    List<Widget> children = const <Widget>[],
  }) : super(
          children: children,
          key: key,
          direction: Axis.vertical,
          mainAxisAlignment: mainAxisAlignment,
          mainAxisSize: mainAxisSize,
          crossAxisAlignment: crossAxisAlignment,
          textDirection: textDirection,
          verticalDirection: verticalDirection,
          textBaseline: textBaseline,
        );
}

class Flexible extends ParentDataWidget<Flex> {
  const Flexible({
    Key key,
    this.flex = 1,
    this.fit = FlexFit.loose,
    @required Widget child,
  }) : super(key: key, child: child);

  final int flex;

  final FlexFit fit;

  @override
  void applyParentData(RenderObject renderObject) {
    assert(renderObject.parentData is FlexParentData);
    final FlexParentData parentData = renderObject.parentData;
    bool needsLayout = false;

    if (parentData.flex != flex) {
      parentData.flex = flex;
      needsLayout = true;
    }

    if (parentData.fit != fit) {
      parentData.fit = fit;
      needsLayout = true;
    }

    if (needsLayout) {
      final AbstractNode targetParent = renderObject.parent;
      if (targetParent is RenderObject) targetParent.markNeedsLayout();
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('flex', flex));
  }
}

class Expanded extends Flexible {
  const Expanded({
    Key key,
    int flex = 1,
    @required Widget child,
  }) : super(key: key, flex: flex, fit: FlexFit.tight, child: child);
}

class Wrap extends MultiChildRenderObjectWidget {
  Wrap({
    Key key,
    this.direction = Axis.horizontal,
    this.alignment = WrapAlignment.start,
    this.spacing = 0.0,
    this.runAlignment = WrapAlignment.start,
    this.runSpacing = 0.0,
    this.crossAxisAlignment = WrapCrossAlignment.start,
    this.textDirection,
    this.verticalDirection = VerticalDirection.down,
    List<Widget> children = const <Widget>[],
  }) : super(key: key, children: children);

  final Axis direction;

  final WrapAlignment alignment;

  final double spacing;

  final WrapAlignment runAlignment;

  final double runSpacing;

  final WrapCrossAlignment crossAxisAlignment;

  final TextDirection textDirection;

  final VerticalDirection verticalDirection;

  @override
  RenderWrap createRenderObject(BuildContext context) {
    return RenderWrap(
      direction: direction,
      alignment: alignment,
      spacing: spacing,
      runAlignment: runAlignment,
      runSpacing: runSpacing,
      crossAxisAlignment: crossAxisAlignment,
      textDirection: textDirection ?? Directionality.of(context),
      verticalDirection: verticalDirection,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderWrap renderObject) {
    renderObject
      ..direction = direction
      ..alignment = alignment
      ..spacing = spacing
      ..runAlignment = runAlignment
      ..runSpacing = runSpacing
      ..crossAxisAlignment = crossAxisAlignment
      ..textDirection = textDirection ?? Directionality.of(context)
      ..verticalDirection = verticalDirection;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<Axis>('direction', direction));
    properties.add(EnumProperty<WrapAlignment>('alignment', alignment));
    properties.add(DoubleProperty('spacing', spacing));
    properties.add(EnumProperty<WrapAlignment>('runAlignment', runAlignment));
    properties.add(DoubleProperty('runSpacing', runSpacing));
    properties.add(DoubleProperty('crossAxisAlignment', runSpacing));
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection,
        defaultValue: null));
    properties.add(EnumProperty<VerticalDirection>(
        'verticalDirection', verticalDirection,
        defaultValue: VerticalDirection.down));
  }
}

class Flow extends MultiChildRenderObjectWidget {
  Flow({
    Key key,
    @required this.delegate,
    List<Widget> children = const <Widget>[],
  })  : assert(delegate != null),
        super(key: key, children: RepaintBoundary.wrapAll(children));

  Flow.unwrapped({
    Key key,
    @required this.delegate,
    List<Widget> children = const <Widget>[],
  })  : assert(delegate != null),
        super(key: key, children: children);

  final FlowDelegate delegate;

  @override
  RenderFlow createRenderObject(BuildContext context) =>
      RenderFlow(delegate: delegate);

  @override
  void updateRenderObject(BuildContext context, RenderFlow renderObject) {
    renderObject..delegate = delegate;
  }
}

class RichText extends MultiChildRenderObjectWidget {
  RichText({
    Key key,
    @required this.text,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.softWrap = true,
    this.overflow = TextOverflow.clip,
    this.textScaleFactor = 1.0,
    this.maxLines,
    this.locale,
    this.strutStyle,
    this.textWidthBasis = TextWidthBasis.parent,
  })  : assert(text != null),
        assert(textAlign != null),
        assert(softWrap != null),
        assert(overflow != null),
        assert(textScaleFactor != null),
        assert(maxLines == null || maxLines > 0),
        assert(textWidthBasis != null),
        super(key: key, children: _extractChildren(text));

  static List<Widget> _extractChildren(InlineSpan span) {
    final List<Widget> result = <Widget>[];
    span.visitChildren((InlineSpan span) {
      if (span is WidgetSpan) {
        result.add(span.child);
      }
      return true;
    });
    return result;
  }

  final InlineSpan text;

  final TextAlign textAlign;

  final TextDirection textDirection;

  final bool softWrap;

  final TextOverflow overflow;

  final double textScaleFactor;

  final int maxLines;

  final Locale locale;

  final StrutStyle strutStyle;

  final TextWidthBasis textWidthBasis;

  @override
  RenderParagraph createRenderObject(BuildContext context) {
    assert(textDirection != null || debugCheckHasDirectionality(context));
    return RenderParagraph(
      text,
      textAlign: textAlign,
      textDirection: textDirection ?? Directionality.of(context),
      softWrap: softWrap,
      overflow: overflow,
      textScaleFactor: textScaleFactor,
      maxLines: maxLines,
      strutStyle: strutStyle,
      textWidthBasis: textWidthBasis,
      locale: locale ?? Localizations.localeOf(context, nullOk: true),
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderParagraph renderObject) {
    assert(textDirection != null || debugCheckHasDirectionality(context));
    renderObject
      ..text = text
      ..textAlign = textAlign
      ..textDirection = textDirection ?? Directionality.of(context)
      ..softWrap = softWrap
      ..overflow = overflow
      ..textScaleFactor = textScaleFactor
      ..maxLines = maxLines
      ..strutStyle = strutStyle
      ..textWidthBasis = textWidthBasis
      ..locale = locale ?? Localizations.localeOf(context, nullOk: true);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<TextAlign>('textAlign', textAlign,
        defaultValue: TextAlign.start));
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection,
        defaultValue: null));
    properties.add(FlagProperty('softWrap',
        value: softWrap,
        ifTrue: 'wrapping at box width',
        ifFalse: 'no wrapping except at line break characters',
        showName: true));
    properties.add(EnumProperty<TextOverflow>('overflow', overflow,
        defaultValue: TextOverflow.clip));
    properties.add(
        DoubleProperty('textScaleFactor', textScaleFactor, defaultValue: 1.0));
    properties.add(IntProperty('maxLines', maxLines, ifNull: 'unlimited'));
    properties.add(EnumProperty<TextWidthBasis>(
        'textWidthBasis', textWidthBasis,
        defaultValue: TextWidthBasis.parent));
    properties.add(StringProperty('text', text.toPlainText()));
  }
}

class RawImage extends LeafRenderObjectWidget {
  const RawImage({
    Key key,
    this.image,
    this.width,
    this.height,
    this.scale = 1.0,
    this.color,
    this.colorBlendMode,
    this.fit,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.centerSlice,
    this.matchTextDirection = false,
    this.invertColors = false,
    this.filterQuality = FilterQuality.low,
  })  : assert(scale != null),
        assert(alignment != null),
        assert(repeat != null),
        assert(matchTextDirection != null),
        super(key: key);

  final ui.Image image;

  final double width;

  final double height;

  final double scale;

  final Color color;

  final FilterQuality filterQuality;

  final BlendMode colorBlendMode;

  final BoxFit fit;

  final AlignmentGeometry alignment;

  final ImageRepeat repeat;

  final Rect centerSlice;

  final bool matchTextDirection;

  final bool invertColors;

  @override
  RenderImage createRenderObject(BuildContext context) {
    assert((!matchTextDirection && alignment is Alignment) ||
        debugCheckHasDirectionality(context));
    return RenderImage(
      image: image,
      width: width,
      height: height,
      scale: scale,
      color: color,
      colorBlendMode: colorBlendMode,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      centerSlice: centerSlice,
      matchTextDirection: matchTextDirection,
      textDirection: matchTextDirection || alignment is! Alignment
          ? Directionality.of(context)
          : null,
      invertColors: invertColors,
      filterQuality: filterQuality,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderImage renderObject) {
    renderObject
      ..image = image
      ..width = width
      ..height = height
      ..scale = scale
      ..color = color
      ..colorBlendMode = colorBlendMode
      ..alignment = alignment
      ..fit = fit
      ..repeat = repeat
      ..centerSlice = centerSlice
      ..matchTextDirection = matchTextDirection
      ..textDirection = matchTextDirection || alignment is! Alignment
          ? Directionality.of(context)
          : null
      ..invertColors = invertColors
      ..filterQuality = filterQuality;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ui.Image>('image', image));
    properties.add(DoubleProperty('width', width, defaultValue: null));
    properties.add(DoubleProperty('height', height, defaultValue: null));
    properties.add(DoubleProperty('scale', scale, defaultValue: 1.0));
    properties.add(ColorProperty('color', color, defaultValue: null));
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
    properties.add(DiagnosticsProperty<bool>('invertColors', invertColors));
    properties.add(EnumProperty<FilterQuality>('filterQuality', filterQuality));
  }
}

class DefaultAssetBundle extends InheritedWidget {
  const DefaultAssetBundle({
    Key key,
    @required this.bundle,
    @required Widget child,
  })  : assert(bundle != null),
        assert(child != null),
        super(key: key, child: child);

  final AssetBundle bundle;

  static AssetBundle of(BuildContext context) {
    final DefaultAssetBundle result =
        context.inheritFromWidgetOfExactType(DefaultAssetBundle);
    return result?.bundle ?? rootBundle;
  }

  @override
  bool updateShouldNotify(DefaultAssetBundle oldWidget) =>
      bundle != oldWidget.bundle;
}

class WidgetToRenderBoxAdapter extends LeafRenderObjectWidget {
  WidgetToRenderBoxAdapter({
    @required this.renderBox,
    this.onBuild,
  })  : assert(renderBox != null),
        super(key: GlobalObjectKey(renderBox));

  final RenderBox renderBox;

  final VoidCallback onBuild;

  @override
  RenderBox createRenderObject(BuildContext context) => renderBox;

  @override
  void updateRenderObject(BuildContext context, RenderBox renderObject) {
    if (onBuild != null) onBuild();
  }
}

class Listener extends StatelessWidget {
  const Listener({
    Key key,
    this.onPointerDown,
    this.onPointerMove,
    @Deprecated('Use MouseRegion.onEnter instead') this.onPointerEnter,
    @Deprecated('Use MouseRegion.onExit instead') this.onPointerExit,
    @Deprecated('Use MouseRegion.onHover instead') this.onPointerHover,
    this.onPointerUp,
    this.onPointerCancel,
    this.onPointerSignal,
    this.behavior = HitTestBehavior.deferToChild,
    Widget child,
  })  : assert(behavior != null),
        _child = child,
        super(key: key);

  final PointerDownEventListener onPointerDown;

  final PointerMoveEventListener onPointerMove;

  final PointerEnterEventListener onPointerEnter;

  final PointerHoverEventListener onPointerHover;

  final PointerExitEventListener onPointerExit;

  final PointerUpEventListener onPointerUp;

  final PointerCancelEventListener onPointerCancel;

  final PointerSignalEventListener onPointerSignal;

  final HitTestBehavior behavior;

  final Widget _child;

  @override
  Widget build(BuildContext context) {
    Widget result = _child;
    if (onPointerEnter != null ||
        onPointerExit != null ||
        onPointerHover != null) {
      result = MouseRegion(
        onEnter: onPointerEnter,
        onExit: onPointerExit,
        onHover: onPointerHover,
        child: result,
      );
    }
    result = _PointerListener(
      onPointerDown: onPointerDown,
      onPointerUp: onPointerUp,
      onPointerMove: onPointerMove,
      onPointerCancel: onPointerCancel,
      onPointerSignal: onPointerSignal,
      behavior: behavior,
      child: result,
    );
    return result;
  }
}

class _PointerListener extends SingleChildRenderObjectWidget {
  const _PointerListener({
    Key key,
    this.onPointerDown,
    this.onPointerMove,
    this.onPointerUp,
    this.onPointerCancel,
    this.onPointerSignal,
    this.behavior = HitTestBehavior.deferToChild,
    Widget child,
  })  : assert(behavior != null),
        super(key: key, child: child);

  final PointerDownEventListener onPointerDown;
  final PointerMoveEventListener onPointerMove;
  final PointerUpEventListener onPointerUp;
  final PointerCancelEventListener onPointerCancel;
  final PointerSignalEventListener onPointerSignal;
  final HitTestBehavior behavior;

  @override
  RenderPointerListener createRenderObject(BuildContext context) {
    return RenderPointerListener(
      onPointerDown: onPointerDown,
      onPointerMove: onPointerMove,
      onPointerUp: onPointerUp,
      onPointerCancel: onPointerCancel,
      onPointerSignal: onPointerSignal,
      behavior: behavior,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderPointerListener renderObject) {
    renderObject
      ..onPointerDown = onPointerDown
      ..onPointerMove = onPointerMove
      ..onPointerUp = onPointerUp
      ..onPointerCancel = onPointerCancel
      ..onPointerSignal = onPointerSignal
      ..behavior = behavior;
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
    properties.add(
        IterableProperty<String>('listeners', listeners, ifEmpty: '<none>'));
    properties.add(EnumProperty<HitTestBehavior>('behavior', behavior));
  }
}

class MouseRegion extends SingleChildRenderObjectWidget {
  const MouseRegion({
    Key key,
    this.onEnter,
    this.onExit,
    this.onHover,
    Widget child,
  }) : super(key: key, child: child);

  final PointerEnterEventListener onEnter;

  final PointerHoverEventListener onHover;

  final PointerExitEventListener onExit;

  @override
  _ListenerElement createElement() => _ListenerElement(this);

  @override
  RenderMouseRegion createRenderObject(BuildContext context) {
    return RenderMouseRegion(
      onEnter: onEnter,
      onHover: onHover,
      onExit: onExit,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderMouseRegion renderObject) {
    renderObject
      ..onEnter = onEnter
      ..onHover = onHover
      ..onExit = onExit;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    final List<String> listeners = <String>[];
    if (onEnter != null) listeners.add('enter');
    if (onExit != null) listeners.add('exit');
    if (onHover != null) listeners.add('hover');
    properties.add(
        IterableProperty<String>('listeners', listeners, ifEmpty: '<none>'));
  }
}

class _ListenerElement extends SingleChildRenderObjectElement {
  _ListenerElement(SingleChildRenderObjectWidget widget) : super(widget);

  @override
  void activate() {
    super.activate();
    final RenderMouseRegion renderMouseListener = renderObject;
    renderMouseListener.postActivate();
  }

  @override
  void deactivate() {
    final RenderMouseRegion renderMouseListener = renderObject;
    renderMouseListener.preDeactivate();
    super.deactivate();
  }
}

class RepaintBoundary extends SingleChildRenderObjectWidget {
  const RepaintBoundary({Key key, Widget child})
      : super(key: key, child: child);

  factory RepaintBoundary.wrap(Widget child, int childIndex) {
    assert(child != null);
    final Key key = child.key != null
        ? ValueKey<Key>(child.key)
        : ValueKey<int>(childIndex);
    return RepaintBoundary(key: key, child: child);
  }

  static List<RepaintBoundary> wrapAll(List<Widget> widgets) {
    final List<RepaintBoundary> result = List<RepaintBoundary>(widgets.length);
    for (int i = 0; i < result.length; ++i)
      result[i] = RepaintBoundary.wrap(widgets[i], i);
    return result;
  }

  @override
  RenderRepaintBoundary createRenderObject(BuildContext context) =>
      RenderRepaintBoundary();
}

class IgnorePointer extends SingleChildRenderObjectWidget {
  const IgnorePointer({
    Key key,
    this.ignoring = true,
    this.ignoringSemantics,
    Widget child,
  })  : assert(ignoring != null),
        super(key: key, child: child);

  final bool ignoring;

  final bool ignoringSemantics;

  @override
  RenderIgnorePointer createRenderObject(BuildContext context) {
    return RenderIgnorePointer(
      ignoring: ignoring,
      ignoringSemantics: ignoringSemantics,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderIgnorePointer renderObject) {
    renderObject
      ..ignoring = ignoring
      ..ignoringSemantics = ignoringSemantics;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('ignoring', ignoring));
    properties.add(DiagnosticsProperty<bool>(
        'ignoringSemantics', ignoringSemantics,
        defaultValue: null));
  }
}

class AbsorbPointer extends SingleChildRenderObjectWidget {
  const AbsorbPointer({
    Key key,
    this.absorbing = true,
    Widget child,
    this.ignoringSemantics,
  })  : assert(absorbing != null),
        super(key: key, child: child);

  final bool absorbing;

  final bool ignoringSemantics;

  @override
  RenderAbsorbPointer createRenderObject(BuildContext context) {
    return RenderAbsorbPointer(
      absorbing: absorbing,
      ignoringSemantics: ignoringSemantics,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderAbsorbPointer renderObject) {
    renderObject
      ..absorbing = absorbing
      ..ignoringSemantics = ignoringSemantics;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('absorbing', absorbing));
    properties.add(DiagnosticsProperty<bool>(
        'ignoringSemantics', ignoringSemantics,
        defaultValue: null));
  }
}

class MetaData extends SingleChildRenderObjectWidget {
  const MetaData({
    Key key,
    this.metaData,
    this.behavior = HitTestBehavior.deferToChild,
    Widget child,
  }) : super(key: key, child: child);

  final dynamic metaData;

  final HitTestBehavior behavior;

  @override
  RenderMetaData createRenderObject(BuildContext context) {
    return RenderMetaData(
      metaData: metaData,
      behavior: behavior,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderMetaData renderObject) {
    renderObject
      ..metaData = metaData
      ..behavior = behavior;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<HitTestBehavior>('behavior', behavior));
    properties.add(DiagnosticsProperty<dynamic>('metaData', metaData));
  }
}

@immutable
class Semantics extends SingleChildRenderObjectWidget {
  Semantics({
    Key key,
    Widget child,
    bool container = false,
    bool explicitChildNodes = false,
    bool excludeSemantics = false,
    bool enabled,
    bool checked,
    bool selected,
    bool toggled,
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
    String onTapHint,
    String onLongPressHint,
    TextDirection textDirection,
    SemanticsSortKey sortKey,
    VoidCallback onTap,
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
    VoidCallback onDismiss,
    MoveCursorHandler onMoveCursorForwardByCharacter,
    MoveCursorHandler onMoveCursorBackwardByCharacter,
    SetSelectionHandler onSetSelection,
    VoidCallback onDidGainAccessibilityFocus,
    VoidCallback onDidLoseAccessibilityFocus,
    Map<CustomSemanticsAction, VoidCallback> customSemanticsActions,
  }) : this.fromProperties(
          key: key,
          child: child,
          container: container,
          explicitChildNodes: explicitChildNodes,
          excludeSemantics: excludeSemantics,
          properties: SemanticsProperties(
            enabled: enabled,
            checked: checked,
            toggled: toggled,
            selected: selected,
            button: button,
            header: header,
            textField: textField,
            readOnly: readOnly,
            focused: focused,
            inMutuallyExclusiveGroup: inMutuallyExclusiveGroup,
            obscured: obscured,
            multiline: multiline,
            scopesRoute: scopesRoute,
            namesRoute: namesRoute,
            hidden: hidden,
            image: image,
            liveRegion: liveRegion,
            label: label,
            value: value,
            increasedValue: increasedValue,
            decreasedValue: decreasedValue,
            hint: hint,
            textDirection: textDirection,
            sortKey: sortKey,
            onTap: onTap,
            onLongPress: onLongPress,
            onScrollLeft: onScrollLeft,
            onScrollRight: onScrollRight,
            onScrollUp: onScrollUp,
            onScrollDown: onScrollDown,
            onIncrease: onIncrease,
            onDecrease: onDecrease,
            onCopy: onCopy,
            onCut: onCut,
            onPaste: onPaste,
            onMoveCursorForwardByCharacter: onMoveCursorForwardByCharacter,
            onMoveCursorBackwardByCharacter: onMoveCursorBackwardByCharacter,
            onDidGainAccessibilityFocus: onDidGainAccessibilityFocus,
            onDidLoseAccessibilityFocus: onDidLoseAccessibilityFocus,
            onDismiss: onDismiss,
            onSetSelection: onSetSelection,
            customSemanticsActions: customSemanticsActions,
            hintOverrides: onTapHint != null || onLongPressHint != null
                ? SemanticsHintOverrides(
                    onTapHint: onTapHint,
                    onLongPressHint: onLongPressHint,
                  )
                : null,
          ),
        );

  const Semantics.fromProperties({
    Key key,
    Widget child,
    this.container = false,
    this.explicitChildNodes = false,
    this.excludeSemantics = false,
    @required this.properties,
  })  : assert(container != null),
        assert(properties != null),
        super(key: key, child: child);

  final SemanticsProperties properties;

  final bool container;

  final bool explicitChildNodes;

  final bool excludeSemantics;

  @override
  RenderSemanticsAnnotations createRenderObject(BuildContext context) {
    return RenderSemanticsAnnotations(
      container: container,
      explicitChildNodes: explicitChildNodes,
      excludeSemantics: excludeSemantics,
      enabled: properties.enabled,
      checked: properties.checked,
      toggled: properties.toggled,
      selected: properties.selected,
      button: properties.button,
      header: properties.header,
      textField: properties.textField,
      readOnly: properties.readOnly,
      focused: properties.focused,
      liveRegion: properties.liveRegion,
      inMutuallyExclusiveGroup: properties.inMutuallyExclusiveGroup,
      obscured: properties.obscured,
      multiline: properties.multiline,
      scopesRoute: properties.scopesRoute,
      namesRoute: properties.namesRoute,
      hidden: properties.hidden,
      image: properties.image,
      label: properties.label,
      value: properties.value,
      increasedValue: properties.increasedValue,
      decreasedValue: properties.decreasedValue,
      hint: properties.hint,
      hintOverrides: properties.hintOverrides,
      textDirection: _getTextDirection(context),
      sortKey: properties.sortKey,
      onTap: properties.onTap,
      onLongPress: properties.onLongPress,
      onScrollLeft: properties.onScrollLeft,
      onScrollRight: properties.onScrollRight,
      onScrollUp: properties.onScrollUp,
      onScrollDown: properties.onScrollDown,
      onIncrease: properties.onIncrease,
      onDecrease: properties.onDecrease,
      onCopy: properties.onCopy,
      onDismiss: properties.onDismiss,
      onCut: properties.onCut,
      onPaste: properties.onPaste,
      onMoveCursorForwardByCharacter: properties.onMoveCursorForwardByCharacter,
      onMoveCursorBackwardByCharacter:
          properties.onMoveCursorBackwardByCharacter,
      onMoveCursorForwardByWord: properties.onMoveCursorForwardByWord,
      onMoveCursorBackwardByWord: properties.onMoveCursorBackwardByWord,
      onSetSelection: properties.onSetSelection,
      onDidGainAccessibilityFocus: properties.onDidGainAccessibilityFocus,
      onDidLoseAccessibilityFocus: properties.onDidLoseAccessibilityFocus,
      customSemanticsActions: properties.customSemanticsActions,
    );
  }

  TextDirection _getTextDirection(BuildContext context) {
    if (properties.textDirection != null) return properties.textDirection;

    final bool containsText = properties.label != null ||
        properties.value != null ||
        properties.hint != null;

    if (!containsText) return null;

    return Directionality.of(context);
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderSemanticsAnnotations renderObject) {
    renderObject
      ..container = container
      ..explicitChildNodes = explicitChildNodes
      ..excludeSemantics = excludeSemantics
      ..scopesRoute = properties.scopesRoute
      ..enabled = properties.enabled
      ..checked = properties.checked
      ..toggled = properties.toggled
      ..selected = properties.selected
      ..button = properties.button
      ..header = properties.header
      ..textField = properties.textField
      ..readOnly = properties.readOnly
      ..focused = properties.focused
      ..inMutuallyExclusiveGroup = properties.inMutuallyExclusiveGroup
      ..obscured = properties.obscured
      ..multiline = properties.multiline
      ..hidden = properties.hidden
      ..image = properties.image
      ..liveRegion = properties.liveRegion
      ..label = properties.label
      ..value = properties.value
      ..increasedValue = properties.increasedValue
      ..decreasedValue = properties.decreasedValue
      ..hint = properties.hint
      ..hintOverrides = properties.hintOverrides
      ..namesRoute = properties.namesRoute
      ..textDirection = _getTextDirection(context)
      ..sortKey = properties.sortKey
      ..onTap = properties.onTap
      ..onLongPress = properties.onLongPress
      ..onScrollLeft = properties.onScrollLeft
      ..onScrollRight = properties.onScrollRight
      ..onScrollUp = properties.onScrollUp
      ..onScrollDown = properties.onScrollDown
      ..onIncrease = properties.onIncrease
      ..onDismiss = properties.onDismiss
      ..onDecrease = properties.onDecrease
      ..onCopy = properties.onCopy
      ..onCut = properties.onCut
      ..onPaste = properties.onPaste
      ..onMoveCursorForwardByCharacter =
          properties.onMoveCursorForwardByCharacter
      ..onMoveCursorBackwardByCharacter =
          properties.onMoveCursorForwardByCharacter
      ..onMoveCursorForwardByWord = properties.onMoveCursorForwardByWord
      ..onMoveCursorBackwardByWord = properties.onMoveCursorBackwardByWord
      ..onSetSelection = properties.onSetSelection
      ..onDidGainAccessibilityFocus = properties.onDidGainAccessibilityFocus
      ..onDidLoseAccessibilityFocus = properties.onDidLoseAccessibilityFocus
      ..customSemanticsActions = properties.customSemanticsActions;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('container', container));
    properties.add(DiagnosticsProperty<SemanticsProperties>(
        'properties', this.properties));
    this.properties.debugFillProperties(properties);
  }
}

class MergeSemantics extends SingleChildRenderObjectWidget {
  const MergeSemantics({Key key, Widget child}) : super(key: key, child: child);

  @override
  RenderMergeSemantics createRenderObject(BuildContext context) =>
      RenderMergeSemantics();
}

class BlockSemantics extends SingleChildRenderObjectWidget {
  const BlockSemantics({Key key, this.blocking = true, Widget child})
      : super(key: key, child: child);

  final bool blocking;

  @override
  RenderBlockSemantics createRenderObject(BuildContext context) =>
      RenderBlockSemantics(blocking: blocking);

  @override
  void updateRenderObject(
      BuildContext context, RenderBlockSemantics renderObject) {
    renderObject.blocking = blocking;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('blocking', blocking));
  }
}

class ExcludeSemantics extends SingleChildRenderObjectWidget {
  const ExcludeSemantics({
    Key key,
    this.excluding = true,
    Widget child,
  })  : assert(excluding != null),
        super(key: key, child: child);

  final bool excluding;

  @override
  RenderExcludeSemantics createRenderObject(BuildContext context) =>
      RenderExcludeSemantics(excluding: excluding);

  @override
  void updateRenderObject(
      BuildContext context, RenderExcludeSemantics renderObject) {
    renderObject.excluding = excluding;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('excluding', excluding));
  }
}

class IndexedSemantics extends SingleChildRenderObjectWidget {
  const IndexedSemantics({
    Key key,
    @required this.index,
    Widget child,
  })  : assert(index != null),
        super(key: key, child: child);

  final int index;

  @override
  RenderIndexedSemantics createRenderObject(BuildContext context) =>
      RenderIndexedSemantics(index: index);

  @override
  void updateRenderObject(
      BuildContext context, RenderIndexedSemantics renderObject) {
    renderObject.index = index;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<int>('index', index));
  }
}

class KeyedSubtree extends StatelessWidget {
  const KeyedSubtree({
    Key key,
    @required this.child,
  })  : assert(child != null),
        super(key: key);

  factory KeyedSubtree.wrap(Widget child, int childIndex) {
    final Key key = child.key != null
        ? ValueKey<Key>(child.key)
        : ValueKey<int>(childIndex);
    return KeyedSubtree(key: key, child: child);
  }

  final Widget child;

  static List<Widget> ensureUniqueKeysForList(Iterable<Widget> items,
      {int baseIndex = 0}) {
    if (items == null || items.isEmpty) return items;

    final List<Widget> itemsWithUniqueKeys = <Widget>[];
    int itemIndex = baseIndex;
    for (Widget item in items) {
      itemsWithUniqueKeys.add(KeyedSubtree.wrap(item, itemIndex));
      itemIndex += 1;
    }

    assert(!debugItemsHaveDuplicateKeys(itemsWithUniqueKeys));
    return itemsWithUniqueKeys;
  }

  @override
  Widget build(BuildContext context) => child;
}

class Builder extends StatelessWidget {
  const Builder({
    Key key,
    @required this.builder,
  })  : assert(builder != null),
        super(key: key);

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) => builder(context);
}

typedef StatefulWidgetBuilder = Widget Function(
    BuildContext context, StateSetter setState);

class StatefulBuilder extends StatefulWidget {
  const StatefulBuilder({
    Key key,
    @required this.builder,
  })  : assert(builder != null),
        super(key: key);

  final StatefulWidgetBuilder builder;

  @override
  _StatefulBuilderState createState() => _StatefulBuilderState();
}

class _StatefulBuilderState extends State<StatefulBuilder> {
  @override
  Widget build(BuildContext context) => widget.builder(context, setState);
}

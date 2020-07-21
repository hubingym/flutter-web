import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/rendering.dart';
import 'package:flutter_web/widgets.dart';
import 'package:flutter_web/ui.dart' show Clip;

import 'constants.dart';
import 'theme.dart';

typedef RectCallback = Rect Function();

enum MaterialType {
  canvas,

  card,

  circle,

  button,

  transparency
}

final Map<MaterialType, BorderRadius> kMaterialEdges =
    <MaterialType, BorderRadius>{
  MaterialType.canvas: null,
  MaterialType.card: BorderRadius.circular(2.0),
  MaterialType.circle: null,
  MaterialType.button: BorderRadius.circular(2.0),
  MaterialType.transparency: null,
};

abstract class MaterialInkController {
  Color get color;

  TickerProvider get vsync;

  void addInkFeature(InkFeature feature);

  void markNeedsPaint();
}

class Material extends StatefulWidget {
  const Material({
    Key key,
    this.type = MaterialType.canvas,
    this.elevation = 0.0,
    this.color,
    this.shadowColor = const Color(0xFF000000),
    this.textStyle,
    this.borderRadius,
    this.shape,
    this.borderOnForeground = true,
    this.clipBehavior = Clip.none,
    this.animationDuration = kThemeChangeDuration,
    this.child,
  })  : assert(type != null),
        assert(elevation != null && elevation >= 0.0),
        assert(shadowColor != null),
        assert(!(shape != null && borderRadius != null)),
        assert(animationDuration != null),
        assert(!(identical(type, MaterialType.circle) &&
            (borderRadius != null || shape != null))),
        assert(clipBehavior != null),
        assert(borderOnForeground != null),
        super(key: key);

  final Widget child;

  final MaterialType type;

  final double elevation;

  final Color color;

  final Color shadowColor;

  final TextStyle textStyle;

  final ShapeBorder shape;

  final bool borderOnForeground;

  final Clip clipBehavior;

  final Duration animationDuration;

  final BorderRadiusGeometry borderRadius;

  static MaterialInkController of(BuildContext context) {
    final _RenderInkFeatures result = context
        .ancestorRenderObjectOfType(const TypeMatcher<_RenderInkFeatures>());
    return result;
  }

  @override
  _MaterialState createState() => _MaterialState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<MaterialType>('type', type));
    properties.add(DoubleProperty('elevation', elevation, defaultValue: 0.0));
    properties
        .add(DiagnosticsProperty<Color>('color', color, defaultValue: null));
    properties.add(DiagnosticsProperty<Color>('shadowColor', shadowColor,
        defaultValue: const Color(0xFF000000)));
    textStyle?.debugFillProperties(properties, prefix: 'textStyle.');
    properties.add(
        DiagnosticsProperty<ShapeBorder>('shape', shape, defaultValue: null));
    properties.add(DiagnosticsProperty<bool>(
        'borderOnForeground', borderOnForeground,
        defaultValue: true));
    properties.add(DiagnosticsProperty<BorderRadiusGeometry>(
        'borderRadius', borderRadius,
        defaultValue: null));
  }

  static const double defaultSplashRadius = 35.0;
}

class _MaterialState extends State<Material> with TickerProviderStateMixin {
  final GlobalKey _inkFeatureRenderer = GlobalKey(debugLabel: 'ink renderer');

  Color _getBackgroundColor(BuildContext context) {
    if (widget.color != null) return widget.color;
    switch (widget.type) {
      case MaterialType.canvas:
        return Theme.of(context).canvasColor;
      case MaterialType.card:
        return Theme.of(context).cardColor;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = _getBackgroundColor(context);
    assert(
        backgroundColor != null || widget.type == MaterialType.transparency,
        'If Material type is not MaterialType.transparency, a color must '
        'either be passed in through the `color` property, or be defined '
        'in the theme (ex. canvasColor != null if type is set to '
        'MaterialType.canvas)');
    Widget contents = widget.child;
    if (contents != null) {
      contents = AnimatedDefaultTextStyle(
        style: widget.textStyle ?? Theme.of(context).textTheme.body1,
        duration: widget.animationDuration,
        child: contents,
      );
    }
    contents = NotificationListener<LayoutChangedNotification>(
      onNotification: (LayoutChangedNotification notification) {
        final _RenderInkFeatures renderer =
            _inkFeatureRenderer.currentContext.findRenderObject();
        renderer._didChangeLayout();
        return false;
      },
      child: _InkFeatures(
        key: _inkFeatureRenderer,
        color: backgroundColor,
        child: contents,
        vsync: this,
      ),
    );

    if (widget.type == MaterialType.canvas &&
        widget.shape == null &&
        widget.borderRadius == null) {
      return AnimatedPhysicalModel(
        curve: Curves.fastOutSlowIn,
        duration: widget.animationDuration,
        shape: BoxShape.rectangle,
        clipBehavior: widget.clipBehavior,
        borderRadius: BorderRadius.zero,
        elevation: widget.elevation,
        color: backgroundColor,
        shadowColor: widget.shadowColor,
        animateColor: false,
        child: contents,
      );
    }

    final ShapeBorder shape = _getShape();

    if (widget.type == MaterialType.transparency) {
      return _transparentInterior(
        context: context,
        shape: shape,
        clipBehavior: widget.clipBehavior,
        contents: contents,
      );
    }

    return _MaterialInterior(
      curve: Curves.fastOutSlowIn,
      duration: widget.animationDuration,
      shape: shape,
      borderOnForeground: widget.borderOnForeground,
      clipBehavior: widget.clipBehavior,
      elevation: widget.elevation,
      color: backgroundColor,
      shadowColor: widget.shadowColor,
      child: contents,
    );
  }

  static Widget _transparentInterior({
    @required BuildContext context,
    @required ShapeBorder shape,
    @required Clip clipBehavior,
    @required Widget contents,
  }) {
    final _ShapeBorderPaint child = _ShapeBorderPaint(
      child: contents,
      shape: shape,
    );
    if (clipBehavior == Clip.none) {
      return child;
    }
    return ClipPath(
      child: child,
      clipper: ShapeBorderClipper(
        shape: shape,
        textDirection: Directionality.of(context),
      ),
      clipBehavior: clipBehavior,
    );
  }

  ShapeBorder _getShape() {
    if (widget.shape != null) return widget.shape;
    if (widget.borderRadius != null)
      return RoundedRectangleBorder(borderRadius: widget.borderRadius);
    switch (widget.type) {
      case MaterialType.canvas:
      case MaterialType.transparency:
        return const RoundedRectangleBorder();

      case MaterialType.card:
      case MaterialType.button:
        return RoundedRectangleBorder(
          borderRadius: widget.borderRadius ?? kMaterialEdges[widget.type],
        );

      case MaterialType.circle:
        return const CircleBorder();
    }
    return const RoundedRectangleBorder();
  }
}

class _RenderInkFeatures extends RenderProxyBox
    implements MaterialInkController {
  _RenderInkFeatures({
    RenderBox child,
    @required this.vsync,
    this.color,
  })  : assert(vsync != null),
        super(child);

  @override
  final TickerProvider vsync;

  @override
  Color color;

  List<InkFeature> _inkFeatures;

  @override
  void addInkFeature(InkFeature feature) {
    assert(!feature._debugDisposed);
    assert(feature._controller == this);
    _inkFeatures ??= <InkFeature>[];
    assert(!_inkFeatures.contains(feature));
    _inkFeatures.add(feature);
    markNeedsPaint();
  }

  void _removeFeature(InkFeature feature) {
    assert(_inkFeatures != null);
    _inkFeatures.remove(feature);
    markNeedsPaint();
  }

  void _didChangeLayout() {
    if (_inkFeatures != null && _inkFeatures.isNotEmpty) markNeedsPaint();
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_inkFeatures != null && _inkFeatures.isNotEmpty) {
      final Canvas canvas = context.canvas;
      canvas.save();
      canvas.translate(offset.dx, offset.dy);
      canvas.clipRect(Offset.zero & size);
      for (InkFeature inkFeature in _inkFeatures) inkFeature._paint(canvas);
      canvas.restore();
    }
    super.paint(context, offset);
  }
}

class _InkFeatures extends SingleChildRenderObjectWidget {
  const _InkFeatures({
    Key key,
    this.color,
    @required this.vsync,
    Widget child,
  }) : super(key: key, child: child);

  final Color color;

  final TickerProvider vsync;

  @override
  _RenderInkFeatures createRenderObject(BuildContext context) {
    return _RenderInkFeatures(
      color: color,
      vsync: vsync,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, _RenderInkFeatures renderObject) {
    renderObject.color = color;
    assert(vsync == renderObject.vsync);
  }
}

abstract class InkFeature {
  InkFeature({
    @required MaterialInkController controller,
    @required this.referenceBox,
    this.onRemoved,
  })  : assert(controller != null),
        assert(referenceBox != null),
        _controller = controller;

  MaterialInkController get controller => _controller;
  _RenderInkFeatures _controller;

  final RenderBox referenceBox;

  final VoidCallback onRemoved;

  bool _debugDisposed = false;

  @mustCallSuper
  void dispose() {
    assert(!_debugDisposed);
    assert(() {
      _debugDisposed = true;
      return true;
    }());
    _controller._removeFeature(this);
    if (onRemoved != null) onRemoved();
  }

  void _paint(Canvas canvas) {
    assert(referenceBox.attached);
    assert(!_debugDisposed);

    final List<RenderObject> descendants = <RenderObject>[referenceBox];
    RenderObject node = referenceBox;
    while (node != _controller) {
      node = node.parent;
      assert(node != null);
      descendants.add(node);
    }

    final Matrix4 transform = Matrix4.identity();
    assert(descendants.length >= 2);
    for (int index = descendants.length - 1; index > 0; index -= 1)
      descendants[index].applyPaintTransform(descendants[index - 1], transform);
    paintFeature(canvas, transform);
  }

  @protected
  void paintFeature(Canvas canvas, Matrix4 transform);

  @override
  String toString() => describeIdentity(this);
}

class ShapeBorderTween extends Tween<ShapeBorder> {
  ShapeBorderTween({ShapeBorder begin, ShapeBorder end})
      : super(begin: begin, end: end);

  @override
  ShapeBorder lerp(double t) {
    return ShapeBorder.lerp(begin, end, t);
  }
}

class _MaterialInterior extends ImplicitlyAnimatedWidget {
  const _MaterialInterior({
    Key key,
    @required this.child,
    @required this.shape,
    this.borderOnForeground = true,
    this.clipBehavior = Clip.none,
    @required this.elevation,
    @required this.color,
    @required this.shadowColor,
    Curve curve = Curves.linear,
    @required Duration duration,
  })  : assert(child != null),
        assert(shape != null),
        assert(clipBehavior != null),
        assert(elevation != null && elevation >= 0.0),
        assert(color != null),
        assert(shadowColor != null),
        super(key: key, curve: curve, duration: duration);

  final Widget child;

  final ShapeBorder shape;

  final bool borderOnForeground;

  final Clip clipBehavior;

  final double elevation;

  final Color color;

  final Color shadowColor;

  @override
  _MaterialInteriorState createState() => _MaterialInteriorState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(DiagnosticsProperty<ShapeBorder>('shape', shape));
    description.add(DoubleProperty('elevation', elevation));
    description.add(DiagnosticsProperty<Color>('color', color));
    description.add(DiagnosticsProperty<Color>('shadowColor', shadowColor));
  }
}

class _MaterialInteriorState
    extends AnimatedWidgetBaseState<_MaterialInterior> {
  Tween<double> _elevation;
  ColorTween _shadowColor;
  ShapeBorderTween _border;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _elevation = visitor(_elevation, widget.elevation,
        (dynamic value) => Tween<double>(begin: value));
    _shadowColor = visitor(_shadowColor, widget.shadowColor,
        (dynamic value) => ColorTween(begin: value));
    _border = visitor(_border, widget.shape,
        (dynamic value) => ShapeBorderTween(begin: value));
  }

  @override
  Widget build(BuildContext context) {
    final ShapeBorder shape = _border.evaluate(animation);
    return PhysicalShape(
      child: _ShapeBorderPaint(
        child: widget.child,
        shape: shape,
        borderOnForeground: widget.borderOnForeground,
      ),
      clipper: ShapeBorderClipper(
        shape: shape,
        textDirection: Directionality.of(context),
      ),
      clipBehavior: widget.clipBehavior,
      elevation: _elevation.evaluate(animation),
      color: widget.color,
      shadowColor: _shadowColor.evaluate(animation),
    );
  }
}

class _ShapeBorderPaint extends StatelessWidget {
  const _ShapeBorderPaint({
    @required this.child,
    @required this.shape,
    this.borderOnForeground = true,
  });

  final Widget child;
  final ShapeBorder shape;
  final bool borderOnForeground;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      child: child,
      painter: borderOnForeground
          ? null
          : _ShapeBorderPainter(shape, Directionality.of(context)),
      foregroundPainter: borderOnForeground
          ? _ShapeBorderPainter(shape, Directionality.of(context))
          : null,
    );
  }
}

class _ShapeBorderPainter extends CustomPainter {
  _ShapeBorderPainter(this.border, this.textDirection);
  final ShapeBorder border;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    border.paint(canvas, Offset.zero & size, textDirection: textDirection);
  }

  @override
  bool shouldRepaint(_ShapeBorderPainter oldDelegate) {
    return oldDelegate.border != border;
  }
}

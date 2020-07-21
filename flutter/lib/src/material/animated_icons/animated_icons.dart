part of material_animated_icons;

class AnimatedIcon extends StatelessWidget {
  const AnimatedIcon({
    Key key,
    @required this.icon,
    @required this.progress,
    this.color,
    this.size,
    this.semanticLabel,
    this.textDirection,
  })  : assert(progress != null),
        assert(icon != null),
        super(key: key);

  final Animation<double> progress;

  final Color color;

  final double size;

  final AnimatedIconData icon;

  final String semanticLabel;

  final TextDirection textDirection;

  static final _UiPathFactory _pathFactory = () => ui.Path();

  @override
  Widget build(BuildContext context) {
    final _AnimatedIconData iconData = icon;
    final IconThemeData iconTheme = IconTheme.of(context);
    final double iconSize = size ?? iconTheme.size;
    final TextDirection textDirection =
        this.textDirection ?? Directionality.of(context);
    final double iconOpacity = iconTheme.opacity;
    Color iconColor = color ?? iconTheme.color;
    if (iconOpacity != 1.0)
      iconColor = iconColor.withOpacity(iconColor.opacity * iconOpacity);
    return Semantics(
      label: semanticLabel,
      child: CustomPaint(
        size: Size(iconSize, iconSize),
        painter: _AnimatedIconPainter(
          paths: iconData.paths,
          progress: progress,
          color: iconColor,
          scale: iconSize / iconData.size.width,
          shouldMirror:
              textDirection == TextDirection.rtl && iconData.matchTextDirection,
          uiPathFactory: _pathFactory,
        ),
      ),
    );
  }
}

typedef _UiPathFactory = ui.Path Function();

class _AnimatedIconPainter extends CustomPainter {
  _AnimatedIconPainter({
    @required this.paths,
    @required this.progress,
    @required this.color,
    @required this.scale,
    @required this.shouldMirror,
    @required this.uiPathFactory,
  }) : super(repaint: progress);

  final List<_PathFrames> paths;
  final Animation<double> progress;
  final Color color;
  final double scale;

  final bool shouldMirror;
  final _UiPathFactory uiPathFactory;

  @override
  void paint(ui.Canvas canvas, Size size) {
    canvas.scale(scale, scale);
    if (shouldMirror) {
      canvas.rotate(math.pi);
      canvas.translate(-size.width, -size.height);
    }

    final double clampedProgress = progress.value.clamp(0.0, 1.0);
    for (_PathFrames path in paths)
      path.paint(canvas, color, uiPathFactory, clampedProgress);
  }

  @override
  bool shouldRepaint(_AnimatedIconPainter oldDelegate) {
    return oldDelegate.progress.value != progress.value ||
        oldDelegate.color != color ||
        oldDelegate.paths != paths ||
        oldDelegate.scale != scale ||
        oldDelegate.uiPathFactory != uiPathFactory;
  }

  @override
  bool hitTest(Offset position) => null;

  @override
  bool shouldRebuildSemantics(CustomPainter oldDelegate) => false;

  @override
  SemanticsBuilderCallback get semanticsBuilder => null;
}

class _PathFrames {
  const _PathFrames({@required this.commands, @required this.opacities});

  final List<_PathCommand> commands;
  final List<double> opacities;

  void paint(ui.Canvas canvas, Color color, _UiPathFactory uiPathFactory,
      double progress) {
    final double opacity =
        _interpolate<double>(opacities, progress, lerpDouble);
    final ui.Paint paint = ui.Paint()
      ..style = PaintingStyle.fill
      ..color = color.withOpacity(color.opacity * opacity);
    final ui.Path path = uiPathFactory();
    for (_PathCommand command in commands) command.apply(path, progress);
    canvas.drawPath(path, paint);
  }
}

abstract class _PathCommand {
  const _PathCommand();

  void apply(ui.Path path, double progress);
}

class _PathMoveTo extends _PathCommand {
  const _PathMoveTo(this.points);

  final List<Offset> points;

  @override
  void apply(Path path, double progress) {
    final Offset offset = _interpolate<Offset>(points, progress, Offset.lerp);
    path.moveTo(offset.dx, offset.dy);
  }
}

class _PathCubicTo extends _PathCommand {
  const _PathCubicTo(
      this.controlPoints1, this.controlPoints2, this.targetPoints);

  final List<Offset> controlPoints2;
  final List<Offset> controlPoints1;
  final List<Offset> targetPoints;

  @override
  void apply(Path path, double progress) {
    final Offset controlPoint1 =
        _interpolate<Offset>(controlPoints1, progress, Offset.lerp);
    final Offset controlPoint2 =
        _interpolate<Offset>(controlPoints2, progress, Offset.lerp);
    final Offset targetPoint =
        _interpolate<Offset>(targetPoints, progress, Offset.lerp);
    path.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx,
        controlPoint2.dy, targetPoint.dx, targetPoint.dy);
  }
}

class _PathLineTo extends _PathCommand {
  const _PathLineTo(this.points);

  final List<Offset> points;

  @override
  void apply(Path path, double progress) {
    final Offset point = _interpolate<Offset>(points, progress, Offset.lerp);
    path.lineTo(point.dx, point.dy);
  }
}

class _PathClose extends _PathCommand {
  const _PathClose();

  @override
  void apply(Path path, double progress) {
    path.close();
  }
}

T _interpolate<T>(
    List<T> values, double progress, _Interpolator<T> interpolator) {
  assert(progress <= 1.0);
  assert(progress >= 0.0);
  if (values.length == 1) return values[0];
  final double targetIdx = lerpDouble(0, values.length - 1, progress);
  final int lowIdx = targetIdx.floor();
  final int highIdx = targetIdx.ceil();
  final double t = targetIdx - lowIdx;
  return interpolator(values[lowIdx], values[highIdx], t);
}

typedef _Interpolator<T> = T Function(T a, T b, double progress);

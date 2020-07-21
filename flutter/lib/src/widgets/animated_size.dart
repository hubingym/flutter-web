import 'package:flutter_web/rendering.dart';
import 'package:flutter_web/scheduler.dart';

import 'basic.dart';
import 'framework.dart';

class AnimatedSize extends SingleChildRenderObjectWidget {
  const AnimatedSize({
    Key key,
    Widget child,
    this.alignment = Alignment.center,
    this.curve = Curves.linear,
    @required this.duration,
    this.reverseDuration,
    @required this.vsync,
  }) : super(key: key, child: child);

  final AlignmentGeometry alignment;

  final Curve curve;

  final Duration duration;

  final Duration reverseDuration;

  final TickerProvider vsync;

  @override
  RenderAnimatedSize createRenderObject(BuildContext context) {
    return RenderAnimatedSize(
      alignment: alignment,
      duration: duration,
      reverseDuration: reverseDuration,
      curve: curve,
      vsync: vsync,
      textDirection: Directionality.of(context),
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderAnimatedSize renderObject) {
    renderObject
      ..alignment = alignment
      ..duration = duration
      ..reverseDuration = reverseDuration
      ..curve = curve
      ..vsync = vsync
      ..textDirection = Directionality.of(context);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<AlignmentGeometry>(
        'alignment', alignment,
        defaultValue: Alignment.topCenter));
    properties
        .add(IntProperty('duration', duration.inMilliseconds, unit: 'ms'));
    properties.add(IntProperty(
        'reverseDuration', reverseDuration?.inMilliseconds,
        unit: 'ms', defaultValue: null));
  }
}

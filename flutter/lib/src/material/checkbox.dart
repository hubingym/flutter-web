import 'dart:math' as math;

import 'package:flutter_web/rendering.dart';
import 'package:flutter_web/widgets.dart';

import 'constants.dart';
import 'theme.dart';
import 'theme_data.dart';
import 'toggleable.dart';

class Checkbox extends StatefulWidget {
  const Checkbox({
    Key key,
    @required this.value,
    this.tristate = false,
    @required this.onChanged,
    this.activeColor,
    this.materialTapTargetSize,
  })  : assert(tristate != null),
        assert(tristate || value != null),
        super(key: key);

  final bool value;

  final ValueChanged<bool> onChanged;

  final Color activeColor;

  final bool tristate;

  final MaterialTapTargetSize materialTapTargetSize;

  static const double width = 18.0;

  @override
  _CheckboxState createState() => new _CheckboxState();
}

class _CheckboxState extends State<Checkbox> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    Size size;
    switch (widget.materialTapTargetSize ?? themeData.materialTapTargetSize) {
      case MaterialTapTargetSize.padded:
        size = const Size(
            2 * kRadialReactionRadius + 8.0, 2 * kRadialReactionRadius + 8.0);
        break;
      case MaterialTapTargetSize.shrinkWrap:
        size = const Size(2 * kRadialReactionRadius, 2 * kRadialReactionRadius);
        break;
    }
    final BoxConstraints additionalConstraints = new BoxConstraints.tight(size);
    return new _CheckboxRenderObjectWidget(
      value: widget.value,
      tristate: widget.tristate,
      activeColor: widget.activeColor ?? themeData.toggleableActiveColor,
      inactiveColor: widget.onChanged != null
          ? themeData.unselectedWidgetColor
          : themeData.disabledColor,
      onChanged: widget.onChanged,
      additionalConstraints: additionalConstraints,
      vsync: this,
    );
  }
}

class _CheckboxRenderObjectWidget extends LeafRenderObjectWidget {
  const _CheckboxRenderObjectWidget({
    Key key,
    @required this.value,
    @required this.tristate,
    @required this.activeColor,
    @required this.inactiveColor,
    @required this.onChanged,
    @required this.vsync,
    @required this.additionalConstraints,
  })  : assert(tristate != null),
        assert(tristate || value != null),
        assert(activeColor != null),
        assert(inactiveColor != null),
        assert(vsync != null),
        super(key: key);

  final bool value;
  final bool tristate;
  final Color activeColor;
  final Color inactiveColor;
  final ValueChanged<bool> onChanged;
  final TickerProvider vsync;
  final BoxConstraints additionalConstraints;

  @override
  _RenderCheckbox createRenderObject(BuildContext context) =>
      new _RenderCheckbox(
        value: value,
        tristate: tristate,
        activeColor: activeColor,
        inactiveColor: inactiveColor,
        onChanged: onChanged,
        vsync: vsync,
        additionalConstraints: additionalConstraints,
      );

  @override
  void updateRenderObject(BuildContext context, _RenderCheckbox renderObject) {
    renderObject
      ..value = value
      ..tristate = tristate
      ..activeColor = activeColor
      ..inactiveColor = inactiveColor
      ..onChanged = onChanged
      ..additionalConstraints = additionalConstraints
      ..vsync = vsync;
  }
}

const double _kEdgeSize = Checkbox.width;
const Radius _kEdgeRadius = Radius.circular(1.0);
const double _kStrokeWidth = 2.0;

class _RenderCheckbox extends RenderToggleable {
  _RenderCheckbox({
    bool value,
    bool tristate,
    Color activeColor,
    Color inactiveColor,
    BoxConstraints additionalConstraints,
    ValueChanged<bool> onChanged,
    @required TickerProvider vsync,
  })  : _oldValue = value,
        super(
          value: value,
          tristate: tristate,
          activeColor: activeColor,
          inactiveColor: inactiveColor,
          onChanged: onChanged,
          additionalConstraints: additionalConstraints,
          vsync: vsync,
        );

  bool _oldValue;

  @override
  set value(bool newValue) {
    if (newValue == value) return;
    _oldValue = value;
    super.value = newValue;
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config.isChecked = value == true;
  }

  RRect _outerRectAt(Offset origin, double t) {
    final double inset = 1.0 - (t - 0.5).abs() * 2.0;
    final double size = _kEdgeSize - inset * _kStrokeWidth;
    final Rect rect =
        new Rect.fromLTWH(origin.dx + inset, origin.dy + inset, size, size);
    return new RRect.fromRectAndRadius(rect, _kEdgeRadius);
  }

  Color _colorAt(double t) {
    return onChanged == null
        ? inactiveColor
        : (t >= 0.25
            ? activeColor
            : Color.lerp(inactiveColor, activeColor, t * 4.0));
  }

  Paint _initStrokePaint(Paint paint) {
    return new Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _kStrokeWidth;
  }

  void _drawBorder(Canvas canvas, RRect outer, double t, Paint paint) {
    assert(t >= 0.0 && t <= 0.5);
    final double size = outer.width;

    RRect inner = outer.deflate(math.min(size / 2.0, _kStrokeWidth + size * t));
    if (inner.tlRadiusX <= 0 || inner.tlRadiusY <= 0) {
      inner = new RRect.fromRectAndRadius(
          inner.outerRect, new Radius.circular(1.0));
    }
    canvas.drawDRRect(outer, inner, paint);
  }

  void _drawCheck(Canvas canvas, Offset origin, double t, Paint paint) {
    assert(t >= 0.0 && t <= 1.0);

    final Path path = new Path();
    const Offset start = Offset(_kEdgeSize * 0.15, _kEdgeSize * 0.45);
    const Offset mid = Offset(_kEdgeSize * 0.4, _kEdgeSize * 0.7);
    const Offset end = Offset(_kEdgeSize * 0.85, _kEdgeSize * 0.25);
    if (t < 0.5) {
      final double strokeT = t * 2.0;
      final Offset drawMid = Offset.lerp(start, mid, strokeT);
      path.moveTo(origin.dx + start.dx, origin.dy + start.dy);
      path.lineTo(origin.dx + drawMid.dx, origin.dy + drawMid.dy);
    } else {
      final double strokeT = (t - 0.5) * 2.0;
      final Offset drawEnd = Offset.lerp(mid, end, strokeT);
      path.moveTo(origin.dx + start.dx, origin.dy + start.dy);
      path.lineTo(origin.dx + mid.dx, origin.dy + mid.dy);
      path.lineTo(origin.dx + drawEnd.dx, origin.dy + drawEnd.dy);
    }
    canvas.drawPath(path, paint);
  }

  void _drawDash(Canvas canvas, Offset origin, double t, Paint paint) {
    assert(t >= 0.0 && t <= 1.0);

    const Offset start = Offset(_kEdgeSize * 0.2, _kEdgeSize * 0.5);
    const Offset mid = Offset(_kEdgeSize * 0.5, _kEdgeSize * 0.5);
    const Offset end = Offset(_kEdgeSize * 0.8, _kEdgeSize * 0.5);
    final Offset drawStart = Offset.lerp(start, mid, 1.0 - t);
    final Offset drawEnd = Offset.lerp(mid, end, t);
    canvas.drawLine(origin + drawStart, origin + drawEnd, paint);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final Canvas canvas = context.canvas;
    paintRadialReaction(canvas, offset, size.center(Offset.zero));

    final Offset origin =
        offset + (size / 2.0 - const Size.square(_kEdgeSize) / 2.0);
    final AnimationStatus status = position.status;
    final double tNormalized =
        status == AnimationStatus.forward || status == AnimationStatus.completed
            ? position.value
            : 1.0 - position.value;

    if (_oldValue == false || value == false) {
      final double t = value == false ? 1.0 - tNormalized : tNormalized;
      final RRect outer = _outerRectAt(origin, t);
      Paint paint = new Paint()..color = _colorAt(t);

      if (t <= 0.5) {
        _drawBorder(canvas, outer, t, paint);
      } else {
        canvas.drawRRect(outer, paint);

        paint = _initStrokePaint(paint);
        final double tShrink = (t - 0.5) * 2.0;
        if (_oldValue == null)
          _drawDash(canvas, origin, tShrink, paint);
        else
          _drawCheck(canvas, origin, tShrink, paint);
      }
    } else {
      final RRect outer = _outerRectAt(origin, 1.0);
      Paint paint = new Paint()..color = _colorAt(1.0);
      canvas.drawRRect(outer, paint);

      paint = _initStrokePaint(paint);
      if (tNormalized <= 0.5) {
        final double tShrink = 1.0 - tNormalized * 2.0;
        if (_oldValue == true)
          _drawCheck(canvas, origin, tShrink, paint);
        else
          _drawDash(canvas, origin, tShrink, paint);
      } else {
        final double tExpand = (tNormalized - 0.5) * 2.0;
        if (value == true)
          _drawCheck(canvas, origin, tExpand, paint);
        else
          _drawDash(canvas, origin, tExpand, paint);
      }
    }
  }
}

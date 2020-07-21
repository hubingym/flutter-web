import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/ui.dart';
import 'package:flutter_web/widgets.dart';

import 'button_theme.dart';
import 'colors.dart';
import 'material_button.dart';
import 'raised_button.dart';
import 'theme.dart';

const Duration _kPressDuration = Duration(milliseconds: 150);

const Duration _kElevationDuration = Duration(milliseconds: 75);

class OutlineButton extends MaterialButton {
  const OutlineButton({
    Key key,
    @required VoidCallback onPressed,
    ButtonTextTheme textTheme,
    Color textColor,
    Color disabledTextColor,
    Color color,
    Color focusColor,
    Color hoverColor,
    Color highlightColor,
    Color splashColor,
    double highlightElevation,
    this.borderSide,
    this.disabledBorderColor,
    this.highlightedBorderColor,
    EdgeInsetsGeometry padding,
    ShapeBorder shape,
    Clip clipBehavior,
    FocusNode focusNode,
    Widget child,
  })  : assert(highlightElevation == null || highlightElevation >= 0.0),
        super(
          key: key,
          onPressed: onPressed,
          textTheme: textTheme,
          textColor: textColor,
          disabledTextColor: disabledTextColor,
          color: color,
          focusColor: focusColor,
          hoverColor: hoverColor,
          highlightColor: highlightColor,
          splashColor: splashColor,
          highlightElevation: highlightElevation,
          padding: padding,
          shape: shape,
          clipBehavior: clipBehavior,
          focusNode: focusNode,
          child: child,
        );

  factory OutlineButton.icon({
    Key key,
    @required VoidCallback onPressed,
    ButtonTextTheme textTheme,
    Color textColor,
    Color disabledTextColor,
    Color color,
    Color focusColor,
    Color hoverColor,
    Color highlightColor,
    Color splashColor,
    double highlightElevation,
    Color highlightedBorderColor,
    Color disabledBorderColor,
    BorderSide borderSide,
    EdgeInsetsGeometry padding,
    ShapeBorder shape,
    Clip clipBehavior,
    FocusNode focusNode,
    @required Widget icon,
    @required Widget label,
  }) = _OutlineButtonWithIcon;

  final Color highlightedBorderColor;

  final Color disabledBorderColor;

  final BorderSide borderSide;

  @override
  Widget build(BuildContext context) {
    final ButtonThemeData buttonTheme = ButtonTheme.of(context);
    return _OutlineButton(
      onPressed: onPressed,
      brightness: buttonTheme.getBrightness(this),
      textTheme: textTheme,
      textColor: buttonTheme.getTextColor(this),
      disabledTextColor: buttonTheme.getDisabledTextColor(this),
      color: color,
      focusColor: buttonTheme.getFocusColor(this),
      hoverColor: buttonTheme.getHoverColor(this),
      highlightColor: buttonTheme.getHighlightColor(this),
      splashColor: buttonTheme.getSplashColor(this),
      highlightElevation: buttonTheme.getHighlightElevation(this),
      borderSide: borderSide,
      disabledBorderColor: disabledBorderColor,
      highlightedBorderColor:
          highlightedBorderColor ?? buttonTheme.colorScheme.primary,
      padding: buttonTheme.getPadding(this),
      shape: buttonTheme.getShape(this),
      clipBehavior: clipBehavior,
      focusNode: focusNode,
      child: child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<BorderSide>('borderSide', borderSide,
        defaultValue: null));
    properties.add(DiagnosticsProperty<Color>(
        'disabledBorderColor', disabledBorderColor,
        defaultValue: null));
    properties.add(DiagnosticsProperty<Color>(
        'highlightedBorderColor', highlightedBorderColor,
        defaultValue: null));
  }
}

class _OutlineButtonWithIcon extends OutlineButton
    with MaterialButtonWithIconMixin {
  _OutlineButtonWithIcon({
    Key key,
    @required VoidCallback onPressed,
    ButtonTextTheme textTheme,
    Color textColor,
    Color disabledTextColor,
    Color color,
    Color focusColor,
    Color hoverColor,
    Color highlightColor,
    Color splashColor,
    double highlightElevation,
    Color highlightedBorderColor,
    Color disabledBorderColor,
    BorderSide borderSide,
    EdgeInsetsGeometry padding,
    ShapeBorder shape,
    Clip clipBehavior,
    FocusNode focusNode,
    @required Widget icon,
    @required Widget label,
  })  : assert(highlightElevation == null || highlightElevation >= 0.0),
        assert(icon != null),
        assert(label != null),
        super(
          key: key,
          onPressed: onPressed,
          textTheme: textTheme,
          textColor: textColor,
          disabledTextColor: disabledTextColor,
          color: color,
          focusColor: focusColor,
          hoverColor: hoverColor,
          highlightColor: highlightColor,
          splashColor: splashColor,
          highlightElevation: highlightElevation,
          disabledBorderColor: disabledBorderColor,
          highlightedBorderColor: highlightedBorderColor,
          borderSide: borderSide,
          padding: padding,
          shape: shape,
          clipBehavior: clipBehavior,
          focusNode: focusNode,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              icon,
              const SizedBox(width: 8.0),
              label,
            ],
          ),
        );
}

class _OutlineButton extends StatefulWidget {
  const _OutlineButton({
    Key key,
    @required this.onPressed,
    this.brightness,
    this.textTheme,
    this.textColor,
    this.disabledTextColor,
    this.color,
    this.focusColor,
    this.hoverColor,
    this.highlightColor,
    this.splashColor,
    @required this.highlightElevation,
    this.borderSide,
    this.disabledBorderColor,
    @required this.highlightedBorderColor,
    this.padding,
    this.shape,
    this.clipBehavior,
    this.focusNode,
    this.child,
  })  : assert(highlightElevation != null && highlightElevation >= 0.0),
        assert(highlightedBorderColor != null),
        super(key: key);

  final VoidCallback onPressed;
  final Brightness brightness;
  final ButtonTextTheme textTheme;
  final Color textColor;
  final Color disabledTextColor;
  final Color color;
  final Color splashColor;
  final Color focusColor;
  final Color hoverColor;
  final Color highlightColor;
  final double highlightElevation;
  final BorderSide borderSide;
  final Color disabledBorderColor;
  final Color highlightedBorderColor;
  final EdgeInsetsGeometry padding;
  final ShapeBorder shape;
  final Clip clipBehavior;
  final FocusNode focusNode;
  final Widget child;

  bool get enabled => onPressed != null;

  @override
  _OutlineButtonState createState() => _OutlineButtonState();
}

class _OutlineButtonState extends State<_OutlineButton>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;
  Animation<double> _fillAnimation;
  Animation<double> _elevationAnimation;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: _kPressDuration,
      vsync: this,
    );
    _fillAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        0.0,
        0.5,
        curve: Curves.fastOutSlowIn,
      ),
    );
    _elevationAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 0.5),
      reverseCurve: const Interval(1.0, 1.0),
    );
  }

  @override
  void didUpdateWidget(_OutlineButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_pressed && !widget.enabled) {
      _pressed = false;
      _controller.reverse();
    }
  }

  void _handleHighlightChanged(bool value) {
    if (_pressed == value) return;
    setState(() {
      _pressed = value;
      if (value)
        _controller.forward();
      else
        _controller.reverse();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getFillColor() {
    if (widget.highlightElevation == null || widget.highlightElevation == 0.0)
      return Colors.transparent;
    final Color color = widget.color ?? Theme.of(context).canvasColor;
    final Tween<Color> colorTween = ColorTween(
      begin: color.withAlpha(0x00),
      end: color.withAlpha(0xFF),
    );
    return colorTween.evaluate(_fillAnimation);
  }

  BorderSide _getOutline() {
    if (widget.borderSide?.style == BorderStyle.none) return widget.borderSide;

    final Color specifiedColor = widget.enabled
        ? (_pressed ? widget.highlightedBorderColor : null) ??
            widget.borderSide?.color
        : widget.disabledBorderColor;

    final Color themeColor =
        Theme.of(context).colorScheme.onSurface.withOpacity(0.12);

    return BorderSide(
      color: specifiedColor ?? themeColor,
      width: widget.borderSide?.width ?? 1.0,
    );
  }

  double _getHighlightElevation() {
    if (widget.highlightElevation == null || widget.highlightElevation == 0.0)
      return 0.0;
    return Tween<double>(
      begin: 0.0,
      end: widget.highlightElevation,
    ).evaluate(_elevationAnimation);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget child) {
        return RaisedButton(
          textColor: widget.textColor,
          disabledTextColor: widget.disabledTextColor,
          color: _getFillColor(),
          splashColor: widget.splashColor,
          focusColor: widget.focusColor,
          hoverColor: widget.hoverColor,
          highlightColor: widget.highlightColor,
          disabledColor: Colors.transparent,
          onPressed: widget.onPressed,
          elevation: 0.0,
          disabledElevation: 0.0,
          focusElevation: 0.0,
          hoverElevation: 0.0,
          highlightElevation: _getHighlightElevation(),
          onHighlightChanged: _handleHighlightChanged,
          padding: widget.padding,
          shape: _OutlineBorder(
            shape: widget.shape,
            side: _getOutline(),
          ),
          clipBehavior: widget.clipBehavior,
          focusNode: widget.focusNode,
          animationDuration: _kElevationDuration,
          child: widget.child,
        );
      },
    );
  }
}

class _OutlineBorder extends ShapeBorder {
  const _OutlineBorder({
    @required this.shape,
    @required this.side,
  })  : assert(shape != null),
        assert(side != null);

  final ShapeBorder shape;
  final BorderSide side;

  @override
  EdgeInsetsGeometry get dimensions {
    return EdgeInsets.all(side.width);
  }

  @override
  ShapeBorder scale(double t) {
    return _OutlineBorder(
      shape: shape.scale(t),
      side: side.scale(t),
    );
  }

  @override
  ShapeBorder lerpFrom(ShapeBorder a, double t) {
    assert(t != null);
    if (a is _OutlineBorder) {
      return _OutlineBorder(
        side: BorderSide.lerp(a.side, side, t),
        shape: ShapeBorder.lerp(a.shape, shape, t),
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder lerpTo(ShapeBorder b, double t) {
    assert(t != null);
    if (b is _OutlineBorder) {
      return _OutlineBorder(
        side: BorderSide.lerp(side, b.side, t),
        shape: ShapeBorder.lerp(shape, b.shape, t),
      );
    }
    return super.lerpTo(b, t);
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection textDirection}) {
    return shape.getInnerPath(rect.deflate(side.width),
        textDirection: textDirection);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection textDirection}) {
    return shape.getOuterPath(rect, textDirection: textDirection);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection textDirection}) {
    switch (side.style) {
      case BorderStyle.none:
        break;
      case BorderStyle.solid:
        canvas.drawPath(shape.getOuterPath(rect, textDirection: textDirection),
            side.toPaint());
    }
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final _OutlineBorder typedOther = other;
    return side == typedOther.side && shape == typedOther.shape;
  }

  @override
  int get hashCode => hashValues(side, shape);
}

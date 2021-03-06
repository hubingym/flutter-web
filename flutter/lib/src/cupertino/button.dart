import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/widgets.dart';

import 'theme.dart';

const Color _kDisabledBackground = Color(0xFFA9A9A9);

const Color _kDisabledForeground = Color(0xFFD1D1D1);

const EdgeInsets _kButtonPadding = EdgeInsets.all(16.0);
const EdgeInsets _kBackgroundButtonPadding = EdgeInsets.symmetric(
  vertical: 14.0,
  horizontal: 64.0,
);

class CupertinoButton extends StatefulWidget {
  const CupertinoButton({
    Key key,
    @required this.child,
    this.padding,
    this.color,
    this.disabledColor,
    this.minSize = 44.0,
    this.pressedOpacity = 0.1,
    this.borderRadius = const BorderRadius.all(Radius.circular(8.0)),
    @required this.onPressed,
  })  : assert(pressedOpacity == null ||
            (pressedOpacity >= 0.0 && pressedOpacity <= 1.0)),
        _filled = false,
        super(key: key);

  const CupertinoButton.filled({
    Key key,
    @required this.child,
    this.padding,
    this.disabledColor,
    this.minSize = 44.0,
    this.pressedOpacity = 0.1,
    this.borderRadius = const BorderRadius.all(Radius.circular(8.0)),
    @required this.onPressed,
  })  : assert(pressedOpacity == null ||
            (pressedOpacity >= 0.0 && pressedOpacity <= 1.0)),
        color = null,
        _filled = true,
        super(key: key);

  final Widget child;

  final EdgeInsetsGeometry padding;

  final Color color;

  final Color disabledColor;

  final VoidCallback onPressed;

  final double minSize;

  final double pressedOpacity;

  final BorderRadius borderRadius;

  final bool _filled;

  bool get enabled => onPressed != null;

  @override
  _CupertinoButtonState createState() => _CupertinoButtonState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(FlagProperty('enabled', value: enabled, ifFalse: 'disabled'));
  }
}

class _CupertinoButtonState extends State<CupertinoButton>
    with SingleTickerProviderStateMixin {
  static const Duration kFadeOutDuration = Duration(milliseconds: 10);
  static const Duration kFadeInDuration = Duration(milliseconds: 100);
  final Tween<double> _opacityTween = Tween<double>(begin: 1.0);

  AnimationController _animationController;
  Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      value: 0.0,
      vsync: this,
    );
    _opacityAnimation = _animationController
        .drive(CurveTween(curve: Curves.decelerate))
        .drive(_opacityTween);
    _setTween();
  }

  @override
  void didUpdateWidget(CupertinoButton old) {
    super.didUpdateWidget(old);
    _setTween();
  }

  void _setTween() {
    _opacityTween.end = widget.pressedOpacity ?? 1.0;
  }

  @override
  void dispose() {
    _animationController.dispose();
    _animationController = null;
    super.dispose();
  }

  bool _buttonHeldDown = false;

  void _handleTapDown(TapDownDetails event) {
    if (!_buttonHeldDown) {
      _buttonHeldDown = true;
      _animate();
    }
  }

  void _handleTapUp(TapUpDetails event) {
    if (_buttonHeldDown) {
      _buttonHeldDown = false;
      _animate();
    }
  }

  void _handleTapCancel() {
    if (_buttonHeldDown) {
      _buttonHeldDown = false;
      _animate();
    }
  }

  void _animate() {
    if (_animationController.isAnimating) return;
    final bool wasHeldDown = _buttonHeldDown;
    final TickerFuture ticker = _buttonHeldDown
        ? _animationController.animateTo(1.0, duration: kFadeOutDuration)
        : _animationController.animateTo(0.0, duration: kFadeInDuration);
    ticker.then<void>((void value) {
      if (mounted && wasHeldDown != _buttonHeldDown) _animate();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.enabled;
    final Color primaryColor = CupertinoTheme.of(context).primaryColor;
    final Color backgroundColor =
        widget.color ?? (widget._filled ? primaryColor : null);
    final Color foregroundColor = backgroundColor != null
        ? CupertinoTheme.of(context).primaryContrastingColor
        : enabled ? primaryColor : _kDisabledForeground;
    final TextStyle textStyle = CupertinoTheme.of(context)
        .textTheme
        .textStyle
        .copyWith(color: foregroundColor);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? _handleTapDown : null,
      onTapUp: enabled ? _handleTapUp : null,
      onTapCancel: enabled ? _handleTapCancel : null,
      onTap: widget.onPressed,
      child: Semantics(
        button: true,
        child: ConstrainedBox(
          constraints: widget.minSize == null
              ? const BoxConstraints()
              : BoxConstraints(
                  minWidth: widget.minSize,
                  minHeight: widget.minSize,
                ),
          child: FadeTransition(
            opacity: _opacityAnimation,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: widget.borderRadius,
                color: backgroundColor != null && !enabled
                    ? widget.disabledColor ?? _kDisabledBackground
                    : backgroundColor,
              ),
              child: Padding(
                padding: widget.padding ??
                    (backgroundColor != null
                        ? _kBackgroundButtonPadding
                        : _kButtonPadding),
                child: Center(
                  widthFactor: 1.0,
                  heightFactor: 1.0,
                  child: DefaultTextStyle(
                    style: textStyle,
                    child: IconTheme(
                      data: IconThemeData(color: foregroundColor),
                      child: widget.child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

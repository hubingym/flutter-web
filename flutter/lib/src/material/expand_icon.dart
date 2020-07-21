import 'dart:math' as math;

import 'package:flutter_web/widgets.dart';

import 'colors.dart';
import 'debug.dart';
import 'icon_button.dart';
import 'icons.dart';
import 'material_localizations.dart';
import 'theme.dart';

class ExpandIcon extends StatefulWidget {
  const ExpandIcon(
      {Key key,
      this.isExpanded = false,
      this.size = 24.0,
      @required this.onPressed,
      this.padding = const EdgeInsets.all(8.0)})
      : assert(isExpanded != null),
        assert(size != null),
        assert(padding != null),
        super(key: key);

  final bool isExpanded;

  final double size;

  final ValueChanged<bool> onPressed;

  final EdgeInsetsGeometry padding;

  @override
  _ExpandIconState createState() => _ExpandIconState();
}

class _ExpandIconState extends State<ExpandIcon>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;
  Animation<double> _iconTurns;

  static final Animatable<double> _iconTurnTween =
      Tween<double>(begin: 0.0, end: 0.5)
          .chain(CurveTween(curve: Curves.fastOutSlowIn));

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(duration: kThemeAnimationDuration, vsync: this);
    _iconTurns = _controller.drive(_iconTurnTween);

    if (widget.isExpanded) {
      _controller.value = math.pi;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ExpandIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  void _handlePressed() {
    if (widget.onPressed != null) widget.onPressed(widget.isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    assert(debugCheckHasMaterialLocalizations(context));
    final MaterialLocalizations localizations =
        MaterialLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final String onTapHint = widget.isExpanded
        ? localizations.expandedIconTapHint
        : localizations.collapsedIconTapHint;

    return Semantics(
      onTapHint: widget.onPressed == null ? null : onTapHint,
      child: IconButton(
        padding: widget.padding,
        color: theme.brightness == Brightness.dark
            ? Colors.white54
            : Colors.black54,
        onPressed: widget.onPressed == null ? null : _handlePressed,
        icon: RotationTransition(
            turns: _iconTurns, child: const Icon(Icons.expand_more)),
      ),
    );
  }
}

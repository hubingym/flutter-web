import 'package:flutter_web/ui.dart' show Clip;
import 'package:flutter_web/widgets.dart';

import 'card_theme.dart';
import 'material.dart';
import 'theme.dart';

class Card extends StatelessWidget {
  const Card({
    Key key,
    this.color,
    this.elevation,
    this.shape,
    this.borderOnForeground = true,
    this.margin,
    this.clipBehavior,
    this.child,
    this.semanticContainer = true,
  })  : assert(elevation == null || elevation >= 0.0),
        assert(borderOnForeground != null),
        super(key: key);

  final Color color;

  final double elevation;

  final ShapeBorder shape;

  final bool borderOnForeground;

  final Clip clipBehavior;

  final EdgeInsetsGeometry margin;

  final bool semanticContainer;

  final Widget child;

  static const double _defaultElevation = 1.0;
  static const Clip _defaultClipBehavior = Clip.none;

  @override
  Widget build(BuildContext context) {
    final CardTheme cardTheme = CardTheme.of(context);

    return Semantics(
      container: semanticContainer,
      child: Container(
        margin: margin ?? cardTheme.margin ?? const EdgeInsets.all(4.0),
        child: Material(
          type: MaterialType.card,
          color: color ?? cardTheme.color ?? Theme.of(context).cardColor,
          elevation: elevation ?? cardTheme.elevation ?? _defaultElevation,
          shape: shape ??
              cardTheme.shape ??
              const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(4.0)),
              ),
          borderOnForeground: borderOnForeground,
          clipBehavior:
              clipBehavior ?? cardTheme.clipBehavior ?? _defaultClipBehavior,
          child: Semantics(
            explicitChildNodes: !semanticContainer,
            child: child,
          ),
        ),
      ),
    );
  }
}

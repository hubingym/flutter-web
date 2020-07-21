import 'dart:math' as math;

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/widgets.dart';

import 'debug.dart';
import 'icons.dart';
import 'ink_well.dart';
import 'material.dart';
import 'theme.dart';
import 'tooltip.dart';

const double _kMinButtonSize = 48.0;

class IconButton extends StatelessWidget {
  const IconButton({
    Key key,
    this.iconSize = 24.0,
    this.padding = const EdgeInsets.all(8.0),
    this.alignment = Alignment.center,
    @required this.icon,
    this.color,
    this.focusColor,
    this.hoverColor,
    this.highlightColor,
    this.splashColor,
    this.disabledColor,
    @required this.onPressed,
    this.focusNode,
    this.tooltip,
  })  : assert(iconSize != null),
        assert(padding != null),
        assert(alignment != null),
        assert(icon != null),
        super(key: key);

  final double iconSize;

  final EdgeInsetsGeometry padding;

  final AlignmentGeometry alignment;

  final Widget icon;

  final Color focusColor;

  final Color hoverColor;

  final Color color;

  final Color splashColor;

  final Color highlightColor;

  final Color disabledColor;

  final VoidCallback onPressed;

  final FocusNode focusNode;

  final String tooltip;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    Color currentColor;
    if (onPressed != null)
      currentColor = color;
    else
      currentColor = disabledColor ?? Theme.of(context).disabledColor;

    Widget result = ConstrainedBox(
      constraints: const BoxConstraints(
          minWidth: _kMinButtonSize, minHeight: _kMinButtonSize),
      child: Padding(
        padding: padding,
        child: SizedBox(
          height: iconSize,
          width: iconSize,
          child: Align(
            alignment: alignment,
            child: IconTheme.merge(
              data: IconThemeData(
                size: iconSize,
                color: currentColor,
              ),
              child: icon,
            ),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      result = Tooltip(
        message: tooltip,
        child: result,
      );
    }

    return Semantics(
      button: true,
      enabled: onPressed != null,
      child: Focus(
        focusNode: focusNode,
        child: InkResponse(
          onTap: onPressed,
          child: result,
          focusColor: focusColor ?? Theme.of(context).focusColor,
          hoverColor: hoverColor ?? Theme.of(context).hoverColor,
          highlightColor: highlightColor ?? Theme.of(context).highlightColor,
          splashColor: splashColor ?? Theme.of(context).splashColor,
          radius: math.max(
            Material.defaultSplashRadius,
            (iconSize + math.min(padding.horizontal, padding.vertical)) * 0.7,
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Widget>('icon', icon, showName: false));
    properties.add(
        StringProperty('tooltip', tooltip, defaultValue: null, quoted: false));
    properties.add(ObjectFlagProperty<VoidCallback>('onPressed', onPressed,
        ifNull: 'disabled'));
    properties
        .add(DiagnosticsProperty<Color>('color', color, defaultValue: null));
    properties.add(DiagnosticsProperty<Color>('disabledColor', disabledColor,
        defaultValue: null));
    properties.add(DiagnosticsProperty<Color>('focusColor', focusColor,
        defaultValue: null));
    properties.add(DiagnosticsProperty<Color>('hoverColor', hoverColor,
        defaultValue: null));
    properties.add(DiagnosticsProperty<Color>('highlightColor', highlightColor,
        defaultValue: null));
    properties.add(DiagnosticsProperty<Color>('splashColor', splashColor,
        defaultValue: null));
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('padding', padding,
        defaultValue: null));
    properties.add(DiagnosticsProperty<FocusNode>('focusNode', focusNode,
        defaultValue: null));
  }
}

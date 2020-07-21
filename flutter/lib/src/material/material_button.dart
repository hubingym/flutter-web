import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/rendering.dart';
import 'package:flutter_web/widgets.dart';

import 'button.dart';
import 'button_theme.dart';
import 'constants.dart';
import 'ink_well.dart';
import 'material.dart';
import 'theme.dart';
import 'theme_data.dart';

class MaterialButton extends StatelessWidget {
  const MaterialButton({
    Key key,
    @required this.onPressed,
    this.onHighlightChanged,
    this.textTheme,
    this.textColor,
    this.disabledTextColor,
    this.color,
    this.disabledColor,
    this.focusColor,
    this.hoverColor,
    this.highlightColor,
    this.splashColor,
    this.colorBrightness,
    this.elevation,
    this.focusElevation,
    this.hoverElevation,
    this.highlightElevation,
    this.disabledElevation,
    this.padding,
    this.shape,
    this.clipBehavior = Clip.none,
    this.focusNode,
    this.materialTapTargetSize,
    this.animationDuration,
    this.minWidth,
    this.height,
    this.child,
  }) : super(key: key);

  final VoidCallback onPressed;

  final ValueChanged<bool> onHighlightChanged;

  final ButtonTextTheme textTheme;

  final Color textColor;

  final Color disabledTextColor;

  final Color color;

  final Color disabledColor;

  final Color splashColor;

  final Color focusColor;

  final Color hoverColor;

  final Color highlightColor;

  final double elevation;

  final double hoverElevation;

  final double focusElevation;

  final double highlightElevation;

  final double disabledElevation;

  final Brightness colorBrightness;

  final Widget child;

  bool get enabled => onPressed != null;

  final EdgeInsetsGeometry padding;

  final ShapeBorder shape;

  final Clip clipBehavior;

  final FocusNode focusNode;

  final Duration animationDuration;

  final MaterialTapTargetSize materialTapTargetSize;

  final double minWidth;

  final double height;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ButtonThemeData buttonTheme = ButtonTheme.of(context);

    return RawMaterialButton(
      onPressed: onPressed,
      onHighlightChanged: onHighlightChanged,
      fillColor: buttonTheme.getFillColor(this),
      textStyle: theme.textTheme.button
          .copyWith(color: buttonTheme.getTextColor(this)),
      focusColor:
          focusColor ?? buttonTheme.getFocusColor(this) ?? theme.focusColor,
      hoverColor:
          hoverColor ?? buttonTheme.getHoverColor(this) ?? theme.hoverColor,
      highlightColor: highlightColor ?? theme.highlightColor,
      splashColor: splashColor ?? theme.splashColor,
      elevation: buttonTheme.getElevation(this),
      focusElevation: buttonTheme.getFocusElevation(this),
      hoverElevation: buttonTheme.getHoverElevation(this),
      highlightElevation: buttonTheme.getHighlightElevation(this),
      padding: buttonTheme.getPadding(this),
      constraints: buttonTheme.getConstraints(this).copyWith(
            minWidth: minWidth,
            minHeight: height,
          ),
      shape: buttonTheme.getShape(this),
      clipBehavior: clipBehavior ?? Clip.none,
      focusNode: focusNode,
      animationDuration: buttonTheme.getAnimationDuration(this),
      child: child,
      materialTapTargetSize:
          materialTapTargetSize ?? theme.materialTapTargetSize,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ObjectFlagProperty<VoidCallback>('onPressed', onPressed,
        ifNull: 'disabled'));
    properties.add(DiagnosticsProperty<ButtonTextTheme>('textTheme', textTheme,
        defaultValue: null));
    properties.add(
        DiagnosticsProperty<Color>('textColor', textColor, defaultValue: null));
    properties.add(DiagnosticsProperty<Color>(
        'disabledTextColor', disabledTextColor,
        defaultValue: null));
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
    properties.add(DiagnosticsProperty<Brightness>(
        'colorBrightness', colorBrightness,
        defaultValue: null));
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('padding', padding,
        defaultValue: null));
    properties.add(
        DiagnosticsProperty<ShapeBorder>('shape', shape, defaultValue: null));
    properties.add(DiagnosticsProperty<FocusNode>('focusNode', focusNode,
        defaultValue: null));
    properties.add(DiagnosticsProperty<MaterialTapTargetSize>(
        'materialTapTargetSize', materialTapTargetSize,
        defaultValue: null));
  }
}

mixin MaterialButtonWithIconMixin {}

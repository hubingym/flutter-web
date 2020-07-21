import 'dart:math' as math;

import 'package:flutter_web/gestures.dart';
import 'package:flutter_web/painting.dart';
import 'package:flutter_web/rendering.dart';
import 'package:flutter_web/ui.dart' show Clip;
import 'package:flutter_web/widgets.dart';

import 'chip_theme.dart';
import 'colors.dart';
import 'debug.dart';
import 'icons.dart';
import 'ink_well.dart';
import 'material.dart';
import 'material_localizations.dart';
import 'theme.dart';
import 'theme_data.dart';
import 'tooltip.dart';

const double _kChipHeight = 32.0;
const double _kDeleteIconSize = 18.0;

const int _kCheckmarkAlpha = 0xde;
const int _kDisabledAlpha = 0x61;
const double _kCheckmarkStrokeWidth = 2.0;

const Duration _kSelectDuration = Duration(milliseconds: 195);
const Duration _kCheckmarkDuration = Duration(milliseconds: 150);
const Duration _kCheckmarkReverseDuration = Duration(milliseconds: 50);
const Duration _kDrawerDuration = Duration(milliseconds: 150);
const Duration _kReverseDrawerDuration = Duration(milliseconds: 100);
const Duration _kDisableDuration = Duration(milliseconds: 75);

const Color _kSelectScrimColor = Color(0x60191919);
const Icon _kDefaultDeleteIcon = Icon(Icons.cancel, size: _kDeleteIconSize);

abstract class ChipAttributes {
  factory ChipAttributes._() => null;

  Widget get label;

  Widget get avatar;

  TextStyle get labelStyle;

  ShapeBorder get shape;

  Clip get clipBehavior;

  Color get backgroundColor;

  EdgeInsetsGeometry get padding;

  EdgeInsetsGeometry get labelPadding;

  MaterialTapTargetSize get materialTapTargetSize;

  double get elevation;

  Color get shadowColor;
}

abstract class DeletableChipAttributes {
  factory DeletableChipAttributes._() => null;

  Widget get deleteIcon;

  VoidCallback get onDeleted;

  Color get deleteIconColor;

  String get deleteButtonTooltipMessage;
}

abstract class SelectableChipAttributes {
  factory SelectableChipAttributes._() => null;

  bool get selected;

  ValueChanged<bool> get onSelected;

  double get pressElevation;

  Color get selectedColor;

  Color get selectedShadowColor;

  String get tooltip;

  ShapeBorder get avatarBorder;
}

abstract class DisabledChipAttributes {
  factory DisabledChipAttributes._() => null;

  bool get isEnabled;

  Color get disabledColor;
}

abstract class TappableChipAttributes {
  factory TappableChipAttributes._() => null;

  VoidCallback get onPressed;

  double get pressElevation;

  String get tooltip;
}

class Chip extends StatelessWidget
    implements ChipAttributes, DeletableChipAttributes {
  const Chip({
    Key key,
    this.avatar,
    @required this.label,
    this.labelStyle,
    this.labelPadding,
    this.deleteIcon,
    this.onDeleted,
    this.deleteIconColor,
    this.deleteButtonTooltipMessage,
    this.shape,
    this.clipBehavior = Clip.none,
    this.backgroundColor,
    this.padding,
    this.materialTapTargetSize,
    this.elevation,
    this.shadowColor,
  })  : assert(label != null),
        assert(clipBehavior != null),
        assert(elevation == null || elevation >= 0.0),
        super(key: key);

  @override
  final Widget avatar;
  @override
  final Widget label;
  @override
  final TextStyle labelStyle;
  @override
  final EdgeInsetsGeometry labelPadding;
  @override
  final ShapeBorder shape;
  @override
  final Clip clipBehavior;
  @override
  final Color backgroundColor;
  @override
  final EdgeInsetsGeometry padding;
  @override
  final Widget deleteIcon;
  @override
  final VoidCallback onDeleted;
  @override
  final Color deleteIconColor;
  @override
  final String deleteButtonTooltipMessage;
  @override
  final MaterialTapTargetSize materialTapTargetSize;
  @override
  final double elevation;
  @override
  final Color shadowColor;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    return RawChip(
      avatar: avatar,
      label: label,
      labelStyle: labelStyle,
      labelPadding: labelPadding,
      deleteIcon: deleteIcon,
      onDeleted: onDeleted,
      deleteIconColor: deleteIconColor,
      deleteButtonTooltipMessage: deleteButtonTooltipMessage,
      tapEnabled: false,
      shape: shape,
      clipBehavior: clipBehavior,
      backgroundColor: backgroundColor,
      padding: padding,
      materialTapTargetSize: materialTapTargetSize,
      elevation: elevation,
      shadowColor: shadowColor,
      isEnabled: true,
    );
  }
}

class InputChip extends StatelessWidget
    implements
        ChipAttributes,
        DeletableChipAttributes,
        SelectableChipAttributes,
        DisabledChipAttributes,
        TappableChipAttributes {
  const InputChip({
    Key key,
    this.avatar,
    @required this.label,
    this.labelStyle,
    this.labelPadding,
    this.selected = false,
    this.isEnabled = true,
    this.onSelected,
    this.deleteIcon,
    this.onDeleted,
    this.deleteIconColor,
    this.deleteButtonTooltipMessage,
    this.onPressed,
    this.pressElevation,
    this.disabledColor,
    this.selectedColor,
    this.tooltip,
    this.shape,
    this.clipBehavior = Clip.none,
    this.backgroundColor,
    this.padding,
    this.materialTapTargetSize,
    this.elevation,
    this.shadowColor,
    this.selectedShadowColor,
    this.avatarBorder = const CircleBorder(),
  })  : assert(selected != null),
        assert(isEnabled != null),
        assert(label != null),
        assert(clipBehavior != null),
        assert(pressElevation == null || pressElevation >= 0.0),
        assert(elevation == null || elevation >= 0.0),
        super(key: key);

  @override
  final Widget avatar;
  @override
  final Widget label;
  @override
  final TextStyle labelStyle;
  @override
  final EdgeInsetsGeometry labelPadding;
  @override
  final bool selected;
  @override
  final bool isEnabled;
  @override
  final ValueChanged<bool> onSelected;
  @override
  final Widget deleteIcon;
  @override
  final VoidCallback onDeleted;
  @override
  final Color deleteIconColor;
  @override
  final String deleteButtonTooltipMessage;
  @override
  final VoidCallback onPressed;
  @override
  final double pressElevation;
  @override
  final Color disabledColor;
  @override
  final Color selectedColor;
  @override
  final String tooltip;
  @override
  final ShapeBorder shape;
  @override
  final Clip clipBehavior;
  @override
  final Color backgroundColor;
  @override
  final EdgeInsetsGeometry padding;
  @override
  final MaterialTapTargetSize materialTapTargetSize;
  @override
  final double elevation;
  @override
  final Color shadowColor;
  @override
  final Color selectedShadowColor;
  @override
  final ShapeBorder avatarBorder;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    return RawChip(
      avatar: avatar,
      label: label,
      labelStyle: labelStyle,
      labelPadding: labelPadding,
      deleteIcon: deleteIcon,
      onDeleted: onDeleted,
      deleteIconColor: deleteIconColor,
      deleteButtonTooltipMessage: deleteButtonTooltipMessage,
      onSelected: onSelected,
      onPressed: onPressed,
      pressElevation: pressElevation,
      selected: selected,
      tapEnabled: true,
      disabledColor: disabledColor,
      selectedColor: selectedColor,
      tooltip: tooltip,
      shape: shape,
      clipBehavior: clipBehavior,
      backgroundColor: backgroundColor,
      padding: padding,
      materialTapTargetSize: materialTapTargetSize,
      elevation: elevation,
      shadowColor: shadowColor,
      selectedShadowColor: selectedShadowColor,
      isEnabled: isEnabled &&
          (onSelected != null || onDeleted != null || onPressed != null),
      avatarBorder: avatarBorder,
    );
  }
}

class ChoiceChip extends StatelessWidget
    implements
        ChipAttributes,
        SelectableChipAttributes,
        DisabledChipAttributes {
  const ChoiceChip({
    Key key,
    this.avatar,
    @required this.label,
    this.labelStyle,
    this.labelPadding,
    this.onSelected,
    this.pressElevation,
    @required this.selected,
    this.selectedColor,
    this.disabledColor,
    this.tooltip,
    this.shape,
    this.clipBehavior = Clip.none,
    this.backgroundColor,
    this.padding,
    this.materialTapTargetSize,
    this.elevation,
    this.shadowColor,
    this.selectedShadowColor,
    this.avatarBorder = const CircleBorder(),
  })  : assert(selected != null),
        assert(label != null),
        assert(clipBehavior != null),
        assert(pressElevation == null || pressElevation >= 0.0),
        assert(elevation == null || elevation >= 0.0),
        super(key: key);

  @override
  final Widget avatar;
  @override
  final Widget label;
  @override
  final TextStyle labelStyle;
  @override
  final EdgeInsetsGeometry labelPadding;
  @override
  final ValueChanged<bool> onSelected;
  @override
  final double pressElevation;
  @override
  final bool selected;
  @override
  final Color disabledColor;
  @override
  final Color selectedColor;
  @override
  final String tooltip;
  @override
  final ShapeBorder shape;
  @override
  final Clip clipBehavior;
  @override
  final Color backgroundColor;
  @override
  final EdgeInsetsGeometry padding;
  @override
  final MaterialTapTargetSize materialTapTargetSize;
  @override
  final double elevation;
  @override
  final Color shadowColor;
  @override
  final Color selectedShadowColor;
  @override
  final ShapeBorder avatarBorder;

  @override
  bool get isEnabled => onSelected != null;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    final ChipThemeData chipTheme = ChipTheme.of(context);
    return RawChip(
      avatar: avatar,
      label: label,
      labelStyle:
          labelStyle ?? (selected ? chipTheme.secondaryLabelStyle : null),
      labelPadding: labelPadding,
      onSelected: onSelected,
      pressElevation: pressElevation,
      selected: selected,
      showCheckmark: false,
      onDeleted: null,
      tooltip: tooltip,
      shape: shape,
      clipBehavior: clipBehavior,
      disabledColor: disabledColor,
      selectedColor: selectedColor ?? chipTheme.secondarySelectedColor,
      backgroundColor: backgroundColor,
      padding: padding,
      isEnabled: isEnabled,
      materialTapTargetSize: materialTapTargetSize,
      elevation: elevation,
      shadowColor: shadowColor,
      selectedShadowColor: selectedShadowColor,
      avatarBorder: avatarBorder,
    );
  }
}

class FilterChip extends StatelessWidget
    implements
        ChipAttributes,
        SelectableChipAttributes,
        DisabledChipAttributes {
  const FilterChip({
    Key key,
    this.avatar,
    @required this.label,
    this.labelStyle,
    this.labelPadding,
    this.selected = false,
    @required this.onSelected,
    this.pressElevation,
    this.disabledColor,
    this.selectedColor,
    this.tooltip,
    this.shape,
    this.clipBehavior = Clip.none,
    this.backgroundColor,
    this.padding,
    this.materialTapTargetSize,
    this.elevation,
    this.shadowColor,
    this.selectedShadowColor,
    this.avatarBorder = const CircleBorder(),
  })  : assert(selected != null),
        assert(label != null),
        assert(clipBehavior != null),
        assert(pressElevation == null || pressElevation >= 0.0),
        assert(elevation == null || elevation >= 0.0),
        super(key: key);

  @override
  final Widget avatar;
  @override
  final Widget label;
  @override
  final TextStyle labelStyle;
  @override
  final EdgeInsetsGeometry labelPadding;
  @override
  final bool selected;
  @override
  final ValueChanged<bool> onSelected;
  @override
  final double pressElevation;
  @override
  final Color disabledColor;
  @override
  final Color selectedColor;
  @override
  final String tooltip;
  @override
  final ShapeBorder shape;
  @override
  final Clip clipBehavior;
  @override
  final Color backgroundColor;
  @override
  final EdgeInsetsGeometry padding;
  @override
  final MaterialTapTargetSize materialTapTargetSize;
  @override
  final double elevation;
  @override
  final Color shadowColor;
  @override
  final Color selectedShadowColor;
  @override
  final ShapeBorder avatarBorder;

  @override
  bool get isEnabled => onSelected != null;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    return RawChip(
      avatar: avatar,
      label: label,
      labelStyle: labelStyle,
      labelPadding: labelPadding,
      onSelected: onSelected,
      pressElevation: pressElevation,
      selected: selected,
      tooltip: tooltip,
      shape: shape,
      clipBehavior: clipBehavior,
      backgroundColor: backgroundColor,
      disabledColor: disabledColor,
      selectedColor: selectedColor,
      padding: padding,
      isEnabled: isEnabled,
      materialTapTargetSize: materialTapTargetSize,
      elevation: elevation,
      shadowColor: shadowColor,
      selectedShadowColor: selectedShadowColor,
      avatarBorder: avatarBorder,
    );
  }
}

class ActionChip extends StatelessWidget
    implements ChipAttributes, TappableChipAttributes {
  const ActionChip({
    Key key,
    this.avatar,
    @required this.label,
    this.labelStyle,
    this.labelPadding,
    @required this.onPressed,
    this.pressElevation,
    this.tooltip,
    this.shape,
    this.clipBehavior = Clip.none,
    this.backgroundColor,
    this.padding,
    this.materialTapTargetSize,
    this.elevation,
    this.shadowColor,
  })  : assert(label != null),
        assert(
          onPressed != null,
          'Rather than disabling an ActionChip by setting onPressed to null, '
          'remove it from the interface entirely.',
        ),
        assert(pressElevation == null || pressElevation >= 0.0),
        assert(elevation == null || elevation >= 0.0),
        super(key: key);

  @override
  final Widget avatar;
  @override
  final Widget label;
  @override
  final TextStyle labelStyle;
  @override
  final EdgeInsetsGeometry labelPadding;
  @override
  final VoidCallback onPressed;
  @override
  final double pressElevation;
  @override
  final String tooltip;
  @override
  final ShapeBorder shape;
  @override
  final Clip clipBehavior;
  @override
  final Color backgroundColor;
  @override
  final EdgeInsetsGeometry padding;
  @override
  final MaterialTapTargetSize materialTapTargetSize;
  @override
  final double elevation;
  @override
  final Color shadowColor;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    return RawChip(
      avatar: avatar,
      label: label,
      onPressed: onPressed,
      pressElevation: pressElevation,
      tooltip: tooltip,
      labelStyle: labelStyle,
      backgroundColor: backgroundColor,
      shape: shape,
      clipBehavior: clipBehavior,
      padding: padding,
      labelPadding: labelPadding,
      isEnabled: true,
      materialTapTargetSize: materialTapTargetSize,
      elevation: elevation,
      shadowColor: shadowColor,
    );
  }
}

class RawChip extends StatefulWidget
    implements
        ChipAttributes,
        DeletableChipAttributes,
        SelectableChipAttributes,
        DisabledChipAttributes,
        TappableChipAttributes {
  const RawChip({
    Key key,
    this.avatar,
    @required this.label,
    this.labelStyle,
    this.padding,
    this.labelPadding,
    Widget deleteIcon,
    this.onDeleted,
    this.deleteIconColor,
    this.deleteButtonTooltipMessage,
    this.onPressed,
    this.onSelected,
    this.pressElevation,
    this.tapEnabled = true,
    this.selected,
    this.showCheckmark = true,
    this.isEnabled = true,
    this.disabledColor,
    this.selectedColor,
    this.tooltip,
    this.shape,
    this.clipBehavior = Clip.none,
    this.backgroundColor,
    this.materialTapTargetSize,
    this.elevation,
    this.shadowColor,
    this.selectedShadowColor,
    this.avatarBorder = const CircleBorder(),
  })  : assert(label != null),
        assert(isEnabled != null),
        assert(clipBehavior != null),
        assert(pressElevation == null || pressElevation >= 0.0),
        assert(elevation == null || elevation >= 0.0),
        deleteIcon = deleteIcon ?? _kDefaultDeleteIcon,
        super(key: key);

  @override
  final Widget avatar;
  @override
  final Widget label;
  @override
  final TextStyle labelStyle;
  @override
  final EdgeInsetsGeometry labelPadding;
  @override
  final Widget deleteIcon;
  @override
  final VoidCallback onDeleted;
  @override
  final Color deleteIconColor;
  @override
  final String deleteButtonTooltipMessage;
  @override
  final ValueChanged<bool> onSelected;
  @override
  final VoidCallback onPressed;
  @override
  final double pressElevation;
  @override
  final bool selected;
  @override
  final bool isEnabled;
  @override
  final Color disabledColor;
  @override
  final Color selectedColor;
  @override
  final String tooltip;
  @override
  final ShapeBorder shape;
  @override
  final Clip clipBehavior;
  @override
  final Color backgroundColor;
  @override
  final EdgeInsetsGeometry padding;
  @override
  final MaterialTapTargetSize materialTapTargetSize;
  @override
  final double elevation;
  @override
  final Color shadowColor;
  @override
  final Color selectedShadowColor;
  @override
  final CircleBorder avatarBorder;

  final bool showCheckmark;

  final bool tapEnabled;

  @override
  _RawChipState createState() => _RawChipState();
}

class _RawChipState extends State<RawChip>
    with TickerProviderStateMixin<RawChip> {
  static const Duration pressedAnimationDuration = Duration(milliseconds: 75);

  AnimationController selectController;
  AnimationController avatarDrawerController;
  AnimationController deleteDrawerController;
  AnimationController enableController;
  Animation<double> checkmarkAnimation;
  Animation<double> avatarDrawerAnimation;
  Animation<double> deleteDrawerAnimation;
  Animation<double> enableAnimation;
  Animation<double> selectionFade;

  bool get hasDeleteButton => widget.onDeleted != null;
  bool get hasAvatar => widget.avatar != null;

  bool get canTap {
    return widget.isEnabled &&
        widget.tapEnabled &&
        (widget.onPressed != null || widget.onSelected != null);
  }

  bool _isTapping = false;
  bool get isTapping => !canTap ? false : _isTapping;

  @override
  void initState() {
    assert(widget.onSelected == null || widget.onPressed == null);
    super.initState();
    selectController = AnimationController(
      duration: _kSelectDuration,
      value: widget.selected == true ? 1.0 : 0.0,
      vsync: this,
    );
    selectionFade = CurvedAnimation(
      parent: selectController,
      curve: Curves.fastOutSlowIn,
    );
    avatarDrawerController = AnimationController(
      duration: _kDrawerDuration,
      value: hasAvatar || widget.selected == true ? 1.0 : 0.0,
      vsync: this,
    );
    deleteDrawerController = AnimationController(
      duration: _kDrawerDuration,
      value: hasDeleteButton ? 1.0 : 0.0,
      vsync: this,
    );
    enableController = AnimationController(
      duration: _kDisableDuration,
      value: widget.isEnabled ? 1.0 : 0.0,
      vsync: this,
    );

    final double checkmarkPercentage =
        _kCheckmarkDuration.inMilliseconds / _kSelectDuration.inMilliseconds;
    final double checkmarkReversePercentage =
        _kCheckmarkReverseDuration.inMilliseconds /
            _kSelectDuration.inMilliseconds;
    final double avatarDrawerReversePercentage =
        _kReverseDrawerDuration.inMilliseconds /
            _kSelectDuration.inMilliseconds;
    checkmarkAnimation = CurvedAnimation(
      parent: selectController,
      curve:
          Interval(1.0 - checkmarkPercentage, 1.0, curve: Curves.fastOutSlowIn),
      reverseCurve: Interval(
        1.0 - checkmarkReversePercentage,
        1.0,
        curve: Curves.fastOutSlowIn,
      ),
    );
    deleteDrawerAnimation = CurvedAnimation(
      parent: deleteDrawerController,
      curve: Curves.fastOutSlowIn,
    );
    avatarDrawerAnimation = CurvedAnimation(
      parent: avatarDrawerController,
      curve: Curves.fastOutSlowIn,
      reverseCurve: Interval(
        1.0 - avatarDrawerReversePercentage,
        1.0,
        curve: Curves.fastOutSlowIn,
      ),
    );
    enableAnimation = CurvedAnimation(
      parent: enableController,
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  void dispose() {
    selectController.dispose();
    avatarDrawerController.dispose();
    deleteDrawerController.dispose();
    enableController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!canTap) {
      return;
    }
    setState(() {
      _isTapping = true;
    });
  }

  void _handleTapCancel() {
    if (!canTap) {
      return;
    }
    setState(() {
      _isTapping = false;
    });
  }

  void _handleTap() {
    if (!canTap) {
      return;
    }
    setState(() {
      _isTapping = false;
    });

    widget.onSelected?.call(!widget.selected);
    widget.onPressed?.call();
  }

  Color getBackgroundColor(ChipThemeData theme) {
    final ColorTween backgroundTween = ColorTween(
      begin: widget.disabledColor ?? theme.disabledColor,
      end: widget.backgroundColor ?? theme.backgroundColor,
    );
    final ColorTween selectTween = ColorTween(
      begin: backgroundTween.evaluate(enableController),
      end: widget.selectedColor ?? theme.selectedColor,
    );
    return selectTween.evaluate(selectionFade);
  }

  @override
  void didUpdateWidget(RawChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isEnabled != widget.isEnabled) {
      setState(() {
        if (widget.isEnabled) {
          enableController.forward();
        } else {
          enableController.reverse();
        }
      });
    }
    if (oldWidget.avatar != widget.avatar ||
        oldWidget.selected != widget.selected) {
      setState(() {
        if (hasAvatar || widget.selected == true) {
          avatarDrawerController.forward();
        } else {
          avatarDrawerController.reverse();
        }
      });
    }
    if (oldWidget.selected != widget.selected) {
      setState(() {
        if (widget.selected == true) {
          selectController.forward();
        } else {
          selectController.reverse();
        }
      });
    }
    if (oldWidget.onDeleted != widget.onDeleted) {
      setState(() {
        if (hasDeleteButton) {
          deleteDrawerController.forward();
        } else {
          deleteDrawerController.reverse();
        }
      });
    }
  }

  Widget _wrapWithTooltip(String tooltip, VoidCallback callback, Widget child) {
    if (child == null || callback == null || tooltip == null) {
      return child;
    }
    return Tooltip(
      message: tooltip,
      child: child,
    );
  }

  Widget _buildDeleteIcon(
      BuildContext context, ThemeData theme, ChipThemeData chipTheme) {
    if (!hasDeleteButton) {
      return null;
    }
    return _wrapWithTooltip(
      widget.deleteButtonTooltipMessage ??
          MaterialLocalizations.of(context)?.deleteButtonTooltip,
      widget.onDeleted,
      InkResponse(
        onTap: widget.isEnabled ? widget.onDeleted : null,
        child: IconTheme(
          data: theme.iconTheme.copyWith(
            color: widget.deleteIconColor ?? chipTheme.deleteIconColor,
          ),
          child: widget.deleteIcon,
        ),
      ),
    );
  }

  static const double _defaultElevation = 0.0;
  static const double _defaultPressElevation = 8.0;
  static const Color _defaultShadowColor = Colors.black;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    assert(debugCheckHasMediaQuery(context));
    assert(debugCheckHasDirectionality(context));
    assert(debugCheckHasMaterialLocalizations(context));

    final ThemeData theme = Theme.of(context);
    final ChipThemeData chipTheme = ChipTheme.of(context);
    final TextDirection textDirection = Directionality.of(context);
    final ShapeBorder shape = widget.shape ?? chipTheme.shape;
    final double elevation =
        widget.elevation ?? chipTheme.elevation ?? _defaultElevation;
    final double pressElevation = widget.pressElevation ??
        chipTheme.pressElevation ??
        _defaultPressElevation;
    final Color shadowColor =
        widget.shadowColor ?? chipTheme.shadowColor ?? _defaultShadowColor;
    final Color selectedShadowColor = widget.selectedShadowColor ??
        chipTheme.selectedShadowColor ??
        _defaultShadowColor;
    final bool selected = widget.selected ?? false;

    Widget result = Material(
      elevation: isTapping ? pressElevation : elevation,
      shadowColor: selected ? selectedShadowColor : shadowColor,
      animationDuration: pressedAnimationDuration,
      shape: shape,
      clipBehavior: widget.clipBehavior,
      child: InkWell(
        onTap: canTap ? _handleTap : null,
        onTapDown: canTap ? _handleTapDown : null,
        onTapCancel: canTap ? _handleTapCancel : null,
        customBorder: shape,
        child: AnimatedBuilder(
          animation: Listenable.merge(
              <Listenable>[selectController, enableController]),
          builder: (BuildContext context, Widget child) {
            return Container(
              decoration: ShapeDecoration(
                shape: shape,
                color: getBackgroundColor(chipTheme),
              ),
              child: child,
            );
          },
          child: _wrapWithTooltip(
            widget.tooltip,
            widget.onPressed,
            _ChipRenderWidget(
              theme: _ChipRenderTheme(
                label: DefaultTextStyle(
                  overflow: TextOverflow.fade,
                  textAlign: TextAlign.start,
                  maxLines: 1,
                  softWrap: false,
                  style: widget.labelStyle ?? chipTheme.labelStyle,
                  child: widget.label,
                ),
                avatar: AnimatedSwitcher(
                  child: widget.avatar,
                  duration: _kDrawerDuration,
                  switchInCurve: Curves.fastOutSlowIn,
                ),
                deleteIcon: AnimatedSwitcher(
                  child: _buildDeleteIcon(context, theme, chipTheme),
                  duration: _kDrawerDuration,
                  switchInCurve: Curves.fastOutSlowIn,
                ),
                brightness: chipTheme.brightness,
                padding: (widget.padding ?? chipTheme.padding)
                    .resolve(textDirection),
                labelPadding: (widget.labelPadding ?? chipTheme.labelPadding)
                    .resolve(textDirection),
                showAvatar: hasAvatar,
                showCheckmark: widget.showCheckmark,
                canTapBody: canTap,
              ),
              value: widget.selected,
              checkmarkAnimation: checkmarkAnimation,
              enableAnimation: enableAnimation,
              avatarDrawerAnimation: avatarDrawerAnimation,
              deleteDrawerAnimation: deleteDrawerAnimation,
              isEnabled: widget.isEnabled,
              avatarBorder: widget.avatarBorder,
            ),
          ),
        ),
      ),
    );
    BoxConstraints constraints;
    switch (widget.materialTapTargetSize ?? theme.materialTapTargetSize) {
      case MaterialTapTargetSize.padded:
        constraints = const BoxConstraints(minHeight: 48.0);
        break;
      case MaterialTapTargetSize.shrinkWrap:
        constraints = const BoxConstraints();
        break;
    }
    result = _ChipRedirectingHitDetectionWidget(
      constraints: constraints,
      child: Center(
        child: result,
        widthFactor: 1.0,
        heightFactor: 1.0,
      ),
    );
    return Semantics(
      container: true,
      selected: widget.selected,
      enabled: canTap ? widget.isEnabled : null,
      child: result,
    );
  }
}

class _ChipRedirectingHitDetectionWidget extends SingleChildRenderObjectWidget {
  const _ChipRedirectingHitDetectionWidget({
    Key key,
    Widget child,
    this.constraints,
  }) : super(key: key, child: child);

  final BoxConstraints constraints;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderChipRedirectingHitDetection(constraints);
  }

  @override
  void updateRenderObject(BuildContext context,
      covariant _RenderChipRedirectingHitDetection renderObject) {
    renderObject.additionalConstraints = constraints;
  }
}

class _RenderChipRedirectingHitDetection extends RenderConstrainedBox {
  _RenderChipRedirectingHitDetection(BoxConstraints additionalConstraints)
      : super(additionalConstraints: additionalConstraints);

  @override
  bool hitTest(BoxHitTestResult result, {Offset position}) {
    if (!size.contains(position)) return false;

    final Offset offset = Offset(position.dx, size.height / 2);
    return result.addWithRawTransform(
      transform: MatrixUtils.forceToPoint(offset),
      position: position,
      hitTest: (BoxHitTestResult result, Offset position) {
        assert(position == offset);
        return child.hitTest(result, position: offset);
      },
    );
  }
}

class _ChipRenderWidget extends RenderObjectWidget {
  const _ChipRenderWidget({
    Key key,
    @required this.theme,
    this.value,
    this.isEnabled,
    this.checkmarkAnimation,
    this.avatarDrawerAnimation,
    this.deleteDrawerAnimation,
    this.enableAnimation,
    this.avatarBorder,
  })  : assert(theme != null),
        super(key: key);

  final _ChipRenderTheme theme;
  final bool value;
  final bool isEnabled;
  final Animation<double> checkmarkAnimation;
  final Animation<double> avatarDrawerAnimation;
  final Animation<double> deleteDrawerAnimation;
  final Animation<double> enableAnimation;
  final ShapeBorder avatarBorder;

  @override
  _RenderChipElement createElement() => _RenderChipElement(this);

  @override
  void updateRenderObject(BuildContext context, _RenderChip renderObject) {
    renderObject
      ..theme = theme
      ..textDirection = Directionality.of(context)
      ..value = value
      ..isEnabled = isEnabled
      ..checkmarkAnimation = checkmarkAnimation
      ..avatarDrawerAnimation = avatarDrawerAnimation
      ..deleteDrawerAnimation = deleteDrawerAnimation
      ..enableAnimation = enableAnimation
      ..avatarBorder = avatarBorder;
  }

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderChip(
      theme: theme,
      textDirection: Directionality.of(context),
      value: value,
      isEnabled: isEnabled,
      checkmarkAnimation: checkmarkAnimation,
      avatarDrawerAnimation: avatarDrawerAnimation,
      deleteDrawerAnimation: deleteDrawerAnimation,
      enableAnimation: enableAnimation,
      avatarBorder: avatarBorder,
    );
  }
}

enum _ChipSlot {
  label,
  avatar,
  deleteIcon,
}

class _RenderChipElement extends RenderObjectElement {
  _RenderChipElement(_ChipRenderWidget chip) : super(chip);

  final Map<_ChipSlot, Element> slotToChild = <_ChipSlot, Element>{};
  final Map<Element, _ChipSlot> childToSlot = <Element, _ChipSlot>{};

  @override
  _ChipRenderWidget get widget => super.widget;

  @override
  _RenderChip get renderObject => super.renderObject;

  @override
  void visitChildren(ElementVisitor visitor) {
    slotToChild.values.forEach(visitor);
  }

  @override
  void forgetChild(Element child) {
    assert(slotToChild.values.contains(child));
    assert(childToSlot.keys.contains(child));
    final _ChipSlot slot = childToSlot[child];
    childToSlot.remove(child);
    slotToChild.remove(slot);
  }

  void _mountChild(Widget widget, _ChipSlot slot) {
    final Element oldChild = slotToChild[slot];
    final Element newChild = updateChild(oldChild, widget, slot);
    if (oldChild != null) {
      slotToChild.remove(slot);
      childToSlot.remove(oldChild);
    }
    if (newChild != null) {
      slotToChild[slot] = newChild;
      childToSlot[newChild] = slot;
    }
  }

  @override
  void mount(Element parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    _mountChild(widget.theme.avatar, _ChipSlot.avatar);
    _mountChild(widget.theme.deleteIcon, _ChipSlot.deleteIcon);
    _mountChild(widget.theme.label, _ChipSlot.label);
  }

  void _updateChild(Widget widget, _ChipSlot slot) {
    final Element oldChild = slotToChild[slot];
    final Element newChild = updateChild(oldChild, widget, slot);
    if (oldChild != null) {
      childToSlot.remove(oldChild);
      slotToChild.remove(slot);
    }
    if (newChild != null) {
      slotToChild[slot] = newChild;
      childToSlot[newChild] = slot;
    }
  }

  @override
  void update(_ChipRenderWidget newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    _updateChild(widget.theme.label, _ChipSlot.label);
    _updateChild(widget.theme.avatar, _ChipSlot.avatar);
    _updateChild(widget.theme.deleteIcon, _ChipSlot.deleteIcon);
  }

  void _updateRenderObject(RenderObject child, _ChipSlot slot) {
    switch (slot) {
      case _ChipSlot.avatar:
        renderObject.avatar = child;
        break;
      case _ChipSlot.label:
        renderObject.label = child;
        break;
      case _ChipSlot.deleteIcon:
        renderObject.deleteIcon = child;
        break;
    }
  }

  @override
  void insertChildRenderObject(RenderObject child, dynamic slotValue) {
    assert(child is RenderBox);
    assert(slotValue is _ChipSlot);
    final _ChipSlot slot = slotValue;
    _updateRenderObject(child, slot);
    assert(renderObject.childToSlot.keys.contains(child));
    assert(renderObject.slotToChild.keys.contains(slot));
  }

  @override
  void removeChildRenderObject(RenderObject child) {
    assert(child is RenderBox);
    assert(renderObject.childToSlot.keys.contains(child));
    _updateRenderObject(null, renderObject.childToSlot[child]);
    assert(!renderObject.childToSlot.keys.contains(child));
    assert(!renderObject.slotToChild.keys.contains(slot));
  }

  @override
  void moveChildRenderObject(RenderObject child, dynamic slotValue) {
    assert(false, 'not reachable');
  }
}

class _ChipRenderTheme {
  const _ChipRenderTheme({
    @required this.avatar,
    @required this.label,
    @required this.deleteIcon,
    @required this.brightness,
    @required this.padding,
    @required this.labelPadding,
    @required this.showAvatar,
    @required this.showCheckmark,
    @required this.canTapBody,
  });

  final Widget avatar;
  final Widget label;
  final Widget deleteIcon;
  final Brightness brightness;
  final EdgeInsets padding;
  final EdgeInsets labelPadding;
  final bool showAvatar;
  final bool showCheckmark;
  final bool canTapBody;

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    final _ChipRenderTheme typedOther = other;
    return typedOther.avatar == avatar &&
        typedOther.label == label &&
        typedOther.deleteIcon == deleteIcon &&
        typedOther.brightness == brightness &&
        typedOther.padding == padding &&
        typedOther.labelPadding == labelPadding &&
        typedOther.showAvatar == showAvatar &&
        typedOther.showCheckmark == showCheckmark &&
        typedOther.canTapBody == canTapBody;
  }

  @override
  int get hashCode {
    return hashValues(
      avatar,
      label,
      deleteIcon,
      brightness,
      padding,
      labelPadding,
      showAvatar,
      showCheckmark,
      canTapBody,
    );
  }
}

class _RenderChip extends RenderBox {
  _RenderChip({
    @required _ChipRenderTheme theme,
    @required TextDirection textDirection,
    this.value,
    this.isEnabled,
    this.checkmarkAnimation,
    this.avatarDrawerAnimation,
    this.deleteDrawerAnimation,
    this.enableAnimation,
    this.avatarBorder,
  })  : assert(theme != null),
        assert(textDirection != null),
        _theme = theme,
        _textDirection = textDirection {
    checkmarkAnimation.addListener(markNeedsPaint);
    avatarDrawerAnimation.addListener(markNeedsLayout);
    deleteDrawerAnimation.addListener(markNeedsLayout);
    enableAnimation.addListener(markNeedsPaint);
  }

  final Map<_ChipSlot, RenderBox> slotToChild = <_ChipSlot, RenderBox>{};
  final Map<RenderBox, _ChipSlot> childToSlot = <RenderBox, _ChipSlot>{};

  bool value;
  bool isEnabled;
  Rect deleteButtonRect;
  Rect pressRect;
  Animation<double> checkmarkAnimation;
  Animation<double> avatarDrawerAnimation;
  Animation<double> deleteDrawerAnimation;
  Animation<double> enableAnimation;
  ShapeBorder avatarBorder;

  RenderBox _updateChild(
      RenderBox oldChild, RenderBox newChild, _ChipSlot slot) {
    if (oldChild != null) {
      dropChild(oldChild);
      childToSlot.remove(oldChild);
      slotToChild.remove(slot);
    }
    if (newChild != null) {
      childToSlot[newChild] = slot;
      slotToChild[slot] = newChild;
      adoptChild(newChild);
    }
    return newChild;
  }

  RenderBox _avatar;
  RenderBox get avatar => _avatar;
  set avatar(RenderBox value) {
    _avatar = _updateChild(_avatar, value, _ChipSlot.avatar);
  }

  RenderBox _deleteIcon;
  RenderBox get deleteIcon => _deleteIcon;
  set deleteIcon(RenderBox value) {
    _deleteIcon = _updateChild(_deleteIcon, value, _ChipSlot.deleteIcon);
  }

  RenderBox _label;
  RenderBox get label => _label;
  set label(RenderBox value) {
    _label = _updateChild(_label, value, _ChipSlot.label);
  }

  _ChipRenderTheme get theme => _theme;
  _ChipRenderTheme _theme;
  set theme(_ChipRenderTheme value) {
    if (_theme == value) {
      return;
    }
    _theme = value;
    markNeedsLayout();
  }

  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (_textDirection == value) {
      return;
    }
    _textDirection = value;
    markNeedsLayout();
  }

  Iterable<RenderBox> get _children sync* {
    if (avatar != null) {
      yield avatar;
    }
    if (label != null) {
      yield label;
    }
    if (deleteIcon != null) {
      yield deleteIcon;
    }
  }

  bool get isDrawingCheckmark =>
      theme.showCheckmark && !(checkmarkAnimation?.isDismissed ?? !value);
  bool get deleteIconShowing => !deleteDrawerAnimation.isDismissed;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    for (RenderBox child in _children) {
      child.attach(owner);
    }
  }

  @override
  void detach() {
    super.detach();
    for (RenderBox child in _children) {
      child.detach();
    }
  }

  @override
  void redepthChildren() {
    _children.forEach(redepthChild);
  }

  @override
  void visitChildren(RenderObjectVisitor visitor) {
    _children.forEach(visitor);
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    final List<DiagnosticsNode> value = <DiagnosticsNode>[];
    void add(RenderBox child, String name) {
      if (child != null) {
        value.add(child.toDiagnosticsNode(name: name));
      }
    }

    add(avatar, 'avatar');
    add(label, 'label');
    add(deleteIcon, 'deleteIcon');
    return value;
  }

  @override
  bool get sizedByParent => false;

  static double _minWidth(RenderBox box, double height) {
    return box == null ? 0.0 : box.getMinIntrinsicWidth(height);
  }

  static double _maxWidth(RenderBox box, double height) {
    return box == null ? 0.0 : box.getMaxIntrinsicWidth(height);
  }

  static double _minHeight(RenderBox box, double width) {
    return box == null ? 0.0 : box.getMinIntrinsicHeight(width);
  }

  static Size _boxSize(RenderBox box) => box == null ? Size.zero : box.size;

  static Rect _boxRect(RenderBox box) =>
      box == null ? Rect.zero : _boxParentData(box).offset & box.size;

  static BoxParentData _boxParentData(RenderBox box) => box.parentData;

  @override
  double computeMinIntrinsicWidth(double height) {
    final double overallPadding =
        theme.padding.horizontal + theme.labelPadding.horizontal;
    return overallPadding +
        _minWidth(avatar, height) +
        _minWidth(label, height) +
        _minWidth(deleteIcon, height);
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    final double overallPadding =
        theme.padding.vertical + theme.labelPadding.horizontal;
    return overallPadding +
        _maxWidth(avatar, height) +
        _maxWidth(label, height) +
        _maxWidth(deleteIcon, height);
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return math.max(
      _kChipHeight,
      theme.padding.vertical +
          theme.labelPadding.vertical +
          _minHeight(label, width),
    );
  }

  @override
  double computeMaxIntrinsicHeight(double width) =>
      computeMinIntrinsicHeight(width);

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    return label.getDistanceToActualBaseline(baseline);
  }

  Size _layoutLabel(double iconSizes, Size size) {
    final Size rawSize = _boxSize(label);

    if (constraints.maxWidth.isFinite) {
      final double maxWidth = math.max(
        0.0,
        constraints.maxWidth -
            iconSizes -
            theme.labelPadding.horizontal -
            theme.padding.horizontal,
      );
      label.layout(
        constraints.copyWith(
          minWidth: 0.0,
          maxWidth: maxWidth,
          minHeight: rawSize.height,
          maxHeight: size.height,
        ),
        parentUsesSize: true,
      );

      final Size updatedSize = _boxSize(label);
      return Size(
        updatedSize.width + theme.labelPadding.horizontal,
        updatedSize.height + theme.labelPadding.vertical,
      );
    }

    label.layout(
      BoxConstraints(
        minHeight: rawSize.height,
        maxHeight: size.height,
        minWidth: 0.0,
        maxWidth: size.width,
      ),
      parentUsesSize: true,
    );

    return Size(
      rawSize.width + theme.labelPadding.horizontal,
      rawSize.height + theme.labelPadding.vertical,
    );
  }

  Size _layoutAvatar(BoxConstraints contentConstraints, double contentSize) {
    final double requestedSize = math.max(0.0, contentSize);
    final BoxConstraints avatarConstraints = BoxConstraints.tightFor(
      width: requestedSize,
      height: requestedSize,
    );
    avatar.layout(avatarConstraints, parentUsesSize: true);
    if (!theme.showCheckmark && !theme.showAvatar) {
      return Size(0.0, contentSize);
    }
    double avatarWidth = 0.0;
    double avatarHeight = 0.0;
    final Size avatarBoxSize = _boxSize(avatar);
    if (theme.showAvatar) {
      avatarWidth += avatarDrawerAnimation.value * avatarBoxSize.width;
    } else {
      avatarWidth += avatarDrawerAnimation.value * contentSize;
    }
    avatarHeight += avatarBoxSize.height;
    return Size(avatarWidth, avatarHeight);
  }

  Size _layoutDeleteIcon(
      BoxConstraints contentConstraints, double contentSize) {
    final double requestedSize = math.max(0.0, contentSize);
    final BoxConstraints deleteIconConstraints = BoxConstraints.tightFor(
      width: requestedSize,
      height: requestedSize,
    );
    deleteIcon.layout(deleteIconConstraints, parentUsesSize: true);
    if (!deleteIconShowing) {
      return Size(0.0, contentSize);
    }
    double deleteIconWidth = 0.0;
    double deleteIconHeight = 0.0;
    final Size boxSize = _boxSize(deleteIcon);
    deleteIconWidth += deleteDrawerAnimation.value * boxSize.width;
    deleteIconHeight += boxSize.height;
    return Size(deleteIconWidth, deleteIconHeight);
  }

  @override
  bool hitTest(BoxHitTestResult result, {Offset position}) {
    if (!size.contains(position)) return false;
    RenderBox hitTestChild;
    switch (textDirection) {
      case TextDirection.ltr:
        if (position.dx / size.width > 0.66)
          hitTestChild = deleteIcon ?? label ?? avatar;
        else
          hitTestChild = label ?? avatar;
        break;
      case TextDirection.rtl:
        if (position.dx / size.width < 0.33)
          hitTestChild = deleteIcon ?? label ?? avatar;
        else
          hitTestChild = label ?? avatar;
        break;
    }
    if (hitTestChild != null) {
      final Offset center = hitTestChild.size.center(Offset.zero);
      return result.addWithRawTransform(
        transform: MatrixUtils.forceToPoint(center),
        position: position,
        hitTest: (BoxHitTestResult result, Offset position) {
          assert(position == center);
          return hitTestChild.hitTest(result, position: center);
        },
      );
    }
    return false;
  }

  @override
  void performLayout() {
    final BoxConstraints contentConstraints = constraints.loosen();

    label.layout(contentConstraints, parentUsesSize: true);
    final double contentSize = math.max(
      _kChipHeight - theme.padding.vertical + theme.labelPadding.vertical,
      _boxSize(label).height + theme.labelPadding.vertical,
    );
    final Size avatarSize = _layoutAvatar(contentConstraints, contentSize);
    final Size deleteIconSize =
        _layoutDeleteIcon(contentConstraints, contentSize);
    Size labelSize = Size(_boxSize(label).width, contentSize);
    labelSize =
        _layoutLabel(avatarSize.width + deleteIconSize.width, labelSize);

    final Size overallSize = Size(
      avatarSize.width + labelSize.width + deleteIconSize.width,
      contentSize,
    );

    const double left = 0.0;
    final double right = overallSize.width;

    Offset centerLayout(Size boxSize, double x) {
      assert(contentSize >= boxSize.height);
      Offset boxOffset;
      switch (textDirection) {
        case TextDirection.rtl:
          boxOffset =
              Offset(x - boxSize.width, (contentSize - boxSize.height) / 2.0);
          break;
        case TextDirection.ltr:
          boxOffset = Offset(x, (contentSize - boxSize.height) / 2.0);
          break;
      }
      return boxOffset;
    }

    Offset avatarOffset = Offset.zero;
    Offset labelOffset = Offset.zero;
    Offset deleteIconOffset = Offset.zero;
    switch (textDirection) {
      case TextDirection.rtl:
        double start = right;
        if (theme.showCheckmark || theme.showAvatar) {
          avatarOffset = centerLayout(avatarSize, start);
          start -= avatarSize.width;
        }
        labelOffset = centerLayout(labelSize, start);
        start -= labelSize.width;
        if (deleteIconShowing) {
          deleteButtonRect = Rect.fromLTWH(
            0.0,
            0.0,
            deleteIconSize.width + theme.padding.right,
            overallSize.height + theme.padding.vertical,
          );
          deleteIconOffset = centerLayout(deleteIconSize, start);
        } else {
          deleteButtonRect = Rect.zero;
        }
        start -= deleteIconSize.width;
        if (theme.canTapBody) {
          pressRect = Rect.fromLTWH(
            deleteButtonRect.width,
            0.0,
            overallSize.width -
                deleteButtonRect.width +
                theme.padding.horizontal,
            overallSize.height + theme.padding.vertical,
          );
        } else {
          pressRect = Rect.zero;
        }
        break;
      case TextDirection.ltr:
        double start = left;
        if (theme.showCheckmark || theme.showAvatar) {
          avatarOffset = centerLayout(
              avatarSize, start - _boxSize(avatar).width + avatarSize.width);
          start += avatarSize.width;
        }
        labelOffset = centerLayout(labelSize, start);
        start += labelSize.width;
        if (theme.canTapBody) {
          pressRect = Rect.fromLTWH(
            0.0,
            0.0,
            deleteIconShowing
                ? start + theme.padding.left
                : overallSize.width + theme.padding.horizontal,
            overallSize.height + theme.padding.vertical,
          );
        } else {
          pressRect = Rect.zero;
        }
        start -= _boxSize(deleteIcon).width - deleteIconSize.width;
        if (deleteIconShowing) {
          deleteIconOffset = centerLayout(deleteIconSize, start);
          deleteButtonRect = Rect.fromLTWH(
            start + theme.padding.left,
            0.0,
            deleteIconSize.width + theme.padding.right,
            overallSize.height + theme.padding.vertical,
          );
        } else {
          deleteButtonRect = Rect.zero;
        }
        break;
    }

    labelOffset = labelOffset +
        Offset(
          0.0,
          ((labelSize.height - theme.labelPadding.vertical) -
                  _boxSize(label).height) /
              2.0,
        );
    _boxParentData(avatar).offset = theme.padding.topLeft + avatarOffset;
    _boxParentData(label).offset =
        theme.padding.topLeft + labelOffset + theme.labelPadding.topLeft;
    _boxParentData(deleteIcon).offset =
        theme.padding.topLeft + deleteIconOffset;
    final Size paddedSize = Size(
      overallSize.width + theme.padding.horizontal,
      overallSize.height + theme.padding.vertical,
    );
    size = constraints.constrain(paddedSize);
    assert(
        size.height == constraints.constrainHeight(paddedSize.height),
        "Constrained height ${size.height} doesn't match expected height "
        '${constraints.constrainWidth(paddedSize.height)}');
    assert(
        size.width == constraints.constrainWidth(paddedSize.width),
        "Constrained width ${size.width} doesn't match expected width "
        '${constraints.constrainWidth(paddedSize.width)}');
  }

  static final ColorTween selectionScrimTween = ColorTween(
    begin: Colors.transparent,
    end: _kSelectScrimColor,
  );

  Color get _disabledColor {
    if (enableAnimation == null || enableAnimation.isCompleted) {
      return Colors.white;
    }
    ColorTween enableTween;
    switch (theme.brightness) {
      case Brightness.light:
        enableTween = ColorTween(
          begin: Colors.white.withAlpha(_kDisabledAlpha),
          end: Colors.white,
        );
        break;
      case Brightness.dark:
        enableTween = ColorTween(
          begin: Colors.black.withAlpha(_kDisabledAlpha),
          end: Colors.black,
        );
        break;
    }
    return enableTween.evaluate(enableAnimation);
  }

  void _paintCheck(Canvas canvas, Offset origin, double size) {
    Color paintColor;
    switch (theme.brightness) {
      case Brightness.light:
        paintColor = theme.showAvatar
            ? Colors.white
            : Colors.black.withAlpha(_kCheckmarkAlpha);
        break;
      case Brightness.dark:
        paintColor = theme.showAvatar
            ? Colors.black
            : Colors.white.withAlpha(_kCheckmarkAlpha);
        break;
    }

    final ColorTween fadeTween =
        ColorTween(begin: Colors.transparent, end: paintColor);

    paintColor = checkmarkAnimation.status == AnimationStatus.reverse
        ? fadeTween.evaluate(checkmarkAnimation)
        : paintColor;

    final Paint paint = Paint()
      ..color = paintColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _kCheckmarkStrokeWidth *
          (avatar != null ? avatar.size.height / 24.0 : 1.0);
    final double t = checkmarkAnimation.status == AnimationStatus.reverse
        ? 1.0
        : checkmarkAnimation.value;
    if (t == 0.0) {
      return;
    }
    assert(t > 0.0 && t <= 1.0);

    final Path path = Path();
    final Offset start = Offset(size * 0.15, size * 0.45);
    final Offset mid = Offset(size * 0.4, size * 0.7);
    final Offset end = Offset(size * 0.85, size * 0.25);
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

  void _paintSelectionOverlay(PaintingContext context, Offset offset) {
    if (isDrawingCheckmark) {
      if (theme.showAvatar) {
        final Rect avatarRect = _boxRect(avatar).shift(offset);
        final Paint darkenPaint = Paint()
          ..color = selectionScrimTween.evaluate(checkmarkAnimation)
          ..blendMode = BlendMode.srcATop;
        final Path path = avatarBorder.getOuterPath(avatarRect);
        context.canvas.drawPath(path, darkenPaint);
      }

      final double checkSize = avatar.size.height * 0.75;
      final Offset checkOffset = _boxParentData(avatar).offset +
          Offset(avatar.size.height * 0.125, avatar.size.height * 0.125);
      _paintCheck(context.canvas, offset + checkOffset, checkSize);
    }
  }

  void _paintAvatar(PaintingContext context, Offset offset) {
    void paintWithOverlay(PaintingContext context, Offset offset) {
      context.paintChild(avatar, _boxParentData(avatar).offset + offset);
      _paintSelectionOverlay(context, offset);
    }

    if (theme.showAvatar == false && avatarDrawerAnimation.isDismissed) {
      return;
    }
    final Color disabledColor = _disabledColor;
    final int disabledColorAlpha = disabledColor.alpha;
    if (needsCompositing) {
      context.pushLayer(
          OpacityLayer(alpha: disabledColorAlpha), paintWithOverlay, offset);
    } else {
      if (disabledColorAlpha != 0xff) {
        context.canvas.saveLayer(
          _boxRect(avatar).shift(offset).inflate(20.0),
          Paint()..color = disabledColor,
        );
      }
      paintWithOverlay(context, offset);
      if (disabledColorAlpha != 0xff) {
        context.canvas.restore();
      }
    }
  }

  void _paintChild(
      PaintingContext context, Offset offset, RenderBox child, bool isEnabled) {
    if (child == null) {
      return;
    }
    final int disabledColorAlpha = _disabledColor.alpha;
    if (!enableAnimation.isCompleted) {
      if (needsCompositing) {
        context.pushLayer(
          OpacityLayer(alpha: disabledColorAlpha),
          (PaintingContext context, Offset offset) {
            context.paintChild(child, _boxParentData(child).offset + offset);
          },
          offset,
        );
      } else {
        final Rect childRect = _boxRect(child).shift(offset);
        context.canvas.saveLayer(
            childRect.inflate(20.0), Paint()..color = _disabledColor);
        context.paintChild(child, _boxParentData(child).offset + offset);
        context.canvas.restore();
      }
    } else {
      context.paintChild(child, _boxParentData(child).offset + offset);
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    _paintAvatar(context, offset);
    if (deleteIconShowing) {
      _paintChild(context, offset, deleteIcon, isEnabled);
    }
    _paintChild(context, offset, label, isEnabled);
  }

  static const bool _debugShowTapTargetOutlines = false;

  @override
  void debugPaint(PaintingContext context, Offset offset) {
    assert(!_debugShowTapTargetOutlines ||
        () {
          final Paint outlinePaint = Paint()
            ..color = const Color(0xff800000)
            ..strokeWidth = 1.0
            ..style = PaintingStyle.stroke;
          if (deleteIconShowing) {
            context.canvas
                .drawRect(deleteButtonRect.shift(offset), outlinePaint);
          }
          context.canvas.drawRect(
            pressRect.shift(offset),
            outlinePaint..color = const Color(0xff008000),
          );
          return true;
        }());
  }

  @override
  bool hitTestSelf(Offset position) =>
      deleteButtonRect.contains(position) || pressRect.contains(position);
}

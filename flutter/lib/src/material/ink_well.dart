import 'dart:collection';

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/gestures.dart';
import 'package:flutter_web/rendering.dart';
import 'package:flutter_web/widgets.dart';

import 'debug.dart';
import 'feedback.dart';
import 'ink_highlight.dart';
import 'material.dart';
import 'theme.dart';

abstract class InteractiveInkFeature extends InkFeature {
  InteractiveInkFeature({
    @required MaterialInkController controller,
    @required RenderBox referenceBox,
    Color color,
    VoidCallback onRemoved,
  })  : assert(controller != null),
        assert(referenceBox != null),
        _color = color,
        super(
            controller: controller,
            referenceBox: referenceBox,
            onRemoved: onRemoved);

  void confirm() {}

  void cancel() {}

  Color get color => _color;
  Color _color;
  set color(Color value) {
    if (value == _color) return;
    _color = value;
    controller.markNeedsPaint();
  }
}

abstract class InteractiveInkFeatureFactory {
  const InteractiveInkFeatureFactory();

  InteractiveInkFeature create({
    @required MaterialInkController controller,
    @required RenderBox referenceBox,
    @required Offset position,
    @required Color color,
    @required TextDirection textDirection,
    bool containedInkWell = false,
    RectCallback rectCallback,
    BorderRadius borderRadius,
    ShapeBorder customBorder,
    double radius,
    VoidCallback onRemoved,
  });
}

class InkResponse extends StatefulWidget {
  const InkResponse({
    Key key,
    this.child,
    this.onTap,
    this.onTapDown,
    this.onTapCancel,
    this.onDoubleTap,
    this.onLongPress,
    this.onHighlightChanged,
    this.onHover,
    this.containedInkWell = false,
    this.highlightShape = BoxShape.circle,
    this.radius,
    this.borderRadius,
    this.customBorder,
    this.focusColor,
    this.hoverColor,
    this.highlightColor,
    this.splashColor,
    this.splashFactory,
    this.enableFeedback = true,
    this.excludeFromSemantics = false,
  })  : assert(containedInkWell != null),
        assert(highlightShape != null),
        assert(enableFeedback != null),
        assert(excludeFromSemantics != null),
        super(key: key);

  final Widget child;

  final GestureTapCallback onTap;

  final GestureTapDownCallback onTapDown;

  final GestureTapCallback onTapCancel;

  final GestureTapCallback onDoubleTap;

  final GestureLongPressCallback onLongPress;

  final ValueChanged<bool> onHighlightChanged;

  final ValueChanged<bool> onHover;

  final bool containedInkWell;

  final BoxShape highlightShape;

  final double radius;

  final BorderRadius borderRadius;

  final ShapeBorder customBorder;

  final Color focusColor;

  final Color hoverColor;

  final Color highlightColor;

  final Color splashColor;

  final InteractiveInkFeatureFactory splashFactory;

  final bool enableFeedback;

  final bool excludeFromSemantics;

  RectCallback getRectCallback(RenderBox referenceBox) => null;

  @mustCallSuper
  bool debugCheckContext(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    assert(debugCheckHasDirectionality(context));
    return true;
  }

  @override
  _InkResponseState<InkResponse> createState() =>
      _InkResponseState<InkResponse>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    final List<String> gestures = <String>[];
    if (onTap != null) gestures.add('tap');
    if (onDoubleTap != null) gestures.add('double tap');
    if (onLongPress != null) gestures.add('long press');
    if (onTapDown != null) gestures.add('tap down');
    if (onTapCancel != null) gestures.add('tap cancel');
    properties
        .add(IterableProperty<String>('gestures', gestures, ifEmpty: '<none>'));
    properties.add(DiagnosticsProperty<bool>(
        'containedInkWell', containedInkWell,
        level: DiagnosticLevel.fine));
    properties.add(DiagnosticsProperty<BoxShape>(
      'highlightShape',
      highlightShape,
      description: '${containedInkWell ? "clipped to " : ""}$highlightShape',
      showName: false,
    ));
  }
}

enum _HighlightType {
  pressed,
  hover,
  focus,
}

class _InkResponseState<T extends InkResponse> extends State<T>
    with AutomaticKeepAliveClientMixin<T> {
  Set<InteractiveInkFeature> _splashes;
  InteractiveInkFeature _currentSplash;
  FocusNode _focusNode;
  bool _hovering = false;
  final Map<_HighlightType, InkHighlight> _highlights =
      <_HighlightType, InkHighlight>{};

  bool get highlightsExist => _highlights.values
      .where((InkHighlight highlight) => highlight != null)
      .isNotEmpty;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _focusNode?.removeListener(_handleFocusUpdate);
    _focusNode = Focus.of(context, nullOk: true);
    _focusNode?.addListener(_handleFocusUpdate);
  }

  @override
  void didUpdateWidget(InkResponse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isWidgetEnabled(widget) != _isWidgetEnabled(oldWidget)) {
      _handleHoverChange(_hovering);
      _handleFocusUpdate();
    }
  }

  @override
  void dispose() {
    _focusNode?.removeListener(_handleFocusUpdate);
    super.dispose();
  }

  @override
  bool get wantKeepAlive =>
      highlightsExist || (_splashes != null && _splashes.isNotEmpty);

  Color getHighlightColorForType(_HighlightType type) {
    switch (type) {
      case _HighlightType.pressed:
        return widget.highlightColor ?? Theme.of(context).highlightColor;
      case _HighlightType.focus:
        return widget.focusColor ?? Theme.of(context).focusColor;
      case _HighlightType.hover:
        return widget.hoverColor ?? Theme.of(context).hoverColor;
    }
    assert(false, 'Unhandled $_HighlightType $type');
    return null;
  }

  Duration getFadeDurationForType(_HighlightType type) {
    switch (type) {
      case _HighlightType.pressed:
        return const Duration(milliseconds: 200);
      case _HighlightType.hover:
      case _HighlightType.focus:
        return const Duration(milliseconds: 50);
    }
    assert(false, 'Unhandled $_HighlightType $type');
    return null;
  }

  void updateHighlight(_HighlightType type, {@required bool value}) {
    final InkHighlight highlight = _highlights[type];
    void handleInkRemoval() {
      assert(_highlights[type] != null);
      _highlights[type] = null;
      updateKeepAlive();
    }

    if (value == (highlight != null && highlight.active)) return;
    if (value) {
      if (highlight == null) {
        final RenderBox referenceBox = context.findRenderObject();
        _highlights[type] = InkHighlight(
          controller: Material.of(context),
          referenceBox: referenceBox,
          color: getHighlightColorForType(type),
          shape: widget.highlightShape,
          borderRadius: widget.borderRadius,
          customBorder: widget.customBorder,
          rectCallback: widget.getRectCallback(referenceBox),
          onRemoved: handleInkRemoval,
          textDirection: Directionality.of(context),
          fadeDuration: getFadeDurationForType(type),
        );
        updateKeepAlive();
      } else {
        highlight.activate();
      }
    } else {
      highlight.deactivate();
    }
    assert(value == (_highlights[type] != null && _highlights[type].active));

    switch (type) {
      case _HighlightType.pressed:
        if (widget.onHighlightChanged != null) widget.onHighlightChanged(value);
        break;
      case _HighlightType.hover:
        if (widget.onHover != null) widget.onHover(value);
        break;
      case _HighlightType.focus:
        break;
    }
  }

  InteractiveInkFeature _createInkFeature(TapDownDetails details) {
    final MaterialInkController inkController = Material.of(context);
    final RenderBox referenceBox = context.findRenderObject();
    final Offset position = referenceBox.globalToLocal(details.globalPosition);
    final Color color = widget.splashColor ?? Theme.of(context).splashColor;
    final RectCallback rectCallback =
        widget.containedInkWell ? widget.getRectCallback(referenceBox) : null;
    final BorderRadius borderRadius = widget.borderRadius;
    final ShapeBorder customBorder = widget.customBorder;

    InteractiveInkFeature splash;
    void onRemoved() {
      if (_splashes != null) {
        assert(_splashes.contains(splash));
        _splashes.remove(splash);
        if (_currentSplash == splash) _currentSplash = null;
        updateKeepAlive();
      }
    }

    splash = (widget.splashFactory ?? Theme.of(context).splashFactory).create(
      controller: inkController,
      referenceBox: referenceBox,
      position: position,
      color: color,
      containedInkWell: widget.containedInkWell,
      rectCallback: rectCallback,
      radius: widget.radius,
      borderRadius: borderRadius,
      customBorder: customBorder,
      onRemoved: onRemoved,
      textDirection: Directionality.of(context),
    );

    return splash;
  }

  void _handleFocusUpdate() {
    final bool showFocus =
        enabled && (Focus.of(context, nullOk: true)?.hasPrimaryFocus ?? false);
    updateHighlight(_HighlightType.focus, value: showFocus);
  }

  void _handleTapDown(TapDownDetails details) {
    final InteractiveInkFeature splash = _createInkFeature(details);
    _splashes ??= HashSet<InteractiveInkFeature>();
    _splashes.add(splash);
    _currentSplash = splash;
    if (widget.onTapDown != null) {
      widget.onTapDown(details);
    }
    updateKeepAlive();
    updateHighlight(_HighlightType.pressed, value: true);
  }

  void _handleTap(BuildContext context) {
    _currentSplash?.confirm();
    _currentSplash = null;
    updateHighlight(_HighlightType.pressed, value: false);
    if (widget.onTap != null) {
      if (widget.enableFeedback) Feedback.forTap(context);
      widget.onTap();
    }
  }

  void _handleTapCancel() {
    _currentSplash?.cancel();
    _currentSplash = null;
    if (widget.onTapCancel != null) {
      widget.onTapCancel();
    }
    updateHighlight(_HighlightType.pressed, value: false);
  }

  void _handleDoubleTap() {
    _currentSplash?.confirm();
    _currentSplash = null;
    if (widget.onDoubleTap != null) widget.onDoubleTap();
  }

  void _handleLongPress(BuildContext context) {
    _currentSplash?.confirm();
    _currentSplash = null;
    if (widget.onLongPress != null) {
      if (widget.enableFeedback) Feedback.forLongPress(context);
      widget.onLongPress();
    }
  }

  @override
  void deactivate() {
    if (_splashes != null) {
      final Set<InteractiveInkFeature> splashes = _splashes;
      _splashes = null;
      for (InteractiveInkFeature splash in splashes) splash.dispose();
      _currentSplash = null;
    }
    assert(_currentSplash == null);
    for (_HighlightType highlight in _highlights.keys) {
      _highlights[highlight]?.dispose();
      _highlights[highlight] = null;
    }
    super.deactivate();
  }

  bool _isWidgetEnabled(InkResponse widget) {
    return widget.onTap != null ||
        widget.onDoubleTap != null ||
        widget.onLongPress != null;
  }

  bool get enabled => _isWidgetEnabled(widget);

  void _handleMouseEnter(PointerEnterEvent event) => _handleHoverChange(true);
  void _handleMouseExit(PointerExitEvent event) => _handleHoverChange(false);
  void _handleHoverChange(bool hovering) {
    if (_hovering != hovering) {
      _hovering = hovering;
      updateHighlight(_HighlightType.hover, value: enabled && _hovering);
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(widget.debugCheckContext(context));
    super.build(context);
    for (_HighlightType type in _highlights.keys) {
      _highlights[type]?.color = getHighlightColorForType(type);
    }
    _currentSplash?.color = widget.splashColor ?? Theme.of(context).splashColor;
    return MouseRegion(
      onEnter: enabled ? _handleMouseEnter : null,
      onExit: enabled ? _handleMouseExit : null,
      child: GestureDetector(
        onTapDown: enabled ? _handleTapDown : null,
        onTap: enabled ? () => _handleTap(context) : null,
        onTapCancel: enabled ? _handleTapCancel : null,
        onDoubleTap: widget.onDoubleTap != null ? _handleDoubleTap : null,
        onLongPress:
            widget.onLongPress != null ? () => _handleLongPress(context) : null,
        behavior: HitTestBehavior.opaque,
        child: widget.child,
        excludeFromSemantics: widget.excludeFromSemantics,
      ),
    );
  }
}

class InkWell extends InkResponse {
  const InkWell({
    Key key,
    Widget child,
    GestureTapCallback onTap,
    GestureTapCallback onDoubleTap,
    GestureLongPressCallback onLongPress,
    GestureTapDownCallback onTapDown,
    GestureTapCancelCallback onTapCancel,
    ValueChanged<bool> onHighlightChanged,
    ValueChanged<bool> onHover,
    Color focusColor,
    Color hoverColor,
    Color highlightColor,
    Color splashColor,
    InteractiveInkFeatureFactory splashFactory,
    double radius,
    BorderRadius borderRadius,
    ShapeBorder customBorder,
    bool enableFeedback = true,
    bool excludeFromSemantics = false,
  }) : super(
          key: key,
          child: child,
          onTap: onTap,
          onDoubleTap: onDoubleTap,
          onLongPress: onLongPress,
          onTapDown: onTapDown,
          onTapCancel: onTapCancel,
          onHighlightChanged: onHighlightChanged,
          onHover: onHover,
          containedInkWell: true,
          highlightShape: BoxShape.rectangle,
          focusColor: focusColor,
          hoverColor: hoverColor,
          highlightColor: highlightColor,
          splashColor: splashColor,
          splashFactory: splashFactory,
          radius: radius,
          borderRadius: borderRadius,
          customBorder: customBorder,
          enableFeedback: enableFeedback ?? true,
          excludeFromSemantics: excludeFromSemantics ?? false,
        );
}

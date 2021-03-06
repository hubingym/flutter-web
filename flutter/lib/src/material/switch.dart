import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/gestures.dart';
import 'package:flutter_web/rendering.dart';
import 'package:flutter_web/widgets.dart';

import 'colors.dart';
import 'constants.dart';
import 'debug.dart';
import 'shadows.dart';
import 'theme.dart';
import 'theme_data.dart';
import 'toggleable.dart';

const double _kTrackHeight = 14.0;
const double _kTrackWidth = 33.0;
const double _kTrackRadius = _kTrackHeight / 2.0;
const double _kThumbRadius = 10.0;
const double _kSwitchWidth =
    _kTrackWidth - 2 * _kTrackRadius + 2 * kRadialReactionRadius;
const double _kSwitchHeight = 2 * kRadialReactionRadius + 8.0;
const double _kSwitchHeightCollapsed = 2 * kRadialReactionRadius;

enum _SwitchType { material, adaptive }

class Switch extends StatefulWidget {
  const Switch({
    Key key,
    @required this.value,
    @required this.onChanged,
    this.activeColor,
    this.activeTrackColor,
    this.inactiveThumbColor,
    this.inactiveTrackColor,
    this.activeThumbImage,
    this.inactiveThumbImage,
    this.materialTapTargetSize,
    this.dragStartBehavior = DragStartBehavior.start,
  })  : _switchType = _SwitchType.material,
        assert(dragStartBehavior != null),
        super(key: key);

  const Switch.adaptive({
    Key key,
    @required this.value,
    @required this.onChanged,
    this.activeColor,
    this.activeTrackColor,
    this.inactiveThumbColor,
    this.inactiveTrackColor,
    this.activeThumbImage,
    this.inactiveThumbImage,
    this.materialTapTargetSize,
    this.dragStartBehavior = DragStartBehavior.start,
  })  : _switchType = _SwitchType.adaptive,
        super(key: key);

  final bool value;

  final ValueChanged<bool> onChanged;

  final Color activeColor;

  final Color activeTrackColor;

  final Color inactiveThumbColor;

  final Color inactiveTrackColor;

  final ImageProvider activeThumbImage;

  final ImageProvider inactiveThumbImage;

  final MaterialTapTargetSize materialTapTargetSize;

  final _SwitchType _switchType;

  final DragStartBehavior dragStartBehavior;

  @override
  _SwitchState createState() => _SwitchState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagProperty('value',
        value: value, ifTrue: 'on', ifFalse: 'off', showName: true));
    properties.add(ObjectFlagProperty<ValueChanged<bool>>(
        'onChanged', onChanged,
        ifNull: 'disabled'));
  }
}

class _SwitchState extends State<Switch> with TickerProviderStateMixin {
  Size getSwitchSize(ThemeData theme) {
    switch (widget.materialTapTargetSize ?? theme.materialTapTargetSize) {
      case MaterialTapTargetSize.padded:
        return const Size(_kSwitchWidth, _kSwitchHeight);
        break;
      case MaterialTapTargetSize.shrinkWrap:
        return const Size(_kSwitchWidth, _kSwitchHeightCollapsed);
        break;
    }
    assert(false);
    return null;
  }

  Widget buildMaterialSwitch(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final Color activeThumbColor =
        widget.activeColor ?? theme.toggleableActiveColor;
    final Color activeTrackColor =
        widget.activeTrackColor ?? activeThumbColor.withAlpha(0x80);

    Color inactiveThumbColor;
    Color inactiveTrackColor;
    if (widget.onChanged != null) {
      const Color black32 = Color(0x52000000);
      inactiveThumbColor = widget.inactiveThumbColor ??
          (isDark ? Colors.grey.shade400 : Colors.grey.shade50);
      inactiveTrackColor =
          widget.inactiveTrackColor ?? (isDark ? Colors.white30 : black32);
    } else {
      inactiveThumbColor = widget.inactiveThumbColor ??
          (isDark ? Colors.grey.shade800 : Colors.grey.shade400);
      inactiveTrackColor = widget.inactiveTrackColor ??
          (isDark ? Colors.white10 : Colors.black12);
    }

    return _SwitchRenderObjectWidget(
      dragStartBehavior: widget.dragStartBehavior,
      value: widget.value,
      activeColor: activeThumbColor,
      inactiveColor: inactiveThumbColor,
      activeThumbImage: widget.activeThumbImage,
      inactiveThumbImage: widget.inactiveThumbImage,
      activeTrackColor: activeTrackColor,
      inactiveTrackColor: inactiveTrackColor,
      configuration: createLocalImageConfiguration(context),
      onChanged: widget.onChanged,
      additionalConstraints: BoxConstraints.tight(getSwitchSize(theme)),
      vsync: this,
    );
  }

  Widget buildCupertinoSwitch(BuildContext context) {
    throw UnimplementedError();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget._switchType) {
      case _SwitchType.material:
        return buildMaterialSwitch(context);

      case _SwitchType.adaptive:
        {
          final ThemeData theme = Theme.of(context);
          assert(theme.platform != null);
          switch (theme.platform) {
            case TargetPlatform.android:
            case TargetPlatform.fuchsia:
              return buildMaterialSwitch(context);
            case TargetPlatform.iOS:
              return buildCupertinoSwitch(context);
          }
        }
    }
    assert(false);
    return null;
  }
}

class _SwitchRenderObjectWidget extends LeafRenderObjectWidget {
  const _SwitchRenderObjectWidget({
    Key key,
    this.value,
    this.activeColor,
    this.inactiveColor,
    this.activeThumbImage,
    this.inactiveThumbImage,
    this.activeTrackColor,
    this.inactiveTrackColor,
    this.configuration,
    this.onChanged,
    this.vsync,
    this.additionalConstraints,
    this.dragStartBehavior,
  }) : super(key: key);

  final bool value;
  final Color activeColor;
  final Color inactiveColor;
  final ImageProvider activeThumbImage;
  final ImageProvider inactiveThumbImage;
  final Color activeTrackColor;
  final Color inactiveTrackColor;
  final ImageConfiguration configuration;
  final ValueChanged<bool> onChanged;
  final TickerProvider vsync;
  final BoxConstraints additionalConstraints;
  final DragStartBehavior dragStartBehavior;

  @override
  _RenderSwitch createRenderObject(BuildContext context) {
    return _RenderSwitch(
      dragStartBehavior: dragStartBehavior,
      value: value,
      activeColor: activeColor,
      inactiveColor: inactiveColor,
      activeThumbImage: activeThumbImage,
      inactiveThumbImage: inactiveThumbImage,
      activeTrackColor: activeTrackColor,
      inactiveTrackColor: inactiveTrackColor,
      configuration: configuration,
      onChanged: onChanged,
      textDirection: Directionality.of(context),
      additionalConstraints: additionalConstraints,
      vsync: vsync,
    );
  }

  @override
  void updateRenderObject(BuildContext context, _RenderSwitch renderObject) {
    renderObject
      ..value = value
      ..activeColor = activeColor
      ..inactiveColor = inactiveColor
      ..activeThumbImage = activeThumbImage
      ..inactiveThumbImage = inactiveThumbImage
      ..activeTrackColor = activeTrackColor
      ..inactiveTrackColor = inactiveTrackColor
      ..configuration = configuration
      ..onChanged = onChanged
      ..textDirection = Directionality.of(context)
      ..additionalConstraints = additionalConstraints
      ..dragStartBehavior = dragStartBehavior
      ..vsync = vsync;
  }
}

class _RenderSwitch extends RenderToggleable {
  _RenderSwitch({
    bool value,
    Color activeColor,
    Color inactiveColor,
    ImageProvider activeThumbImage,
    ImageProvider inactiveThumbImage,
    Color activeTrackColor,
    Color inactiveTrackColor,
    ImageConfiguration configuration,
    BoxConstraints additionalConstraints,
    @required TextDirection textDirection,
    ValueChanged<bool> onChanged,
    @required TickerProvider vsync,
    DragStartBehavior dragStartBehavior,
  })  : assert(textDirection != null),
        _activeThumbImage = activeThumbImage,
        _inactiveThumbImage = inactiveThumbImage,
        _activeTrackColor = activeTrackColor,
        _inactiveTrackColor = inactiveTrackColor,
        _configuration = configuration,
        _textDirection = textDirection,
        super(
          value: value,
          tristate: false,
          activeColor: activeColor,
          inactiveColor: inactiveColor,
          onChanged: onChanged,
          additionalConstraints: additionalConstraints,
          vsync: vsync,
        ) {
    _drag = HorizontalDragGestureRecognizer()
      ..onStart = _handleDragStart
      ..onUpdate = _handleDragUpdate
      ..onEnd = _handleDragEnd
      ..dragStartBehavior = dragStartBehavior;
  }

  ImageProvider get activeThumbImage => _activeThumbImage;
  ImageProvider _activeThumbImage;
  set activeThumbImage(ImageProvider value) {
    if (value == _activeThumbImage) return;
    _activeThumbImage = value;
    markNeedsPaint();
  }

  ImageProvider get inactiveThumbImage => _inactiveThumbImage;
  ImageProvider _inactiveThumbImage;
  set inactiveThumbImage(ImageProvider value) {
    if (value == _inactiveThumbImage) return;
    _inactiveThumbImage = value;
    markNeedsPaint();
  }

  Color get activeTrackColor => _activeTrackColor;
  Color _activeTrackColor;
  set activeTrackColor(Color value) {
    assert(value != null);
    if (value == _activeTrackColor) return;
    _activeTrackColor = value;
    markNeedsPaint();
  }

  Color get inactiveTrackColor => _inactiveTrackColor;
  Color _inactiveTrackColor;
  set inactiveTrackColor(Color value) {
    assert(value != null);
    if (value == _inactiveTrackColor) return;
    _inactiveTrackColor = value;
    markNeedsPaint();
  }

  ImageConfiguration get configuration => _configuration;
  ImageConfiguration _configuration;
  set configuration(ImageConfiguration value) {
    assert(value != null);
    if (value == _configuration) return;
    _configuration = value;
    markNeedsPaint();
  }

  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    assert(value != null);
    if (_textDirection == value) return;
    _textDirection = value;
    markNeedsPaint();
  }

  DragStartBehavior get dragStartBehavior => _drag.dragStartBehavior;
  set dragStartBehavior(DragStartBehavior value) {
    assert(value != null);
    if (_drag.dragStartBehavior == value) return;
    _drag.dragStartBehavior = value;
  }

  @override
  void detach() {
    _cachedThumbPainter?.dispose();
    _cachedThumbPainter = null;
    super.detach();
  }

  double get _trackInnerLength => size.width - 2.0 * kRadialReactionRadius;

  HorizontalDragGestureRecognizer _drag;

  void _handleDragStart(DragStartDetails details) {
    if (isInteractive) reactionController.forward();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (isInteractive) {
      position
        ..curve = null
        ..reverseCurve = null;
      final double delta = details.primaryDelta / _trackInnerLength;
      switch (textDirection) {
        case TextDirection.rtl:
          positionController.value -= delta;
          break;
        case TextDirection.ltr:
          positionController.value += delta;
          break;
      }
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    if (position.value >= 0.5)
      positionController.forward();
    else
      positionController.reverse();
    reactionController.reverse();
  }

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    assert(debugHandleEvent(event, entry));
    if (event is PointerDownEvent && onChanged != null) _drag.addPointer(event);
    super.handleEvent(event, entry);
  }

  Color _cachedThumbColor;
  ImageProvider _cachedThumbImage;
  BoxPainter _cachedThumbPainter;

  BoxDecoration _createDefaultThumbDecoration(
      Color color, ImageProvider image) {
    return BoxDecoration(
      color: color,
      image: image == null ? null : DecorationImage(image: image),
      shape: BoxShape.circle,
      boxShadow: kElevationToShadow[1],
    );
  }

  bool _isPainting = false;

  void _handleDecorationChanged() {
    if (!_isPainting) markNeedsPaint();
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config.isToggled = value == true;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final Canvas canvas = context.canvas;
    final bool isEnabled = onChanged != null;
    final double currentValue = position.value;

    double visualPosition;
    switch (textDirection) {
      case TextDirection.rtl:
        visualPosition = 1.0 - currentValue;
        break;
      case TextDirection.ltr:
        visualPosition = currentValue;
        break;
    }

    final Color trackColor = isEnabled
        ? Color.lerp(inactiveTrackColor, activeTrackColor, currentValue)
        : inactiveTrackColor;

    final Color thumbColor = isEnabled
        ? Color.lerp(inactiveColor, activeColor, currentValue)
        : inactiveColor;

    final ImageProvider thumbImage = isEnabled
        ? (currentValue < 0.5 ? inactiveThumbImage : activeThumbImage)
        : inactiveThumbImage;

    final Paint paint = Paint()..color = trackColor;
    const double trackHorizontalPadding = kRadialReactionRadius - _kTrackRadius;
    final Rect trackRect = Rect.fromLTWH(
      offset.dx + trackHorizontalPadding,
      offset.dy + (size.height - _kTrackHeight) / 2.0,
      size.width - 2.0 * trackHorizontalPadding,
      _kTrackHeight,
    );
    final RRect trackRRect = RRect.fromRectAndRadius(
        trackRect, const Radius.circular(_kTrackRadius));
    canvas.drawRRect(trackRRect, paint);

    final Offset thumbPosition = Offset(
      kRadialReactionRadius + visualPosition * _trackInnerLength,
      size.height / 2.0,
    );

    paintRadialReaction(canvas, offset, thumbPosition);

    try {
      _isPainting = true;
      BoxPainter thumbPainter;
      if (_cachedThumbPainter == null ||
          thumbColor != _cachedThumbColor ||
          thumbImage != _cachedThumbImage) {
        _cachedThumbColor = thumbColor;
        _cachedThumbImage = thumbImage;
        _cachedThumbPainter =
            _createDefaultThumbDecoration(thumbColor, thumbImage)
                .createBoxPainter(_handleDecorationChanged);
      }
      thumbPainter = _cachedThumbPainter;

      final double inset = 1.0 - (currentValue - 0.5).abs() * 2.0;
      final double radius = _kThumbRadius - inset;
      thumbPainter.paint(
        canvas,
        thumbPosition + offset - Offset(radius, radius),
        configuration.copyWith(size: Size.fromRadius(radius)),
      );
    } finally {
      _isPainting = false;
    }
  }
}

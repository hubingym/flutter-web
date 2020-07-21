import 'dart:async';

import 'package:flutter_web/gestures.dart';
import 'package:flutter_web/widgets.dart';

const Color _kScrollbarColor = Color(0x99777777);
const double _kScrollbarMinLength = 36.0;
const double _kScrollbarMinOverscrollLength = 8.0;
const Radius _kScrollbarRadius = Radius.circular(1.5);
const Radius _kScrollbarRadiusDragging = Radius.circular(4.0);
const Duration _kScrollbarTimeToFade = Duration(milliseconds: 1200);
const Duration _kScrollbarFadeDuration = Duration(milliseconds: 250);
const Duration _kScrollbarResizeDuration = Duration(milliseconds: 150);

const double _kScrollbarThickness = 2.5;
const double _kScrollbarThicknessDragging = 8.0;

const double _kScrollbarMainAxisMargin = 3.0;
const double _kScrollbarCrossAxisMargin = 3.0;

class CupertinoScrollbar extends StatefulWidget {
  const CupertinoScrollbar({
    Key key,
    this.controller,
    @required this.child,
  }) : super(key: key);

  final Widget child;

  final ScrollController controller;

  @override
  _CupertinoScrollbarState createState() => _CupertinoScrollbarState();
}

class _CupertinoScrollbarState extends State<CupertinoScrollbar>
    with TickerProviderStateMixin {
  final GlobalKey _customPaintKey = GlobalKey();
  ScrollbarPainter _painter;
  TextDirection _textDirection;

  AnimationController _fadeoutAnimationController;
  Animation<double> _fadeoutOpacityAnimation;
  AnimationController _thicknessAnimationController;
  Timer _fadeoutTimer;
  double _dragScrollbarPositionY;
  Drag _drag;

  double get _thickness {
    return _kScrollbarThickness +
        _thicknessAnimationController.value *
            (_kScrollbarThicknessDragging - _kScrollbarThickness);
  }

  Radius get _radius {
    return Radius.lerp(_kScrollbarRadius, _kScrollbarRadiusDragging,
        _thicknessAnimationController.value);
  }

  @override
  void initState() {
    super.initState();
    _fadeoutAnimationController = AnimationController(
      vsync: this,
      duration: _kScrollbarFadeDuration,
    );
    _fadeoutOpacityAnimation = CurvedAnimation(
      parent: _fadeoutAnimationController,
      curve: Curves.fastOutSlowIn,
    );
    _thicknessAnimationController = AnimationController(
      vsync: this,
      duration: _kScrollbarResizeDuration,
    );
    _thicknessAnimationController.addListener(() {
      _painter.updateThickness(_thickness, _radius);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _textDirection = Directionality.of(context);
    _painter = _buildCupertinoScrollbarPainter();
  }

  ScrollbarPainter _buildCupertinoScrollbarPainter() {
    return ScrollbarPainter(
      color: _kScrollbarColor,
      textDirection: _textDirection,
      thickness: _thickness,
      fadeoutOpacityAnimation: _fadeoutOpacityAnimation,
      mainAxisMargin: _kScrollbarMainAxisMargin,
      crossAxisMargin: _kScrollbarCrossAxisMargin,
      radius: _radius,
      padding: MediaQuery.of(context).padding,
      minLength: _kScrollbarMinLength,
      minOverscrollLength: _kScrollbarMinOverscrollLength,
    );
  }

  void _dragScrollbar(double primaryDelta) {
    assert(widget.controller != null);

    final double scrollOffsetLocal = _painter.getTrackToScroll(primaryDelta);
    final double scrollOffsetGlobal =
        scrollOffsetLocal + widget.controller.position.pixels;

    if (_drag == null) {
      _drag = widget.controller.position.drag(
        DragStartDetails(
          globalPosition: Offset(0.0, scrollOffsetGlobal),
        ),
        () {},
      );
    } else {
      _drag.update(DragUpdateDetails(
        globalPosition: Offset(0.0, scrollOffsetGlobal),
        delta: Offset(0.0, -scrollOffsetLocal),
        primaryDelta: -scrollOffsetLocal,
      ));
    }
  }

  void _startFadeoutTimer() {
    _fadeoutTimer?.cancel();
    _fadeoutTimer = Timer(_kScrollbarTimeToFade, () {
      _fadeoutAnimationController.reverse();
      _fadeoutTimer = null;
    });
  }

  void _assertVertical() {
    assert(
      widget.controller.position.axis == Axis.vertical,
      'Scrollbar dragging is only supported for vertical scrolling. Don\'t pass the controller param to a horizontal scrollbar.',
    );
  }

  void _handleLongPressStart(LongPressStartDetails details) {
    _assertVertical();
    _fadeoutTimer?.cancel();
    _fadeoutAnimationController.forward();
    _dragScrollbar(details.localPosition.dy);
    _dragScrollbarPositionY = details.localPosition.dy;
  }

  void _handleLongPress() {
    _assertVertical();
    _fadeoutTimer?.cancel();
    _thicknessAnimationController.forward();
  }

  void _handleLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    _assertVertical();
    _dragScrollbar(details.localPosition.dy - _dragScrollbarPositionY);
    _dragScrollbarPositionY = details.localPosition.dy;
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    _handleDragScrollEnd(details.velocity.pixelsPerSecond.dy);
  }

  void _handleHorizontalDragStart(DragStartDetails details) {
    _assertVertical();
    _fadeoutTimer?.cancel();
    _thicknessAnimationController.forward();
    _dragScrollbar(details.localPosition.dy);
    _dragScrollbarPositionY = details.localPosition.dy;
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    _assertVertical();
    _dragScrollbar(details.localPosition.dy - _dragScrollbarPositionY);
    _dragScrollbarPositionY = details.localPosition.dy;
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    _handleDragScrollEnd(details.velocity.pixelsPerSecond.dy);
  }

  void _handleDragScrollEnd(double trackVelocityY) {
    _assertVertical();
    _startFadeoutTimer();
    _thicknessAnimationController.reverse();
    _dragScrollbarPositionY = null;
    final double scrollVelocityY = _painter.getTrackToScroll(trackVelocityY);
    _drag?.end(DragEndDetails(
      primaryVelocity: -scrollVelocityY,
      velocity: Velocity(
        pixelsPerSecond: Offset(
          0.0,
          -scrollVelocityY,
        ),
      ),
    ));
    _drag = null;
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    final ScrollMetrics metrics = notification.metrics;
    if (metrics.maxScrollExtent <= metrics.minScrollExtent) {
      return false;
    }

    if (notification is ScrollUpdateNotification ||
        notification is OverscrollNotification) {
      if (_fadeoutAnimationController.status != AnimationStatus.forward) {
        _fadeoutAnimationController.forward();
      }

      _fadeoutTimer?.cancel();
      _painter.update(notification.metrics, notification.metrics.axisDirection);
    } else if (notification is ScrollEndNotification) {
      if (_dragScrollbarPositionY == null) {
        _startFadeoutTimer();
      }
    }
    return false;
  }

  Map<Type, GestureRecognizerFactory> get _gestures {
    final Map<Type, GestureRecognizerFactory> gestures =
        <Type, GestureRecognizerFactory>{};
    if (widget.controller == null) {
      return gestures;
    }

    gestures[_ThumbLongPressGestureRecognizer] =
        GestureRecognizerFactoryWithHandlers<_ThumbLongPressGestureRecognizer>(
      () => _ThumbLongPressGestureRecognizer(
        debugOwner: this,
        kind: PointerDeviceKind.touch,
        customPaintKey: _customPaintKey,
      ),
      (_ThumbLongPressGestureRecognizer instance) {
        instance
          ..onLongPressStart = _handleLongPressStart
          ..onLongPress = _handleLongPress
          ..onLongPressMoveUpdate = _handleLongPressMoveUpdate
          ..onLongPressEnd = _handleLongPressEnd;
      },
    );
    gestures[_ThumbHorizontalDragGestureRecognizer] =
        GestureRecognizerFactoryWithHandlers<
            _ThumbHorizontalDragGestureRecognizer>(
      () => _ThumbHorizontalDragGestureRecognizer(
        debugOwner: this,
        kind: PointerDeviceKind.touch,
        customPaintKey: _customPaintKey,
      ),
      (_ThumbHorizontalDragGestureRecognizer instance) {
        instance
          ..onStart = _handleHorizontalDragStart
          ..onUpdate = _handleHorizontalDragUpdate
          ..onEnd = _handleHorizontalDragEnd;
      },
    );

    return gestures;
  }

  @override
  void dispose() {
    _fadeoutAnimationController.dispose();
    _thicknessAnimationController.dispose();
    _fadeoutTimer?.cancel();
    _painter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: RepaintBoundary(
        child: RawGestureDetector(
          gestures: _gestures,
          child: CustomPaint(
            key: _customPaintKey,
            foregroundPainter: _painter,
            child: RepaintBoundary(
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

class _ThumbLongPressGestureRecognizer extends LongPressGestureRecognizer {
  _ThumbLongPressGestureRecognizer({
    double postAcceptSlopTolerance,
    PointerDeviceKind kind,
    Object debugOwner,
    GlobalKey customPaintKey,
  })  : _customPaintKey = customPaintKey,
        super(
          postAcceptSlopTolerance: postAcceptSlopTolerance,
          kind: kind,
          debugOwner: debugOwner,
        );

  final GlobalKey _customPaintKey;

  @override
  bool isPointerAllowed(PointerDownEvent event) {
    if (!_hitTestInteractive(_customPaintKey, event.position)) {
      return false;
    }
    return super.isPointerAllowed(event);
  }
}

class _ThumbHorizontalDragGestureRecognizer
    extends HorizontalDragGestureRecognizer {
  _ThumbHorizontalDragGestureRecognizer({
    PointerDeviceKind kind,
    Object debugOwner,
    GlobalKey customPaintKey,
  })  : _customPaintKey = customPaintKey,
        super(
          kind: kind,
          debugOwner: debugOwner,
        );

  final GlobalKey _customPaintKey;

  @override
  bool isPointerAllowed(PointerEvent event) {
    if (!_hitTestInteractive(_customPaintKey, event.position)) {
      return false;
    }
    return super.isPointerAllowed(event);
  }

  @override
  bool isFlingGesture(VelocityEstimate estimate) {
    final double minVelocity = minFlingVelocity ?? kMinFlingVelocity;
    final double minDistance = minFlingDistance ?? kTouchSlop;
    return estimate.pixelsPerSecond.dy.abs() > minVelocity &&
        estimate.offset.dy.abs() > minDistance;
  }
}

bool _hitTestInteractive(GlobalKey customPaintKey, Offset offset) {
  if (customPaintKey.currentContext == null) {
    return false;
  }
  final CustomPaint customPaint = customPaintKey.currentContext.widget;
  final ScrollbarPainter painter = customPaint.foregroundPainter;
  final RenderBox renderBox = customPaintKey.currentContext.findRenderObject();
  final Offset localOffset = renderBox.globalToLocal(offset);
  return painter.hitTestInteractive(localOffset);
}

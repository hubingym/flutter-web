import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_web/ui.dart';

import 'package:flutter_web/gestures.dart';
import 'package:flutter_web/rendering.dart';
import 'package:flutter_web/scheduler.dart';

import 'basic.dart';
import 'framework.dart';
import 'gesture_detector.dart';
import 'notification_listener.dart';
import 'scroll_configuration.dart';
import 'scroll_context.dart';
import 'scroll_controller.dart';
import 'scroll_physics.dart';
import 'scroll_position.dart';
import 'scroll_position_with_single_context.dart';
import 'ticker_provider.dart';
import 'viewport.dart';

export 'package:flutter_web/physics.dart' show Tolerance;

typedef ViewportBuilder = Widget Function(
    BuildContext context, ViewportOffset position);

class Scrollable extends StatefulWidget {
  const Scrollable({
    Key key,
    this.axisDirection = AxisDirection.down,
    this.controller,
    this.physics,
    @required this.viewportBuilder,
    this.excludeFromSemantics = false,
    this.semanticChildCount,
    this.dragStartBehavior = DragStartBehavior.start,
  })  : assert(axisDirection != null),
        assert(dragStartBehavior != null),
        assert(viewportBuilder != null),
        assert(excludeFromSemantics != null),
        super(key: key);

  final AxisDirection axisDirection;

  final ScrollController controller;

  final ScrollPhysics physics;

  final ViewportBuilder viewportBuilder;

  final bool excludeFromSemantics;

  final int semanticChildCount;

  final DragStartBehavior dragStartBehavior;

  Axis get axis => axisDirectionToAxis(axisDirection);

  @override
  ScrollableState createState() => ScrollableState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<AxisDirection>('axisDirection', axisDirection));
    properties.add(DiagnosticsProperty<ScrollPhysics>('physics', physics));
  }

  static ScrollableState of(BuildContext context) {
    final _ScrollableScope widget =
        context.inheritFromWidgetOfExactType(_ScrollableScope);
    return widget?.scrollable;
  }

  static Future<void> ensureVisible(
    BuildContext context, {
    double alignment = 0.0,
    Duration duration = Duration.zero,
    Curve curve = Curves.ease,
  }) {
    final List<Future<void>> futures = <Future<void>>[];

    ScrollableState scrollable = Scrollable.of(context);
    while (scrollable != null) {
      futures.add(scrollable.position.ensureVisible(
        context.findRenderObject(),
        alignment: alignment,
        duration: duration,
        curve: curve,
      ));
      context = scrollable.context;
      scrollable = Scrollable.of(context);
    }

    if (futures.isEmpty || duration == Duration.zero)
      return Future<void>.value();
    if (futures.length == 1) return futures.single;
    return Future.wait<void>(futures).then<void>((List<void> _) => null);
  }
}

class _ScrollableScope extends InheritedWidget {
  const _ScrollableScope({
    Key key,
    @required this.scrollable,
    @required this.position,
    @required Widget child,
  })  : assert(scrollable != null),
        assert(child != null),
        super(key: key, child: child);

  final ScrollableState scrollable;
  final ScrollPosition position;

  @override
  bool updateShouldNotify(_ScrollableScope old) {
    return position != old.position;
  }
}

class ScrollableState extends State<Scrollable>
    with TickerProviderStateMixin
    implements ScrollContext {
  ScrollPosition get position => _position;
  ScrollPosition _position;

  @override
  AxisDirection get axisDirection => widget.axisDirection;

  ScrollBehavior _configuration;
  ScrollPhysics _physics;

  void _updatePosition() {
    _configuration = ScrollConfiguration.of(context);
    _physics = _configuration.getScrollPhysics(context);
    if (widget.physics != null) _physics = widget.physics.applyTo(_physics);
    final ScrollController controller = widget.controller;
    final ScrollPosition oldPosition = position;
    if (oldPosition != null) {
      controller?.detach(oldPosition);

      scheduleMicrotask(oldPosition.dispose);
    }

    _position = controller?.createScrollPosition(_physics, this, oldPosition) ??
        ScrollPositionWithSingleContext(
            physics: _physics, context: this, oldPosition: oldPosition);
    assert(position != null);
    controller?.attach(position);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updatePosition();
  }

  bool _shouldUpdatePosition(Scrollable oldWidget) {
    ScrollPhysics newPhysics = widget.physics;
    ScrollPhysics oldPhysics = oldWidget.physics;
    do {
      if (newPhysics?.runtimeType != oldPhysics?.runtimeType) return true;
      newPhysics = newPhysics?.parent;
      oldPhysics = oldPhysics?.parent;
    } while (newPhysics != null || oldPhysics != null);

    return widget.controller?.runtimeType != oldWidget.controller?.runtimeType;
  }

  @override
  void didUpdateWidget(Scrollable oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.detach(position);
      widget.controller?.attach(position);
    }

    if (_shouldUpdatePosition(oldWidget)) _updatePosition();
  }

  @override
  void dispose() {
    widget.controller?.detach(position);
    position.dispose();
    super.dispose();
  }

  final GlobalKey _scrollSemanticsKey = GlobalKey();

  @override
  @protected
  void setSemanticsActions(Set<SemanticsAction> actions) {
    if (_gestureDetectorKey.currentState != null)
      _gestureDetectorKey.currentState.replaceSemanticsActions(actions);
  }

  final GlobalKey<RawGestureDetectorState> _gestureDetectorKey =
      GlobalKey<RawGestureDetectorState>();
  final GlobalKey _ignorePointerKey = GlobalKey();

  Map<Type, GestureRecognizerFactory> _gestureRecognizers =
      const <Type, GestureRecognizerFactory>{};
  bool _shouldIgnorePointer = false;

  bool _lastCanDrag;
  Axis _lastAxisDirection;

  @override
  @protected
  void setCanDrag(bool canDrag) {
    if (canDrag == _lastCanDrag &&
        (!canDrag || widget.axis == _lastAxisDirection)) return;
    if (!canDrag) {
      _gestureRecognizers = const <Type, GestureRecognizerFactory>{};
    } else {
      switch (widget.axis) {
        case Axis.vertical:
          _gestureRecognizers = <Type, GestureRecognizerFactory>{
            VerticalDragGestureRecognizer: GestureRecognizerFactoryWithHandlers<
                VerticalDragGestureRecognizer>(
              () => VerticalDragGestureRecognizer(),
              (VerticalDragGestureRecognizer instance) {
                instance
                  ..onDown = _handleDragDown
                  ..onStart = _handleDragStart
                  ..onUpdate = _handleDragUpdate
                  ..onEnd = _handleDragEnd
                  ..onCancel = _handleDragCancel
                  ..minFlingDistance = _physics?.minFlingDistance
                  ..minFlingVelocity = _physics?.minFlingVelocity
                  ..maxFlingVelocity = _physics?.maxFlingVelocity
                  ..dragStartBehavior = widget.dragStartBehavior;
              },
            ),
          };
          break;
        case Axis.horizontal:
          _gestureRecognizers = <Type, GestureRecognizerFactory>{
            HorizontalDragGestureRecognizer:
                GestureRecognizerFactoryWithHandlers<
                    HorizontalDragGestureRecognizer>(
              () => HorizontalDragGestureRecognizer(),
              (HorizontalDragGestureRecognizer instance) {
                instance
                  ..onDown = _handleDragDown
                  ..onStart = _handleDragStart
                  ..onUpdate = _handleDragUpdate
                  ..onEnd = _handleDragEnd
                  ..onCancel = _handleDragCancel
                  ..minFlingDistance = _physics?.minFlingDistance
                  ..minFlingVelocity = _physics?.minFlingVelocity
                  ..maxFlingVelocity = _physics?.maxFlingVelocity
                  ..dragStartBehavior = widget.dragStartBehavior;
              },
            ),
          };
          break;
      }
    }
    _lastCanDrag = canDrag;
    _lastAxisDirection = widget.axis;
    if (_gestureDetectorKey.currentState != null)
      _gestureDetectorKey.currentState
          .replaceGestureRecognizers(_gestureRecognizers);
  }

  @override
  TickerProvider get vsync => this;

  @override
  @protected
  void setIgnorePointer(bool value) {
    if (_shouldIgnorePointer == value) return;
    _shouldIgnorePointer = value;
    if (_ignorePointerKey.currentContext != null) {
      final RenderIgnorePointer renderBox =
          _ignorePointerKey.currentContext.findRenderObject();
      renderBox.ignoring = _shouldIgnorePointer;
    }
  }

  @override
  BuildContext get notificationContext => _gestureDetectorKey.currentContext;

  @override
  BuildContext get storageContext => context;

  Drag _drag;
  ScrollHoldController _hold;

  void _handleDragDown(DragDownDetails details) {
    assert(_drag == null);
    assert(_hold == null);
    _hold = position.hold(_disposeHold);
  }

  void _handleDragStart(DragStartDetails details) {
    assert(_drag == null);
    _drag = position.drag(details, _disposeDrag);
    assert(_drag != null);
    assert(_hold == null);
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    assert(_hold == null || _drag == null);
    _drag?.update(details);
  }

  void _handleDragEnd(DragEndDetails details) {
    assert(_hold == null || _drag == null);
    _drag?.end(details);
    assert(_drag == null);
  }

  void _handleDragCancel() {
    assert(_hold == null || _drag == null);
    _hold?.cancel();
    _drag?.cancel();
    assert(_hold == null);
    assert(_drag == null);
  }

  void _disposeHold() {
    _hold = null;
  }

  void _disposeDrag() {
    _drag = null;
  }

  double _targetScrollOffsetForPointerScroll(PointerScrollEvent event) {
    final double delta = widget.axis == Axis.horizontal
        ? event.scrollDelta.dx
        : event.scrollDelta.dy;
    return math.min(math.max(position.pixels + delta, position.minScrollExtent),
        position.maxScrollExtent);
  }

  void _receivedPointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent && position != null) {
      final double targetScrollOffset =
          _targetScrollOffsetForPointerScroll(event);

      if (targetScrollOffset != position.pixels) {
        GestureBinding.instance.pointerSignalResolver
            .register(event, _handlePointerScroll);
      }
    }
  }

  void _handlePointerScroll(PointerEvent event) {
    assert(event is PointerScrollEvent);
    final double targetScrollOffset =
        _targetScrollOffsetForPointerScroll(event);
    if (targetScrollOffset != position.pixels) {
      position.jumpTo(targetScrollOffset);
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(position != null);

    Widget result = _ScrollableScope(
      scrollable: this,
      position: position,
      child: Listener(
        onPointerSignal: _receivedPointerSignal,
        child: RawGestureDetector(
          key: _gestureDetectorKey,
          gestures: _gestureRecognizers,
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: widget.excludeFromSemantics,
          child: Semantics(
            explicitChildNodes: !widget.excludeFromSemantics,
            child: IgnorePointer(
              key: _ignorePointerKey,
              ignoring: _shouldIgnorePointer,
              ignoringSemantics: false,
              child: widget.viewportBuilder(context, position),
            ),
          ),
        ),
      ),
    );

    if (!widget.excludeFromSemantics) {
      result = _ScrollSemantics(
        key: _scrollSemanticsKey,
        child: result,
        position: position,
        allowImplicitScrolling: widget?.physics?.allowImplicitScrolling ??
            _physics.allowImplicitScrolling,
        semanticChildCount: widget.semanticChildCount,
      );
    }

    return _configuration.buildViewportChrome(
        context, result, widget.axisDirection);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ScrollPosition>('position', position));
  }
}

class _ScrollSemantics extends SingleChildRenderObjectWidget {
  const _ScrollSemantics({
    Key key,
    @required this.position,
    @required this.allowImplicitScrolling,
    @required this.semanticChildCount,
    Widget child,
  })  : assert(position != null),
        super(key: key, child: child);

  final ScrollPosition position;
  final bool allowImplicitScrolling;
  final int semanticChildCount;

  @override
  _RenderScrollSemantics createRenderObject(BuildContext context) {
    return _RenderScrollSemantics(
      position: position,
      allowImplicitScrolling: allowImplicitScrolling,
      semanticChildCount: semanticChildCount,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, _RenderScrollSemantics renderObject) {
    renderObject
      ..allowImplicitScrolling = allowImplicitScrolling
      ..position = position
      ..semanticChildCount = semanticChildCount;
  }
}

class _RenderScrollSemantics extends RenderProxyBox {
  _RenderScrollSemantics({
    @required ScrollPosition position,
    @required bool allowImplicitScrolling,
    @required int semanticChildCount,
    RenderBox child,
  })  : _position = position,
        _allowImplicitScrolling = allowImplicitScrolling,
        _semanticChildCount = semanticChildCount,
        assert(position != null),
        super(child) {
    position.addListener(markNeedsSemanticsUpdate);
  }

  ScrollPosition get position => _position;
  ScrollPosition _position;
  set position(ScrollPosition value) {
    assert(value != null);
    if (value == _position) return;
    _position.removeListener(markNeedsSemanticsUpdate);
    _position = value;
    _position.addListener(markNeedsSemanticsUpdate);
    markNeedsSemanticsUpdate();
  }

  bool get allowImplicitScrolling => _allowImplicitScrolling;
  bool _allowImplicitScrolling;
  set allowImplicitScrolling(bool value) {
    if (value == _allowImplicitScrolling) return;
    _allowImplicitScrolling = value;
    markNeedsSemanticsUpdate();
  }

  int get semanticChildCount => _semanticChildCount;
  int _semanticChildCount;
  set semanticChildCount(int value) {
    if (value == semanticChildCount) return;
    _semanticChildCount = value;
    markNeedsSemanticsUpdate();
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config.isSemanticBoundary = true;
    if (position.haveDimensions) {
      config
        ..hasImplicitScrolling = allowImplicitScrolling
        ..scrollPosition = _position.pixels
        ..scrollExtentMax = _position.maxScrollExtent
        ..scrollExtentMin = _position.minScrollExtent
        ..scrollChildCount = semanticChildCount;
    }
  }

  SemanticsNode _innerNode;

  @override
  void assembleSemanticsNode(SemanticsNode node, SemanticsConfiguration config,
      Iterable<SemanticsNode> children) {
    if (children.isEmpty ||
        !children.first.isTagged(RenderViewport.useTwoPaneSemantics)) {
      super.assembleSemanticsNode(node, config, children);
      return;
    }

    _innerNode ??= SemanticsNode(showOnScreen: showOnScreen);
    _innerNode
      ..isMergedIntoParent = node.isPartOfNodeMerging
      ..rect = Offset.zero & node.rect.size;

    int firstVisibleIndex;
    final List<SemanticsNode> excluded = <SemanticsNode>[_innerNode];
    final List<SemanticsNode> included = <SemanticsNode>[];
    for (SemanticsNode child in children) {
      assert(child.isTagged(RenderViewport.useTwoPaneSemantics));
      if (child.isTagged(RenderViewport.excludeFromScrolling)) {
        excluded.add(child);
      } else {
        if (!child.hasFlag(SemanticsFlag.isHidden))
          firstVisibleIndex ??= child.indexInParent;
        included.add(child);
      }
    }
    config.scrollIndex = firstVisibleIndex;
    node.updateWith(config: null, childrenInInversePaintOrder: excluded);
    _innerNode.updateWith(
        config: config, childrenInInversePaintOrder: included);
  }

  @override
  void clearSemantics() {
    super.clearSemantics();
    _innerNode = null;
  }
}

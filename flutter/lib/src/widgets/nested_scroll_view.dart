import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_web/gestures.dart';
import 'package:flutter_web/painting.dart';
import 'package:flutter_web/physics.dart';
import 'package:flutter_web/rendering.dart';
import 'package:flutter_web/scheduler.dart';
import 'package:flutter_web/gestures.dart' show DragStartBehavior;

import 'basic.dart';
import 'framework.dart';
import 'primary_scroll_controller.dart';
import 'scroll_activity.dart';
import 'scroll_context.dart';
import 'scroll_controller.dart';
import 'scroll_metrics.dart';
import 'scroll_physics.dart';
import 'scroll_position.dart';
import 'scroll_view.dart';
import 'sliver.dart';
import 'viewport.dart';

typedef NestedScrollViewHeaderSliversBuilder = List<Widget> Function(
    BuildContext context, bool innerBoxIsScrolled);

class NestedScrollView extends StatefulWidget {
  const NestedScrollView({
    Key key,
    this.controller,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.physics,
    @required this.headerSliverBuilder,
    @required this.body,
    this.dragStartBehavior = DragStartBehavior.start,
  })  : assert(scrollDirection != null),
        assert(reverse != null),
        assert(headerSliverBuilder != null),
        assert(body != null),
        super(key: key);

  final ScrollController controller;

  final Axis scrollDirection;

  final bool reverse;

  final ScrollPhysics physics;

  final NestedScrollViewHeaderSliversBuilder headerSliverBuilder;

  final Widget body;

  final DragStartBehavior dragStartBehavior;

  static SliverOverlapAbsorberHandle sliverOverlapAbsorberHandleFor(
      BuildContext context) {
    final _InheritedNestedScrollView target =
        context.inheritFromWidgetOfExactType(_InheritedNestedScrollView);
    assert(target != null,
        'NestedScrollView.sliverOverlapAbsorberHandleFor must be called with a context that contains a NestedScrollView.');
    return target.state._absorberHandle;
  }

  List<Widget> _buildSlivers(BuildContext context,
      ScrollController innerController, bool bodyIsScrolled) {
    final List<Widget> slivers = <Widget>[];
    slivers.addAll(headerSliverBuilder(context, bodyIsScrolled));
    slivers.add(SliverFillRemaining(
      child: PrimaryScrollController(
        controller: innerController,
        child: body,
      ),
    ));
    return slivers;
  }

  @override
  _NestedScrollViewState createState() => _NestedScrollViewState();
}

class _NestedScrollViewState extends State<NestedScrollView> {
  final SliverOverlapAbsorberHandle _absorberHandle =
      SliverOverlapAbsorberHandle();

  _NestedScrollCoordinator _coordinator;

  @override
  void initState() {
    super.initState();
    _coordinator = _NestedScrollCoordinator(
        this, widget.controller, _handleHasScrolledBodyChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _coordinator.setParent(widget.controller);
  }

  @override
  void didUpdateWidget(NestedScrollView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller)
      _coordinator.setParent(widget.controller);
  }

  @override
  void dispose() {
    _coordinator.dispose();
    _coordinator = null;
    super.dispose();
  }

  bool _lastHasScrolledBody;

  void _handleHasScrolledBodyChanged() {
    if (!mounted) return;
    final bool newHasScrolledBody = _coordinator.hasScrolledBody;
    if (_lastHasScrolledBody != newHasScrolledBody) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedNestedScrollView(
      state: this,
      child: Builder(
        builder: (BuildContext context) {
          _lastHasScrolledBody = _coordinator.hasScrolledBody;
          return _NestedScrollViewCustomScrollView(
            dragStartBehavior: widget.dragStartBehavior,
            scrollDirection: widget.scrollDirection,
            reverse: widget.reverse,
            physics: widget.physics != null
                ? widget.physics.applyTo(const ClampingScrollPhysics())
                : const ClampingScrollPhysics(),
            controller: _coordinator._outerController,
            slivers: widget._buildSlivers(
              context,
              _coordinator._innerController,
              _lastHasScrolledBody,
            ),
            handle: _absorberHandle,
          );
        },
      ),
    );
  }
}

class _NestedScrollViewCustomScrollView extends CustomScrollView {
  const _NestedScrollViewCustomScrollView({
    @required Axis scrollDirection,
    @required bool reverse,
    @required ScrollPhysics physics,
    @required ScrollController controller,
    @required List<Widget> slivers,
    @required this.handle,
    DragStartBehavior dragStartBehavior = DragStartBehavior.start,
  }) : super(
          scrollDirection: scrollDirection,
          reverse: reverse,
          physics: physics,
          controller: controller,
          slivers: slivers,
          dragStartBehavior: dragStartBehavior,
        );

  final SliverOverlapAbsorberHandle handle;

  @override
  Widget buildViewport(
    BuildContext context,
    ViewportOffset offset,
    AxisDirection axisDirection,
    List<Widget> slivers,
  ) {
    assert(!shrinkWrap);
    return NestedScrollViewViewport(
      axisDirection: axisDirection,
      offset: offset,
      slivers: slivers,
      handle: handle,
    );
  }
}

class _InheritedNestedScrollView extends InheritedWidget {
  const _InheritedNestedScrollView({
    Key key,
    @required this.state,
    @required Widget child,
  })  : assert(state != null),
        assert(child != null),
        super(key: key, child: child);

  final _NestedScrollViewState state;

  @override
  bool updateShouldNotify(_InheritedNestedScrollView old) => state != old.state;
}

class _NestedScrollMetrics extends FixedScrollMetrics {
  _NestedScrollMetrics({
    @required double minScrollExtent,
    @required double maxScrollExtent,
    @required double pixels,
    @required double viewportDimension,
    @required AxisDirection axisDirection,
    @required this.minRange,
    @required this.maxRange,
    @required this.correctionOffset,
  }) : super(
          minScrollExtent: minScrollExtent,
          maxScrollExtent: maxScrollExtent,
          pixels: pixels,
          viewportDimension: viewportDimension,
          axisDirection: axisDirection,
        );

  @override
  _NestedScrollMetrics copyWith({
    double minScrollExtent,
    double maxScrollExtent,
    double pixels,
    double viewportDimension,
    AxisDirection axisDirection,
    double minRange,
    double maxRange,
    double correctionOffset,
  }) {
    return _NestedScrollMetrics(
      minScrollExtent: minScrollExtent ?? this.minScrollExtent,
      maxScrollExtent: maxScrollExtent ?? this.maxScrollExtent,
      pixels: pixels ?? this.pixels,
      viewportDimension: viewportDimension ?? this.viewportDimension,
      axisDirection: axisDirection ?? this.axisDirection,
      minRange: minRange ?? this.minRange,
      maxRange: maxRange ?? this.maxRange,
      correctionOffset: correctionOffset ?? this.correctionOffset,
    );
  }

  final double minRange;

  final double maxRange;

  final double correctionOffset;
}

typedef _NestedScrollActivityGetter = ScrollActivity Function(
    _NestedScrollPosition position);

class _NestedScrollCoordinator
    implements ScrollActivityDelegate, ScrollHoldController {
  _NestedScrollCoordinator(
      this._state, this._parent, this._onHasScrolledBodyChanged) {
    final double initialScrollOffset = _parent?.initialScrollOffset ?? 0.0;
    _outerController = _NestedScrollController(this,
        initialScrollOffset: initialScrollOffset, debugLabel: 'outer');
    _innerController = _NestedScrollController(this,
        initialScrollOffset: 0.0, debugLabel: 'inner');
  }

  final _NestedScrollViewState _state;
  ScrollController _parent;
  final VoidCallback _onHasScrolledBodyChanged;

  _NestedScrollController _outerController;
  _NestedScrollController _innerController;

  _NestedScrollPosition get _outerPosition {
    if (!_outerController.hasClients) return null;
    return _outerController.nestedPositions.single;
  }

  Iterable<_NestedScrollPosition> get _innerPositions {
    return _innerController.nestedPositions;
  }

  bool get canScrollBody {
    final _NestedScrollPosition outer = _outerPosition;
    if (outer == null) return true;
    return outer.haveDimensions && outer.extentAfter == 0.0;
  }

  bool get hasScrolledBody {
    for (_NestedScrollPosition position in _innerPositions) {
      if (position.pixels > position.minScrollExtent) return true;
    }
    return false;
  }

  void updateShadow() {
    if (_onHasScrolledBodyChanged != null) _onHasScrolledBodyChanged();
  }

  ScrollDirection get userScrollDirection => _userScrollDirection;
  ScrollDirection _userScrollDirection = ScrollDirection.idle;

  void updateUserScrollDirection(ScrollDirection value) {
    assert(value != null);
    if (userScrollDirection == value) return;
    _userScrollDirection = value;
    _outerPosition.didUpdateScrollDirection(value);
    for (_NestedScrollPosition position in _innerPositions)
      position.didUpdateScrollDirection(value);
  }

  ScrollDragController _currentDrag;

  void beginActivity(ScrollActivity newOuterActivity,
      _NestedScrollActivityGetter innerActivityGetter) {
    _outerPosition.beginActivity(newOuterActivity);
    bool scrolling = newOuterActivity.isScrolling;
    for (_NestedScrollPosition position in _innerPositions) {
      final ScrollActivity newInnerActivity = innerActivityGetter(position);
      position.beginActivity(newInnerActivity);
      scrolling = scrolling && newInnerActivity.isScrolling;
    }
    _currentDrag?.dispose();
    _currentDrag = null;
    if (!scrolling) updateUserScrollDirection(ScrollDirection.idle);
  }

  @override
  AxisDirection get axisDirection => _outerPosition.axisDirection;

  static IdleScrollActivity _createIdleScrollActivity(
      _NestedScrollPosition position) {
    return IdleScrollActivity(position);
  }

  @override
  void goIdle() {
    beginActivity(
        _createIdleScrollActivity(_outerPosition), _createIdleScrollActivity);
  }

  @override
  void goBallistic(double velocity) {
    beginActivity(
      createOuterBallisticScrollActivity(velocity),
      (_NestedScrollPosition position) =>
          createInnerBallisticScrollActivity(position, velocity),
    );
  }

  ScrollActivity createOuterBallisticScrollActivity(double velocity) {
    _NestedScrollPosition innerPosition;
    if (velocity != 0.0) {
      for (_NestedScrollPosition position in _innerPositions) {
        if (innerPosition != null) {
          if (velocity > 0.0) {
            if (innerPosition.pixels < position.pixels) continue;
          } else {
            assert(velocity < 0.0);
            if (innerPosition.pixels > position.pixels) continue;
          }
        }
        innerPosition = position;
      }
    }

    if (innerPosition == null) {
      return _outerPosition.createBallisticScrollActivity(
        _outerPosition.physics
            .createBallisticSimulation(_outerPosition, velocity),
        mode: _NestedBallisticScrollActivityMode.independent,
      );
    }

    final _NestedScrollMetrics metrics = _getMetrics(innerPosition, velocity);

    return _outerPosition.createBallisticScrollActivity(
      _outerPosition.physics.createBallisticSimulation(metrics, velocity),
      mode: _NestedBallisticScrollActivityMode.outer,
      metrics: metrics,
    );
  }

  @protected
  ScrollActivity createInnerBallisticScrollActivity(
      _NestedScrollPosition position, double velocity) {
    return position.createBallisticScrollActivity(
      position.physics.createBallisticSimulation(
        velocity == 0 ? position : _getMetrics(position, velocity),
        velocity,
      ),
      mode: _NestedBallisticScrollActivityMode.inner,
    );
  }

  _NestedScrollMetrics _getMetrics(
      _NestedScrollPosition innerPosition, double velocity) {
    assert(innerPosition != null);
    double pixels, minRange, maxRange, correctionOffset, extra;
    if (innerPosition.pixels == innerPosition.minScrollExtent) {
      pixels = _outerPosition.pixels.clamp(
          _outerPosition.minScrollExtent, _outerPosition.maxScrollExtent);
      minRange = _outerPosition.minScrollExtent;
      maxRange = _outerPosition.maxScrollExtent;
      assert(minRange <= maxRange);
      correctionOffset = 0.0;
      extra = 0.0;
    } else {
      assert(innerPosition.pixels != innerPosition.minScrollExtent);
      if (innerPosition.pixels < innerPosition.minScrollExtent) {
        pixels = innerPosition.pixels -
            innerPosition.minScrollExtent +
            _outerPosition.minScrollExtent;
      } else {
        assert(innerPosition.pixels > innerPosition.minScrollExtent);
        pixels = innerPosition.pixels -
            innerPosition.minScrollExtent +
            _outerPosition.maxScrollExtent;
      }
      if ((velocity > 0.0) &&
          (innerPosition.pixels > innerPosition.minScrollExtent)) {
        extra = _outerPosition.maxScrollExtent - _outerPosition.pixels;
        assert(extra >= 0.0);
        minRange = pixels;
        maxRange = pixels + extra;
        assert(minRange <= maxRange);
        correctionOffset = _outerPosition.pixels - pixels;
      } else if ((velocity < 0.0) &&
          (innerPosition.pixels < innerPosition.minScrollExtent)) {
        extra = _outerPosition.pixels - _outerPosition.minScrollExtent;
        assert(extra >= 0.0);
        minRange = pixels - extra;
        maxRange = pixels;
        assert(minRange <= maxRange);
        correctionOffset = _outerPosition.pixels - pixels;
      } else {
        if (velocity > 0.0) {
          extra = _outerPosition.minScrollExtent - _outerPosition.pixels;
        } else {
          assert(velocity < 0.0);

          extra = _outerPosition.pixels -
              (_outerPosition.maxScrollExtent - _outerPosition.minScrollExtent);
        }
        assert(extra <= 0.0);
        minRange = _outerPosition.minScrollExtent;
        maxRange = _outerPosition.maxScrollExtent + extra;
        assert(minRange <= maxRange);
        correctionOffset = 0.0;
      }
    }
    return _NestedScrollMetrics(
      minScrollExtent: _outerPosition.minScrollExtent,
      maxScrollExtent: _outerPosition.maxScrollExtent +
          innerPosition.maxScrollExtent -
          innerPosition.minScrollExtent +
          extra,
      pixels: pixels,
      viewportDimension: _outerPosition.viewportDimension,
      axisDirection: _outerPosition.axisDirection,
      minRange: minRange,
      maxRange: maxRange,
      correctionOffset: correctionOffset,
    );
  }

  double unnestOffset(double value, _NestedScrollPosition source) {
    if (source == _outerPosition)
      return value.clamp(
          _outerPosition.minScrollExtent, _outerPosition.maxScrollExtent);
    if (value < source.minScrollExtent)
      return value - source.minScrollExtent + _outerPosition.minScrollExtent;
    return value - source.minScrollExtent + _outerPosition.maxScrollExtent;
  }

  double nestOffset(double value, _NestedScrollPosition target) {
    if (target == _outerPosition)
      return value.clamp(
          _outerPosition.minScrollExtent, _outerPosition.maxScrollExtent);
    if (value < _outerPosition.minScrollExtent)
      return value - _outerPosition.minScrollExtent + target.minScrollExtent;
    if (value > _outerPosition.maxScrollExtent)
      return value - _outerPosition.maxScrollExtent + target.minScrollExtent;
    return target.minScrollExtent;
  }

  void updateCanDrag() {
    if (!_outerPosition.haveDimensions) return;
    double maxInnerExtent = 0.0;
    for (_NestedScrollPosition position in _innerPositions) {
      if (!position.haveDimensions) return;
      maxInnerExtent = math.max(
          maxInnerExtent, position.maxScrollExtent - position.minScrollExtent);
    }
    _outerPosition.updateCanDrag(maxInnerExtent);
  }

  Future<void> animateTo(
    double to, {
    @required Duration duration,
    @required Curve curve,
  }) async {
    final DrivenScrollActivity outerActivity =
        _outerPosition.createDrivenScrollActivity(
      nestOffset(to, _outerPosition),
      duration,
      curve,
    );
    final List<Future<void>> resultFutures = <Future<void>>[outerActivity.done];
    beginActivity(
      outerActivity,
      (_NestedScrollPosition position) {
        final DrivenScrollActivity innerActivity =
            position.createDrivenScrollActivity(
          nestOffset(to, position),
          duration,
          curve,
        );
        resultFutures.add(innerActivity.done);
        return innerActivity;
      },
    );
    await Future.wait<void>(resultFutures);
  }

  void jumpTo(double to) {
    goIdle();
    _outerPosition.localJumpTo(nestOffset(to, _outerPosition));
    for (_NestedScrollPosition position in _innerPositions)
      position.localJumpTo(nestOffset(to, position));
    goBallistic(0.0);
  }

  @override
  double setPixels(double newPixels) {
    assert(false);
    return 0.0;
  }

  ScrollHoldController hold(VoidCallback holdCancelCallback) {
    beginActivity(
      HoldScrollActivity(
          delegate: _outerPosition, onHoldCanceled: holdCancelCallback),
      (_NestedScrollPosition position) =>
          HoldScrollActivity(delegate: position),
    );
    return this;
  }

  @override
  void cancel() {
    goBallistic(0.0);
  }

  Drag drag(DragStartDetails details, VoidCallback dragCancelCallback) {
    final ScrollDragController drag = ScrollDragController(
      delegate: this,
      details: details,
      onDragCanceled: dragCancelCallback,
    );
    beginActivity(
      DragScrollActivity(_outerPosition, drag),
      (_NestedScrollPosition position) => DragScrollActivity(position, drag),
    );
    assert(_currentDrag == null);
    _currentDrag = drag;
    return drag;
  }

  @override
  void applyUserOffset(double delta) {
    updateUserScrollDirection(
        delta > 0.0 ? ScrollDirection.forward : ScrollDirection.reverse);
    assert(delta != 0.0);
    if (_innerPositions.isEmpty) {
      _outerPosition.applyFullDragUpdate(delta);
    } else if (delta < 0.0) {
      final double innerDelta = _outerPosition.applyClampedDragUpdate(delta);
      if (innerDelta != 0.0) {
        for (_NestedScrollPosition position in _innerPositions)
          position.applyFullDragUpdate(innerDelta);
      }
    } else {
      double outerDelta = 0.0;
      final List<double> overscrolls = <double>[];
      final List<_NestedScrollPosition> innerPositions =
          _innerPositions.toList();
      for (_NestedScrollPosition position in innerPositions) {
        final double overscroll = position.applyClampedDragUpdate(delta);
        outerDelta = math.max(outerDelta, overscroll);
        overscrolls.add(overscroll);
      }
      if (outerDelta != 0.0)
        outerDelta -= _outerPosition.applyClampedDragUpdate(outerDelta);

      for (int i = 0; i < innerPositions.length; ++i) {
        final double remainingDelta = overscrolls[i] - outerDelta;
        if (remainingDelta > 0.0)
          innerPositions[i].applyFullDragUpdate(remainingDelta);
      }
    }
  }

  void setParent(ScrollController value) {
    _parent = value;
    updateParent();
  }

  void updateParent() {
    _outerPosition
        ?.setParent(_parent ?? PrimaryScrollController.of(_state.context));
  }

  @mustCallSuper
  void dispose() {
    _currentDrag?.dispose();
    _currentDrag = null;
    _outerController.dispose();
    _innerController.dispose();
  }

  @override
  String toString() =>
      '$runtimeType(outer=$_outerController; inner=$_innerController)';
}

class _NestedScrollController extends ScrollController {
  _NestedScrollController(
    this.coordinator, {
    double initialScrollOffset = 0.0,
    String debugLabel,
  }) : super(initialScrollOffset: initialScrollOffset, debugLabel: debugLabel);

  final _NestedScrollCoordinator coordinator;

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition oldPosition,
  ) {
    return _NestedScrollPosition(
      coordinator: coordinator,
      physics: physics,
      context: context,
      initialPixels: initialScrollOffset,
      oldPosition: oldPosition,
      debugLabel: debugLabel,
    );
  }

  @override
  void attach(ScrollPosition position) {
    assert(position is _NestedScrollPosition);
    super.attach(position);
    coordinator.updateParent();
    coordinator.updateCanDrag();
    position.addListener(_scheduleUpdateShadow);
    _scheduleUpdateShadow();
  }

  @override
  void detach(ScrollPosition position) {
    assert(position is _NestedScrollPosition);
    position.removeListener(_scheduleUpdateShadow);
    super.detach(position);
    _scheduleUpdateShadow();
  }

  void _scheduleUpdateShadow() {
    SchedulerBinding.instance.addPostFrameCallback((Duration timeStamp) {
      coordinator.updateShadow();
    });
  }

  Iterable<_NestedScrollPosition> get nestedPositions sync* {
    yield* Iterable.castFrom<ScrollPosition, _NestedScrollPosition>(positions);
  }
}

class _NestedScrollPosition extends ScrollPosition
    implements ScrollActivityDelegate {
  _NestedScrollPosition({
    @required ScrollPhysics physics,
    @required ScrollContext context,
    double initialPixels = 0.0,
    ScrollPosition oldPosition,
    String debugLabel,
    @required this.coordinator,
  }) : super(
          physics: physics,
          context: context,
          oldPosition: oldPosition,
          debugLabel: debugLabel,
        ) {
    if (pixels == null && initialPixels != null) correctPixels(initialPixels);
    if (activity == null) goIdle();
    assert(activity != null);
    saveScrollOffset();
  }

  final _NestedScrollCoordinator coordinator;

  TickerProvider get vsync => context.vsync;

  ScrollController _parent;

  void setParent(ScrollController value) {
    _parent?.detach(this);
    _parent = value;
    _parent?.attach(this);
  }

  @override
  AxisDirection get axisDirection => context.axisDirection;

  @override
  void absorb(ScrollPosition other) {
    super.absorb(other);
    activity.updateDelegate(this);
  }

  @override
  void restoreScrollOffset() {
    if (coordinator.canScrollBody) super.restoreScrollOffset();
  }

  double applyClampedDragUpdate(double delta) {
    assert(delta != 0.0);

    final double min =
        delta < 0.0 ? -double.infinity : math.min(minScrollExtent, pixels);

    final double max =
        delta > 0.0 ? double.infinity : math.max(maxScrollExtent, pixels);
    final double oldPixels = pixels;
    final double newPixels = (pixels - delta).clamp(min, max);
    final double clampedDelta = newPixels - pixels;
    if (clampedDelta == 0.0) return delta;
    final double overscroll = physics.applyBoundaryConditions(this, newPixels);
    final double actualNewPixels = newPixels - overscroll;
    final double offset = actualNewPixels - oldPixels;
    if (offset != 0.0) {
      forcePixels(actualNewPixels);
      didUpdateScrollPositionBy(offset);
    }
    return delta + offset;
  }

  double applyFullDragUpdate(double delta) {
    assert(delta != 0.0);
    final double oldPixels = pixels;

    final double newPixels =
        pixels - physics.applyPhysicsToUserOffset(this, delta);
    if (oldPixels == newPixels) return 0.0;

    final double overscroll = physics.applyBoundaryConditions(this, newPixels);
    final double actualNewPixels = newPixels - overscroll;
    if (actualNewPixels != oldPixels) {
      forcePixels(actualNewPixels);
      didUpdateScrollPositionBy(actualNewPixels - oldPixels);
    }
    if (overscroll != 0.0) {
      didOverscrollBy(overscroll);
      return overscroll;
    }
    return 0.0;
  }

  @override
  ScrollDirection get userScrollDirection => coordinator.userScrollDirection;

  DrivenScrollActivity createDrivenScrollActivity(
      double to, Duration duration, Curve curve) {
    return DrivenScrollActivity(
      this,
      from: pixels,
      to: to,
      duration: duration,
      curve: curve,
      vsync: vsync,
    );
  }

  @override
  double applyUserOffset(double delta) {
    assert(false);
    return 0.0;
  }

  @override
  void goIdle() {
    beginActivity(IdleScrollActivity(this));
  }

  @override
  void goBallistic(double velocity) {
    Simulation simulation;
    if (velocity != 0.0 || outOfRange)
      simulation = physics.createBallisticSimulation(this, velocity);
    beginActivity(createBallisticScrollActivity(
      simulation,
      mode: _NestedBallisticScrollActivityMode.independent,
    ));
  }

  ScrollActivity createBallisticScrollActivity(
    Simulation simulation, {
    @required _NestedBallisticScrollActivityMode mode,
    _NestedScrollMetrics metrics,
  }) {
    if (simulation == null) return IdleScrollActivity(this);
    assert(mode != null);
    switch (mode) {
      case _NestedBallisticScrollActivityMode.outer:
        assert(metrics != null);
        if (metrics.minRange == metrics.maxRange)
          return IdleScrollActivity(this);
        return _NestedOuterBallisticScrollActivity(
            coordinator, this, metrics, simulation, context.vsync);
      case _NestedBallisticScrollActivityMode.inner:
        return _NestedInnerBallisticScrollActivity(
            coordinator, this, simulation, context.vsync);
      case _NestedBallisticScrollActivityMode.independent:
        return BallisticScrollActivity(this, simulation, context.vsync);
    }
    return null;
  }

  @override
  Future<void> animateTo(
    double to, {
    @required Duration duration,
    @required Curve curve,
  }) {
    return coordinator.animateTo(coordinator.unnestOffset(to, this),
        duration: duration, curve: curve);
  }

  @override
  void jumpTo(double value) {
    return coordinator.jumpTo(coordinator.unnestOffset(value, this));
  }

  @override
  void jumpToWithoutSettling(double value) {
    assert(false);
  }

  void localJumpTo(double value) {
    if (pixels != value) {
      final double oldPixels = pixels;
      forcePixels(value);
      didStartScroll();
      didUpdateScrollPositionBy(pixels - oldPixels);
      didEndScroll();
    }
  }

  @override
  void applyNewDimensions() {
    super.applyNewDimensions();
    coordinator.updateCanDrag();
  }

  void updateCanDrag(double totalExtent) {
    context.setCanDrag(totalExtent > (viewportDimension - maxScrollExtent) ||
        minScrollExtent != maxScrollExtent);
  }

  @override
  ScrollHoldController hold(VoidCallback holdCancelCallback) {
    return coordinator.hold(holdCancelCallback);
  }

  @override
  Drag drag(DragStartDetails details, VoidCallback dragCancelCallback) {
    return coordinator.drag(details, dragCancelCallback);
  }

  @override
  void dispose() {
    _parent?.detach(this);
    super.dispose();
  }
}

enum _NestedBallisticScrollActivityMode { outer, inner, independent }

class _NestedInnerBallisticScrollActivity extends BallisticScrollActivity {
  _NestedInnerBallisticScrollActivity(
    this.coordinator,
    _NestedScrollPosition position,
    Simulation simulation,
    TickerProvider vsync,
  ) : super(position, simulation, vsync);

  final _NestedScrollCoordinator coordinator;

  @override
  _NestedScrollPosition get delegate => super.delegate;

  @override
  void resetActivity() {
    delegate.beginActivity(
        coordinator.createInnerBallisticScrollActivity(delegate, velocity));
  }

  @override
  void applyNewDimensions() {
    delegate.beginActivity(
        coordinator.createInnerBallisticScrollActivity(delegate, velocity));
  }

  @override
  bool applyMoveTo(double value) {
    return super.applyMoveTo(coordinator.nestOffset(value, delegate));
  }
}

class _NestedOuterBallisticScrollActivity extends BallisticScrollActivity {
  _NestedOuterBallisticScrollActivity(
    this.coordinator,
    _NestedScrollPosition position,
    this.metrics,
    Simulation simulation,
    TickerProvider vsync,
  )   : assert(metrics.minRange != metrics.maxRange),
        assert(metrics.maxRange > metrics.minRange),
        super(position, simulation, vsync);

  final _NestedScrollCoordinator coordinator;
  final _NestedScrollMetrics metrics;

  @override
  _NestedScrollPosition get delegate => super.delegate;

  @override
  void resetActivity() {
    delegate.beginActivity(
        coordinator.createOuterBallisticScrollActivity(velocity));
  }

  @override
  void applyNewDimensions() {
    delegate.beginActivity(
        coordinator.createOuterBallisticScrollActivity(velocity));
  }

  @override
  bool applyMoveTo(double value) {
    bool done = false;
    if (velocity > 0.0) {
      if (value < metrics.minRange) return true;
      if (value > metrics.maxRange) {
        value = metrics.maxRange;
        done = true;
      }
    } else if (velocity < 0.0) {
      if (value > metrics.maxRange) return true;
      if (value < metrics.minRange) {
        value = metrics.minRange;
        done = true;
      }
    } else {
      value = value.clamp(metrics.minRange, metrics.maxRange);
      done = true;
    }
    final bool result = super.applyMoveTo(value + metrics.correctionOffset);
    assert(result);
    return !done;
  }

  @override
  String toString() {
    return '$runtimeType(${metrics.minRange} .. ${metrics.maxRange}; correcting by ${metrics.correctionOffset})';
  }
}

class SliverOverlapAbsorberHandle extends ChangeNotifier {
  int _writers = 0;

  double get layoutExtent => _layoutExtent;
  double _layoutExtent;

  double get scrollExtent => _scrollExtent;
  double _scrollExtent;

  void _setExtents(double layoutValue, double scrollValue) {
    assert(_writers == 1,
        'Multiple RenderSliverOverlapAbsorbers have been provided the same SliverOverlapAbsorberHandle.');
    _layoutExtent = layoutValue;
    _scrollExtent = scrollValue;
  }

  void _markNeedsLayout() => notifyListeners();

  @override
  String toString() {
    String extra;
    switch (_writers) {
      case 0:
        extra = ', orphan';
        break;
      case 1:
        break;
      default:
        extra = ', $_writers WRITERS ASSIGNED';
        break;
    }
    return '$runtimeType($layoutExtent$extra)';
  }
}

class SliverOverlapAbsorber extends SingleChildRenderObjectWidget {
  const SliverOverlapAbsorber({
    Key key,
    @required this.handle,
    Widget child,
  })  : assert(handle != null),
        super(key: key, child: child);

  final SliverOverlapAbsorberHandle handle;

  @override
  RenderSliverOverlapAbsorber createRenderObject(BuildContext context) {
    return RenderSliverOverlapAbsorber(
      handle: handle,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderSliverOverlapAbsorber renderObject) {
    renderObject..handle = handle;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
        DiagnosticsProperty<SliverOverlapAbsorberHandle>('handle', handle));
  }
}

class RenderSliverOverlapAbsorber extends RenderSliver
    with RenderObjectWithChildMixin<RenderSliver> {
  RenderSliverOverlapAbsorber({
    @required SliverOverlapAbsorberHandle handle,
    RenderSliver child,
  })  : assert(handle != null),
        _handle = handle {
    this.child = child;
  }

  SliverOverlapAbsorberHandle get handle => _handle;
  SliverOverlapAbsorberHandle _handle;
  set handle(SliverOverlapAbsorberHandle value) {
    assert(value != null);
    if (handle == value) return;
    if (attached) {
      handle._writers -= 1;
      value._writers += 1;
      value._setExtents(handle.layoutExtent, handle.scrollExtent);
    }
    _handle = value;
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    handle._writers += 1;
  }

  @override
  void detach() {
    handle._writers -= 1;
    super.detach();
  }

  @override
  void performLayout() {
    assert(handle._writers == 1,
        'A SliverOverlapAbsorberHandle cannot be passed to multiple RenderSliverOverlapAbsorber objects at the same time.');
    if (child == null) {
      geometry = const SliverGeometry();
      return;
    }
    child.layout(constraints, parentUsesSize: true);
    final SliverGeometry childLayoutGeometry = child.geometry;
    geometry = SliverGeometry(
      scrollExtent: childLayoutGeometry.scrollExtent -
          childLayoutGeometry.maxScrollObstructionExtent,
      paintExtent: childLayoutGeometry.paintExtent,
      paintOrigin: childLayoutGeometry.paintOrigin,
      layoutExtent: childLayoutGeometry.paintExtent -
          childLayoutGeometry.maxScrollObstructionExtent,
      maxPaintExtent: childLayoutGeometry.maxPaintExtent,
      maxScrollObstructionExtent:
          childLayoutGeometry.maxScrollObstructionExtent,
      hitTestExtent: childLayoutGeometry.hitTestExtent,
      visible: childLayoutGeometry.visible,
      hasVisualOverflow: childLayoutGeometry.hasVisualOverflow,
      scrollOffsetCorrection: childLayoutGeometry.scrollOffsetCorrection,
    );
    handle._setExtents(childLayoutGeometry.maxScrollObstructionExtent,
        childLayoutGeometry.maxScrollObstructionExtent);
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {}

  @override
  bool hitTestChildren(SliverHitTestResult result,
      {@required double mainAxisPosition, @required double crossAxisPosition}) {
    if (child != null)
      return child.hitTest(result,
          mainAxisPosition: mainAxisPosition,
          crossAxisPosition: crossAxisPosition);
    return false;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) context.paintChild(child, offset);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
        DiagnosticsProperty<SliverOverlapAbsorberHandle>('handle', handle));
  }
}

class SliverOverlapInjector extends SingleChildRenderObjectWidget {
  const SliverOverlapInjector({
    Key key,
    @required this.handle,
    Widget child,
  })  : assert(handle != null),
        super(key: key, child: child);

  final SliverOverlapAbsorberHandle handle;

  @override
  RenderSliverOverlapInjector createRenderObject(BuildContext context) {
    return RenderSliverOverlapInjector(
      handle: handle,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderSliverOverlapInjector renderObject) {
    renderObject..handle = handle;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
        DiagnosticsProperty<SliverOverlapAbsorberHandle>('handle', handle));
  }
}

class RenderSliverOverlapInjector extends RenderSliver {
  RenderSliverOverlapInjector({
    @required SliverOverlapAbsorberHandle handle,
  })  : assert(handle != null),
        _handle = handle;

  double _currentLayoutExtent;
  double _currentMaxExtent;

  SliverOverlapAbsorberHandle get handle => _handle;
  SliverOverlapAbsorberHandle _handle;
  set handle(SliverOverlapAbsorberHandle value) {
    assert(value != null);
    if (handle == value) return;
    if (attached) {
      handle.removeListener(markNeedsLayout);
    }
    _handle = value;
    if (attached) {
      handle.addListener(markNeedsLayout);
      if (handle.layoutExtent != _currentLayoutExtent ||
          handle.scrollExtent != _currentMaxExtent) markNeedsLayout();
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    handle.addListener(markNeedsLayout);
    if (handle.layoutExtent != _currentLayoutExtent ||
        handle.scrollExtent != _currentMaxExtent) markNeedsLayout();
  }

  @override
  void detach() {
    handle.removeListener(markNeedsLayout);
    super.detach();
  }

  @override
  void performLayout() {
    _currentLayoutExtent = handle.layoutExtent;
    _currentMaxExtent = handle.layoutExtent;
    final double clampedLayoutExtent = math.min(
        _currentLayoutExtent - constraints.scrollOffset,
        constraints.remainingPaintExtent);
    geometry = SliverGeometry(
      scrollExtent: _currentLayoutExtent,
      paintExtent: math.max(0.0, clampedLayoutExtent),
      maxPaintExtent: _currentMaxExtent,
    );
  }

  @override
  void debugPaint(PaintingContext context, Offset offset) {
    assert(() {
      if (debugPaintSizeEnabled) {
        final Paint paint = Paint()
          ..color = const Color(0xFFCC9933)
          ..strokeWidth = 3.0
          ..style = PaintingStyle.stroke;
        Offset start, end, delta;
        switch (constraints.axis) {
          case Axis.vertical:
            final double x = offset.dx + constraints.crossAxisExtent / 2.0;
            start = Offset(x, offset.dy);
            end = Offset(x, offset.dy + geometry.paintExtent);
            delta = Offset(constraints.crossAxisExtent / 5.0, 0.0);
            break;
          case Axis.horizontal:
            final double y = offset.dy + constraints.crossAxisExtent / 2.0;
            start = Offset(offset.dx, y);
            end = Offset(offset.dy + geometry.paintExtent, y);
            delta = Offset(0.0, constraints.crossAxisExtent / 5.0);
            break;
        }
        for (int index = -2; index <= 2; index += 1) {
          paintZigZag(context.canvas, paint, start - delta * index.toDouble(),
              end - delta * index.toDouble(), 10, 10.0);
        }
      }
      return true;
    }());
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
        DiagnosticsProperty<SliverOverlapAbsorberHandle>('handle', handle));
  }
}

class NestedScrollViewViewport extends Viewport {
  NestedScrollViewViewport({
    Key key,
    AxisDirection axisDirection = AxisDirection.down,
    AxisDirection crossAxisDirection,
    double anchor = 0.0,
    @required ViewportOffset offset,
    Key center,
    List<Widget> slivers = const <Widget>[],
    @required this.handle,
  })  : assert(handle != null),
        super(
          key: key,
          axisDirection: axisDirection,
          crossAxisDirection: crossAxisDirection,
          anchor: anchor,
          offset: offset,
          center: center,
          slivers: slivers,
        );

  final SliverOverlapAbsorberHandle handle;

  @override
  RenderNestedScrollViewViewport createRenderObject(BuildContext context) {
    return RenderNestedScrollViewViewport(
      axisDirection: axisDirection,
      crossAxisDirection: crossAxisDirection ??
          Viewport.getDefaultCrossAxisDirection(context, axisDirection),
      anchor: anchor,
      offset: offset,
      handle: handle,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderNestedScrollViewViewport renderObject) {
    renderObject
      ..axisDirection = axisDirection
      ..crossAxisDirection = crossAxisDirection ??
          Viewport.getDefaultCrossAxisDirection(context, axisDirection)
      ..anchor = anchor
      ..offset = offset
      ..handle = handle;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
        DiagnosticsProperty<SliverOverlapAbsorberHandle>('handle', handle));
  }
}

class RenderNestedScrollViewViewport extends RenderViewport {
  RenderNestedScrollViewViewport({
    AxisDirection axisDirection = AxisDirection.down,
    @required AxisDirection crossAxisDirection,
    @required ViewportOffset offset,
    double anchor = 0.0,
    List<RenderSliver> children,
    RenderSliver center,
    @required SliverOverlapAbsorberHandle handle,
  })  : assert(handle != null),
        _handle = handle,
        super(
          axisDirection: axisDirection,
          crossAxisDirection: crossAxisDirection,
          offset: offset,
          anchor: anchor,
          children: children,
          center: center,
        );

  SliverOverlapAbsorberHandle get handle => _handle;
  SliverOverlapAbsorberHandle _handle;

  set handle(SliverOverlapAbsorberHandle value) {
    assert(value != null);
    if (handle == value) return;
    _handle = value;
    handle._markNeedsLayout();
  }

  @override
  void markNeedsLayout() {
    handle._markNeedsLayout();
    super.markNeedsLayout();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
        DiagnosticsProperty<SliverOverlapAbsorberHandle>('handle', handle));
  }
}

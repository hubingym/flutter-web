import 'dart:async';

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/gestures.dart';
import 'package:flutter_web/physics.dart';
import 'package:flutter_web/rendering.dart';
import 'package:flutter_web/scheduler.dart';

import 'basic.dart';
import 'framework.dart';
import 'gesture_detector.dart';
import 'page_storage.dart';
import 'scroll_activity.dart';
import 'scroll_context.dart';
import 'scroll_metrics.dart';
import 'scroll_notification.dart';
import 'scroll_physics.dart';

export 'scroll_activity.dart' show ScrollHoldController;

abstract class ScrollPosition extends ViewportOffset with ScrollMetrics {
  ScrollPosition({
    @required this.physics,
    @required this.context,
    this.keepScrollOffset = true,
    ScrollPosition oldPosition,
    this.debugLabel,
  })  : assert(physics != null),
        assert(context != null),
        assert(context.vsync != null),
        assert(keepScrollOffset != null) {
    if (oldPosition != null) absorb(oldPosition);
    if (keepScrollOffset) restoreScrollOffset();
  }

  final ScrollPhysics physics;

  final ScrollContext context;

  final bool keepScrollOffset;

  final String debugLabel;

  @override
  double get minScrollExtent => _minScrollExtent;
  double _minScrollExtent;

  @override
  double get maxScrollExtent => _maxScrollExtent;
  double _maxScrollExtent;

  @override
  double get pixels => _pixels;
  double _pixels;

  @override
  double get viewportDimension => _viewportDimension;
  double _viewportDimension;

  bool get haveDimensions => _haveDimensions;
  bool _haveDimensions = false;

  @protected
  @mustCallSuper
  void absorb(ScrollPosition other) {
    assert(other != null);
    assert(other.context == context);
    assert(_pixels == null);
    _minScrollExtent = other.minScrollExtent;
    _maxScrollExtent = other.maxScrollExtent;
    _pixels = other._pixels;
    _viewportDimension = other.viewportDimension;

    assert(activity == null);
    assert(other.activity != null);
    _activity = other.activity;
    other._activity = null;
    if (other.runtimeType != runtimeType) activity.resetActivity();
    context.setIgnorePointer(activity.shouldIgnorePointer);
    isScrollingNotifier.value = activity.isScrolling;
  }

  double setPixels(double newPixels) {
    assert(_pixels != null);
    assert(SchedulerBinding.instance.schedulerPhase.index <=
        SchedulerPhase.transientCallbacks.index);
    if (newPixels != pixels) {
      final double overscroll = applyBoundaryConditions(newPixels);
      assert(() {
        final double delta = newPixels - pixels;
        if (overscroll.abs() > delta.abs()) {
          throw FlutterError(
              '$runtimeType.applyBoundaryConditions returned invalid overscroll value.\n'
              'setPixels() was called to change the scroll offset from $pixels to $newPixels.\n'
              'That is a delta of $delta units.\n'
              '$runtimeType.applyBoundaryConditions reported an overscroll of $overscroll units.');
        }
        return true;
      }());
      final double oldPixels = _pixels;
      _pixels = newPixels - overscroll;
      if (_pixels != oldPixels) {
        notifyListeners();
        didUpdateScrollPositionBy(_pixels - oldPixels);
      }
      if (overscroll != 0.0) {
        didOverscrollBy(overscroll);
        return overscroll;
      }
    }
    return 0.0;
  }

  void correctPixels(double value) {
    _pixels = value;
  }

  @override
  void correctBy(double correction) {
    assert(
      _pixels != null,
      'An initial pixels value must exist by caling correctPixels on the ScrollPosition',
    );
    _pixels += correction;
    _didChangeViewportDimensionOrReceiveCorrection = true;
  }

  @protected
  void forcePixels(double value) {
    assert(pixels != null);
    _pixels = value;
    notifyListeners();
  }

  @protected
  void saveScrollOffset() {
    PageStorage.of(context.storageContext)
        ?.writeState(context.storageContext, pixels);
  }

  @protected
  void restoreScrollOffset() {
    if (pixels == null) {
      final double value = PageStorage.of(context.storageContext)
          ?.readState(context.storageContext);
      if (value != null) correctPixels(value);
    }
  }

  @protected
  double applyBoundaryConditions(double value) {
    final double result = physics.applyBoundaryConditions(this, value);
    assert(() {
      final double delta = value - pixels;
      if (result.abs() > delta.abs()) {
        throw FlutterError(
            '${physics.runtimeType}.applyBoundaryConditions returned invalid overscroll value.\n'
            'The method was called to consider a change from $pixels to $value, which is a '
            'delta of ${delta.toStringAsFixed(1)} units. However, it returned an overscroll of '
            '${result.toStringAsFixed(1)} units, which has a greater magnitude than the delta. '
            'The applyBoundaryConditions method is only supposed to reduce the possible range '
            'of movement, not increase it.\n'
            'The scroll extents are $minScrollExtent .. $maxScrollExtent, and the '
            'viewport dimension is $viewportDimension.');
      }
      return true;
    }());
    return result;
  }

  bool _didChangeViewportDimensionOrReceiveCorrection = true;

  @override
  bool applyViewportDimension(double viewportDimension) {
    if (_viewportDimension != viewportDimension) {
      _viewportDimension = viewportDimension;
      _didChangeViewportDimensionOrReceiveCorrection = true;
    }
    return true;
  }

  Set<SemanticsAction> _semanticActions;

  void _updateSemanticActions() {
    SemanticsAction forward;
    SemanticsAction backward;
    switch (axis) {
      case Axis.vertical:
        forward = SemanticsAction.scrollUp;
        backward = SemanticsAction.scrollDown;
        break;
      case Axis.horizontal:
        forward = SemanticsAction.scrollLeft;
        backward = SemanticsAction.scrollRight;
        break;
    }

    final Set<SemanticsAction> actions = Set<SemanticsAction>();
    if (pixels > minScrollExtent) actions.add(backward);
    if (pixels < maxScrollExtent) actions.add(forward);

    if (setEquals<SemanticsAction>(actions, _semanticActions)) return;

    _semanticActions = actions;
    context.setSemanticsActions(_semanticActions);
  }

  @override
  bool applyContentDimensions(double minScrollExtent, double maxScrollExtent) {
    if (!nearEqual(_minScrollExtent, minScrollExtent,
            Tolerance.defaultTolerance.distance) ||
        !nearEqual(_maxScrollExtent, maxScrollExtent,
            Tolerance.defaultTolerance.distance) ||
        _didChangeViewportDimensionOrReceiveCorrection) {
      _minScrollExtent = minScrollExtent;
      _maxScrollExtent = maxScrollExtent;
      _haveDimensions = true;
      applyNewDimensions();
      _didChangeViewportDimensionOrReceiveCorrection = false;
    }
    return true;
  }

  @protected
  @mustCallSuper
  void applyNewDimensions() {
    assert(pixels != null);
    activity.applyNewDimensions();
    _updateSemanticActions();
  }

  Future<void> ensureVisible(
    RenderObject object, {
    double alignment = 0.0,
    Duration duration = Duration.zero,
    Curve curve = Curves.ease,
  }) {
    assert(object.attached);
    final RenderAbstractViewport viewport = RenderAbstractViewport.of(object);
    assert(viewport != null);

    final double target = viewport
        .getOffsetToReveal(object, alignment)
        .offset
        .clamp(minScrollExtent, maxScrollExtent);

    if (target == pixels) return Future<void>.value();

    if (duration == Duration.zero) {
      jumpTo(target);
      return Future<void>.value();
    }

    return animateTo(target, duration: duration, curve: curve);
  }

  final ValueNotifier<bool> isScrollingNotifier = ValueNotifier<bool>(false);

  @override
  Future<void> animateTo(
    double to, {
    @required Duration duration,
    @required Curve curve,
  });

  @override
  void jumpTo(double value);

  @override
  Future<void> moveTo(
    double to, {
    Duration duration,
    Curve curve,
    bool clamp = true,
  }) {
    assert(to != null);
    assert(clamp != null);

    if (clamp) to = to.clamp(minScrollExtent, maxScrollExtent);

    return super.moveTo(to, duration: duration, curve: curve);
  }

  @override
  bool get allowImplicitScrolling => physics.allowImplicitScrolling;

  @Deprecated('This will lead to bugs.')
  void jumpToWithoutSettling(double value);

  ScrollHoldController hold(VoidCallback holdCancelCallback);

  Drag drag(DragStartDetails details, VoidCallback dragCancelCallback);

  @protected
  ScrollActivity get activity => _activity;
  ScrollActivity _activity;

  void beginActivity(ScrollActivity newActivity) {
    if (newActivity == null) return;
    bool wasScrolling, oldIgnorePointer;
    if (_activity != null) {
      oldIgnorePointer = _activity.shouldIgnorePointer;
      wasScrolling = _activity.isScrolling;
      if (wasScrolling && !newActivity.isScrolling) didEndScroll();
      _activity.dispose();
    } else {
      oldIgnorePointer = false;
      wasScrolling = false;
    }
    _activity = newActivity;
    if (oldIgnorePointer != activity.shouldIgnorePointer)
      context.setIgnorePointer(activity.shouldIgnorePointer);
    isScrollingNotifier.value = activity.isScrolling;
    if (!wasScrolling && _activity.isScrolling) didStartScroll();
  }

  void didStartScroll() {
    activity.dispatchScrollStartNotification(
        copyWith(), context.notificationContext);
  }

  void didUpdateScrollPositionBy(double delta) {
    activity.dispatchScrollUpdateNotification(
        copyWith(), context.notificationContext, delta);
  }

  void didEndScroll() {
    activity.dispatchScrollEndNotification(
        copyWith(), context.notificationContext);
    if (keepScrollOffset) saveScrollOffset();
  }

  void didOverscrollBy(double value) {
    assert(activity.isScrolling);
    activity.dispatchOverscrollNotification(
        copyWith(), context.notificationContext, value);
  }

  void didUpdateScrollDirection(ScrollDirection direction) {
    UserScrollNotification(
            metrics: copyWith(),
            context: context.notificationContext,
            direction: direction)
        .dispatch(context.notificationContext);
  }

  @override
  void dispose() {
    assert(pixels != null);
    activity?.dispose();
    _activity = null;
    super.dispose();
  }

  @override
  void notifyListeners() {
    _updateSemanticActions();
    super.notifyListeners();
  }

  @override
  void debugFillDescription(List<String> description) {
    if (debugLabel != null) description.add(debugLabel);
    super.debugFillDescription(description);
    description.add(
        'range: ${minScrollExtent?.toStringAsFixed(1)}..${maxScrollExtent?.toStringAsFixed(1)}');
    description.add('viewport: ${viewportDimension?.toStringAsFixed(1)}');
  }
}

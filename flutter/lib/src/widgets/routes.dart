import 'dart:async';

import 'package:flutter_web/foundation.dart';

import 'basic.dart';
import 'focus_manager.dart';
import 'focus_scope.dart';
import 'framework.dart';
import 'modal_barrier.dart';
import 'navigator.dart';
import 'overlay.dart';
import 'page_storage.dart';
import 'transitions.dart';

const Color _kTransparent = Color(0x00000000);

abstract class OverlayRoute<T> extends Route<T> {
  OverlayRoute({
    RouteSettings settings,
  }) : super(settings: settings);

  Iterable<OverlayEntry> createOverlayEntries();

  @override
  List<OverlayEntry> get overlayEntries => _overlayEntries;
  final List<OverlayEntry> _overlayEntries = <OverlayEntry>[];

  @override
  void install(OverlayEntry insertionPoint) {
    assert(_overlayEntries.isEmpty);
    _overlayEntries.addAll(createOverlayEntries());
    navigator.overlay?.insertAll(_overlayEntries, above: insertionPoint);
    super.install(insertionPoint);
  }

  @protected
  bool get finishedWhenPopped => true;

  @override
  bool didPop(T result) {
    final bool returnValue = super.didPop(result);
    assert(returnValue);
    if (finishedWhenPopped) navigator.finalizeRoute(this);
    return returnValue;
  }

  @override
  void dispose() {
    for (OverlayEntry entry in _overlayEntries) entry.remove();
    _overlayEntries.clear();
    super.dispose();
  }
}

abstract class TransitionRoute<T> extends OverlayRoute<T> {
  TransitionRoute({
    RouteSettings settings,
  }) : super(settings: settings);

  Future<T> get completed => _transitionCompleter.future;
  final Completer<T> _transitionCompleter = Completer<T>();

  Duration get transitionDuration;

  bool get opaque;

  @override
  bool get finishedWhenPopped =>
      _controller.status == AnimationStatus.dismissed;

  Animation<double> get animation => _animation;
  Animation<double> _animation;

  @protected
  AnimationController get controller => _controller;
  AnimationController _controller;

  Animation<double> get secondaryAnimation => _secondaryAnimation;
  final ProxyAnimation _secondaryAnimation =
      ProxyAnimation(kAlwaysDismissedAnimation);

  AnimationController createAnimationController() {
    assert(!_transitionCompleter.isCompleted,
        'Cannot reuse a $runtimeType after disposing it.');
    final Duration duration = transitionDuration;
    assert(duration != null && duration >= Duration.zero);
    return AnimationController(
      duration: duration,
      debugLabel: debugLabel,
      vsync: navigator,
    );
  }

  Animation<double> createAnimation() {
    assert(!_transitionCompleter.isCompleted,
        'Cannot reuse a $runtimeType after disposing it.');
    assert(_controller != null);
    return _controller.view;
  }

  T _result;

  void _handleStatusChanged(AnimationStatus status) {
    switch (status) {
      case AnimationStatus.completed:
        if (overlayEntries.isNotEmpty) overlayEntries.first.opaque = opaque;
        break;
      case AnimationStatus.forward:
      case AnimationStatus.reverse:
        if (overlayEntries.isNotEmpty) overlayEntries.first.opaque = false;
        break;
      case AnimationStatus.dismissed:
        if (!isActive) {
          navigator.finalizeRoute(this);
          assert(overlayEntries.isEmpty);
        }
        break;
    }
    changedInternalState();
  }

  @override
  void install(OverlayEntry insertionPoint) {
    assert(!_transitionCompleter.isCompleted,
        'Cannot install a $runtimeType after disposing it.');
    _controller = createAnimationController();
    assert(_controller != null,
        '$runtimeType.createAnimationController() returned null.');
    _animation = createAnimation();
    assert(_animation != null, '$runtimeType.createAnimation() returned null.');
    super.install(insertionPoint);
  }

  @override
  TickerFuture didPush() {
    assert(_controller != null,
        '$runtimeType.didPush called before calling install() or after calling dispose().');
    assert(!_transitionCompleter.isCompleted,
        'Cannot reuse a $runtimeType after disposing it.');
    _animation.addStatusListener(_handleStatusChanged);
    return _controller.forward();
  }

  @override
  void didReplace(Route<dynamic> oldRoute) {
    assert(_controller != null,
        '$runtimeType.didReplace called before calling install() or after calling dispose().');
    assert(!_transitionCompleter.isCompleted,
        'Cannot reuse a $runtimeType after disposing it.');
    if (oldRoute is TransitionRoute)
      _controller.value = oldRoute._controller.value;
    _animation.addStatusListener(_handleStatusChanged);
    super.didReplace(oldRoute);
  }

  @override
  bool didPop(T result) {
    assert(_controller != null,
        '$runtimeType.didPop called before calling install() or after calling dispose().');
    assert(!_transitionCompleter.isCompleted,
        'Cannot reuse a $runtimeType after disposing it.');
    _result = result;
    _controller.reverse();
    return super.didPop(result);
  }

  @override
  void didPopNext(Route<dynamic> nextRoute) {
    assert(_controller != null,
        '$runtimeType.didPopNext called before calling install() or after calling dispose().');
    assert(!_transitionCompleter.isCompleted,
        'Cannot reuse a $runtimeType after disposing it.');
    _updateSecondaryAnimation(nextRoute);
    super.didPopNext(nextRoute);
  }

  @override
  void didChangeNext(Route<dynamic> nextRoute) {
    assert(_controller != null,
        '$runtimeType.didChangeNext called before calling install() or after calling dispose().');
    assert(!_transitionCompleter.isCompleted,
        'Cannot reuse a $runtimeType after disposing it.');
    _updateSecondaryAnimation(nextRoute);
    super.didChangeNext(nextRoute);
  }

  void _updateSecondaryAnimation(Route<dynamic> nextRoute) {
    if (nextRoute is TransitionRoute<dynamic> &&
        canTransitionTo(nextRoute) &&
        nextRoute.canTransitionFrom(this)) {
      final Animation<double> current = _secondaryAnimation.parent;
      if (current != null) {
        if (current is TrainHoppingAnimation) {
          TrainHoppingAnimation newAnimation;
          newAnimation = TrainHoppingAnimation(
            current.currentTrain,
            nextRoute._animation,
            onSwitchedTrain: () {
              assert(_secondaryAnimation.parent == newAnimation);
              assert(newAnimation.currentTrain == nextRoute._animation);
              _secondaryAnimation.parent = newAnimation.currentTrain;
              newAnimation.dispose();
            },
          );
          _secondaryAnimation.parent = newAnimation;
          current.dispose();
        } else {
          _secondaryAnimation.parent =
              TrainHoppingAnimation(current, nextRoute._animation);
        }
      } else {
        _secondaryAnimation.parent = nextRoute._animation;
      }
    } else {
      _secondaryAnimation.parent = kAlwaysDismissedAnimation;
    }
  }

  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) => true;

  bool canTransitionFrom(TransitionRoute<dynamic> previousRoute) => true;

  @override
  void dispose() {
    assert(!_transitionCompleter.isCompleted,
        'Cannot dispose a $runtimeType twice.');
    _controller?.dispose();
    _transitionCompleter.complete(_result);
    super.dispose();
  }

  String get debugLabel => '$runtimeType';

  @override
  String toString() => '$runtimeType(animation: $_controller)';
}

class LocalHistoryEntry {
  LocalHistoryEntry({this.onRemove});

  final VoidCallback onRemove;

  LocalHistoryRoute<dynamic> _owner;

  void remove() {
    _owner.removeLocalHistoryEntry(this);
    assert(_owner == null);
  }

  void _notifyRemoved() {
    if (onRemove != null) onRemove();
  }
}

mixin LocalHistoryRoute<T> on Route<T> {
  List<LocalHistoryEntry> _localHistory;

  void addLocalHistoryEntry(LocalHistoryEntry entry) {
    assert(entry._owner == null);
    entry._owner = this;
    _localHistory ??= <LocalHistoryEntry>[];
    final bool wasEmpty = _localHistory.isEmpty;
    _localHistory.add(entry);
    if (wasEmpty) changedInternalState();
  }

  void removeLocalHistoryEntry(LocalHistoryEntry entry) {
    assert(entry != null);
    assert(entry._owner == this);
    assert(_localHistory.contains(entry));
    _localHistory.remove(entry);
    entry._owner = null;
    entry._notifyRemoved();
    if (_localHistory.isEmpty) changedInternalState();
  }

  @override
  Future<RoutePopDisposition> willPop() async {
    if (willHandlePopInternally) return RoutePopDisposition.pop;
    return await super.willPop();
  }

  @override
  bool didPop(T result) {
    if (_localHistory != null && _localHistory.isNotEmpty) {
      final LocalHistoryEntry entry = _localHistory.removeLast();
      assert(entry._owner == this);
      entry._owner = null;
      entry._notifyRemoved();
      if (_localHistory.isEmpty) changedInternalState();
      return false;
    }
    return super.didPop(result);
  }

  @override
  bool get willHandlePopInternally {
    return _localHistory != null && _localHistory.isNotEmpty;
  }
}

class _ModalScopeStatus extends InheritedWidget {
  const _ModalScopeStatus({
    Key key,
    @required this.isCurrent,
    @required this.canPop,
    @required this.route,
    @required Widget child,
  })  : assert(isCurrent != null),
        assert(canPop != null),
        assert(route != null),
        assert(child != null),
        super(key: key, child: child);

  final bool isCurrent;
  final bool canPop;
  final Route<dynamic> route;

  @override
  bool updateShouldNotify(_ModalScopeStatus old) {
    return isCurrent != old.isCurrent ||
        canPop != old.canPop ||
        route != old.route;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(FlagProperty('isCurrent',
        value: isCurrent, ifTrue: 'active', ifFalse: 'inactive'));
    description.add(FlagProperty('canPop', value: canPop, ifTrue: 'can pop'));
  }
}

class _ModalScope<T> extends StatefulWidget {
  const _ModalScope({
    Key key,
    this.route,
  }) : super(key: key);

  final ModalRoute<T> route;

  @override
  _ModalScopeState<T> createState() => _ModalScopeState<T>();
}

class _ModalScopeState<T> extends State<_ModalScope<T>> {
  Widget _page;

  Listenable _listenable;

  final FocusScopeNode focusScopeNode =
      FocusScopeNode(debugLabel: '$_ModalScopeState Focus Scope');

  @override
  void initState() {
    super.initState();
    final List<Listenable> animations = <Listenable>[];
    if (widget.route.animation != null) animations.add(widget.route.animation);
    if (widget.route.secondaryAnimation != null)
      animations.add(widget.route.secondaryAnimation);
    _listenable = Listenable.merge(animations);
    if (widget.route.isCurrent) {
      widget.route.navigator.focusScopeNode.setFirstFocus(focusScopeNode);
    }
  }

  @override
  void didUpdateWidget(_ModalScope<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    assert(widget.route == oldWidget.route);
    if (widget.route.isCurrent) {
      widget.route.navigator.focusScopeNode.setFirstFocus(focusScopeNode);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _page = null;
  }

  void _forceRebuildPage() {
    setState(() {
      _page = null;
    });
  }

  @override
  void dispose() {
    focusScopeNode.dispose();
    super.dispose();
  }

  void _routeSetState(VoidCallback fn) {
    setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return _ModalScopeStatus(
      route: widget.route,
      isCurrent: widget.route.isCurrent,
      canPop: widget.route.canPop,
      child: Offstage(
        offstage: widget.route.offstage,
        child: PageStorage(
          bucket: widget.route._storageBucket,
          child: FocusScope(
            node: focusScopeNode,
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _listenable,
                builder: (BuildContext context, Widget child) {
                  return widget.route.buildTransitions(
                    context,
                    widget.route.animation,
                    widget.route.secondaryAnimation,
                    IgnorePointer(
                      ignoring: widget.route.animation?.status ==
                          AnimationStatus.reverse,
                      child: child,
                    ),
                  );
                },
                child: _page ??= RepaintBoundary(
                  key: widget.route._subtreeKey,
                  child: Builder(
                    builder: (BuildContext context) {
                      return widget.route.buildPage(
                        context,
                        widget.route.animation,
                        widget.route.secondaryAnimation,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

abstract class ModalRoute<T> extends TransitionRoute<T>
    with LocalHistoryRoute<T> {
  ModalRoute({
    RouteSettings settings,
  }) : super(settings: settings);

  @optionalTypeArgs
  static ModalRoute<T> of<T extends Object>(BuildContext context) {
    final _ModalScopeStatus widget =
        context.inheritFromWidgetOfExactType(_ModalScopeStatus);
    return widget?.route;
  }

  @protected
  void setState(VoidCallback fn) {
    if (_scopeKey.currentState != null) {
      _scopeKey.currentState._routeSetState(fn);
    } else {
      fn();
    }
  }

  static RoutePredicate withName(String name) {
    return (Route<dynamic> route) {
      return !route.willHandlePopInternally &&
          route is ModalRoute &&
          route.settings.name == name;
    };
  }

  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation);

  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }

  @override
  void install(OverlayEntry insertionPoint) {
    super.install(insertionPoint);
    _animationProxy = ProxyAnimation(super.animation);
    _secondaryAnimationProxy = ProxyAnimation(super.secondaryAnimation);
  }

  @override
  TickerFuture didPush() {
    if (_scopeKey.currentState != null) {
      navigator.focusScopeNode
          .setFirstFocus(_scopeKey.currentState.focusScopeNode);
    }
    return super.didPush();
  }

  bool get barrierDismissible;

  bool get semanticsDismissible => true;

  Color get barrierColor;

  String get barrierLabel;

  bool get maintainState;

  bool get offstage => _offstage;
  bool _offstage = false;
  set offstage(bool value) {
    if (_offstage == value) return;
    setState(() {
      _offstage = value;
    });
    _animationProxy.parent =
        _offstage ? kAlwaysCompleteAnimation : super.animation;
    _secondaryAnimationProxy.parent =
        _offstage ? kAlwaysDismissedAnimation : super.secondaryAnimation;
  }

  BuildContext get subtreeContext => _subtreeKey.currentContext;

  @override
  Animation<double> get animation => _animationProxy;
  ProxyAnimation _animationProxy;

  @override
  Animation<double> get secondaryAnimation => _secondaryAnimationProxy;
  ProxyAnimation _secondaryAnimationProxy;

  final List<WillPopCallback> _willPopCallbacks = <WillPopCallback>[];

  @override
  Future<RoutePopDisposition> willPop() async {
    final _ModalScopeState<T> scope = _scopeKey.currentState;
    assert(scope != null);
    for (WillPopCallback callback
        in List<WillPopCallback>.from(_willPopCallbacks)) {
      if (!await callback()) return RoutePopDisposition.doNotPop;
    }
    return await super.willPop();
  }

  void addScopedWillPopCallback(WillPopCallback callback) {
    assert(_scopeKey.currentState != null,
        'Tried to add a willPop callback to a route that is not currently in the tree.');
    _willPopCallbacks.add(callback);
  }

  void removeScopedWillPopCallback(WillPopCallback callback) {
    assert(_scopeKey.currentState != null,
        'Tried to remove a willPop callback from a route that is not currently in the tree.');
    _willPopCallbacks.remove(callback);
  }

  @protected
  bool get hasScopedWillPopCallback {
    return _willPopCallbacks.isNotEmpty;
  }

  @override
  void didChangePrevious(Route<dynamic> previousRoute) {
    super.didChangePrevious(previousRoute);
    changedInternalState();
  }

  @override
  void changedInternalState() {
    super.changedInternalState();
    setState(() {});
    _modalBarrier.markNeedsBuild();
  }

  @override
  void changedExternalState() {
    super.changedExternalState();
    if (_scopeKey.currentState != null)
      _scopeKey.currentState._forceRebuildPage();
  }

  bool get canPop => !isFirst || willHandlePopInternally;

  final GlobalKey<_ModalScopeState<T>> _scopeKey =
      GlobalKey<_ModalScopeState<T>>();
  final GlobalKey _subtreeKey = GlobalKey();
  final PageStorageBucket _storageBucket = PageStorageBucket();

  static final Animatable<double> _easeCurveTween =
      CurveTween(curve: Curves.ease);

  OverlayEntry _modalBarrier;
  Widget _buildModalBarrier(BuildContext context) {
    Widget barrier;
    if (barrierColor != null && !offstage) {
      assert(barrierColor != _kTransparent);
      final Animation<Color> color = animation.drive(
        ColorTween(
          begin: _kTransparent,
          end: barrierColor,
        ).chain(_easeCurveTween),
      );
      barrier = AnimatedModalBarrier(
        color: color,
        dismissible: barrierDismissible,
        semanticsLabel: barrierLabel,
        barrierSemanticsDismissible: semanticsDismissible,
      );
    } else {
      barrier = ModalBarrier(
        dismissible: barrierDismissible,
        semanticsLabel: barrierLabel,
        barrierSemanticsDismissible: semanticsDismissible,
      );
    }
    return IgnorePointer(
      ignoring: animation.status == AnimationStatus.reverse ||
          animation.status == AnimationStatus.dismissed,
      child: barrier,
    );
  }

  Widget _modalScopeCache;

  Widget _buildModalScope(BuildContext context) {
    return _modalScopeCache ??= _ModalScope<T>(
      key: _scopeKey,
      route: this,
    );
  }

  @override
  Iterable<OverlayEntry> createOverlayEntries() sync* {
    yield _modalBarrier = OverlayEntry(builder: _buildModalBarrier);
    yield OverlayEntry(builder: _buildModalScope, maintainState: maintainState);
  }

  @override
  String toString() => '$runtimeType($settings, animation: $_animation)';
}

abstract class PopupRoute<T> extends ModalRoute<T> {
  PopupRoute({
    RouteSettings settings,
  }) : super(settings: settings);

  @override
  bool get opaque => false;

  @override
  bool get maintainState => true;
}

class RouteObserver<R extends Route<dynamic>> extends NavigatorObserver {
  final Map<R, Set<RouteAware>> _listeners = <R, Set<RouteAware>>{};

  void subscribe(RouteAware routeAware, R route) {
    assert(routeAware != null);
    assert(route != null);
    final Set<RouteAware> subscribers =
        _listeners.putIfAbsent(route, () => <RouteAware>{});
    if (subscribers.add(routeAware)) {
      routeAware.didPush();
    }
  }

  void unsubscribe(RouteAware routeAware) {
    assert(routeAware != null);
    for (R route in _listeners.keys) {
      final Set<RouteAware> subscribers = _listeners[route];
      subscribers?.remove(routeAware);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic> previousRoute) {
    if (route is R && previousRoute is R) {
      final List<RouteAware> previousSubscribers =
          _listeners[previousRoute]?.toList();

      if (previousSubscribers != null) {
        for (RouteAware routeAware in previousSubscribers) {
          routeAware.didPopNext();
        }
      }

      final List<RouteAware> subscribers = _listeners[route]?.toList();

      if (subscribers != null) {
        for (RouteAware routeAware in subscribers) {
          routeAware.didPop();
        }
      }
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic> previousRoute) {
    if (route is R && previousRoute is R) {
      final Set<RouteAware> previousSubscribers = _listeners[previousRoute];

      if (previousSubscribers != null) {
        for (RouteAware routeAware in previousSubscribers) {
          routeAware.didPushNext();
        }
      }
    }
  }
}

abstract class RouteAware {
  void didPopNext() {}

  void didPush() {}

  void didPop() {}

  void didPushNext() {}
}

class _DialogRoute<T> extends PopupRoute<T> {
  _DialogRoute({
    @required RoutePageBuilder pageBuilder,
    bool barrierDismissible = true,
    String barrierLabel,
    Color barrierColor = const Color(0x80000000),
    Duration transitionDuration = const Duration(milliseconds: 200),
    RouteTransitionsBuilder transitionBuilder,
    RouteSettings settings,
  })  : assert(barrierDismissible != null),
        _pageBuilder = pageBuilder,
        _barrierDismissible = barrierDismissible,
        _barrierLabel = barrierLabel,
        _barrierColor = barrierColor,
        _transitionDuration = transitionDuration,
        _transitionBuilder = transitionBuilder,
        super(settings: settings);

  final RoutePageBuilder _pageBuilder;

  @override
  bool get barrierDismissible => _barrierDismissible;
  final bool _barrierDismissible;

  @override
  String get barrierLabel => _barrierLabel;
  final String _barrierLabel;

  @override
  Color get barrierColor => _barrierColor;
  final Color _barrierColor;

  @override
  Duration get transitionDuration => _transitionDuration;
  final Duration _transitionDuration;

  final RouteTransitionsBuilder _transitionBuilder;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return Semantics(
      child: _pageBuilder(context, animation, secondaryAnimation),
      scopesRoute: true,
      explicitChildNodes: true,
    );
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    if (_transitionBuilder == null) {
      return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.linear,
          ),
          child: child);
    }
    return _transitionBuilder(context, animation, secondaryAnimation, child);
  }
}

Future<T> showGeneralDialog<T>({
  @required BuildContext context,
  @required RoutePageBuilder pageBuilder,
  bool barrierDismissible,
  String barrierLabel,
  Color barrierColor,
  Duration transitionDuration,
  RouteTransitionsBuilder transitionBuilder,
}) {
  assert(pageBuilder != null);
  assert(!barrierDismissible || barrierLabel != null);
  return Navigator.of(context, rootNavigator: true).push<T>(_DialogRoute<T>(
    pageBuilder: pageBuilder,
    barrierDismissible: barrierDismissible,
    barrierLabel: barrierLabel,
    barrierColor: barrierColor,
    transitionDuration: transitionDuration,
    transitionBuilder: transitionBuilder,
  ));
}

typedef RoutePageBuilder = Widget Function(BuildContext context,
    Animation<double> animation, Animation<double> secondaryAnimation);

typedef RouteTransitionsBuilder = Widget Function(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child);

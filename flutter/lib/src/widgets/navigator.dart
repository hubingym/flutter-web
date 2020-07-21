import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/rendering.dart';
import 'package:flutter_web/scheduler.dart';
import 'package:flutter_web/ui.dart' show isWeb;

import 'basic.dart';
import '../widgets/binding.dart';
import 'focus_manager.dart';
import 'focus_scope.dart';
import 'framework.dart';
import 'overlay.dart';
import 'ticker_provider.dart';
import '../util.dart';

typedef RouteFactory = Route<dynamic> Function(RouteSettings settings);

typedef RoutePredicate = bool Function(Route<dynamic> route);

typedef WillPopCallback = Future<bool> Function();

enum RoutePopDisposition {
  pop,

  doNotPop,

  bubble,
}

abstract class Route<T> {
  Route({RouteSettings settings})
      : settings = settings ?? const RouteSettings();

  NavigatorState get navigator => _navigator;
  NavigatorState _navigator;

  final RouteSettings settings;

  List<OverlayEntry> get overlayEntries => const <OverlayEntry>[];

  @protected
  @mustCallSuper
  void install(OverlayEntry insertionPoint) {}

  @protected
  TickerFuture didPush() => TickerFuture.complete();

  @protected
  @mustCallSuper
  void didReplace(Route<dynamic> oldRoute) {}

  Future<RoutePopDisposition> willPop() async {
    return isFirst ? RoutePopDisposition.bubble : RoutePopDisposition.pop;
  }

  bool get willHandlePopInternally => false;

  T get currentResult => null;

  Future<T> get popped => _popCompleter.future;
  final Completer<T> _popCompleter = Completer<T>();

  @protected
  @mustCallSuper
  bool didPop(T result) {
    didComplete(result);
    return true;
  }

  @protected
  @mustCallSuper
  void didComplete(T result) {
    _popCompleter.complete(result);
  }

  @protected
  @mustCallSuper
  void didPopNext(Route<dynamic> nextRoute) {}

  @protected
  @mustCallSuper
  void didChangeNext(Route<dynamic> nextRoute) {}

  @protected
  @mustCallSuper
  void didChangePrevious(Route<dynamic> previousRoute) {}

  @protected
  @mustCallSuper
  void changedInternalState() {}

  @protected
  @mustCallSuper
  void changedExternalState() {}

  @mustCallSuper
  @protected
  void dispose() {
    _navigator = null;
  }

  bool get isCurrent {
    return _navigator != null && _navigator._history.last == this;
  }

  bool get isFirst {
    return _navigator != null && _navigator._history.first == this;
  }

  bool get isActive {
    return _navigator != null && _navigator._history.contains(this);
  }
}

@immutable
class RouteSettings {
  const RouteSettings({
    this.name,
    this.isInitialRoute = false,
    this.arguments,
  });

  RouteSettings copyWith({
    String name,
    bool isInitialRoute,
    Object arguments,
  }) {
    return RouteSettings(
      name: name ?? this.name,
      isInitialRoute: isInitialRoute ?? this.isInitialRoute,
      arguments: arguments ?? this.arguments,
    );
  }

  final String name;

  final bool isInitialRoute;

  final Object arguments;

  @override
  String toString() => assertionsEnabled
      ? '$runtimeType("$name", $arguments)'
      : super.toString();
}

class NavigatorObserver {
  NavigatorState get navigator => _navigator;
  NavigatorState _navigator;

  void didPush(Route<dynamic> route, Route<dynamic> previousRoute) {}

  void didPop(Route<dynamic> route, Route<dynamic> previousRoute) {}

  void didRemove(Route<dynamic> route, Route<dynamic> previousRoute) {}

  void didReplace({Route<dynamic> newRoute, Route<dynamic> oldRoute}) {}

  void didStartUserGesture(
      Route<dynamic> route, Route<dynamic> previousRoute) {}

  void didStopUserGesture() {}
}

class Navigator extends StatefulWidget {
  const Navigator({
    Key key,
    this.initialRoute,
    @required this.onGenerateRoute,
    this.onUnknownRoute,
    this.observers = const <NavigatorObserver>[],
  })  : assert(onGenerateRoute != null),
        super(key: key);

  final String initialRoute;

  final RouteFactory onGenerateRoute;

  final RouteFactory onUnknownRoute;

  final List<NavigatorObserver> observers;

  static const String defaultRouteName = '/';

  @optionalTypeArgs
  static Future<T> pushNamed<T extends Object>(
    BuildContext context,
    String routeName, {
    Object arguments,
  }) {
    return Navigator.of(context).pushNamed<T>(routeName, arguments: arguments);
  }

  @optionalTypeArgs
  static Future<T> pushReplacementNamed<T extends Object, TO extends Object>(
    BuildContext context,
    String routeName, {
    TO result,
    Object arguments,
  }) {
    return Navigator.of(context).pushReplacementNamed<T, TO>(routeName,
        arguments: arguments, result: result);
  }

  @optionalTypeArgs
  static Future<T> popAndPushNamed<T extends Object, TO extends Object>(
    BuildContext context,
    String routeName, {
    TO result,
    Object arguments,
  }) {
    return Navigator.of(context).popAndPushNamed<T, TO>(routeName,
        arguments: arguments, result: result);
  }

  @optionalTypeArgs
  static Future<T> pushNamedAndRemoveUntil<T extends Object>(
    BuildContext context,
    String newRouteName,
    RoutePredicate predicate, {
    Object arguments,
  }) {
    return Navigator.of(context).pushNamedAndRemoveUntil<T>(
        newRouteName, predicate,
        arguments: arguments);
  }

  @optionalTypeArgs
  static Future<T> push<T extends Object>(
      BuildContext context, Route<T> route) {
    return Navigator.of(context).push(route);
  }

  @optionalTypeArgs
  static Future<T> pushReplacement<T extends Object, TO extends Object>(
      BuildContext context, Route<T> newRoute,
      {TO result}) {
    return Navigator.of(context)
        .pushReplacement<T, TO>(newRoute, result: result);
  }

  @optionalTypeArgs
  static Future<T> pushAndRemoveUntil<T extends Object>(
      BuildContext context, Route<T> newRoute, RoutePredicate predicate) {
    return Navigator.of(context).pushAndRemoveUntil<T>(newRoute, predicate);
  }

  @optionalTypeArgs
  static void replace<T extends Object>(BuildContext context,
      {@required Route<dynamic> oldRoute, @required Route<T> newRoute}) {
    return Navigator.of(context)
        .replace<T>(oldRoute: oldRoute, newRoute: newRoute);
  }

  @optionalTypeArgs
  static void replaceRouteBelow<T extends Object>(BuildContext context,
      {@required Route<dynamic> anchorRoute, Route<T> newRoute}) {
    return Navigator.of(context)
        .replaceRouteBelow<T>(anchorRoute: anchorRoute, newRoute: newRoute);
  }

  static bool canPop(BuildContext context) {
    final NavigatorState navigator = Navigator.of(context, nullOk: true);
    return navigator != null && navigator.canPop();
  }

  @optionalTypeArgs
  static Future<bool> maybePop<T extends Object>(BuildContext context,
      [T result]) {
    return Navigator.of(context).maybePop<T>(result);
  }

  @optionalTypeArgs
  static bool pop<T extends Object>(BuildContext context, [T result]) {
    return Navigator.of(context).pop<T>(result);
  }

  static void popUntil(BuildContext context, RoutePredicate predicate) {
    Navigator.of(context).popUntil(predicate);
  }

  static void removeRoute(BuildContext context, Route<dynamic> route) {
    return Navigator.of(context).removeRoute(route);
  }

  static void removeRouteBelow(
      BuildContext context, Route<dynamic> anchorRoute) {
    return Navigator.of(context).removeRouteBelow(anchorRoute);
  }

  static NavigatorState of(
    BuildContext context, {
    bool rootNavigator = false,
    bool nullOk = false,
  }) {
    final NavigatorState navigator = rootNavigator
        ? context.rootAncestorStateOfType(const TypeMatcher<NavigatorState>())
        : context.ancestorStateOfType(const TypeMatcher<NavigatorState>());
    assert(() {
      if (navigator == null && !nullOk) {
        throw FlutterError(
            'Navigator operation requested with a context that does not include a Navigator.\n'
            'The context used to push or pop routes from the Navigator must be that of a '
            'widget that is a descendant of a Navigator widget.');
      }
      return true;
    }());
    return navigator;
  }

  @override
  NavigatorState createState() => NavigatorState();
}

class NavigatorState extends State<Navigator> with TickerProviderStateMixin {
  final GlobalKey<OverlayState> _overlayKey = GlobalKey<OverlayState>();
  final List<Route<dynamic>> _history = <Route<dynamic>>[];
  final Set<Route<dynamic>> _poppedRoutes = Set<Route<dynamic>>();

  final FocusScopeNode focusScopeNode = FocusScopeNode();

  final List<OverlayEntry> _initialOverlayEntries = <OverlayEntry>[];

  @override
  void initState() {
    super.initState();
    for (NavigatorObserver observer in widget.observers) {
      assert(observer.navigator == null);
      observer._navigator = this;
    }
    String initialRouteName = widget.initialRoute ?? Navigator.defaultRouteName;
    if (initialRouteName.startsWith('/') && initialRouteName.length > 1) {
      initialRouteName = initialRouteName.substring(1);
      assert(Navigator.defaultRouteName == '/');
      final List<String> plannedInitialRouteNames = <String>[
        Navigator.defaultRouteName,
      ];
      final List<Route<dynamic>> plannedInitialRoutes = <Route<dynamic>>[
        _routeNamed<dynamic>(Navigator.defaultRouteName,
            allowNull: true, arguments: null),
      ];
      final List<String> routeParts = initialRouteName.split('/');
      if (initialRouteName.isNotEmpty) {
        String routeName = '';
        for (String part in routeParts) {
          routeName += '/$part';
          plannedInitialRouteNames.add(routeName);
          plannedInitialRoutes.add(_routeNamed<dynamic>(routeName,
              allowNull: true, arguments: null));
        }
      }

      if (_shouldAbandonInitialRoute(plannedInitialRoutes)) {
        assert(() {
          FlutterError.reportError(
            FlutterErrorDetails(
                exception: 'Could not navigate to initial route.\n'
                    'The requested route name was: "/$initialRouteName"\n'
                    'The following routes were therefore attempted:\n'
                    ' * ${plannedInitialRouteNames.join("\n * ")}\n'
                    'This resulted in the following objects:\n'
                    ' * ${plannedInitialRoutes.join("\n * ")}\n'
                    'One or more of those objects was null, and therefore the initial route specified will be '
                    'ignored and "${Navigator.defaultRouteName}" will be used instead.'),
          );
          return true;
        }());
        push(_routeNamed<Object>(Navigator.defaultRouteName, arguments: null));
      } else {
        plannedInitialRoutes
            .where((Route<dynamic> route) => route != null)
            .forEach(push);
      }
    } else {
      Route<Object> route;
      if (initialRouteName != Navigator.defaultRouteName)
        route = _routeNamed<Object>(initialRouteName,
            allowNull: true, arguments: null);
      route ??=
          _routeNamed<Object>(Navigator.defaultRouteName, arguments: null);
      push(route);
    }
    for (Route<dynamic> route in _history)
      _initialOverlayEntries.addAll(route.overlayEntries);
  }

  @override
  void didUpdateWidget(Navigator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.observers != widget.observers) {
      for (NavigatorObserver observer in oldWidget.observers)
        observer._navigator = null;
      for (NavigatorObserver observer in widget.observers) {
        assert(observer.navigator == null);
        observer._navigator = this;
      }
    }
    for (Route<dynamic> route in _history) route.changedExternalState();
  }

  @override
  void dispose() {
    assert(!_debugLocked);
    assert(() {
      _debugLocked = true;
      return true;
    }());
    for (NavigatorObserver observer in widget.observers)
      observer._navigator = null;
    final List<Route<dynamic>> doomed = _poppedRoutes.toList()
      ..addAll(_history);
    for (Route<dynamic> route in doomed) route.dispose();
    _poppedRoutes.clear();
    _history.clear();
    focusScopeNode.dispose();
    super.dispose();
    assert(() {
      _debugLocked = false;
      return true;
    }());
  }

  OverlayState get overlay => _overlayKey.currentState;

  OverlayEntry get _currentOverlayEntry {
    for (Route<dynamic> route in _history.reversed) {
      if (route.overlayEntries.isNotEmpty) return route.overlayEntries.last;
    }
    return null;
  }

  bool _debugLocked = false;

  bool _shouldAbandonInitialRoute(List<Route<dynamic>> plannedInitialRoutes) {
    assert(plannedInitialRoutes.length > 0);

    if (plannedInitialRoutes.last == null) {
      return true;
    }

    if (isWeb) {
      return false;
    }

    return plannedInitialRoutes.contains(null);
  }

  Route<T> _routeNamed<T>(String name,
      {@required Object arguments, bool allowNull = false}) {
    assert(!_debugLocked);
    assert(name != null);
    final RouteSettings settings = RouteSettings(
      name: name,
      isInitialRoute: _history.isEmpty,
      arguments: arguments,
    );
    Route<T> route = widget.onGenerateRoute(settings);
    if (route == null && !allowNull) {
      assert(() {
        if (widget.onUnknownRoute == null) {
          throw FlutterError(
              'If a Navigator has no onUnknownRoute, then its onGenerateRoute must never return null.\n'
              'When trying to build the route "$name", onGenerateRoute returned null, but there was no '
              'onUnknownRoute callback specified.\n'
              'The Navigator was:\n'
              '  $this');
        }
        return true;
      }());
      route = widget.onUnknownRoute(settings);
      assert(() {
        if (route == null) {
          throw FlutterError('A Navigator\'s onUnknownRoute returned null.\n'
              'When trying to build the route "$name", both onGenerateRoute and onUnknownRoute returned '
              'null. The onUnknownRoute callback should never return null.\n'
              'The Navigator was:\n'
              '  $this');
        }
        return true;
      }());
    }
    return route;
  }

  @optionalTypeArgs
  Future<T> pushNamed<T extends Object>(
    String routeName, {
    Object arguments,
  }) {
    return push<T>(_routeNamed<T>(routeName, arguments: arguments));
  }

  @optionalTypeArgs
  Future<T> pushReplacementNamed<T extends Object, TO extends Object>(
    String routeName, {
    TO result,
    Object arguments,
  }) {
    return pushReplacement<T, TO>(
        _routeNamed<T>(routeName, arguments: arguments),
        result: result);
  }

  @optionalTypeArgs
  Future<T> popAndPushNamed<T extends Object, TO extends Object>(
    String routeName, {
    TO result,
    Object arguments,
  }) {
    pop<TO>(result);
    return pushNamed<T>(routeName, arguments: arguments);
  }

  @optionalTypeArgs
  Future<T> pushNamedAndRemoveUntil<T extends Object>(
    String newRouteName,
    RoutePredicate predicate, {
    Object arguments,
  }) {
    return pushAndRemoveUntil<T>(
        _routeNamed<T>(newRouteName, arguments: arguments), predicate);
  }

  @optionalTypeArgs
  Future<T> push<T extends Object>(Route<T> route) {
    assert(!_debugLocked);
    assert(() {
      _debugLocked = true;
      return true;
    }());
    assert(route != null);
    assert(route._navigator == null);
    final Route<dynamic> oldRoute = _history.isNotEmpty ? _history.last : null;
    route._navigator = this;
    route.install(_currentOverlayEntry);
    _history.add(route);
    route.didPush();
    route.didChangeNext(null);
    if (oldRoute != null) {
      oldRoute.didChangeNext(route);
      route.didChangePrevious(oldRoute);
    }
    for (NavigatorObserver observer in widget.observers)
      observer.didPush(route, oldRoute);
    assert(() {
      _debugLocked = false;
      return true;
    }());
    _afterNavigation();
    return route.popped;
  }

  void _afterNavigation() {
    if (!kReleaseMode) {
      developer.postEvent('Flutter.Navigation', <String, dynamic>{});
    }
    _cancelActivePointers();
  }

  @optionalTypeArgs
  Future<T> pushReplacement<T extends Object, TO extends Object>(
      Route<T> newRoute,
      {TO result}) {
    assert(!_debugLocked);
    assert(() {
      _debugLocked = true;
      return true;
    }());
    final Route<dynamic> oldRoute = _history.last;
    assert(oldRoute != null && oldRoute._navigator == this);
    assert(oldRoute.overlayEntries.isNotEmpty);
    assert(newRoute._navigator == null);
    assert(newRoute.overlayEntries.isEmpty);
    final int index = _history.length - 1;
    assert(index >= 0);
    assert(_history.indexOf(oldRoute) == index);
    newRoute._navigator = this;
    newRoute.install(_currentOverlayEntry);
    _history[index] = newRoute;
    newRoute.didPush().whenCompleteOrCancel(() {
      if (mounted) {
        oldRoute
          ..didComplete(result ?? oldRoute.currentResult)
          ..dispose();
      }
    });
    newRoute.didChangeNext(null);
    if (index > 0) {
      _history[index - 1].didChangeNext(newRoute);
      newRoute.didChangePrevious(_history[index - 1]);
    }
    for (NavigatorObserver observer in widget.observers)
      observer.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    assert(() {
      _debugLocked = false;
      return true;
    }());
    _afterNavigation();
    return newRoute.popped;
  }

  @optionalTypeArgs
  Future<T> pushAndRemoveUntil<T extends Object>(
      Route<T> newRoute, RoutePredicate predicate) {
    assert(!_debugLocked);
    assert(() {
      _debugLocked = true;
      return true;
    }());
    final List<Route<dynamic>> removedRoutes = <Route<dynamic>>[];
    while (_history.isNotEmpty && !predicate(_history.last)) {
      final Route<dynamic> removedRoute = _history.removeLast();
      assert(removedRoute != null && removedRoute._navigator == this);
      assert(removedRoute.overlayEntries.isNotEmpty);
      removedRoutes.add(removedRoute);
    }
    assert(newRoute._navigator == null);
    assert(newRoute.overlayEntries.isEmpty);
    final Route<dynamic> oldRoute = _history.isNotEmpty ? _history.last : null;
    newRoute._navigator = this;
    newRoute.install(_currentOverlayEntry);
    _history.add(newRoute);
    newRoute.didPush().whenCompleteOrCancel(() {
      if (mounted) {
        for (Route<dynamic> route in removedRoutes) route.dispose();
      }
    });
    newRoute.didChangeNext(null);
    if (oldRoute != null) oldRoute.didChangeNext(newRoute);
    for (NavigatorObserver observer in widget.observers) {
      observer.didPush(newRoute, oldRoute);
      for (Route<dynamic> removedRoute in removedRoutes)
        observer.didRemove(removedRoute, oldRoute);
    }
    assert(() {
      _debugLocked = false;
      return true;
    }());
    _afterNavigation();
    return newRoute.popped;
  }

  @optionalTypeArgs
  void replace<T extends Object>(
      {@required Route<dynamic> oldRoute, @required Route<T> newRoute}) {
    assert(!_debugLocked);
    assert(oldRoute != null);
    assert(newRoute != null);
    if (oldRoute == newRoute) return;
    assert(() {
      _debugLocked = true;
      return true;
    }());
    assert(oldRoute._navigator == this);
    assert(newRoute._navigator == null);
    assert(oldRoute.overlayEntries.isNotEmpty);
    assert(newRoute.overlayEntries.isEmpty);
    assert(!overlay.debugIsVisible(oldRoute.overlayEntries.last));
    final int index = _history.indexOf(oldRoute);
    assert(index >= 0);
    newRoute._navigator = this;
    newRoute.install(oldRoute.overlayEntries.last);
    _history[index] = newRoute;
    newRoute.didReplace(oldRoute);
    if (index + 1 < _history.length) {
      newRoute.didChangeNext(_history[index + 1]);
      _history[index + 1].didChangePrevious(newRoute);
    } else {
      newRoute.didChangeNext(null);
    }
    if (index > 0) {
      _history[index - 1].didChangeNext(newRoute);
      newRoute.didChangePrevious(_history[index - 1]);
    }
    for (NavigatorObserver observer in widget.observers)
      observer.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    oldRoute.dispose();
    assert(() {
      _debugLocked = false;
      return true;
    }());
  }

  @optionalTypeArgs
  void replaceRouteBelow<T extends Object>(
      {@required Route<dynamic> anchorRoute, Route<T> newRoute}) {
    assert(anchorRoute != null);
    assert(anchorRoute._navigator == this);
    assert(_history.indexOf(anchorRoute) > 0);
    replace<T>(
        oldRoute: _history[_history.indexOf(anchorRoute) - 1],
        newRoute: newRoute);
  }

  bool canPop() {
    assert(_history.isNotEmpty);
    return _history.length > 1 || _history[0].willHandlePopInternally;
  }

  @optionalTypeArgs
  Future<bool> maybePop<T extends Object>([T result]) async {
    final Route<T> route = _history.last;
    assert(route._navigator == this);
    final RoutePopDisposition disposition = await route.willPop();
    if (disposition != RoutePopDisposition.bubble && mounted) {
      if (disposition == RoutePopDisposition.pop) pop(result);
      return true;
    }
    return false;
  }

  @optionalTypeArgs
  bool pop<T extends Object>([T result]) {
    assert(!_debugLocked);
    assert(() {
      _debugLocked = true;
      return true;
    }());
    final Route<dynamic> route = _history.last;
    assert(route._navigator == this);
    bool debugPredictedWouldPop;
    assert(() {
      debugPredictedWouldPop = !route.willHandlePopInternally;
      return true;
    }());
    if (route.didPop(result ?? route.currentResult)) {
      assert(debugPredictedWouldPop);
      if (_history.length > 1) {
        _history.removeLast();

        if (route._navigator != null) _poppedRoutes.add(route);
        _history.last.didPopNext(route);
        for (NavigatorObserver observer in widget.observers)
          observer.didPop(route, _history.last);
      } else {
        assert(() {
          _debugLocked = false;
          return true;
        }());
        return false;
      }
    } else {
      assert(!debugPredictedWouldPop);
    }
    assert(() {
      _debugLocked = false;
      return true;
    }());
    _afterNavigation();
    return true;
  }

  void popUntil(RoutePredicate predicate) {
    while (!predicate(_history.last)) pop();
  }

  void removeRoute(Route<dynamic> route) {
    assert(route != null);
    assert(!_debugLocked);
    assert(() {
      _debugLocked = true;
      return true;
    }());
    assert(route._navigator == this);
    final int index = _history.indexOf(route);
    assert(index != -1);
    final Route<dynamic> previousRoute = index > 0 ? _history[index - 1] : null;
    final Route<dynamic> nextRoute =
        (index + 1 < _history.length) ? _history[index + 1] : null;
    _history.removeAt(index);
    previousRoute?.didChangeNext(nextRoute);
    nextRoute?.didChangePrevious(previousRoute);
    for (NavigatorObserver observer in widget.observers)
      observer.didRemove(route, previousRoute);
    route.dispose();
    assert(() {
      _debugLocked = false;
      return true;
    }());
    _afterNavigation();
  }

  void removeRouteBelow(Route<dynamic> anchorRoute) {
    assert(!_debugLocked);
    assert(() {
      _debugLocked = true;
      return true;
    }());
    assert(anchorRoute._navigator == this);
    final int index = _history.indexOf(anchorRoute) - 1;
    assert(index >= 0);
    final Route<dynamic> targetRoute = _history[index];
    assert(targetRoute._navigator == this);
    assert(targetRoute.overlayEntries.isEmpty ||
        !overlay.debugIsVisible(targetRoute.overlayEntries.last));
    _history.removeAt(index);
    final Route<dynamic> nextRoute =
        index < _history.length ? _history[index] : null;
    final Route<dynamic> previousRoute = index > 0 ? _history[index - 1] : null;
    if (previousRoute != null) previousRoute.didChangeNext(nextRoute);
    if (nextRoute != null) nextRoute.didChangePrevious(previousRoute);
    targetRoute.dispose();
    assert(() {
      _debugLocked = false;
      return true;
    }());
  }

  void finalizeRoute(Route<dynamic> route) {
    _poppedRoutes.remove(route);
    route.dispose();
  }

  bool get userGestureInProgress => _userGesturesInProgress > 0;
  int _userGesturesInProgress = 0;

  void didStartUserGesture() {
    _userGesturesInProgress += 1;
    if (_userGesturesInProgress == 1) {
      final Route<dynamic> route = _history.last;
      final Route<dynamic> previousRoute =
          !route.willHandlePopInternally && _history.length > 1
              ? _history[_history.length - 2]
              : null;

      for (NavigatorObserver observer in widget.observers)
        observer.didStartUserGesture(route, previousRoute);
    }
  }

  void didStopUserGesture() {
    assert(_userGesturesInProgress > 0);
    _userGesturesInProgress -= 1;
    if (_userGesturesInProgress == 0) {
      for (NavigatorObserver observer in widget.observers)
        observer.didStopUserGesture();
    }
  }

  final Set<int> _activePointers = <int>{};

  void _handlePointerDown(PointerDownEvent event) {
    _activePointers.add(event.pointer);
  }

  void _handlePointerUpOrCancel(PointerEvent event) {
    _activePointers.remove(event.pointer);
  }

  void _cancelActivePointers() {
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.idle) {
      final RenderAbsorbPointer absorber = _overlayKey.currentContext
          ?.ancestorRenderObjectOfType(
              const TypeMatcher<RenderAbsorbPointer>());
      setState(() {
        absorber?.absorbing = true;
      });
    }
    _activePointers.toList().forEach(WidgetsBinding.instance.cancelPointer);
  }

  @override
  Widget build(BuildContext context) {
    assert(!_debugLocked);
    assert(_history.isNotEmpty);
    return Listener(
      onPointerDown: _handlePointerDown,
      onPointerUp: _handlePointerUpOrCancel,
      onPointerCancel: _handlePointerUpOrCancel,
      child: AbsorbPointer(
        absorbing: false,
        child: FocusScope(
          node: focusScopeNode,
          autofocus: true,
          child: Overlay(
            key: _overlayKey,
            initialEntries: _initialOverlayEntries,
          ),
        ),
      ),
    );
  }
}

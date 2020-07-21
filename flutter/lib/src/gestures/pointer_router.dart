import 'dart:collection';

import 'package:vector_math/vector_math_64.dart';
import 'package:flutter_web/foundation.dart';
import 'events.dart';

typedef PointerRoute = void Function(PointerEvent event);

class PointerRouter {
  final Map<int, LinkedHashSet<_RouteEntry>> _routeMap =
      <int, LinkedHashSet<_RouteEntry>>{};
  final LinkedHashSet<_RouteEntry> _globalRoutes = LinkedHashSet<_RouteEntry>();

  void addRoute(int pointer, PointerRoute route, [Matrix4 transform]) {
    final LinkedHashSet<_RouteEntry> routes =
        _routeMap.putIfAbsent(pointer, () => LinkedHashSet<_RouteEntry>());
    assert(!routes.any(_RouteEntry.isRoutePredicate(route)));
    routes.add(_RouteEntry(route: route, transform: transform));
  }

  void removeRoute(int pointer, PointerRoute route) {
    assert(_routeMap.containsKey(pointer));
    final LinkedHashSet<_RouteEntry> routes = _routeMap[pointer];
    assert(routes.any(_RouteEntry.isRoutePredicate(route)));
    routes.removeWhere(_RouteEntry.isRoutePredicate(route));
    if (routes.isEmpty) _routeMap.remove(pointer);
  }

  void addGlobalRoute(PointerRoute route, [Matrix4 transform]) {
    assert(!_globalRoutes.any(_RouteEntry.isRoutePredicate(route)));
    _globalRoutes.add(_RouteEntry(route: route, transform: transform));
  }

  void removeGlobalRoute(PointerRoute route) {
    assert(_globalRoutes.any(_RouteEntry.isRoutePredicate(route)));
    _globalRoutes.removeWhere(_RouteEntry.isRoutePredicate(route));
  }

  void _dispatch(PointerEvent event, _RouteEntry entry) {
    try {
      event = event.transformed(entry.transform);
      entry.route(event);
    } catch (exception, stack) {
      FlutterError.reportError(FlutterErrorDetailsForPointerRouter(
        exception: exception,
        stack: stack,
        library: 'gesture library',
        context: ErrorDescription('while routing a pointer event'),
        router: this,
        route: entry.route,
        event: event,
        informationCollector: () sync* {
          yield DiagnosticsProperty<PointerEvent>('Event', event,
              style: DiagnosticsTreeStyle.errorProperty);
        },
      ));
    }
  }

  void route(PointerEvent event) {
    final LinkedHashSet<_RouteEntry> routes = _routeMap[event.pointer];
    final List<_RouteEntry> globalRoutes =
        List<_RouteEntry>.from(_globalRoutes);
    if (routes != null) {
      for (_RouteEntry entry in List<_RouteEntry>.from(routes)) {
        if (routes.any(_RouteEntry.isRoutePredicate(entry.route)))
          _dispatch(event, entry);
      }
    }
    for (_RouteEntry entry in globalRoutes) {
      if (_globalRoutes.any(_RouteEntry.isRoutePredicate(entry.route)))
        _dispatch(event, entry);
    }
  }
}

class FlutterErrorDetailsForPointerRouter extends FlutterErrorDetails {
  const FlutterErrorDetailsForPointerRouter({
    dynamic exception,
    StackTrace stack,
    String library,
    DiagnosticsNode context,
    this.router,
    this.route,
    this.event,
    InformationCollector informationCollector,
    bool silent = false,
  }) : super(
            exception: exception,
            stack: stack,
            library: library,
            context: context,
            informationCollector: informationCollector,
            silent: silent);

  final PointerRouter router;

  final PointerRoute route;

  final PointerEvent event;
}

typedef _RouteEntryPredicate = bool Function(_RouteEntry entry);

class _RouteEntry {
  const _RouteEntry({
    @required this.route,
    @required this.transform,
  });

  final PointerRoute route;
  final Matrix4 transform;

  static _RouteEntryPredicate isRoutePredicate(PointerRoute route) {
    return (_RouteEntry entry) => entry.route == route;
  }
}

import 'package:flutter_web/foundation.dart';

import 'basic.dart';
import 'binding.dart';
import 'framework.dart';
import 'navigator.dart';
import 'overlay.dart';
import 'pages.dart';
import 'routes.dart';
import 'transitions.dart';

import 'ticker_provider.dart' show TickerMode;

typedef CreateRectTween = Tween<Rect> Function(Rect begin, Rect end);

typedef HeroPlaceholderBuilder = Widget Function(
  BuildContext context,
  Size heroSize,
  Widget child,
);

typedef HeroFlightShuttleBuilder = Widget Function(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection flightDirection,
  BuildContext fromHeroContext,
  BuildContext toHeroContext,
);

typedef _OnFlightEnded = void Function(_HeroFlight flight);

enum HeroFlightDirection {
  push,

  pop,
}

Rect _boundingBoxFor(BuildContext context, [BuildContext ancestorContext]) {
  final RenderBox box = context.findRenderObject();
  assert(box != null && box.hasSize);
  return MatrixUtils.transformRect(
    box.getTransformTo(ancestorContext?.findRenderObject()),
    Offset.zero & box.size,
  );
}

class Hero extends StatefulWidget {
  const Hero({
    Key key,
    @required this.tag,
    this.createRectTween,
    this.flightShuttleBuilder,
    this.placeholderBuilder,
    this.transitionOnUserGestures = false,
    @required this.child,
  })  : assert(tag != null),
        assert(transitionOnUserGestures != null),
        assert(child != null),
        super(key: key);

  final Object tag;

  final CreateRectTween createRectTween;

  final Widget child;

  final HeroFlightShuttleBuilder flightShuttleBuilder;

  final HeroPlaceholderBuilder placeholderBuilder;

  final bool transitionOnUserGestures;

  static Map<Object, _HeroState> _allHeroesFor(
    BuildContext context,
    bool isUserGestureTransition,
    NavigatorState navigator,
  ) {
    assert(context != null);
    assert(isUserGestureTransition != null);
    assert(navigator != null);
    final Map<Object, _HeroState> result = <Object, _HeroState>{};

    void addHero(StatefulElement hero, Object tag) {
      assert(() {
        if (result.containsKey(tag)) {
          throw FlutterError(
              'There are multiple heroes that share the same tag within a subtree.\n'
              'Within each subtree for which heroes are to be animated (i.e. a PageRoute subtree), '
              'each Hero must have a unique non-null tag.\n'
              'In this case, multiple heroes had the following tag: $tag\n'
              'Here is the subtree for one of the offending heroes:\n'
              '${hero.toStringDeep(prefixLineOne: "# ")}');
        }
        return true;
      }());
      final _HeroState heroState = hero.state;
      result[tag] = heroState;
    }

    void visitor(Element element) {
      if (element.widget is Hero) {
        final StatefulElement hero = element;
        final Hero heroWidget = element.widget;
        if (!isUserGestureTransition || heroWidget.transitionOnUserGestures) {
          final Object tag = heroWidget.tag;
          assert(tag != null);
          if (Navigator.of(hero) == navigator) {
            addHero(hero, tag);
          } else {
            final ModalRoute<dynamic> heroRoute = ModalRoute.of(hero);
            if (heroRoute != null &&
                heroRoute is PageRoute &&
                heroRoute.isCurrent) {
              addHero(hero, tag);
            }
          }
        }
      }
      element.visitChildren(visitor);
    }

    context.visitChildElements(visitor);
    return result;
  }

  @override
  _HeroState createState() => _HeroState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Object>('tag', tag));
  }
}

class _HeroState extends State<Hero> {
  final GlobalKey _key = GlobalKey();
  Size _placeholderSize;

  bool _shouldIncludeChild = true;

  void startFlight({bool shouldIncludedChildInPlaceholder = false}) {
    _shouldIncludeChild = shouldIncludedChildInPlaceholder;
    assert(mounted);
    final RenderBox box = context.findRenderObject();
    assert(box != null && box.hasSize);
    setState(() {
      _placeholderSize = box.size;
    });
  }

  void endFlight() {
    if (mounted) {
      setState(() {
        _placeholderSize = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(context.ancestorWidgetOfExactType(Hero) == null,
        'A Hero widget cannot be the descendant of another Hero widget.');

    final bool isHeroInFlight = _placeholderSize != null;

    if (isHeroInFlight && widget.placeholderBuilder != null) {
      return widget.placeholderBuilder(context, _placeholderSize, widget.child);
    }

    if (isHeroInFlight && !_shouldIncludeChild) {
      return SizedBox(
        width: _placeholderSize.width,
        height: _placeholderSize.height,
      );
    }

    return SizedBox(
      width: _placeholderSize?.width,
      height: _placeholderSize?.height,
      child: Offstage(
          offstage: isHeroInFlight,
          child: TickerMode(
            enabled: !isHeroInFlight,
            child: KeyedSubtree(key: _key, child: widget.child),
          )),
    );
  }
}

class _HeroFlightManifest {
  _HeroFlightManifest({
    @required this.type,
    @required this.overlay,
    @required this.navigatorRect,
    @required this.fromRoute,
    @required this.toRoute,
    @required this.fromHero,
    @required this.toHero,
    @required this.createRectTween,
    @required this.shuttleBuilder,
    @required this.isUserGestureTransition,
  }) : assert(fromHero.widget.tag == toHero.widget.tag);

  final HeroFlightDirection type;
  final OverlayState overlay;
  final Rect navigatorRect;
  final PageRoute<dynamic> fromRoute;
  final PageRoute<dynamic> toRoute;
  final _HeroState fromHero;
  final _HeroState toHero;
  final CreateRectTween createRectTween;
  final HeroFlightShuttleBuilder shuttleBuilder;
  final bool isUserGestureTransition;

  Object get tag => fromHero.widget.tag;

  Animation<double> get animation {
    return CurvedAnimation(
      parent: (type == HeroFlightDirection.push)
          ? toRoute.animation
          : fromRoute.animation,
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  String toString() {
    return '_HeroFlightManifest($type tag: $tag from route: ${fromRoute.settings} '
        'to route: ${toRoute.settings} with hero: $fromHero to $toHero)';
  }
}

class _HeroFlight {
  _HeroFlight(this.onFlightEnded) {
    _proxyAnimation = ProxyAnimation()
      ..addStatusListener(_handleAnimationUpdate);
  }

  final _OnFlightEnded onFlightEnded;

  Tween<Rect> heroRectTween;
  Widget shuttle;

  Animation<double> _heroOpacity = kAlwaysCompleteAnimation;
  ProxyAnimation _proxyAnimation;
  _HeroFlightManifest manifest;
  OverlayEntry overlayEntry;
  bool _aborted = false;

  Tween<Rect> _doCreateRectTween(Rect begin, Rect end) {
    final CreateRectTween createRectTween =
        manifest.toHero.widget.createRectTween ?? manifest.createRectTween;
    if (createRectTween != null) return createRectTween(begin, end);
    return RectTween(begin: begin, end: end);
  }

  static final Animatable<double> _reverseTween =
      Tween<double>(begin: 1.0, end: 0.0);

  Widget _buildOverlay(BuildContext context) {
    assert(manifest != null);
    shuttle ??= manifest.shuttleBuilder(
      context,
      manifest.animation,
      manifest.type,
      manifest.fromHero.context,
      manifest.toHero.context,
    );
    assert(shuttle != null);

    return AnimatedBuilder(
      animation: _proxyAnimation,
      child: shuttle,
      builder: (BuildContext context, Widget child) {
        final RenderBox toHeroBox = manifest.toHero.context?.findRenderObject();
        if (_aborted || toHeroBox == null || !toHeroBox.attached) {
          if (_heroOpacity.isCompleted) {
            _heroOpacity = _proxyAnimation.drive(
              _reverseTween.chain(
                  CurveTween(curve: Interval(_proxyAnimation.value, 1.0))),
            );
          }
        } else if (toHeroBox.hasSize) {
          final RenderBox finalRouteBox =
              manifest.toRoute.subtreeContext?.findRenderObject();
          final Offset toHeroOrigin =
              toHeroBox.localToGlobal(Offset.zero, ancestor: finalRouteBox);
          if (toHeroOrigin != heroRectTween.end.topLeft) {
            final Rect heroRectEnd = toHeroOrigin & heroRectTween.end.size;
            heroRectTween =
                _doCreateRectTween(heroRectTween.begin, heroRectEnd);
          }
        }

        final Rect rect = heroRectTween.evaluate(_proxyAnimation);
        final Size size = manifest.navigatorRect.size;
        final RelativeRect offsets = RelativeRect.fromSize(rect, size);

        return Positioned(
          top: offsets.top,
          right: offsets.right,
          bottom: offsets.bottom,
          left: offsets.left,
          child: IgnorePointer(
            child: RepaintBoundary(
              child: Opacity(
                opacity: _heroOpacity.value,
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleAnimationUpdate(AnimationStatus status) {
    if (status == AnimationStatus.completed ||
        status == AnimationStatus.dismissed) {
      _proxyAnimation.parent = null;

      assert(overlayEntry != null);
      overlayEntry.remove();
      overlayEntry = null;

      manifest.fromHero.endFlight();
      manifest.toHero.endFlight();
      onFlightEnded(this);
    }
  }

  void start(_HeroFlightManifest initialManifest) {
    assert(!_aborted);
    assert(() {
      final Animation<double> initial = initialManifest.animation;
      assert(initial != null);
      final HeroFlightDirection type = initialManifest.type;
      assert(type != null);
      switch (type) {
        case HeroFlightDirection.pop:
          return initial.value == 1.0 && initialManifest.isUserGestureTransition
              ? initial.status == AnimationStatus.completed
              : initial.status == AnimationStatus.reverse;
        case HeroFlightDirection.push:
          return initial.value == 0.0 &&
              initial.status == AnimationStatus.forward;
      }
      return null;
    }());

    manifest = initialManifest;

    if (manifest.type == HeroFlightDirection.pop)
      _proxyAnimation.parent = ReverseAnimation(manifest.animation);
    else
      _proxyAnimation.parent = manifest.animation;

    manifest.fromHero.startFlight(
        shouldIncludedChildInPlaceholder:
            manifest.type == HeroFlightDirection.push);
    manifest.toHero.startFlight();

    heroRectTween = _doCreateRectTween(
      _boundingBoxFor(
          manifest.fromHero.context, manifest.fromRoute.subtreeContext),
      _boundingBoxFor(manifest.toHero.context, manifest.toRoute.subtreeContext),
    );

    overlayEntry = OverlayEntry(builder: _buildOverlay);
    manifest.overlay.insert(overlayEntry);
  }

  void divert(_HeroFlightManifest newManifest) {
    assert(manifest.tag == newManifest.tag);

    if (manifest.type == HeroFlightDirection.push &&
        newManifest.type == HeroFlightDirection.pop) {
      assert(newManifest.animation.status == AnimationStatus.reverse);
      assert(manifest.fromHero == newManifest.toHero);
      assert(manifest.toHero == newManifest.fromHero);
      assert(manifest.fromRoute == newManifest.toRoute);
      assert(manifest.toRoute == newManifest.fromRoute);

      _proxyAnimation.parent = ReverseAnimation(newManifest.animation);
      heroRectTween = ReverseTween<Rect>(heroRectTween);
    } else if (manifest.type == HeroFlightDirection.pop &&
        newManifest.type == HeroFlightDirection.push) {
      assert(newManifest.animation.status == AnimationStatus.forward);
      assert(manifest.toHero == newManifest.fromHero);
      assert(manifest.toRoute == newManifest.fromRoute);

      _proxyAnimation.parent = newManifest.animation.drive(
        Tween<double>(
          begin: manifest.animation.value,
          end: 1.0,
        ),
      );

      if (manifest.fromHero != newManifest.toHero) {
        manifest.fromHero.endFlight();
        newManifest.toHero.startFlight();
        heroRectTween = _doCreateRectTween(
          heroRectTween.end,
          _boundingBoxFor(
              newManifest.toHero.context, newManifest.toRoute.subtreeContext),
        );
      } else {
        heroRectTween =
            _doCreateRectTween(heroRectTween.end, heroRectTween.begin);
      }
    } else {
      assert(manifest.fromHero != newManifest.fromHero);
      assert(manifest.toHero != newManifest.toHero);

      heroRectTween = _doCreateRectTween(
        heroRectTween.evaluate(_proxyAnimation),
        _boundingBoxFor(
            newManifest.toHero.context, newManifest.toRoute.subtreeContext),
      );
      shuttle = null;

      if (newManifest.type == HeroFlightDirection.pop)
        _proxyAnimation.parent = ReverseAnimation(newManifest.animation);
      else
        _proxyAnimation.parent = newManifest.animation;

      manifest.fromHero.endFlight();
      manifest.toHero.endFlight();

      newManifest.fromHero.startFlight(
          shouldIncludedChildInPlaceholder:
              newManifest.type == HeroFlightDirection.push);
      newManifest.toHero.startFlight();

      overlayEntry.markNeedsBuild();
    }

    _aborted = false;
    manifest = newManifest;
  }

  void abort() {
    _aborted = true;
  }

  @override
  String toString() {
    final RouteSettings from = manifest.fromRoute.settings;
    final RouteSettings to = manifest.toRoute.settings;
    final Object tag = manifest.tag;
    return 'HeroFlight(for: $tag, from: $from, to: $to ${_proxyAnimation.parent})';
  }
}

class HeroController extends NavigatorObserver {
  HeroController({this.createRectTween});

  final CreateRectTween createRectTween;

  final Map<Object, _HeroFlight> _flights = <Object, _HeroFlight>{};

  @override
  void didPush(Route<dynamic> route, Route<dynamic> previousRoute) {
    assert(navigator != null);
    assert(route != null);
    _maybeStartHeroTransition(
        previousRoute, route, HeroFlightDirection.push, false);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic> previousRoute) {
    assert(navigator != null);
    assert(route != null);

    if (!navigator.userGestureInProgress)
      _maybeStartHeroTransition(
          route, previousRoute, HeroFlightDirection.pop, false);
  }

  @override
  void didReplace({Route<dynamic> newRoute, Route<dynamic> oldRoute}) {
    assert(navigator != null);
    if (newRoute?.isCurrent == true) {
      _maybeStartHeroTransition(
          oldRoute, newRoute, HeroFlightDirection.push, false);
    }
  }

  @override
  void didStartUserGesture(Route<dynamic> route, Route<dynamic> previousRoute) {
    assert(navigator != null);
    assert(route != null);
    _maybeStartHeroTransition(
        route, previousRoute, HeroFlightDirection.pop, true);
  }

  void _maybeStartHeroTransition(
    Route<dynamic> fromRoute,
    Route<dynamic> toRoute,
    HeroFlightDirection flightType,
    bool isUserGestureTransition,
  ) {
    if (toRoute != fromRoute &&
        toRoute is PageRoute<dynamic> &&
        fromRoute is PageRoute<dynamic>) {
      final PageRoute<dynamic> from = fromRoute;
      final PageRoute<dynamic> to = toRoute;
      final Animation<double> animation =
          (flightType == HeroFlightDirection.push)
              ? to.animation
              : from.animation;

      switch (flightType) {
        case HeroFlightDirection.pop:
          if (animation.value == 0.0) {
            return;
          }
          break;
        case HeroFlightDirection.push:
          if (animation.value == 1.0) {
            return;
          }
          break;
      }

      if (isUserGestureTransition &&
          flightType == HeroFlightDirection.pop &&
          to.maintainState) {
        _startHeroTransition(
            from, to, animation, flightType, isUserGestureTransition);
      } else {
        to.offstage = to.animation.value == 0.0;

        WidgetsBinding.instance.addPostFrameCallback((Duration value) {
          _startHeroTransition(
              from, to, animation, flightType, isUserGestureTransition);
        });
      }
    }
  }

  void _startHeroTransition(
    PageRoute<dynamic> from,
    PageRoute<dynamic> to,
    Animation<double> animation,
    HeroFlightDirection flightType,
    bool isUserGestureTransition,
  ) {
    if (navigator == null ||
        from.subtreeContext == null ||
        to.subtreeContext == null) {
      to.offstage = false;
      return;
    }

    final Rect navigatorRect = _boundingBoxFor(navigator.context);

    final Map<Object, _HeroState> fromHeroes = Hero._allHeroesFor(
        from.subtreeContext, isUserGestureTransition, navigator);
    final Map<Object, _HeroState> toHeroes = Hero._allHeroesFor(
        to.subtreeContext, isUserGestureTransition, navigator);

    to.offstage = false;

    for (Object tag in fromHeroes.keys) {
      if (toHeroes[tag] != null) {
        final HeroFlightShuttleBuilder fromShuttleBuilder =
            fromHeroes[tag].widget.flightShuttleBuilder;
        final HeroFlightShuttleBuilder toShuttleBuilder =
            toHeroes[tag].widget.flightShuttleBuilder;

        final _HeroFlightManifest manifest = _HeroFlightManifest(
          type: flightType,
          overlay: navigator.overlay,
          navigatorRect: navigatorRect,
          fromRoute: from,
          toRoute: to,
          fromHero: fromHeroes[tag],
          toHero: toHeroes[tag],
          createRectTween: createRectTween,
          shuttleBuilder: toShuttleBuilder ??
              fromShuttleBuilder ??
              _defaultHeroFlightShuttleBuilder,
          isUserGestureTransition: isUserGestureTransition,
        );

        if (_flights[tag] != null)
          _flights[tag].divert(manifest);
        else
          _flights[tag] = _HeroFlight(_handleFlightEnded)..start(manifest);
      } else if (_flights[tag] != null) {
        _flights[tag].abort();
      }
    }
  }

  void _handleFlightEnded(_HeroFlight flight) {
    _flights.remove(flight.manifest.tag);
  }

  static final HeroFlightShuttleBuilder _defaultHeroFlightShuttleBuilder = (
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection flightDirection,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    final Hero toHero = toHeroContext.widget;
    return toHero.child;
  };
}

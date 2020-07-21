import 'dart:async';
import 'dart:collection' show HashMap;

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/rendering.dart';

import 'banner.dart';
import 'basic.dart';
import 'binding.dart';
import 'framework.dart';
import 'focus_traversal.dart';
import 'localizations.dart';
import 'media_query.dart';
import 'navigator.dart';
import 'pages.dart';
import 'performance_overlay.dart';
import 'semantics_debugger.dart';
import 'text.dart';
import 'title.dart';
import 'widget_inspector.dart';

export 'package:flutter_web/ui.dart' show Locale;

typedef LocaleListResolutionCallback = Locale Function(
    List<Locale> locales, Iterable<Locale> supportedLocales);

typedef LocaleResolutionCallback = Locale Function(
    Locale locale, Iterable<Locale> supportedLocales);

typedef GenerateAppTitle = String Function(BuildContext context);

typedef PageRouteFactory = PageRoute<T> Function<T>(
    RouteSettings settings, WidgetBuilder builder);

class WidgetsApp extends StatefulWidget {
  WidgetsApp({
    Key key,
    this.navigatorKey,
    this.onGenerateRoute,
    this.onUnknownRoute,
    this.navigatorObservers = const <NavigatorObserver>[],
    this.initialRoute,
    this.pageRouteBuilder,
    this.home,
    this.routes = const <String, WidgetBuilder>{},
    this.builder,
    this.title = '',
    this.onGenerateTitle,
    this.textStyle,
    @required this.color,
    this.locale,
    this.localizationsDelegates,
    this.localeListResolutionCallback,
    this.localeResolutionCallback,
    this.supportedLocales = const <Locale>[Locale('en', 'US')],
    this.showPerformanceOverlay = false,
    this.checkerboardRasterCacheImages = false,
    this.checkerboardOffscreenLayers = false,
    this.showSemanticsDebugger = false,
    this.debugShowWidgetInspector = false,
    this.debugShowCheckedModeBanner = true,
    this.inspectorSelectButtonBuilder,
  })  : assert(navigatorObservers != null),
        assert(routes != null),
        assert(
            home == null || !routes.containsKey(Navigator.defaultRouteName),
            'If the home property is specified, the routes table '
            'cannot include an entry for "/", since it would be redundant.'),
        assert(
            builder != null ||
                home != null ||
                routes.containsKey(Navigator.defaultRouteName) ||
                onGenerateRoute != null ||
                onUnknownRoute != null,
            'Either the home property must be specified, '
            'or the routes table must include an entry for "/", '
            'or there must be on onGenerateRoute callback specified, '
            'or there must be an onUnknownRoute callback specified, '
            'or the builder property must be specified, '
            'because otherwise there is nothing to fall back on if the '
            'app is started with an intent that specifies an unknown route.'),
        assert(
            (home != null ||
                    routes.isNotEmpty ||
                    onGenerateRoute != null ||
                    onUnknownRoute != null) ||
                (builder != null &&
                    navigatorKey == null &&
                    initialRoute == null &&
                    navigatorObservers.isEmpty),
            'If no route is provided using '
            'home, routes, onGenerateRoute, or onUnknownRoute, '
            'a non-null callback for the builder property must be provided, '
            'and the other navigator-related properties, '
            'navigatorKey, initialRoute, and navigatorObservers, '
            'must have their initial values '
            '(null, null, and the empty list, respectively).'),
        assert(
            builder != null ||
                onGenerateRoute != null ||
                pageRouteBuilder != null,
            'If neither builder nor onGenerateRoute are provided, the '
            'pageRouteBuilder must be specified so that the default handler '
            'will know what kind of PageRoute transition to build.'),
        assert(title != null),
        assert(color != null),
        assert(supportedLocales != null && supportedLocales.isNotEmpty),
        assert(showPerformanceOverlay != null),
        assert(checkerboardRasterCacheImages != null),
        assert(checkerboardOffscreenLayers != null),
        assert(showSemanticsDebugger != null),
        assert(debugShowCheckedModeBanner != null),
        assert(debugShowWidgetInspector != null),
        super(key: key);

  final GlobalKey<NavigatorState> navigatorKey;

  final RouteFactory onGenerateRoute;

  final PageRouteFactory pageRouteBuilder;

  final Widget home;

  final Map<String, WidgetBuilder> routes;

  final RouteFactory onUnknownRoute;

  final String initialRoute;

  final List<NavigatorObserver> navigatorObservers;

  final TransitionBuilder builder;

  final String title;

  final GenerateAppTitle onGenerateTitle;

  final TextStyle textStyle;

  final Color color;

  final Locale locale;

  final Iterable<LocalizationsDelegate<dynamic>> localizationsDelegates;

  final LocaleListResolutionCallback localeListResolutionCallback;

  final LocaleResolutionCallback localeResolutionCallback;

  final Iterable<Locale> supportedLocales;

  final bool showPerformanceOverlay;

  final bool checkerboardRasterCacheImages;

  final bool checkerboardOffscreenLayers;

  final bool showSemanticsDebugger;

  final bool debugShowWidgetInspector;

  final InspectorSelectButtonBuilder inspectorSelectButtonBuilder;

  final bool debugShowCheckedModeBanner;

  static bool showPerformanceOverlayOverride = false;

  static bool debugShowWidgetInspectorOverride = false;

  static bool debugAllowBannerOverride = true;

  @override
  _WidgetsAppState createState() => _WidgetsAppState();
}

class _WidgetsAppState extends State<WidgetsApp>
    implements WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    _updateNavigator();
    _locale = _resolveLocales(
        WidgetsBinding.instance.window.locales, widget.supportedLocales);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(WidgetsApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.navigatorKey != oldWidget.navigatorKey) _updateNavigator();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {}

  @override
  void didHaveMemoryPressure() {}

  GlobalKey<NavigatorState> _navigator;

  void _updateNavigator() {
    _navigator = widget.navigatorKey ?? GlobalObjectKey<NavigatorState>(this);
  }

  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    final String name = settings.name;
    final WidgetBuilder pageContentBuilder =
        name == Navigator.defaultRouteName && widget.home != null
            ? (BuildContext context) => widget.home
            : widget.routes[name];

    if (pageContentBuilder != null) {
      assert(
          widget.pageRouteBuilder != null,
          'The default onGenerateRoute handler for WidgetsApp must have a '
          'pageRouteBuilder set if the home or routes properties are set.');
      final Route<dynamic> route = widget.pageRouteBuilder<dynamic>(
        settings,
        pageContentBuilder,
      );
      assert(route != null,
          'The pageRouteBuilder for WidgetsApp must return a valid non-null Route.');
      return route;
    }
    if (widget.onGenerateRoute != null) return widget.onGenerateRoute(settings);
    return null;
  }

  Route<dynamic> _onUnknownRoute(RouteSettings settings) {
    assert(() {
      if (widget.onUnknownRoute == null) {
        throw FlutterError(
            'Could not find a generator for route $settings in the $runtimeType.\n'
            'Generators for routes are searched for in the following order:\n'
            ' 1. For the "/" route, the "home" property, if non-null, is used.\n'
            ' 2. Otherwise, the "routes" table is used, if it has an entry for '
            'the route.\n'
            ' 3. Otherwise, onGenerateRoute is called. It should return a '
            'non-null value for any valid route not handled by "home" and "routes".\n'
            ' 4. Finally if all else fails onUnknownRoute is called.\n'
            'Unfortunately, onUnknownRoute was not set.');
      }
      return true;
    }());
    final Route<dynamic> result = widget.onUnknownRoute(settings);
    assert(() {
      if (result == null) {
        throw FlutterError('The onUnknownRoute callback returned null.\n'
            'When the $runtimeType requested the route $settings from its '
            'onUnknownRoute callback, the callback returned null. Such callbacks '
            'must never return null.');
      }
      return true;
    }());
    return result;
  }

  @override
  Future<bool> didPopRoute() async {
    assert(mounted);
    final NavigatorState navigator = _navigator?.currentState;
    if (navigator == null) return false;
    return await navigator.maybePop();
  }

  @override
  Future<bool> didPushRoute(String route) async {
    assert(mounted);
    final NavigatorState navigator = _navigator?.currentState;
    if (navigator == null) return false;
    navigator.pushNamed(route);
    return true;
  }

  Locale _locale;

  Locale _resolveLocales(
      List<Locale> preferredLocales, Iterable<Locale> supportedLocales) {
    if (widget.localeListResolutionCallback != null) {
      final Locale locale = widget.localeListResolutionCallback(
          preferredLocales, widget.supportedLocales);
      if (locale != null) return locale;
    }

    if (widget.localeResolutionCallback != null) {
      final Locale locale = widget.localeResolutionCallback(
        preferredLocales != null && preferredLocales.isNotEmpty
            ? preferredLocales.first
            : null,
        widget.supportedLocales,
      );
      if (locale != null) return locale;
    }

    return basicLocaleListResolution(preferredLocales, supportedLocales);
  }

  static Locale basicLocaleListResolution(
      List<Locale> preferredLocales, Iterable<Locale> supportedLocales) {
    if (preferredLocales == null || preferredLocales.isEmpty) {
      return supportedLocales.first;
    }

    final Map<String, Locale> allSupportedLocales = HashMap<String, Locale>();
    final Map<String, Locale> languageAndCountryLocales =
        HashMap<String, Locale>();
    final Map<String, Locale> languageAndScriptLocales =
        HashMap<String, Locale>();
    final Map<String, Locale> languageLocales = HashMap<String, Locale>();
    final Map<String, Locale> countryLocales = HashMap<String, Locale>();
    for (Locale locale in supportedLocales) {
      allSupportedLocales[
              '${locale.languageCode}_${locale.scriptCode}_${locale.countryCode}'] ??=
          locale;
      languageAndScriptLocales[
          '${locale.languageCode}_${locale.scriptCode}'] ??= locale;
      languageAndCountryLocales[
          '${locale.languageCode}_${locale.countryCode}'] ??= locale;
      languageLocales[locale.languageCode] ??= locale;
      countryLocales[locale.countryCode] ??= locale;
    }

    Locale matchesLanguageCode;
    Locale matchesCountryCode;

    for (int localeIndex = 0;
        localeIndex < preferredLocales.length;
        localeIndex += 1) {
      final Locale userLocale = preferredLocales[localeIndex];

      if (allSupportedLocales.containsKey(
          '${userLocale.languageCode}_${userLocale.scriptCode}_${userLocale.countryCode}')) {
        return userLocale;
      }

      if (userLocale.scriptCode != null) {
        final Locale match = languageAndScriptLocales[
            '${userLocale.languageCode}_${userLocale.scriptCode}'];
        if (match != null) {
          return match;
        }
      }

      if (userLocale.countryCode != null) {
        final Locale match = languageAndCountryLocales[
            '${userLocale.languageCode}_${userLocale.countryCode}'];
        if (match != null) {
          return match;
        }
      }

      if (matchesLanguageCode != null) {
        return matchesLanguageCode;
      }

      Locale match = languageLocales[userLocale.languageCode];
      if (match != null) {
        matchesLanguageCode = match;

        if (localeIndex == 0 &&
            !(localeIndex + 1 < preferredLocales.length &&
                preferredLocales[localeIndex + 1].languageCode ==
                    userLocale.languageCode)) {
          return matchesLanguageCode;
        }
      }

      if (matchesCountryCode == null && userLocale.countryCode != null) {
        match = countryLocales[userLocale.countryCode];
        if (match != null) {
          matchesCountryCode = match;
        }
      }
    }

    final Locale resolvedLocale =
        matchesLanguageCode ?? matchesCountryCode ?? supportedLocales.first;
    return resolvedLocale;
  }

  @override
  void didChangeLocales(List<Locale> locales) {
    final Locale newLocale = _resolveLocales(locales, widget.supportedLocales);
    if (newLocale != _locale) {
      setState(() {
        _locale = newLocale;
      });
    }
  }

  Iterable<LocalizationsDelegate<dynamic>> get _localizationsDelegates sync* {
    if (widget.localizationsDelegates != null)
      yield* widget.localizationsDelegates;
    yield DefaultWidgetsLocalizations.delegate;
  }

  @override
  void didChangeAccessibilityFeatures() {
    setState(() {});
  }

  @override
  void didChangeMetrics() {
    setState(() {});
  }

  @override
  void didChangeTextScaleFactor() {
    setState(() {});
  }

  @override
  void didChangePlatformBrightness() {
    setState(() {});
  }

  bool _debugCheckLocalizations(Locale appLocale) {
    assert(() {
      final Set<Type> unsupportedTypes = _localizationsDelegates
          .map<Type>((LocalizationsDelegate<dynamic> delegate) => delegate.type)
          .toSet();
      for (LocalizationsDelegate<dynamic> delegate in _localizationsDelegates) {
        if (!unsupportedTypes.contains(delegate.type)) continue;
        if (delegate.isSupported(appLocale))
          unsupportedTypes.remove(delegate.type);
      }
      if (unsupportedTypes.isEmpty) return true;

      if (listEquals(
          unsupportedTypes.map((Type type) => type.toString()).toList(),
          <String>['CupertinoLocalizations'])) return true;

      final StringBuffer message = StringBuffer();
      message.writeln('\u2550' * 8);
      message.writeln(
          'Warning: This application\'s locale, $appLocale, is not supported by all of its\n'
          'localization delegates.');
      for (Type unsupportedType in unsupportedTypes) {
        if (unsupportedType.toString() == 'CupertinoLocalizations') continue;
        message.writeln(
            '> A $unsupportedType delegate that supports the $appLocale locale was not found.');
      }
      message.writeln(
          'See https://flutter.dev/tutorials/internationalization/ for more\n'
          'information about configuring an app\'s locale, supportedLocales,\n'
          'and localizationsDelegates parameters.');
      message.writeln('\u2550' * 8);
      debugPrint(message.toString());
      return true;
    }());
    return true;
  }

  @override
  Widget build(BuildContext context) {
    Widget navigator;
    if (_navigator != null) {
      navigator = Navigator(
        key: _navigator,
        initialRoute: WidgetsBinding.instance.window.defaultRouteName !=
                Navigator.defaultRouteName
            ? WidgetsBinding.instance.window.defaultRouteName
            : widget.initialRoute ??
                WidgetsBinding.instance.window.defaultRouteName,
        onGenerateRoute: _onGenerateRoute,
        onUnknownRoute: _onUnknownRoute,
        observers: widget.navigatorObservers,
      );
    }

    Widget result;
    if (widget.builder != null) {
      result = Builder(
        builder: (BuildContext context) {
          return widget.builder(context, navigator);
        },
      );
    } else {
      assert(navigator != null);
      result = navigator;
    }

    if (widget.textStyle != null) {
      result = DefaultTextStyle(
        style: widget.textStyle,
        child: result,
      );
    }

    PerformanceOverlay performanceOverlay;

    if (widget.showPerformanceOverlay ||
        WidgetsApp.showPerformanceOverlayOverride) {
      performanceOverlay = PerformanceOverlay.allEnabled(
        checkerboardRasterCacheImages: widget.checkerboardRasterCacheImages,
        checkerboardOffscreenLayers: widget.checkerboardOffscreenLayers,
      );
    } else if (widget.checkerboardRasterCacheImages ||
        widget.checkerboardOffscreenLayers) {
      performanceOverlay = PerformanceOverlay(
        checkerboardRasterCacheImages: widget.checkerboardRasterCacheImages,
        checkerboardOffscreenLayers: widget.checkerboardOffscreenLayers,
      );
    }
    if (performanceOverlay != null) {
      result = Stack(
        children: <Widget>[
          result,
          Positioned(
              top: 0.0, left: 0.0, right: 0.0, child: performanceOverlay),
        ],
      );
    }

    if (widget.showSemanticsDebugger) {
      result = SemanticsDebugger(
        child: result,
      );
    }

    assert(() {
      if (widget.debugShowWidgetInspector ||
          WidgetsApp.debugShowWidgetInspectorOverride) {
        result = WidgetInspector(
          child: result,
          selectButtonBuilder: widget.inspectorSelectButtonBuilder,
        );
      }
      if (widget.debugShowCheckedModeBanner &&
          WidgetsApp.debugAllowBannerOverride) {
        result = CheckedModeBanner(
          child: result,
        );
      }
      return true;
    }());

    Widget title;
    if (widget.onGenerateTitle != null) {
      title = Builder(
        builder: (BuildContext context) {
          final String title = widget.onGenerateTitle(context);
          assert(
              title != null, 'onGenerateTitle must return a non-null String');
          return Title(
            title: title,
            color: widget.color,
            child: result,
          );
        },
      );
    } else {
      title = Title(
        title: widget.title,
        color: widget.color,
        child: result,
      );
    }

    final Locale appLocale = widget.locale != null
        ? _resolveLocales(<Locale>[widget.locale], widget.supportedLocales)
        : _locale;

    assert(_debugCheckLocalizations(appLocale));

    return DefaultFocusTraversal(
      policy: ReadingOrderTraversalPolicy(),
      child: MediaQuery(
        data: MediaQueryData.fromWindow(WidgetsBinding.instance.window),
        child: Localizations(
          locale: appLocale,
          delegates: _localizationsDelegates.toList(),
          child: title,
        ),
      ),
    );
  }
}

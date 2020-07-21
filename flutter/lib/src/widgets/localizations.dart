import 'dart:async';
import 'package:flutter_web/ui.dart' show Locale;

import 'package:flutter_web/foundation.dart';

import 'basic.dart';
import 'binding.dart';
import 'container.dart';
import 'framework.dart';

class _Pending {
  _Pending(this.delegate, this.futureValue);
  final LocalizationsDelegate<dynamic> delegate;
  final Future<dynamic> futureValue;
}

Future<Map<Type, dynamic>> _loadAll(
    Locale locale, Iterable<LocalizationsDelegate<dynamic>> allDelegates) {
  final Map<Type, dynamic> output = <Type, dynamic>{};
  List<_Pending> pendingList;

  final Set<Type> types = Set<Type>();
  final List<LocalizationsDelegate<dynamic>> delegates =
      <LocalizationsDelegate<dynamic>>[];
  for (LocalizationsDelegate<dynamic> delegate in allDelegates) {
    if (!types.contains(delegate.type) && delegate.isSupported(locale)) {
      types.add(delegate.type);
      delegates.add(delegate);
    }
  }

  for (LocalizationsDelegate<dynamic> delegate in delegates) {
    final Future<dynamic> inputValue = delegate.load(locale);
    dynamic completedValue;
    final Future<dynamic> futureValue =
        inputValue.then<dynamic>((dynamic value) {
      return completedValue = value;
    });
    if (completedValue != null) {
      final Type type = delegate.type;
      assert(!output.containsKey(type));
      output[type] = completedValue;
    } else {
      pendingList ??= <_Pending>[];
      pendingList.add(_Pending(delegate, futureValue));
    }
  }

  if (pendingList == null) return SynchronousFuture<Map<Type, dynamic>>(output);

  return Future.wait<dynamic>(pendingList.map((_Pending p) => p.futureValue))
      .then<Map<Type, dynamic>>((List<dynamic> values) {
    assert(values.length == pendingList.length);
    for (int i = 0; i < values.length; i += 1) {
      final Type type = pendingList[i].delegate.type;
      assert(!output.containsKey(type));
      output[type] = values[i];
    }
    return output;
  });
}

abstract class LocalizationsDelegate<T> {
  const LocalizationsDelegate();

  bool isSupported(Locale locale);

  Future<T> load(Locale locale);

  bool shouldReload(covariant LocalizationsDelegate<T> old);

  Type get type => T;

  @override
  String toString() => '$runtimeType[$type]';
}

abstract class WidgetsLocalizations {
  TextDirection get textDirection;

  static WidgetsLocalizations of(BuildContext context) {
    return Localizations.of<WidgetsLocalizations>(
        context, WidgetsLocalizations);
  }
}

class _WidgetsLocalizationsDelegate
    extends LocalizationsDelegate<WidgetsLocalizations> {
  const _WidgetsLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<WidgetsLocalizations> load(Locale locale) =>
      DefaultWidgetsLocalizations.load(locale);

  @override
  bool shouldReload(_WidgetsLocalizationsDelegate old) => false;
}

class DefaultWidgetsLocalizations implements WidgetsLocalizations {
  const DefaultWidgetsLocalizations();

  @override
  TextDirection get textDirection => TextDirection.ltr;

  static Future<WidgetsLocalizations> load(Locale locale) {
    return SynchronousFuture<WidgetsLocalizations>(
        const DefaultWidgetsLocalizations());
  }

  static const LocalizationsDelegate<WidgetsLocalizations> delegate =
      _WidgetsLocalizationsDelegate();
}

class _LocalizationsScope extends InheritedWidget {
  const _LocalizationsScope({
    Key key,
    @required this.locale,
    @required this.localizationsState,
    @required this.typeToResources,
    Widget child,
  })  : assert(localizationsState != null),
        assert(typeToResources != null),
        super(key: key, child: child);

  final Locale locale;
  final _LocalizationsState localizationsState;
  final Map<Type, dynamic> typeToResources;

  @override
  bool updateShouldNotify(_LocalizationsScope old) {
    return typeToResources != old.typeToResources;
  }
}

class Localizations extends StatefulWidget {
  Localizations({
    Key key,
    @required this.locale,
    @required this.delegates,
    this.child,
  })  : assert(locale != null),
        assert(delegates != null),
        assert(delegates.any((LocalizationsDelegate<dynamic> delegate) =>
            delegate is LocalizationsDelegate<WidgetsLocalizations>)),
        super(key: key);

  factory Localizations.override({
    Key key,
    @required BuildContext context,
    Locale locale,
    List<LocalizationsDelegate<dynamic>> delegates,
    Widget child,
  }) {
    final List<LocalizationsDelegate<dynamic>> mergedDelegates =
        Localizations._delegatesOf(context);
    if (delegates != null) mergedDelegates.insertAll(0, delegates);
    return Localizations(
      key: key,
      locale: locale ?? Localizations.localeOf(context),
      delegates: mergedDelegates,
      child: child,
    );
  }

  final Locale locale;

  final List<LocalizationsDelegate<dynamic>> delegates;

  final Widget child;

  static Locale localeOf(BuildContext context, {bool nullOk = false}) {
    assert(context != null);
    assert(nullOk != null);
    final _LocalizationsScope scope =
        context.inheritFromWidgetOfExactType(_LocalizationsScope);
    if (nullOk && scope == null) return null;
    assert(scope != null, 'a Localizations ancestor was not found');
    return scope.localizationsState.locale;
  }

  static List<LocalizationsDelegate<dynamic>> _delegatesOf(
      BuildContext context) {
    assert(context != null);
    final _LocalizationsScope scope =
        context.inheritFromWidgetOfExactType(_LocalizationsScope);
    assert(scope != null, 'a Localizations ancestor was not found');
    return List<LocalizationsDelegate<dynamic>>.from(
        scope.localizationsState.widget.delegates);
  }

  static T of<T>(BuildContext context, Type type) {
    assert(context != null);
    assert(type != null);
    final _LocalizationsScope scope =
        context.inheritFromWidgetOfExactType(_LocalizationsScope);
    return scope?.localizationsState?.resourcesFor<T>(type);
  }

  @override
  _LocalizationsState createState() => _LocalizationsState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Locale>('locale', locale));
    properties.add(IterableProperty<LocalizationsDelegate<dynamic>>(
        'delegates', delegates));
  }
}

class _LocalizationsState extends State<Localizations> {
  final GlobalKey _localizedResourcesScopeKey = GlobalKey();
  Map<Type, dynamic> _typeToResources = <Type, dynamic>{};

  Locale get locale => _locale;
  Locale _locale;

  @override
  void initState() {
    super.initState();
    load(widget.locale);
  }

  bool _anyDelegatesShouldReload(Localizations old) {
    if (widget.delegates.length != old.delegates.length) return true;
    final List<LocalizationsDelegate<dynamic>> delegates =
        widget.delegates.toList();
    final List<LocalizationsDelegate<dynamic>> oldDelegates =
        old.delegates.toList();
    for (int i = 0; i < delegates.length; i += 1) {
      final LocalizationsDelegate<dynamic> delegate = delegates[i];
      final LocalizationsDelegate<dynamic> oldDelegate = oldDelegates[i];
      if (delegate.runtimeType != oldDelegate.runtimeType ||
          delegate.shouldReload(oldDelegate)) return true;
    }
    return false;
  }

  @override
  void didUpdateWidget(Localizations old) {
    super.didUpdateWidget(old);
    if (widget.locale != old.locale ||
        (widget.delegates == null && old.delegates != null) ||
        (widget.delegates != null && old.delegates == null) ||
        (widget.delegates != null && _anyDelegatesShouldReload(old)))
      load(widget.locale);
  }

  void load(Locale locale) {
    final Iterable<LocalizationsDelegate<dynamic>> delegates = widget.delegates;
    if (delegates == null || delegates.isEmpty) {
      _locale = locale;
      return;
    }

    Map<Type, dynamic> typeToResources;
    final Future<Map<Type, dynamic>> typeToResourcesFuture =
        _loadAll(locale, delegates).then((Map<Type, dynamic> value) {
      return typeToResources = value;
    });

    if (typeToResources != null) {
      _typeToResources = typeToResources;
      _locale = locale;
    } else {
      WidgetsBinding.instance.deferFirstFrameReport();
      typeToResourcesFuture.then((Map<Type, dynamic> value) {
        WidgetsBinding.instance.allowFirstFrameReport();
        if (!mounted) return;
        setState(() {
          _typeToResources = value;
          _locale = locale;
        });
      });
    }
  }

  T resourcesFor<T>(Type type) {
    assert(type != null);
    final T resources = _typeToResources[type];
    return resources;
  }

  TextDirection get _textDirection {
    final WidgetsLocalizations resources =
        _typeToResources[WidgetsLocalizations];
    assert(resources != null);
    return resources.textDirection;
  }

  @override
  Widget build(BuildContext context) {
    if (_locale == null) return Container();
    return Semantics(
      textDirection: _textDirection,
      child: _LocalizationsScope(
        key: _localizedResourcesScopeKey,
        locale: _locale,
        localizationsState: this,
        typeToResources: _typeToResources,
        child: Directionality(
          textDirection: _textDirection,
          child: widget.child,
        ),
      ),
    );
  }
}

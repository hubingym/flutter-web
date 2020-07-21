import 'package:flutter_web/cupertino.dart';
import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/widgets.dart';

import 'material_localizations.dart';
import 'theme_data.dart';
import 'typography.dart';

export 'theme_data.dart' show Brightness, ThemeData;

const Duration kThemeAnimationDuration = Duration(milliseconds: 200);

class Theme extends StatelessWidget {
  const Theme({
    Key key,
    @required this.data,
    this.isMaterialAppTheme = false,
    @required this.child,
  })  : assert(child != null),
        assert(data != null),
        super(key: key);

  final ThemeData data;

  final bool isMaterialAppTheme;

  final Widget child;

  static final ThemeData _kFallbackTheme = ThemeData.fallback();

  static ThemeData of(BuildContext context, {bool shadowThemeOnly = false}) {
    final _InheritedTheme inheritedTheme =
        context.inheritFromWidgetOfExactType(_InheritedTheme);
    if (shadowThemeOnly) {
      if (inheritedTheme == null || inheritedTheme.theme.isMaterialAppTheme)
        return null;
      return inheritedTheme.theme.data;
    }

    final MaterialLocalizations localizations =
        MaterialLocalizations.of(context);
    final ScriptCategory category =
        localizations?.scriptCategory ?? ScriptCategory.englishLike;
    final ThemeData theme = inheritedTheme?.theme?.data ?? _kFallbackTheme;
    return ThemeData.localize(
        theme, theme.typography.geometryThemeFor(category));
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedTheme(
        theme: this,
        child: CupertinoTheme(
          data: MaterialBasedCupertinoThemeData(
            materialTheme: data,
          ),
          child: IconTheme(
            data: data.iconTheme,
            child: child,
          ),
        ));
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(DiagnosticsProperty<ThemeData>('data', data, showName: false));
  }
}

class _InheritedTheme extends InheritedWidget {
  const _InheritedTheme({
    Key key,
    @required this.theme,
    @required Widget child,
  })  : assert(theme != null),
        super(key: key, child: child);

  final Theme theme;

  @override
  bool updateShouldNotify(_InheritedTheme old) => theme.data != old.theme.data;
}

class ThemeDataTween extends Tween<ThemeData> {
  ThemeDataTween({ThemeData begin, ThemeData end})
      : super(begin: begin, end: end);

  @override
  ThemeData lerp(double t) => ThemeData.lerp(begin, end, t);
}

class AnimatedTheme extends ImplicitlyAnimatedWidget {
  const AnimatedTheme({
    Key key,
    @required this.data,
    this.isMaterialAppTheme = false,
    Curve curve = Curves.linear,
    Duration duration = kThemeAnimationDuration,
    @required this.child,
  })  : assert(child != null),
        assert(data != null),
        super(key: key, curve: curve, duration: duration);

  final ThemeData data;

  final bool isMaterialAppTheme;

  final Widget child;

  @override
  _AnimatedThemeState createState() => _AnimatedThemeState();
}

class _AnimatedThemeState extends AnimatedWidgetBaseState<AnimatedTheme> {
  ThemeDataTween _data;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _data = visitor(
        _data, widget.data, (dynamic value) => ThemeDataTween(begin: value));
    assert(_data != null);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      isMaterialAppTheme: widget.isMaterialAppTheme,
      child: widget.child,
      data: _data.evaluate(animation),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(DiagnosticsProperty<ThemeDataTween>('data', _data,
        showName: false, defaultValue: null));
  }
}

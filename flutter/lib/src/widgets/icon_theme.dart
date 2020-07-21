import 'package:flutter_web/foundation.dart';

import 'basic.dart';
import 'framework.dart';
import 'icon_theme_data.dart';

class IconTheme extends InheritedWidget {
  const IconTheme({
    Key key,
    @required this.data,
    @required Widget child,
  })  : assert(data != null),
        assert(child != null),
        super(key: key, child: child);

  static Widget merge({
    Key key,
    @required IconThemeData data,
    @required Widget child,
  }) {
    return Builder(
      builder: (BuildContext context) {
        return IconTheme(
          key: key,
          data: _getInheritedIconThemeData(context).merge(data),
          child: child,
        );
      },
    );
  }

  final IconThemeData data;

  static IconThemeData of(BuildContext context) {
    final IconThemeData iconThemeData = _getInheritedIconThemeData(context);
    return iconThemeData.isConcrete
        ? iconThemeData
        : const IconThemeData.fallback().merge(iconThemeData);
  }

  static IconThemeData _getInheritedIconThemeData(BuildContext context) {
    final IconTheme iconTheme = context.inheritFromWidgetOfExactType(IconTheme);
    return iconTheme?.data ?? const IconThemeData.fallback();
  }

  @override
  bool updateShouldNotify(IconTheme oldWidget) => data != oldWidget.data;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(DiagnosticsProperty<IconThemeData>('data', data, showName: false));
  }
}

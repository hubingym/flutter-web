import 'package:flutter_web/widgets.dart' show NavigatorObserver, Route;

import 'package:flutter_web/ui.dart' as ui;

class WebOnlyNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic> previousRoute) {
    _webOnlyNotifyRouteName(route);
  }

  @override
  void didReplace({Route<dynamic> newRoute, Route<dynamic> oldRoute}) {
    _webOnlyNotifyRouteName(newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic> previousRoute) {
    _webOnlyNotifyRouteName(previousRoute);
  }

  void _webOnlyNotifyRouteName(Route<dynamic> route) {
    final String routeName = route?.settings?.name;
    if (routeName != null) {
      ui.webOnlyRouteName = routeName;
    }
  }
}

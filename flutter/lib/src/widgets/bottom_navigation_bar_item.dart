import 'package:flutter_web/ui.dart' show Color;

import 'framework.dart';

class BottomNavigationBarItem {
  const BottomNavigationBarItem({
    @required this.icon,
    this.title,
    Widget activeIcon,
    this.backgroundColor,
  })  : activeIcon = activeIcon ?? icon,
        assert(icon != null);

  final Widget icon;

  final Widget activeIcon;

  final Widget title;

  final Color backgroundColor;
}

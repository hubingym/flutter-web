import 'package:flutter_web/rendering.dart';

import 'basic.dart';
import 'framework.dart';

abstract class PreferredSizeWidget implements Widget {
  Size get preferredSize;
}

class PreferredSize extends StatelessWidget implements PreferredSizeWidget {
  const PreferredSize({
    Key key,
    @required this.child,
    @required this.preferredSize,
  }) : super(key: key);

  final Widget child;

  @override
  final Size preferredSize;

  @override
  Widget build(BuildContext context) => child;
}

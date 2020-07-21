import 'package:flutter_web/foundation.dart';

import 'framework.dart';
import 'scroll_controller.dart';

class PrimaryScrollController extends InheritedWidget {
  const PrimaryScrollController(
      {Key key, @required this.controller, @required Widget child})
      : assert(controller != null),
        super(key: key, child: child);

  const PrimaryScrollController.none({Key key, @required Widget child})
      : controller = null,
        super(key: key, child: child);

  final ScrollController controller;

  static ScrollController of(BuildContext context) {
    final PrimaryScrollController result =
        context.inheritFromWidgetOfExactType(PrimaryScrollController);
    return result?.controller;
  }

  @override
  bool updateShouldNotify(PrimaryScrollController oldWidget) =>
      controller != oldWidget.controller;
}

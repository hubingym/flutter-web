import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/rendering.dart';

import 'framework.dart';
import 'overscroll_indicator.dart';
import 'scroll_physics.dart';

const Color _kDefaultGlowColor = const Color(0xFFFFFFFF);

@immutable
class ScrollBehavior {
  const ScrollBehavior();

  TargetPlatform getPlatform(BuildContext context) => defaultTargetPlatform;

  Widget buildViewportChrome(
      BuildContext context, Widget child, AxisDirection axisDirection) {
    switch (getPlatform(context)) {
      case TargetPlatform.iOS:
        return child;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        return new GlowingOverscrollIndicator(
          child: child,
          axisDirection: axisDirection,
          color: _kDefaultGlowColor,
        );
    }
    return null;
  }

  ScrollPhysics getScrollPhysics(BuildContext context) {
    switch (getPlatform(context)) {
      case TargetPlatform.iOS:
        return const BouncingScrollPhysics();
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        return const ClampingScrollPhysics();
    }
    return null;
  }

  bool shouldNotify(covariant ScrollBehavior oldDelegate) => false;

  @override
  String toString() => '$runtimeType';
}

class ScrollConfiguration extends InheritedWidget {
  const ScrollConfiguration({
    Key key,
    @required this.behavior,
    @required Widget child,
  }) : super(key: key, child: child);

  final ScrollBehavior behavior;

  static ScrollBehavior of(BuildContext context) {
    final ScrollConfiguration configuration =
        context.inheritFromWidgetOfExactType(ScrollConfiguration);
    return configuration?.behavior ?? const ScrollBehavior();
  }

  @override
  bool updateShouldNotify(ScrollConfiguration oldWidget) {
    assert(behavior != null);
    return behavior.runtimeType != oldWidget.behavior.runtimeType ||
        (behavior != oldWidget.behavior &&
            behavior.shouldNotify(oldWidget.behavior));
  }
}

import 'package:flutter_web/foundation.dart';

import 'basic.dart';
import 'framework.dart';
import 'ticker_provider.dart';

class Visibility extends StatelessWidget {
  const Visibility({
    Key key,
    @required this.child,
    this.replacement = const SizedBox.shrink(),
    this.visible = true,
    this.maintainState = false,
    this.maintainAnimation = false,
    this.maintainSize = false,
    this.maintainSemantics = false,
    this.maintainInteractivity = false,
  })  : assert(child != null),
        assert(replacement != null),
        assert(visible != null),
        assert(maintainState != null),
        assert(maintainAnimation != null),
        assert(maintainSize != null),
        assert(maintainState == true || maintainAnimation == false,
            'Cannot maintain animations if the state is not also maintained.'),
        assert(maintainAnimation == true || maintainSize == false,
            'Cannot maintain size if animations are not maintained.'),
        assert(maintainSize == true || maintainSemantics == false,
            'Cannot maintain semantics if size is not maintained.'),
        assert(maintainSize == true || maintainInteractivity == false,
            'Cannot maintain interactivity if size is not maintained.'),
        super(key: key);

  final Widget child;

  final Widget replacement;

  final bool visible;

  final bool maintainState;

  final bool maintainAnimation;

  final bool maintainSize;

  final bool maintainSemantics;

  final bool maintainInteractivity;

  @override
  Widget build(BuildContext context) {
    if (maintainSize) {
      Widget result = child;
      if (!maintainInteractivity) {
        result = IgnorePointer(
          child: child,
          ignoring: !visible,
          ignoringSemantics: !visible && !maintainSemantics,
        );
      }
      return Opacity(
        opacity: visible ? 1.0 : 0.0,
        alwaysIncludeSemantics: maintainSemantics,
        child: result,
      );
    }
    assert(!maintainInteractivity);
    assert(!maintainSemantics);
    assert(!maintainSize);
    if (maintainState) {
      Widget result = child;
      if (!maintainAnimation)
        result = TickerMode(child: child, enabled: visible);
      return Offstage(
        child: result,
        offstage: !visible,
      );
    }
    assert(!maintainAnimation);
    assert(!maintainState);
    return visible ? child : replacement;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagProperty('visible',
        value: visible, ifFalse: 'hidden', ifTrue: 'visible'));
    properties.add(FlagProperty('maintainState',
        value: maintainState, ifFalse: 'maintainState'));
    properties.add(FlagProperty('maintainAnimation',
        value: maintainAnimation, ifFalse: 'maintainAnimation'));
    properties.add(FlagProperty('maintainSize',
        value: maintainSize, ifFalse: 'maintainSize'));
    properties.add(FlagProperty('maintainSemantics',
        value: maintainSemantics, ifFalse: 'maintainSemantics'));
    properties.add(FlagProperty('maintainInteractivity',
        value: maintainInteractivity, ifFalse: 'maintainInteractivity'));
  }
}

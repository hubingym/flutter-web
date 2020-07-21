import 'package:flutter_web/foundation.dart';

import 'basic.dart';
import 'container.dart';
import 'debug.dart';
import 'framework.dart';
import 'gesture_detector.dart';
import 'navigator.dart';
import 'transitions.dart';

class ModalBarrier extends StatelessWidget {
  const ModalBarrier({
    Key key,
    this.color,
    this.dismissible = true,
    this.semanticsLabel,
    this.barrierSemanticsDismissible = true,
  }) : super(key: key);

  final Color color;

  final bool dismissible;

  final bool barrierSemanticsDismissible;

  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    assert(!dismissible ||
        semanticsLabel == null ||
        debugCheckHasDirectionality(context));
    final bool semanticsDismissible =
        dismissible && defaultTargetPlatform != TargetPlatform.android;
    final bool modalBarrierSemanticsDismissible =
        barrierSemanticsDismissible ?? semanticsDismissible;
    return BlockSemantics(
        child: ExcludeSemantics(
            excluding:
                !semanticsDismissible || !modalBarrierSemanticsDismissible,
            child: GestureDetector(
                onTapDown: (TapDownDetails details) {
                  if (dismissible) Navigator.maybePop(context);
                },
                behavior: HitTestBehavior.opaque,
                child: Semantics(
                    label: semanticsDismissible ? semanticsLabel : null,
                    textDirection:
                        semanticsDismissible && semanticsLabel != null
                            ? Directionality.of(context)
                            : null,
                    child: ConstrainedBox(
                        constraints: const BoxConstraints.expand(),
                        child: color == null
                            ? null
                            : DecoratedBox(
                                decoration: BoxDecoration(
                                color: color,
                              )))))));
  }
}

class AnimatedModalBarrier extends AnimatedWidget {
  const AnimatedModalBarrier({
    Key key,
    Animation<Color> color,
    this.dismissible = true,
    this.semanticsLabel,
    this.barrierSemanticsDismissible,
  }) : super(key: key, listenable: color);

  Animation<Color> get color => listenable;

  final bool dismissible;

  final String semanticsLabel;

  final bool barrierSemanticsDismissible;

  @override
  Widget build(BuildContext context) {
    return ModalBarrier(
      color: color?.value,
      dismissible: dismissible,
      semanticsLabel: semanticsLabel,
      barrierSemanticsDismissible: barrierSemanticsDismissible,
    );
  }
}

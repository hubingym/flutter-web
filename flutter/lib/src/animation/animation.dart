import 'package:flutter_web/foundation.dart';

import 'tween.dart';

enum AnimationStatus {
  dismissed,

  forward,

  reverse,

  completed,
}

typedef AnimationStatusListener = void Function(AnimationStatus status);

abstract class Animation<T> extends Listenable implements ValueListenable<T> {
  const Animation();

  @override
  void addListener(VoidCallback listener);

  @override
  void removeListener(VoidCallback listener);

  void addStatusListener(AnimationStatusListener listener);

  void removeStatusListener(AnimationStatusListener listener);

  AnimationStatus get status;

  @override
  T get value;

  bool get isDismissed => status == AnimationStatus.dismissed;

  bool get isCompleted => status == AnimationStatus.completed;

  @optionalTypeArgs
  Animation<U> drive<U>(Animatable<U> child) {
    assert(this is Animation<double>);
    return child.animate(this as dynamic);
  }

  @override
  String toString() {
    return '${describeIdentity(this)}(${toStringDetails()})';
  }

  String toStringDetails() {
    assert(status != null);
    String icon;
    switch (status) {
      case AnimationStatus.forward:
        icon = '\u25B6';
        break;
      case AnimationStatus.reverse:
        icon = '\u25C0';
        break;
      case AnimationStatus.completed:
        icon = '\u23ED';
        break;
      case AnimationStatus.dismissed:
        icon = '\u23EE';
        break;
    }
    assert(icon != null);
    return '$icon';
  }
}

import 'package:meta/meta.dart';
import 'package:flutter_web/ui.dart';

import 'velocity_tracker.dart';

class DragDownDetails {
  DragDownDetails({
    this.globalPosition = Offset.zero,
    Offset localPosition,
  })  : assert(globalPosition != null),
        localPosition = localPosition ?? globalPosition;

  final Offset globalPosition;

  final Offset localPosition;

  @override
  String toString() => '$runtimeType($globalPosition)';
}

typedef GestureDragDownCallback = void Function(DragDownDetails details);

class DragStartDetails {
  DragStartDetails({
    this.sourceTimeStamp,
    this.globalPosition = Offset.zero,
    Offset localPosition,
  })  : assert(globalPosition != null),
        localPosition = localPosition ?? globalPosition;

  final Duration sourceTimeStamp;

  final Offset globalPosition;

  final Offset localPosition;

  @override
  String toString() => '$runtimeType($globalPosition)';
}

typedef GestureDragStartCallback = void Function(DragStartDetails details);

class DragUpdateDetails {
  DragUpdateDetails({
    this.sourceTimeStamp,
    this.delta = Offset.zero,
    this.primaryDelta,
    @required this.globalPosition,
    Offset localPosition,
  })  : assert(delta != null),
        assert(primaryDelta == null ||
            (primaryDelta == delta.dx && delta.dy == 0.0) ||
            (primaryDelta == delta.dy && delta.dx == 0.0)),
        localPosition = localPosition ?? globalPosition;

  final Duration sourceTimeStamp;

  final Offset delta;

  final double primaryDelta;

  final Offset globalPosition;

  final Offset localPosition;

  @override
  String toString() => '$runtimeType($delta)';
}

typedef GestureDragUpdateCallback = void Function(DragUpdateDetails details);

class DragEndDetails {
  DragEndDetails({
    this.velocity = Velocity.zero,
    this.primaryVelocity,
  })  : assert(velocity != null),
        assert(primaryVelocity == null ||
            primaryVelocity == velocity.pixelsPerSecond.dx ||
            primaryVelocity == velocity.pixelsPerSecond.dy);

  final Velocity velocity;

  final double primaryVelocity;

  @override
  String toString() => '$runtimeType($velocity)';
}

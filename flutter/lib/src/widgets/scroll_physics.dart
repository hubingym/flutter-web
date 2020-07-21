import 'dart:math' as math;

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/gestures.dart';
import 'package:flutter_web/physics.dart';
import 'package:flutter_web/ui.dart' as ui;

import 'overscroll_indicator.dart';
import 'scroll_metrics.dart';
import 'scroll_simulation.dart';

export 'package:flutter_web/physics.dart'
    show Simulation, ScrollSpringSimulation, Tolerance;

@immutable
class ScrollPhysics {
  const ScrollPhysics({this.parent});

  final ScrollPhysics parent;

  @protected
  ScrollPhysics buildParent(ScrollPhysics ancestor) =>
      parent?.applyTo(ancestor) ?? ancestor;

  ScrollPhysics applyTo(ScrollPhysics ancestor) {
    return ScrollPhysics(parent: buildParent(ancestor));
  }

  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    if (parent == null) return offset;
    return parent.applyPhysicsToUserOffset(position, offset);
  }

  bool shouldAcceptUserOffset(ScrollMetrics position) {
    if (parent == null)
      return position.pixels != 0.0 ||
          position.minScrollExtent != position.maxScrollExtent;
    return parent.shouldAcceptUserOffset(position);
  }

  double applyBoundaryConditions(ScrollMetrics position, double value) {
    if (parent == null) return 0.0;
    return parent.applyBoundaryConditions(position, value);
  }

  Simulation createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    if (parent == null) return null;
    return parent.createBallisticSimulation(position, velocity);
  }

  static final SpringDescription _kDefaultSpring =
      SpringDescription.withDampingRatio(
    mass: 0.5,
    stiffness: 100.0,
    ratio: 1.1,
  );

  SpringDescription get spring => parent?.spring ?? _kDefaultSpring;

  static final Tolerance _kDefaultTolerance = Tolerance(
      velocity: 1.0 / (0.050 * ui.window.devicePixelRatio),
      distance: 1.0 / ui.window.devicePixelRatio);

  Tolerance get tolerance => parent?.tolerance ?? _kDefaultTolerance;

  double get minFlingDistance => parent?.minFlingDistance ?? kTouchSlop;

  double get minFlingVelocity => parent?.minFlingVelocity ?? kMinFlingVelocity;

  double get maxFlingVelocity => parent?.maxFlingVelocity ?? kMaxFlingVelocity;

  double carriedMomentum(double existingVelocity) {
    if (parent == null) return 0.0;
    return parent.carriedMomentum(existingVelocity);
  }

  double get dragStartDistanceMotionThreshold =>
      parent?.dragStartDistanceMotionThreshold;

  bool get allowImplicitScrolling => true;

  @override
  String toString() {
    if (parent == null) return runtimeType.toString();
    return '$runtimeType -> $parent';
  }
}

class BouncingScrollPhysics extends ScrollPhysics {
  const BouncingScrollPhysics({ScrollPhysics parent}) : super(parent: parent);

  @override
  BouncingScrollPhysics applyTo(ScrollPhysics ancestor) {
    return BouncingScrollPhysics(parent: buildParent(ancestor));
  }

  double frictionFactor(double overscrollFraction) =>
      0.52 * math.pow(1 - overscrollFraction, 2);

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    assert(offset != 0.0);
    assert(position.minScrollExtent <= position.maxScrollExtent);

    if (!position.outOfRange) return offset;

    final double overscrollPastStart =
        math.max(position.minScrollExtent - position.pixels, 0.0);
    final double overscrollPastEnd =
        math.max(position.pixels - position.maxScrollExtent, 0.0);
    final double overscrollPast =
        math.max(overscrollPastStart, overscrollPastEnd);
    final bool easing = (overscrollPastStart > 0.0 && offset < 0.0) ||
        (overscrollPastEnd > 0.0 && offset > 0.0);

    final double friction = easing
        ? frictionFactor(
            (overscrollPast - offset.abs()) / position.viewportDimension)
        : frictionFactor(overscrollPast / position.viewportDimension);
    final double direction = offset.sign;

    return direction * _applyFriction(overscrollPast, offset.abs(), friction);
  }

  static double _applyFriction(
      double extentOutside, double absDelta, double gamma) {
    assert(absDelta > 0);
    double total = 0.0;
    if (extentOutside > 0) {
      final double deltaToLimit = extentOutside / gamma;
      if (absDelta < deltaToLimit) return absDelta * gamma;
      total += extentOutside;
      absDelta -= deltaToLimit;
    }
    return total + absDelta;
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) => 0.0;

  @override
  Simulation createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    final Tolerance tolerance = this.tolerance;
    if (velocity.abs() >= tolerance.velocity || position.outOfRange) {
      return BouncingScrollSimulation(
        spring: spring,
        position: position.pixels,
        velocity: velocity * 0.91,
        leadingExtent: position.minScrollExtent,
        trailingExtent: position.maxScrollExtent,
        tolerance: tolerance,
      );
    }
    return null;
  }

  @override
  double get minFlingVelocity => kMinFlingVelocity * 2.0;

  @override
  double carriedMomentum(double existingVelocity) {
    return existingVelocity.sign *
        math.min(0.000816 * math.pow(existingVelocity.abs(), 1.967).toDouble(),
            40000.0);
  }

  @override
  double get dragStartDistanceMotionThreshold => 3.5;
}

class ClampingScrollPhysics extends ScrollPhysics {
  const ClampingScrollPhysics({ScrollPhysics parent}) : super(parent: parent);

  @override
  ClampingScrollPhysics applyTo(ScrollPhysics ancestor) {
    return ClampingScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    assert(() {
      if (value == position.pixels) {
        throw FlutterError(
            '$runtimeType.applyBoundaryConditions() was called redundantly.\n'
            'The proposed new position, $value, is exactly equal to the current position of the '
            'given ${position.runtimeType}, ${position.pixels}.\n'
            'The applyBoundaryConditions method should only be called when the value is '
            'going to actually change the pixels, otherwise it is redundant.\n'
            'The physics object in question was:\n'
            '  $this\n'
            'The position object in question was:\n'
            '  $position\n');
      }
      return true;
    }());
    if (value < position.pixels && position.pixels <= position.minScrollExtent)
      return value - position.pixels;
    if (position.maxScrollExtent <= position.pixels && position.pixels < value)
      return value - position.pixels;
    if (value < position.minScrollExtent &&
        position.minScrollExtent < position.pixels)
      return value - position.minScrollExtent;
    if (position.pixels < position.maxScrollExtent &&
        position.maxScrollExtent < value)
      return value - position.maxScrollExtent;
    return 0.0;
  }

  @override
  Simulation createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    final Tolerance tolerance = this.tolerance;
    if (position.outOfRange) {
      double end;
      if (position.pixels > position.maxScrollExtent)
        end = position.maxScrollExtent;
      if (position.pixels < position.minScrollExtent)
        end = position.minScrollExtent;
      assert(end != null);
      return ScrollSpringSimulation(
          spring, position.pixels, end, math.min(0.0, velocity),
          tolerance: tolerance);
    }
    if (velocity.abs() < tolerance.velocity) return null;
    if (velocity > 0.0 && position.pixels >= position.maxScrollExtent)
      return null;
    if (velocity < 0.0 && position.pixels <= position.minScrollExtent)
      return null;
    return ClampingScrollSimulation(
      position: position.pixels,
      velocity: velocity,
      tolerance: tolerance,
    );
  }
}

class AlwaysScrollableScrollPhysics extends ScrollPhysics {
  const AlwaysScrollableScrollPhysics({ScrollPhysics parent})
      : super(parent: parent);

  @override
  AlwaysScrollableScrollPhysics applyTo(ScrollPhysics ancestor) {
    return AlwaysScrollableScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) => true;
}

class NeverScrollableScrollPhysics extends ScrollPhysics {
  const NeverScrollableScrollPhysics({ScrollPhysics parent})
      : super(parent: parent);

  @override
  NeverScrollableScrollPhysics applyTo(ScrollPhysics ancestor) {
    return NeverScrollableScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) => false;

  @override
  bool get allowImplicitScrolling => false;
}

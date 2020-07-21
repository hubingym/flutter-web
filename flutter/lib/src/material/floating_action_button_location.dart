import 'dart:math' as math;

import 'package:flutter_web/widgets.dart';

import 'scaffold.dart';

const double kFloatingActionButtonMargin = 16.0;

const Duration kFloatingActionButtonSegue = Duration(milliseconds: 200);

const double kFloatingActionButtonTurnInterval = 0.125;

abstract class FloatingActionButtonLocation {
  const FloatingActionButtonLocation();

  static const FloatingActionButtonLocation endFloat =
      _EndFloatFloatingActionButtonLocation();

  static const FloatingActionButtonLocation centerFloat =
      _CenterFloatFloatingActionButtonLocation();

  static const FloatingActionButtonLocation endDocked =
      _EndDockedFloatingActionButtonLocation();

  static const FloatingActionButtonLocation centerDocked =
      _CenterDockedFloatingActionButtonLocation();

  static const FloatingActionButtonLocation startTop =
      _StartTopFloatingActionButtonLocation();

  static const FloatingActionButtonLocation miniStartTop =
      _MiniStartTopFloatingActionButtonLocation();

  static const FloatingActionButtonLocation endTop =
      _EndTopFloatingActionButtonLocation();

  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry);

  @override
  String toString() => '$runtimeType';
}

double _leftOffset(ScaffoldPrelayoutGeometry scaffoldGeometry,
    {double offset = 0.0}) {
  return kFloatingActionButtonMargin + scaffoldGeometry.minInsets.left - offset;
}

double _rightOffset(ScaffoldPrelayoutGeometry scaffoldGeometry,
    {double offset = 0.0}) {
  return scaffoldGeometry.scaffoldSize.width -
      kFloatingActionButtonMargin -
      scaffoldGeometry.minInsets.right -
      scaffoldGeometry.floatingActionButtonSize.width +
      offset;
}

double _endOffset(ScaffoldPrelayoutGeometry scaffoldGeometry,
    {double offset = 0.0}) {
  assert(scaffoldGeometry.textDirection != null);
  switch (scaffoldGeometry.textDirection) {
    case TextDirection.rtl:
      return _leftOffset(scaffoldGeometry, offset: offset);
    case TextDirection.ltr:
      return _rightOffset(scaffoldGeometry, offset: offset);
  }
  return null;
}

double _startOffset(ScaffoldPrelayoutGeometry scaffoldGeometry,
    {double offset = 0.0}) {
  assert(scaffoldGeometry.textDirection != null);
  switch (scaffoldGeometry.textDirection) {
    case TextDirection.rtl:
      return _rightOffset(scaffoldGeometry, offset: offset);
    case TextDirection.ltr:
      return _leftOffset(scaffoldGeometry, offset: offset);
  }
  return null;
}

class _CenterFloatFloatingActionButtonLocation
    extends FloatingActionButtonLocation {
  const _CenterFloatFloatingActionButtonLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final double fabX = (scaffoldGeometry.scaffoldSize.width -
            scaffoldGeometry.floatingActionButtonSize.width) /
        2.0;

    final double contentBottom = scaffoldGeometry.contentBottom;
    final double bottomSheetHeight = scaffoldGeometry.bottomSheetSize.height;
    final double fabHeight = scaffoldGeometry.floatingActionButtonSize.height;
    final double snackBarHeight = scaffoldGeometry.snackBarSize.height;
    double fabY = contentBottom - fabHeight - kFloatingActionButtonMargin;
    if (snackBarHeight > 0.0)
      fabY = math.min(
          fabY,
          contentBottom -
              snackBarHeight -
              fabHeight -
              kFloatingActionButtonMargin);
    if (bottomSheetHeight > 0.0)
      fabY =
          math.min(fabY, contentBottom - bottomSheetHeight - fabHeight / 2.0);

    return Offset(fabX, fabY);
  }

  @override
  String toString() => 'FloatingActionButtonLocation.centerFloat';
}

class _EndFloatFloatingActionButtonLocation
    extends FloatingActionButtonLocation {
  const _EndFloatFloatingActionButtonLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final double fabX = _endOffset(scaffoldGeometry);

    final double contentBottom = scaffoldGeometry.contentBottom;
    final double bottomSheetHeight = scaffoldGeometry.bottomSheetSize.height;
    final double fabHeight = scaffoldGeometry.floatingActionButtonSize.height;
    final double snackBarHeight = scaffoldGeometry.snackBarSize.height;

    double fabY = contentBottom - fabHeight - kFloatingActionButtonMargin;
    if (snackBarHeight > 0.0)
      fabY = math.min(
          fabY,
          contentBottom -
              snackBarHeight -
              fabHeight -
              kFloatingActionButtonMargin);
    if (bottomSheetHeight > 0.0)
      fabY =
          math.min(fabY, contentBottom - bottomSheetHeight - fabHeight / 2.0);

    return Offset(fabX, fabY);
  }

  @override
  String toString() => 'FloatingActionButtonLocation.endFloat';
}

abstract class _DockedFloatingActionButtonLocation
    extends FloatingActionButtonLocation {
  const _DockedFloatingActionButtonLocation();

  @protected
  double getDockedY(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final double contentBottom = scaffoldGeometry.contentBottom;
    final double bottomSheetHeight = scaffoldGeometry.bottomSheetSize.height;
    final double fabHeight = scaffoldGeometry.floatingActionButtonSize.height;
    final double snackBarHeight = scaffoldGeometry.snackBarSize.height;

    double fabY = contentBottom - fabHeight / 2.0;

    if (snackBarHeight > 0.0)
      fabY = math.min(
          fabY,
          contentBottom -
              snackBarHeight -
              fabHeight -
              kFloatingActionButtonMargin);

    if (bottomSheetHeight > 0.0)
      fabY =
          math.min(fabY, contentBottom - bottomSheetHeight - fabHeight / 2.0);

    final double maxFabY = scaffoldGeometry.scaffoldSize.height - fabHeight;
    return math.min(maxFabY, fabY);
  }
}

class _EndDockedFloatingActionButtonLocation
    extends _DockedFloatingActionButtonLocation {
  const _EndDockedFloatingActionButtonLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final double fabX = _endOffset(scaffoldGeometry);
    return Offset(fabX, getDockedY(scaffoldGeometry));
  }

  @override
  String toString() => 'FloatingActionButtonLocation.endDocked';
}

class _CenterDockedFloatingActionButtonLocation
    extends _DockedFloatingActionButtonLocation {
  const _CenterDockedFloatingActionButtonLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final double fabX = (scaffoldGeometry.scaffoldSize.width -
            scaffoldGeometry.floatingActionButtonSize.width) /
        2.0;
    return Offset(fabX, getDockedY(scaffoldGeometry));
  }

  @override
  String toString() => 'FloatingActionButtonLocation.centerDocked';
}

double _straddleAppBar(ScaffoldPrelayoutGeometry scaffoldGeometry) {
  final double fabHalfHeight =
      scaffoldGeometry.floatingActionButtonSize.height / 2.0;
  return scaffoldGeometry.contentTop - fabHalfHeight;
}

class _StartTopFloatingActionButtonLocation
    extends FloatingActionButtonLocation {
  const _StartTopFloatingActionButtonLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    return Offset(
        _startOffset(scaffoldGeometry), _straddleAppBar(scaffoldGeometry));
  }

  @override
  String toString() => 'FloatingActionButtonLocation.startTop';
}

class _MiniStartTopFloatingActionButtonLocation
    extends FloatingActionButtonLocation {
  const _MiniStartTopFloatingActionButtonLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    return Offset(_startOffset(scaffoldGeometry, offset: 4.0),
        _straddleAppBar(scaffoldGeometry));
  }

  @override
  String toString() => 'FloatingActionButtonLocation.miniStartTop';
}

class _EndTopFloatingActionButtonLocation extends FloatingActionButtonLocation {
  const _EndTopFloatingActionButtonLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    return Offset(
        _endOffset(scaffoldGeometry), _straddleAppBar(scaffoldGeometry));
  }

  @override
  String toString() => 'FloatingActionButtonLocation.endTop';
}

abstract class FloatingActionButtonAnimator {
  const FloatingActionButtonAnimator();

  static const FloatingActionButtonAnimator scaling =
      _ScalingFabMotionAnimator();

  Offset getOffset(
      {@required Offset begin,
      @required Offset end,
      @required double progress});

  Animation<double> getScaleAnimation({@required Animation<double> parent});

  Animation<double> getRotationAnimation({@required Animation<double> parent});

  double getAnimationRestart(double previousValue) => 0.0;

  @override
  String toString() => '$runtimeType';
}

class _ScalingFabMotionAnimator extends FloatingActionButtonAnimator {
  const _ScalingFabMotionAnimator();

  @override
  Offset getOffset({Offset begin, Offset end, double progress}) {
    if (progress < 0.5) {
      return begin;
    } else {
      return end;
    }
  }

  @override
  Animation<double> getScaleAnimation({Animation<double> parent}) {
    const Curve curve = Interval(0.5, 1.0, curve: Curves.ease);
    return _AnimationSwap<double>(
      ReverseAnimation(parent.drive(CurveTween(curve: curve.flipped))),
      parent.drive(CurveTween(curve: curve)),
      parent,
      0.5,
    );
  }

  static final Animatable<double> _rotationTween = Tween<double>(
    begin: 1.0 - kFloatingActionButtonTurnInterval * 2.0,
    end: 1.0,
  );

  static final Animatable<double> _thresholdCenterTween =
      CurveTween(curve: const Threshold(0.5));

  @override
  Animation<double> getRotationAnimation({Animation<double> parent}) {
    return _AnimationSwap<double>(
      parent.drive(_rotationTween),
      ReverseAnimation(parent.drive(_thresholdCenterTween)),
      parent,
      0.5,
    );
  }

  @override
  double getAnimationRestart(double previousValue) =>
      math.min(1.0 - previousValue, previousValue);
}

class _AnimationSwap<T> extends CompoundAnimation<T> {
  _AnimationSwap(
      Animation<T> first, Animation<T> next, this.parent, this.swapThreshold)
      : super(first: first, next: next);

  final Animation<double> parent;
  final double swapThreshold;

  @override
  T get value => parent.value < swapThreshold ? first.value : next.value;
}

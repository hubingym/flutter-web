import 'dart:math' as math;

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/rendering.dart';

import '../util.dart';

abstract class ScrollMetrics {
  ScrollMetrics copyWith({
    double minScrollExtent,
    double maxScrollExtent,
    double pixels,
    double viewportDimension,
    AxisDirection axisDirection,
  }) {
    return new FixedScrollMetrics(
      minScrollExtent: minScrollExtent ?? this.minScrollExtent,
      maxScrollExtent: maxScrollExtent ?? this.maxScrollExtent,
      pixels: pixels ?? this.pixels,
      viewportDimension: viewportDimension ?? this.viewportDimension,
      axisDirection: axisDirection ?? this.axisDirection,
    );
  }

  double get minScrollExtent;

  double get maxScrollExtent;

  double get pixels;

  double get viewportDimension;

  AxisDirection get axisDirection;

  Axis get axis => axisDirectionToAxis(axisDirection);

  bool get outOfRange => pixels < minScrollExtent || pixels > maxScrollExtent;

  bool get atEdge => pixels == minScrollExtent || pixels == maxScrollExtent;

  double get extentBefore => math.max(pixels - minScrollExtent, 0.0);

  double get extentInside {
    return math.min(pixels, maxScrollExtent) -
        math.max(pixels, minScrollExtent) +
        math.min(viewportDimension, maxScrollExtent - minScrollExtent);
  }

  double get extentAfter => math.max(maxScrollExtent - pixels, 0.0);
}

class FixedScrollMetrics extends ScrollMetrics {
  FixedScrollMetrics({
    @required this.minScrollExtent,
    @required this.maxScrollExtent,
    @required this.pixels,
    @required this.viewportDimension,
    @required this.axisDirection,
  });

  @override
  final double minScrollExtent;

  @override
  final double maxScrollExtent;

  @override
  final double pixels;

  @override
  final double viewportDimension;

  @override
  final AxisDirection axisDirection;

  @override
  String toString() {
    if (assertionsEnabled) {
      return '$runtimeType(${extentBefore.toStringAsFixed(1)}..'
          '[${extentInside.toStringAsFixed(1)}]..'
          '${extentAfter.toStringAsFixed(1)})';
    } else {
      return super.toString();
    }
  }
}

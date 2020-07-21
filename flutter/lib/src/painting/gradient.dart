import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter_web/ui.dart' as ui;
import 'package:meta/meta.dart';

import 'alignment.dart';
import 'basic_types.dart';

class _ColorsAndStops {
  _ColorsAndStops(this.colors, this.stops);
  final List<Color> colors;
  final List<double> stops;
}

Color _sample(List<Color> colors, List<double> stops, double t) {
  assert(colors != null);
  assert(colors.isNotEmpty);
  assert(stops != null);
  assert(stops.isNotEmpty);
  assert(t != null);
  if (t <= stops.first) return colors.first;
  if (t >= stops.last) return colors.last;
  final int index = stops.lastIndexWhere((double s) => s <= t);
  assert(index != -1);
  return Color.lerp(
    colors[index],
    colors[index + 1],
    (t - stops[index]) / (stops[index + 1] - stops[index]),
  );
}

_ColorsAndStops _interpolateColorsAndStops(
  List<Color> aColors,
  List<double> aStops,
  List<Color> bColors,
  List<double> bStops,
  double t,
) {
  assert(aColors.length >= 2);
  assert(bColors.length >= 2);
  assert(aStops.length == aColors.length);
  assert(bStops.length == bColors.length);
  final SplayTreeSet<double> stops = SplayTreeSet<double>()
    ..addAll(aStops)
    ..addAll(bStops);
  final List<double> interpolatedStops = stops.toList(growable: false);
  final List<Color> interpolatedColors = interpolatedStops
      .map<Color>((double stop) => Color.lerp(
          _sample(aColors, aStops, stop), _sample(bColors, bStops, stop), t))
      .toList(growable: false);
  return _ColorsAndStops(interpolatedColors, interpolatedStops);
}

@immutable
abstract class Gradient {
  const Gradient({
    @required this.colors,
    this.stops,
  }) : assert(colors != null);

  final List<Color> colors;

  final List<double> stops;

  List<double> _impliedStops() {
    if (stops != null) return stops;
    assert(colors.length >= 2, 'colors list must have at least two colors');
    final double separation = 1.0 / (colors.length - 1);
    return List<double>.generate(
      colors.length,
      (int index) => index * separation,
      growable: false,
    );
  }

  Shader createShader(Rect rect, {TextDirection textDirection});

  Gradient scale(double factor);

  @protected
  Gradient lerpFrom(Gradient a, double t) {
    if (a == null) return scale(t);
    return null;
  }

  @protected
  Gradient lerpTo(Gradient b, double t) {
    if (b == null) return scale(1.0 - t);
    return null;
  }

  static Gradient lerp(Gradient a, Gradient b, double t) {
    assert(t != null);
    Gradient result;
    if (b != null) result = b.lerpFrom(a, t);
    if (result == null && a != null) result = a.lerpTo(b, t);
    if (result != null) return result;
    if (a == null && b == null) return null;
    assert(a != null && b != null);
    return t < 0.5 ? a.scale(1.0 - (t * 2.0)) : b.scale((t - 0.5) * 2.0);
  }
}

class LinearGradient extends Gradient {
  const LinearGradient({
    this.begin = Alignment.centerLeft,
    this.end = Alignment.centerRight,
    @required List<Color> colors,
    List<double> stops,
    this.tileMode = TileMode.clamp,
  })  : assert(begin != null),
        assert(end != null),
        assert(tileMode != null),
        super(colors: colors, stops: stops);

  final AlignmentGeometry begin;

  final AlignmentGeometry end;

  final TileMode tileMode;

  @override
  Shader createShader(Rect rect, {TextDirection textDirection}) {
    return ui.Gradient.linear(
      begin.resolve(textDirection).withinRect(rect),
      end.resolve(textDirection).withinRect(rect),
      colors,
      _impliedStops(),
      tileMode,
    );
  }

  @override
  LinearGradient scale(double factor) {
    return LinearGradient(
      begin: begin,
      end: end,
      colors: colors
          .map<Color>((Color color) => Color.lerp(null, color, factor))
          .toList(),
      stops: stops,
      tileMode: tileMode,
    );
  }

  @override
  Gradient lerpFrom(Gradient a, double t) {
    if (a == null || (a is LinearGradient))
      return LinearGradient.lerp(a, this, t);
    return super.lerpFrom(a, t);
  }

  @override
  Gradient lerpTo(Gradient b, double t) {
    if (b == null || (b is LinearGradient))
      return LinearGradient.lerp(this, b, t);
    return super.lerpTo(b, t);
  }

  static LinearGradient lerp(LinearGradient a, LinearGradient b, double t) {
    assert(t != null);
    if (a == null && b == null) return null;
    if (a == null) return b.scale(t);
    if (b == null) return a.scale(1.0 - t);
    final _ColorsAndStops interpolated = _interpolateColorsAndStops(
      a.colors,
      a._impliedStops(),
      b.colors,
      b._impliedStops(),
      t,
    );
    return LinearGradient(
      begin: AlignmentGeometry.lerp(a.begin, b.begin, t),
      end: AlignmentGeometry.lerp(a.end, b.end, t),
      colors: interpolated.colors,
      stops: interpolated.stops,
      tileMode: t < 0.5 ? a.tileMode : b.tileMode,
    );
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final LinearGradient typedOther = other;
    if (begin != typedOther.begin ||
        end != typedOther.end ||
        tileMode != typedOther.tileMode ||
        colors?.length != typedOther.colors?.length ||
        stops?.length != typedOther.stops?.length) return false;
    if (colors != null) {
      assert(typedOther.colors != null);
      assert(colors.length == typedOther.colors.length);
      for (int i = 0; i < colors.length; i += 1) {
        if (colors[i] != typedOther.colors[i]) return false;
      }
    }
    if (stops != null) {
      assert(typedOther.stops != null);
      assert(stops.length == typedOther.stops.length);
      for (int i = 0; i < stops.length; i += 1) {
        if (stops[i] != typedOther.stops[i]) return false;
      }
    }
    return true;
  }

  @override
  int get hashCode =>
      hashValues(begin, end, tileMode, hashList(colors), hashList(stops));

  @override
  String toString() {
    return '$runtimeType($begin, $end, $colors, $stops, $tileMode)';
  }
}

class RadialGradient extends Gradient {
  const RadialGradient({
    this.center = Alignment.center,
    this.radius = 0.5,
    @required List<Color> colors,
    List<double> stops,
    this.tileMode = TileMode.clamp,
    this.focal,
    this.focalRadius = 0.0,
  })  : assert(center != null),
        assert(radius != null),
        assert(tileMode != null),
        assert(focalRadius != null),
        super(colors: colors, stops: stops);

  final AlignmentGeometry center;

  final double radius;

  final TileMode tileMode;

  final AlignmentGeometry focal;

  final double focalRadius;

  @override
  Shader createShader(Rect rect, {TextDirection textDirection}) {
    return ui.Gradient.radial(
      center.resolve(textDirection).withinRect(rect),
      radius * rect.shortestSide,
      colors,
      _impliedStops(),
      tileMode,
      null,
      focal == null ? null : focal.resolve(textDirection).withinRect(rect),
      focalRadius * rect.shortestSide,
    );
  }

  @override
  RadialGradient scale(double factor) {
    return RadialGradient(
      center: center,
      radius: radius,
      colors: colors
          .map<Color>((Color color) => Color.lerp(null, color, factor))
          .toList(),
      stops: stops,
      tileMode: tileMode,
      focal: focal,
      focalRadius: focalRadius,
    );
  }

  @override
  Gradient lerpFrom(Gradient a, double t) {
    if (a == null || (a is RadialGradient))
      return RadialGradient.lerp(a, this, t);
    return super.lerpFrom(a, t);
  }

  @override
  Gradient lerpTo(Gradient b, double t) {
    if (b == null || (b is RadialGradient))
      return RadialGradient.lerp(this, b, t);
    return super.lerpTo(b, t);
  }

  static RadialGradient lerp(RadialGradient a, RadialGradient b, double t) {
    assert(t != null);
    if (a == null && b == null) return null;
    if (a == null) return b.scale(t);
    if (b == null) return a.scale(1.0 - t);
    final _ColorsAndStops interpolated = _interpolateColorsAndStops(
      a.colors,
      a._impliedStops(),
      b.colors,
      b._impliedStops(),
      t,
    );
    return RadialGradient(
      center: AlignmentGeometry.lerp(a.center, b.center, t),
      radius: math.max(0.0, ui.lerpDouble(a.radius, b.radius, t)),
      colors: interpolated.colors,
      stops: interpolated.stops,
      tileMode: t < 0.5 ? a.tileMode : b.tileMode,
      focal: AlignmentGeometry.lerp(a.focal, b.focal, t),
      focalRadius:
          math.max(0.0, ui.lerpDouble(a.focalRadius, b.focalRadius, t)),
    );
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final RadialGradient typedOther = other;
    if (center != typedOther.center ||
        radius != typedOther.radius ||
        tileMode != typedOther.tileMode ||
        colors?.length != typedOther.colors?.length ||
        stops?.length != typedOther.stops?.length ||
        focal != typedOther.focal ||
        focalRadius != typedOther.focalRadius) return false;
    if (colors != null) {
      assert(typedOther.colors != null);
      assert(colors.length == typedOther.colors.length);
      for (int i = 0; i < colors.length; i += 1) {
        if (colors[i] != typedOther.colors[i]) return false;
      }
    }
    if (stops != null) {
      assert(typedOther.stops != null);
      assert(stops.length == typedOther.stops.length);
      for (int i = 0; i < stops.length; i += 1) {
        if (stops[i] != typedOther.stops[i]) return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => hashValues(center, radius, tileMode, hashList(colors),
      hashList(stops), focal, focalRadius);

  @override
  String toString() {
    return '$runtimeType($center, $radius, $colors, $stops, $tileMode, $focal, $focalRadius)';
  }
}

class SweepGradient extends Gradient {
  const SweepGradient({
    this.center = Alignment.center,
    this.startAngle = 0.0,
    this.endAngle = math.pi * 2,
    @required List<Color> colors,
    List<double> stops,
    this.tileMode = TileMode.clamp,
  })  : assert(center != null),
        assert(startAngle != null),
        assert(endAngle != null),
        assert(tileMode != null),
        super(colors: colors, stops: stops);

  final AlignmentGeometry center;

  final double startAngle;

  final double endAngle;

  final TileMode tileMode;

  @override
  Shader createShader(Rect rect, {TextDirection textDirection}) {
    return ui.Gradient.sweep(
      center.resolve(textDirection).withinRect(rect),
      colors,
      _impliedStops(),
      tileMode,
      startAngle,
      endAngle,
    );
  }

  @override
  SweepGradient scale(double factor) {
    return SweepGradient(
      center: center,
      startAngle: startAngle,
      endAngle: endAngle,
      colors: colors
          .map<Color>((Color color) => Color.lerp(null, color, factor))
          .toList(),
      stops: stops,
      tileMode: tileMode,
    );
  }

  @override
  Gradient lerpFrom(Gradient a, double t) {
    if (a == null || (a is SweepGradient))
      return SweepGradient.lerp(a, this, t);
    return super.lerpFrom(a, t);
  }

  @override
  Gradient lerpTo(Gradient b, double t) {
    if (b == null || (b is SweepGradient))
      return SweepGradient.lerp(this, b, t);
    return super.lerpTo(b, t);
  }

  static SweepGradient lerp(SweepGradient a, SweepGradient b, double t) {
    assert(t != null);
    if (a == null && b == null) return null;
    if (a == null) return b.scale(t);
    if (b == null) return a.scale(1.0 - t);
    final _ColorsAndStops interpolated = _interpolateColorsAndStops(
      a.colors,
      a._impliedStops(),
      b.colors,
      b._impliedStops(),
      t,
    );
    return SweepGradient(
      center: AlignmentGeometry.lerp(a.center, b.center, t),
      startAngle: math.max(0.0, ui.lerpDouble(a.startAngle, b.startAngle, t)),
      endAngle: math.max(0.0, ui.lerpDouble(a.endAngle, b.endAngle, t)),
      colors: interpolated.colors,
      stops: interpolated.stops,
      tileMode: t < 0.5 ? a.tileMode : b.tileMode,
    );
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final SweepGradient typedOther = other;
    if (center != typedOther.center ||
        startAngle != typedOther.startAngle ||
        endAngle != typedOther.endAngle ||
        tileMode != typedOther.tileMode ||
        colors?.length != typedOther.colors?.length ||
        stops?.length != typedOther.stops?.length) return false;
    if (colors != null) {
      assert(typedOther.colors != null);
      assert(colors.length == typedOther.colors.length);
      for (int i = 0; i < colors.length; i += 1) {
        if (colors[i] != typedOther.colors[i]) return false;
      }
    }
    if (stops != null) {
      assert(typedOther.stops != null);
      assert(stops.length == typedOther.stops.length);
      for (int i = 0; i < stops.length; i += 1) {
        if (stops[i] != typedOther.stops[i]) return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => hashValues(center, startAngle, endAngle, tileMode,
      hashList(colors), hashList(stops));

  @override
  String toString() {
    return '$runtimeType($center, $startAngle, $endAngle, $colors, $stops, $tileMode)';
  }
}

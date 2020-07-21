import 'dart:math' as math;
import 'package:flutter_web/ui.dart' show Color, lerpDouble, hashValues;

import 'package:flutter_web/foundation.dart';

double _getHue(
    double red, double green, double blue, double max, double delta) {
  double hue;
  if (max == 0.0) {
    hue = 0.0;
  } else if (max == red) {
    hue = 60.0 * (((green - blue) / delta) % 6);
  } else if (max == green) {
    hue = 60.0 * (((blue - red) / delta) + 2);
  } else if (max == blue) {
    hue = 60.0 * (((red - green) / delta) + 4);
  }

  hue = hue.isNaN ? 0.0 : hue;
  return hue;
}

Color _colorFromHue(
  double alpha,
  double hue,
  double chroma,
  double secondary,
  double match,
) {
  double red;
  double green;
  double blue;
  if (hue < 60.0) {
    red = chroma;
    green = secondary;
    blue = 0.0;
  } else if (hue < 120.0) {
    red = secondary;
    green = chroma;
    blue = 0.0;
  } else if (hue < 180.0) {
    red = 0.0;
    green = chroma;
    blue = secondary;
  } else if (hue < 240.0) {
    red = 0.0;
    green = secondary;
    blue = chroma;
  } else if (hue < 300.0) {
    red = secondary;
    green = 0.0;
    blue = chroma;
  } else {
    red = chroma;
    green = 0.0;
    blue = secondary;
  }
  return Color.fromARGB((alpha * 0xFF).round(), ((red + match) * 0xFF).round(),
      ((green + match) * 0xFF).round(), ((blue + match) * 0xFF).round());
}

@immutable
class HSVColor {
  const HSVColor.fromAHSV(this.alpha, this.hue, this.saturation, this.value)
      : assert(alpha != null),
        assert(hue != null),
        assert(saturation != null),
        assert(value != null),
        assert(alpha >= 0.0),
        assert(alpha <= 1.0),
        assert(hue >= 0.0),
        assert(hue <= 360.0),
        assert(saturation >= 0.0),
        assert(saturation <= 1.0),
        assert(value >= 0.0),
        assert(value <= 1.0);

  factory HSVColor.fromColor(Color color) {
    final double red = color.red / 0xFF;
    final double green = color.green / 0xFF;
    final double blue = color.blue / 0xFF;

    final double max = math.max(red, math.max(green, blue));
    final double min = math.min(red, math.min(green, blue));
    final double delta = max - min;

    final double alpha = color.alpha / 0xFF;
    final double hue = _getHue(red, green, blue, max, delta);
    final double saturation = max == 0.0 ? 0.0 : delta / max;

    return HSVColor.fromAHSV(alpha, hue, saturation, max);
  }

  final double alpha;

  final double hue;

  final double saturation;

  final double value;

  HSVColor withAlpha(double alpha) {
    return HSVColor.fromAHSV(alpha, hue, saturation, value);
  }

  HSVColor withHue(double hue) {
    return HSVColor.fromAHSV(alpha, hue, saturation, value);
  }

  HSVColor withSaturation(double saturation) {
    return HSVColor.fromAHSV(alpha, hue, saturation, value);
  }

  HSVColor withValue(double value) {
    return HSVColor.fromAHSV(alpha, hue, saturation, value);
  }

  Color toColor() {
    final double chroma = saturation * value;
    final double secondary =
        chroma * (1.0 - (((hue / 60.0) % 2.0) - 1.0).abs());
    final double match = value - chroma;

    return _colorFromHue(alpha, hue, chroma, secondary, match);
  }

  HSVColor _scaleAlpha(double factor) {
    return withAlpha(alpha * factor);
  }

  static HSVColor lerp(HSVColor a, HSVColor b, double t) {
    assert(t != null);
    if (a == null && b == null) return null;
    if (a == null) return b._scaleAlpha(t);
    if (b == null) return a._scaleAlpha(1.0 - t);
    return HSVColor.fromAHSV(
      lerpDouble(a.alpha, b.alpha, t).clamp(0.0, 1.0),
      lerpDouble(a.hue, b.hue, t) % 360.0,
      lerpDouble(a.saturation, b.saturation, t).clamp(0.0, 1.0),
      lerpDouble(a.value, b.value, t).clamp(0.0, 1.0),
    );
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (other is! HSVColor) return false;
    final HSVColor typedOther = other;
    return typedOther.alpha == alpha &&
        typedOther.hue == hue &&
        typedOther.saturation == saturation &&
        typedOther.value == value;
  }

  @override
  int get hashCode => hashValues(alpha, hue, saturation, value);

  @override
  String toString() => '$runtimeType($alpha, $hue, $saturation, $value)';
}

@immutable
class HSLColor {
  const HSLColor.fromAHSL(this.alpha, this.hue, this.saturation, this.lightness)
      : assert(alpha != null),
        assert(hue != null),
        assert(saturation != null),
        assert(lightness != null),
        assert(alpha >= 0.0),
        assert(alpha <= 1.0),
        assert(hue >= 0.0),
        assert(hue <= 360.0),
        assert(saturation >= 0.0),
        assert(saturation <= 1.0),
        assert(lightness >= 0.0),
        assert(lightness <= 1.0);

  factory HSLColor.fromColor(Color color) {
    final double red = color.red / 0xFF;
    final double green = color.green / 0xFF;
    final double blue = color.blue / 0xFF;

    final double max = math.max(red, math.max(green, blue));
    final double min = math.min(red, math.min(green, blue));
    final double delta = max - min;

    final double alpha = color.alpha / 0xFF;
    final double hue = _getHue(red, green, blue, max, delta);
    final double lightness = (max + min) / 2.0;

    final double saturation = lightness == 1.0
        ? 0.0
        : (delta / (1.0 - (2.0 * lightness - 1.0).abs())).clamp(0.0, 1.0);
    return HSLColor.fromAHSL(alpha, hue, saturation, lightness);
  }

  final double alpha;

  final double hue;

  final double saturation;

  final double lightness;

  HSLColor withAlpha(double alpha) {
    return HSLColor.fromAHSL(alpha, hue, saturation, lightness);
  }

  HSLColor withHue(double hue) {
    return HSLColor.fromAHSL(alpha, hue, saturation, lightness);
  }

  HSLColor withSaturation(double saturation) {
    return HSLColor.fromAHSL(alpha, hue, saturation, lightness);
  }

  HSLColor withLightness(double lightness) {
    return HSLColor.fromAHSL(alpha, hue, saturation, lightness);
  }

  Color toColor() {
    final double chroma = (1.0 - (2.0 * lightness - 1.0).abs()) * saturation;
    final double secondary =
        chroma * (1.0 - (((hue / 60.0) % 2.0) - 1.0).abs());
    final double match = lightness - chroma / 2.0;

    return _colorFromHue(alpha, hue, chroma, secondary, match);
  }

  HSLColor _scaleAlpha(double factor) {
    return withAlpha(alpha * factor);
  }

  static HSLColor lerp(HSLColor a, HSLColor b, double t) {
    assert(t != null);
    if (a == null && b == null) return null;
    if (a == null) return b._scaleAlpha(t);
    if (b == null) return a._scaleAlpha(1.0 - t);
    return HSLColor.fromAHSL(
      lerpDouble(a.alpha, b.alpha, t).clamp(0.0, 1.0),
      lerpDouble(a.hue, b.hue, t) % 360.0,
      lerpDouble(a.saturation, b.saturation, t).clamp(0.0, 1.0),
      lerpDouble(a.lightness, b.lightness, t).clamp(0.0, 1.0),
    );
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (other is! HSLColor) return false;
    final HSLColor typedOther = other;
    return typedOther.alpha == alpha &&
        typedOther.hue == hue &&
        typedOther.saturation == saturation &&
        typedOther.lightness == lightness;
  }

  @override
  int get hashCode => hashValues(alpha, hue, saturation, lightness);

  @override
  String toString() => '$runtimeType($alpha, $hue, $saturation, $lightness)';
}

class ColorSwatch<T> extends Color {
  const ColorSwatch(int primary, this._swatch) : super(primary);

  @protected
  final Map<T, Color> _swatch;

  Color operator [](T index) => _swatch[index];

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    final ColorSwatch<T> typedOther = other;
    return super == other && _swatch == typedOther._swatch;
  }

  @override
  int get hashCode => hashValues(runtimeType, value, _swatch);

  @override
  String toString() => '$runtimeType(primary value: ${super.toString()})';
}

class ColorProperty extends DiagnosticsProperty<Color> {
  ColorProperty(
    String name,
    Color value, {
    bool showName = true,
    Object defaultValue = kNoDefaultValue,
    DiagnosticsTreeStyle style = DiagnosticsTreeStyle.singleLine,
    DiagnosticLevel level = DiagnosticLevel.info,
  })  : assert(showName != null),
        assert(style != null),
        assert(level != null),
        super(
          name,
          value,
          defaultValue: defaultValue,
          showName: showName,
          style: style,
          level: level,
        );

  @override
  Map<String, Object> toJsonMap(DiagnosticsSerializationDelegate delegate) {
    final Map<String, Object> json = super.toJsonMap(delegate);
    if (value != null) {
      json['valueProperties'] = <String, Object>{
        'red': value.red,
        'green': value.green,
        'blue': value.blue,
        'alpha': value.alpha,
      };
    }
    return json;
  }
}

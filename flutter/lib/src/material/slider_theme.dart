import 'dart:math' as math;
import 'package:flutter_web/ui.dart' show Path, lerpDouble;

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/rendering.dart';
import 'package:flutter_web/widgets.dart';

import 'colors.dart';
import 'theme.dart';
import 'theme_data.dart';

class SliderTheme extends InheritedWidget {
  const SliderTheme({
    Key key,
    @required this.data,
    @required Widget child,
  })  : assert(child != null),
        assert(data != null),
        super(key: key, child: child);

  final SliderThemeData data;

  static SliderThemeData of(BuildContext context) {
    final SliderTheme inheritedTheme =
        context.inheritFromWidgetOfExactType(SliderTheme);
    return inheritedTheme != null
        ? inheritedTheme.data
        : Theme.of(context).sliderTheme;
  }

  @override
  bool updateShouldNotify(SliderTheme oldWidget) => data != oldWidget.data;
}

enum ShowValueIndicator {
  onlyForDiscrete,

  onlyForContinuous,

  always,

  never,
}

enum Thumb {
  start,

  end,
}

class SliderThemeData extends Diagnosticable {
  const SliderThemeData({
    this.trackHeight,
    this.activeTrackColor,
    this.inactiveTrackColor,
    this.disabledActiveTrackColor,
    this.disabledInactiveTrackColor,
    this.activeTickMarkColor,
    this.inactiveTickMarkColor,
    this.disabledActiveTickMarkColor,
    this.disabledInactiveTickMarkColor,
    this.thumbColor,
    this.overlappingShapeStrokeColor,
    this.disabledThumbColor,
    this.overlayColor,
    this.valueIndicatorColor,
    this.overlayShape,
    this.tickMarkShape,
    this.thumbShape,
    this.trackShape,
    this.valueIndicatorShape,
    this.rangeTickMarkShape,
    this.rangeThumbShape,
    this.rangeTrackShape,
    this.rangeValueIndicatorShape,
    this.showValueIndicator,
    this.valueIndicatorTextStyle,
    this.minThumbSeparation,
    this.thumbSelector,
  });

  factory SliderThemeData.fromPrimaryColors({
    @required Color primaryColor,
    @required Color primaryColorDark,
    @required Color primaryColorLight,
    @required TextStyle valueIndicatorTextStyle,
  }) {
    assert(primaryColor != null);
    assert(primaryColorDark != null);
    assert(primaryColorLight != null);
    assert(valueIndicatorTextStyle != null);

    const int activeTrackAlpha = 0xff;
    const int inactiveTrackAlpha = 0x3d;
    const int disabledActiveTrackAlpha = 0x52;
    const int disabledInactiveTrackAlpha = 0x1f;
    const int activeTickMarkAlpha = 0x8a;
    const int inactiveTickMarkAlpha = 0x8a;
    const int disabledActiveTickMarkAlpha = 0x1f;
    const int disabledInactiveTickMarkAlpha = 0x1f;
    const int thumbAlpha = 0xff;
    const int disabledThumbAlpha = 0x52;
    const int overlayAlpha = 0x1f;
    const int valueIndicatorAlpha = 0xff;

    return SliderThemeData(
      trackHeight: 2.0,
      activeTrackColor: primaryColor.withAlpha(activeTrackAlpha),
      inactiveTrackColor: primaryColor.withAlpha(inactiveTrackAlpha),
      disabledActiveTrackColor:
          primaryColorDark.withAlpha(disabledActiveTrackAlpha),
      disabledInactiveTrackColor:
          primaryColorDark.withAlpha(disabledInactiveTrackAlpha),
      activeTickMarkColor: primaryColorLight.withAlpha(activeTickMarkAlpha),
      inactiveTickMarkColor: primaryColor.withAlpha(inactiveTickMarkAlpha),
      disabledActiveTickMarkColor:
          primaryColorLight.withAlpha(disabledActiveTickMarkAlpha),
      disabledInactiveTickMarkColor:
          primaryColorDark.withAlpha(disabledInactiveTickMarkAlpha),
      thumbColor: primaryColor.withAlpha(thumbAlpha),
      overlappingShapeStrokeColor: Colors.white,
      disabledThumbColor: primaryColorDark.withAlpha(disabledThumbAlpha),
      overlayColor: primaryColor.withAlpha(overlayAlpha),
      valueIndicatorColor: primaryColor.withAlpha(valueIndicatorAlpha),
      overlayShape: const RoundSliderOverlayShape(),
      tickMarkShape: const RoundSliderTickMarkShape(),
      thumbShape: const RoundSliderThumbShape(),
      trackShape: const RoundedRectSliderTrackShape(),
      valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
      rangeTickMarkShape: const RoundRangeSliderTickMarkShape(),
      rangeThumbShape: const RoundRangeSliderThumbShape(),
      rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
      rangeValueIndicatorShape: const PaddleRangeSliderValueIndicatorShape(),
      valueIndicatorTextStyle: valueIndicatorTextStyle,
      showValueIndicator: ShowValueIndicator.onlyForDiscrete,
    );
  }

  final double trackHeight;

  final Color activeTrackColor;

  final Color inactiveTrackColor;

  final Color disabledActiveTrackColor;

  final Color disabledInactiveTrackColor;

  final Color activeTickMarkColor;

  final Color inactiveTickMarkColor;

  final Color disabledActiveTickMarkColor;

  final Color disabledInactiveTickMarkColor;

  final Color thumbColor;

  final Color overlappingShapeStrokeColor;

  final Color disabledThumbColor;

  final Color overlayColor;

  final Color valueIndicatorColor;

  final SliderComponentShape overlayShape;

  final SliderTickMarkShape tickMarkShape;

  final SliderComponentShape thumbShape;

  final SliderTrackShape trackShape;

  final SliderComponentShape valueIndicatorShape;

  final RangeSliderTickMarkShape rangeTickMarkShape;

  final RangeSliderThumbShape rangeThumbShape;

  final RangeSliderTrackShape rangeTrackShape;

  final RangeSliderValueIndicatorShape rangeValueIndicatorShape;

  final ShowValueIndicator showValueIndicator;

  final TextStyle valueIndicatorTextStyle;

  final double minThumbSeparation;

  final RangeThumbSelector thumbSelector;

  SliderThemeData copyWith({
    double trackHeight,
    Color activeTrackColor,
    Color inactiveTrackColor,
    Color disabledActiveTrackColor,
    Color disabledInactiveTrackColor,
    Color activeTickMarkColor,
    Color inactiveTickMarkColor,
    Color disabledActiveTickMarkColor,
    Color disabledInactiveTickMarkColor,
    Color thumbColor,
    Color overlappingShapeStrokeColor,
    Color disabledThumbColor,
    Color overlayColor,
    Color valueIndicatorColor,
    SliderComponentShape overlayShape,
    SliderTickMarkShape tickMarkShape,
    SliderComponentShape thumbShape,
    SliderTrackShape trackShape,
    SliderComponentShape valueIndicatorShape,
    RangeSliderTickMarkShape rangeTickMarkShape,
    RangeSliderThumbShape rangeThumbShape,
    RangeSliderTrackShape rangeTrackShape,
    RangeSliderValueIndicatorShape rangeValueIndicatorShape,
    ShowValueIndicator showValueIndicator,
    TextStyle valueIndicatorTextStyle,
    double minThumbSeparation,
    RangeThumbSelector thumbSelector,
  }) {
    return SliderThemeData(
      trackHeight: trackHeight ?? this.trackHeight,
      activeTrackColor: activeTrackColor ?? this.activeTrackColor,
      inactiveTrackColor: inactiveTrackColor ?? this.inactiveTrackColor,
      disabledActiveTrackColor:
          disabledActiveTrackColor ?? this.disabledActiveTrackColor,
      disabledInactiveTrackColor:
          disabledInactiveTrackColor ?? this.disabledInactiveTrackColor,
      activeTickMarkColor: activeTickMarkColor ?? this.activeTickMarkColor,
      inactiveTickMarkColor:
          inactiveTickMarkColor ?? this.inactiveTickMarkColor,
      disabledActiveTickMarkColor:
          disabledActiveTickMarkColor ?? this.disabledActiveTickMarkColor,
      disabledInactiveTickMarkColor:
          disabledInactiveTickMarkColor ?? this.disabledInactiveTickMarkColor,
      thumbColor: thumbColor ?? this.thumbColor,
      overlappingShapeStrokeColor:
          overlappingShapeStrokeColor ?? this.overlappingShapeStrokeColor,
      disabledThumbColor: disabledThumbColor ?? this.disabledThumbColor,
      overlayColor: overlayColor ?? this.overlayColor,
      valueIndicatorColor: valueIndicatorColor ?? this.valueIndicatorColor,
      overlayShape: overlayShape ?? this.overlayShape,
      tickMarkShape: tickMarkShape ?? this.tickMarkShape,
      thumbShape: thumbShape ?? this.thumbShape,
      trackShape: trackShape ?? this.trackShape,
      valueIndicatorShape: valueIndicatorShape ?? this.valueIndicatorShape,
      rangeTickMarkShape: rangeTickMarkShape ?? this.rangeTickMarkShape,
      rangeThumbShape: rangeThumbShape ?? this.rangeThumbShape,
      rangeTrackShape: rangeTrackShape ?? this.rangeTrackShape,
      rangeValueIndicatorShape:
          rangeValueIndicatorShape ?? this.rangeValueIndicatorShape,
      showValueIndicator: showValueIndicator ?? this.showValueIndicator,
      valueIndicatorTextStyle:
          valueIndicatorTextStyle ?? this.valueIndicatorTextStyle,
      minThumbSeparation: minThumbSeparation ?? this.minThumbSeparation,
      thumbSelector: thumbSelector ?? this.thumbSelector,
    );
  }

  static SliderThemeData lerp(SliderThemeData a, SliderThemeData b, double t) {
    assert(a != null);
    assert(b != null);
    assert(t != null);
    return SliderThemeData(
      trackHeight: lerpDouble(a.trackHeight, b.trackHeight, t),
      activeTrackColor: Color.lerp(a.activeTrackColor, b.activeTrackColor, t),
      inactiveTrackColor:
          Color.lerp(a.inactiveTrackColor, b.inactiveTrackColor, t),
      disabledActiveTrackColor:
          Color.lerp(a.disabledActiveTrackColor, b.disabledActiveTrackColor, t),
      disabledInactiveTrackColor: Color.lerp(
          a.disabledInactiveTrackColor, b.disabledInactiveTrackColor, t),
      activeTickMarkColor:
          Color.lerp(a.activeTickMarkColor, b.activeTickMarkColor, t),
      inactiveTickMarkColor:
          Color.lerp(a.inactiveTickMarkColor, b.inactiveTickMarkColor, t),
      disabledActiveTickMarkColor: Color.lerp(
          a.disabledActiveTickMarkColor, b.disabledActiveTickMarkColor, t),
      disabledInactiveTickMarkColor: Color.lerp(
          a.disabledInactiveTickMarkColor, b.disabledInactiveTickMarkColor, t),
      thumbColor: Color.lerp(a.thumbColor, b.thumbColor, t),
      overlappingShapeStrokeColor: Color.lerp(
          a.overlappingShapeStrokeColor, b.overlappingShapeStrokeColor, t),
      disabledThumbColor:
          Color.lerp(a.disabledThumbColor, b.disabledThumbColor, t),
      overlayColor: Color.lerp(a.overlayColor, b.overlayColor, t),
      valueIndicatorColor:
          Color.lerp(a.valueIndicatorColor, b.valueIndicatorColor, t),
      overlayShape: t < 0.5 ? a.overlayShape : b.overlayShape,
      tickMarkShape: t < 0.5 ? a.tickMarkShape : b.tickMarkShape,
      thumbShape: t < 0.5 ? a.thumbShape : b.thumbShape,
      trackShape: t < 0.5 ? a.trackShape : b.trackShape,
      valueIndicatorShape:
          t < 0.5 ? a.valueIndicatorShape : b.valueIndicatorShape,
      rangeTickMarkShape: t < 0.5 ? a.rangeTickMarkShape : b.rangeTickMarkShape,
      rangeThumbShape: t < 0.5 ? a.rangeThumbShape : b.rangeThumbShape,
      rangeTrackShape: t < 0.5 ? a.rangeTrackShape : b.rangeTrackShape,
      rangeValueIndicatorShape:
          t < 0.5 ? a.rangeValueIndicatorShape : b.rangeValueIndicatorShape,
      showValueIndicator: t < 0.5 ? a.showValueIndicator : b.showValueIndicator,
      valueIndicatorTextStyle: TextStyle.lerp(
          a.valueIndicatorTextStyle, b.valueIndicatorTextStyle, t),
      minThumbSeparation:
          lerpDouble(a.minThumbSeparation, b.minThumbSeparation, t),
      thumbSelector: t < 0.5 ? a.thumbSelector : b.thumbSelector,
    );
  }

  @override
  int get hashCode {
    return hashList(<Object>[
      trackHeight,
      activeTrackColor,
      inactiveTrackColor,
      disabledActiveTrackColor,
      disabledInactiveTrackColor,
      activeTickMarkColor,
      inactiveTickMarkColor,
      disabledActiveTickMarkColor,
      disabledInactiveTickMarkColor,
      thumbColor,
      overlappingShapeStrokeColor,
      disabledThumbColor,
      overlayColor,
      valueIndicatorColor,
      overlayShape,
      tickMarkShape,
      thumbShape,
      trackShape,
      valueIndicatorShape,
      rangeTickMarkShape,
      rangeThumbShape,
      rangeTrackShape,
      rangeValueIndicatorShape,
      showValueIndicator,
      valueIndicatorTextStyle,
      minThumbSeparation,
      thumbSelector,
    ]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    final SliderThemeData otherData = other;
    return otherData.trackHeight == trackHeight &&
        otherData.activeTrackColor == activeTrackColor &&
        otherData.inactiveTrackColor == inactiveTrackColor &&
        otherData.disabledActiveTrackColor == disabledActiveTrackColor &&
        otherData.disabledInactiveTrackColor == disabledInactiveTrackColor &&
        otherData.activeTickMarkColor == activeTickMarkColor &&
        otherData.inactiveTickMarkColor == inactiveTickMarkColor &&
        otherData.disabledActiveTickMarkColor == disabledActiveTickMarkColor &&
        otherData.disabledInactiveTickMarkColor ==
            disabledInactiveTickMarkColor &&
        otherData.thumbColor == thumbColor &&
        otherData.overlappingShapeStrokeColor == overlappingShapeStrokeColor &&
        otherData.disabledThumbColor == disabledThumbColor &&
        otherData.overlayColor == overlayColor &&
        otherData.valueIndicatorColor == valueIndicatorColor &&
        otherData.overlayShape == overlayShape &&
        otherData.tickMarkShape == tickMarkShape &&
        otherData.thumbShape == thumbShape &&
        otherData.trackShape == trackShape &&
        otherData.valueIndicatorShape == valueIndicatorShape &&
        otherData.rangeTickMarkShape == rangeTickMarkShape &&
        otherData.rangeThumbShape == rangeThumbShape &&
        otherData.rangeTrackShape == rangeTrackShape &&
        otherData.rangeValueIndicatorShape == rangeValueIndicatorShape &&
        otherData.showValueIndicator == showValueIndicator &&
        otherData.valueIndicatorTextStyle == valueIndicatorTextStyle &&
        otherData.minThumbSeparation == minThumbSeparation &&
        otherData.thumbSelector == thumbSelector;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    const SliderThemeData defaultData = SliderThemeData();
    properties.add(DoubleProperty('trackHeight', trackHeight,
        defaultValue: defaultData.trackHeight));
    properties.add(ColorProperty('activeTrackColor', activeTrackColor,
        defaultValue: defaultData.activeTrackColor));
    properties.add(ColorProperty('inactiveTrackColor', inactiveTrackColor,
        defaultValue: defaultData.inactiveTrackColor));
    properties.add(ColorProperty(
        'disabledActiveTrackColor', disabledActiveTrackColor,
        defaultValue: defaultData.disabledActiveTrackColor));
    properties.add(ColorProperty(
        'disabledInactiveTrackColor', disabledInactiveTrackColor,
        defaultValue: defaultData.disabledInactiveTrackColor));
    properties.add(ColorProperty('activeTickMarkColor', activeTickMarkColor,
        defaultValue: defaultData.activeTickMarkColor));
    properties.add(ColorProperty('inactiveTickMarkColor', inactiveTickMarkColor,
        defaultValue: defaultData.inactiveTickMarkColor));
    properties.add(ColorProperty(
        'disabledActiveTickMarkColor', disabledActiveTickMarkColor,
        defaultValue: defaultData.disabledActiveTickMarkColor));
    properties.add(ColorProperty(
        'disabledInactiveTickMarkColor', disabledInactiveTickMarkColor,
        defaultValue: defaultData.disabledInactiveTickMarkColor));
    properties.add(ColorProperty('thumbColor', thumbColor,
        defaultValue: defaultData.thumbColor));
    properties.add(ColorProperty(
        'overlappingShapeStrokeColor', overlappingShapeStrokeColor,
        defaultValue: defaultData.overlappingShapeStrokeColor));
    properties.add(ColorProperty('disabledThumbColor', disabledThumbColor,
        defaultValue: defaultData.disabledThumbColor));
    properties.add(ColorProperty('overlayColor', overlayColor,
        defaultValue: defaultData.overlayColor));
    properties.add(ColorProperty('valueIndicatorColor', valueIndicatorColor,
        defaultValue: defaultData.valueIndicatorColor));
    properties.add(DiagnosticsProperty<SliderComponentShape>(
        'overlayShape', overlayShape,
        defaultValue: defaultData.overlayShape));
    properties.add(DiagnosticsProperty<SliderTickMarkShape>(
        'tickMarkShape', tickMarkShape,
        defaultValue: defaultData.tickMarkShape));
    properties.add(DiagnosticsProperty<SliderComponentShape>(
        'thumbShape', thumbShape,
        defaultValue: defaultData.thumbShape));
    properties.add(DiagnosticsProperty<SliderTrackShape>(
        'trackShape', trackShape,
        defaultValue: defaultData.trackShape));
    properties.add(DiagnosticsProperty<SliderComponentShape>(
        'valueIndicatorShape', valueIndicatorShape,
        defaultValue: defaultData.valueIndicatorShape));
    properties.add(DiagnosticsProperty<RangeSliderTickMarkShape>(
        'rangeTickMarkShape', rangeTickMarkShape,
        defaultValue: defaultData.rangeTickMarkShape));
    properties.add(DiagnosticsProperty<RangeSliderThumbShape>(
        'rangeThumbShape', rangeThumbShape,
        defaultValue: defaultData.rangeThumbShape));
    properties.add(DiagnosticsProperty<RangeSliderTrackShape>(
        'rangeTrackShape', rangeTrackShape,
        defaultValue: defaultData.rangeTrackShape));
    properties.add(DiagnosticsProperty<RangeSliderValueIndicatorShape>(
        'rangeValueIndicatorShape', rangeValueIndicatorShape,
        defaultValue: defaultData.rangeValueIndicatorShape));
    properties.add(EnumProperty<ShowValueIndicator>(
        'showValueIndicator', showValueIndicator,
        defaultValue: defaultData.showValueIndicator));
    properties.add(DiagnosticsProperty<TextStyle>(
        'valueIndicatorTextStyle', valueIndicatorTextStyle,
        defaultValue: defaultData.valueIndicatorTextStyle));
    properties.add(DoubleProperty('minThumbSeparation', minThumbSeparation,
        defaultValue: defaultData.minThumbSeparation));
    properties.add(DiagnosticsProperty<RangeThumbSelector>(
        'thumbSelector', thumbSelector,
        defaultValue: defaultData.thumbSelector));
  }
}

abstract class SliderComponentShape {
  const SliderComponentShape();

  Size getPreferredSize(bool isEnabled, bool isDiscrete);

  void paint(
    PaintingContext context,
    Offset center, {
    Animation<double> activationAnimation,
    Animation<double> enableAnimation,
    bool isDiscrete,
    TextPainter labelPainter,
    RenderBox parentBox,
    SliderThemeData sliderTheme,
    TextDirection textDirection,
    double value,
  });

  static final SliderComponentShape noThumb = _EmptySliderComponentShape();

  static final SliderComponentShape noOverlay = _EmptySliderComponentShape();
}

abstract class SliderTickMarkShape {
  const SliderTickMarkShape();

  Size getPreferredSize({
    SliderThemeData sliderTheme,
    bool isEnabled,
  });

  void paint(
    PaintingContext context,
    Offset center, {
    RenderBox parentBox,
    SliderThemeData sliderTheme,
    Animation<double> enableAnimation,
    Offset thumbCenter,
    bool isEnabled,
    TextDirection textDirection,
  });

  static final SliderTickMarkShape noTickMark = _EmptySliderTickMarkShape();
}

abstract class SliderTrackShape {
  const SliderTrackShape();

  Rect getPreferredRect({
    RenderBox parentBox,
    Offset offset = Offset.zero,
    SliderThemeData sliderTheme,
    bool isEnabled,
    bool isDiscrete,
  });

  void paint(
    PaintingContext context,
    Offset offset, {
    RenderBox parentBox,
    SliderThemeData sliderTheme,
    Animation<double> enableAnimation,
    Offset thumbCenter,
    bool isEnabled,
    bool isDiscrete,
    TextDirection textDirection,
  });
}

abstract class RangeSliderThumbShape {
  const RangeSliderThumbShape();

  Size getPreferredSize(bool isEnabled, bool isDiscrete);

  void paint(
    PaintingContext context,
    Offset center, {
    Animation<double> activationAnimation,
    Animation<double> enableAnimation,
    bool isDiscrete,
    bool isEnabled,
    bool isOnTop,
    TextDirection textDirection,
    SliderThemeData sliderTheme,
    Thumb thumb,
  });
}

abstract class RangeSliderValueIndicatorShape {
  const RangeSliderValueIndicatorShape();

  Size getPreferredSize(bool isEnabled, bool isDiscrete,
      {TextPainter labelPainter});

  void paint(
    PaintingContext context,
    Offset center, {
    Animation<double> activationAnimation,
    Animation<double> enableAnimation,
    bool isDiscrete,
    bool isOnTop,
    TextPainter labelPainter,
    RenderBox parentBox,
    SliderThemeData sliderTheme,
    TextDirection textDirection,
    double value,
    Thumb thumb,
  });
}

abstract class RangeSliderTickMarkShape {
  const RangeSliderTickMarkShape();

  Size getPreferredSize({
    SliderThemeData sliderTheme,
    bool isEnabled,
  });

  void paint(
    PaintingContext context,
    Offset center, {
    RenderBox parentBox,
    SliderThemeData sliderTheme,
    Animation<double> enableAnimation,
    Offset startThumbCenter,
    Offset endThumbCenter,
    bool isEnabled,
    TextDirection textDirection,
  });
}

abstract class RangeSliderTrackShape {
  const RangeSliderTrackShape();

  Rect getPreferredRect({
    RenderBox parentBox,
    Offset offset = Offset.zero,
    SliderThemeData sliderTheme,
    bool isEnabled,
    bool isDiscrete,
  });

  void paint(
    PaintingContext context,
    Offset offset, {
    RenderBox parentBox,
    SliderThemeData sliderTheme,
    Animation<double> enableAnimation,
    Offset startThumbCenter,
    Offset endThumbCenter,
    bool isEnabled,
    bool isDiscrete,
    TextDirection textDirection,
  });
}

abstract class BaseSliderTrackShape {
  Rect getPreferredRect({
    @required RenderBox parentBox,
    Offset offset = Offset.zero,
    @required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    assert(isEnabled != null);
    assert(isDiscrete != null);
    assert(parentBox != null);
    assert(sliderTheme != null);
    final double thumbWidth =
        sliderTheme.thumbShape.getPreferredSize(isEnabled, isDiscrete).width;
    final double overlayWidth =
        sliderTheme.overlayShape.getPreferredSize(isEnabled, isDiscrete).width;
    final double trackHeight = sliderTheme.trackHeight;
    assert(overlayWidth >= 0);
    assert(trackHeight >= 0);
    assert(parentBox.size.width >= overlayWidth);
    assert(parentBox.size.height >= trackHeight);

    final double trackLeft = offset.dx + overlayWidth / 2;
    final double trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth =
        parentBox.size.width - math.max(thumbWidth, overlayWidth);
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}

class RectangularSliderTrackShape extends SliderTrackShape
    with BaseSliderTrackShape {
  const RectangularSliderTrackShape({this.disabledThumbGapWidth = 2.0});

  final double disabledThumbGapWidth;

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    @required RenderBox parentBox,
    @required SliderThemeData sliderTheme,
    @required Animation<double> enableAnimation,
    @required TextDirection textDirection,
    @required Offset thumbCenter,
    bool isDiscrete = false,
    bool isEnabled = false,
  }) {
    assert(context != null);
    assert(offset != null);
    assert(parentBox != null);
    assert(sliderTheme != null);
    assert(sliderTheme.disabledActiveTrackColor != null);
    assert(sliderTheme.disabledInactiveTrackColor != null);
    assert(sliderTheme.activeTrackColor != null);
    assert(sliderTheme.inactiveTrackColor != null);
    assert(sliderTheme.thumbShape != null);
    assert(enableAnimation != null);
    assert(textDirection != null);
    assert(thumbCenter != null);
    assert(isEnabled != null);
    assert(isDiscrete != null);

    if (sliderTheme.trackHeight <= 0) {
      return;
    }

    final ColorTween activeTrackColorTween = ColorTween(
        begin: sliderTheme.disabledActiveTrackColor,
        end: sliderTheme.activeTrackColor);
    final ColorTween inactiveTrackColorTween = ColorTween(
        begin: sliderTheme.disabledInactiveTrackColor,
        end: sliderTheme.inactiveTrackColor);
    final Paint activePaint = Paint()
      ..color = activeTrackColorTween.evaluate(enableAnimation);
    final Paint inactivePaint = Paint()
      ..color = inactiveTrackColorTween.evaluate(enableAnimation);
    Paint leftTrackPaint;
    Paint rightTrackPaint;
    switch (textDirection) {
      case TextDirection.ltr:
        leftTrackPaint = activePaint;
        rightTrackPaint = inactivePaint;
        break;
      case TextDirection.rtl:
        leftTrackPaint = inactivePaint;
        rightTrackPaint = activePaint;
        break;
    }

    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final Size thumbSize =
        sliderTheme.thumbShape.getPreferredSize(isEnabled, isDiscrete);
    final Rect leftTrackSegment = Rect.fromLTRB(
        trackRect.left + trackRect.height / 2,
        trackRect.top,
        thumbCenter.dx - thumbSize.width / 2,
        trackRect.bottom);
    if (!leftTrackSegment.isEmpty)
      context.canvas.drawRect(leftTrackSegment, leftTrackPaint);
    final Rect rightTrackSegment = Rect.fromLTRB(
        thumbCenter.dx + thumbSize.width / 2,
        trackRect.top,
        trackRect.right,
        trackRect.bottom);
    if (!rightTrackSegment.isEmpty)
      context.canvas.drawRect(rightTrackSegment, rightTrackPaint);
  }
}

class RoundedRectSliderTrackShape extends SliderTrackShape
    with BaseSliderTrackShape {
  const RoundedRectSliderTrackShape();

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    @required RenderBox parentBox,
    @required SliderThemeData sliderTheme,
    @required Animation<double> enableAnimation,
    @required TextDirection textDirection,
    @required Offset thumbCenter,
    bool isDiscrete = false,
    bool isEnabled = false,
  }) {
    assert(context != null);
    assert(offset != null);
    assert(parentBox != null);
    assert(sliderTheme != null);
    assert(sliderTheme.disabledActiveTrackColor != null);
    assert(sliderTheme.disabledInactiveTrackColor != null);
    assert(sliderTheme.activeTrackColor != null);
    assert(sliderTheme.inactiveTrackColor != null);
    assert(sliderTheme.thumbShape != null);
    assert(enableAnimation != null);
    assert(textDirection != null);
    assert(thumbCenter != null);

    if (sliderTheme.trackHeight <= 0) {
      return;
    }

    final ColorTween activeTrackColorTween = ColorTween(
        begin: sliderTheme.disabledActiveTrackColor,
        end: sliderTheme.activeTrackColor);
    final ColorTween inactiveTrackColorTween = ColorTween(
        begin: sliderTheme.disabledInactiveTrackColor,
        end: sliderTheme.inactiveTrackColor);
    final Paint activePaint = Paint()
      ..color = activeTrackColorTween.evaluate(enableAnimation);
    final Paint inactivePaint = Paint()
      ..color = inactiveTrackColorTween.evaluate(enableAnimation);
    Paint leftTrackPaint;
    Paint rightTrackPaint;
    switch (textDirection) {
      case TextDirection.ltr:
        leftTrackPaint = activePaint;
        rightTrackPaint = inactivePaint;
        break;
      case TextDirection.rtl:
        leftTrackPaint = inactivePaint;
        rightTrackPaint = activePaint;
        break;
    }

    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final Rect leftTrackArcRect = Rect.fromLTWH(
        trackRect.left, trackRect.top, trackRect.height, trackRect.height);
    if (!leftTrackArcRect.isEmpty)
      context.canvas.drawArc(
          leftTrackArcRect, math.pi / 2, math.pi, false, leftTrackPaint);
    final Rect rightTrackArcRect = Rect.fromLTWH(
        trackRect.right - trackRect.height / 2,
        trackRect.top,
        trackRect.height,
        trackRect.height);
    if (!rightTrackArcRect.isEmpty)
      context.canvas.drawArc(
          rightTrackArcRect, -math.pi / 2, math.pi, false, rightTrackPaint);

    final Size thumbSize =
        sliderTheme.thumbShape.getPreferredSize(isEnabled, isDiscrete);
    final Rect leftTrackSegment = Rect.fromLTRB(
        trackRect.left + trackRect.height / 2,
        trackRect.top,
        thumbCenter.dx - thumbSize.width / 2,
        trackRect.bottom);
    if (!leftTrackSegment.isEmpty)
      context.canvas.drawRect(leftTrackSegment, leftTrackPaint);
    final Rect rightTrackSegment = Rect.fromLTRB(
        thumbCenter.dx + thumbSize.width / 2,
        trackRect.top,
        trackRect.right,
        trackRect.bottom);
    if (!rightTrackSegment.isEmpty)
      context.canvas.drawRect(rightTrackSegment, rightTrackPaint);
  }
}

class RectangularRangeSliderTrackShape extends RangeSliderTrackShape {
  const RectangularRangeSliderTrackShape();

  @override
  Rect getPreferredRect({
    @required RenderBox parentBox,
    Offset offset = Offset.zero,
    @required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    assert(parentBox != null);
    assert(offset != null);
    assert(sliderTheme != null);
    assert(sliderTheme.overlayShape != null);
    assert(isEnabled != null);
    assert(isDiscrete != null);
    final double overlayWidth =
        sliderTheme.overlayShape.getPreferredSize(isEnabled, isDiscrete).width;
    final double trackHeight = sliderTheme.trackHeight;
    assert(overlayWidth >= 0);
    assert(trackHeight >= 0);
    assert(parentBox.size.width >= overlayWidth);
    assert(parentBox.size.height >= trackHeight);

    final double trackLeft = offset.dx + overlayWidth / 2;
    final double trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width - overlayWidth;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    @required RenderBox parentBox,
    @required SliderThemeData sliderTheme,
    @required Animation<double> enableAnimation,
    @required Offset startThumbCenter,
    @required Offset endThumbCenter,
    bool isEnabled = false,
    bool isDiscrete = false,
    @required TextDirection textDirection,
  }) {
    assert(context != null);
    assert(offset != null);
    assert(parentBox != null);
    assert(sliderTheme != null);
    assert(sliderTheme.disabledActiveTrackColor != null);
    assert(sliderTheme.disabledInactiveTrackColor != null);
    assert(sliderTheme.activeTrackColor != null);
    assert(sliderTheme.inactiveTrackColor != null);
    assert(sliderTheme.rangeThumbShape != null);
    assert(enableAnimation != null);
    assert(startThumbCenter != null);
    assert(endThumbCenter != null);
    assert(isEnabled != null);
    assert(isDiscrete != null);
    assert(textDirection != null);

    final ColorTween activeTrackColorTween = ColorTween(
        begin: sliderTheme.disabledActiveTrackColor,
        end: sliderTheme.activeTrackColor);
    final ColorTween inactiveTrackColorTween = ColorTween(
        begin: sliderTheme.disabledInactiveTrackColor,
        end: sliderTheme.inactiveTrackColor);
    final Paint activePaint = Paint()
      ..color = activeTrackColorTween.evaluate(enableAnimation);
    final Paint inactivePaint = Paint()
      ..color = inactiveTrackColorTween.evaluate(enableAnimation);

    Offset leftThumbOffset;
    Offset rightThumbOffset;
    switch (textDirection) {
      case TextDirection.ltr:
        leftThumbOffset = startThumbCenter;
        rightThumbOffset = endThumbCenter;
        break;
      case TextDirection.rtl:
        leftThumbOffset = endThumbCenter;
        rightThumbOffset = startThumbCenter;
        break;
    }
    final Size thumbSize =
        sliderTheme.rangeThumbShape.getPreferredSize(isEnabled, isDiscrete);
    final double thumbRadius = thumbSize.width / 2;

    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    final Rect leftTrackSegment = Rect.fromLTRB(trackRect.left, trackRect.top,
        leftThumbOffset.dx - thumbRadius, trackRect.bottom);
    if (!leftTrackSegment.isEmpty)
      context.canvas.drawRect(leftTrackSegment, inactivePaint);
    final Rect middleTrackSegment = Rect.fromLTRB(
        leftThumbOffset.dx + thumbRadius,
        trackRect.top,
        rightThumbOffset.dx - thumbRadius,
        trackRect.bottom);
    if (!middleTrackSegment.isEmpty)
      context.canvas.drawRect(middleTrackSegment, activePaint);
    final Rect rightTrackSegment = Rect.fromLTRB(
        rightThumbOffset.dx + thumbRadius,
        trackRect.top,
        trackRect.right,
        trackRect.bottom);
    if (!rightTrackSegment.isEmpty)
      context.canvas.drawRect(rightTrackSegment, inactivePaint);
  }
}

class RoundedRectRangeSliderTrackShape extends RangeSliderTrackShape {
  const RoundedRectRangeSliderTrackShape();

  @override
  Rect getPreferredRect({
    @required RenderBox parentBox,
    Offset offset = Offset.zero,
    @required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    assert(parentBox != null);
    assert(offset != null);
    assert(sliderTheme != null);
    assert(sliderTheme.overlayShape != null);
    assert(sliderTheme.trackHeight != null);
    assert(isEnabled != null);
    assert(isDiscrete != null);
    final double overlayWidth =
        sliderTheme.overlayShape.getPreferredSize(isEnabled, isDiscrete).width;
    final double trackHeight = sliderTheme.trackHeight;
    assert(overlayWidth >= 0);
    assert(trackHeight >= 0);
    assert(parentBox.size.width >= overlayWidth);
    assert(parentBox.size.height >= trackHeight);

    final double trackLeft = offset.dx + overlayWidth / 2;
    final double trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width - overlayWidth;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    @required RenderBox parentBox,
    @required SliderThemeData sliderTheme,
    @required Animation<double> enableAnimation,
    @required Offset startThumbCenter,
    @required Offset endThumbCenter,
    bool isEnabled = false,
    bool isDiscrete = false,
    @required TextDirection textDirection,
  }) {
    assert(context != null);
    assert(offset != null);
    assert(parentBox != null);
    assert(sliderTheme != null);
    assert(sliderTheme.disabledActiveTrackColor != null);
    assert(sliderTheme.disabledInactiveTrackColor != null);
    assert(sliderTheme.activeTrackColor != null);
    assert(sliderTheme.inactiveTrackColor != null);
    assert(sliderTheme.rangeThumbShape != null);
    assert(enableAnimation != null);
    assert(startThumbCenter != null);
    assert(endThumbCenter != null);
    assert(isEnabled != null);
    assert(isDiscrete != null);
    assert(textDirection != null);

    final ColorTween activeTrackColorTween = ColorTween(
        begin: sliderTheme.disabledActiveTrackColor,
        end: sliderTheme.activeTrackColor);
    final ColorTween inactiveTrackColorTween = ColorTween(
        begin: sliderTheme.disabledInactiveTrackColor,
        end: sliderTheme.inactiveTrackColor);
    final Paint activePaint = Paint()
      ..color = activeTrackColorTween.evaluate(enableAnimation);
    final Paint inactivePaint = Paint()
      ..color = inactiveTrackColorTween.evaluate(enableAnimation);

    Offset leftThumbOffset;
    Offset rightThumbOffset;
    switch (textDirection) {
      case TextDirection.ltr:
        leftThumbOffset = startThumbCenter;
        rightThumbOffset = endThumbCenter;
        break;
      case TextDirection.rtl:
        leftThumbOffset = endThumbCenter;
        rightThumbOffset = startThumbCenter;
        break;
    }
    final Size thumbSize =
        sliderTheme.rangeThumbShape.getPreferredSize(isEnabled, isDiscrete);
    final double thumbRadius = thumbSize.width / 2;
    assert(thumbRadius > 0);

    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    final double trackRadius = trackRect.height / 2;

    final Rect leftTrackArcRect = Rect.fromLTWH(
        trackRect.left, trackRect.top, trackRect.height, trackRect.height);
    if (!leftTrackArcRect.isEmpty)
      context.canvas.drawArc(
          leftTrackArcRect, math.pi / 2, math.pi, false, inactivePaint);

    final Rect leftTrackSegment = Rect.fromLTRB(trackRect.left + trackRadius,
        trackRect.top, leftThumbOffset.dx - thumbRadius, trackRect.bottom);
    if (!leftTrackSegment.isEmpty)
      context.canvas.drawRect(leftTrackSegment, inactivePaint);
    final Rect middleTrackSegment = Rect.fromLTRB(
        leftThumbOffset.dx + thumbRadius,
        trackRect.top,
        rightThumbOffset.dx - thumbRadius,
        trackRect.bottom);
    if (!middleTrackSegment.isEmpty)
      context.canvas.drawRect(middleTrackSegment, activePaint);
    final Rect rightTrackSegment = Rect.fromLTRB(
        rightThumbOffset.dx + thumbRadius,
        trackRect.top,
        trackRect.right - trackRadius,
        trackRect.bottom);
    if (!rightTrackSegment.isEmpty)
      context.canvas.drawRect(rightTrackSegment, inactivePaint);

    final Rect rightTrackArcRect = Rect.fromLTWH(
        trackRect.right - trackRect.height,
        trackRect.top,
        trackRect.height,
        trackRect.height);
    if (!rightTrackArcRect.isEmpty)
      context.canvas.drawArc(
          rightTrackArcRect, -math.pi / 2, math.pi, false, inactivePaint);
  }
}

class RoundSliderTickMarkShape extends SliderTickMarkShape {
  const RoundSliderTickMarkShape({this.tickMarkRadius});

  final double tickMarkRadius;

  @override
  Size getPreferredSize({
    @required SliderThemeData sliderTheme,
    bool isEnabled = false,
  }) {
    assert(sliderTheme != null);
    assert(sliderTheme.trackHeight != null);
    assert(isEnabled != null);

    return Size.fromRadius(tickMarkRadius ?? sliderTheme.trackHeight / 2);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    @required RenderBox parentBox,
    @required SliderThemeData sliderTheme,
    @required Animation<double> enableAnimation,
    @required TextDirection textDirection,
    @required Offset thumbCenter,
    bool isEnabled = false,
  }) {
    assert(context != null);
    assert(center != null);
    assert(parentBox != null);
    assert(sliderTheme != null);
    assert(sliderTheme.disabledActiveTickMarkColor != null);
    assert(sliderTheme.disabledInactiveTickMarkColor != null);
    assert(sliderTheme.activeTickMarkColor != null);
    assert(sliderTheme.inactiveTickMarkColor != null);
    assert(enableAnimation != null);
    assert(textDirection != null);
    assert(thumbCenter != null);
    assert(isEnabled != null);

    Color begin;
    Color end;
    switch (textDirection) {
      case TextDirection.ltr:
        final bool isTickMarkRightOfThumb = center.dx > thumbCenter.dx;
        begin = isTickMarkRightOfThumb
            ? sliderTheme.disabledInactiveTickMarkColor
            : sliderTheme.disabledActiveTickMarkColor;
        end = isTickMarkRightOfThumb
            ? sliderTheme.inactiveTickMarkColor
            : sliderTheme.activeTickMarkColor;
        break;
      case TextDirection.rtl:
        final bool isTickMarkLeftOfThumb = center.dx < thumbCenter.dx;
        begin = isTickMarkLeftOfThumb
            ? sliderTheme.disabledInactiveTickMarkColor
            : sliderTheme.disabledActiveTickMarkColor;
        end = isTickMarkLeftOfThumb
            ? sliderTheme.inactiveTickMarkColor
            : sliderTheme.activeTickMarkColor;
        break;
    }
    final Paint paint = Paint()
      ..color = ColorTween(begin: begin, end: end).evaluate(enableAnimation);

    final double tickMarkRadius = getPreferredSize(
          isEnabled: isEnabled,
          sliderTheme: sliderTheme,
        ).width /
        2;
    if (tickMarkRadius > 0) {
      context.canvas.drawCircle(center, tickMarkRadius, paint);
    }
  }
}

class RoundRangeSliderTickMarkShape extends RangeSliderTickMarkShape {
  const RoundRangeSliderTickMarkShape({this.tickMarkRadius});

  final double tickMarkRadius;

  @override
  Size getPreferredSize({
    @required SliderThemeData sliderTheme,
    bool isEnabled = false,
  }) {
    assert(sliderTheme != null);
    assert(sliderTheme.trackHeight != null);
    assert(isEnabled != null);
    return Size.fromRadius(tickMarkRadius ?? sliderTheme.trackHeight / 2);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    @required RenderBox parentBox,
    @required SliderThemeData sliderTheme,
    @required Animation<double> enableAnimation,
    @required Offset startThumbCenter,
    @required Offset endThumbCenter,
    bool isEnabled = false,
    @required TextDirection textDirection,
  }) {
    assert(context != null);
    assert(center != null);
    assert(parentBox != null);
    assert(sliderTheme != null);
    assert(sliderTheme.disabledActiveTickMarkColor != null);
    assert(sliderTheme.disabledInactiveTickMarkColor != null);
    assert(sliderTheme.activeTickMarkColor != null);
    assert(sliderTheme.inactiveTickMarkColor != null);
    assert(enableAnimation != null);
    assert(startThumbCenter != null);
    assert(endThumbCenter != null);
    assert(isEnabled != null);
    assert(textDirection != null);

    bool isBetweenThumbs;
    switch (textDirection) {
      case TextDirection.ltr:
        isBetweenThumbs =
            startThumbCenter.dx < center.dx && center.dx < endThumbCenter.dx;
        break;
      case TextDirection.rtl:
        isBetweenThumbs =
            endThumbCenter.dx < center.dx && center.dx < startThumbCenter.dx;
        break;
    }
    final Color begin = isBetweenThumbs
        ? sliderTheme.disabledActiveTickMarkColor
        : sliderTheme.disabledInactiveTickMarkColor;
    final Color end = isBetweenThumbs
        ? sliderTheme.activeTickMarkColor
        : sliderTheme.inactiveTickMarkColor;
    final Paint paint = Paint()
      ..color = ColorTween(begin: begin, end: end).evaluate(enableAnimation);

    final double tickMarkRadius = getPreferredSize(
          isEnabled: isEnabled,
          sliderTheme: sliderTheme,
        ).width /
        2;
    if (tickMarkRadius > 0) {
      context.canvas.drawCircle(center, tickMarkRadius, paint);
    }
  }
}

class _EmptySliderTickMarkShape extends SliderTickMarkShape {
  @override
  Size getPreferredSize({
    SliderThemeData sliderTheme,
    bool isEnabled,
  }) {
    return Size.zero;
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    RenderBox parentBox,
    SliderThemeData sliderTheme,
    Animation<double> enableAnimation,
    Offset thumbCenter,
    bool isEnabled,
    TextDirection textDirection,
  }) {}
}

class _EmptySliderComponentShape extends SliderComponentShape {
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => Size.zero;

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    Animation<double> activationAnimation,
    Animation<double> enableAnimation,
    bool isDiscrete,
    TextPainter labelPainter,
    RenderBox parentBox,
    SliderThemeData sliderTheme,
    TextDirection textDirection,
    double value,
  }) {}
}

class RoundSliderThumbShape extends SliderComponentShape {
  const RoundSliderThumbShape({
    this.enabledThumbRadius = 10.0,
    this.disabledThumbRadius,
  });

  final double enabledThumbRadius;

  final double disabledThumbRadius;
  double get _disabledThumbRadius => disabledThumbRadius ?? enabledThumbRadius;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(
        isEnabled == true ? enabledThumbRadius : _disabledThumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    Animation<double> activationAnimation,
    @required Animation<double> enableAnimation,
    bool isDiscrete,
    TextPainter labelPainter,
    RenderBox parentBox,
    @required SliderThemeData sliderTheme,
    TextDirection textDirection,
    double value,
  }) {
    assert(context != null);
    assert(center != null);
    assert(enableAnimation != null);
    assert(sliderTheme != null);
    assert(sliderTheme.disabledThumbColor != null);
    assert(sliderTheme.thumbColor != null);

    final Canvas canvas = context.canvas;
    final Tween<double> radiusTween = Tween<double>(
      begin: _disabledThumbRadius,
      end: enabledThumbRadius,
    );
    final ColorTween colorTween = ColorTween(
      begin: sliderTheme.disabledThumbColor,
      end: sliderTheme.thumbColor,
    );
    canvas.drawCircle(
      center,
      radiusTween.evaluate(enableAnimation),
      Paint()..color = colorTween.evaluate(enableAnimation),
    );
  }
}

class RoundRangeSliderThumbShape extends RangeSliderThumbShape {
  const RoundRangeSliderThumbShape({
    this.enabledThumbRadius = 10.0,
    this.disabledThumbRadius,
  }) : assert(enabledThumbRadius != null);

  final double enabledThumbRadius;

  final double disabledThumbRadius;
  double get _disabledThumbRadius => disabledThumbRadius ?? enabledThumbRadius;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(
        isEnabled == true ? enabledThumbRadius : _disabledThumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    @required Animation<double> activationAnimation,
    @required Animation<double> enableAnimation,
    bool isDiscrete = false,
    bool isEnabled = false,
    bool isOnTop,
    @required SliderThemeData sliderTheme,
    TextDirection textDirection,
    Thumb thumb,
  }) {
    assert(context != null);
    assert(center != null);
    assert(activationAnimation != null);
    assert(sliderTheme != null);
    assert(sliderTheme.showValueIndicator != null);
    assert(sliderTheme.overlappingShapeStrokeColor != null);
    assert(enableAnimation != null);
    final Canvas canvas = context.canvas;
    final Tween<double> radiusTween = Tween<double>(
      begin: _disabledThumbRadius,
      end: enabledThumbRadius,
    );
    final ColorTween colorTween = ColorTween(
      begin: sliderTheme.disabledThumbColor,
      end: sliderTheme.thumbColor,
    );
    final double radius = radiusTween.evaluate(enableAnimation);

    if (isOnTop == true) {
      bool showValueIndicator;
      switch (sliderTheme.showValueIndicator) {
        case ShowValueIndicator.onlyForDiscrete:
          showValueIndicator = isDiscrete;
          break;
        case ShowValueIndicator.onlyForContinuous:
          showValueIndicator = !isDiscrete;
          break;
        case ShowValueIndicator.always:
          showValueIndicator = true;
          break;
        case ShowValueIndicator.never:
          showValueIndicator = false;
          break;
      }

      final Paint strokePaint = Paint()
        ..color = sliderTheme.overlappingShapeStrokeColor
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      if (showValueIndicator && activationAnimation.value > 0) {
        const double startAngle = -math.pi / 2 + 0.2;
        const double sweepAngle = math.pi * 2 - 0.4;
        canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
            startAngle, sweepAngle, false, strokePaint);
      } else {
        canvas.drawCircle(center, radius, strokePaint);
      }
    }

    canvas.drawCircle(
      center,
      radius,
      Paint()..color = colorTween.evaluate(enableAnimation),
    );
  }
}

class RoundSliderOverlayShape extends SliderComponentShape {
  const RoundSliderOverlayShape({this.overlayRadius = 24.0});

  final double overlayRadius;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(overlayRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    @required Animation<double> activationAnimation,
    @required Animation<double> enableAnimation,
    bool isDiscrete = false,
    @required TextPainter labelPainter,
    @required RenderBox parentBox,
    @required SliderThemeData sliderTheme,
    @required TextDirection textDirection,
    @required double value,
  }) {
    assert(context != null);
    assert(center != null);
    assert(activationAnimation != null);
    assert(enableAnimation != null);
    assert(labelPainter != null);
    assert(parentBox != null);
    assert(sliderTheme != null);
    assert(textDirection != null);
    assert(value != null);

    final Canvas canvas = context.canvas;
    final Tween<double> radiusTween = Tween<double>(
      begin: 0.0,
      end: overlayRadius,
    );

    canvas.drawCircle(
      center,
      radiusTween.evaluate(activationAnimation),
      Paint()..color = sliderTheme.overlayColor,
    );
  }
}

class PaddleSliderValueIndicatorShape extends SliderComponentShape {
  const PaddleSliderValueIndicatorShape();

  static const _PaddleSliderTrackShapePathPainter _pathPainter =
      _PaddleSliderTrackShapePathPainter();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete,
      {@required TextPainter labelPainter}) {
    assert(labelPainter != null);
    return _pathPainter.getPreferredSize(isEnabled, isDiscrete, labelPainter);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    @required Animation<double> activationAnimation,
    @required Animation<double> enableAnimation,
    bool isDiscrete,
    @required TextPainter labelPainter,
    @required RenderBox parentBox,
    @required SliderThemeData sliderTheme,
    TextDirection textDirection,
    double value,
  }) {
    assert(context != null);
    assert(center != null);
    assert(activationAnimation != null);
    assert(enableAnimation != null);
    assert(labelPainter != null);
    assert(parentBox != null);
    assert(sliderTheme != null);
    final ColorTween enableColor = ColorTween(
      begin: sliderTheme.disabledThumbColor,
      end: sliderTheme.valueIndicatorColor,
    );
    _pathPainter.drawValueIndicator(
      parentBox,
      context.canvas,
      center,
      Paint()..color = enableColor.evaluate(enableAnimation),
      activationAnimation.value,
      labelPainter,
      null,
    );
  }
}

class PaddleRangeSliderValueIndicatorShape
    extends RangeSliderValueIndicatorShape {
  const PaddleRangeSliderValueIndicatorShape();

  static const _PaddleSliderTrackShapePathPainter _pathPainter =
      _PaddleSliderTrackShapePathPainter();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete,
      {@required TextPainter labelPainter}) {
    assert(labelPainter != null);
    return _pathPainter.getPreferredSize(isEnabled, isDiscrete, labelPainter);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    @required Animation<double> activationAnimation,
    @required Animation<double> enableAnimation,
    bool isDiscrete,
    bool isOnTop = false,
    @required TextPainter labelPainter,
    @required RenderBox parentBox,
    @required SliderThemeData sliderTheme,
    TextDirection textDirection,
    Thumb thumb,
    double value,
  }) {
    assert(context != null);
    assert(center != null);
    assert(activationAnimation != null);
    assert(enableAnimation != null);
    assert(labelPainter != null);
    assert(parentBox != null);
    assert(sliderTheme != null);
    final ColorTween enableColor = ColorTween(
      begin: sliderTheme.disabledThumbColor,
      end: sliderTheme.valueIndicatorColor,
    );

    _pathPainter.drawValueIndicator(
      parentBox,
      context.canvas,
      center,
      Paint()..color = enableColor.evaluate(enableAnimation),
      activationAnimation.value,
      labelPainter,
      isOnTop ? sliderTheme.overlappingShapeStrokeColor : null,
    );
  }
}

class _PaddleSliderTrackShapePathPainter {
  const _PaddleSliderTrackShapePathPainter();

  static const double _topLobeRadius = 16.0;

  static const double _labelTextDesignSize = 14.0;

  static const double _bottomLobeRadius = 6.0;

  static const double _bottomLobeStartAngle = -1.1 * math.pi / 4.0;

  static const double _bottomLobeEndAngle = 1.1 * 5 * math.pi / 4.0;

  static const double _labelPadding = 8.0;
  static const double _distanceBetweenTopBottomCenters = 40.0;
  static const Offset _topLobeCenter =
      Offset(0.0, -_distanceBetweenTopBottomCenters);
  static const double _topNeckRadius = 14.0;

  static const double _neckTriangleHypotenuse = _topLobeRadius + _topNeckRadius;

  static const double _twoSeventyDegrees = 3.0 * math.pi / 2.0;
  static const double _ninetyDegrees = math.pi / 2.0;
  static const double _thirtyDegrees = math.pi / 6.0;
  static const double _preferredHeight =
      _distanceBetweenTopBottomCenters + _topLobeRadius + _bottomLobeRadius;

  static const bool _debuggingLabelLocation = false;

  static Path _bottomLobePath;
  static Offset _bottomLobeEnd;

  Size getPreferredSize(
    bool isEnabled,
    bool isDiscrete,
    TextPainter labelPainter,
  ) {
    assert(labelPainter != null);
    final double labelHalfWidth = labelPainter.width / 2.0;
    return Size((labelHalfWidth + _topLobeRadius) * 2, _preferredHeight);
  }

  static void _addArc(Path path, Offset center, double radius,
      double startAngle, double endAngle) {
    final Rect arcRect = Rect.fromCircle(center: center, radius: radius);
    path.arcTo(arcRect, startAngle, endAngle - startAngle, false);
  }

  static void _generateBottomLobe() {
    const double bottomNeckRadius = 4.5;
    const double bottomNeckStartAngle = _bottomLobeEndAngle - math.pi;
    const double bottomNeckEndAngle = 0.0;

    final Path path = Path();
    final Offset bottomKnobStart = Offset(
      _bottomLobeRadius * math.cos(_bottomLobeStartAngle),
      _bottomLobeRadius * math.sin(_bottomLobeStartAngle) - 2,
    );
    final Offset bottomNeckRightCenter = bottomKnobStart +
        Offset(
          bottomNeckRadius * math.cos(bottomNeckStartAngle),
          -bottomNeckRadius * math.sin(bottomNeckStartAngle),
        );
    final Offset bottomNeckLeftCenter = Offset(
      -bottomNeckRightCenter.dx,
      bottomNeckRightCenter.dy,
    );
    final Offset bottomNeckStartRight = Offset(
      bottomNeckRightCenter.dx - bottomNeckRadius,
      bottomNeckRightCenter.dy,
    );
    path.moveTo(bottomNeckStartRight.dx, bottomNeckStartRight.dy);
    _addArc(
      path,
      bottomNeckRightCenter,
      bottomNeckRadius,
      math.pi - bottomNeckEndAngle,
      math.pi - bottomNeckStartAngle,
    );
    _addArc(
      path,
      Offset.zero,
      _bottomLobeRadius,
      _bottomLobeStartAngle,
      _bottomLobeEndAngle,
    );
    _addArc(
      path,
      bottomNeckLeftCenter,
      bottomNeckRadius,
      bottomNeckStartAngle,
      bottomNeckEndAngle,
    );

    _bottomLobeEnd = Offset(
      -bottomNeckStartRight.dx,
      bottomNeckStartRight.dy,
    );
    _bottomLobePath = path;
  }

  Offset _addBottomLobe(Path path) {
    if (_bottomLobePath == null || _bottomLobeEnd == null) {
      _generateBottomLobe();
    }
    path.extendWithPath(_bottomLobePath, Offset.zero);
    return _bottomLobeEnd;
  }

  double _getIdealOffset(
    RenderBox parentBox,
    double halfWidthNeeded,
    double scale,
    Offset center,
  ) {
    const double edgeMargin = 4.0;
    final Rect topLobeRect = Rect.fromLTWH(
      -_topLobeRadius - halfWidthNeeded,
      -_topLobeRadius - _distanceBetweenTopBottomCenters,
      2.0 * (_topLobeRadius + halfWidthNeeded),
      2.0 * _topLobeRadius,
    );

    final Offset topLeft = (topLobeRect.topLeft * scale) + center;
    final Offset bottomRight = (topLobeRect.bottomRight * scale) + center;
    double shift = 0.0;
    if (topLeft.dx < edgeMargin) {
      shift = edgeMargin - topLeft.dx;
    }
    if (bottomRight.dx > parentBox.size.width - edgeMargin) {
      shift = parentBox.size.width - bottomRight.dx - edgeMargin;
    }
    shift = scale == 0.0 ? 0.0 : shift / scale;
    return shift;
  }

  void drawValueIndicator(
    RenderBox parentBox,
    Canvas canvas,
    Offset center,
    Paint paint,
    double scale,
    TextPainter labelPainter,
    Color strokePaintColor,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);

    final double textScaleFactor = labelPainter.height / _labelTextDesignSize;
    final double overallScale = scale * textScaleFactor;
    canvas.scale(overallScale, overallScale);
    final double inverseTextScale =
        textScaleFactor != 0 ? 1.0 / textScaleFactor : 0.0;
    final double labelHalfWidth = labelPainter.width / 2.0;

    final double halfWidthNeeded = math.max(
      0.0,
      inverseTextScale * labelHalfWidth - (_topLobeRadius - _labelPadding),
    );

    double shift =
        _getIdealOffset(parentBox, halfWidthNeeded, overallScale, center);
    double leftWidthNeeded;
    double rightWidthNeeded;
    if (shift < 0.0) {
      shift = math.max(shift, -halfWidthNeeded);
    } else {
      shift = math.min(shift, halfWidthNeeded);
    }
    rightWidthNeeded = halfWidthNeeded + shift;
    leftWidthNeeded = halfWidthNeeded - shift;

    final Path path = Path();
    final Offset bottomLobeEnd = _addBottomLobe(path);

    final double neckTriangleBase = _topNeckRadius - bottomLobeEnd.dx;

    final double leftAmount =
        math.max(0.0, math.min(1.0, leftWidthNeeded / neckTriangleBase));
    final double rightAmount =
        math.max(0.0, math.min(1.0, rightWidthNeeded / neckTriangleBase));

    final double leftTheta = (1.0 - leftAmount) * _thirtyDegrees;
    final double rightTheta = (1.0 - rightAmount) * _thirtyDegrees;

    final Offset neckLeftCenter = Offset(
      -neckTriangleBase,
      _topLobeCenter.dy + math.cos(leftTheta) * _neckTriangleHypotenuse,
    );
    final Offset neckRightCenter = Offset(
      neckTriangleBase,
      _topLobeCenter.dy + math.cos(rightTheta) * _neckTriangleHypotenuse,
    );
    final double leftNeckArcAngle = _ninetyDegrees - leftTheta;
    final double rightNeckArcAngle = math.pi + _ninetyDegrees - rightTheta;

    final double neckStretchBaseline = math.max(0.0,
        bottomLobeEnd.dy - math.max(neckLeftCenter.dy, neckRightCenter.dy));
    final double t = math.pow(inverseTextScale, 3.0);
    final double stretch =
        (neckStretchBaseline * t).clamp(0.0, 10.0 * neckStretchBaseline);
    final Offset neckStretch = Offset(0.0, neckStretchBaseline - stretch);

    assert(!_debuggingLabelLocation ||
        () {
          final Offset leftCenter =
              _topLobeCenter - Offset(leftWidthNeeded, 0.0) + neckStretch;
          final Offset rightCenter =
              _topLobeCenter + Offset(rightWidthNeeded, 0.0) + neckStretch;
          final Rect valueRect = Rect.fromLTRB(
            leftCenter.dx - _topLobeRadius,
            leftCenter.dy - _topLobeRadius,
            rightCenter.dx + _topLobeRadius,
            rightCenter.dy + _topLobeRadius,
          );
          final Paint outlinePaint = Paint()
            ..color = const Color(0xffff0000)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0;
          canvas.drawRect(valueRect, outlinePaint);
          return true;
        }());

    _addArc(
      path,
      neckLeftCenter + neckStretch,
      _topNeckRadius,
      0.0,
      -leftNeckArcAngle,
    );
    _addArc(
      path,
      _topLobeCenter - Offset(leftWidthNeeded, 0.0) + neckStretch,
      _topLobeRadius,
      _ninetyDegrees + leftTheta,
      _twoSeventyDegrees,
    );
    _addArc(
      path,
      _topLobeCenter + Offset(rightWidthNeeded, 0.0) + neckStretch,
      _topLobeRadius,
      _twoSeventyDegrees,
      _twoSeventyDegrees + math.pi - rightTheta,
    );
    _addArc(
      path,
      neckRightCenter + neckStretch,
      _topNeckRadius,
      rightNeckArcAngle,
      math.pi,
    );

    if (strokePaintColor != null) {
      final Paint strokePaint = Paint()
        ..color = strokePaintColor
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      canvas.drawPath(path, strokePaint);
    }

    canvas.drawPath(path, paint);

    canvas.save();
    canvas.translate(shift, -_distanceBetweenTopBottomCenters + neckStretch.dy);
    canvas.scale(inverseTextScale, inverseTextScale);
    labelPainter.paint(canvas,
        Offset.zero - Offset(labelHalfWidth, labelPainter.height / 2.0));
    canvas.restore();
    canvas.restore();
  }
}

typedef RangeSemanticFormatterCallback = String Function(RangeValues values);

typedef RangeThumbSelector = Thumb Function(
    TextDirection textDirection,
    RangeValues values,
    double tapValue,
    Size thumbSize,
    Size trackSize,
    double dx);

class RangeValues {
  const RangeValues(this.start, this.end);

  final double start;

  final double end;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    final RangeValues typedOther = other;
    return typedOther.start == start && typedOther.end == end;
  }

  @override
  int get hashCode => hashValues(start, end);

  @override
  String toString() {
    return '$runtimeType($start, $end)';
  }
}

class RangeLabels {
  const RangeLabels(this.start, this.end);

  final String start;

  final String end;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    final RangeLabels typedOther = other;
    return typedOther.start == start && typedOther.end == end;
  }

  @override
  int get hashCode => hashValues(start, end);

  @override
  String toString() {
    return '$runtimeType($start, $end)';
  }
}

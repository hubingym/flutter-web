import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_web/ui.dart' as ui;

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/gestures.dart';
import 'package:flutter_web/rendering.dart';
import 'package:flutter_web/scheduler.dart' show timeDilation;
import 'package:flutter_web/widgets.dart';

import 'constants.dart';
import 'debug.dart';
import 'slider_theme.dart';
import 'theme.dart';

class RangeSlider extends StatefulWidget {
  RangeSlider(
      {Key key,
      @required this.values,
      @required this.onChanged,
      this.onChangeStart,
      this.onChangeEnd,
      this.min = 0.0,
      this.max = 1.0,
      this.divisions,
      this.labels,
      this.activeColor,
      this.inactiveColor,
      this.semanticFormatterCallback})
      : assert(values != null),
        assert(min != null),
        assert(max != null),
        assert(min <= max),
        assert(values.start <= values.end),
        assert(values.start >= min && values.start <= max),
        assert(values.end >= min && values.end <= max),
        assert(divisions == null || divisions > 0),
        super(key: key);

  final RangeValues values;

  final ValueChanged<RangeValues> onChanged;

  final ValueChanged<RangeValues> onChangeStart;

  final ValueChanged<RangeValues> onChangeEnd;

  final double min;

  final double max;

  final int divisions;

  final RangeLabels labels;

  final Color activeColor;

  final Color inactiveColor;

  final RangeSemanticFormatterCallback semanticFormatterCallback;

  static const double _minTouchTargetWidth = 48;

  @override
  _RangeSliderState createState() => _RangeSliderState();
}

class _RangeSliderState extends State<RangeSlider>
    with TickerProviderStateMixin {
  static const Duration enableAnimationDuration = Duration(milliseconds: 75);
  static const Duration valueIndicatorAnimationDuration =
      Duration(milliseconds: 100);

  AnimationController overlayController;

  AnimationController valueIndicatorController;

  AnimationController enableController;

  AnimationController startPositionController;
  AnimationController endPositionController;
  Timer interactionTimer;

  @override
  void initState() {
    super.initState();
    overlayController = AnimationController(
      duration: kRadialReactionDuration,
      vsync: this,
    );
    valueIndicatorController = AnimationController(
      duration: valueIndicatorAnimationDuration,
      vsync: this,
    );
    enableController = AnimationController(
        duration: enableAnimationDuration,
        vsync: this,
        value: widget.onChanged != null ? 1.0 : 0.0);
    startPositionController = AnimationController(
        duration: Duration.zero,
        vsync: this,
        value: _unlerp(widget.values.start));
    endPositionController = AnimationController(
        duration: Duration.zero,
        vsync: this,
        value: _unlerp(widget.values.end));
  }

  @override
  void didUpdateWidget(RangeSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.onChanged == widget.onChanged) return;
    final bool wasEnabled = oldWidget.onChanged != null;
    final bool isEnabled = widget.onChanged != null;
    if (wasEnabled != isEnabled) {
      if (isEnabled) {
        enableController.forward();
      } else {
        enableController.reverse();
      }
    }
  }

  @override
  void dispose() {
    interactionTimer?.cancel();
    overlayController.dispose();
    valueIndicatorController.dispose();
    enableController.dispose();
    startPositionController.dispose();
    endPositionController.dispose();
    super.dispose();
  }

  void _handleChanged(RangeValues values) {
    assert(widget.onChanged != null);
    final RangeValues lerpValues = _lerpRangeValues(values);
    if (lerpValues != widget.values) {
      widget.onChanged(lerpValues);
    }
  }

  void _handleDragStart(RangeValues values) {
    assert(widget.onChangeStart != null);
    widget.onChangeStart(_lerpRangeValues(values));
  }

  void _handleDragEnd(RangeValues values) {
    assert(widget.onChangeEnd != null);
    widget.onChangeEnd(_lerpRangeValues(values));
  }

  double _lerp(double value) => ui.lerpDouble(widget.min, widget.max, value);

  RangeValues _lerpRangeValues(RangeValues values) {
    return RangeValues(_lerp(values.start), _lerp(values.end));
  }

  double _unlerp(double value) {
    assert(value <= widget.max);
    assert(value >= widget.min);
    return widget.max > widget.min
        ? (value - widget.min) / (widget.max - widget.min)
        : 0.0;
  }

  RangeValues _unlerpRangeValues(RangeValues values) {
    return RangeValues(_unlerp(values.start), _unlerp(values.end));
  }

  static final RangeThumbSelector _defaultRangeThumbSelector = (
    TextDirection textDirection,
    RangeValues values,
    double tapValue,
    Size thumbSize,
    Size trackSize,
    double dx,
  ) {
    final double touchRadius =
        math.max(thumbSize.width, RangeSlider._minTouchTargetWidth) / 2;
    final bool inStartTouchTarget =
        (tapValue - values.start).abs() * trackSize.width < touchRadius;
    final bool inEndTouchTarget =
        (tapValue - values.end).abs() * trackSize.width < touchRadius;

    if (inStartTouchTarget && inEndTouchTarget) {
      bool towardsStart;
      bool towardsEnd;
      switch (textDirection) {
        case TextDirection.ltr:
          towardsStart = dx < 0;
          towardsEnd = dx > 0;
          break;
        case TextDirection.rtl:
          towardsStart = dx > 0;
          towardsEnd = dx < 0;
          break;
      }
      if (towardsStart) return Thumb.start;
      if (towardsEnd) return Thumb.end;
    } else {
      if (tapValue < values.start || inStartTouchTarget) return Thumb.start;
      if (tapValue > values.end || inEndTouchTarget) return Thumb.end;
    }
    return null;
  };

  static const double _defaultTrackHeight = 2;
  static const RangeSliderTrackShape _defaultTrackShape =
      RoundedRectRangeSliderTrackShape();
  static const RangeSliderTickMarkShape _defaultTickMarkShape =
      RoundRangeSliderTickMarkShape();
  static const SliderComponentShape _defaultOverlayShape =
      RoundSliderOverlayShape();
  static const RangeSliderThumbShape _defaultThumbShape =
      RoundRangeSliderThumbShape();
  static const RangeSliderValueIndicatorShape _defaultValueIndicatorShape =
      PaddleRangeSliderValueIndicatorShape();
  static const ShowValueIndicator _defaultShowValueIndicator =
      ShowValueIndicator.onlyForDiscrete;
  static const double _defaultMinThumbSeparation = 8;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    assert(debugCheckHasMediaQuery(context));

    final ThemeData theme = Theme.of(context);
    SliderThemeData sliderTheme = SliderTheme.of(context);

    sliderTheme = sliderTheme.copyWith(
      trackHeight: sliderTheme.trackHeight ?? _defaultTrackHeight,
      activeTrackColor: widget.activeColor ??
          sliderTheme.activeTrackColor ??
          theme.colorScheme.primary,
      inactiveTrackColor: widget.inactiveColor ??
          sliderTheme.inactiveTrackColor ??
          theme.colorScheme.primary.withOpacity(0.24),
      disabledActiveTrackColor: sliderTheme.disabledActiveTrackColor ??
          theme.colorScheme.onSurface.withOpacity(0.32),
      disabledInactiveTrackColor: sliderTheme.disabledInactiveTrackColor ??
          theme.colorScheme.onSurface.withOpacity(0.12),
      activeTickMarkColor: widget.inactiveColor ??
          sliderTheme.activeTickMarkColor ??
          theme.colorScheme.onPrimary.withOpacity(0.54),
      inactiveTickMarkColor: widget.activeColor ??
          sliderTheme.inactiveTickMarkColor ??
          theme.colorScheme.primary.withOpacity(0.54),
      disabledActiveTickMarkColor: sliderTheme.disabledActiveTickMarkColor ??
          theme.colorScheme.onPrimary.withOpacity(0.12),
      disabledInactiveTickMarkColor:
          sliderTheme.disabledInactiveTickMarkColor ??
              theme.colorScheme.onSurface.withOpacity(0.12),
      thumbColor: widget.activeColor ??
          sliderTheme.thumbColor ??
          theme.colorScheme.primary,
      overlappingShapeStrokeColor:
          sliderTheme.overlappingShapeStrokeColor ?? theme.colorScheme.surface,
      disabledThumbColor: sliderTheme.disabledThumbColor ??
          theme.colorScheme.onSurface.withOpacity(0.38),
      overlayColor: widget.activeColor?.withOpacity(0.12) ??
          sliderTheme.overlayColor ??
          theme.colorScheme.primary.withOpacity(0.12),
      valueIndicatorColor: widget.activeColor ??
          sliderTheme.valueIndicatorColor ??
          theme.colorScheme.primary,
      rangeTrackShape: sliderTheme.rangeTrackShape ?? _defaultTrackShape,
      rangeTickMarkShape:
          sliderTheme.rangeTickMarkShape ?? _defaultTickMarkShape,
      rangeThumbShape: sliderTheme.rangeThumbShape ?? _defaultThumbShape,
      overlayShape: sliderTheme.overlayShape ?? _defaultOverlayShape,
      rangeValueIndicatorShape:
          sliderTheme.rangeValueIndicatorShape ?? _defaultValueIndicatorShape,
      showValueIndicator:
          sliderTheme.showValueIndicator ?? _defaultShowValueIndicator,
      valueIndicatorTextStyle: sliderTheme.valueIndicatorTextStyle ??
          theme.textTheme.body2.copyWith(
            color: theme.colorScheme.onPrimary,
          ),
      minThumbSeparation:
          sliderTheme.minThumbSeparation ?? _defaultMinThumbSeparation,
      thumbSelector: sliderTheme.thumbSelector ?? _defaultRangeThumbSelector,
    );

    return _RangeSliderRenderObjectWidget(
      values: _unlerpRangeValues(widget.values),
      divisions: widget.divisions,
      labels: widget.labels,
      sliderTheme: sliderTheme,
      textScaleFactor: MediaQuery.of(context).textScaleFactor,
      onChanged: (widget.onChanged != null) && (widget.max > widget.min)
          ? _handleChanged
          : null,
      onChangeStart: widget.onChangeStart != null ? _handleDragStart : null,
      onChangeEnd: widget.onChangeEnd != null ? _handleDragEnd : null,
      state: this,
      semanticFormatterCallback: widget.semanticFormatterCallback,
    );
  }
}

class _RangeSliderRenderObjectWidget extends LeafRenderObjectWidget {
  const _RangeSliderRenderObjectWidget({
    Key key,
    this.values,
    this.divisions,
    this.labels,
    this.sliderTheme,
    this.textScaleFactor,
    this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.state,
    this.semanticFormatterCallback,
  }) : super(key: key);

  final RangeValues values;
  final int divisions;
  final RangeLabels labels;
  final SliderThemeData sliderTheme;
  final double textScaleFactor;
  final ValueChanged<RangeValues> onChanged;
  final ValueChanged<RangeValues> onChangeStart;
  final ValueChanged<RangeValues> onChangeEnd;
  final RangeSemanticFormatterCallback semanticFormatterCallback;
  final _RangeSliderState state;

  @override
  _RenderRangeSlider createRenderObject(BuildContext context) {
    return _RenderRangeSlider(
      values: values,
      divisions: divisions,
      labels: labels,
      sliderTheme: sliderTheme,
      theme: Theme.of(context),
      textScaleFactor: textScaleFactor,
      onChanged: onChanged,
      onChangeStart: onChangeStart,
      onChangeEnd: onChangeEnd,
      state: state,
      textDirection: Directionality.of(context),
      semanticFormatterCallback: semanticFormatterCallback,
      platform: Theme.of(context).platform,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, _RenderRangeSlider renderObject) {
    renderObject
      ..values = values
      ..divisions = divisions
      ..labels = labels
      ..sliderTheme = sliderTheme
      ..theme = Theme.of(context)
      ..textScaleFactor = textScaleFactor
      ..onChanged = onChanged
      ..onChangeStart = onChangeStart
      ..onChangeEnd = onChangeEnd
      ..textDirection = Directionality.of(context)
      ..semanticFormatterCallback = semanticFormatterCallback
      ..platform = Theme.of(context).platform;
  }
}

class _RenderRangeSlider extends RenderBox {
  _RenderRangeSlider({
    @required RangeValues values,
    int divisions,
    RangeLabels labels,
    SliderThemeData sliderTheme,
    ThemeData theme,
    double textScaleFactor,
    TargetPlatform platform,
    ValueChanged<RangeValues> onChanged,
    RangeSemanticFormatterCallback semanticFormatterCallback,
    this.onChangeStart,
    this.onChangeEnd,
    @required _RangeSliderState state,
    @required TextDirection textDirection,
  })  : assert(values != null),
        assert(values.start >= 0.0 && values.start <= 1.0),
        assert(values.end >= 0.0 && values.end <= 1.0),
        assert(state != null),
        assert(textDirection != null),
        _platform = platform,
        _semanticFormatterCallback = semanticFormatterCallback,
        _labels = labels,
        _values = values,
        _divisions = divisions,
        _sliderTheme = sliderTheme,
        _theme = theme,
        _textScaleFactor = textScaleFactor,
        _onChanged = onChanged,
        _state = state,
        _textDirection = textDirection {
    _updateLabelPainters();
    final GestureArenaTeam team = GestureArenaTeam();
    _drag = HorizontalDragGestureRecognizer()
      ..team = team
      ..onStart = _handleDragStart
      ..onUpdate = _handleDragUpdate
      ..onEnd = _handleDragEnd
      ..onCancel = _handleDragCancel;
    _tap = TapGestureRecognizer()
      ..team = team
      ..onTapDown = _handleTapDown
      ..onTapUp = _handleTapUp
      ..onTapCancel = _handleTapCancel;
    _overlayAnimation = CurvedAnimation(
      parent: _state.overlayController,
      curve: Curves.fastOutSlowIn,
    );
    _valueIndicatorAnimation = CurvedAnimation(
      parent: _state.valueIndicatorController,
      curve: Curves.fastOutSlowIn,
    );
    _enableAnimation = CurvedAnimation(
      parent: _state.enableController,
      curve: Curves.easeInOut,
    );
  }

  Thumb _lastThumbSelection;

  static const Duration _positionAnimationDuration = Duration(milliseconds: 75);

  static const double _minPreferredTrackWidth = 144.0;

  double get _maxSliderPartWidth =>
      _sliderPartSizes.map((Size size) => size.width).reduce(math.max);
  double get _maxSliderPartHeight =>
      _sliderPartSizes.map((Size size) => size.height).reduce(math.max);
  List<Size> get _sliderPartSizes => <Size>[
        _sliderTheme.overlayShape.getPreferredSize(isEnabled, isDiscrete),
        _sliderTheme.rangeThumbShape.getPreferredSize(isEnabled, isDiscrete),
        _sliderTheme.rangeTickMarkShape
            .getPreferredSize(isEnabled: isEnabled, sliderTheme: sliderTheme),
      ];
  double get _minPreferredTrackHeight => _sliderTheme.trackHeight;

  Rect get _trackRect => _sliderTheme.rangeTrackShape.getPreferredRect(
        parentBox: this,
        offset: Offset.zero,
        sliderTheme: _sliderTheme,
        isDiscrete: false,
      );

  static const Duration _minimumInteractionTime = Duration(milliseconds: 500);

  final _RangeSliderState _state;
  Animation<double> _overlayAnimation;
  Animation<double> _valueIndicatorAnimation;
  Animation<double> _enableAnimation;
  final TextPainter _startLabelPainter = TextPainter();
  final TextPainter _endLabelPainter = TextPainter();
  HorizontalDragGestureRecognizer _drag;
  TapGestureRecognizer _tap;
  bool _active = false;
  RangeValues _newValues;

  bool get isEnabled => onChanged != null;

  bool get isDiscrete => divisions != null && divisions > 0;

  RangeValues get values => _values;
  RangeValues _values;
  set values(RangeValues newValues) {
    assert(newValues != null);
    assert(newValues.start != null &&
        newValues.start >= 0.0 &&
        newValues.start <= 1.0);
    assert(
        newValues.end != null && newValues.end >= 0.0 && newValues.end <= 1.0);
    assert(newValues.start <= newValues.end);
    final RangeValues convertedValues =
        isDiscrete ? _discretizeRangeValues(newValues) : newValues;
    if (convertedValues == _values) {
      return;
    }
    _values = convertedValues;
    if (isDiscrete) {
      final double startDistance =
          (_values.start - _state.startPositionController.value).abs();
      _state.startPositionController.duration = startDistance != 0.0
          ? _positionAnimationDuration * (1.0 / startDistance)
          : Duration.zero;
      _state.startPositionController
          .animateTo(_values.start, curve: Curves.easeInOut);
      final double endDistance =
          (_values.end - _state.endPositionController.value).abs();
      _state.endPositionController.duration = endDistance != 0.0
          ? _positionAnimationDuration * (1.0 / endDistance)
          : Duration.zero;
      _state.endPositionController
          .animateTo(_values.end, curve: Curves.easeInOut);
    } else {
      _state.startPositionController.value = convertedValues.start;
      _state.endPositionController.value = convertedValues.end;
    }
    markNeedsSemanticsUpdate();
  }

  TargetPlatform _platform;
  TargetPlatform get platform => _platform;
  set platform(TargetPlatform value) {
    if (_platform == value) return;
    _platform = value;
    markNeedsSemanticsUpdate();
  }

  RangeSemanticFormatterCallback _semanticFormatterCallback;
  RangeSemanticFormatterCallback get semanticFormatterCallback =>
      _semanticFormatterCallback;
  set semanticFormatterCallback(RangeSemanticFormatterCallback value) {
    if (_semanticFormatterCallback == value) return;
    _semanticFormatterCallback = value;
    markNeedsSemanticsUpdate();
  }

  int get divisions => _divisions;
  int _divisions;
  set divisions(int value) {
    if (value == _divisions) {
      return;
    }
    _divisions = value;
    markNeedsPaint();
  }

  RangeLabels get labels => _labels;
  RangeLabels _labels;
  set labels(RangeLabels labels) {
    if (labels == _labels) return;
    _labels = labels;
    _updateLabelPainters();
  }

  SliderThemeData get sliderTheme => _sliderTheme;
  SliderThemeData _sliderTheme;
  set sliderTheme(SliderThemeData value) {
    if (value == _sliderTheme) return;
    _sliderTheme = value;
    markNeedsPaint();
  }

  ThemeData get theme => _theme;
  ThemeData _theme;
  set theme(ThemeData value) {
    if (value == _theme) return;
    _theme = value;
    markNeedsPaint();
  }

  double get textScaleFactor => _textScaleFactor;
  double _textScaleFactor;
  set textScaleFactor(double value) {
    if (value == _textScaleFactor) return;
    _textScaleFactor = value;
    _updateLabelPainters();
  }

  ValueChanged<RangeValues> get onChanged => _onChanged;
  ValueChanged<RangeValues> _onChanged;
  set onChanged(ValueChanged<RangeValues> value) {
    if (value == _onChanged) return;
    final bool wasEnabled = isEnabled;
    _onChanged = value;
    if (wasEnabled != isEnabled) {
      markNeedsPaint();
      markNeedsSemanticsUpdate();
    }
  }

  ValueChanged<RangeValues> onChangeStart;
  ValueChanged<RangeValues> onChangeEnd;

  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    assert(value != null);
    if (value == _textDirection) return;
    _textDirection = value;
    _updateLabelPainters();
  }

  bool get showValueIndicator {
    bool showValueIndicator;
    switch (_sliderTheme.showValueIndicator) {
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
    return showValueIndicator;
  }

  Size get _thumbSize =>
      _sliderTheme.rangeThumbShape.getPreferredSize(isEnabled, isDiscrete);

  double get _adjustmentUnit {
    switch (_platform) {
      case TargetPlatform.iOS:
        return 0.1;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      default:
        return 0.05;
    }
  }

  void _updateLabelPainters() {
    _updateLabelPainter(Thumb.start);
    _updateLabelPainter(Thumb.end);
  }

  void _updateLabelPainter(Thumb thumb) {
    if (labels == null) return;

    String text;
    TextPainter labelPainter;
    switch (thumb) {
      case Thumb.start:
        text = labels.start;
        labelPainter = _startLabelPainter;
        break;
      case Thumb.end:
        text = labels.end;
        labelPainter = _endLabelPainter;
        break;
    }

    if (labels != null) {
      labelPainter
        ..text = TextSpan(
          style: _sliderTheme.valueIndicatorTextStyle,
          text: text,
        )
        ..textDirection = textDirection
        ..textScaleFactor = textScaleFactor
        ..layout();
    } else {
      labelPainter.text = null;
    }

    markNeedsLayout();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _overlayAnimation.addListener(markNeedsPaint);
    _valueIndicatorAnimation.addListener(markNeedsPaint);
    _enableAnimation.addListener(markNeedsPaint);
    _state.startPositionController.addListener(markNeedsPaint);
    _state.endPositionController.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _overlayAnimation.removeListener(markNeedsPaint);
    _valueIndicatorAnimation.removeListener(markNeedsPaint);
    _enableAnimation.removeListener(markNeedsPaint);
    _state.startPositionController.removeListener(markNeedsPaint);
    _state.endPositionController.removeListener(markNeedsPaint);
    super.detach();
  }

  double _getValueFromVisualPosition(double visualPosition) {
    switch (textDirection) {
      case TextDirection.rtl:
        return 1.0 - visualPosition;
      case TextDirection.ltr:
        return visualPosition;
    }
    return null;
  }

  double _getValueFromGlobalPosition(Offset globalPosition) {
    final double visualPosition =
        (globalToLocal(globalPosition).dx - _trackRect.left) / _trackRect.width;
    return _getValueFromVisualPosition(visualPosition);
  }

  double _discretize(double value) {
    double result = value.clamp(0.0, 1.0);
    if (isDiscrete) {
      result = (result * divisions).round() / divisions;
    }
    return result;
  }

  RangeValues _discretizeRangeValues(RangeValues values) {
    return RangeValues(_discretize(values.start), _discretize(values.end));
  }

  void _startInteraction(Offset globalPosition) {
    final double tapValue =
        _getValueFromGlobalPosition(globalPosition).clamp(0.0, 1.0);
    _lastThumbSelection = sliderTheme.thumbSelector(
        textDirection, values, tapValue, _thumbSize, size, 0);

    if (_lastThumbSelection != null) {
      _active = true;

      final RangeValues currentValues = _discretizeRangeValues(values);
      if (_lastThumbSelection == Thumb.start) {
        _newValues = RangeValues(tapValue, currentValues.end);
      } else if (_lastThumbSelection == Thumb.end) {
        _newValues = RangeValues(currentValues.start, tapValue);
      }
      _updateLabelPainter(_lastThumbSelection);

      if (onChangeStart != null) {
        onChangeStart(currentValues);
      }

      onChanged(_discretizeRangeValues(_newValues));

      _state.overlayController.forward();
      if (showValueIndicator) {
        _state.valueIndicatorController.forward();
        _state.interactionTimer?.cancel();
        _state.interactionTimer =
            Timer(_minimumInteractionTime * timeDilation, () {
          _state.interactionTimer = null;
          if (!_active &&
              _state.valueIndicatorController.status ==
                  AnimationStatus.completed) {
            _state.valueIndicatorController.reverse();
          }
        });
      }
    }
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final double dragValue =
        _getValueFromGlobalPosition(details.globalPosition);

    bool shouldCallOnChangeStart = false;
    if (_lastThumbSelection == null) {
      _lastThumbSelection = sliderTheme.thumbSelector(
          textDirection, values, dragValue, _thumbSize, size, details.delta.dx);
      if (_lastThumbSelection != null) {
        shouldCallOnChangeStart = true;
        _active = true;
        _state.overlayController.forward();
        if (showValueIndicator) {
          _state.valueIndicatorController.forward();
        }
      }
    }

    if (isEnabled && _lastThumbSelection != null) {
      final RangeValues currentValues = _discretizeRangeValues(values);
      if (onChangeStart != null && shouldCallOnChangeStart) {
        onChangeStart(currentValues);
      }
      final double currentDragValue = _discretize(dragValue);

      final double minThumbSeparationValue =
          isDiscrete ? 0 : sliderTheme.minThumbSeparation / _trackRect.width;
      if (_lastThumbSelection == Thumb.start) {
        _newValues = RangeValues(
            math.min(
                currentDragValue, currentValues.end - minThumbSeparationValue),
            currentValues.end);
      } else if (_lastThumbSelection == Thumb.end) {
        _newValues = RangeValues(
            currentValues.start,
            math.max(currentDragValue,
                currentValues.start + minThumbSeparationValue));
      }
      onChanged(_newValues);
    }
  }

  void _endInteraction() {
    _state.overlayController.reverse();
    if (showValueIndicator && _state.interactionTimer == null) {
      _state.valueIndicatorController.reverse();
    }

    if (_active && _state.mounted && _lastThumbSelection != null) {
      final RangeValues discreteValues = _discretizeRangeValues(_newValues);
      if (onChangeEnd != null) {
        onChangeEnd(discreteValues);
      }
      _active = false;
    }
  }

  void _handleDragStart(DragStartDetails details) {
    _startInteraction(details.globalPosition);
  }

  void _handleDragEnd(DragEndDetails details) {
    _endInteraction();
  }

  void _handleDragCancel() {
    _endInteraction();
  }

  void _handleTapDown(TapDownDetails details) {
    _startInteraction(details.globalPosition);
  }

  void _handleTapUp(TapUpDetails details) {
    _endInteraction();
  }

  void _handleTapCancel() {
    _endInteraction();
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void handleEvent(PointerEvent event, HitTestEntry entry) {
    assert(debugHandleEvent(event, entry));
    if (event is PointerDownEvent && isEnabled) {
      _drag.addPointer(event);
      _tap.addPointer(event);
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      _minPreferredTrackWidth + _maxSliderPartWidth;

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _minPreferredTrackWidth + _maxSliderPartWidth;

  @override
  double computeMinIntrinsicHeight(double width) =>
      math.max(_minPreferredTrackHeight, _maxSliderPartHeight);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      math.max(_minPreferredTrackHeight, _maxSliderPartHeight);

  @override
  bool get sizedByParent => true;

  @override
  void performResize() {
    size = Size(
      constraints.hasBoundedWidth
          ? constraints.maxWidth
          : _minPreferredTrackWidth + _maxSliderPartWidth,
      constraints.hasBoundedHeight
          ? constraints.maxHeight
          : math.max(_minPreferredTrackHeight, _maxSliderPartHeight),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final double startValue = _state.startPositionController.value;
    final double endValue = _state.endPositionController.value;

    double startVisualPosition;
    double endVisualPosition;
    switch (textDirection) {
      case TextDirection.rtl:
        startVisualPosition = 1.0 - startValue;
        endVisualPosition = 1.0 - endValue;
        break;
      case TextDirection.ltr:
        startVisualPosition = startValue;
        endVisualPosition = endValue;
        break;
    }

    final Rect trackRect = _sliderTheme.rangeTrackShape.getPreferredRect(
        parentBox: this,
        offset: offset,
        sliderTheme: _sliderTheme,
        isDiscrete: isDiscrete);
    final Offset startThumbCenter = Offset(
        trackRect.left + startVisualPosition * trackRect.width,
        trackRect.center.dy);
    final Offset endThumbCenter = Offset(
        trackRect.left + endVisualPosition * trackRect.width,
        trackRect.center.dy);

    _sliderTheme.rangeTrackShape.paint(context, offset,
        parentBox: this,
        sliderTheme: _sliderTheme,
        enableAnimation: _enableAnimation,
        textDirection: _textDirection,
        startThumbCenter: startThumbCenter,
        endThumbCenter: endThumbCenter,
        isDiscrete: isDiscrete,
        isEnabled: isEnabled);

    if (!_overlayAnimation.isDismissed) {
      if (_lastThumbSelection == Thumb.start) {
        _sliderTheme.overlayShape.paint(
          context,
          startThumbCenter,
          activationAnimation: _overlayAnimation,
          enableAnimation: _enableAnimation,
          isDiscrete: isDiscrete,
          labelPainter: _startLabelPainter,
          parentBox: this,
          sliderTheme: _sliderTheme,
          textDirection: _textDirection,
          value: startValue,
        );
      }
      if (_lastThumbSelection == Thumb.end) {
        _sliderTheme.overlayShape.paint(
          context,
          endThumbCenter,
          activationAnimation: _overlayAnimation,
          enableAnimation: _enableAnimation,
          isDiscrete: isDiscrete,
          labelPainter: _endLabelPainter,
          parentBox: this,
          sliderTheme: _sliderTheme,
          textDirection: _textDirection,
          value: endValue,
        );
      }
    }

    if (isDiscrete) {
      final double tickMarkWidth = _sliderTheme.rangeTickMarkShape
          .getPreferredSize(
            isEnabled: isEnabled,
            sliderTheme: _sliderTheme,
          )
          .width;
      final double adjustedTrackWidth = trackRect.width - tickMarkWidth;

      if (adjustedTrackWidth / divisions >= 3.0 * tickMarkWidth) {
        final double dy = trackRect.center.dy;
        for (int i = 0; i <= divisions; i++) {
          final double value = i / divisions;

          final double dx =
              trackRect.left + value * adjustedTrackWidth + tickMarkWidth / 2;
          final Offset tickMarkOffset = Offset(dx, dy);
          _sliderTheme.rangeTickMarkShape.paint(
            context,
            tickMarkOffset,
            parentBox: this,
            sliderTheme: _sliderTheme,
            enableAnimation: _enableAnimation,
            textDirection: _textDirection,
            startThumbCenter: startThumbCenter,
            endThumbCenter: endThumbCenter,
            isEnabled: isEnabled,
          );
        }
      }
    }

    final double thumbDelta = (endThumbCenter.dx - startThumbCenter.dx).abs();

    final bool isLastThumbStart = _lastThumbSelection == Thumb.start;
    final Thumb bottomThumb = isLastThumbStart ? Thumb.end : Thumb.start;
    final Thumb topThumb = isLastThumbStart ? Thumb.start : Thumb.end;
    final Offset bottomThumbCenter =
        isLastThumbStart ? endThumbCenter : startThumbCenter;
    final Offset topThumbCenter =
        isLastThumbStart ? startThumbCenter : endThumbCenter;
    final TextPainter bottomLabelPainter =
        isLastThumbStart ? _endLabelPainter : _startLabelPainter;
    final TextPainter topLabelPainter =
        isLastThumbStart ? _startLabelPainter : _endLabelPainter;
    final double bottomValue = isLastThumbStart ? endValue : startValue;
    final double topValue = isLastThumbStart ? startValue : endValue;

    if (isEnabled &&
        labels != null &&
        !_valueIndicatorAnimation.isDismissed &&
        showValueIndicator) {
      _sliderTheme.rangeValueIndicatorShape.paint(
        context,
        bottomThumbCenter,
        activationAnimation: _valueIndicatorAnimation,
        enableAnimation: _enableAnimation,
        isDiscrete: isDiscrete,
        isOnTop: false,
        labelPainter: bottomLabelPainter,
        parentBox: this,
        sliderTheme: _sliderTheme,
        textDirection: _textDirection,
        thumb: bottomThumb,
        value: bottomValue,
      );
      _sliderTheme.rangeValueIndicatorShape.paint(
        context,
        topThumbCenter,
        activationAnimation: _valueIndicatorAnimation,
        enableAnimation: _enableAnimation,
        isDiscrete: isDiscrete,
        isOnTop: thumbDelta <
            sliderTheme.rangeValueIndicatorShape
                .getPreferredSize(isEnabled, isDiscrete,
                    labelPainter: topLabelPainter)
                .width,
        labelPainter: topLabelPainter,
        parentBox: this,
        sliderTheme: _sliderTheme,
        textDirection: _textDirection,
        thumb: topThumb,
        value: topValue,
      );
    }

    _sliderTheme.rangeThumbShape.paint(
      context,
      bottomThumbCenter,
      activationAnimation: _valueIndicatorAnimation,
      enableAnimation: _enableAnimation,
      isDiscrete: isDiscrete,
      isOnTop: false,
      textDirection: textDirection,
      sliderTheme: _sliderTheme,
      thumb: bottomThumb,
    );
    _sliderTheme.rangeThumbShape.paint(
      context,
      topThumbCenter,
      activationAnimation: _valueIndicatorAnimation,
      enableAnimation: _enableAnimation,
      isDiscrete: isDiscrete,
      isOnTop: thumbDelta <
          sliderTheme.rangeThumbShape
              .getPreferredSize(isEnabled, isDiscrete)
              .width,
      textDirection: textDirection,
      sliderTheme: _sliderTheme,
      thumb: topThumb,
    );
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);

    config.isSemanticBoundary = isEnabled;
    if (isEnabled) {
      config.textDirection = textDirection;
      config.customSemanticsActions = <CustomSemanticsAction, VoidCallback>{
        _decreaseStart: _decreaseStartAction,
        _increaseStart: _increaseStartAction,
        _decreaseEnd: _decreaseEndAction,
        _increaseEnd: _increaseEndAction,
      };
      if (semanticFormatterCallback != null) {
        config.value =
            semanticFormatterCallback(_state._lerpRangeValues(values));
      } else {
        config.value = values.toString();
      }
    }
  }

  final CustomSemanticsAction _decreaseStart =
      const CustomSemanticsAction(label: 'Decrease Min');
  final CustomSemanticsAction _increaseStart =
      const CustomSemanticsAction(label: 'Increase Min');
  final CustomSemanticsAction _decreaseEnd =
      const CustomSemanticsAction(label: 'Decrease Max');
  final CustomSemanticsAction _increaseEnd =
      const CustomSemanticsAction(label: 'Increase Max');

  double get _semanticActionUnit =>
      divisions != null ? 1.0 / divisions : _adjustmentUnit;

  void _increaseStartAction() {
    if (isEnabled) {
      onChanged(RangeValues(_increaseValue(values.start), values.end));
    }
  }

  void _decreaseStartAction() {
    if (isEnabled) {
      onChanged(RangeValues(_decreaseValue(values.start), values.end));
    }
  }

  void _increaseEndAction() {
    if (isEnabled) {
      onChanged(RangeValues(values.start, _increaseValue(values.end)));
    }
  }

  void _decreaseEndAction() {
    if (isEnabled) {
      onChanged(RangeValues(values.start, _decreaseValue(values.end)));
    }
  }

  double _increaseValue(double value) {
    return (value + _semanticActionUnit).clamp(0.0, 1.0);
  }

  double _decreaseValue(double value) {
    return (value - _semanticActionUnit).clamp(0.0, 1.0);
  }
}

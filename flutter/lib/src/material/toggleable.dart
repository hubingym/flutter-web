import 'package:flutter_web/animation.dart';
import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/gestures.dart';
import 'package:flutter_web/rendering.dart';
import 'package:flutter_web/scheduler.dart';

import 'constants.dart';

const Duration _kToggleDuration = Duration(milliseconds: 200);
final Tween<double> _kRadialReactionRadiusTween =
    Tween<double>(begin: 0.0, end: kRadialReactionRadius);

abstract class RenderToggleable extends RenderConstrainedBox {
  RenderToggleable({
    @required bool value,
    bool tristate = false,
    @required Color activeColor,
    @required Color inactiveColor,
    ValueChanged<bool> onChanged,
    BoxConstraints additionalConstraints,
    @required TickerProvider vsync,
  })  : assert(tristate != null),
        assert(tristate || value != null),
        assert(activeColor != null),
        assert(inactiveColor != null),
        assert(vsync != null),
        _value = value,
        _tristate = tristate,
        _activeColor = activeColor,
        _inactiveColor = inactiveColor,
        _onChanged = onChanged,
        _vsync = vsync,
        super(additionalConstraints: additionalConstraints) {
    _tap = TapGestureRecognizer()
      ..onTapDown = _handleTapDown
      ..onTap = _handleTap
      ..onTapUp = _handleTapUp
      ..onTapCancel = _handleTapCancel;
    _positionController = AnimationController(
      duration: _kToggleDuration,
      value: value == false ? 0.0 : 1.0,
      vsync: vsync,
    );
    _position = CurvedAnimation(
      parent: _positionController,
      curve: Curves.linear,
    )
      ..addListener(markNeedsPaint)
      ..addStatusListener(_handlePositionStateChanged);
    _reactionController = AnimationController(
      duration: kRadialReactionDuration,
      vsync: vsync,
    );
    _reaction = CurvedAnimation(
      parent: _reactionController,
      curve: Curves.fastOutSlowIn,
    )..addListener(markNeedsPaint);
  }

  @protected
  AnimationController get positionController => _positionController;
  AnimationController _positionController;

  CurvedAnimation get position => _position;
  CurvedAnimation _position;

  @protected
  AnimationController get reactionController => _reactionController;
  AnimationController _reactionController;
  Animation<double> _reaction;

  TickerProvider get vsync => _vsync;
  TickerProvider _vsync;
  set vsync(TickerProvider value) {
    assert(value != null);
    if (value == _vsync) return;
    _vsync = value;
    positionController.resync(vsync);
    reactionController.resync(vsync);
  }

  bool get value => _value;
  bool _value;
  set value(bool value) {
    assert(tristate || value != null);
    if (value == _value) return;
    _value = value;
    markNeedsSemanticsUpdate();
    _position
      ..curve = Curves.easeIn
      ..reverseCurve = Curves.easeOut;
    if (tristate) {
      switch (_positionController.status) {
        case AnimationStatus.forward:
        case AnimationStatus.completed:
          _positionController.reverse();
          break;
        default:
          _positionController.forward();
      }
    } else {
      if (value == true)
        _positionController.forward();
      else
        _positionController.reverse();
    }
  }

  bool get tristate => _tristate;
  bool _tristate;
  set tristate(bool value) {
    assert(tristate != null);
    if (value == _tristate) return;
    _tristate = value;
    markNeedsSemanticsUpdate();
  }

  Color get activeColor => _activeColor;
  Color _activeColor;
  set activeColor(Color value) {
    assert(value != null);
    if (value == _activeColor) return;
    _activeColor = value;
    markNeedsPaint();
  }

  Color get inactiveColor => _inactiveColor;
  Color _inactiveColor;
  set inactiveColor(Color value) {
    assert(value != null);
    if (value == _inactiveColor) return;
    _inactiveColor = value;
    markNeedsPaint();
  }

  ValueChanged<bool> get onChanged => _onChanged;
  ValueChanged<bool> _onChanged;
  set onChanged(ValueChanged<bool> value) {
    if (value == _onChanged) return;
    final bool wasInteractive = isInteractive;
    _onChanged = value;
    if (wasInteractive != isInteractive) {
      markNeedsPaint();
      markNeedsSemanticsUpdate();
    }
  }

  bool get isInteractive => onChanged != null;

  TapGestureRecognizer _tap;
  Offset _downPosition;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    if (value == false)
      _positionController.reverse();
    else
      _positionController.forward();
    if (isInteractive) {
      switch (_reactionController.status) {
        case AnimationStatus.forward:
          _reactionController.forward();
          break;
        case AnimationStatus.reverse:
          _reactionController.reverse();
          break;
        case AnimationStatus.dismissed:
        case AnimationStatus.completed:
          break;
      }
    }
  }

  @override
  void detach() {
    _positionController.stop();
    _reactionController.stop();
    super.detach();
  }

  void _handlePositionStateChanged(AnimationStatus status) {
    if (isInteractive && !tristate) {
      if (status == AnimationStatus.completed && _value == false) {
        onChanged(true);
      } else if (status == AnimationStatus.dismissed && _value != false) {
        onChanged(false);
      }
    }
  }

  void _handleTapDown(TapDownDetails details) {
    if (isInteractive) {
      _downPosition = globalToLocal(details.globalPosition);
      _reactionController.forward();
    }
  }

  void _handleTap() {
    if (!isInteractive) return;
    switch (value) {
      case false:
        onChanged(true);
        break;
      case true:
        onChanged(tristate ? null : false);
        break;
      default:
        onChanged(false);
        break;
    }
    sendSemanticsEvent(const TapSemanticEvent());
  }

  void _handleTapUp(TapUpDetails details) {
    _downPosition = null;
    if (isInteractive) _reactionController.reverse();
  }

  void _handleTapCancel() {
    _downPosition = null;
    if (isInteractive) _reactionController.reverse();
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    assert(debugHandleEvent(event, entry));
    if (event is PointerDownEvent && isInteractive) _tap.addPointer(event);
  }

  void paintRadialReaction(Canvas canvas, Offset offset, Offset origin) {
    if (!_reaction.isDismissed) {
      final Paint reactionPaint = Paint()
        ..color = activeColor.withAlpha(kRadialReactionAlpha);
      final Offset center =
          Offset.lerp(_downPosition ?? origin, origin, _reaction.value);
      final double radius = _kRadialReactionRadiusTween.evaluate(_reaction);
      canvas.drawCircle(center + offset, radius, reactionPaint);
    }
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);

    config.isEnabled = isInteractive;
    if (isInteractive) config.onTap = _handleTap;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagProperty('value',
        value: value, ifTrue: 'checked', ifFalse: 'unchecked', showName: true));
    properties.add(FlagProperty('isInteractive',
        value: isInteractive,
        ifTrue: 'enabled',
        ifFalse: 'disabled',
        defaultValue: true));
  }
}

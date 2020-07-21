import 'package:flutter_web/rendering.dart';

import 'animated_size.dart';
import 'basic.dart';
import 'framework.dart';
import 'ticker_provider.dart';
import 'transitions.dart';

enum CrossFadeState {
  showFirst,

  showSecond,
}

typedef AnimatedCrossFadeBuilder = Widget Function(
    Widget topChild, Key topChildKey, Widget bottomChild, Key bottomChildKey);

class AnimatedCrossFade extends StatefulWidget {
  const AnimatedCrossFade({
    Key key,
    @required this.firstChild,
    @required this.secondChild,
    this.firstCurve = Curves.linear,
    this.secondCurve = Curves.linear,
    this.sizeCurve = Curves.linear,
    this.alignment = Alignment.topCenter,
    @required this.crossFadeState,
    @required this.duration,
    this.reverseDuration,
    this.layoutBuilder = defaultLayoutBuilder,
  })  : assert(firstChild != null),
        assert(secondChild != null),
        assert(firstCurve != null),
        assert(secondCurve != null),
        assert(sizeCurve != null),
        assert(alignment != null),
        assert(crossFadeState != null),
        assert(duration != null),
        assert(layoutBuilder != null),
        super(key: key);

  final Widget firstChild;

  final Widget secondChild;

  final CrossFadeState crossFadeState;

  final Duration duration;

  final Duration reverseDuration;

  final Curve firstCurve;

  final Curve secondCurve;

  final Curve sizeCurve;

  final AlignmentGeometry alignment;

  final AnimatedCrossFadeBuilder layoutBuilder;

  static Widget defaultLayoutBuilder(Widget topChild, Key topChildKey,
      Widget bottomChild, Key bottomChildKey) {
    return Stack(
      overflow: Overflow.visible,
      children: <Widget>[
        Positioned(
          key: bottomChildKey,
          left: 0.0,
          top: 0.0,
          right: 0.0,
          child: bottomChild,
        ),
        Positioned(
          key: topChildKey,
          child: topChild,
        ),
      ],
    );
  }

  @override
  _AnimatedCrossFadeState createState() => _AnimatedCrossFadeState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(EnumProperty<CrossFadeState>('crossFadeState', crossFadeState));
    properties.add(DiagnosticsProperty<AlignmentGeometry>(
        'alignment', alignment,
        defaultValue: Alignment.topCenter));
    properties
        .add(IntProperty('duration', duration.inMilliseconds, unit: 'ms'));
    properties.add(IntProperty(
        'reverseDuration', reverseDuration?.inMilliseconds,
        unit: 'ms', defaultValue: null));
  }
}

class _AnimatedCrossFadeState extends State<AnimatedCrossFade>
    with TickerProviderStateMixin {
  AnimationController _controller;
  Animation<double> _firstAnimation;
  Animation<double> _secondAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      reverseDuration: widget.reverseDuration,
      vsync: this,
    );
    if (widget.crossFadeState == CrossFadeState.showSecond)
      _controller.value = 1.0;
    _firstAnimation = _initAnimation(widget.firstCurve, true);
    _secondAnimation = _initAnimation(widget.secondCurve, false);
    _controller.addStatusListener((AnimationStatus status) {
      setState(() {});
    });
  }

  Animation<double> _initAnimation(Curve curve, bool inverted) {
    Animation<double> result = _controller.drive(CurveTween(curve: curve));
    if (inverted) result = result.drive(Tween<double>(begin: 1.0, end: 0.0));
    return result;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AnimatedCrossFade oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.duration != oldWidget.duration)
      _controller.duration = widget.duration;
    if (widget.reverseDuration != oldWidget.reverseDuration)
      _controller.reverseDuration = widget.reverseDuration;
    if (widget.firstCurve != oldWidget.firstCurve)
      _firstAnimation = _initAnimation(widget.firstCurve, true);
    if (widget.secondCurve != oldWidget.secondCurve)
      _secondAnimation = _initAnimation(widget.secondCurve, false);
    if (widget.crossFadeState != oldWidget.crossFadeState) {
      switch (widget.crossFadeState) {
        case CrossFadeState.showFirst:
          _controller.reverse();
          break;
        case CrossFadeState.showSecond:
          _controller.forward();
          break;
      }
    }
  }

  bool get _isTransitioning =>
      _controller.status == AnimationStatus.forward ||
      _controller.status == AnimationStatus.reverse;

  @override
  Widget build(BuildContext context) {
    const Key kFirstChildKey =
        ValueKey<CrossFadeState>(CrossFadeState.showFirst);
    const Key kSecondChildKey =
        ValueKey<CrossFadeState>(CrossFadeState.showSecond);
    final bool transitioningForwards =
        _controller.status == AnimationStatus.completed ||
            _controller.status == AnimationStatus.forward;
    Key topKey;
    Widget topChild;
    Animation<double> topAnimation;
    Key bottomKey;
    Widget bottomChild;
    Animation<double> bottomAnimation;
    if (transitioningForwards) {
      topKey = kSecondChildKey;
      topChild = widget.secondChild;
      topAnimation = _secondAnimation;
      bottomKey = kFirstChildKey;
      bottomChild = widget.firstChild;
      bottomAnimation = _firstAnimation;
    } else {
      topKey = kFirstChildKey;
      topChild = widget.firstChild;
      topAnimation = _firstAnimation;
      bottomKey = kSecondChildKey;
      bottomChild = widget.secondChild;
      bottomAnimation = _secondAnimation;
    }

    bottomChild = TickerMode(
      key: bottomKey,
      enabled: _isTransitioning,
      child: ExcludeSemantics(
        excluding: true,
        child: FadeTransition(
          opacity: bottomAnimation,
          child: bottomChild,
        ),
      ),
    );
    topChild = TickerMode(
      key: topKey,
      enabled: true,
      child: ExcludeSemantics(
        excluding: false,
        child: FadeTransition(
          opacity: topAnimation,
          child: topChild,
        ),
      ),
    );
    return ClipRect(
      child: AnimatedSize(
        alignment: widget.alignment,
        duration: widget.duration,
        reverseDuration: widget.reverseDuration,
        curve: widget.sizeCurve,
        vsync: this,
        child: widget.layoutBuilder(topChild, topKey, bottomChild, bottomKey),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(
        EnumProperty<CrossFadeState>('crossFadeState', widget.crossFadeState));
    description.add(DiagnosticsProperty<AnimationController>(
        'controller', _controller,
        showName: false));
    description.add(DiagnosticsProperty<AlignmentGeometry>(
        'alignment', widget.alignment,
        defaultValue: Alignment.topCenter));
  }
}

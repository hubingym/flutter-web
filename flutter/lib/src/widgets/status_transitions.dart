import 'basic.dart';
import 'framework.dart';

abstract class StatusTransitionWidget extends StatefulWidget {
  const StatusTransitionWidget({Key key, @required this.animation})
      : assert(animation != null),
        super(key: key);

  final Animation<double> animation;

  Widget build(BuildContext context);

  @override
  _StatusTransitionState createState() => _StatusTransitionState();
}

class _StatusTransitionState extends State<StatusTransitionWidget> {
  @override
  void initState() {
    super.initState();
    widget.animation.addStatusListener(_animationStatusChanged);
  }

  @override
  void didUpdateWidget(StatusTransitionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animation != oldWidget.animation) {
      oldWidget.animation.removeStatusListener(_animationStatusChanged);
      widget.animation.addStatusListener(_animationStatusChanged);
    }
  }

  @override
  void dispose() {
    widget.animation.removeStatusListener(_animationStatusChanged);
    super.dispose();
  }

  void _animationStatusChanged(AnimationStatus status) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return widget.build(context);
  }
}

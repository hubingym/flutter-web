import 'package:flutter_web/gestures.dart';
import 'package:flutter_web/rendering.dart';

import 'framework.dart';
import 'notification_listener.dart';
import 'scroll_metrics.dart';

mixin ViewportNotificationMixin on Notification {
  int get depth => _depth;
  int _depth = 0;

  @override
  bool visitAncestor(Element element) {
    if (element is RenderObjectElement &&
        element.renderObject is RenderAbstractViewport) _depth += 1;
    return super.visitAncestor(element);
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('depth: $depth (${depth == 0 ? "local" : "remote"})');
  }
}

abstract class ScrollNotification extends LayoutChangedNotification
    with ViewportNotificationMixin {
  ScrollNotification({
    @required this.metrics,
    @required this.context,
  });

  final ScrollMetrics metrics;

  final BuildContext context;

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('$metrics');
  }
}

class ScrollStartNotification extends ScrollNotification {
  ScrollStartNotification({
    @required ScrollMetrics metrics,
    @required BuildContext context,
    this.dragDetails,
  }) : super(metrics: metrics, context: context);

  final DragStartDetails dragDetails;

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    if (dragDetails != null) description.add('$dragDetails');
  }
}

class ScrollUpdateNotification extends ScrollNotification {
  ScrollUpdateNotification({
    @required ScrollMetrics metrics,
    @required BuildContext context,
    this.dragDetails,
    this.scrollDelta,
  }) : super(metrics: metrics, context: context);

  final DragUpdateDetails dragDetails;

  final double scrollDelta;

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('scrollDelta: $scrollDelta');
    if (dragDetails != null) description.add('$dragDetails');
  }
}

class OverscrollNotification extends ScrollNotification {
  OverscrollNotification({
    @required ScrollMetrics metrics,
    @required BuildContext context,
    this.dragDetails,
    @required this.overscroll,
    this.velocity = 0.0,
  })  : assert(overscroll != null),
        assert(overscroll.isFinite),
        assert(overscroll != 0.0),
        assert(velocity != null),
        super(metrics: metrics, context: context);

  final DragUpdateDetails dragDetails;

  final double overscroll;

  final double velocity;

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('overscroll: ${overscroll.toStringAsFixed(1)}');
    description.add('velocity: ${velocity.toStringAsFixed(1)}');
    if (dragDetails != null) description.add('$dragDetails');
  }
}

class ScrollEndNotification extends ScrollNotification {
  ScrollEndNotification({
    @required ScrollMetrics metrics,
    @required BuildContext context,
    this.dragDetails,
  }) : super(metrics: metrics, context: context);

  final DragEndDetails dragDetails;

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    if (dragDetails != null) description.add('$dragDetails');
  }
}

class UserScrollNotification extends ScrollNotification {
  UserScrollNotification({
    @required ScrollMetrics metrics,
    @required BuildContext context,
    this.direction,
  }) : super(metrics: metrics, context: context);

  final ScrollDirection direction;

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('direction: $direction');
  }
}

typedef ScrollNotificationPredicate = bool Function(
    ScrollNotification notification);

bool defaultScrollNotificationPredicate(ScrollNotification notification) {
  return notification.depth == 0;
}

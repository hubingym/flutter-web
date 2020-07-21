import 'framework.dart';

typedef bool NotificationListenerCallback<T extends Notification>(
    T notification);

abstract class Notification {
  const Notification();

  @protected
  @mustCallSuper
  bool visitAncestor(Element element) {
    if (element is StatelessElement) {
      final StatelessWidget widget = element.widget;
      if (widget is NotificationListener<Notification>) {
        if (widget._dispatch(this, element)) return false;
      }
    }
    return true;
  }

  void dispatch(BuildContext target) {
    assert(target != null);
    target.visitAncestorElements(visitAncestor);
  }

  @override
  String toString() {
    final List<String> description = <String>[];
    debugFillDescription(description);
    return '$runtimeType(${description.join(", ")})';
  }

  @protected
  @mustCallSuper
  void debugFillDescription(List<String> description) {}
}

class NotificationListener<T extends Notification> extends StatelessWidget {
  const NotificationListener({
    Key key,
    @required this.child,
    this.onNotification,
  }) : super(key: key);

  final Widget child;

  final NotificationListenerCallback<T> onNotification;

  bool _dispatch(Notification notification, Element element) {
    if (onNotification != null && notification is T) {
      final bool result = onNotification(notification);
      return result == true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) => child;
}

class LayoutChangedNotification extends Notification {}

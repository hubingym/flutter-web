import 'package:flutter_web/rendering.dart';

import 'framework.dart';
import 'notification_listener.dart';

class SizeChangedLayoutNotification extends LayoutChangedNotification {}

class SizeChangedLayoutNotifier extends SingleChildRenderObjectWidget {
  const SizeChangedLayoutNotifier({Key key, Widget child})
      : super(key: key, child: child);

  @override
  _RenderSizeChangedWithCallback createRenderObject(BuildContext context) {
    return _RenderSizeChangedWithCallback(onLayoutChangedCallback: () {
      SizeChangedLayoutNotification().dispatch(context);
    });
  }
}

class _RenderSizeChangedWithCallback extends RenderProxyBox {
  _RenderSizeChangedWithCallback(
      {RenderBox child, @required this.onLayoutChangedCallback})
      : assert(onLayoutChangedCallback != null),
        super(child);

  final VoidCallback onLayoutChangedCallback;

  Size _oldSize;

  @override
  void performLayout() {
    super.performLayout();

    if (_oldSize != null && size != _oldSize) onLayoutChangedCallback();
    _oldSize = size;
  }
}

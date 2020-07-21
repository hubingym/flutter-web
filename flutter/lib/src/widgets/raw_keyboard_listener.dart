import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/services.dart';

import 'basic.dart';
import 'focus_scope.dart';
import 'focus_manager.dart';
import 'framework.dart';

export 'package:flutter_web/services.dart' show RawKeyEvent;

class RawKeyboardListener extends StatefulWidget {
  const RawKeyboardListener({
    Key key,
    @required this.focusNode,
    @required this.onKey,
    @required this.child,
  })  : assert(focusNode != null),
        assert(child != null),
        super(key: key);

  final FocusNode focusNode;

  final ValueChanged<RawKeyEvent> onKey;

  final Widget child;

  @override
  _RawKeyboardListenerState createState() => _RawKeyboardListenerState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<FocusNode>('focusNode', focusNode));
  }
}

class _RawKeyboardListenerState extends State<RawKeyboardListener> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(RawKeyboardListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode.removeListener(_handleFocusChanged);
      widget.focusNode.addListener(_handleFocusChanged);
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocusChanged);
    _detachKeyboardIfAttached();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (widget.focusNode.hasFocus)
      _attachKeyboardIfDetached();
    else
      _detachKeyboardIfAttached();
  }

  bool _listening = false;

  void _attachKeyboardIfDetached() {
    if (_listening) return;
    RawKeyboard.instance.addListener(_handleRawKeyEvent);
    _listening = true;
  }

  void _detachKeyboardIfAttached() {
    if (!_listening) return;
    RawKeyboard.instance.removeListener(_handleRawKeyEvent);
    _listening = false;
  }

  void _handleRawKeyEvent(RawKeyEvent event) {
    if (widget.onKey != null) widget.onKey(event);
  }

  @override
  Widget build(BuildContext context) =>
      Focus(focusNode: widget.focusNode, child: widget.child);
}

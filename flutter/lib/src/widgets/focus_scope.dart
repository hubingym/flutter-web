import 'package:flutter_web/foundation.dart';

import 'basic.dart';
import 'focus_manager.dart';
import 'framework.dart';
import 'inherited_notifier.dart';

class Focus extends StatefulWidget {
  const Focus({
    Key key,
    @required this.child,
    this.focusNode,
    this.autofocus = false,
    this.onFocusChange,
    this.onKey,
    this.debugLabel,
    this.skipTraversal = false,
  })  : assert(child != null),
        assert(autofocus != null),
        assert(skipTraversal != null),
        super(key: key);

  final String debugLabel;

  final Widget child;

  final FocusOnKeyCallback onKey;

  final ValueChanged<bool> onFocusChange;

  final bool autofocus;

  final FocusNode focusNode;

  final bool skipTraversal;

  static FocusNode of(BuildContext context, {bool nullOk = false}) {
    assert(context != null);
    assert(nullOk != null);
    final _FocusMarker marker =
        context.inheritFromWidgetOfExactType(_FocusMarker);
    final FocusNode node = marker?.notifier;
    if (node is FocusScopeNode) {
      if (!nullOk) {
        throw FlutterError(
            'Focus.of() was called with a context that does not contain a Focus between the given '
            'context and the nearest FocusScope widget.\n'
            'No Focus ancestor could be found starting from the context that was passed to '
            'Focus.of() to the point where it found the nearest FocusScope widget. This can happen '
            'because you are using a widget that looks for a Focus ancestor, and do not have a '
            'Focus widget ancestor in the current FocusScope.\n'
            'The context used was:\n'
            '  $context');
      }
      return null;
    }
    if (node == null) {
      if (!nullOk) {
        throw FlutterError(
            'Focus.of() was called with a context that does not contain a Focus widget.\n'
            'No Focus widget ancestor could be found starting from the context that was passed to '
            'Focus.of(). This can happen because you are using a widget that looks for a Focus '
            'ancestor, and do not have a Focus widget descendant in the nearest FocusScope.\n'
            'The context used was:\n'
            '  $context');
      }
      return null;
    }
    return node;
  }

  static bool isAt(BuildContext context) =>
      Focus.of(context, nullOk: true)?.hasFocus ?? false;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(StringProperty('debugLabel', debugLabel, defaultValue: null));
    properties.add(FlagProperty('autofocus',
        value: autofocus, ifTrue: 'AUTOFOCUS', defaultValue: false));
    properties.add(
        DiagnosticsProperty<FocusNode>('node', focusNode, defaultValue: null));
  }

  @override
  _FocusState createState() => _FocusState();
}

class _FocusState extends State<Focus> {
  FocusNode _internalNode;
  FocusNode get focusNode => widget.focusNode ?? _internalNode;
  bool _hasFocus;
  bool _didAutofocus = false;
  FocusAttachment _focusAttachment;

  @override
  void initState() {
    super.initState();
    _initNode();
  }

  void _initNode() {
    if (widget.focusNode == null) {
      _internalNode ??= _createNode();
    }
    focusNode.skipTraversal = widget.skipTraversal;
    _focusAttachment = focusNode.attach(context, onKey: widget.onKey);
    _hasFocus = focusNode.hasFocus;

    focusNode.addListener(_handleFocusChanged);
  }

  FocusNode _createNode() => FocusNode(debugLabel: widget.debugLabel);

  @override
  void dispose() {
    focusNode.removeListener(_handleFocusChanged);
    _focusAttachment.detach();

    _internalNode?.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _focusAttachment?.reparent();
    if (!_didAutofocus && widget.autofocus) {
      FocusScope.of(context).autofocus(focusNode);
      _didAutofocus = true;
    }
  }

  @override
  void deactivate() {
    super.deactivate();
    _didAutofocus = false;
  }

  @override
  void didUpdateWidget(Focus oldWidget) {
    super.didUpdateWidget(oldWidget);
    assert(() {
      if (oldWidget.debugLabel != widget.debugLabel && _internalNode != null) {
        _internalNode.debugLabel = widget.debugLabel;
      }
      return true;
    }());

    if (oldWidget.focusNode == widget.focusNode) {
      return;
    }

    _focusAttachment.detach();
    focusNode.removeListener(_handleFocusChanged);
    _initNode();

    _hasFocus = focusNode.hasFocus;
  }

  void _handleFocusChanged() {
    if (_hasFocus != focusNode.hasFocus) {
      setState(() {
        _hasFocus = focusNode.hasFocus;
      });
      if (widget.onFocusChange != null) {
        widget.onFocusChange(focusNode.hasFocus);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _focusAttachment.reparent();
    return _FocusMarker(
      node: focusNode,
      child: widget.child,
    );
  }
}

class FocusScope extends Focus {
  const FocusScope({
    Key key,
    FocusScopeNode node,
    @required Widget child,
    bool autofocus = false,
    ValueChanged<bool> onFocusChange,
    FocusOnKeyCallback onKey,
    String debugLabel,
  })  : assert(child != null),
        assert(autofocus != null),
        super(
          key: key,
          child: child,
          focusNode: node,
          autofocus: autofocus,
          onFocusChange: onFocusChange,
          onKey: onKey,
          debugLabel: debugLabel,
        );

  static FocusScopeNode of(BuildContext context) {
    assert(context != null);
    final _FocusMarker marker =
        context.inheritFromWidgetOfExactType(_FocusMarker);
    return marker?.notifier?.nearestScope ??
        context.owner.focusManager.rootScope;
  }

  @override
  _FocusScopeState createState() => _FocusScopeState();
}

class _FocusScopeState extends _FocusState {
  @override
  FocusScopeNode _createNode() {
    return FocusScopeNode(
      debugLabel: widget.debugLabel,
    );
  }

  @override
  Widget build(BuildContext context) {
    _focusAttachment.reparent();
    return Semantics(
      explicitChildNodes: true,
      child: _FocusMarker(
        node: focusNode,
        child: widget.child,
      ),
    );
  }
}

class _FocusMarker extends InheritedNotifier<FocusNode> {
  const _FocusMarker({
    Key key,
    @required FocusNode node,
    @required Widget child,
  })  : assert(node != null),
        assert(child != null),
        super(key: key, notifier: node, child: child);
}

import 'dart:async';

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/painting.dart';
import 'package:flutter_web/services.dart';

import 'binding.dart';
import 'focus_scope.dart';
import 'focus_traversal.dart';
import 'framework.dart';

typedef FocusOnKeyCallback = bool Function(FocusNode node, RawKeyEvent event);

class FocusAttachment {
  FocusAttachment._(this._node) : assert(_node != null);

  final FocusNode _node;

  bool get isAttached => _node._attachment == this;

  void detach() {
    assert(_node != null);
    if (isAttached) {
      if (_node.hasPrimaryFocus) {
        _node.unfocus();
      }
      _node._parent?._removeChild(_node);
      _node._attachment = null;
    }
    assert(!isAttached);
  }

  void reparent({FocusNode parent}) {
    assert(_node != null);
    if (isAttached) {
      assert(_node.context != null);
      parent ??= Focus.of(_node.context, nullOk: true);
      parent ??= FocusScope.of(_node.context);
      assert(parent != null);
      parent._reparent(_node);
    }
  }
}

class FocusNode with DiagnosticableTreeMixin, ChangeNotifier {
  FocusNode({
    String debugLabel,
    FocusOnKeyCallback onKey,
    this.skipTraversal = false,
  })  : assert(skipTraversal != null),
        _onKey = onKey {
    this.debugLabel = debugLabel;
  }

  bool skipTraversal;

  BuildContext get context => _context;
  BuildContext _context;

  FocusOnKeyCallback get onKey => _onKey;
  FocusOnKeyCallback _onKey;

  FocusManager _manager;
  bool _hasKeyboardToken = false;

  FocusNode get parent => _parent;
  FocusNode _parent;

  Iterable<FocusNode> get children => _children;
  final List<FocusNode> _children = <FocusNode>[];

  Iterable<FocusNode> get traversalChildren =>
      children.where((FocusNode node) => !node.skipTraversal);

  String get debugLabel => _debugLabel;
  String _debugLabel;
  set debugLabel(String value) {
    assert(() {
      _debugLabel = value;
      return true;
    }());
  }

  FocusAttachment _attachment;

  Iterable<FocusNode> get descendants sync* {
    for (FocusNode child in _children) {
      yield* child.descendants;
      yield child;
    }
  }

  Iterable<FocusNode> get traversalDescendants =>
      descendants.where((FocusNode node) => !node.skipTraversal);

  Iterable<FocusNode> get ancestors sync* {
    FocusNode parent = _parent;
    while (parent != null) {
      yield parent;
      parent = parent._parent;
    }
  }

  bool get hasFocus {
    if (_manager?._currentFocus == null) {
      return false;
    }
    if (hasPrimaryFocus) {
      return true;
    }
    return _manager._currentFocus.ancestors.contains(this);
  }

  bool get hasPrimaryFocus => _manager?._currentFocus == this;

  FocusScopeNode get nearestScope => enclosingScope;

  FocusScopeNode get enclosingScope {
    return ancestors.firstWhere((FocusNode node) => node is FocusScopeNode,
        orElse: () => null);
  }

  Size get size {
    assert(
        context != null,
        "Tried to get the size of a focus node that didn't have its context set yet.\n"
        'The context needs to be set before trying to evaluate traversal policies. This '
        'is typically done with the attach method.');
    return context.findRenderObject().semanticBounds.size;
  }

  Offset get offset {
    assert(
        context != null,
        "Tried to get the offset of a focus node that didn't have its context set yet.\n"
        'The context needs to be set before trying to evaluate traversal policies. This '
        'is typically done with the attach method.');
    final RenderObject object = context.findRenderObject();
    return MatrixUtils.transformPoint(
        object.getTransformTo(null), object.semanticBounds.topLeft);
  }

  Rect get rect {
    assert(
        context != null,
        "Tried to get the bounds of a focus node that didn't have its context set yet.\n"
        'The context needs to be set before trying to evaluate traversal policies. This '
        'is typically done with the attach method.');
    final RenderObject object = context.findRenderObject();
    final Offset globalOffset = MatrixUtils.transformPoint(
        object.getTransformTo(null), object.semanticBounds.topLeft);
    return globalOffset & object.semanticBounds.size;
  }

  void unfocus() {
    if (hasPrimaryFocus) {
      final FocusScopeNode scope = enclosingScope;
      assert(scope != null, 'Node has primary focus, but no enclosingScope.');
      scope._focusedChildren.remove(this);
      _manager?._willUnfocusNode(this);
      return;
    }
    if (hasFocus) {
      _manager._currentFocus.unfocus();
    }
  }

  bool consumeKeyboardToken() {
    if (!_hasKeyboardToken) {
      return false;
    }
    _hasKeyboardToken = false;
    return true;
  }

  void _markAsDirty({FocusNode newFocus}) {
    if (_manager != null) {
      _manager._dirtyNodes?.add(this);
      _manager._markNeedsUpdate(newFocus: newFocus);
    } else {
      newFocus?._setAsFocusedChild();
      newFocus?._notify();
      if (newFocus != this) {
        _notify();
      }
    }
  }

  @mustCallSuper
  void _removeChild(FocusNode node) {
    assert(node != null);
    assert(_children.contains(node),
        "Tried to remove a node that wasn't a child.");
    assert(node._parent == this);
    assert(node._manager == _manager);

    node.enclosingScope?._focusedChildren?.remove(node);

    node._parent = null;
    _children.remove(node);
    assert(_manager == null || !_manager.rootScope.descendants.contains(node));
  }

  void _updateManager(FocusManager manager) {
    _manager = manager;
    for (FocusNode descendant in descendants) {
      descendant._manager = manager;
    }
  }

  @mustCallSuper
  void _reparent(FocusNode child) {
    assert(child != null);
    assert(child != this, 'Tried to make a child into a parent of itself.');
    if (child._parent == this) {
      assert(_children.contains(child),
          "Found a node that says it's a child, but doesn't appear in the child list.");

      return;
    }
    assert(_manager == null || child != _manager.rootScope,
        "Reparenting the root node isn't allowed.");
    assert(!ancestors.contains(child),
        'The supplied child is already an ancestor of this node. Loops are not allowed.');
    final FocusScopeNode oldScope = child.enclosingScope;
    final bool hadFocus = child.hasFocus;
    child._parent?._removeChild(child);
    _children.add(child);
    child._parent = this;
    child._updateManager(_manager);
    if (hadFocus) {
      _manager?._currentFocus?._setAsFocusedChild();
    }
    if (oldScope != null &&
        child.context != null &&
        child.enclosingScope != oldScope) {
      DefaultFocusTraversal.of(child.context, nullOk: true)
          ?.changedScope(node: child, oldScope: oldScope);
    }
  }

  @mustCallSuper
  FocusAttachment attach(BuildContext context, {FocusOnKeyCallback onKey}) {
    _context = context;
    _onKey = onKey ?? _onKey;
    _attachment = FocusAttachment._(this);
    return _attachment;
  }

  @override
  void dispose() {
    _manager?._willDisposeFocusNode(this);
    _attachment?.detach();
    super.dispose();
  }

  @mustCallSuper
  void _notify() {
    if (_parent == null) {
      return;
    }
    if (hasPrimaryFocus) {
      _setAsFocusedChild();
    }
    notifyListeners();
  }

  void requestFocus([FocusNode node]) {
    if (node != null) {
      if (node._parent == null) {
        _reparent(node);
      }
      assert(node.ancestors.contains(this),
          'Focus was requested for a node that is not a descendant of the scope from which it was requested.');
      node._doRequestFocus();
      return;
    }
    _doRequestFocus();
  }

  void _doRequestFocus() {
    _setAsFocusedChild();
    if (hasPrimaryFocus) {
      return;
    }
    _hasKeyboardToken = true;
    _markAsDirty(newFocus: this);
  }

  void _setAsFocusedChild() {
    FocusNode scopeFocus = this;
    for (FocusScopeNode ancestor in ancestors.whereType<FocusScopeNode>()) {
      assert(scopeFocus != ancestor,
          'Somehow made a loop by setting focusedChild to its scope.');

      ancestor._focusedChildren.remove(scopeFocus);

      ancestor._focusedChildren.add(scopeFocus);
      scopeFocus = ancestor;
    }
  }

  bool nextFocus() => DefaultFocusTraversal.of(context).next(this);

  bool previousFocus() => DefaultFocusTraversal.of(context).previous(this);

  bool focusInDirection(TraversalDirection direction) =>
      DefaultFocusTraversal.of(context).inDirection(this, direction);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<BuildContext>('context', context,
        defaultValue: null));
    properties.add(FlagProperty('hasFocus',
        value: hasFocus, ifTrue: 'FOCUSED', defaultValue: false));
    properties
        .add(StringProperty('debugLabel', debugLabel, defaultValue: null));
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    int count = 1;
    return _children.map<DiagnosticsNode>((FocusNode child) {
      return child.toDiagnosticsNode(name: 'Child ${count++}');
    }).toList();
  }
}

class FocusScopeNode extends FocusNode {
  FocusScopeNode({
    String debugLabel,
    FocusOnKeyCallback onKey,
  }) : super(debugLabel: debugLabel, onKey: onKey);

  @override
  FocusScopeNode get nearestScope => this;

  bool get isFirstFocus => enclosingScope.focusedChild == this;

  FocusNode get focusedChild {
    assert(
        _focusedChildren.isEmpty ||
            _focusedChildren.last.enclosingScope == this,
        'Focused child does not have the same idea of its enclosing scope as the scope does.');
    return _focusedChildren.isNotEmpty ? _focusedChildren.last : null;
  }

  final List<FocusNode> _focusedChildren = <FocusNode>[];

  void setFirstFocus(FocusScopeNode scope) {
    assert(scope != null);
    if (scope._parent == null) {
      _reparent(scope);
    }
    assert(scope.ancestors.contains(this),
        '$FocusScopeNode $scope must be a child of $this to set it as first focus.');
    if (hasFocus) {
      scope._doRequestFocus();
    } else {
      scope._setAsFocusedChild();
    }
  }

  void autofocus(FocusNode node) {
    if (focusedChild == null) {
      if (node._parent == null) {
        _reparent(node);
      }
      assert(node.ancestors.contains(this),
          'Autofocus was requested for a node that is not a descendant of the scope from which it was requested.');
      node._doRequestFocus();
    }
  }

  @override
  void _doRequestFocus() {
    FocusNode primaryFocus = focusedChild ?? this;

    while (
        primaryFocus is FocusScopeNode && primaryFocus.focusedChild != null) {
      final FocusScopeNode scope = primaryFocus;
      primaryFocus = scope.focusedChild;
    }
    if (primaryFocus is FocusScopeNode) {
      _setAsFocusedChild();
      _markAsDirty(newFocus: primaryFocus);
    } else {
      primaryFocus.requestFocus();
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<FocusNode>('focusedChild', focusedChild,
        defaultValue: null));
  }
}

class FocusManager with DiagnosticableTreeMixin {
  FocusManager() {
    rootScope._manager = this;
    RawKeyboard.instance.addListener(_handleRawKeyEvent);
  }

  final FocusScopeNode rootScope =
      FocusScopeNode(debugLabel: 'Root Focus Scope');

  void _handleRawKeyEvent(RawKeyEvent event) {
    if (_currentFocus == null) {
      return;
    }
    Iterable<FocusNode> allNodes(FocusNode node) sync* {
      yield node;
      for (FocusNode ancestor in node.ancestors) {
        yield ancestor;
      }
    }

    for (FocusNode node in allNodes(_currentFocus)) {
      if (node.onKey != null && node.onKey(node, event)) {
        break;
      }
    }
  }

  FocusNode _currentFocus;

  FocusNode _nextFocus;

  final Set<FocusNode> _dirtyNodes = <FocusNode>{};

  void _willDisposeFocusNode(FocusNode node) {
    assert(node != null);
    _willUnfocusNode(node);
    _dirtyNodes.remove(node);
  }

  void _willUnfocusNode(FocusNode node) {
    assert(node != null);
    if (_currentFocus == node) {
      _currentFocus = null;
      _dirtyNodes.add(node);
      _markNeedsUpdate();
    }
    if (_nextFocus == node) {
      _nextFocus = null;
      _dirtyNodes.add(node);
      _markNeedsUpdate();
    }
  }

  bool _haveScheduledUpdate = false;

  void _markNeedsUpdate({FocusNode newFocus}) {
    _nextFocus = newFocus ?? _nextFocus;
    if (_haveScheduledUpdate) {
      return;
    }
    _haveScheduledUpdate = true;
    scheduleMicrotask(_applyFocusChange);
  }

  void _applyFocusChange() {
    _haveScheduledUpdate = false;
    final FocusNode previousFocus = _currentFocus;
    if (_currentFocus == null && _nextFocus == null) {
      _nextFocus = rootScope;
    }
    if (_nextFocus != null && _nextFocus != _currentFocus) {
      _currentFocus = _nextFocus;
      final Set<FocusNode> previousPath =
          previousFocus?.ancestors?.toSet() ?? <FocusNode>{};
      final Set<FocusNode> nextPath = _nextFocus.ancestors.toSet();

      _dirtyNodes.addAll(nextPath.difference(previousPath));

      _dirtyNodes.addAll(previousPath.difference(nextPath));
      _nextFocus = null;
    }
    if (previousFocus != _currentFocus) {
      if (previousFocus != null) {
        _dirtyNodes.add(previousFocus);
      }
      if (_currentFocus != null) {
        _dirtyNodes.add(_currentFocus);
      }
    }
    for (FocusNode node in _dirtyNodes) {
      node._notify();
    }
    _dirtyNodes.clear();
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return <DiagnosticsNode>[
      rootScope.toDiagnosticsNode(name: 'rootScope'),
    ];
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties.add(FlagProperty('haveScheduledUpdate',
        value: _haveScheduledUpdate, ifTrue: 'UPDATE SCHEDULED'));
    properties.add(DiagnosticsProperty<FocusNode>('currentFocus', _currentFocus,
        defaultValue: null));
  }
}

String debugDescribeFocusTree() {
  assert(WidgetsBinding.instance != null);
  String result;
  assert(() {
    result = WidgetsBinding.instance.focusManager.toStringDeep();
    return true;
  }());
  return result ?? '';
}

void debugDumpFocusTree() {
  assert(() {
    debugPrint(debugDescribeFocusTree());
    return true;
  }());
}

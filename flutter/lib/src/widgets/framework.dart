import 'dart:async';
import 'dart:collection';
import 'dart:developer';

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/rendering.dart';

import 'debug.dart';
import 'focus_manager.dart';

export 'package:flutter_web/ui.dart' show hashValues, hashList;

export 'package:flutter_web/foundation.dart'
    show
        immutable,
        mustCallSuper,
        optionalTypeArgs,
        protected,
        required,
        visibleForTesting;
export 'package:flutter_web/foundation.dart'
    show
        FlutterError,
        ErrorSummary,
        ErrorDescription,
        ErrorHint,
        debugPrint,
        debugPrintStack;
export 'package:flutter_web/foundation.dart'
    show VoidCallback, ValueChanged, ValueGetter, ValueSetter;
export 'package:flutter_web/foundation.dart'
    show DiagnosticsNode, DiagnosticLevel;
export 'package:flutter_web/foundation.dart' show Key, LocalKey, ValueKey;
export 'package:flutter_web/rendering.dart'
    show RenderObject, RenderBox, debugDumpRenderTree, debugDumpLayerTree;

class UniqueKey extends LocalKey {
  UniqueKey();

  @override
  String toString() => '[#${shortHash(this)}]';
}

class ObjectKey extends LocalKey {
  const ObjectKey(this.value);

  final Object value;

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) return false;
    final ObjectKey typedOther = other;
    return identical(value, typedOther.value);
  }

  @override
  int get hashCode => hashValues(runtimeType, identityHashCode(value));

  @override
  String toString() {
    if (runtimeType == ObjectKey) return '[${describeIdentity(value)}]';
    return '[$runtimeType ${describeIdentity(value)}]';
  }
}

@optionalTypeArgs
abstract class GlobalKey<T extends State<StatefulWidget>> extends Key {
  factory GlobalKey({String debugLabel}) => LabeledGlobalKey<T>(debugLabel);

  const GlobalKey.constructor() : super.empty();

  static final Map<GlobalKey, Element> _registry = <GlobalKey, Element>{};
  static final Set<Element> _debugIllFatedElements = HashSet<Element>();
  static final Map<GlobalKey, Element> _debugReservations =
      <GlobalKey, Element>{};

  void _register(Element element) {
    assert(() {
      if (_registry.containsKey(this)) {
        assert(element.widget != null);
        assert(_registry[this].widget != null);
        assert(
            element.widget.runtimeType != _registry[this].widget.runtimeType);
        _debugIllFatedElements.add(_registry[this]);
      }
      return true;
    }());
    _registry[this] = element;
  }

  void _unregister(Element element) {
    assert(() {
      if (_registry.containsKey(this) && _registry[this] != element) {
        assert(element.widget != null);
        assert(_registry[this].widget != null);
        assert(
            element.widget.runtimeType != _registry[this].widget.runtimeType);
      }
      return true;
    }());
    if (_registry[this] == element) _registry.remove(this);
  }

  void _debugReserveFor(Element parent) {
    assert(() {
      assert(parent != null);
      if (_debugReservations.containsKey(this) &&
          _debugReservations[this] != parent) {
        if (_debugReservations[this].renderObject?.attached == false) {
          _debugReservations[this] = parent;
          return true;
        }

        final String older = _debugReservations[this].toString();
        final String newer = parent.toString();
        if (older != newer) {
          throw FlutterError.fromParts(<DiagnosticsNode>[
            ErrorSummary('Multiple widgets used the same GlobalKey.'),
            ErrorDescription(
                'The key $this was used by multiple widgets. The parents of those widgets were:\n'
                '- $older\n'
                '- $newer\n'
                'A GlobalKey can only be specified on one widget at a time in the widget tree.')
          ]);
        }
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('Multiple widgets used the same GlobalKey.'),
          ErrorDescription(
              'The key $this was used by multiple widgets. The parents of those widgets were '
              'different widgets that both had the following description:\n'
              '  $parent\n'
              'A GlobalKey can only be specified on one widget at a time in the widget tree.'),
        ]);
      }
      _debugReservations[this] = parent;
      return true;
    }());
  }

  static void _debugVerifyIllFatedPopulation() {
    assert(() {
      Map<GlobalKey, Set<Element>> duplicates;
      for (Element element in _debugIllFatedElements) {
        if (element._debugLifecycleState != _ElementLifecycle.defunct) {
          assert(element != null);
          assert(element.widget != null);
          assert(element.widget.key != null);
          final GlobalKey key = element.widget.key;
          assert(_registry.containsKey(key));
          duplicates ??= <GlobalKey, Set<Element>>{};
          final Set<Element> elements =
              duplicates.putIfAbsent(key, () => HashSet<Element>());
          elements.add(element);
          elements.add(_registry[key]);
        }
      }
      _debugIllFatedElements.clear();
      _debugReservations.clear();
      if (duplicates != null) {
        final List<DiagnosticsNode> information = <DiagnosticsNode>[];
        information
            .add(ErrorSummary('Multiple widgets used the same GlobalKey.'));
        for (GlobalKey key in duplicates.keys) {
          final Set<Element> elements = duplicates[key];

          information.add(Element.describeElements(
              'The key $key was used by ${elements.length} widgets', elements));
        }
        information.add(ErrorDescription(
            'A GlobalKey can only be specified on one widget at a time in the widget tree.'));
        throw FlutterError.fromParts(information);
      }
      return true;
    }());
  }

  Element get _currentElement => _registry[this];

  BuildContext get currentContext => _currentElement;

  Widget get currentWidget => _currentElement?.widget;

  T get currentState {
    final Element element = _currentElement;
    if (element is StatefulElement) {
      final StatefulElement statefulElement = element;
      final State state = statefulElement.state;
      if (state is T) return state;
    }
    return null;
  }
}

@optionalTypeArgs
class LabeledGlobalKey<T extends State<StatefulWidget>> extends GlobalKey<T> {
  LabeledGlobalKey(this._debugLabel) : super.constructor();

  final String _debugLabel;

  @override
  String toString() {
    final String label = _debugLabel != null ? ' $_debugLabel' : '';
    if (runtimeType == LabeledGlobalKey)
      return '[GlobalKey#${shortHash(this)}$label]';
    return '[${describeIdentity(this)}$label]';
  }
}

@optionalTypeArgs
class GlobalObjectKey<T extends State<StatefulWidget>> extends GlobalKey<T> {
  const GlobalObjectKey(this.value) : super.constructor();

  final Object value;

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) return false;
    final GlobalObjectKey<T> typedOther = other;
    return identical(value, typedOther.value);
  }

  @override
  int get hashCode => identityHashCode(value);

  @override
  String toString() {
    String selfType = runtimeType.toString();

    const String suffix = '<State<StatefulWidget>>';
    if (selfType.endsWith(suffix)) {
      selfType = selfType.substring(0, selfType.length - suffix.length);
    }
    return '[$selfType ${describeIdentity(value)}]';
  }
}

@optionalTypeArgs
class TypeMatcher<T> {
  const TypeMatcher();

  bool check(dynamic object) => object is T;
}

@immutable
abstract class Widget extends DiagnosticableTree {
  const Widget({this.key});

  final Key key;

  @protected
  Element createElement();

  @override
  String toStringShort() {
    return key == null ? '$runtimeType' : '$runtimeType-$key';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.defaultDiagnosticsTreeStyle = DiagnosticsTreeStyle.dense;
  }

  static bool canUpdate(Widget oldWidget, Widget newWidget) {
    return oldWidget.runtimeType == newWidget.runtimeType &&
        oldWidget.key == newWidget.key;
  }
}

abstract class StatelessWidget extends Widget {
  const StatelessWidget({Key key}) : super(key: key);

  @override
  StatelessElement createElement() => StatelessElement(this);

  @protected
  Widget build(BuildContext context);
}

abstract class StatefulWidget extends Widget {
  const StatefulWidget({Key key}) : super(key: key);

  @override
  StatefulElement createElement() => StatefulElement(this);

  @protected
  State createState();
}

enum _StateLifecycle {
  created,

  initialized,

  ready,

  defunct,
}

typedef StateSetter = void Function(VoidCallback fn);

@optionalTypeArgs
abstract class State<T extends StatefulWidget> extends Diagnosticable {
  T get widget => _widget;
  T _widget;

  _StateLifecycle _debugLifecycleState = _StateLifecycle.created;

  bool _debugTypesAreRight(Widget widget) => widget is T;

  BuildContext get context => _element;
  StatefulElement _element;

  bool get mounted => _element != null;

  @protected
  @mustCallSuper
  void initState() {
    assert(_debugLifecycleState == _StateLifecycle.created);
  }

  @mustCallSuper
  @protected
  void didUpdateWidget(covariant T oldWidget) {}

  @protected
  @mustCallSuper
  void reassemble() {}

  @protected
  void setState(VoidCallback fn) {
    assert(fn != null);
    assert(() {
      if (_debugLifecycleState == _StateLifecycle.defunct) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('setState() called after dispose(): $this'),
          ErrorDescription(
              'This error happens if you call setState() on a State object for a widget that '
              'no longer appears in the widget tree (e.g., whose parent widget no longer '
              'includes the widget in its build). This error can occur when code calls '
              'setState() from a timer or an animation callback.'),
          ErrorHint('The preferred solution is '
              'to cancel the timer or stop listening to the animation in the dispose() '
              'callback. Another solution is to check the "mounted" property of this '
              'object before calling setState() to ensure the object is still in the '
              'tree.'),
          ErrorHint(
              'This error might indicate a memory leak if setState() is being called '
              'because another object is retaining a reference to this State object '
              'after it has been removed from the tree. To avoid memory leaks, '
              'consider breaking the reference to this object during dispose().'),
        ]);
      }
      if (_debugLifecycleState == _StateLifecycle.created && !mounted) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('setState() called in constructor: $this'),
          ErrorHint(
              'This happens when you call setState() on a State object for a widget that '
              'hasn\'t been inserted into the widget tree yet. It is not necessary to call '
              'setState() in the constructor, since the state is already assumed to be dirty '
              'when it is initially created.')
        ]);
      }
      return true;
    }());
    final dynamic result = fn() as dynamic;
    assert(() {
      if (result is Future) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('setState() callback argument returned a Future.'),
          ErrorDescription(
              'The setState() method on $this was called with a closure or method that '
              'returned a Future. Maybe it is marked as "async".'),
          ErrorHint(
              'Instead of performing asynchronous work inside a call to setState(), first '
              'execute the work (without updating the widget state), and then synchronously '
              'update the state inside a call to setState().')
        ]);
      }

      return true;
    }());
    _element.markNeedsBuild();
  }

  @protected
  @mustCallSuper
  void deactivate() {}

  @protected
  @mustCallSuper
  void dispose() {
    assert(_debugLifecycleState == _StateLifecycle.ready);
    assert(() {
      _debugLifecycleState = _StateLifecycle.defunct;
      return true;
    }());
  }

  @protected
  Widget build(BuildContext context);

  @protected
  @mustCallSuper
  void didChangeDependencies() {}

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    assert(() {
      properties.add(EnumProperty<_StateLifecycle>(
          'lifecycle state', _debugLifecycleState,
          defaultValue: _StateLifecycle.ready));
      return true;
    }());
    properties
        .add(ObjectFlagProperty<T>('_widget', _widget, ifNull: 'no widget'));
    properties.add(ObjectFlagProperty<StatefulElement>('_element', _element,
        ifNull: 'not mounted'));
  }
}

abstract class ProxyWidget extends Widget {
  const ProxyWidget({Key key, @required this.child}) : super(key: key);

  final Widget child;
}

abstract class ParentDataWidget<T extends RenderObjectWidget>
    extends ProxyWidget {
  const ParentDataWidget({Key key, Widget child})
      : super(key: key, child: child);

  @override
  ParentDataElement<T> createElement() => ParentDataElement<T>(this);

  bool debugIsValidAncestor(RenderObjectWidget ancestor) {
    assert(T != dynamic);
    assert(T != RenderObjectWidget);
    return ancestor is T;
  }

  Iterable<DiagnosticsNode> debugDescribeInvalidAncestorChain(
      {String description,
      DiagnosticsNode ownershipChain,
      bool foundValidAncestor,
      Iterable<Widget> badAncestors}) sync* {
    assert(T != dynamic);
    assert(T != RenderObjectWidget);
    if (!foundValidAncestor) {
      yield ErrorDescription(
          '$runtimeType widgets must be placed inside $T widgets.\n'
          '$description has no $T ancestor at all.');
    } else {
      assert(badAncestors.isNotEmpty);
      yield ErrorDescription(
          '$runtimeType widgets must be placed directly inside $T widgets.\n'
          '$description has a $T ancestor, but there are other widgets between them:');
      for (Widget ancestor in badAncestors) {
        if (ancestor.runtimeType == runtimeType) {
          yield ErrorDescription(
              '- $ancestor (this is a different $runtimeType than the one with the problem)');
        } else {
          yield ErrorDescription('- $ancestor');
        }
      }
      yield ErrorDescription(
          'These widgets cannot come between a $runtimeType and its $T.');
    }
    yield ErrorDescription(
        'The ownership chain for the parent of the offending $runtimeType was:\n  $ownershipChain');
  }

  @protected
  void applyParentData(RenderObject renderObject);

  @protected
  bool debugCanApplyOutOfTurn() => false;
}

abstract class InheritedWidget extends ProxyWidget {
  const InheritedWidget({Key key, Widget child})
      : super(key: key, child: child);

  @override
  InheritedElement createElement() => InheritedElement(this);

  @protected
  bool updateShouldNotify(covariant InheritedWidget oldWidget);
}

abstract class RenderObjectWidget extends Widget {
  const RenderObjectWidget({Key key}) : super(key: key);

  @override
  RenderObjectElement createElement();

  @protected
  RenderObject createRenderObject(BuildContext context);

  @protected
  void updateRenderObject(
      BuildContext context, covariant RenderObject renderObject) {}

  @protected
  void didUnmountRenderObject(covariant RenderObject renderObject) {}
}

abstract class LeafRenderObjectWidget extends RenderObjectWidget {
  const LeafRenderObjectWidget({Key key}) : super(key: key);

  @override
  LeafRenderObjectElement createElement() => LeafRenderObjectElement(this);
}

abstract class SingleChildRenderObjectWidget extends RenderObjectWidget {
  const SingleChildRenderObjectWidget({Key key, this.child}) : super(key: key);

  final Widget child;

  @override
  SingleChildRenderObjectElement createElement() =>
      SingleChildRenderObjectElement(this);
}

abstract class MultiChildRenderObjectWidget extends RenderObjectWidget {
  MultiChildRenderObjectWidget({Key key, this.children = const <Widget>[]})
      : assert(children != null),
        assert(() {
          final int index = children.indexOf(null);
          if (index >= 0) {
            throw FlutterError(
                "$runtimeType's children must not contain any null values, "
                'but a null value was found at index $index');
          }
          return true;
        }()),
        super(key: key);

  final List<Widget> children;

  @override
  MultiChildRenderObjectElement createElement() =>
      MultiChildRenderObjectElement(this);
}

enum _ElementLifecycle {
  initial,
  active,
  inactive,
  defunct,
}

class _InactiveElements {
  bool _locked = false;
  final Set<Element> _elements = HashSet<Element>();

  void _unmount(Element element) {
    assert(element._debugLifecycleState == _ElementLifecycle.inactive);
    assert(() {
      if (debugPrintGlobalKeyedWidgetLifecycle) {
        if (element.widget.key is GlobalKey)
          debugPrint('Discarding $element from inactive elements list.');
      }
      return true;
    }());
    element.visitChildren((Element child) {
      assert(child._parent == element);
      _unmount(child);
    });
    element.unmount();
    assert(element._debugLifecycleState == _ElementLifecycle.defunct);
  }

  void _unmountAll() {
    _locked = true;
    final List<Element> elements = _elements.toList()..sort(Element._sort);
    _elements.clear();
    try {
      elements.reversed.forEach(_unmount);
    } finally {
      assert(_elements.isEmpty);
      _locked = false;
    }
  }

  static void _deactivateRecursively(Element element) {
    assert(element._debugLifecycleState == _ElementLifecycle.active);
    element.deactivate();
    assert(element._debugLifecycleState == _ElementLifecycle.inactive);
    element.visitChildren(_deactivateRecursively);
    assert(() {
      element.debugDeactivated();
      return true;
    }());
  }

  void add(Element element) {
    assert(!_locked);
    assert(!_elements.contains(element));
    assert(element._parent == null);
    if (element._active) _deactivateRecursively(element);
    _elements.add(element);
  }

  void remove(Element element) {
    assert(!_locked);
    assert(_elements.contains(element));
    assert(element._parent == null);
    _elements.remove(element);
    assert(!element._active);
  }

  bool debugContains(Element element) {
    bool result;
    assert(() {
      result = _elements.contains(element);
      return true;
    }());
    return result;
  }
}

typedef ElementVisitor = void Function(Element element);

abstract class BuildContext {
  Widget get widget;

  BuildOwner get owner;

  RenderObject findRenderObject();

  Size get size;

  InheritedWidget inheritFromElement(InheritedElement ancestor,
      {Object aspect});

  InheritedWidget inheritFromWidgetOfExactType(Type targetType,
      {Object aspect});

  InheritedElement ancestorInheritedElementForWidgetOfExactType(
      Type targetType);

  Widget ancestorWidgetOfExactType(Type targetType);

  State ancestorStateOfType(TypeMatcher matcher);

  State rootAncestorStateOfType(TypeMatcher matcher);

  RenderObject ancestorRenderObjectOfType(TypeMatcher matcher);

  void visitAncestorElements(bool visitor(Element element));

  void visitChildElements(ElementVisitor visitor);

  DiagnosticsNode describeElement(String name,
      {DiagnosticsTreeStyle style = DiagnosticsTreeStyle.errorProperty});

  DiagnosticsNode describeWidget(String name,
      {DiagnosticsTreeStyle style = DiagnosticsTreeStyle.errorProperty});

  List<DiagnosticsNode> describeMissingAncestor(
      {@required Type expectedAncestorType});

  DiagnosticsNode describeOwnershipChain(String name);
}

class BuildOwner {
  BuildOwner({this.onBuildScheduled});

  VoidCallback onBuildScheduled;

  final _InactiveElements _inactiveElements = _InactiveElements();

  final List<Element> _dirtyElements = <Element>[];
  bool _scheduledFlushDirtyElements = false;

  bool _dirtyElementsNeedsResorting;

  bool get _debugIsInBuildScope => _dirtyElementsNeedsResorting != null;

  FocusManager focusManager = FocusManager();

  void scheduleBuildFor(Element element) {
    assert(element != null);
    assert(element.owner == this);
    assert(() {
      if (debugPrintScheduleBuildForStacks)
        debugPrintStack(
            label:
                'scheduleBuildFor() called for $element${_dirtyElements.contains(element) ? " (ALREADY IN LIST)" : ""}');
      if (!element.dirty) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary(
              'scheduleBuildFor() called for a widget that is not marked as dirty.'),
          element.describeElement(
              'The method was called for the following element'),
          ErrorDescription(
              'This element is not current marked as dirty. Make sure to set the dirty flag before '
              'calling scheduleBuildFor().'),
          ErrorHint(
              'If you did not attempt to call scheduleBuildFor() yourself, then this probably '
              'indicates a bug in the widgets framework. Please report it:\n'
              '  https://github.com/flutter/flutter/issues/new?template=BUG.md')
        ]);
      }
      return true;
    }());
    if (element._inDirtyList) {
      assert(() {
        if (debugPrintScheduleBuildForStacks)
          debugPrintStack(
              label:
                  'BuildOwner.scheduleBuildFor() called; _dirtyElementsNeedsResorting was $_dirtyElementsNeedsResorting (now true); dirty list is: $_dirtyElements');
        if (!_debugIsInBuildScope) {
          throw FlutterError.fromParts(<DiagnosticsNode>[
            ErrorSummary(
                'BuildOwner.scheduleBuildFor() called inappropriately.'),
            ErrorHint(
                'The BuildOwner.scheduleBuildFor() method should only be called while the '
                'buildScope() method is actively rebuilding the widget tree.')
          ]);
        }
        return true;
      }());
      _dirtyElementsNeedsResorting = true;
      return;
    }
    if (!_scheduledFlushDirtyElements && onBuildScheduled != null) {
      _scheduledFlushDirtyElements = true;
      onBuildScheduled();
    }
    _dirtyElements.add(element);
    element._inDirtyList = true;
    assert(() {
      if (debugPrintScheduleBuildForStacks)
        debugPrint('...dirty list is now: $_dirtyElements');
      return true;
    }());
  }

  int _debugStateLockLevel = 0;
  bool get _debugStateLocked => _debugStateLockLevel > 0;

  bool get debugBuilding => _debugBuilding;
  bool _debugBuilding = false;
  Element _debugCurrentBuildTarget;

  void lockState(void callback()) {
    assert(callback != null);
    assert(_debugStateLockLevel >= 0);
    assert(() {
      _debugStateLockLevel += 1;
      return true;
    }());
    try {
      callback();
    } finally {
      assert(() {
        _debugStateLockLevel -= 1;
        return true;
      }());
    }
    assert(_debugStateLockLevel >= 0);
  }

  void buildScope(Element context, [VoidCallback callback]) {
    if (callback == null && _dirtyElements.isEmpty) return;
    assert(context != null);
    assert(_debugStateLockLevel >= 0);
    assert(!_debugBuilding);
    assert(() {
      if (debugPrintBuildScope)
        debugPrint(
            'buildScope called with context $context; dirty list is: $_dirtyElements');
      _debugStateLockLevel += 1;
      _debugBuilding = true;
      return true;
    }());
    Timeline.startSync('Build', arguments: timelineWhitelistArguments);
    try {
      _scheduledFlushDirtyElements = true;
      if (callback != null) {
        assert(_debugStateLocked);
        Element debugPreviousBuildTarget;
        assert(() {
          context._debugSetAllowIgnoredCallsToMarkNeedsBuild(true);
          debugPreviousBuildTarget = _debugCurrentBuildTarget;
          _debugCurrentBuildTarget = context;
          return true;
        }());
        _dirtyElementsNeedsResorting = false;
        try {
          callback();
        } finally {
          assert(() {
            context._debugSetAllowIgnoredCallsToMarkNeedsBuild(false);
            assert(_debugCurrentBuildTarget == context);
            _debugCurrentBuildTarget = debugPreviousBuildTarget;
            _debugElementWasRebuilt(context);
            return true;
          }());
        }
      }
      _dirtyElements.sort(Element._sort);
      _dirtyElementsNeedsResorting = false;
      int dirtyCount = _dirtyElements.length;
      int index = 0;
      while (index < dirtyCount) {
        assert(_dirtyElements[index] != null);
        assert(_dirtyElements[index]._inDirtyList);
        assert(!_dirtyElements[index]._active ||
            _dirtyElements[index]._debugIsInScope(context));
        try {
          _dirtyElements[index].rebuild();
        } catch (e, stack) {
          _debugReportException(
            ErrorDescription('while rebuilding dirty elements'),
            e,
            stack,
            informationCollector: () sync* {
              yield DiagnosticsDebugCreator(
                  DebugCreator(_dirtyElements[index]));
              yield _dirtyElements[index].describeElement(
                  'The element being rebuilt at the time was index $index of $dirtyCount');
            },
          );
        }
        index += 1;
        if (dirtyCount < _dirtyElements.length ||
            _dirtyElementsNeedsResorting) {
          _dirtyElements.sort(Element._sort);
          _dirtyElementsNeedsResorting = false;
          dirtyCount = _dirtyElements.length;
          while (index > 0 && _dirtyElements[index - 1].dirty) {
            index -= 1;
          }
        }
      }
      assert(() {
        if (_dirtyElements
            .any((Element element) => element._active && element.dirty)) {
          throw FlutterError.fromParts(<DiagnosticsNode>[
            ErrorSummary('buildScope missed some dirty elements.'),
            ErrorHint(
                'This probably indicates that the dirty list should have been resorted but was not.'),
            Element.describeElements(
                'The list of dirty elements at the end of the buildScope call was',
                _dirtyElements)
          ]);
        }
        return true;
      }());
    } finally {
      for (Element element in _dirtyElements) {
        assert(element._inDirtyList);
        element._inDirtyList = false;
      }
      _dirtyElements.clear();
      _scheduledFlushDirtyElements = false;
      _dirtyElementsNeedsResorting = null;
      Timeline.finishSync();
      assert(_debugBuilding);
      assert(() {
        _debugBuilding = false;
        _debugStateLockLevel -= 1;
        if (debugPrintBuildScope) debugPrint('buildScope finished');
        return true;
      }());
    }
    assert(_debugStateLockLevel >= 0);
  }

  Map<Element, Set<GlobalKey>>
      _debugElementsThatWillNeedToBeRebuiltDueToGlobalKeyShenanigans;

  void _debugTrackElementThatWillNeedToBeRebuiltDueToGlobalKeyShenanigans(
      Element node, GlobalKey key) {
    _debugElementsThatWillNeedToBeRebuiltDueToGlobalKeyShenanigans ??=
        HashMap<Element, Set<GlobalKey>>();
    final Set<GlobalKey> keys =
        _debugElementsThatWillNeedToBeRebuiltDueToGlobalKeyShenanigans
            .putIfAbsent(node, () => HashSet<GlobalKey>());
    keys.add(key);
  }

  void _debugElementWasRebuilt(Element node) {
    _debugElementsThatWillNeedToBeRebuiltDueToGlobalKeyShenanigans
        ?.remove(node);
  }

  void finalizeTree() {
    Timeline.startSync('Finalize tree', arguments: timelineWhitelistArguments);
    try {
      lockState(() {
        _inactiveElements._unmountAll();
      });
      assert(() {
        try {
          GlobalKey._debugVerifyIllFatedPopulation();
          if (_debugElementsThatWillNeedToBeRebuiltDueToGlobalKeyShenanigans !=
                  null &&
              _debugElementsThatWillNeedToBeRebuiltDueToGlobalKeyShenanigans
                  .isNotEmpty) {
            final Set<GlobalKey> keys = HashSet<GlobalKey>();
            for (Element element
                in _debugElementsThatWillNeedToBeRebuiltDueToGlobalKeyShenanigans
                    .keys) {
              if (element._debugLifecycleState != _ElementLifecycle.defunct)
                keys.addAll(
                    _debugElementsThatWillNeedToBeRebuiltDueToGlobalKeyShenanigans[
                        element]);
            }
            if (keys.isNotEmpty) {
              final Map<String, int> keyStringCount = HashMap<String, int>();
              for (String key
                  in keys.map<String>((GlobalKey key) => key.toString())) {
                if (keyStringCount.containsKey(key)) {
                  keyStringCount[key] += 1;
                } else {
                  keyStringCount[key] = 1;
                }
              }
              final List<String> keyLabels = <String>[];
              keyStringCount.forEach((String key, int count) {
                if (count == 1) {
                  keyLabels.add(key);
                } else {
                  keyLabels.add(
                      '$key ($count different affected keys had this toString representation)');
                }
              });
              final Iterable<Element> elements =
                  _debugElementsThatWillNeedToBeRebuiltDueToGlobalKeyShenanigans
                      .keys;
              final Map<String, int> elementStringCount =
                  HashMap<String, int>();
              for (String element in elements
                  .map<String>((Element element) => element.toString())) {
                if (elementStringCount.containsKey(element)) {
                  elementStringCount[element] += 1;
                } else {
                  elementStringCount[element] = 1;
                }
              }
              final List<String> elementLabels = <String>[];
              elementStringCount.forEach((String element, int count) {
                if (count == 1) {
                  elementLabels.add(element);
                } else {
                  elementLabels.add(
                      '$element ($count different affected elements had this toString representation)');
                }
              });
              assert(keyLabels.isNotEmpty);
              final String the = keys.length == 1 ? ' the' : '';
              final String s = keys.length == 1 ? '' : 's';
              final String were = keys.length == 1 ? 'was' : 'were';
              final String their = keys.length == 1 ? 'its' : 'their';
              final String respective =
                  elementLabels.length == 1 ? '' : ' respective';
              final String those = keys.length == 1 ? 'that' : 'those';
              final String s2 = elementLabels.length == 1 ? '' : 's';
              final String those2 =
                  elementLabels.length == 1 ? 'that' : 'those';
              final String they = elementLabels.length == 1 ? 'it' : 'they';
              final String think =
                  elementLabels.length == 1 ? 'thinks' : 'think';
              final String are = elementLabels.length == 1 ? 'is' : 'are';

              throw FlutterError.fromParts(<DiagnosticsNode>[
                ErrorSummary('Duplicate GlobalKey$s detected in widget tree.'),
                ErrorDescription(
                    'The following GlobalKey$s $were specified multiple times in the widget tree. This will lead to '
                    'parts of the widget tree being truncated unexpectedly, because the second time a key is seen, '
                    'the previous instance is moved to the new location. The key$s $were:\n'
                    '- ${keyLabels.join("\n  ")}\n'
                    'This was determined by noticing that after$the widget$s with the above global key$s $were moved '
                    'out of $their$respective previous parent$s2, $those2 previous parent$s2 never updated during this frame, meaning '
                    'that $they either did not update at all or updated before the widget$s $were moved, in either case '
                    'implying that $they still $think that $they should have a child with $those global key$s.\n'
                    'The specific parent$s2 that did not update after having one or more children forcibly removed '
                    'due to GlobalKey reparenting $are:\n'
                    '- ${elementLabels.join("\n  ")}'
                    '\nA GlobalKey can only be specified on one widget at a time in the widget tree.')
              ]);
            }
          }
        } finally {
          _debugElementsThatWillNeedToBeRebuiltDueToGlobalKeyShenanigans
              ?.clear();
        }
        return true;
      }());
    } catch (e, stack) {
      _debugReportException(
          ErrorSummary('while finalizing the widget tree'), e, stack);
    } finally {
      Timeline.finishSync();
    }
  }

  void reassemble(Element root) {
    Timeline.startSync('Dirty Element Tree');
    try {
      assert(root._parent == null);
      assert(root.owner == this);
      root.reassemble();
    } finally {
      Timeline.finishSync();
    }
  }
}

abstract class Element extends DiagnosticableTree implements BuildContext {
  Element(Widget widget)
      : assert(widget != null),
        _widget = widget;

  Element _parent;

  @override
  bool operator ==(Object other) => identical(this, other);

  @override
  int get hashCode => _cachedHash;
  final int _cachedHash = _nextHashCode = (_nextHashCode + 1) % 0xffffff;
  static int _nextHashCode = 1;

  dynamic get slot => _slot;
  dynamic _slot;

  int get depth => _depth;
  int _depth;

  static int _sort(Element a, Element b) {
    if (a.depth < b.depth) return -1;
    if (b.depth < a.depth) return 1;
    if (b.dirty && !a.dirty) return -1;
    if (a.dirty && !b.dirty) return 1;
    return 0;
  }

  @override
  Widget get widget => _widget;
  Widget _widget;

  @override
  BuildOwner get owner => _owner;
  BuildOwner _owner;

  bool _active = false;

  @mustCallSuper
  @protected
  void reassemble() {
    markNeedsBuild();
    visitChildren((Element child) {
      child.reassemble();
    });
  }

  bool _debugIsInScope(Element target) {
    Element current = this;
    while (current != null) {
      if (target == current) return true;
      current = current._parent;
    }
    return false;
  }

  RenderObject get renderObject {
    RenderObject result;
    void visit(Element element) {
      assert(result == null);
      if (element is RenderObjectElement)
        result = element.renderObject;
      else
        element.visitChildren(visit);
    }

    visit(this);
    return result;
  }

  @override
  List<DiagnosticsNode> describeMissingAncestor(
      {@required Type expectedAncestorType}) {
    final List<DiagnosticsNode> information = <DiagnosticsNode>[];
    final List<Element> ancestors = <Element>[];
    visitAncestorElements((Element element) {
      ancestors.add(element);
      return true;
    });

    information.add(DiagnosticsProperty<Element>(
      'The specific widget that could not find a $expectedAncestorType ancestor was',
      this,
      style: DiagnosticsTreeStyle.errorProperty,
    ));

    if (ancestors.isNotEmpty) {
      information.add(
          describeElements('The ancestors of this widget were', ancestors));
    } else {
      information.add(
          ErrorDescription('This widget is the root of the tree, so it has no '
              'ancestors, let alone a "$expectedAncestorType" ancestor.'));
    }
    return information;
  }

  static DiagnosticsNode describeElements(
      String name, Iterable<Element> elements) {
    return DiagnosticsBlock(
      name: name,
      children: elements
          .map<DiagnosticsNode>(
              (Element element) => DiagnosticsProperty<Element>('', element))
          .toList(),
      allowTruncate: true,
    );
  }

  @override
  DiagnosticsNode describeElement(String name,
      {DiagnosticsTreeStyle style = DiagnosticsTreeStyle.errorProperty}) {
    return DiagnosticsProperty<Element>(name, this, style: style);
  }

  @override
  DiagnosticsNode describeWidget(String name,
      {DiagnosticsTreeStyle style = DiagnosticsTreeStyle.errorProperty}) {
    return DiagnosticsProperty<Element>(name, this, style: style);
  }

  @override
  DiagnosticsNode describeOwnershipChain(String name) {
    return StringProperty(name, debugGetCreatorChain(10));
  }

  _ElementLifecycle _debugLifecycleState = _ElementLifecycle.initial;

  void visitChildren(ElementVisitor visitor) {}

  void debugVisitOnstageChildren(ElementVisitor visitor) =>
      visitChildren(visitor);

  @override
  void visitChildElements(ElementVisitor visitor) {
    assert(() {
      if (owner == null || !owner._debugStateLocked) return true;
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('visitChildElements() called during build.'),
        ErrorDescription(
            'The BuildContext.visitChildElements() method can\'t be called during '
            'build because the child list is still being updated at that point, '
            'so the children might not be constructed yet, or might be old children '
            'that are going to be replaced.')
      ]);
    }());
    visitChildren(visitor);
  }

  @protected
  Element updateChild(Element child, Widget newWidget, dynamic newSlot) {
    assert(() {
      if (newWidget != null && newWidget.key is GlobalKey) {
        final GlobalKey key = newWidget.key;
        key._debugReserveFor(this);
      }
      return true;
    }());
    if (newWidget == null) {
      if (child != null) deactivateChild(child);
      return null;
    }
    if (child != null) {
      if (child.widget == newWidget) {
        if (child.slot != newSlot) updateSlotForChild(child, newSlot);
        return child;
      }
      if (Widget.canUpdate(child.widget, newWidget)) {
        if (child.slot != newSlot) updateSlotForChild(child, newSlot);
        child.update(newWidget);
        assert(child.widget == newWidget);
        assert(() {
          child.owner._debugElementWasRebuilt(child);
          return true;
        }());
        return child;
      }
      deactivateChild(child);
      assert(child._parent == null);
    }
    return inflateWidget(newWidget, newSlot);
  }

  @mustCallSuper
  void mount(Element parent, dynamic newSlot) {
    assert(_debugLifecycleState == _ElementLifecycle.initial);
    assert(widget != null);
    assert(_parent == null);
    assert(parent == null ||
        parent._debugLifecycleState == _ElementLifecycle.active);
    assert(slot == null);
    assert(depth == null);
    assert(!_active);
    _parent = parent;
    _slot = newSlot;
    _depth = _parent != null ? _parent.depth + 1 : 1;
    _active = true;
    if (parent != null) _owner = parent.owner;
    if (widget.key is GlobalKey) {
      final GlobalKey key = widget.key;
      key._register(this);
    }
    _updateInheritance();
    assert(() {
      _debugLifecycleState = _ElementLifecycle.active;
      return true;
    }());
  }

  @mustCallSuper
  void update(covariant Widget newWidget) {
    assert(_debugLifecycleState == _ElementLifecycle.active &&
        widget != null &&
        newWidget != null &&
        newWidget != widget &&
        depth != null &&
        _active &&
        Widget.canUpdate(widget, newWidget));
    _widget = newWidget;
  }

  @protected
  void updateSlotForChild(Element child, dynamic newSlot) {
    assert(_debugLifecycleState == _ElementLifecycle.active);
    assert(child != null);
    assert(child._parent == this);
    void visit(Element element) {
      element._updateSlot(newSlot);
      if (element is! RenderObjectElement) element.visitChildren(visit);
    }

    visit(child);
  }

  void _updateSlot(dynamic newSlot) {
    assert(_debugLifecycleState == _ElementLifecycle.active);
    assert(widget != null);
    assert(_parent != null);
    assert(_parent._debugLifecycleState == _ElementLifecycle.active);
    assert(depth != null);
    _slot = newSlot;
  }

  void _updateDepth(int parentDepth) {
    final int expectedDepth = parentDepth + 1;
    if (_depth < expectedDepth) {
      _depth = expectedDepth;
      visitChildren((Element child) {
        child._updateDepth(expectedDepth);
      });
    }
  }

  void detachRenderObject() {
    visitChildren((Element child) {
      child.detachRenderObject();
    });
    _slot = null;
  }

  void attachRenderObject(dynamic newSlot) {
    assert(_slot == null);
    visitChildren((Element child) {
      child.attachRenderObject(newSlot);
    });
    _slot = newSlot;
  }

  Element _retakeInactiveElement(GlobalKey key, Widget newWidget) {
    final Element element = key._currentElement;
    if (element == null) return null;
    if (!Widget.canUpdate(element.widget, newWidget)) return null;
    assert(() {
      if (debugPrintGlobalKeyedWidgetLifecycle)
        debugPrint(
            'Attempting to take $element from ${element._parent ?? "inactive elements list"} to put in $this.');
      return true;
    }());
    final Element parent = element._parent;
    if (parent != null) {
      assert(() {
        if (parent == this) {
          throw FlutterError.fromParts(<DiagnosticsNode>[
            ErrorSummary(
                'A GlobalKey was used multiple times inside one widget\'s child list.'),
            DiagnosticsProperty<GlobalKey>('The offending GlobalKey was', key),
            parent
                .describeElement('The parent of the widgets with that key was'),
            element.describeElement(
                'The first child to get instantiated with that key became'),
            DiagnosticsProperty<Widget>(
                'The second child that was to be instantiated with that key was',
                widget,
                style: DiagnosticsTreeStyle.errorProperty),
            ErrorDescription(
                'A GlobalKey can only be specified on one widget at a time in the widget tree.')
          ]);
        }
        parent.owner
            ._debugTrackElementThatWillNeedToBeRebuiltDueToGlobalKeyShenanigans(
          parent,
          key,
        );
        return true;
      }());
      parent.forgetChild(element);
      parent.deactivateChild(element);
    }
    assert(element._parent == null);
    owner._inactiveElements.remove(element);
    return element;
  }

  @protected
  Element inflateWidget(Widget newWidget, dynamic newSlot) {
    assert(newWidget != null);
    final Key key = newWidget.key;
    if (key is GlobalKey) {
      final Element newChild = _retakeInactiveElement(key, newWidget);
      if (newChild != null) {
        assert(newChild._parent == null);
        assert(() {
          _debugCheckForCycles(newChild);
          return true;
        }());
        newChild._activateWithParent(this, newSlot);
        final Element updatedChild = updateChild(newChild, newWidget, newSlot);
        assert(newChild == updatedChild);
        return updatedChild;
      }
    }
    final Element newChild = newWidget.createElement();
    assert(() {
      _debugCheckForCycles(newChild);
      return true;
    }());
    newChild.mount(this, newSlot);
    assert(newChild._debugLifecycleState == _ElementLifecycle.active);
    return newChild;
  }

  void _debugCheckForCycles(Element newChild) {
    assert(newChild._parent == null);
    assert(() {
      Element node = this;
      while (node._parent != null) node = node._parent;
      assert(node != newChild);
      return true;
    }());
  }

  @protected
  void deactivateChild(Element child) {
    assert(child != null);
    assert(child._parent == this);
    child._parent = null;
    child.detachRenderObject();
    owner._inactiveElements.add(child);
    assert(() {
      if (debugPrintGlobalKeyedWidgetLifecycle) {
        if (child.widget.key is GlobalKey)
          debugPrint('Deactivated $child (keyed child of $this)');
      }
      return true;
    }());
  }

  @protected
  void forgetChild(Element child);

  void _activateWithParent(Element parent, dynamic newSlot) {
    assert(_debugLifecycleState == _ElementLifecycle.inactive);
    _parent = parent;
    assert(() {
      if (debugPrintGlobalKeyedWidgetLifecycle)
        debugPrint('Reactivating $this (now child of $_parent).');
      return true;
    }());
    _updateDepth(_parent.depth);
    _activateRecursively(this);
    attachRenderObject(newSlot);
    assert(_debugLifecycleState == _ElementLifecycle.active);
  }

  static void _activateRecursively(Element element) {
    assert(element._debugLifecycleState == _ElementLifecycle.inactive);
    element.activate();
    assert(element._debugLifecycleState == _ElementLifecycle.active);
    element.visitChildren(_activateRecursively);
  }

  @mustCallSuper
  void activate() {
    assert(_debugLifecycleState == _ElementLifecycle.inactive);
    assert(widget != null);
    assert(owner != null);
    assert(depth != null);
    assert(!_active);
    final bool hadDependencies =
        (_dependencies != null && _dependencies.isNotEmpty) ||
            _hadUnsatisfiedDependencies;
    _active = true;

    _dependencies?.clear();
    _hadUnsatisfiedDependencies = false;
    _updateInheritance();
    assert(() {
      _debugLifecycleState = _ElementLifecycle.active;
      return true;
    }());
    if (_dirty) owner.scheduleBuildFor(this);
    if (hadDependencies) didChangeDependencies();
  }

  @mustCallSuper
  void deactivate() {
    assert(_debugLifecycleState == _ElementLifecycle.active);
    assert(widget != null);
    assert(depth != null);
    assert(_active);
    if (_dependencies != null && _dependencies.isNotEmpty) {
      for (InheritedElement dependency in _dependencies)
        dependency._dependents.remove(this);
    }
    _inheritedWidgets = null;
    _active = false;
    assert(() {
      _debugLifecycleState = _ElementLifecycle.inactive;
      return true;
    }());
  }

  @mustCallSuper
  void debugDeactivated() {
    assert(_debugLifecycleState == _ElementLifecycle.inactive);
  }

  @mustCallSuper
  void unmount() {
    assert(_debugLifecycleState == _ElementLifecycle.inactive);
    assert(widget != null);
    assert(depth != null);
    assert(!_active);
    if (widget.key is GlobalKey) {
      final GlobalKey key = widget.key;
      key._unregister(this);
    }
    assert(() {
      _debugLifecycleState = _ElementLifecycle.defunct;
      return true;
    }());
  }

  @override
  RenderObject findRenderObject() => renderObject;

  @override
  Size get size {
    assert(() {
      if (_debugLifecycleState != _ElementLifecycle.active) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('Cannot get size of inactive element.'),
          ErrorDescription(
              'In order for an element to have a valid size, the element must be '
              'active, which means it is part of the tree.\n'
              'Instead, this element is in the $_debugLifecycleState state.'),
          describeElement(
              'The size getter was called for the following element')
        ]);
      }
      if (owner._debugBuilding) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('Cannot get size during build.'),
          ErrorDescription(
              'The size of this render object has not yet been determined because '
              'the framework is still in the process of building widgets, which '
              'means the render tree for this frame has not yet been determined. '
              'The size getter should only be called from paint callbacks or '
              'interaction event handlers (e.g. gesture callbacks).'),
          ErrorSpacer(),
          ErrorHint(
              'If you need some sizing information during build to decide which '
              'widgets to build, consider using a LayoutBuilder widget, which can '
              'tell you the layout constraints at a given location in the tree. See '
              '<https://api.flutter.dev/flutter/widgets/LayoutBuilder-class.html> '
              'for more details.'),
          ErrorSpacer(),
          describeElement(
              'The size getter was called for the following element')
        ]);
      }
      return true;
    }());
    final RenderObject renderObject = findRenderObject();
    assert(() {
      if (renderObject == null) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('Cannot get size without a render object.'),
          ErrorHint(
              'In order for an element to have a valid size, the element must have '
              'an associated render object. This element does not have an associated '
              'render object, which typically means that the size getter was called '
              'too early in the pipeline (e.g., during the build phase) before the '
              'framework has created the render tree.'),
          describeElement(
              'The size getter was called for the following element')
        ]);
      }
      if (renderObject is RenderSliver) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('Cannot get size from a RenderSliver.'),
          ErrorHint('The render object associated with this element is a '
              '${renderObject.runtimeType}, which is a subtype of RenderSliver. '
              'Slivers do not have a size per se. They have a more elaborate '
              'geometry description, which can be accessed by calling '
              'findRenderObject and then using the "geometry" getter on the '
              'resulting object.'),
          describeElement(
              'The size getter was called for the following element'),
          renderObject.describeForError('The associated render sliver was'),
        ]);
      }
      if (renderObject is! RenderBox) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary(
              'Cannot get size from a render object that is not a RenderBox.'),
          ErrorHint(
              'Instead of being a subtype of RenderBox, the render object associated '
              'with this element is a ${renderObject.runtimeType}. If this type of '
              'render object does have a size, consider calling findRenderObject '
              'and extracting its size manually.'),
          describeElement(
              'The size getter was called for the following element'),
          renderObject.describeForError('The associated render object was')
        ]);
      }
      final RenderBox box = renderObject;
      if (!box.hasSize) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary(
              'Cannot get size from a render object that has not been through layout.'),
          ErrorHint(
              'The size of this render object has not yet been determined because '
              'this render object has not yet been through layout, which typically '
              'means that the size getter was called too early in the pipeline '
              '(e.g., during the build phase) before the framework has determined '
              'the size and position of the render objects during layout.'),
          describeElement(
              'The size getter was called for the following element'),
          box.describeForError(
              'The render object from which the size was to be obtained was')
        ]);
      }
      if (box.debugNeedsLayout) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary(
              'Cannot get size from a render object that has been marked dirty for layout.'),
          ErrorHint(
              'The size of this render object is ambiguous because this render object has '
              'been modified since it was last laid out, which typically means that the size '
              'getter was called too early in the pipeline (e.g., during the build phase) '
              'before the framework has determined the size and position of the render '
              'objects during layout.'),
          describeElement(
              'The size getter was called for the following element'),
          box.describeForError(
              'The render object from which the size was to be obtained was'),
          ErrorHint(
              'Consider using debugPrintMarkNeedsLayoutStacks to determine why the render '
              'object in question is dirty, if you did not expect this.'),
        ]);
      }
      return true;
    }());
    if (renderObject is RenderBox) return renderObject.size;
    return null;
  }

  Map<Type, InheritedElement> _inheritedWidgets;
  Set<InheritedElement> _dependencies;
  bool _hadUnsatisfiedDependencies = false;

  bool _debugCheckStateIsActiveForAncestorLookup() {
    assert(() {
      if (_debugLifecycleState != _ElementLifecycle.active) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary(
              'Looking up a deactivated widget\'s ancestor is unsafe.'),
          ErrorDescription(
              'At this point the state of the widget\'s element tree is no longer '
              'stable.'),
          ErrorHint(
              'To safely refer to a widget\'s ancestor in its dispose() method, '
              'save a reference to the ancestor by calling inheritFromWidgetOfExactType() '
              'in the widget\'s didChangeDependencies() method.')
        ]);
      }
      return true;
    }());
    return true;
  }

  @override
  InheritedWidget inheritFromElement(InheritedElement ancestor,
      {Object aspect}) {
    assert(ancestor != null);
    _dependencies ??= HashSet<InheritedElement>();
    _dependencies.add(ancestor);
    ancestor.updateDependencies(this, aspect);
    return ancestor.widget;
  }

  @override
  InheritedWidget inheritFromWidgetOfExactType(Type targetType,
      {Object aspect}) {
    assert(_debugCheckStateIsActiveForAncestorLookup());
    final InheritedElement ancestor =
        _inheritedWidgets == null ? null : _inheritedWidgets[targetType];
    if (ancestor != null) {
      assert(ancestor is InheritedElement);
      return inheritFromElement(ancestor, aspect: aspect);
    }
    _hadUnsatisfiedDependencies = true;
    return null;
  }

  @override
  InheritedElement ancestorInheritedElementForWidgetOfExactType(
      Type targetType) {
    assert(_debugCheckStateIsActiveForAncestorLookup());
    final InheritedElement ancestor =
        _inheritedWidgets == null ? null : _inheritedWidgets[targetType];
    return ancestor;
  }

  void _updateInheritance() {
    assert(_active);
    _inheritedWidgets = _parent?._inheritedWidgets;
  }

  @override
  Widget ancestorWidgetOfExactType(Type targetType) {
    assert(_debugCheckStateIsActiveForAncestorLookup());
    Element ancestor = _parent;
    while (ancestor != null && ancestor.widget.runtimeType != targetType)
      ancestor = ancestor._parent;
    return ancestor?.widget;
  }

  @override
  State ancestorStateOfType(TypeMatcher matcher) {
    assert(_debugCheckStateIsActiveForAncestorLookup());
    Element ancestor = _parent;
    while (ancestor != null) {
      if (ancestor is StatefulElement && matcher.check(ancestor.state)) break;
      ancestor = ancestor._parent;
    }
    final StatefulElement statefulAncestor = ancestor;
    return statefulAncestor?.state;
  }

  @override
  State rootAncestorStateOfType(TypeMatcher matcher) {
    assert(_debugCheckStateIsActiveForAncestorLookup());
    Element ancestor = _parent;
    StatefulElement statefulAncestor;
    while (ancestor != null) {
      if (ancestor is StatefulElement && matcher.check(ancestor.state))
        statefulAncestor = ancestor;
      ancestor = ancestor._parent;
    }
    return statefulAncestor?.state;
  }

  @override
  RenderObject ancestorRenderObjectOfType(TypeMatcher matcher) {
    assert(_debugCheckStateIsActiveForAncestorLookup());
    Element ancestor = _parent;
    while (ancestor != null) {
      if (ancestor is RenderObjectElement &&
          matcher.check(ancestor.renderObject)) break;
      ancestor = ancestor._parent;
    }
    final RenderObjectElement renderObjectAncestor = ancestor;
    return renderObjectAncestor?.renderObject;
  }

  @override
  void visitAncestorElements(bool visitor(Element element)) {
    assert(_debugCheckStateIsActiveForAncestorLookup());
    Element ancestor = _parent;
    while (ancestor != null && visitor(ancestor)) ancestor = ancestor._parent;
  }

  @mustCallSuper
  void didChangeDependencies() {
    assert(_active);
    assert(_debugCheckOwnerBuildTargetExists('didChangeDependencies'));
    markNeedsBuild();
  }

  bool _debugCheckOwnerBuildTargetExists(String methodName) {
    assert(() {
      if (owner._debugCurrentBuildTarget == null) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('$methodName for ${widget.runtimeType} was called at an '
              'inappropriate time.'),
          ErrorDescription(
              'It may only be called while the widgets are being built.'),
          ErrorHint(
              'A possible cause of this error is when $methodName is called during '
              'one of:\n'
              ' * network I/O event\n'
              ' * file I/O event\n'
              ' * timer\n'
              ' * microtask (caused by Future.then, async/await, scheduleMicrotask)')
        ]);
      }
      return true;
    }());
    return true;
  }

  String debugGetCreatorChain(int limit) {
    final List<String> chain = <String>[];
    Element node = this;
    while (chain.length < limit && node != null) {
      chain.add(node.toStringShort());
      node = node._parent;
    }
    if (node != null) chain.add('\u22EF');
    return chain.join(' \u2190 ');
  }

  List<Element> debugGetDiagnosticChain() {
    final List<Element> chain = <Element>[this];
    Element node = _parent;
    while (node != null) {
      chain.add(node);
      node = node._parent;
    }
    return chain;
  }

  @override
  String toStringShort() {
    return widget != null ? '${widget.toStringShort()}' : '[$runtimeType]';
  }

  @override
  DiagnosticsNode toDiagnosticsNode({String name, DiagnosticsTreeStyle style}) {
    return _ElementDiagnosticableTreeNode(
      name: name,
      value: this,
      style: style,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.defaultDiagnosticsTreeStyle = DiagnosticsTreeStyle.dense;
    properties.add(ObjectFlagProperty<int>('depth', depth, ifNull: 'no depth'));
    properties
        .add(ObjectFlagProperty<Widget>('widget', widget, ifNull: 'no widget'));
    if (widget != null) {
      properties.add(DiagnosticsProperty<Key>('key', widget?.key,
          showName: false, defaultValue: null, level: DiagnosticLevel.hidden));
      widget.debugFillProperties(properties);
    }
    properties.add(FlagProperty('dirty', value: dirty, ifTrue: 'dirty'));
    if (_dependencies != null && _dependencies.isNotEmpty) {
      final List<DiagnosticsNode> diagnosticsDependencies = _dependencies
          .map((InheritedElement element) => element.widget
              .toDiagnosticsNode(style: DiagnosticsTreeStyle.sparse))
          .toList();
      properties.add(DiagnosticsProperty<List<DiagnosticsNode>>(
          'dependencies', diagnosticsDependencies));
    }
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    final List<DiagnosticsNode> children = <DiagnosticsNode>[];
    visitChildren((Element child) {
      if (child != null) {
        children.add(child.toDiagnosticsNode());
      } else {
        children.add(DiagnosticsNode.message('<null child>'));
      }
    });
    return children;
  }

  bool get dirty => _dirty;
  bool _dirty = true;

  bool _inDirtyList = false;

  bool _debugBuiltOnce = false;

  bool _debugAllowIgnoredCallsToMarkNeedsBuild = false;
  bool _debugSetAllowIgnoredCallsToMarkNeedsBuild(bool value) {
    assert(_debugAllowIgnoredCallsToMarkNeedsBuild == !value);
    _debugAllowIgnoredCallsToMarkNeedsBuild = value;
    return true;
  }

  void markNeedsBuild() {
    assert(_debugLifecycleState != _ElementLifecycle.defunct);
    if (!_active) return;
    assert(owner != null);
    assert(_debugLifecycleState == _ElementLifecycle.active);
    assert(() {
      if (owner._debugBuilding) {
        assert(owner._debugCurrentBuildTarget != null);
        assert(owner._debugStateLocked);
        if (_debugIsInScope(owner._debugCurrentBuildTarget)) return true;
        if (!_debugAllowIgnoredCallsToMarkNeedsBuild) {
          final List<DiagnosticsNode> information = <DiagnosticsNode>[
            ErrorSummary('setState() or markNeedsBuild() called during build.'),
            ErrorDescription(
                'This ${widget.runtimeType} widget cannot be marked as needing to build because the framework '
                'is already in the process of building widgets.  A widget can be marked as '
                'needing to be built during the build phase only if one of its ancestors '
                'is currently building. This exception is allowed because the framework '
                'builds parent widgets before children, which means a dirty descendant '
                'will always be built. Otherwise, the framework might not visit this '
                'widget during this build phase.'),
            describeElement(
              'The widget on which setState() or markNeedsBuild() was called was',
            )
          ];
          if (owner._debugCurrentBuildTarget != null)
            information.add(owner._debugCurrentBuildTarget.describeWidget(
                'The widget which was currently being built when the offending call was made was'));
          throw FlutterError.fromParts(information);
        }
        assert(dirty);
      } else if (owner._debugStateLocked) {
        assert(!_debugAllowIgnoredCallsToMarkNeedsBuild);
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary(
              'setState() or markNeedsBuild() called when widget tree was locked.'),
          ErrorDescription(
              'This ${widget.runtimeType} widget cannot be marked as needing to build '
              'because the framework is locked.'),
          describeElement(
              'The widget on which setState() or markNeedsBuild() was called was')
        ]);
      }
      return true;
    }());
    if (dirty) return;
    _dirty = true;
    owner.scheduleBuildFor(this);
  }

  void rebuild() {
    assert(_debugLifecycleState != _ElementLifecycle.initial);
    if (!_active || !_dirty) return;
    assert(() {
      if (debugOnRebuildDirtyWidget != null) {
        debugOnRebuildDirtyWidget(this, _debugBuiltOnce);
      }
      if (debugPrintRebuildDirtyWidgets) {
        if (!_debugBuiltOnce) {
          debugPrint('Building $this');
          _debugBuiltOnce = true;
        } else {
          debugPrint('Rebuilding $this');
        }
      }
      return true;
    }());
    assert(_debugLifecycleState == _ElementLifecycle.active);
    assert(owner._debugStateLocked);
    Element debugPreviousBuildTarget;
    assert(() {
      debugPreviousBuildTarget = owner._debugCurrentBuildTarget;
      owner._debugCurrentBuildTarget = this;
      return true;
    }());
    performRebuild();
    assert(() {
      assert(owner._debugCurrentBuildTarget == this);
      owner._debugCurrentBuildTarget = debugPreviousBuildTarget;
      return true;
    }());
    assert(!_dirty);
  }

  @protected
  void performRebuild();
}

class _ElementDiagnosticableTreeNode extends DiagnosticableTreeNode {
  _ElementDiagnosticableTreeNode({
    String name,
    @required Element value,
    @required DiagnosticsTreeStyle style,
    this.stateful = false,
  }) : super(
          name: name,
          value: value,
          style: style,
        );

  final bool stateful;

  @override
  Map<String, Object> toJsonMap(DiagnosticsSerializationDelegate delegate) {
    final Map<String, Object> json = super.toJsonMap(delegate);
    final Element element = value;
    json['widgetRuntimeType'] = element.widget?.runtimeType?.toString();
    json['stateful'] = stateful;
    return json;
  }
}

typedef ErrorWidgetBuilder = Widget Function(FlutterErrorDetails details);

class ErrorWidget extends LeafRenderObjectWidget {
  ErrorWidget(Object exception)
      : message = _stringify(exception),
        _flutterError = exception is FlutterError ? exception : null,
        super(key: UniqueKey());

  static ErrorWidgetBuilder builder =
      (FlutterErrorDetails details) => ErrorWidget(details.exception);

  final String message;
  final FlutterError _flutterError;

  static String _stringify(Object exception) {
    try {
      return exception.toString();
    } catch (e) {}
    return 'Error';
  }

  @override
  RenderBox createRenderObject(BuildContext context) => RenderErrorBox(message);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    if (_flutterError == null)
      properties.add(StringProperty('message', message, quoted: false));
    else
      properties.add(_flutterError.toDiagnosticsNode(
          style: DiagnosticsTreeStyle.whitespace));
  }
}

typedef WidgetBuilder = Widget Function(BuildContext context);

typedef IndexedWidgetBuilder = Widget Function(BuildContext context, int index);

typedef TransitionBuilder = Widget Function(BuildContext context, Widget child);

typedef ControlsWidgetBuilder = Widget Function(BuildContext context,
    {VoidCallback onStepContinue, VoidCallback onStepCancel});

abstract class ComponentElement extends Element {
  ComponentElement(Widget widget) : super(widget);

  Element _child;

  @override
  void mount(Element parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    assert(_child == null);
    assert(_active);
    _firstBuild();
    assert(_child != null);
  }

  void _firstBuild() {
    rebuild();
  }

  @override
  void performRebuild() {
    if (!kReleaseMode && debugProfileBuildsEnabled)
      Timeline.startSync('${widget.runtimeType}',
          arguments: timelineWhitelistArguments);

    assert(_debugSetAllowIgnoredCallsToMarkNeedsBuild(true));
    Widget built;
    try {
      built = build();
      debugWidgetBuilderValue(widget, built);
    } catch (e, stack) {
      built = ErrorWidget.builder(_debugReportException(
        ErrorDescription('building $this'),
        e,
        stack,
        informationCollector: () sync* {
          yield DiagnosticsDebugCreator(DebugCreator(this));
        },
      ));
    } finally {
      _dirty = false;
      assert(_debugSetAllowIgnoredCallsToMarkNeedsBuild(false));
    }
    try {
      _child = updateChild(_child, built, slot);
      assert(_child != null);
    } catch (e, stack) {
      built = ErrorWidget.builder(_debugReportException(
        ErrorDescription('building $this'),
        e,
        stack,
        informationCollector: () sync* {
          yield DiagnosticsDebugCreator(DebugCreator(this));
        },
      ));
      _child = updateChild(null, built, slot);
    }

    if (!kReleaseMode && debugProfileBuildsEnabled) Timeline.finishSync();
  }

  @protected
  Widget build();

  @override
  void visitChildren(ElementVisitor visitor) {
    if (_child != null) visitor(_child);
  }

  @override
  void forgetChild(Element child) {
    assert(child == _child);
    _child = null;
  }
}

class StatelessElement extends ComponentElement {
  StatelessElement(StatelessWidget widget) : super(widget);

  @override
  StatelessWidget get widget => super.widget;

  @override
  Widget build() => widget.build(this);

  @override
  void update(StatelessWidget newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    _dirty = true;
    rebuild();
  }
}

class StatefulElement extends ComponentElement {
  StatefulElement(StatefulWidget widget)
      : _state = widget.createState(),
        super(widget) {
    assert(() {
      if (!_state._debugTypesAreRight(widget)) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary(
              'StatefulWidget.createState must return a subtype of State<${widget.runtimeType}>'),
          ErrorDescription(
              'The createState function for ${widget.runtimeType} returned a state '
              'of type ${_state.runtimeType}, which is not a subtype of '
              'State<${widget.runtimeType}>, violating the contract for createState.')
        ]);
      }
      return true;
    }());
    assert(_state._element == null);
    _state._element = this;
    assert(_state._widget == null);
    _state._widget = widget;
    assert(_state._debugLifecycleState == _StateLifecycle.created);
  }

  @override
  Widget build() => state.build(this);

  State<StatefulWidget> get state => _state;
  State<StatefulWidget> _state;

  @override
  void reassemble() {
    state.reassemble();
    super.reassemble();
  }

  @override
  void _firstBuild() {
    assert(_state._debugLifecycleState == _StateLifecycle.created);
    try {
      _debugSetAllowIgnoredCallsToMarkNeedsBuild(true);
      final dynamic debugCheckForReturnedFuture = _state.initState() as dynamic;
      assert(() {
        if (debugCheckForReturnedFuture is Future) {
          throw FlutterError.fromParts(<DiagnosticsNode>[
            ErrorSummary(
                '${_state.runtimeType}.initState() returned a Future.'),
            ErrorDescription(
                'State.initState() must be a void method without an `async` keyword.'),
            ErrorHint(
                'Rather than awaiting on asynchronous work directly inside of initState, '
                'call a separate method to do this work without awaiting it.')
          ]);
        }
        return true;
      }());
    } finally {
      _debugSetAllowIgnoredCallsToMarkNeedsBuild(false);
    }
    assert(() {
      _state._debugLifecycleState = _StateLifecycle.initialized;
      return true;
    }());
    _state.didChangeDependencies();
    assert(() {
      _state._debugLifecycleState = _StateLifecycle.ready;
      return true;
    }());
    super._firstBuild();
  }

  @override
  void update(StatefulWidget newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    final StatefulWidget oldWidget = _state._widget;

    _dirty = true;
    _state._widget = widget;
    try {
      _debugSetAllowIgnoredCallsToMarkNeedsBuild(true);
      final dynamic debugCheckForReturnedFuture =
          _state.didUpdateWidget(oldWidget) as dynamic;
      assert(() {
        if (debugCheckForReturnedFuture is Future) {
          throw FlutterError.fromParts(<DiagnosticsNode>[
            ErrorSummary(
                '${_state.runtimeType}.didUpdateWidget() returned a Future.'),
            ErrorDescription(
                'State.didUpdateWidget() must be a void method without an `async` keyword.'),
            ErrorHint(
                'Rather than awaiting on asynchronous work directly inside of didUpdateWidget, '
                'call a separate method to do this work without awaiting it.')
          ]);
        }
        return true;
      }());
    } finally {
      _debugSetAllowIgnoredCallsToMarkNeedsBuild(false);
    }
    rebuild();
  }

  @override
  void activate() {
    super.activate();

    assert(_active);
    markNeedsBuild();
  }

  @override
  void deactivate() {
    _state.deactivate();
    super.deactivate();
  }

  @override
  void unmount() {
    super.unmount();
    _state.dispose();
    assert(() {
      if (_state._debugLifecycleState == _StateLifecycle.defunct) return true;
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary(
            '${_state.runtimeType}.dispose failed to call super.dispose.'),
        ErrorDescription(
            'dispose() implementations must always call their superclass dispose() method, to ensure '
            'that all the resources used by the widget are fully released.')
      ]);
    }());
    _state._element = null;
    _state = null;
  }

  @override
  InheritedWidget inheritFromElement(Element ancestor, {Object aspect}) {
    assert(ancestor != null);
    assert(() {
      final Type targetType = ancestor.widget.runtimeType;
      if (state._debugLifecycleState == _StateLifecycle.created) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary(
              'inheritFromWidgetOfExactType($targetType) or inheritFromElement() was called before ${_state.runtimeType}.initState() completed.'),
          ErrorDescription(
            'When an inherited widget changes, for example if the value of Theme.of() changes, '
            'its dependent widgets are rebuilt. If the dependent widget\'s reference to '
            'the inherited widget is in a constructor or an initState() method, '
            'then the rebuilt dependent widget will not reflect the changes in the '
            'inherited widget.',
          ),
          ErrorHint(
              'Typically references to inherited widgets should occur in widget build() methods. Alternatively, '
              'initialization based on inherited widgets can be placed in the didChangeDependencies method, which '
              'is called after initState and whenever the dependencies change thereafter.')
        ]);
      }
      if (state._debugLifecycleState == _StateLifecycle.defunct) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary(
              'inheritFromWidgetOfExactType($targetType) or inheritFromElement() was called after dispose(): $this'),
          ErrorDescription(
              'This error happens if you call inheritFromWidgetOfExactType() on the '
              'BuildContext for a widget that no longer appears in the widget tree '
              '(e.g., whose parent widget no longer includes the widget in its '
              'build). This error can occur when code calls '
              'inheritFromWidgetOfExactType() from a timer or an animation callback.'),
          ErrorHint(
              'The preferred solution is to cancel the timer or stop listening to the '
              'animation in the dispose() callback. Another solution is to check the '
              '"mounted" property of this object before calling '
              'inheritFromWidgetOfExactType() to ensure the object is still in the '
              'tree.'),
          ErrorHint('This error might indicate a memory leak if '
              'inheritFromWidgetOfExactType() is being called because another object '
              'is retaining a reference to this State object after it has been '
              'removed from the tree. To avoid memory leaks, consider breaking the '
              'reference to this object during dispose().'),
        ]);
      }
      return true;
    }());
    return super.inheritFromElement(ancestor, aspect: aspect);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _state.didChangeDependencies();
  }

  @override
  DiagnosticsNode toDiagnosticsNode({String name, DiagnosticsTreeStyle style}) {
    return _ElementDiagnosticableTreeNode(
      name: name,
      value: this,
      style: style,
      stateful: true,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<State<StatefulWidget>>('state', state,
        defaultValue: null));
  }
}

abstract class ProxyElement extends ComponentElement {
  ProxyElement(ProxyWidget widget) : super(widget);

  @override
  ProxyWidget get widget => super.widget;

  @override
  Widget build() => widget.child;

  @override
  void update(ProxyWidget newWidget) {
    final ProxyWidget oldWidget = widget;
    assert(widget != null);
    assert(widget != newWidget);
    super.update(newWidget);
    assert(widget == newWidget);
    updated(oldWidget);
    _dirty = true;
    rebuild();
  }

  @protected
  void updated(covariant ProxyWidget oldWidget) {
    notifyClients(oldWidget);
  }

  @protected
  void notifyClients(covariant ProxyWidget oldWidget);
}

class ParentDataElement<T extends RenderObjectWidget> extends ProxyElement {
  ParentDataElement(ParentDataWidget<T> widget) : super(widget);

  @override
  ParentDataWidget<T> get widget => super.widget;

  @override
  void mount(Element parent, dynamic newSlot) {
    assert(() {
      final List<Widget> badAncestors = <Widget>[];
      Element ancestor = parent;
      while (ancestor != null) {
        if (ancestor is ParentDataElement<RenderObjectWidget>) {
          badAncestors.add(ancestor.widget);
        } else if (ancestor is RenderObjectElement) {
          if (widget.debugIsValidAncestor(ancestor.widget)) break;
          badAncestors.add(ancestor.widget);
        }
        ancestor = ancestor._parent;
      }
      if (ancestor != null && badAncestors.isEmpty) return true;

      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('Incorrect use of ParentDataWidget.'),
        ...widget.debugDescribeInvalidAncestorChain(
          description: '$this',
          ownershipChain: ErrorDescription(parent.debugGetCreatorChain(10)),
          foundValidAncestor: ancestor != null,
          badAncestors: badAncestors,
        ),
      ]);
    }());
    super.mount(parent, newSlot);
  }

  void _applyParentData(ParentDataWidget<T> widget) {
    void applyParentDataToChild(Element child) {
      if (child is RenderObjectElement) {
        child._updateParentData(widget);
      } else {
        assert(child is! ParentDataElement<RenderObjectWidget>);
        child.visitChildren(applyParentDataToChild);
      }
    }

    visitChildren(applyParentDataToChild);
  }

  void applyWidgetOutOfTurn(ParentDataWidget<T> newWidget) {
    assert(newWidget != null);
    assert(newWidget.debugCanApplyOutOfTurn());
    assert(newWidget.child == widget.child);
    _applyParentData(newWidget);
  }

  @override
  void notifyClients(ParentDataWidget<T> oldWidget) {
    _applyParentData(widget);
  }
}

class InheritedElement extends ProxyElement {
  InheritedElement(InheritedWidget widget) : super(widget);

  @override
  InheritedWidget get widget => super.widget;

  final Map<Element, Object> _dependents = HashMap<Element, Object>();

  @override
  void _updateInheritance() {
    assert(_active);
    final Map<Type, InheritedElement> incomingWidgets =
        _parent?._inheritedWidgets;
    if (incomingWidgets != null)
      _inheritedWidgets = HashMap<Type, InheritedElement>.from(incomingWidgets);
    else
      _inheritedWidgets = HashMap<Type, InheritedElement>();
    _inheritedWidgets[widget.runtimeType] = this;
  }

  @override
  void debugDeactivated() {
    assert(() {
      assert(_dependents.isEmpty);
      return true;
    }());
    super.debugDeactivated();
  }

  @protected
  Object getDependencies(Element dependent) {
    return _dependents[dependent];
  }

  @protected
  void setDependencies(Element dependent, Object value) {
    _dependents[dependent] = value;
  }

  @protected
  void updateDependencies(Element dependent, Object aspect) {
    setDependencies(dependent, null);
  }

  @protected
  void notifyDependent(covariant InheritedWidget oldWidget, Element dependent) {
    dependent.didChangeDependencies();
  }

  @override
  void updated(InheritedWidget oldWidget) {
    if (widget.updateShouldNotify(oldWidget)) super.updated(oldWidget);
  }

  @override
  void notifyClients(InheritedWidget oldWidget) {
    assert(_debugCheckOwnerBuildTargetExists('notifyClients'));
    for (Element dependent in _dependents.keys) {
      assert(() {
        Element ancestor = dependent._parent;
        while (ancestor != this && ancestor != null)
          ancestor = ancestor._parent;
        return ancestor == this;
      }());

      assert(dependent._dependencies.contains(this));
      notifyDependent(oldWidget, dependent);
    }
  }
}

abstract class RenderObjectElement extends Element {
  RenderObjectElement(RenderObjectWidget widget) : super(widget);

  @override
  RenderObjectWidget get widget => super.widget;

  @override
  RenderObject get renderObject => _renderObject;
  RenderObject _renderObject;

  RenderObjectElement _ancestorRenderObjectElement;

  RenderObjectElement _findAncestorRenderObjectElement() {
    Element ancestor = _parent;
    while (ancestor != null && ancestor is! RenderObjectElement)
      ancestor = ancestor._parent;
    return ancestor;
  }

  ParentDataElement<RenderObjectWidget> _findAncestorParentDataElement() {
    Element ancestor = _parent;
    while (ancestor != null && ancestor is! RenderObjectElement) {
      if (ancestor is ParentDataElement<RenderObjectWidget>) return ancestor;
      ancestor = ancestor._parent;
    }
    return null;
  }

  @override
  void mount(Element parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    _renderObject = widget.createRenderObject(this);
    assert(() {
      _debugUpdateRenderObjectOwner();
      return true;
    }());
    assert(_slot == newSlot);
    attachRenderObject(newSlot);
    _dirty = false;
  }

  @override
  void update(covariant RenderObjectWidget newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    assert(() {
      _debugUpdateRenderObjectOwner();
      return true;
    }());
    widget.updateRenderObject(this, renderObject);
    _dirty = false;
  }

  void _debugUpdateRenderObjectOwner() {
    assert(() {
      _renderObject.debugCreator = DebugCreator(this);
      return true;
    }());
  }

  @override
  void performRebuild() {
    widget.updateRenderObject(this, renderObject);
    _dirty = false;
  }

  @protected
  List<Element> updateChildren(
      List<Element> oldChildren, List<Widget> newWidgets,
      {Set<Element> forgottenChildren}) {
    assert(oldChildren != null);
    assert(newWidgets != null);

    Element replaceWithNullIfForgotten(Element child) {
      return forgottenChildren != null && forgottenChildren.contains(child)
          ? null
          : child;
    }

    int newChildrenTop = 0;
    int oldChildrenTop = 0;
    int newChildrenBottom = newWidgets.length - 1;
    int oldChildrenBottom = oldChildren.length - 1;

    final List<Element> newChildren = oldChildren.length == newWidgets.length
        ? oldChildren
        : List<Element>(newWidgets.length);

    Element previousChild;

    while ((oldChildrenTop <= oldChildrenBottom) &&
        (newChildrenTop <= newChildrenBottom)) {
      final Element oldChild =
          replaceWithNullIfForgotten(oldChildren[oldChildrenTop]);
      final Widget newWidget = newWidgets[newChildrenTop];
      assert(oldChild == null ||
          oldChild._debugLifecycleState == _ElementLifecycle.active);
      if (oldChild == null || !Widget.canUpdate(oldChild.widget, newWidget))
        break;
      final Element newChild = updateChild(oldChild, newWidget, previousChild);
      assert(newChild._debugLifecycleState == _ElementLifecycle.active);
      newChildren[newChildrenTop] = newChild;
      previousChild = newChild;
      newChildrenTop += 1;
      oldChildrenTop += 1;
    }

    while ((oldChildrenTop <= oldChildrenBottom) &&
        (newChildrenTop <= newChildrenBottom)) {
      final Element oldChild =
          replaceWithNullIfForgotten(oldChildren[oldChildrenBottom]);
      final Widget newWidget = newWidgets[newChildrenBottom];
      assert(oldChild == null ||
          oldChild._debugLifecycleState == _ElementLifecycle.active);
      if (oldChild == null || !Widget.canUpdate(oldChild.widget, newWidget))
        break;
      oldChildrenBottom -= 1;
      newChildrenBottom -= 1;
    }

    final bool haveOldChildren = oldChildrenTop <= oldChildrenBottom;
    Map<Key, Element> oldKeyedChildren;
    if (haveOldChildren) {
      oldKeyedChildren = <Key, Element>{};
      while (oldChildrenTop <= oldChildrenBottom) {
        final Element oldChild =
            replaceWithNullIfForgotten(oldChildren[oldChildrenTop]);
        assert(oldChild == null ||
            oldChild._debugLifecycleState == _ElementLifecycle.active);
        if (oldChild != null) {
          if (oldChild.widget.key != null)
            oldKeyedChildren[oldChild.widget.key] = oldChild;
          else
            deactivateChild(oldChild);
        }
        oldChildrenTop += 1;
      }
    }

    while (newChildrenTop <= newChildrenBottom) {
      Element oldChild;
      final Widget newWidget = newWidgets[newChildrenTop];
      if (haveOldChildren) {
        final Key key = newWidget.key;
        if (key != null) {
          oldChild = oldKeyedChildren[key];
          if (oldChild != null) {
            if (Widget.canUpdate(oldChild.widget, newWidget)) {
              oldKeyedChildren.remove(key);
            } else {
              oldChild = null;
            }
          }
        }
      }
      assert(oldChild == null || Widget.canUpdate(oldChild.widget, newWidget));
      final Element newChild = updateChild(oldChild, newWidget, previousChild);
      assert(newChild._debugLifecycleState == _ElementLifecycle.active);
      assert(oldChild == newChild ||
          oldChild == null ||
          oldChild._debugLifecycleState != _ElementLifecycle.active);
      newChildren[newChildrenTop] = newChild;
      previousChild = newChild;
      newChildrenTop += 1;
    }

    assert(oldChildrenTop == oldChildrenBottom + 1);
    assert(newChildrenTop == newChildrenBottom + 1);
    assert(newWidgets.length - newChildrenTop ==
        oldChildren.length - oldChildrenTop);
    newChildrenBottom = newWidgets.length - 1;
    oldChildrenBottom = oldChildren.length - 1;

    while ((oldChildrenTop <= oldChildrenBottom) &&
        (newChildrenTop <= newChildrenBottom)) {
      final Element oldChild = oldChildren[oldChildrenTop];
      assert(replaceWithNullIfForgotten(oldChild) != null);
      assert(oldChild._debugLifecycleState == _ElementLifecycle.active);
      final Widget newWidget = newWidgets[newChildrenTop];
      assert(Widget.canUpdate(oldChild.widget, newWidget));
      final Element newChild = updateChild(oldChild, newWidget, previousChild);
      assert(newChild._debugLifecycleState == _ElementLifecycle.active);
      assert(oldChild == newChild ||
          oldChild == null ||
          oldChild._debugLifecycleState != _ElementLifecycle.active);
      newChildren[newChildrenTop] = newChild;
      previousChild = newChild;
      newChildrenTop += 1;
      oldChildrenTop += 1;
    }

    if (haveOldChildren && oldKeyedChildren.isNotEmpty) {
      for (Element oldChild in oldKeyedChildren.values) {
        if (forgottenChildren == null || !forgottenChildren.contains(oldChild))
          deactivateChild(oldChild);
      }
    }

    return newChildren;
  }

  @override
  void deactivate() {
    super.deactivate();
    assert(
        !renderObject.attached,
        'A RenderObject was still attached when attempting to deactivate its '
        'RenderObjectElement: $renderObject');
  }

  @override
  void unmount() {
    super.unmount();
    assert(
        !renderObject.attached,
        'A RenderObject was still attached when attempting to unmount its '
        'RenderObjectElement: $renderObject');
    widget.didUnmountRenderObject(renderObject);
  }

  void _updateParentData(ParentDataWidget<RenderObjectWidget> parentData) {
    parentData.applyParentData(renderObject);
  }

  @override
  void _updateSlot(dynamic newSlot) {
    assert(slot != newSlot);
    super._updateSlot(newSlot);
    assert(slot == newSlot);
    _ancestorRenderObjectElement.moveChildRenderObject(renderObject, slot);
  }

  @override
  void attachRenderObject(dynamic newSlot) {
    assert(_ancestorRenderObjectElement == null);
    _slot = newSlot;
    _ancestorRenderObjectElement = _findAncestorRenderObjectElement();
    _ancestorRenderObjectElement?.insertChildRenderObject(
        renderObject, newSlot);
    final ParentDataElement<RenderObjectWidget> parentDataElement =
        _findAncestorParentDataElement();
    if (parentDataElement != null) _updateParentData(parentDataElement.widget);
  }

  @override
  void detachRenderObject() {
    if (_ancestorRenderObjectElement != null) {
      _ancestorRenderObjectElement.removeChildRenderObject(renderObject);
      _ancestorRenderObjectElement = null;
    }
    _slot = null;
  }

  @protected
  void insertChildRenderObject(
      covariant RenderObject child, covariant dynamic slot);

  @protected
  void moveChildRenderObject(
      covariant RenderObject child, covariant dynamic slot);

  @protected
  void removeChildRenderObject(covariant RenderObject child);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<RenderObject>(
        'renderObject', renderObject,
        defaultValue: null));
  }
}

abstract class RootRenderObjectElement extends RenderObjectElement {
  RootRenderObjectElement(RenderObjectWidget widget) : super(widget);

  void assignOwner(BuildOwner owner) {
    _owner = owner;
  }

  @override
  void mount(Element parent, dynamic newSlot) {
    assert(parent == null);
    assert(newSlot == null);
    super.mount(parent, newSlot);
  }
}

class LeafRenderObjectElement extends RenderObjectElement {
  LeafRenderObjectElement(LeafRenderObjectWidget widget) : super(widget);

  @override
  void forgetChild(Element child) {
    assert(false);
  }

  @override
  void insertChildRenderObject(RenderObject child, dynamic slot) {
    assert(false);
  }

  @override
  void moveChildRenderObject(RenderObject child, dynamic slot) {
    assert(false);
  }

  @override
  void removeChildRenderObject(RenderObject child) {
    assert(false);
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    return widget.debugDescribeChildren();
  }
}

class SingleChildRenderObjectElement extends RenderObjectElement {
  SingleChildRenderObjectElement(SingleChildRenderObjectWidget widget)
      : super(widget);

  @override
  SingleChildRenderObjectWidget get widget => super.widget;

  Element _child;

  @override
  void visitChildren(ElementVisitor visitor) {
    if (_child != null) visitor(_child);
  }

  @override
  void forgetChild(Element child) {
    assert(child == _child);
    _child = null;
  }

  @override
  void mount(Element parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    _child = updateChild(_child, widget.child, null);
  }

  @override
  void update(SingleChildRenderObjectWidget newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    _child = updateChild(_child, widget.child, null);
  }

  @override
  void insertChildRenderObject(RenderObject child, dynamic slot) {
    final RenderObjectWithChildMixin<RenderObject> renderObject =
        this.renderObject;
    assert(slot == null);
    assert(renderObject.debugValidateChild(child));
    renderObject.child = child;
    assert(renderObject == this.renderObject);
  }

  @override
  void moveChildRenderObject(RenderObject child, dynamic slot) {
    assert(false);
  }

  @override
  void removeChildRenderObject(RenderObject child) {
    final RenderObjectWithChildMixin<RenderObject> renderObject =
        this.renderObject;
    assert(renderObject.child == child);
    renderObject.child = null;
    assert(renderObject == this.renderObject);
  }
}

class MultiChildRenderObjectElement extends RenderObjectElement {
  MultiChildRenderObjectElement(MultiChildRenderObjectWidget widget)
      : assert(!debugChildrenHaveDuplicateKeys(widget, widget.children)),
        super(widget);

  @override
  MultiChildRenderObjectWidget get widget => super.widget;

  @protected
  @visibleForTesting
  Iterable<Element> get children =>
      _children.where((Element child) => !_forgottenChildren.contains(child));

  List<Element> _children;

  final Set<Element> _forgottenChildren = HashSet<Element>();

  @override
  void insertChildRenderObject(RenderObject child, Element slot) {
    final ContainerRenderObjectMixin<RenderObject,
            ContainerParentDataMixin<RenderObject>> renderObject =
        this.renderObject;
    assert(renderObject.debugValidateChild(child));
    renderObject.insert(child, after: slot?.renderObject);
    assert(renderObject == this.renderObject);
  }

  @override
  void moveChildRenderObject(RenderObject child, dynamic slot) {
    final ContainerRenderObjectMixin<RenderObject,
            ContainerParentDataMixin<RenderObject>> renderObject =
        this.renderObject;
    assert(child.parent == renderObject);
    renderObject.move(child, after: slot?.renderObject);
    assert(renderObject == this.renderObject);
  }

  @override
  void removeChildRenderObject(RenderObject child) {
    final ContainerRenderObjectMixin<RenderObject,
            ContainerParentDataMixin<RenderObject>> renderObject =
        this.renderObject;
    assert(child.parent == renderObject);
    renderObject.remove(child);
    assert(renderObject == this.renderObject);
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    for (Element child in _children) {
      if (!_forgottenChildren.contains(child)) visitor(child);
    }
  }

  @override
  void forgetChild(Element child) {
    assert(_children.contains(child));
    assert(!_forgottenChildren.contains(child));
    _forgottenChildren.add(child);
  }

  @override
  void mount(Element parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    _children = List<Element>(widget.children.length);
    Element previousChild;
    for (int i = 0; i < _children.length; i += 1) {
      final Element newChild = inflateWidget(widget.children[i], previousChild);
      _children[i] = newChild;
      previousChild = newChild;
    }
  }

  @override
  void update(MultiChildRenderObjectWidget newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    _children = updateChildren(_children, widget.children,
        forgottenChildren: _forgottenChildren);
    _forgottenChildren.clear();
  }
}

class DebugCreator {
  DebugCreator(this.element);

  final Element element;

  @override
  String toString() => element.debugGetCreatorChain(12);
}

FlutterErrorDetails _debugReportException(
  DiagnosticsNode context,
  dynamic exception,
  StackTrace stack, {
  InformationCollector informationCollector,
}) {
  final FlutterErrorDetails details = FlutterErrorDetails(
    exception: exception,
    stack: stack,
    library: 'widgets library',
    context: context,
    informationCollector: informationCollector,
  );
  FlutterError.reportError(details);
  return details;
}

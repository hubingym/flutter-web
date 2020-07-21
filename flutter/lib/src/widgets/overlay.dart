import 'dart:collection';

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/rendering.dart';
import 'package:flutter_web/scheduler.dart';
import 'package:meta/meta.dart';

import 'basic.dart';
import 'debug.dart';
import 'framework.dart';
import 'ticker_provider.dart';

class OverlayEntry {
  OverlayEntry({
    @required this.builder,
    bool opaque = false,
    bool maintainState = false,
  })  : assert(builder != null),
        assert(opaque != null),
        assert(maintainState != null),
        _opaque = opaque,
        _maintainState = maintainState;

  final WidgetBuilder builder;

  bool get opaque => _opaque;
  bool _opaque;
  set opaque(bool value) {
    if (_opaque == value) return;
    _opaque = value;
    assert(_overlay != null);
    _overlay._didChangeEntryOpacity();
  }

  bool get maintainState => _maintainState;
  bool _maintainState;
  set maintainState(bool value) {
    assert(_maintainState != null);
    if (_maintainState == value) return;
    _maintainState = value;
    assert(_overlay != null);
    _overlay._didChangeEntryOpacity();
  }

  OverlayState _overlay;
  final GlobalKey<_OverlayEntryState> _key =
      new GlobalKey<_OverlayEntryState>();

  void remove() {
    assert(_overlay != null);
    final OverlayState overlay = _overlay;
    _overlay = null;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((Duration duration) {
        overlay._remove(this);
      });
    } else {
      overlay._remove(this);
    }
  }

  void markNeedsBuild() {
    _key.currentState?._markNeedsBuild();
  }
}

class _OverlayEntry extends StatefulWidget {
  _OverlayEntry(this.entry)
      : assert(entry != null),
        super(key: entry._key);

  final OverlayEntry entry;

  @override
  _OverlayEntryState createState() => new _OverlayEntryState();
}

class _OverlayEntryState extends State<_OverlayEntry> {
  @override
  Widget build(BuildContext context) {
    return widget.entry.builder(context);
  }

  void _markNeedsBuild() {
    setState(() {});
  }
}

class Overlay extends StatefulWidget {
  const Overlay({Key key, this.initialEntries = const <OverlayEntry>[]})
      : assert(initialEntries != null),
        super(key: key);

  final List<OverlayEntry> initialEntries;

  static OverlayState of(BuildContext context, {Widget debugRequiredFor}) {
    final OverlayState result =
        context.ancestorStateOfType(const TypeMatcher<OverlayState>());
    assert(() {
      if (debugRequiredFor != null && result == null) {
        final String additional = context.widget != debugRequiredFor
            ? '\nThe context from which that widget was searching for an '
                'overlay was:\n  $context'
            : '';
        throw new FlutterError('No Overlay widget found.\n'
            '${debugRequiredFor.runtimeType} widgets require an Overlay '
            'widget ancestor for correct operation.\n'
            'The most common way to add an Overlay to an application is to '
            'include a MaterialApp or Navigator widget in the runApp() call.\n'
            'The specific widget that failed to find an overlay was:\n'
            '  $debugRequiredFor'
            '$additional');
      }
      return true;
    }());
    return result;
  }

  @override
  OverlayState createState() => new OverlayState();
}

class OverlayState extends State<Overlay>
    with TickerProviderStateMixin<Overlay> {
  final List<OverlayEntry> _entries = <OverlayEntry>[];

  @override
  void initState() {
    super.initState();
    insertAll(widget.initialEntries);
  }

  void insert(OverlayEntry entry, {OverlayEntry above}) {
    assert(entry._overlay == null);
    assert(
        above == null || (above._overlay == this && _entries.contains(above)));
    entry._overlay = this;
    setState(() {
      final int index =
          above == null ? _entries.length : _entries.indexOf(above) + 1;
      _entries.insert(index, entry);
    });
  }

  void insertAll(Iterable<OverlayEntry> entries, {OverlayEntry above}) {
    assert(
        above == null || (above._overlay == this && _entries.contains(above)));
    if (entries.isEmpty) return;
    for (OverlayEntry entry in entries) {
      assert(entry._overlay == null);
      entry._overlay = this;
    }
    setState(() {
      final int index =
          above == null ? _entries.length : _entries.indexOf(above) + 1;
      _entries.insertAll(index, entries);
    });
  }

  void _remove(OverlayEntry entry) {
    if (mounted) {
      _entries.remove(entry);
      setState(() {});
    }
  }

  bool debugIsVisible(OverlayEntry entry) {
    bool result = false;
    assert(_entries.contains(entry));
    assert(() {
      for (int i = _entries.length - 1; i > 0; i -= 1) {
        final OverlayEntry candidate = _entries[i];
        if (candidate == entry) {
          result = true;
          break;
        }
        if (candidate.opaque) break;
      }
      return true;
    }());
    return result;
  }

  void _didChangeEntryOpacity() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> onstageChildren = <Widget>[];
    final List<Widget> offstageChildren = <Widget>[];
    bool onstage = true;
    for (int i = _entries.length - 1; i >= 0; i -= 1) {
      final OverlayEntry entry = _entries[i];
      if (onstage) {
        onstageChildren.add(new _OverlayEntry(entry));
        if (entry.opaque) onstage = false;
      } else if (entry.maintainState) {
        offstageChildren.add(
            new TickerMode(enabled: false, child: new _OverlayEntry(entry)));
      }
    }
    return new _Theatre(
      onstage: new Stack(
        fit: StackFit.expand,
        children: onstageChildren.reversed.toList(growable: false),
      ),
      offstage: offstageChildren,
    );
  }
}

class _Theatre extends RenderObjectWidget {
  _Theatre({
    this.onstage,
    @required this.offstage,
  })  : assert(offstage != null),
        assert(!offstage.any((Widget child) => child == null));

  final Stack onstage;

  final List<Widget> offstage;

  @override
  _TheatreElement createElement() => new _TheatreElement(this);

  @override
  _RenderTheatre createRenderObject(BuildContext context) =>
      new _RenderTheatre();
}

class _TheatreElement extends RenderObjectElement {
  _TheatreElement(_Theatre widget)
      : assert(!debugChildrenHaveDuplicateKeys(widget, widget.offstage)),
        super(widget);

  @override
  _Theatre get widget => super.widget;

  @override
  _RenderTheatre get renderObject => super.renderObject;

  Element _onstage;
  static final Object _onstageSlot = new Object();

  List<Element> _offstage;
  final Set<Element> _forgottenOffstageChildren = new HashSet<Element>();

  @override
  void insertChildRenderObject(RenderBox child, dynamic slot) {
    if (slot == _onstageSlot) {
      assert(child is RenderStack);
      renderObject.child = child;
    } else {
      assert(slot == null || slot is Element);
      renderObject.insert(child, after: slot?.renderObject);
    }
  }

  @override
  void moveChildRenderObject(RenderBox child, dynamic slot) {
    if (slot == _onstageSlot) {
      renderObject.remove(child);
      assert(child is RenderStack);
      renderObject.child = child;
    } else {
      assert(slot == null || slot is Element);
      if (renderObject.child == child) {
        renderObject.child = null;
        renderObject.insert(child, after: slot?.renderObject);
      } else {
        renderObject.move(child, after: slot?.renderObject);
      }
    }
  }

  @override
  void removeChildRenderObject(RenderBox child) {
    if (renderObject.child == child) {
      renderObject.child = null;
    } else {
      renderObject.remove(child);
    }
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    if (_onstage != null) visitor(_onstage);
    for (Element child in _offstage) {
      if (!_forgottenOffstageChildren.contains(child)) visitor(child);
    }
  }

  @override
  void debugVisitOnstageChildren(ElementVisitor visitor) {
    if (_onstage != null) visitor(_onstage);
  }

  @override
  bool forgetChild(Element child) {
    if (child == _onstage) {
      _onstage = null;
    } else {
      assert(_offstage.contains(child));
      assert(!_forgottenOffstageChildren.contains(child));
      _forgottenOffstageChildren.add(child);
    }
    return true;
  }

  @override
  void mount(Element parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    _onstage = updateChild(_onstage, widget.onstage, _onstageSlot);
    _offstage = new List<Element>(widget.offstage.length);
    Element previousChild;
    for (int i = 0; i < _offstage.length; i += 1) {
      final Element newChild = inflateWidget(widget.offstage[i], previousChild);
      _offstage[i] = newChild;
      previousChild = newChild;
    }
  }

  @override
  void update(_Theatre newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    _onstage = updateChild(_onstage, widget.onstage, _onstageSlot);
    _offstage = updateChildren(_offstage, widget.offstage,
        forgottenChildren: _forgottenOffstageChildren);
    _forgottenOffstageChildren.clear();
  }
}

class _RenderTheatre extends RenderBox
    with
        RenderObjectWithChildMixin<RenderStack>,
        RenderProxyBoxMixin<RenderStack>,
        ContainerRenderObjectMixin<RenderBox, StackParentData> {
  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! StackParentData)
      child.parentData = StackParentData();
  }

  @override
  void redepthChildren() {
    if (child != null) redepthChild(child);
    super.redepthChildren();
  }

  @override
  void visitChildren(RenderObjectVisitor visitor) {
    if (child != null) visitor(child);
    super.visitChildren(visitor);
  }

  @override
  List<DiagnosticsNode> debugDescribeChildren() {
    final List<DiagnosticsNode> children = <DiagnosticsNode>[];

    if (child != null) children.add(child.toDiagnosticsNode(name: 'onstage'));

    if (firstChild != null) {
      RenderBox child = firstChild;

      int count = 1;
      while (true) {
        children.add(
          child.toDiagnosticsNode(
            name: 'offstage $count',
            style: DiagnosticsTreeStyle.offstage,
          ),
        );
        if (child == lastChild) break;
        final StackParentData childParentData = child.parentData;
        child = childParentData.nextSibling;
        count += 1;
      }
    } else {
      children.add(
        DiagnosticsNode.message(
          'no offstage children',
          style: DiagnosticsTreeStyle.offstage,
        ),
      );
    }
    return children;
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    if (child != null) visitor(child);
  }
}

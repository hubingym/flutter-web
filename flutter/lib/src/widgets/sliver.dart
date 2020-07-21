import 'dart:collection' show SplayTreeMap, HashMap;

import 'package:flutter_web/foundation.dart';
import 'package:flutter_web/rendering.dart';

import 'automatic_keep_alive.dart';
import 'basic.dart';
import 'framework.dart';

export 'package:flutter_web/rendering.dart'
    show
        SliverGridDelegate,
        SliverGridDelegateWithFixedCrossAxisCount,
        SliverGridDelegateWithMaxCrossAxisExtent;

typedef SemanticIndexCallback = int Function(Widget widget, int localIndex);

int _kDefaultSemanticIndexCallback(Widget _, int localIndex) => localIndex;

abstract class SliverChildDelegate {
  const SliverChildDelegate();

  Widget build(BuildContext context, int index);

  int get estimatedChildCount => null;

  double estimateMaxScrollOffset(
    int firstIndex,
    int lastIndex,
    double leadingScrollOffset,
    double trailingScrollOffset,
  ) =>
      null;

  void didFinishLayout(int firstIndex, int lastIndex) {}

  bool shouldRebuild(covariant SliverChildDelegate oldDelegate);

  int findIndexByKey(Key key) => null;

  @override
  String toString() {
    final List<String> description = <String>[];
    debugFillDescription(description);
    return '${describeIdentity(this)}(${description.join(", ")})';
  }

  @protected
  @mustCallSuper
  void debugFillDescription(List<String> description) {
    try {
      final int children = estimatedChildCount;
      if (children != null) description.add('estimated child count: $children');
    } catch (e) {
      description.add('estimated child count: EXCEPTION (${e.runtimeType})');
    }
  }
}

class _SaltedValueKey extends ValueKey<Key> {
  const _SaltedValueKey(Key key)
      : assert(key != null),
        super(key);
}

typedef ChildIndexGetter = int Function(Key key);

class SliverChildBuilderDelegate extends SliverChildDelegate {
  const SliverChildBuilderDelegate(
    this.builder, {
    this.findChildIndexCallback,
    this.childCount,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
    this.semanticIndexCallback = _kDefaultSemanticIndexCallback,
    this.semanticIndexOffset = 0,
  })  : assert(builder != null),
        assert(addAutomaticKeepAlives != null),
        assert(addRepaintBoundaries != null),
        assert(addSemanticIndexes != null),
        assert(semanticIndexCallback != null);

  final IndexedWidgetBuilder builder;

  final int childCount;

  final bool addAutomaticKeepAlives;

  final bool addRepaintBoundaries;

  final bool addSemanticIndexes;

  final int semanticIndexOffset;

  final SemanticIndexCallback semanticIndexCallback;

  final ChildIndexGetter findChildIndexCallback;

  @override
  int findIndexByKey(Key key) {
    if (findChildIndexCallback == null) return null;
    assert(key != null);
    Key childKey;
    if (key is _SaltedValueKey) {
      final _SaltedValueKey saltedValueKey = key;
      childKey = saltedValueKey.value;
    } else {
      childKey = key;
    }
    return findChildIndexCallback(childKey);
  }

  @override
  Widget build(BuildContext context, int index) {
    assert(builder != null);
    if (index < 0 || (childCount != null && index >= childCount)) return null;
    Widget child;
    try {
      child = builder(context, index);
    } catch (exception, stackTrace) {
      child = _createErrorWidget(exception, stackTrace);
    }
    if (child == null) return null;
    final Key key = child.key != null ? _SaltedValueKey(child.key) : null;
    if (addRepaintBoundaries) child = RepaintBoundary(child: child);
    if (addSemanticIndexes) {
      final int semanticIndex = semanticIndexCallback(child, index);
      if (semanticIndex != null)
        child = IndexedSemantics(
            index: semanticIndex + semanticIndexOffset, child: child);
    }
    if (addAutomaticKeepAlives) child = AutomaticKeepAlive(child: child);
    return KeyedSubtree(child: child, key: key);
  }

  @override
  int get estimatedChildCount => childCount;

  @override
  bool shouldRebuild(covariant SliverChildBuilderDelegate oldDelegate) => true;
}

class SliverChildListDelegate extends SliverChildDelegate {
  SliverChildListDelegate(
    this.children, {
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
    this.semanticIndexCallback = _kDefaultSemanticIndexCallback,
    this.semanticIndexOffset = 0,
  })  : assert(children != null),
        assert(addAutomaticKeepAlives != null),
        assert(addRepaintBoundaries != null),
        assert(addSemanticIndexes != null),
        assert(semanticIndexCallback != null),
        _keyToIndex = <Key, int>{null: 0};

  const SliverChildListDelegate.fixed(
    this.children, {
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
    this.semanticIndexCallback = _kDefaultSemanticIndexCallback,
    this.semanticIndexOffset = 0,
  })  : assert(children != null),
        assert(addAutomaticKeepAlives != null),
        assert(addRepaintBoundaries != null),
        assert(addSemanticIndexes != null),
        assert(semanticIndexCallback != null),
        _keyToIndex = null;

  final bool addAutomaticKeepAlives;

  final bool addRepaintBoundaries;

  final bool addSemanticIndexes;

  final int semanticIndexOffset;

  final SemanticIndexCallback semanticIndexCallback;

  final List<Widget> children;

  final Map<Key, int> _keyToIndex;

  bool get _isConstantInstance => _keyToIndex == null;

  int _findChildIndex(Key key) {
    if (_isConstantInstance) {
      return null;
    }

    if (!_keyToIndex.containsKey(key)) {
      int index = _keyToIndex[null];
      while (index < children.length) {
        final Widget child = children[index];
        if (child.key != null) {
          _keyToIndex[child.key] = index;
        }
        if (child.key == key) {
          _keyToIndex[null] = index + 1;
          return index;
        }
        index += 1;
      }
      _keyToIndex[null] = index;
    } else {
      return _keyToIndex[key];
    }
    return null;
  }

  @override
  int findIndexByKey(Key key) {
    assert(key != null);
    Key childKey;
    if (key is _SaltedValueKey) {
      final _SaltedValueKey saltedValueKey = key;
      childKey = saltedValueKey.value;
    } else {
      childKey = key;
    }
    return _findChildIndex(childKey);
  }

  @override
  Widget build(BuildContext context, int index) {
    assert(children != null);
    if (index < 0 || index >= children.length) return null;
    Widget child = children[index];
    final Key key = child.key != null ? _SaltedValueKey(child.key) : null;
    assert(child != null,
        "The sliver's children must not contain null values, but a null value was found at index $index");
    if (addRepaintBoundaries) child = RepaintBoundary(child: child);
    if (addSemanticIndexes) {
      final int semanticIndex = semanticIndexCallback(child, index);
      if (semanticIndex != null)
        child = IndexedSemantics(
            index: semanticIndex + semanticIndexOffset, child: child);
    }
    if (addAutomaticKeepAlives) child = AutomaticKeepAlive(child: child);
    return KeyedSubtree(child: child, key: key);
  }

  @override
  int get estimatedChildCount => children.length;

  @override
  bool shouldRebuild(covariant SliverChildListDelegate oldDelegate) {
    return children != oldDelegate.children;
  }
}

abstract class SliverWithKeepAliveWidget extends RenderObjectWidget {
  const SliverWithKeepAliveWidget({
    Key key,
  }) : super(key: key);

  @override
  RenderSliverWithKeepAliveMixin createRenderObject(BuildContext context);
}

abstract class SliverMultiBoxAdaptorWidget extends SliverWithKeepAliveWidget {
  const SliverMultiBoxAdaptorWidget({
    Key key,
    @required this.delegate,
  })  : assert(delegate != null),
        super(key: key);

  final SliverChildDelegate delegate;

  @override
  SliverMultiBoxAdaptorElement createElement() =>
      SliverMultiBoxAdaptorElement(this);

  @override
  RenderSliverMultiBoxAdaptor createRenderObject(BuildContext context);

  double estimateMaxScrollOffset(
    SliverConstraints constraints,
    int firstIndex,
    int lastIndex,
    double leadingScrollOffset,
    double trailingScrollOffset,
  ) {
    assert(lastIndex >= firstIndex);
    return delegate.estimateMaxScrollOffset(
      firstIndex,
      lastIndex,
      leadingScrollOffset,
      trailingScrollOffset,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(DiagnosticsProperty<SliverChildDelegate>('delegate', delegate));
  }
}

class SliverList extends SliverMultiBoxAdaptorWidget {
  const SliverList({
    Key key,
    @required SliverChildDelegate delegate,
  }) : super(key: key, delegate: delegate);

  @override
  RenderSliverList createRenderObject(BuildContext context) {
    final SliverMultiBoxAdaptorElement element = context;
    return RenderSliverList(childManager: element);
  }
}

class SliverFixedExtentList extends SliverMultiBoxAdaptorWidget {
  const SliverFixedExtentList({
    Key key,
    @required SliverChildDelegate delegate,
    @required this.itemExtent,
  }) : super(key: key, delegate: delegate);

  final double itemExtent;

  @override
  RenderSliverFixedExtentList createRenderObject(BuildContext context) {
    final SliverMultiBoxAdaptorElement element = context;
    return RenderSliverFixedExtentList(
        childManager: element, itemExtent: itemExtent);
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderSliverFixedExtentList renderObject) {
    renderObject.itemExtent = itemExtent;
  }
}

class SliverGrid extends SliverMultiBoxAdaptorWidget {
  const SliverGrid({
    Key key,
    @required SliverChildDelegate delegate,
    @required this.gridDelegate,
  }) : super(key: key, delegate: delegate);

  SliverGrid.count({
    Key key,
    @required int crossAxisCount,
    double mainAxisSpacing = 0.0,
    double crossAxisSpacing = 0.0,
    double childAspectRatio = 1.0,
    List<Widget> children = const <Widget>[],
  })  : gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: mainAxisSpacing,
          crossAxisSpacing: crossAxisSpacing,
          childAspectRatio: childAspectRatio,
        ),
        super(key: key, delegate: SliverChildListDelegate(children));

  SliverGrid.extent({
    Key key,
    @required double maxCrossAxisExtent,
    double mainAxisSpacing = 0.0,
    double crossAxisSpacing = 0.0,
    double childAspectRatio = 1.0,
    List<Widget> children = const <Widget>[],
  })  : gridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: maxCrossAxisExtent,
          mainAxisSpacing: mainAxisSpacing,
          crossAxisSpacing: crossAxisSpacing,
          childAspectRatio: childAspectRatio,
        ),
        super(key: key, delegate: SliverChildListDelegate(children));

  final SliverGridDelegate gridDelegate;

  @override
  RenderSliverGrid createRenderObject(BuildContext context) {
    final SliverMultiBoxAdaptorElement element = context;
    return RenderSliverGrid(childManager: element, gridDelegate: gridDelegate);
  }

  @override
  void updateRenderObject(BuildContext context, RenderSliverGrid renderObject) {
    renderObject.gridDelegate = gridDelegate;
  }

  @override
  double estimateMaxScrollOffset(
    SliverConstraints constraints,
    int firstIndex,
    int lastIndex,
    double leadingScrollOffset,
    double trailingScrollOffset,
  ) {
    return super.estimateMaxScrollOffset(
          constraints,
          firstIndex,
          lastIndex,
          leadingScrollOffset,
          trailingScrollOffset,
        ) ??
        gridDelegate
            .getLayout(constraints)
            .computeMaxScrollOffset(delegate.estimatedChildCount);
  }
}

class SliverFillViewport extends SliverMultiBoxAdaptorWidget {
  const SliverFillViewport({
    Key key,
    @required SliverChildDelegate delegate,
    this.viewportFraction = 1.0,
  })  : assert(viewportFraction != null),
        assert(viewportFraction > 0.0),
        super(key: key, delegate: delegate);

  final double viewportFraction;

  @override
  RenderSliverFillViewport createRenderObject(BuildContext context) {
    final SliverMultiBoxAdaptorElement element = context;
    return RenderSliverFillViewport(
        childManager: element, viewportFraction: viewportFraction);
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderSliverFillViewport renderObject) {
    renderObject.viewportFraction = viewportFraction;
  }
}

class SliverMultiBoxAdaptorElement extends RenderObjectElement
    implements RenderSliverBoxChildManager {
  SliverMultiBoxAdaptorElement(SliverMultiBoxAdaptorWidget widget)
      : super(widget);

  @override
  SliverMultiBoxAdaptorWidget get widget => super.widget;

  @override
  RenderSliverMultiBoxAdaptor get renderObject => super.renderObject;

  @override
  void update(covariant SliverMultiBoxAdaptorWidget newWidget) {
    final SliverMultiBoxAdaptorWidget oldWidget = widget;
    super.update(newWidget);
    final SliverChildDelegate newDelegate = newWidget.delegate;
    final SliverChildDelegate oldDelegate = oldWidget.delegate;
    if (newDelegate != oldDelegate &&
        (newDelegate.runtimeType != oldDelegate.runtimeType ||
            newDelegate.shouldRebuild(oldDelegate))) performRebuild();
  }

  final Map<int, Widget> _childWidgets = HashMap<int, Widget>();
  final SplayTreeMap<int, Element> _childElements =
      SplayTreeMap<int, Element>();
  RenderBox _currentBeforeChild;

  @override
  void performRebuild() {
    _childWidgets.clear();
    super.performRebuild();
    _currentBeforeChild = null;
    assert(_currentlyUpdatingChildIndex == null);
    try {
      final SplayTreeMap<int, Element> newChildren =
          SplayTreeMap<int, Element>();

      void processElement(int index) {
        _currentlyUpdatingChildIndex = index;
        if (_childElements[index] != null &&
            _childElements[index] != newChildren[index]) {
          _childElements[index] =
              updateChild(_childElements[index], null, index);
        }
        final Element newChild =
            updateChild(newChildren[index], _build(index), index);
        if (newChild != null) {
          _childElements[index] = newChild;
          final SliverMultiBoxAdaptorParentData parentData =
              newChild.renderObject.parentData;
          if (!parentData.keptAlive)
            _currentBeforeChild = newChild.renderObject;
        } else {
          _childElements.remove(index);
        }
      }

      for (int index in _childElements.keys.toList()) {
        final Key key = _childElements[index].widget.key;
        final int newIndex =
            key == null ? null : widget.delegate.findIndexByKey(key);
        if (newIndex != null && newIndex != index) {
          newChildren[newIndex] = _childElements[index];

          newChildren.putIfAbsent(index, () => null);

          _childElements.remove(index);
        } else {
          newChildren.putIfAbsent(index, () => _childElements[index]);
        }
      }

      renderObject.debugChildIntegrityEnabled = false;
      newChildren.keys.forEach(processElement);
      if (_didUnderflow) {
        final int lastKey = _childElements.lastKey() ?? -1;
        final int rightBoundary = lastKey + 1;
        newChildren[rightBoundary] = _childElements[rightBoundary];
        processElement(rightBoundary);
      }
    } finally {
      _currentlyUpdatingChildIndex = null;
      renderObject.debugChildIntegrityEnabled = true;
    }
  }

  Widget _build(int index) {
    return _childWidgets.putIfAbsent(
        index, () => widget.delegate.build(this, index));
  }

  @override
  void createChild(int index, {@required RenderBox after}) {
    assert(_currentlyUpdatingChildIndex == null);
    owner.buildScope(this, () {
      final bool insertFirst = after == null;
      assert(insertFirst || _childElements[index - 1] != null);
      _currentBeforeChild =
          insertFirst ? null : _childElements[index - 1].renderObject;
      Element newChild;
      try {
        _currentlyUpdatingChildIndex = index;
        newChild = updateChild(_childElements[index], _build(index), index);
      } finally {
        _currentlyUpdatingChildIndex = null;
      }
      if (newChild != null) {
        _childElements[index] = newChild;
      } else {
        _childElements.remove(index);
      }
    });
  }

  @override
  Element updateChild(Element child, Widget newWidget, dynamic newSlot) {
    final SliverMultiBoxAdaptorParentData oldParentData =
        child?.renderObject?.parentData;
    final Element newChild = super.updateChild(child, newWidget, newSlot);
    final SliverMultiBoxAdaptorParentData newParentData =
        newChild?.renderObject?.parentData;

    if (oldParentData != newParentData &&
        oldParentData != null &&
        newParentData != null) {
      newParentData.layoutOffset = oldParentData.layoutOffset;
    }
    return newChild;
  }

  @override
  void forgetChild(Element child) {
    assert(child != null);
    assert(child.slot != null);
    assert(_childElements.containsKey(child.slot));
    _childElements.remove(child.slot);
  }

  @override
  void removeChild(RenderBox child) {
    final int index = renderObject.indexOf(child);
    assert(_currentlyUpdatingChildIndex == null);
    assert(index >= 0);
    owner.buildScope(this, () {
      assert(_childElements.containsKey(index));
      try {
        _currentlyUpdatingChildIndex = index;
        final Element result = updateChild(_childElements[index], null, index);
        assert(result == null);
      } finally {
        _currentlyUpdatingChildIndex = null;
      }
      _childElements.remove(index);
      assert(!_childElements.containsKey(index));
    });
  }

  static double _extrapolateMaxScrollOffset(
    int firstIndex,
    int lastIndex,
    double leadingScrollOffset,
    double trailingScrollOffset,
    int childCount,
  ) {
    if (lastIndex == childCount - 1) return trailingScrollOffset;
    final int reifiedCount = lastIndex - firstIndex + 1;
    final double averageExtent =
        (trailingScrollOffset - leadingScrollOffset) / reifiedCount;
    final int remainingCount = childCount - lastIndex - 1;
    return trailingScrollOffset + averageExtent * remainingCount;
  }

  @override
  double estimateMaxScrollOffset(
    SliverConstraints constraints, {
    int firstIndex,
    int lastIndex,
    double leadingScrollOffset,
    double trailingScrollOffset,
  }) {
    final int childCount = this.childCount;
    if (childCount == null) return double.infinity;
    return widget.estimateMaxScrollOffset(
          constraints,
          firstIndex,
          lastIndex,
          leadingScrollOffset,
          trailingScrollOffset,
        ) ??
        _extrapolateMaxScrollOffset(
          firstIndex,
          lastIndex,
          leadingScrollOffset,
          trailingScrollOffset,
          childCount,
        );
  }

  @override
  int get childCount => widget.delegate.estimatedChildCount;

  @override
  void didStartLayout() {
    assert(debugAssertChildListLocked());
  }

  @override
  void didFinishLayout() {
    assert(debugAssertChildListLocked());
    final int firstIndex = _childElements.firstKey() ?? 0;
    final int lastIndex = _childElements.lastKey() ?? 0;
    widget.delegate.didFinishLayout(firstIndex, lastIndex);
  }

  int _currentlyUpdatingChildIndex;

  @override
  bool debugAssertChildListLocked() {
    assert(_currentlyUpdatingChildIndex == null);
    return true;
  }

  @override
  void didAdoptChild(RenderBox child) {
    assert(_currentlyUpdatingChildIndex != null);
    final SliverMultiBoxAdaptorParentData childParentData = child.parentData;
    childParentData.index = _currentlyUpdatingChildIndex;
  }

  bool _didUnderflow = false;

  @override
  void setDidUnderflow(bool value) {
    _didUnderflow = value;
  }

  @override
  void insertChildRenderObject(covariant RenderObject child, int slot) {
    assert(slot != null);
    assert(_currentlyUpdatingChildIndex == slot);
    assert(renderObject.debugValidateChild(child));
    renderObject.insert(child, after: _currentBeforeChild);
    assert(() {
      final SliverMultiBoxAdaptorParentData childParentData = child.parentData;
      assert(slot == childParentData.index);
      return true;
    }());
  }

  @override
  void moveChildRenderObject(covariant RenderObject child, int slot) {
    assert(slot != null);
    assert(_currentlyUpdatingChildIndex == slot);
    renderObject.move(child, after: _currentBeforeChild);
  }

  @override
  void removeChildRenderObject(covariant RenderObject child) {
    assert(_currentlyUpdatingChildIndex != null);
    renderObject.remove(child);
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    assert(!_childElements.values.any((Element child) => child == null));
    _childElements.values.toList().forEach(visitor);
  }

  @override
  void debugVisitOnstageChildren(ElementVisitor visitor) {
    _childElements.values.where((Element child) {
      final SliverMultiBoxAdaptorParentData parentData =
          child.renderObject.parentData;
      double itemExtent;
      switch (renderObject.constraints.axis) {
        case Axis.horizontal:
          itemExtent = child.renderObject.paintBounds.width;
          break;
        case Axis.vertical:
          itemExtent = child.renderObject.paintBounds.height;
          break;
      }

      return parentData.layoutOffset <
              renderObject.constraints.scrollOffset +
                  renderObject.constraints.remainingPaintExtent &&
          parentData.layoutOffset + itemExtent >
              renderObject.constraints.scrollOffset;
    }).forEach(visitor);
  }
}

class SliverFillRemaining extends SingleChildRenderObjectWidget {
  const SliverFillRemaining({
    Key key,
    Widget child,
  }) : super(key: key, child: child);

  @override
  RenderSliverFillRemaining createRenderObject(BuildContext context) =>
      RenderSliverFillRemaining();
}

class KeepAlive extends ParentDataWidget<SliverWithKeepAliveWidget> {
  const KeepAlive({
    Key key,
    @required this.keepAlive,
    @required Widget child,
  })  : assert(child != null),
        assert(keepAlive != null),
        super(key: key, child: child);

  final bool keepAlive;

  @override
  void applyParentData(RenderObject renderObject) {
    assert(renderObject.parentData is KeepAliveParentDataMixin);
    final KeepAliveParentDataMixin parentData = renderObject.parentData;
    if (parentData.keepAlive != keepAlive) {
      parentData.keepAlive = keepAlive;
      final AbstractNode targetParent = renderObject.parent;
      if (targetParent is RenderObject && !keepAlive)
        targetParent.markNeedsLayout();
    }
  }

  @override
  bool debugCanApplyOutOfTurn() => keepAlive;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('keepAlive', keepAlive));
  }
}

Widget _createErrorWidget(dynamic exception, StackTrace stackTrace) {
  final FlutterErrorDetails details = FlutterErrorDetails(
    exception: exception,
    stack: stackTrace,
    library: 'widgets library',
    context: ErrorDescription('building'),
  );
  FlutterError.reportError(details);
  return ErrorWidget.builder(details);
}

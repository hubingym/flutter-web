import 'package:flutter_web/rendering.dart';

import 'basic.dart';
import 'framework.dart';
import 'sliver.dart';

class SliverPrototypeExtentList extends SliverMultiBoxAdaptorWidget {
  const SliverPrototypeExtentList({
    Key key,
    @required SliverChildDelegate delegate,
    @required this.prototypeItem,
  })  : assert(prototypeItem != null),
        super(key: key, delegate: delegate);

  final Widget prototypeItem;

  @override
  _RenderSliverPrototypeExtentList createRenderObject(BuildContext context) {
    final _SliverPrototypeExtentListElement element = context;
    return _RenderSliverPrototypeExtentList(childManager: element);
  }

  @override
  _SliverPrototypeExtentListElement createElement() =>
      _SliverPrototypeExtentListElement(this);
}

class _SliverPrototypeExtentListElement extends SliverMultiBoxAdaptorElement {
  _SliverPrototypeExtentListElement(SliverPrototypeExtentList widget)
      : super(widget);

  @override
  SliverPrototypeExtentList get widget => super.widget;

  @override
  _RenderSliverPrototypeExtentList get renderObject => super.renderObject;

  Element _prototype;
  static final Object _prototypeSlot = Object();

  @override
  void insertChildRenderObject(
      covariant RenderObject child, covariant dynamic slot) {
    if (slot == _prototypeSlot) {
      assert(child is RenderBox);
      renderObject.child = child;
    } else {
      super.insertChildRenderObject(child, slot);
    }
  }

  @override
  void didAdoptChild(RenderBox child) {
    if (child != renderObject.child) super.didAdoptChild(child);
  }

  @override
  void moveChildRenderObject(RenderBox child, dynamic slot) {
    if (slot == _prototypeSlot)
      assert(false);
    else
      super.moveChildRenderObject(child, slot);
  }

  @override
  void removeChildRenderObject(RenderBox child) {
    if (renderObject.child == child)
      renderObject.child = null;
    else
      super.removeChildRenderObject(child);
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    if (_prototype != null) visitor(_prototype);
    super.visitChildren(visitor);
  }

  @override
  void mount(Element parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    _prototype = updateChild(_prototype, widget.prototypeItem, _prototypeSlot);
  }

  @override
  void update(SliverPrototypeExtentList newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    _prototype = updateChild(_prototype, widget.prototypeItem, _prototypeSlot);
  }
}

class _RenderSliverPrototypeExtentList
    extends RenderSliverFixedExtentBoxAdaptor {
  _RenderSliverPrototypeExtentList({
    @required _SliverPrototypeExtentListElement childManager,
  }) : super(childManager: childManager);

  RenderBox _child;
  RenderBox get child => _child;
  set child(RenderBox value) {
    if (_child != null) dropChild(_child);
    _child = value;
    if (_child != null) adoptChild(_child);
    markNeedsLayout();
  }

  @override
  void performLayout() {
    child.layout(constraints.asBoxConstraints(), parentUsesSize: true);
    super.performLayout();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    if (_child != null) _child.attach(owner);
  }

  @override
  void detach() {
    super.detach();
    if (_child != null) _child.detach();
  }

  @override
  void redepthChildren() {
    if (_child != null) redepthChild(_child);
    super.redepthChildren();
  }

  @override
  void visitChildren(RenderObjectVisitor visitor) {
    if (_child != null) visitor(_child);
    super.visitChildren(visitor);
  }

  @override
  double get itemExtent {
    assert(child != null && child.hasSize);
    return constraints.axis == Axis.vertical
        ? child.size.height
        : child.size.width;
  }
}

import 'package:meta/meta.dart';

class AbstractNode {
  int get depth => _depth;
  int _depth = 0;

  @protected
  void redepthChild(AbstractNode child) {
    assert(child.owner == owner);
    if (child._depth <= _depth) {
      child._depth = _depth + 1;
      child.redepthChildren();
    }
  }

  void redepthChildren() {}

  Object get owner => _owner;
  Object _owner;

  bool get attached => _owner != null;

  @mustCallSuper
  void attach(covariant Object owner) {
    assert(owner != null);
    assert(_owner == null);
    _owner = owner;
  }

  @mustCallSuper
  void detach() {
    assert(_owner != null);
    _owner = null;
    assert(parent == null || attached == parent.attached);
  }

  AbstractNode get parent => _parent;
  AbstractNode _parent;

  @protected
  @mustCallSuper
  void adoptChild(covariant AbstractNode child) {
    assert(child != null);
    assert(child._parent == null);
    assert(() {
      AbstractNode node = this;
      while (node.parent != null) node = node.parent;
      assert(node != child);
      return true;
    }());
    child._parent = this;
    if (attached) {
      child.attach(_owner);
    }
    redepthChild(child);
  }

  @protected
  @mustCallSuper
  void dropChild(covariant AbstractNode child) {
    assert(child != null);
    assert(child._parent == this);
    assert(child.attached == attached);
    child._parent = null;
    if (attached) {
      child.detach();
    }
  }
}

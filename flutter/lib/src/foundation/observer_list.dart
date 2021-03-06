import 'dart:collection';

class ObserverList<T> extends Iterable<T> {
  final List<T> _list = <T>[];
  bool _isDirty = false;
  HashSet<T> _set;

  void add(T item) {
    _isDirty = true;
    _list.add(item);
  }

  bool remove(T item) {
    _isDirty = true;
    return _list.remove(item);
  }

  @override
  bool contains(Object element) {
    if (_list.length < 15) {
      return _list.contains(element);
    }

    if (_isDirty) {
      if (_set == null) {
        _set = new HashSet<T>.from(_list);
      } else {
        _set.clear();
        _set.addAll(_list);
      }
      _isDirty = false;
    }

    return _set.contains(element);
  }

  @override
  Iterator<T> get iterator => _list.iterator;

  @override
  bool get isEmpty => _list.isEmpty;

  @override
  bool get isNotEmpty => _list.isNotEmpty;
}

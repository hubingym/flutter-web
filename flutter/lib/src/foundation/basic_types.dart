import 'dart:async';
import 'dart:collection';

export 'package:flutter_web/ui.dart' show VoidCallback;

typedef ValueChanged<T> = void Function(T value);

typedef ValueSetter<T> = void Function(T value);

typedef ValueGetter<T> = T Function();

typedef IterableFilter<T> = Iterable<T> Function(Iterable<T> input);

typedef AsyncCallback = Future<void> Function();

typedef AsyncValueSetter<T> = Future<void> Function(T value);

typedef AsyncValueGetter<T> = Future<T> Function();

class CachingIterable<E> extends IterableBase<E> {
  CachingIterable(this._prefillIterator);

  final Iterator<E> _prefillIterator;
  final List<E> _results = <E>[];

  @override
  Iterator<E> get iterator {
    return _LazyListIterator<E>(this);
  }

  @override
  Iterable<T> map<T>(T f(E e)) {
    return CachingIterable<T>(super.map<T>(f).iterator);
  }

  @override
  Iterable<E> where(bool test(E element)) {
    return CachingIterable<E>(super.where(test).iterator);
  }

  @override
  Iterable<T> expand<T>(Iterable<T> f(E element)) {
    return CachingIterable<T>(super.expand<T>(f).iterator);
  }

  @override
  Iterable<E> take(int count) {
    return CachingIterable<E>(super.take(count).iterator);
  }

  @override
  Iterable<E> takeWhile(bool test(E value)) {
    return CachingIterable<E>(super.takeWhile(test).iterator);
  }

  @override
  Iterable<E> skip(int count) {
    return CachingIterable<E>(super.skip(count).iterator);
  }

  @override
  Iterable<E> skipWhile(bool test(E value)) {
    return CachingIterable<E>(super.skipWhile(test).iterator);
  }

  @override
  int get length {
    _precacheEntireList();
    return _results.length;
  }

  @override
  List<E> toList({bool growable = true}) {
    _precacheEntireList();
    return List<E>.from(_results, growable: growable);
  }

  void _precacheEntireList() {
    while (_fillNext()) {}
  }

  bool _fillNext() {
    if (!_prefillIterator.moveNext()) return false;
    _results.add(_prefillIterator.current);
    return true;
  }
}

class _LazyListIterator<E> implements Iterator<E> {
  _LazyListIterator(this._owner) : _index = -1;

  final CachingIterable<E> _owner;
  int _index;

  @override
  E get current {
    assert(_index >= 0);
    if (_index < 0 || _index == _owner._results.length) return null;
    return _owner._results[_index];
  }

  @override
  bool moveNext() {
    if (_index >= _owner._results.length) return false;
    _index += 1;
    if (_index == _owner._results.length) return _owner._fillNext();
    return true;
  }
}

class Factory<T> {
  const Factory(this.constructor) : assert(constructor != null);

  final ValueGetter<T> constructor;

  Type get type => T;

  @override
  String toString() {
    return 'Factory(type: $type)';
  }
}

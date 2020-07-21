import 'dart:async';

class SynchronousFuture<T> implements Future<T> {
  SynchronousFuture(this._value);

  final T _value;

  @override
  Stream<T> asStream() {
    final StreamController<T> controller = new StreamController<T>();
    controller.add(_value);
    controller.close();
    return controller.stream;
  }

  @override
  Future<T> catchError(Function onError, {bool test(dynamic error)}) =>
      new Completer<T>().future;

  @override
  Future<E> then<E>(dynamic f(T value), {Function onError}) {
    final dynamic result = f(_value);
    if (result is Future<E>) return result;
    return new SynchronousFuture<E>(result);
  }

  @override
  Future<T> timeout(Duration timeLimit, {dynamic onTimeout()}) {
    return new Future<T>.value(_value).timeout(timeLimit, onTimeout: onTimeout);
  }

  @override
  Future<T> whenComplete(dynamic action()) {
    try {
      final dynamic result = action();
      if (result is Future) return result.then<T>((dynamic value) => _value);
      return this;
    } catch (e, stack) {
      return new Future<T>.error(e, stack);
    }
  }
}

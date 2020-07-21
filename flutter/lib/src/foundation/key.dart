import 'package:meta/meta.dart';
import 'package:flutter_web/ui.dart' show hashValues;

abstract class Key {
  const factory Key(String value) = ValueKey<String>;

  @protected
  const Key.empty();
}

abstract class LocalKey extends Key {
  const LocalKey() : super.empty();
}

class ValueKey<T> extends LocalKey {
  const ValueKey(this.value);

  final T value;

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) return false;
    final ValueKey<T> typedOther = other;
    return value == typedOther.value;
  }

  @override
  int get hashCode => hashValues(runtimeType, value);

  @override
  String toString() {
    final String valueString = T == String ? '<\'$value\'>' : '<$value>';

    if (runtimeType == new _TypeLiteral<ValueKey<T>>().type)
      return '[$valueString]';
    return '[$T $valueString]';
  }
}

class _TypeLiteral<T> {
  Type get type => T;
}

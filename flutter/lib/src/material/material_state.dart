import 'package:flutter_web/ui.dart' show Color;

enum MaterialState {
  hovered,

  focused,

  pressed,

  dragged,

  selected,

  disabled,

  error,
}

typedef MaterialPropertyResolver<T> = T Function(Set<MaterialState> states);

abstract class MaterialStateColor extends Color
    implements MaterialStateProperty<Color> {
  const MaterialStateColor(int defaultValue) : super(defaultValue);

  static MaterialStateColor resolveWith(
          MaterialPropertyResolver<Color> callback) =>
      _MaterialStateColor(callback);

  @override
  Color resolve(Set<MaterialState> states);
}

class _MaterialStateColor extends MaterialStateColor {
  _MaterialStateColor(this._resolve) : super(_resolve(_defaultStates).value);

  final MaterialPropertyResolver<Color> _resolve;

  static const Set<MaterialState> _defaultStates = <MaterialState>{};

  @override
  Color resolve(Set<MaterialState> states) => _resolve(states);
}

abstract class MaterialStateProperty<T> {
  T resolve(Set<MaterialState> states);

  static T resolveAs<T>(T value, Set<MaterialState> states) {
    if (value is MaterialStateProperty<T>) {
      final MaterialStateProperty<T> property = value;
      return property.resolve(states);
    }
    return value;
  }

  static MaterialStateProperty<T> resolveWith<T>(
          MaterialPropertyResolver<T> callback) =>
      _MaterialStateProperty<T>(callback);
}

class _MaterialStateProperty<T> implements MaterialStateProperty<T> {
  _MaterialStateProperty(this._resolve);

  final MaterialPropertyResolver<T> _resolve;

  @override
  T resolve(Set<MaterialState> states) => _resolve(states);
}

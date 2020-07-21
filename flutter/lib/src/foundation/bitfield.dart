import 'package:flutter_web/ui.dart' as ui show kMaxUnsignedSMI;

const int kMaxUnsignedSMI = ui.kMaxUnsignedSMI;

class BitField<T extends dynamic> {
  BitField(this._length)
      : assert(_length <= _smiBits),
        _bits = _allZeros;

  BitField.filled(this._length, bool value)
      : assert(_length <= _smiBits),
        _bits = value ? _allOnes : _allZeros;

  final int _length;
  int _bits;

  static const int _smiBits = 62;
  static const int _allZeros = 0;
  static const int _allOnes = kMaxUnsignedSMI;

  bool operator [](T index) {
    assert(index.index < _length);
    return (_bits & 1 << index.index) > 0;
  }

  void operator []=(T index, bool value) {
    assert(index.index < _length);
    if (value)
      _bits = _bits | (1 << index.index);
    else
      _bits = _bits & ~(1 << index.index);
  }

  void reset([bool value = false]) {
    _bits = value ? _allOnes : _allZeros;
  }
}

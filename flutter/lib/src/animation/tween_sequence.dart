import 'package:flutter_web/foundation.dart';

import 'animation.dart';
import 'tween.dart';

class TweenSequence<T> extends Animatable<T> {
  TweenSequence(List<TweenSequenceItem<T>> items)
      : assert(items != null),
        assert(items.isNotEmpty) {
    _items.addAll(items);

    double totalWeight = 0.0;
    for (TweenSequenceItem<T> item in _items) totalWeight += item.weight;
    assert(totalWeight > 0.0);

    double start = 0.0;
    for (int i = 0; i < _items.length; i += 1) {
      final double end =
          i == _items.length - 1 ? 1.0 : start + _items[i].weight / totalWeight;
      _intervals.add(_Interval(start, end));
      start = end;
    }
  }

  final List<TweenSequenceItem<T>> _items = <TweenSequenceItem<T>>[];
  final List<_Interval> _intervals = <_Interval>[];

  T _evaluateAt(double t, int index) {
    final TweenSequenceItem<T> element = _items[index];
    final double tInterval = _intervals[index].value(t);
    return element.tween.transform(tInterval);
  }

  @override
  T transform(double t) {
    assert(t >= 0.0 && t <= 1.0);
    if (t == 1.0) return _evaluateAt(t, _items.length - 1);
    for (int index = 0; index < _items.length; index++) {
      if (_intervals[index].contains(t)) return _evaluateAt(t, index);
    }

    assert(false, 'TweenSequence.evaluate() could not find a interval for $t');
    return null;
  }

  @override
  String toString() => 'TweenSequence(${_items.length} items)';
}

class TweenSequenceItem<T> {
  const TweenSequenceItem({
    @required this.tween,
    @required this.weight,
  })  : assert(tween != null),
        assert(weight != null),
        assert(weight > 0.0);

  final Animatable<T> tween;

  final double weight;
}

class _Interval {
  const _Interval(this.start, this.end) : assert(end > start);

  final double start;
  final double end;

  bool contains(double t) => t >= start && t < end;

  double value(double t) => (t - start) / (end - start);

  @override
  String toString() => '<$start, $end>';
}

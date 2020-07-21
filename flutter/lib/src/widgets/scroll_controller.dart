import 'dart:async';

import 'package:flutter_web/animation.dart';
import 'package:flutter_web/foundation.dart';

import 'scroll_context.dart';
import 'scroll_physics.dart';
import 'scroll_position.dart';
import 'scroll_position_with_single_context.dart';

class ScrollController extends ChangeNotifier {
  ScrollController({
    double initialScrollOffset = 0.0,
    this.keepScrollOffset = true,
    this.debugLabel,
  })  : assert(initialScrollOffset != null),
        assert(keepScrollOffset != null),
        _initialScrollOffset = initialScrollOffset;

  double get initialScrollOffset => _initialScrollOffset;
  final double _initialScrollOffset;

  final bool keepScrollOffset;

  final String debugLabel;

  @protected
  Iterable<ScrollPosition> get positions => _positions;
  final List<ScrollPosition> _positions = <ScrollPosition>[];

  bool get hasClients => _positions.isNotEmpty;

  ScrollPosition get position {
    assert(_positions.isNotEmpty,
        'ScrollController not attached to any scroll views.');
    assert(_positions.length == 1,
        'ScrollController attached to multiple scroll views.');
    return _positions.single;
  }

  double get offset => position.pixels;

  Future<void> animateTo(
    double offset, {
    @required Duration duration,
    @required Curve curve,
  }) {
    assert(_positions.isNotEmpty,
        'ScrollController not attached to any scroll views.');
    final List<Future<void>> animations = List<Future<void>>(_positions.length);
    for (int i = 0; i < _positions.length; i += 1)
      animations[i] =
          _positions[i].animateTo(offset, duration: duration, curve: curve);
    return Future.wait<void>(animations).then<void>((List<void> _) => null);
  }

  void jumpTo(double value) {
    assert(_positions.isNotEmpty,
        'ScrollController not attached to any scroll views.');
    for (ScrollPosition position in List<ScrollPosition>.from(_positions))
      position.jumpTo(value);
  }

  void attach(ScrollPosition position) {
    assert(!_positions.contains(position));
    _positions.add(position);
    position.addListener(notifyListeners);
  }

  void detach(ScrollPosition position) {
    assert(_positions.contains(position));
    position.removeListener(notifyListeners);
    _positions.remove(position);
  }

  @override
  void dispose() {
    for (ScrollPosition position in _positions)
      position.removeListener(notifyListeners);
    super.dispose();
  }

  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition oldPosition,
  ) {
    return ScrollPositionWithSingleContext(
      physics: physics,
      context: context,
      initialPixels: initialScrollOffset,
      keepScrollOffset: keepScrollOffset,
      oldPosition: oldPosition,
      debugLabel: debugLabel,
    );
  }

  @override
  String toString() {
    final List<String> description = <String>[];
    debugFillDescription(description);
    return '${describeIdentity(this)}(${description.join(", ")})';
  }

  @mustCallSuper
  void debugFillDescription(List<String> description) {
    if (debugLabel != null) description.add(debugLabel);
    if (initialScrollOffset != 0.0)
      description.add(
          'initialScrollOffset: ${initialScrollOffset.toStringAsFixed(1)}, ');
    if (_positions.isEmpty) {
      description.add('no clients');
    } else if (_positions.length == 1) {
      description.add('one client, offset ${offset?.toStringAsFixed(1)}');
    } else {
      description.add('${_positions.length} clients');
    }
  }
}

class TrackingScrollController extends ScrollController {
  TrackingScrollController({
    double initialScrollOffset = 0.0,
    bool keepScrollOffset = true,
    String debugLabel,
  }) : super(
            initialScrollOffset: initialScrollOffset,
            keepScrollOffset: keepScrollOffset,
            debugLabel: debugLabel);

  final Map<ScrollPosition, VoidCallback> _positionToListener =
      <ScrollPosition, VoidCallback>{};
  ScrollPosition _lastUpdated;
  double _lastUpdatedOffset;

  ScrollPosition get mostRecentlyUpdatedPosition => _lastUpdated;

  @override
  double get initialScrollOffset =>
      _lastUpdatedOffset ?? super.initialScrollOffset;

  @override
  void attach(ScrollPosition position) {
    super.attach(position);
    assert(!_positionToListener.containsKey(position));
    _positionToListener[position] = () {
      _lastUpdated = position;
      _lastUpdatedOffset = position.pixels;
    };
    position.addListener(_positionToListener[position]);
  }

  @override
  void detach(ScrollPosition position) {
    super.detach(position);
    assert(_positionToListener.containsKey(position));
    position.removeListener(_positionToListener[position]);
    _positionToListener.remove(position);
    if (_lastUpdated == position) _lastUpdated = null;
    if (_positionToListener.isEmpty) _lastUpdatedOffset = null;
  }

  @override
  void dispose() {
    for (ScrollPosition position in positions) {
      assert(_positionToListener.containsKey(position));
      position.removeListener(_positionToListener[position]);
    }
    super.dispose();
  }
}

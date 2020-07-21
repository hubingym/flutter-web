import 'dart:collection';

import 'package:flutter_web/ui.dart';
import 'package:flutter_web/foundation.dart';

import 'package:vector_math/vector_math_64.dart';

import 'events.dart';

abstract class HitTestable {
  factory HitTestable._() => null;

  void hitTest(HitTestResult result, Offset position);
}

abstract class HitTestDispatcher {
  factory HitTestDispatcher._() => null;

  void dispatchEvent(PointerEvent event, HitTestResult result);
}

abstract class HitTestTarget {
  factory HitTestTarget._() => null;

  void handleEvent(PointerEvent event, HitTestEntry entry);
}

class HitTestEntry {
  HitTestEntry(this.target);

  final HitTestTarget target;

  @override
  String toString() => '$target';

  Matrix4 get transform => _transform;
  Matrix4 _transform;
}

class HitTestResult {
  HitTestResult()
      : _path = <HitTestEntry>[],
        _transforms = Queue<Matrix4>();

  HitTestResult.wrap(HitTestResult result)
      : _path = result._path,
        _transforms = result._transforms;

  Iterable<HitTestEntry> get path => _path;
  final List<HitTestEntry> _path;

  final Queue<Matrix4> _transforms;

  void add(HitTestEntry entry) {
    assert(entry._transform == null);
    entry._transform = _transforms.isEmpty ? null : _transforms.last;
    _path.add(entry);
  }

  @protected
  void pushTransform(Matrix4 transform) {
    assert(transform != null);
    assert(
        _debugVectorMoreOrLessEquals(
                transform.getRow(2), Vector4(0, 0, 1, 0)) &&
            _debugVectorMoreOrLessEquals(
                transform.getColumn(2), Vector4(0, 0, 1, 0)),
        'The third row and third column of a transform matrix for pointer '
        'events must be Vector4(0, 0, 1, 0) to ensure that a transformed '
        'point is directly under the pointer device. Did you forget to run the paint '
        'matrix through PointerEvent.removePerspectiveTransform?'
        'The provided matrix is:\n$transform');
    _transforms
        .add(_transforms.isEmpty ? transform : transform * _transforms.last);
  }

  @protected
  void popTransform() {
    assert(_transforms.isNotEmpty);
    _transforms.removeLast();
  }

  bool _debugVectorMoreOrLessEquals(Vector4 a, Vector4 b,
      {double epsilon = precisionErrorTolerance}) {
    bool result = true;
    assert(() {
      final Vector4 difference = a - b;
      result = difference.storage
          .every((double component) => component.abs() < epsilon);
      return true;
    }());
    return result;
  }

  @override
  String toString() =>
      'HitTestResult(${_path.isEmpty ? "<empty path>" : _path.join(", ")})';
}

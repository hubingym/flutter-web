import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_web/foundation.dart';
import 'package:vector_math/vector_math_64.dart';

import 'basic_types.dart';

class MatrixUtils {
  MatrixUtils._();

  static Offset getAsTranslation(Matrix4 transform) {
    assert(transform != null);
    final Float64List values = transform.storage;

    if (values[0] == 1.0 &&
        values[1] == 0.0 &&
        values[2] == 0.0 &&
        values[3] == 0.0 &&
        values[4] == 0.0 &&
        values[5] == 1.0 &&
        values[6] == 0.0 &&
        values[7] == 0.0 &&
        values[8] == 0.0 &&
        values[9] == 0.0 &&
        values[10] == 1.0 &&
        values[11] == 0.0 &&
        values[14] == 0.0 &&
        values[15] == 1.0) {
      return Offset(values[12], values[13]);
    }
    return null;
  }

  static double getAsScale(Matrix4 transform) {
    assert(transform != null);
    final Float64List values = transform.storage;

    if (values[1] == 0.0 &&
        values[2] == 0.0 &&
        values[3] == 0.0 &&
        values[4] == 0.0 &&
        values[6] == 0.0 &&
        values[7] == 0.0 &&
        values[8] == 0.0 &&
        values[9] == 0.0 &&
        values[10] == 1.0 &&
        values[11] == 0.0 &&
        values[12] == 0.0 &&
        values[13] == 0.0 &&
        values[14] == 0.0 &&
        values[15] == 1.0 &&
        values[0] == values[5]) {
      return values[0];
    }
    return null;
  }

  static bool matrixEquals(Matrix4 a, Matrix4 b) {
    if (identical(a, b)) return true;
    assert(a != null || b != null);
    if (a == null) return isIdentity(b);
    if (b == null) return isIdentity(a);
    assert(a != null && b != null);
    return a.storage[0] == b.storage[0] &&
        a.storage[1] == b.storage[1] &&
        a.storage[2] == b.storage[2] &&
        a.storage[3] == b.storage[3] &&
        a.storage[4] == b.storage[4] &&
        a.storage[5] == b.storage[5] &&
        a.storage[6] == b.storage[6] &&
        a.storage[7] == b.storage[7] &&
        a.storage[8] == b.storage[8] &&
        a.storage[9] == b.storage[9] &&
        a.storage[10] == b.storage[10] &&
        a.storage[11] == b.storage[11] &&
        a.storage[12] == b.storage[12] &&
        a.storage[13] == b.storage[13] &&
        a.storage[14] == b.storage[14] &&
        a.storage[15] == b.storage[15];
  }

  static bool isIdentity(Matrix4 a) {
    assert(a != null);
    return a.storage[0] == 1.0 &&
        a.storage[1] == 0.0 &&
        a.storage[2] == 0.0 &&
        a.storage[3] == 0.0 &&
        a.storage[4] == 0.0 &&
        a.storage[5] == 1.0 &&
        a.storage[6] == 0.0 &&
        a.storage[7] == 0.0 &&
        a.storage[8] == 0.0 &&
        a.storage[9] == 0.0 &&
        a.storage[10] == 1.0 &&
        a.storage[11] == 0.0 &&
        a.storage[12] == 0.0 &&
        a.storage[13] == 0.0 &&
        a.storage[14] == 0.0 &&
        a.storage[15] == 1.0;
  }

  static Offset transformPoint(Matrix4 transform, Offset point) {
    final Vector3 position3 = Vector3(point.dx, point.dy, 0.0);
    final Vector3 transformed3 = transform.perspectiveTransform(position3);
    return Offset(transformed3.x, transformed3.y);
  }

  static Rect transformRect(Matrix4 transform, Rect rect) {
    final Offset point1 = transformPoint(transform, rect.topLeft);
    final Offset point2 = transformPoint(transform, rect.topRight);
    final Offset point3 = transformPoint(transform, rect.bottomLeft);
    final Offset point4 = transformPoint(transform, rect.bottomRight);
    return Rect.fromLTRB(
      _min4(point1.dx, point2.dx, point3.dx, point4.dx),
      _min4(point1.dy, point2.dy, point3.dy, point4.dy),
      _max4(point1.dx, point2.dx, point3.dx, point4.dx),
      _max4(point1.dy, point2.dy, point3.dy, point4.dy),
    );
  }

  static double _min4(double a, double b, double c, double d) {
    return math.min(a, math.min(b, math.min(c, d)));
  }

  static double _max4(double a, double b, double c, double d) {
    return math.max(a, math.max(b, math.max(c, d)));
  }

  static Rect inverseTransformRect(Matrix4 transform, Rect rect) {
    assert(rect != null);

    if (isIdentity(transform)) return rect;
    transform = Matrix4.copy(transform)..invert();
    return transformRect(transform, rect);
  }

  static Matrix4 createCylindricalProjectionTransform({
    @required double radius,
    @required double angle,
    double perspective = 0.001,
    Axis orientation = Axis.vertical,
  }) {
    assert(radius != null);
    assert(angle != null);
    assert(perspective >= 0 && perspective <= 1.0);
    assert(orientation != null);

    Matrix4 result = Matrix4.identity()
      ..setEntry(3, 2, -perspective)
      ..setEntry(2, 3, -radius)
      ..setEntry(3, 3, perspective * radius + 1.0);

    result *= (orientation == Axis.horizontal
            ? Matrix4.rotationY(angle)
            : Matrix4.rotationX(angle)) *
        Matrix4.translationValues(0.0, 0.0, radius);

    return result;
  }

  static Matrix4 forceToPoint(Offset offset) {
    return Matrix4.identity()
      ..setRow(0, Vector4(0, 0, 0, offset.dx))
      ..setRow(1, Vector4(0, 0, 0, offset.dy));
  }
}

List<String> debugDescribeTransform(Matrix4 transform) {
  if (transform == null) return const <String>['null'];
  return <String>[
    '[0] ${debugFormatDouble(transform.entry(0, 0))},${debugFormatDouble(transform.entry(0, 1))},${debugFormatDouble(transform.entry(0, 2))},${debugFormatDouble(transform.entry(0, 3))}',
    '[1] ${debugFormatDouble(transform.entry(1, 0))},${debugFormatDouble(transform.entry(1, 1))},${debugFormatDouble(transform.entry(1, 2))},${debugFormatDouble(transform.entry(1, 3))}',
    '[2] ${debugFormatDouble(transform.entry(2, 0))},${debugFormatDouble(transform.entry(2, 1))},${debugFormatDouble(transform.entry(2, 2))},${debugFormatDouble(transform.entry(2, 3))}',
    '[3] ${debugFormatDouble(transform.entry(3, 0))},${debugFormatDouble(transform.entry(3, 1))},${debugFormatDouble(transform.entry(3, 2))},${debugFormatDouble(transform.entry(3, 3))}',
  ];
}

class TransformProperty extends DiagnosticsProperty<Matrix4> {
  TransformProperty(
    String name,
    Matrix4 value, {
    bool showName = true,
    Object defaultValue = kNoDefaultValue,
    DiagnosticLevel level = DiagnosticLevel.info,
  })  : assert(showName != null),
        assert(level != null),
        super(
          name,
          value,
          showName: showName,
          defaultValue: defaultValue,
          level: level,
        );

  @override
  String valueToString({TextTreeConfiguration parentConfiguration}) {
    if (parentConfiguration != null &&
        !parentConfiguration.lineBreakProperties) {
      final List<String> values = <String>[
        '${debugFormatDouble(value.entry(0, 0))},${debugFormatDouble(value.entry(0, 1))},${debugFormatDouble(value.entry(0, 2))},${debugFormatDouble(value.entry(0, 3))}',
        '${debugFormatDouble(value.entry(1, 0))},${debugFormatDouble(value.entry(1, 1))},${debugFormatDouble(value.entry(1, 2))},${debugFormatDouble(value.entry(1, 3))}',
        '${debugFormatDouble(value.entry(2, 0))},${debugFormatDouble(value.entry(2, 1))},${debugFormatDouble(value.entry(2, 2))},${debugFormatDouble(value.entry(2, 3))}',
        '${debugFormatDouble(value.entry(3, 0))},${debugFormatDouble(value.entry(3, 1))},${debugFormatDouble(value.entry(3, 2))},${debugFormatDouble(value.entry(3, 3))}',
      ];
      return '[${values.join('; ')}]';
    }
    return debugDescribeTransform(value).join('\n');
  }
}

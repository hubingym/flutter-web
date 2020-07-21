import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_web/foundation.dart';

class _Vector {
  _Vector(int size)
      : _offset = 0,
        _length = size,
        _elements = Float64List(size);

  _Vector.fromVOL(List<double> values, int offset, int length)
      : _offset = offset,
        _length = length,
        _elements = values;

  final int _offset;

  final int _length;

  final List<double> _elements;

  double operator [](int i) => _elements[i + _offset];
  void operator []=(int i, double value) {
    _elements[i + _offset] = value;
  }

  double operator *(_Vector a) {
    double result = 0.0;
    for (int i = 0; i < _length; i += 1) result += this[i] * a[i];
    return result;
  }

  double norm() => math.sqrt(this * this);
}

class _Matrix {
  _Matrix(int rows, int cols)
      : _columns = cols,
        _elements = Float64List(rows * cols);

  final int _columns;
  final List<double> _elements;

  double get(int row, int col) => _elements[row * _columns + col];
  void set(int row, int col, double value) {
    _elements[row * _columns + col] = value;
  }

  _Vector getRow(int row) => _Vector.fromVOL(
        _elements,
        row * _columns,
        _columns,
      );
}

class PolynomialFit {
  PolynomialFit(int degree) : coefficients = Float64List(degree + 1);

  final List<double> coefficients;

  double confidence;
}

class LeastSquaresSolver {
  LeastSquaresSolver(this.x, this.y, this.w)
      : assert(x.length == y.length),
        assert(y.length == w.length);

  final List<double> x;

  final List<double> y;

  final List<double> w;

  PolynomialFit solve(int degree) {
    if (degree > x.length) return null;

    final PolynomialFit result = PolynomialFit(degree);

    final int m = x.length;
    final int n = degree + 1;

    final _Matrix a = _Matrix(n, m);
    for (int h = 0; h < m; h += 1) {
      a.set(0, h, w[h]);
      for (int i = 1; i < n; i += 1) a.set(i, h, a.get(i - 1, h) * x[h]);
    }

    final _Matrix q = _Matrix(n, m);

    final _Matrix r = _Matrix(n, n);
    for (int j = 0; j < n; j += 1) {
      for (int h = 0; h < m; h += 1) q.set(j, h, a.get(j, h));
      for (int i = 0; i < j; i += 1) {
        final double dot = q.getRow(j) * q.getRow(i);
        for (int h = 0; h < m; h += 1)
          q.set(j, h, q.get(j, h) - dot * q.get(i, h));
      }

      final double norm = q.getRow(j).norm();
      if (norm < precisionErrorTolerance) {
        return null;
      }

      final double inverseNorm = 1.0 / norm;
      for (int h = 0; h < m; h += 1) q.set(j, h, q.get(j, h) * inverseNorm);
      for (int i = 0; i < n; i += 1)
        r.set(j, i, i < j ? 0.0 : q.getRow(j) * a.getRow(i));
    }

    final _Vector wy = _Vector(m);
    for (int h = 0; h < m; h += 1) wy[h] = y[h] * w[h];
    for (int i = n - 1; i >= 0; i -= 1) {
      result.coefficients[i] = q.getRow(i) * wy;
      for (int j = n - 1; j > i; j -= 1)
        result.coefficients[i] -= r.get(i, j) * result.coefficients[j];
      result.coefficients[i] /= r.get(i, i);
    }

    double yMean = 0.0;
    for (int h = 0; h < m; h += 1) yMean += y[h];
    yMean /= m;

    double sumSquaredError = 0.0;
    double sumSquaredTotal = 0.0;
    for (int h = 0; h < m; h += 1) {
      double term = 1.0;
      double err = y[h] - result.coefficients[0];
      for (int i = 1; i < n; i += 1) {
        term *= x[h];
        err -= term * result.coefficients[i];
      }
      sumSquaredError += w[h] * w[h] * err * err;
      final double v = y[h] - yMean;
      sumSquaredTotal += w[h] * w[h] * v * v;
    }

    result.confidence = sumSquaredTotal <= precisionErrorTolerance
        ? 1.0
        : 1.0 - (sumSquaredError / sumSquaredTotal);

    return result;
  }
}

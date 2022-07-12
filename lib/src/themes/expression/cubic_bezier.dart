import 'dart:math';

const _epsilon = 1e-6;
const _minX = 0.0;
const _maxX = 1.0;

// based on https://github.com/WebKit/webkit/blob/main/Source/WebCore/platform/graphics/UnitBezier.h
class CubicBezier {
  late final double _coefficientCx;
  late final double _coefficientBx;
  late final double _coefficientAx;
  late final double _coefficientCy;
  late final double _coefficientBy;
  late final double _coefficientAy;
  final Point<double> _controlPoint1;
  final Point<double> _controlPoint2;

  CubicBezier(this._controlPoint1, this._controlPoint2) {
    _coefficientCx = 3.0 * _controlPoint1.x;
    _coefficientBx =
        3.0 * (_controlPoint2.x - _controlPoint1.x) - _coefficientCx;
    _coefficientAx = 1.0 - _coefficientCx - _coefficientBx;

    _coefficientCy = 3.0 * _controlPoint1.y;
    _coefficientBy =
        3.0 * (_controlPoint2.y - _controlPoint1.y) - _coefficientCy;
    _coefficientAy = 1.0 - _coefficientCy - _coefficientBy;
  }

  double solve(double x) {
    return _sampleCurveY(_solveCurveX(x));
  }

  double _sampleCurveX(double t) {
    return ((_coefficientAx * t + _coefficientBx) * t + _coefficientCx) *
        t;
  }

  double _sampleCurveY(double t) {
    return ((_coefficientAy * t + _coefficientBy) * t + _coefficientCy) *
        t;
  }

  double _sampleCurveDerivativeX(double t) {
    return (3.0 * _coefficientAx * t + 2.0 * _coefficientBx) * t +
        _coefficientCx;
  }

  double _solveCurveX(double x) {
    if (x < _minX) {
      return _minX;
    }
    if (x > _maxX) {
      return _maxX;
    }
    var t = _newtonsMethod(x);
    if (t == null) {
      t = _bisectionMethod(x);
    }
    return t;
  }

  double? _newtonsMethod(double x) {
    final attempts = 8;
    double t = x;

    for (var i = 0; i < attempts; ++i) {
      final x2 = _sampleCurveX(t) - x;
      if (x2.abs() < _epsilon) return t;

      final d2 = _sampleCurveDerivativeX(t);
      if (d2.abs() < _epsilon) break;

      t = t - x2 / d2;
    }
    return null;
  }

  double _bisectionMethod(double x) {
    double t0 = 0.0;
    double t1 = 1.0;
    double t = x;
    final attempts = 20;

    for (int i = 0; i < attempts; ++i) {
      final x2 = _sampleCurveX(t);
      if ((x2 - x).abs() < _epsilon) break;

      if (x > x2) {
        t0 = t;
      } else {
        t1 = t;
      }

      t = (t1 - t0) * 0.5 + t0;
    }
    return t;
  }
}

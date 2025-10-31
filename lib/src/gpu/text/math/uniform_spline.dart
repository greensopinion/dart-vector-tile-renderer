
import 'package:vector_tile_renderer/src/gpu/text/math/polynomial.dart';
import 'package:vector_tile_renderer/src/gpu/text/math/uniform_spline_base.dart';

class UniformSplineInterpolation extends UniformSplineInterpolationBase {
  @override
  final List<double> ys;
  final List<SplineSegment> segments;

  UniformSplineInterpolation(this.ys)
      : assert(ys.length >= 2),
        segments = _computeSegments(ys);

  /// Compute natural cubic spline coefficients with h = 1
  static List<SplineSegment> _computeSegments(List<double> ys) {
    final n = ys.length;
    final alpha = List<double>.filled(n, 0.0);

    for (int i = 1; i < n - 1; i++) {
      // Simplified because h[i] = 1 for all i
      alpha[i] = 3 * (ys[i + 1] - 2 * ys[i] + ys[i - 1]);
    }

    final l = List<double>.filled(n, 0.0);
    final mu = List<double>.filled(n, 0.0);
    final z = List<double>.filled(n, 0.0);

    l[0] = 1.0;
    z[0] = 0.0;

    for (int i = 1; i < n - 1; i++) {
      l[i] = 4.0 - mu[i - 1];
      mu[i] = 1.0 / l[i];
      z[i] = (alpha[i] - z[i - 1]) / l[i];
    }

    l[n - 1] = 1.0;
    z[n - 1] = 0.0;

    final c = List<double>.filled(n, 0.0);
    final b = List<double>.filled(n - 1, 0.0);
    final d = List<double>.filled(n - 1, 0.0);
    final a = List<double>.filled(n - 1, 0.0);

    // Backward substitution
    for (int j = n - 2; j >= 0; j--) {
      c[j] = z[j] - mu[j] * c[j + 1];
      b[j] = (ys[j + 1] - ys[j]) - (2 * c[j] + c[j + 1]) / 3.0;
      d[j] = (c[j + 1] - c[j]) / 3.0;
      a[j] = ys[j];
    }

    // Build spline segments
    final segments = <SplineSegment>[];
    for (int i = 0; i < n - 1; i++) {
      segments.add(SplineSegment(
        cubicCoefficient: d[i],
        quadraticCoefficient: c[i],
        linearCoefficient: b[i],
        constantTerm: a[i],
      ));
    }
    return segments;
  }

  /// Interpolates a value at parameter t (0 <= t <= n - 1)
  @override
  double interpolate(double t) {
    if (t <= 0) return ys.first;
    if (t >= ys.length - 1) return ys.last;

    final i = t.floor();
    final localT = t - i;
    return segments[i].evaluate(localT);
  }

  /// Derivative (slope) at parameter t
  @override
  double derivative(double t) {
    if (t <= 0) return segments.first.derivative().evaluate(0);
    if (t >= ys.length - 1) return segments.last.derivative().evaluate(1);

    final i = t.floor();
    final localT = t - i;
    return segments[i].derivative().evaluate(localT);
  }

  /// Returns the derivative polynomial for a specific segment
  @override
  Polynomial derivativePolynomial(int segmentIndex) {
    assert(segmentIndex >= 0 && segmentIndex < segments.length);
    return segments[segmentIndex].derivative();
  }
}


class SplineSegment extends Polynomial{

  SplineSegment({
    required double cubicCoefficient,
    required double quadraticCoefficient,
    required double linearCoefficient,
    required double constantTerm,
  }) : super([
    cubicCoefficient,
    quadraticCoefficient,
    linearCoefficient,
    constantTerm
  ]);
}
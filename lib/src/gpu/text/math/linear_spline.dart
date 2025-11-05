import 'package:vector_tile_renderer/src/gpu/text/math/polynomial.dart';
import 'package:vector_tile_renderer/src/gpu/text/math/uniform_spline_base.dart';

class LinearUniformSplineInterpolation extends UniformSplineInterpolationBase {
  @override
  final List<double> ys;
  final List<LinearSegment> segments;

  LinearUniformSplineInterpolation(this.ys)
      : assert(ys.length >= 2),
        segments = _computeSegments(ys);

  /// Compute linear interpolation segments with h = 1
  static List<LinearSegment> _computeSegments(List<double> ys) {
    final segments = <LinearSegment>[];
    for (int i = 0; i < ys.length - 1; i++) {
      final slope = ys[i + 1] - ys[i];
      segments.add(LinearSegment(
        linearCoefficient: slope,
        constantTerm: ys[i],
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
  /// For linear interpolation, the derivative is constant within each segment
  @override
  double derivative(double t) {
    if (t <= 0) return segments.first.linearCoefficient;
    if (t >= ys.length - 1) return segments.last.linearCoefficient;

    final i = t.floor();
    return segments[i].linearCoefficient;
  }

  /// Returns the derivative polynomial for a specific segment
  /// For linear interpolation, the derivative is a constant
  @override
  Polynomial derivativePolynomial(int segmentIndex) {
    assert(segmentIndex >= 0 && segmentIndex < segments.length);
    // Linear segment derivative is just a constant polynomial
    return Polynomial([segments[segmentIndex].linearCoefficient]);
  }
}

class LinearSegment extends Polynomial {
  final double linearCoefficient;

  LinearSegment({
    required this.linearCoefficient,
    required double constantTerm,
  }) : super([linearCoefficient, constantTerm]);
}

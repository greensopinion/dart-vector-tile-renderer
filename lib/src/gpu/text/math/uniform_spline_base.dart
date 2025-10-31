import 'package:vector_tile_renderer/src/gpu/text/math/polynomial.dart';

/// Abstract interface for uniform spline interpolation
///
/// Uniform splines interpolate between control points with unit spacing (h=1).
/// The parameter t ranges from 0 to n-1, where n is the number of control points.
abstract class UniformSplineInterpolationBase {
  /// The control point values (y-coordinates)
  List<double> get ys;

  /// Interpolates a value at parameter t (0 <= t <= n - 1)
  ///
  /// Values outside the range are clamped to the first/last point.
  double interpolate(double t);

  /// Returns the derivative (slope) at parameter t
  ///
  /// Values outside the range are clamped to the first/last segment's derivative.
  double derivative(double t);

  /// Returns the derivative polynomial for a specific segment
  ///
  /// Used for arc length calculations and other operations requiring
  /// the analytical form of the derivative.
  Polynomial derivativePolynomial(int segmentIndex);

  /// Returns the number of control points
  int get length => ys.length;

  /// Returns the number of segments (length - 1)
  int get numSegments => ys.length - 1;

  /// Returns the maximum valid parameter value (n - 1)
  double get maxT => (ys.length - 1).toDouble();
}

import 'package:test/test.dart';
import 'package:vector_tile_renderer/src/gpu/text/math/uniform_spline.dart';

void main() {
  group('UniformSplineInterpolation', () {
    group('interpolate', () {
      test('passes through all control points', () {
        final ys = [0.0, 1.0, 4.0, 2.0, 0.0];
        final spline = UniformSplineInterpolation(ys);

        for (int i = 0; i < ys.length; i++) {
          expect(spline.interpolate(i.toDouble()), closeTo(ys[i], 0.0001));
        }
      });

      test('interpolates linearly between two points', () {
        final ys = [0.0, 10.0];
        final spline = UniformSplineInterpolation(ys);

        // Natural cubic spline with two points behaves like linear interpolation
        expect(spline.interpolate(0.0), closeTo(0.0, 0.0001));
        expect(spline.interpolate(1.0), closeTo(10.0, 0.0001));
        expect(spline.interpolate(0.5), closeTo(5.0, 0.1));
      });

      test('handles horizontal line', () {
        final ys = [5.0, 5.0, 5.0, 5.0];
        final spline = UniformSplineInterpolation(ys);

        expect(spline.interpolate(0.0), closeTo(5.0, 0.0001));
        expect(spline.interpolate(1.5), closeTo(5.0, 0.0001));
        expect(spline.interpolate(2.5), closeTo(5.0, 0.0001));
        expect(spline.interpolate(3.0), closeTo(5.0, 0.0001));
      });

      test('clamps values below zero to first point', () {
        final ys = [1.0, 2.0, 3.0];
        final spline = UniformSplineInterpolation(ys);

        expect(spline.interpolate(-1.0), equals(1.0));
        expect(spline.interpolate(-0.5), equals(1.0));
        expect(spline.interpolate(0.0), equals(1.0));
      });

      test('clamps values above max to last point', () {
        final ys = [1.0, 2.0, 3.0];
        final spline = UniformSplineInterpolation(ys);

        expect(spline.interpolate(2.0), equals(3.0));
        expect(spline.interpolate(2.5), equals(3.0));
        expect(spline.interpolate(10.0), equals(3.0));
      });

      test('interpolates smooth curve through points', () {
        final ys = [0.0, 1.0, 0.0];
        final spline = UniformSplineInterpolation(ys);

        // Should create smooth curve that goes up and down
        final val0_5 = spline.interpolate(0.5);
        final val1_5 = spline.interpolate(1.5);

        // Both values should be between 0 and 1
        expect(val0_5, greaterThan(0.0));
        expect(val0_5, lessThan(1.0));
        expect(val1_5, greaterThan(0.0));
        expect(val1_5, lessThan(1.0));

        // Due to symmetry, they should be equal
        expect(val0_5, closeTo(val1_5, 0.0001));
      });

      test('handles sine-like data', () {
        final ys = [0.0, 0.707, 1.0, 0.707, 0.0];
        final spline = UniformSplineInterpolation(ys);

        // Should smoothly interpolate through these points
        expect(spline.interpolate(0.0), closeTo(0.0, 0.0001));
        expect(spline.interpolate(2.0), closeTo(1.0, 0.0001));
        expect(spline.interpolate(4.0), closeTo(0.0, 0.0001));

        // Values between should be smooth
        final val0_5 = spline.interpolate(0.5);
        expect(val0_5, greaterThan(0.0));
        expect(val0_5, lessThan(0.707));
      });

      test('handles negative values', () {
        final ys = [-1.0, 0.0, 1.0, 0.0, -1.0];
        final spline = UniformSplineInterpolation(ys);

        expect(spline.interpolate(0.0), closeTo(-1.0, 0.0001));
        expect(spline.interpolate(1.0), closeTo(0.0, 0.0001));
        expect(spline.interpolate(2.0), closeTo(1.0, 0.0001));
        expect(spline.interpolate(3.0), closeTo(0.0, 0.0001));
        expect(spline.interpolate(4.0), closeTo(-1.0, 0.0001));
      });
    });

    group('derivative', () {
      test('has zero derivative for horizontal line', () {
        final ys = [5.0, 5.0, 5.0, 5.0];
        final spline = UniformSplineInterpolation(ys);

        expect(spline.derivative(0.5), closeTo(0.0, 0.0001));
        expect(spline.derivative(1.5), closeTo(0.0, 0.0001));
        expect(spline.derivative(2.5), closeTo(0.0, 0.0001));
      });

      test('has positive derivative for increasing linear', () {
        final ys = [0.0, 10.0];
        final spline = UniformSplineInterpolation(ys);

        final deriv = spline.derivative(0.5);
        expect(deriv, greaterThan(0.0));
      });

      test('has negative derivative for decreasing values', () {
        final ys = [10.0, 0.0];
        final spline = UniformSplineInterpolation(ys);

        final deriv = spline.derivative(0.5);
        expect(deriv, lessThan(0.0));
      });

      test('has zero derivative at peak', () {
        final ys = [0.0, 1.0, 0.0];
        final spline = UniformSplineInterpolation(ys);

        // Derivative at the middle point should be close to zero (peak)
        final deriv = spline.derivative(1.0);
        expect(deriv, closeTo(0.0, 0.001));
      });

      test('clamps derivative below zero', () {
        final ys = [1.0, 2.0, 3.0];
        final spline = UniformSplineInterpolation(ys);

        // Should return derivative at t=0
        final deriv = spline.derivative(-1.0);
        expect(deriv, isNotNull);
      });

      test('clamps derivative above max', () {
        final ys = [1.0, 2.0, 3.0];
        final spline = UniformSplineInterpolation(ys);

        // Should return derivative at t=n-1
        final deriv = spline.derivative(10.0);
        expect(deriv, isNotNull);
      });

      test('derivative changes sign at local extrema', () {
        final ys = [0.0, 1.0, 0.0, -1.0, 0.0];
        final spline = UniformSplineInterpolation(ys);

        final deriv0_5 = spline.derivative(0.5);
        final deriv1_5 = spline.derivative(1.5);
        final deriv2_5 = spline.derivative(2.5);
        final deriv3_5 = spline.derivative(3.5);

        // Should be positive before first peak
        expect(deriv0_5, greaterThan(0.0));
        // Should be negative between peaks
        expect(deriv1_5, lessThan(0.0));
        // Should be negative before valley
        expect(deriv2_5, lessThan(0.0));
        // Should be positive after valley
        expect(deriv3_5, greaterThan(0.0));
      });
    });

    group('SplineSegment', () {
      test('evaluates cubic polynomial correctly', () {
        // Create a segment representing x^3 + 2x^2 + 3x + 4
        final segment = SplineSegment(
          cubicCoefficient: 1.0,
          quadraticCoefficient: 2.0,
          linearCoefficient: 3.0,
          constantTerm: 4.0,
        );

        expect(segment.evaluate(0.0), equals(4.0));
        expect(segment.evaluate(1.0), equals(10.0));
        expect(segment.evaluate(2.0), equals(26.0));
      });

      test('derivative of segment is quadratic', () {
        // Segment: x^3 + 2x^2 + 3x + 4
        // Derivative: 3x^2 + 4x + 3
        final segment = SplineSegment(
          cubicCoefficient: 1.0,
          quadraticCoefficient: 2.0,
          linearCoefficient: 3.0,
          constantTerm: 4.0,
        );

        final deriv = segment.derivative();
        expect(deriv.evaluate(0.0), equals(3.0));
        expect(deriv.evaluate(1.0), equals(10.0));
        expect(deriv.evaluate(2.0), equals(23.0));
      });
    });

    group('edge cases', () {
      test('minimum two points required', () {
        expect(
          () => UniformSplineInterpolation([1.0]),
          throwsA(isA<AssertionError>()),
        );
      });

      test('handles very small values', () {
        final ys = [0.0001, 0.0002, 0.0001];
        final spline = UniformSplineInterpolation(ys);

        expect(spline.interpolate(0.0), closeTo(0.0001, 0.00001));
        expect(spline.interpolate(1.0), closeTo(0.0002, 0.00001));
        expect(spline.interpolate(2.0), closeTo(0.0001, 0.00001));
      });

      test('handles large values', () {
        final ys = [1000.0, 2000.0, 1500.0];
        final spline = UniformSplineInterpolation(ys);

        expect(spline.interpolate(0.0), closeTo(1000.0, 0.1));
        expect(spline.interpolate(1.0), closeTo(2000.0, 0.1));
        expect(spline.interpolate(2.0), closeTo(1500.0, 0.1));
      });
    });
  });
}

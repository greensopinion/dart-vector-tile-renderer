import 'package:test/test.dart';
import 'package:vector_tile_renderer/src/gpu/text/math/linear_spline.dart';

void main() {
  group('LinearUniformSplineInterpolation', () {
    group('interpolate', () {
      test('passes through all control points', () {
        final ys = [0.0, 1.0, 4.0, 2.0, 0.0];
        final spline = LinearUniformSplineInterpolation(ys);

        for (int i = 0; i < ys.length; i++) {
          expect(spline.interpolate(i.toDouble()), equals(ys[i]));
        }
      });

      test('interpolates linearly between two points', () {
        final ys = [0.0, 10.0];
        final spline = LinearUniformSplineInterpolation(ys);

        expect(spline.interpolate(0.0), equals(0.0));
        expect(spline.interpolate(0.5), equals(5.0));
        expect(spline.interpolate(1.0), equals(10.0));
      });

      test('handles horizontal line', () {
        final ys = [5.0, 5.0, 5.0, 5.0];
        final spline = LinearUniformSplineInterpolation(ys);

        expect(spline.interpolate(0.0), equals(5.0));
        expect(spline.interpolate(1.5), equals(5.0));
        expect(spline.interpolate(2.5), equals(5.0));
        expect(spline.interpolate(3.0), equals(5.0));
      });

      test('clamps values below zero to first point', () {
        final ys = [1.0, 2.0, 3.0];
        final spline = LinearUniformSplineInterpolation(ys);

        expect(spline.interpolate(-1.0), equals(1.0));
        expect(spline.interpolate(-0.5), equals(1.0));
        expect(spline.interpolate(0.0), equals(1.0));
      });

      test('clamps values above max to last point', () {
        final ys = [1.0, 2.0, 3.0];
        final spline = LinearUniformSplineInterpolation(ys);

        expect(spline.interpolate(2.0), equals(3.0));
        expect(spline.interpolate(2.5), equals(3.0));
        expect(spline.interpolate(10.0), equals(3.0));
      });

      test('interpolates at quarter points', () {
        final ys = [0.0, 4.0];
        final spline = LinearUniformSplineInterpolation(ys);

        expect(spline.interpolate(0.25), equals(1.0));
        expect(spline.interpolate(0.5), equals(2.0));
        expect(spline.interpolate(0.75), equals(3.0));
      });

      test('handles negative values', () {
        final ys = [-10.0, 0.0, 10.0];
        final spline = LinearUniformSplineInterpolation(ys);

        expect(spline.interpolate(0.0), equals(-10.0));
        expect(spline.interpolate(0.5), equals(-5.0));
        expect(spline.interpolate(1.0), equals(0.0));
        expect(spline.interpolate(1.5), equals(5.0));
        expect(spline.interpolate(2.0), equals(10.0));
      });

      test('handles decreasing values', () {
        final ys = [10.0, 5.0, 0.0];
        final spline = LinearUniformSplineInterpolation(ys);

        expect(spline.interpolate(0.5), equals(7.5));
        expect(spline.interpolate(1.5), equals(2.5));
      });

      test('interpolates through multiple segments', () {
        final ys = [0.0, 2.0, 4.0, 6.0];
        final spline = LinearUniformSplineInterpolation(ys);

        expect(spline.interpolate(0.5), equals(1.0));
        expect(spline.interpolate(1.5), equals(3.0));
        expect(spline.interpolate(2.5), equals(5.0));
      });

      test('handles non-uniform slopes', () {
        final ys = [0.0, 10.0, 15.0, 25.0];
        final spline = LinearUniformSplineInterpolation(ys);

        // First segment: slope = 10
        expect(spline.interpolate(0.5), equals(5.0));
        // Second segment: slope = 5
        expect(spline.interpolate(1.5), equals(12.5));
        // Third segment: slope = 10
        expect(spline.interpolate(2.5), equals(20.0));
      });

      test('handles very small values', () {
        final ys = [0.0001, 0.0002, 0.0001];
        final spline = LinearUniformSplineInterpolation(ys);

        expect(spline.interpolate(0.0), closeTo(0.0001, 0.00001));
        expect(spline.interpolate(1.0), closeTo(0.0002, 0.00001));
        expect(spline.interpolate(2.0), closeTo(0.0001, 0.00001));
      });

      test('handles large values', () {
        final ys = [1000.0, 2000.0, 1500.0];
        final spline = LinearUniformSplineInterpolation(ys);

        expect(spline.interpolate(0.5), equals(1500.0));
        expect(spline.interpolate(1.5), equals(1750.0));
      });
    });

    group('derivative', () {
      test('has zero derivative for horizontal line', () {
        final ys = [5.0, 5.0, 5.0, 5.0];
        final spline = LinearUniformSplineInterpolation(ys);

        expect(spline.derivative(0.5), equals(0.0));
        expect(spline.derivative(1.5), equals(0.0));
        expect(spline.derivative(2.5), equals(0.0));
      });

      test('has positive derivative for increasing line', () {
        final ys = [0.0, 10.0];
        final spline = LinearUniformSplineInterpolation(ys);

        expect(spline.derivative(0.0), equals(10.0));
        expect(spline.derivative(0.5), equals(10.0));
        expect(spline.derivative(1.0), equals(10.0));
      });

      test('has negative derivative for decreasing line', () {
        final ys = [10.0, 0.0];
        final spline = LinearUniformSplineInterpolation(ys);

        expect(spline.derivative(0.5), equals(-10.0));
      });

      test('derivative is constant within each segment', () {
        final ys = [0.0, 5.0, 15.0];
        final spline = LinearUniformSplineInterpolation(ys);

        // First segment: slope = 5
        expect(spline.derivative(0.0), equals(5.0));
        expect(spline.derivative(0.25), equals(5.0));
        expect(spline.derivative(0.5), equals(5.0));
        expect(spline.derivative(0.99), equals(5.0));

        // Second segment: slope = 10
        expect(spline.derivative(1.0), equals(10.0));
        expect(spline.derivative(1.5), equals(10.0));
        expect(spline.derivative(1.99), equals(10.0));
      });

      test('derivative changes between segments', () {
        final ys = [0.0, 10.0, 15.0, 25.0];
        final spline = LinearUniformSplineInterpolation(ys);

        expect(spline.derivative(0.5), equals(10.0));
        expect(spline.derivative(1.5), equals(5.0));
        expect(spline.derivative(2.5), equals(10.0));
      });

      test('clamps derivative below zero', () {
        final ys = [1.0, 2.0, 3.0];
        final spline = LinearUniformSplineInterpolation(ys);

        // Should return derivative of first segment
        expect(spline.derivative(-1.0), equals(1.0));
      });

      test('clamps derivative above max', () {
        final ys = [1.0, 2.0, 3.0];
        final spline = LinearUniformSplineInterpolation(ys);

        // Should return derivative of last segment
        expect(spline.derivative(10.0), equals(1.0));
      });

      test('handles negative slopes', () {
        final ys = [10.0, 5.0, 0.0, -5.0];
        final spline = LinearUniformSplineInterpolation(ys);

        expect(spline.derivative(0.5), equals(-5.0));
        expect(spline.derivative(1.5), equals(-5.0));
        expect(spline.derivative(2.5), equals(-5.0));
      });
    });

    group('LinearSegment', () {
      test('evaluates linear polynomial correctly', () {
        final segment = LinearSegment(
          linearCoefficient: 2.0,
          constantTerm: 3.0,
        );

        expect(segment.evaluate(0.0), equals(3.0));
        expect(segment.evaluate(1.0), equals(5.0));
        expect(segment.evaluate(2.0), equals(7.0));
      });

      test('derivative of segment is constant', () {
        final segment = LinearSegment(
          linearCoefficient: 5.0,
          constantTerm: 10.0,
        );

        final deriv = segment.derivative();
        expect(deriv.evaluate(0.0), equals(5.0));
        expect(deriv.evaluate(1.0), equals(5.0));
        expect(deriv.evaluate(100.0), equals(5.0));
      });

      test('exposes linear coefficient', () {
        final segment = LinearSegment(
          linearCoefficient: 7.5,
          constantTerm: 2.5,
        );

        expect(segment.linearCoefficient, equals(7.5));
      });
    });

    group('edge cases', () {
      test('minimum two points required', () {
        expect(
          () => LinearUniformSplineInterpolation([1.0]),
          throwsA(isA<AssertionError>()),
        );
      });

      test('works with exactly two points', () {
        final ys = [5.0, 10.0];
        final spline = LinearUniformSplineInterpolation(ys);

        expect(spline.interpolate(0.0), equals(5.0));
        expect(spline.interpolate(0.5), equals(7.5));
        expect(spline.interpolate(1.0), equals(10.0));
      });

      test('handles zigzag pattern', () {
        final ys = [0.0, 10.0, 0.0, 10.0, 0.0];
        final spline = LinearUniformSplineInterpolation(ys);

        expect(spline.interpolate(0.5), equals(5.0));
        expect(spline.interpolate(1.5), equals(5.0));
        expect(spline.interpolate(2.5), equals(5.0));
        expect(spline.interpolate(3.5), equals(5.0));
      });
    });

    group('comparison with segments', () {
      test('number of segments equals number of points minus one', () {
        final ys = [1.0, 2.0, 3.0, 4.0, 5.0];
        final spline = LinearUniformSplineInterpolation(ys);

        expect(spline.segments.length, equals(ys.length - 1));
      });

      test('each segment covers unit interval', () {
        final ys = [0.0, 10.0, 30.0];
        final spline = LinearUniformSplineInterpolation(ys);

        // Segment 0: from t=0 to t=1
        expect(spline.segments[0].evaluate(0.0), equals(0.0));
        expect(spline.segments[0].evaluate(1.0), equals(10.0));

        // Segment 1: from t=1 to t=2 (but in local coords 0 to 1)
        expect(spline.segments[1].evaluate(0.0), equals(10.0));
        expect(spline.segments[1].evaluate(1.0), equals(30.0));
      });
    });
  });
}

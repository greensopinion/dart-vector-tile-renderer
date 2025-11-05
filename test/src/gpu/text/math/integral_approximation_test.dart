import 'package:test/test.dart';
import 'package:vector_tile_renderer/src/gpu/text/math/integral_approximation.dart';
import 'package:vector_tile_renderer/src/gpu/text/math/polynomial.dart';

void main() {
  group('IntegralApproximation', () {
    group('trapezoidalSqrtFunc', () {
      test('integrates constant function sqrt(4) = 2 over [0, 1]', () {
        // sqrt(4) = 2, integral from 0 to 1 should be 2
        const polynomial = Polynomial([4.0]);
        final result = IntegralApproximation.trapezoidalSqrtFunc(
          polynomial,
          0.0,
          1.0,
        );
        expect(result, closeTo(2.0, 0.001));
      });

      test('integrates constant function sqrt(9) = 3 over [0, 2]', () {
        // sqrt(9) = 3, integral from 0 to 2 should be 6
        const polynomial = Polynomial([9.0]);
        final result = IntegralApproximation.trapezoidalSqrtFunc(
          polynomial,
          0.0,
          2.0,
        );
        expect(result, closeTo(6.0, 0.001));
      });

      test('integrates sqrt(x^2) = |x| over [0, 1]', () {
        // For x >= 0: sqrt(x^2) = x
        // Integral from 0 to 1 should be 0.5
        const polynomial = Polynomial([1.0, 0.0, 0.0]); // x^2
        final result = IntegralApproximation.trapezoidalSqrtFunc(
          polynomial,
          0.0,
          1.0,
        );
        expect(result, closeTo(0.5, 0.01));
      });

      test('integrates sqrt(1 + x^2) over [0, 1]', () {
        // This is arc length of y = x from 0 to 1
        // Exact value is sinh^(-1)(1) + sqrt(2)/2 ≈ 1.1478
        const polynomial = Polynomial([1.0, 0.0, 1.0]); // x^2 + 1
        final result = IntegralApproximation.trapezoidalSqrtFunc(
          polynomial,
          0.0,
          1.0,
        );
        expect(result, closeTo(1.1478, 0.01));
      });

      test('integrates over reversed bounds', () {
        // Integral from 1 to 0 should be negative of integral from 0 to 1
        const polynomial = Polynomial([4.0]);
        final forward = IntegralApproximation.trapezoidalSqrtFunc(
          polynomial,
          0.0,
          1.0,
        );
        final backward = IntegralApproximation.trapezoidalSqrtFunc(
          polynomial,
          1.0,
          0.0,
        );
        expect(backward, closeTo(-forward, 0.001));
      });

      test('integrates with different step counts', () {
        const polynomial = Polynomial([1.0, 0.0, 1.0]); // x^2 + 1

        final result8 = IntegralApproximation.trapezoidalSqrtFunc(
          polynomial,
          0.0,
          1.0,
          steps: 8,
        );

        final result32 = IntegralApproximation.trapezoidalSqrtFunc(
          polynomial,
          0.0,
          1.0,
          steps: 32,
        );

        final result128 = IntegralApproximation.trapezoidalSqrtFunc(
          polynomial,
          0.0,
          1.0,
          steps: 128,
        );

        // Higher step counts should converge to similar values
        expect(
            (result32 - result128).abs(), lessThan((result8 - result32).abs()));
      });

      test(
          'integrates quadratic polynomial sqrt(4 + 4x + x^2) = sqrt((x+2)^2) = |x+2|',
          () {
        // For x >= -2: sqrt((x+2)^2) = x+2
        // Integral from 0 to 1 is integral of (x+2) = [x^2/2 + 2x] from 0 to 1
        // = (1/2 + 2) - 0 = 2.5
        const polynomial = Polynomial([1.0, 4.0, 4.0]); // x^2 + 4x + 4
        final result = IntegralApproximation.trapezoidalSqrtFunc(
          polynomial,
          0.0,
          1.0,
        );
        expect(result, closeTo(2.5, 0.01));
      });

      test('integrates over zero-width interval', () {
        const polynomial = Polynomial([4.0]);
        final result = IntegralApproximation.trapezoidalSqrtFunc(
          polynomial,
          1.0,
          1.0,
        );
        expect(result, equals(0.0));
      });

      test('integrates sqrt(1 + 4x^2) for arc length of parabola', () {
        // Arc length element for y = x^2 is sqrt(1 + (2x)^2) = sqrt(1 + 4x^2)
        const polynomial = Polynomial([4.0, 0.0, 1.0]); // 4x^2 + 1
        final result = IntegralApproximation.trapezoidalSqrtFunc(
          polynomial,
          0.0,
          1.0,
          steps: 32,
        );
        // Known approximate value for arc length of y=x^2 from 0 to 1 is ~1.479
        expect(result, closeTo(1.479, 0.01));
      });

      test('handles negative bounds correctly', () {
        // sqrt(4) = 2, integral from -1 to 1 should be 4
        const polynomial = Polynomial([4.0]);
        final result = IntegralApproximation.trapezoidalSqrtFunc(
          polynomial,
          -1.0,
          1.0,
        );
        expect(result, closeTo(4.0, 0.001));
      });
    });
  });
}

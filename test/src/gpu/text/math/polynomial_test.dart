import 'package:test/test.dart';
import 'package:vector_tile_renderer/src/gpu/text/math/polynomial.dart';

void main() {
  group('Polynomial', () {
    group('evaluate', () {
      test('evaluates constant polynomial', () {
        // f(x) = 5
        final p = Polynomial([5.0]);
        expect(p.evaluate(0), equals(5.0));
        expect(p.evaluate(1), equals(5.0));
        expect(p.evaluate(10), equals(5.0));
      });

      test('evaluates linear polynomial', () {
        // f(x) = 2x + 3
        final p = Polynomial([2.0, 3.0]);
        expect(p.evaluate(0), equals(3.0));
        expect(p.evaluate(1), equals(5.0));
        expect(p.evaluate(2), equals(7.0));
      });

      test('evaluates quadratic polynomial', () {
        // f(x) = x^2 + 2x + 1 = (x + 1)^2
        final p = Polynomial([1.0, 2.0, 1.0]);
        expect(p.evaluate(0), equals(1.0));
        expect(p.evaluate(1), equals(4.0));
        expect(p.evaluate(2), equals(9.0));
        expect(p.evaluate(-1), equals(0.0));
      });

      test('evaluates cubic polynomial', () {
        // f(x) = x^3 + 0x^2 + 0x + 8
        final p = Polynomial([1.0, 0.0, 0.0, 8.0]);
        expect(p.evaluate(0), equals(8.0));
        expect(p.evaluate(1), equals(9.0));
        expect(p.evaluate(2), equals(16.0));
      });

      test('evaluates polynomial with negative coefficients', () {
        // f(x) = -2x + 5
        final p = Polynomial([-2.0, 5.0]);
        expect(p.evaluate(0), equals(5.0));
        expect(p.evaluate(1), equals(3.0));
        expect(p.evaluate(2), equals(1.0));
      });
    });

    group('derivative', () {
      test('derivative of constant is zero', () {
        // f(x) = 5, f'(x) = 0
        final p = Polynomial([5.0]);
        final derivative = p.derivative();
        expect(derivative.evaluate(0), equals(0.0));
        expect(derivative.evaluate(10), equals(0.0));
      });

      test('derivative of linear polynomial', () {
        // f(x) = 2x + 3, f'(x) = 2
        final p = Polynomial([2.0, 3.0]);
        final derivative = p.derivative();
        expect(derivative.evaluate(0), equals(2.0));
        expect(derivative.evaluate(5), equals(2.0));
      });

      test('derivative of quadratic polynomial', () {
        // f(x) = 3x^2 + 2x + 1, f'(x) = 6x + 2
        final p = Polynomial([3.0, 2.0, 1.0]);
        final derivative = p.derivative();
        expect(derivative.evaluate(0), equals(2.0));
        expect(derivative.evaluate(1), equals(8.0));
        expect(derivative.evaluate(2), equals(14.0));
      });

      test('derivative of cubic polynomial', () {
        // f(x) = x^3 + 2x^2 + 3x + 4, f'(x) = 3x^2 + 4x + 3
        final p = Polynomial([1.0, 2.0, 3.0, 4.0]);
        final derivative = p.derivative();
        expect(derivative.evaluate(0), equals(3.0));
        expect(derivative.evaluate(1), equals(10.0));
        expect(derivative.evaluate(2), equals(23.0));
      });
    });

    group('multiply', () {
      test('multiply constant polynomials', () {
        // f(x) = 3, g(x) = 4, f*g = 12
        final p1 = Polynomial([3.0]);
        final p2 = Polynomial([4.0]);
        final product = p1.multiply(p2);
        expect(product.evaluate(0), equals(12.0));
        expect(product.evaluate(5), equals(12.0));
      });

      test('multiply linear polynomials', () {
        // f(x) = x + 1, g(x) = x + 2
        // f*g = x^2 + 3x + 2
        final p1 = Polynomial([1.0, 1.0]);
        final p2 = Polynomial([1.0, 2.0]);
        final product = p1.multiply(p2);
        expect(product.evaluate(0), equals(2.0));
        expect(product.evaluate(1), equals(6.0));
        expect(product.evaluate(2), equals(12.0));
      });

      test('multiply linear by quadratic', () {
        // f(x) = 2x, g(x) = x^2 + 1
        // f*g = 2x^3 + 2x
        final p1 = Polynomial([2.0, 0.0]);
        final p2 = Polynomial([1.0, 0.0, 1.0]);
        final product = p1.multiply(p2);
        expect(product.evaluate(0), equals(0.0));
        expect(product.evaluate(1), equals(4.0));
        expect(product.evaluate(2), equals(20.0));
      });

      test('multiply by zero polynomial', () {
        // f(x) = x + 1, g(x) = 0
        final p1 = Polynomial([1.0, 1.0]);
        final p2 = Polynomial([0.0]);
        final product = p1.multiply(p2);
        expect(product.evaluate(0), equals(0.0));
        expect(product.evaluate(5), equals(0.0));
      });
    });

    group('squared', () {
      test('square constant polynomial', () {
        // f(x) = 3, f^2 = 9
        final p = Polynomial([3.0]);
        final squared = p.squared();
        expect(squared.evaluate(0), equals(9.0));
        expect(squared.evaluate(10), equals(9.0));
      });

      test('square linear polynomial', () {
        // f(x) = x + 1, f^2 = x^2 + 2x + 1
        final p = Polynomial([1.0, 1.0]);
        final squared = p.squared();
        expect(squared.evaluate(0), equals(1.0));
        expect(squared.evaluate(1), equals(4.0));
        expect(squared.evaluate(2), equals(9.0));
      });

      test('square quadratic polynomial', () {
        // f(x) = x^2 + 1, f^2 = x^4 + 2x^2 + 1
        final p = Polynomial([1.0, 0.0, 1.0]);
        final squared = p.squared();
        expect(squared.evaluate(0), equals(1.0));
        expect(squared.evaluate(1), equals(4.0));
        expect(squared.evaluate(2), equals(25.0));
      });
    });

    group('sum', () {
      test('add constant polynomials', () {
        // f(x) = 3, g(x) = 5, f+g = 8
        final p1 = Polynomial([3.0]);
        final p2 = Polynomial([5.0]);
        final sum = Polynomial.sum(p1, p2);
        expect(sum.evaluate(0), equals(8.0));
        expect(sum.evaluate(10), equals(8.0));
      });

      test('add linear polynomials', () {
        // f(x) = 2x + 1, g(x) = 3x + 2
        // f+g = 5x + 3
        final p1 = Polynomial([2.0, 1.0]);
        final p2 = Polynomial([3.0, 2.0]);
        final sum = Polynomial.sum(p1, p2);
        expect(sum.evaluate(0), equals(3.0));
        expect(sum.evaluate(1), equals(8.0));
        expect(sum.evaluate(2), equals(13.0));
      });

      test('add polynomials of different degrees', () {
        // f(x) = x^2 + 1, g(x) = 2x
        // f+g = x^2 + 2x + 1
        final p1 = Polynomial([1.0, 0.0, 1.0]);
        final p2 = Polynomial([2.0, 0.0]);
        final sum = Polynomial.sum(p1, p2);
        expect(sum.evaluate(0), equals(1.0));
        expect(sum.evaluate(1), equals(4.0));
        expect(sum.evaluate(2), equals(9.0));
      });

      test('add quadratic polynomials', () {
        // f(x) = x^2 + 2x + 1, g(x) = -x^2 + x + 2
        // f+g = 3x + 3
        final p1 = Polynomial([1.0, 2.0, 1.0]);
        final p2 = Polynomial([-1.0, 1.0, 2.0]);
        final sum = Polynomial.sum(p1, p2);
        expect(sum.evaluate(0), equals(3.0));
        expect(sum.evaluate(1), equals(6.0));
        expect(sum.evaluate(2), equals(9.0));
      });

      test('add with negative result', () {
        // f(x) = 2, g(x) = -5
        // f+g = -3
        final p1 = Polynomial([2.0]);
        final p2 = Polynomial([-5.0]);
        final sum = Polynomial.sum(p1, p2);
        expect(sum.evaluate(0), equals(-3.0));
        expect(sum.evaluate(10), equals(-3.0));
      });
    });

    group('exponentForTerm', () {
      test('returns correct exponents for linear polynomial', () {
        // f(x) = 2x + 3
        final p = Polynomial([2.0, 3.0]);
        expect(p.exponentForTerm(0), equals(1));
        expect(p.exponentForTerm(1), equals(0));
      });

      test('returns correct exponents for cubic polynomial', () {
        // f(x) = x^3 + 2x^2 + 3x + 4
        final p = Polynomial([1.0, 2.0, 3.0, 4.0]);
        expect(p.exponentForTerm(0), equals(3));
        expect(p.exponentForTerm(1), equals(2));
        expect(p.exponentForTerm(2), equals(1));
        expect(p.exponentForTerm(3), equals(0));
      });
    });
  });
}

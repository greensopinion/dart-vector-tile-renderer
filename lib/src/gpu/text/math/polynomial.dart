import 'dart:math';

/// terms sorted by highest exponent first
class Polynomial {
  final List<double> _terms;

  const Polynomial(this._terms);

  int exponentForTerm(int i) {
    return _terms.length - 1 - i;
  }

  Polynomial derivative() => Polynomial([
        for (int i = 0; i < _terms.length - 1; i++)
          exponentForTerm(i) * _terms[i],
      ]);

  // Horner's method
  double evaluate(double x) {
    double result = 0.0;
    for (final coefficient in _terms) {
      result = result * x + coefficient;
    }
    return result;
  }

  /// Multiply this polynomial by [other]
  Polynomial multiply(Polynomial other) {
    final int newLength = _terms.length + other._terms.length - 1;
    final List<double> resultTerms = List.filled(newLength, 0.0);

    for (int i = 0; i < _terms.length; i++) {
      for (int j = 0; j < other._terms.length; j++) {
        resultTerms[i + j] += _terms[i] * other._terms[j];
      }
    }

    return Polynomial(resultTerms);
  }

  /// Return this polynomial squared
  Polynomial squared() => multiply(this);

  /// Add this polynomial to [other]
  static Polynomial sum(Polynomial f, Polynomial g) {
    final int maxLength = max(f._terms.length, g._terms.length);

    final List<double> resultTerms = List.filled(maxLength, 0.0);

    // Pad the shorter polynomial with zeros on the left (highest exponent side)
    for (int i = 0; i < maxLength; i++) {
      double a = i >= maxLength - f._terms.length
          ? f._terms[i - (maxLength - f._terms.length)]
          : 0.0;
      double b = i >= maxLength - g._terms.length
          ? g._terms[i - (maxLength - g._terms.length)]
          : 0.0;
      resultTerms[i] = a + b;
    }

    return Polynomial(resultTerms);
  }
}

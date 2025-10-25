import 'dart:math';

import 'package:vector_tile_renderer/src/gpu/text/math/polynomial.dart';

class IntegralApproximation {

  /// Approximates the definite integral of sqrt(P(x))
  static double trapezoidalSqrtFunc(Polynomial function, double lowerBound, double higherBound, {int steps = 16}) {
    final double h = (higherBound - lowerBound) / steps;
    double sum = 0.0;

    for (int i = 0; i <= steps; i++) {
      double x = lowerBound + i * h;
      double fx = sqrt(function.evaluate(x));

      if (i == 0 || i == steps) {
        sum += fx; // endpoints counted once
      } else {
        sum += 2 * fx; // interior points counted twice
      }
    }

    return (h / 2) * sum;
  }
}
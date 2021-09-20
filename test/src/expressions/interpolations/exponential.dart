import 'package:test/test.dart';
import 'package:vector_tile_renderer/src/expressions/argument_expression.dart';
import 'package:vector_tile_renderer/src/expressions/interpolate/exponential_interpolation_expression.dart';
import 'package:vector_tile_renderer/src/expressions/value_expression.dart';
import 'package:vector_tile_renderer/src/themes/theme_function_model.dart';

import '../helpers.dart';

void main() {
  final expression = ExponentialInterpolationExpression<double>(
    2,
    ArgumentExpression('zoom'),
    [
      FunctionStop<double>(ValueExpression(0), ValueExpression(0)),
      FunctionStop<double>(ValueExpression(10), ValueExpression(100)),
    ],
  );

  test('Exponential interpolation uses values based on stops', () {
    const delta = 0.00001;

    expectEvaluated(expression, 0, {'zoom': 0});
    expectEvaluated(expression, closeTo(0.09775, delta), {'zoom': 1});
    expectEvaluated(expression, closeTo(49.95112, delta), {'zoom': 9});
    expectEvaluated(expression, 100, {'zoom': 10});
  });

  test('Exponential interpolation uses last values when outside of bounds', () {
    expectEvaluated(expression, 0, {'zoom': -1});
    expectEvaluated(expression, 100, {'zoom': 100});
  });
}

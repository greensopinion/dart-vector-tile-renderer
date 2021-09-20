import 'package:test/test.dart';
import 'package:vector_tile_renderer/src/expressions/argument_expression.dart';
import 'package:vector_tile_renderer/src/expressions/interpolate/linear_interpolation_expression.dart';
import 'package:vector_tile_renderer/src/expressions/value_expression.dart';
import 'package:vector_tile_renderer/src/themes/theme_function_model.dart';

import '../helpers.dart';

void main() {
  final expression = LinearInterpolationExpression<double>(
    ArgumentExpression('zoom'),
    [
      FunctionStop<double>(ValueExpression(0), ValueExpression(0)),
      FunctionStop<double>(ValueExpression(10), ValueExpression(100)),
    ],
  );

  test('Linear interpolation uses values based on stops', () {
    expectEvaluated(expression, 0, {'zoom': 0});
    expectEvaluated(expression, 50, {'zoom': 5});
    expectEvaluated(expression, 100, {'zoom': 10});
  });

  test('Linear interpolation uses last values when outside of bounds', () {
    expectEvaluated(expression, 0, {'zoom': -1});
    expectEvaluated(expression, 100, {'zoom': 100});
  });
}

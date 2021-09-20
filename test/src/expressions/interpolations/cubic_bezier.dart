import 'package:test/test.dart';
import 'package:vector_math/vector_math.dart';
import 'package:vector_tile_renderer/src/expressions/argument_expression.dart';
import 'package:vector_tile_renderer/src/expressions/interpolate/cubic_bezier_interpolation_expression.dart';
import 'package:vector_tile_renderer/src/expressions/value_expression.dart';
import 'package:vector_tile_renderer/src/themes/theme_function_model.dart';

import '../helpers.dart';

void main() {
  final expression = CubicBezierInterpolationExpression<double>(
    Vector2(0.5, 0),
    Vector2(1, 1),
    ArgumentExpression<double>('zoom'),
    [
      FunctionStop<double>(ValueExpression(0), ValueExpression(0)),
      FunctionStop<double>(ValueExpression(100), ValueExpression(10)),
    ],
  );

  test('Linear interpolation uses values based on stops', () {
    const delta = 0.00001;

    expectEvaluated(expression, 0, {'zoom': 0});
    expectEvaluated(expression, closeTo(1.27778, delta), {'zoom': 1});
    expectEvaluated(expression, closeTo(81.98363, delta), {'zoom': 9});
    expectEvaluated(expression, 100, {'zoom': 10});
  });

  test('Linear interpolation uses last values when outside of bounds', () {
    expectEvaluated(expression, 0, {'zoom': -1});
    expectEvaluated(expression, 100, {'zoom': 100});
  });
}

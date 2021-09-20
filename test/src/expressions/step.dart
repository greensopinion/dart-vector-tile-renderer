import 'package:test/test.dart';
import 'package:vector_tile_renderer/src/expressions/argument_expression.dart';
import 'package:vector_tile_renderer/src/expressions/step_expression.dart';
import 'package:vector_tile_renderer/src/expressions/value_expression.dart';

import 'helpers.dart';

void main() {
  test('step expression picks values based on steps', () {
    final expression = StepExpression<String>(
      ArgumentExpression<double>('zoom'),
      ValueExpression('base'),
      [
        Step<String>(1, ValueExpression('1')),
        Step<String>(3, ValueExpression('3')),
        Step<String>(7, ValueExpression('7')),
        Step<String>(20, ValueExpression('20')),
      ],
    );

    expectEvaluated(expression, 'base', {'zoom': 0});
    expectEvaluated(expression, '1', {'zoom': 1});
    expectEvaluated(expression, '1', {'zoom': 2.99999});
    expectEvaluated(expression, '3', {'zoom': 3});
    expectEvaluated(expression, '20', {'zoom': 200});
  });
}

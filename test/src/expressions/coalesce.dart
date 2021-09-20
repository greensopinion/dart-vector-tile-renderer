import 'package:test/test.dart';
import 'package:vector_tile_renderer/src/expressions/argument_expression.dart';
import 'package:vector_tile_renderer/src/expressions/coalesce_expression.dart';
import 'package:vector_tile_renderer/src/expressions/value_expression.dart';

import 'helpers.dart';

void main() {
  test('coalesce returns the first non-null value', () {
    final expression = CoalesceExpression<String>([
      ValueExpression(null),
      ArgumentExpression('doesnt-exist'),
      ArgumentExpression('result'),
      ArgumentExpression('also-exists')
    ]);

    final args = {'result': 'result', 'also-exists': 'wrong'};

    expectEvaluated(expression, 'result', args);
  });

  test('coalesce returns null if no expression is non-null', () {
    final expression = CoalesceExpression<String>([ValueExpression(null)]);
    expectEvaluated(expression, null);
  });
}

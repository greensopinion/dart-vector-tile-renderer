import 'package:test/test.dart';
import 'package:vector_tile_renderer/src/expressions/argument_expression.dart';
import 'package:vector_tile_renderer/src/expressions/case_expression.dart';
import 'package:vector_tile_renderer/src/expressions/value_expression.dart';

import 'helpers.dart';

void main() {
  test('case expression evaluates value of first true expression', () {
    final expression = CaseExpression<String>(
      [
        Case<String>(ValueExpression(false), ValueExpression('false')),
        Case<String>(
            ArgumentExpression('true-value'), ValueExpression('result')),
        Case<String>(ValueExpression(true), ValueExpression('wrong result')),
      ],
      ValueExpression('fallback'),
    );

    expectEvaluated(expression, 'result', {'true-value': true});
  });

  test('case expression evaluates fallback in case of no true expression', () {
    final expression = CaseExpression<String>(
      [Case<String>(ValueExpression(false), ValueExpression('false'))],
      ValueExpression('fallback'),
    );

    expectEvaluated(expression, 'fallback');
  });
}

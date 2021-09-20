import 'package:test/test.dart';
import 'package:vector_tile_renderer/src/expressions/match_expression.dart';
import 'package:vector_tile_renderer/src/expressions/value_expression.dart';

import 'helpers.dart';

void main() {
  test('match expression evaluates first output matching input', () {
    final expression = MatchExpression<String, String>(
      ValueExpression('input'),
      [
        Match<String, String>(
          ValueExpression('not-input'),
          ValueExpression('not-input'),
        ),
        Match<String, String>(
          ValueExpression('input'),
          ValueExpression('result'),
        ),
        Match<String, String>(
          ValueExpression('input'),
          ValueExpression('not-result'),
        ),
      ],
      ValueExpression('fallback'),
    );

    expectEvaluated(expression, 'result');
  });

  test('match expression evaluates fallback if no match matches', () {
    final expression = MatchExpression<String, String>(
      ValueExpression('input'),
      [
        Match<String, String>(
          ValueExpression('not-input'),
          ValueExpression('not-input'),
        ),
      ],
      ValueExpression('fallback'),
    );

    expectEvaluated(expression, 'fallback');
  });
}

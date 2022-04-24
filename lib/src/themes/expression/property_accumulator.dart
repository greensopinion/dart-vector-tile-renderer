import 'expression.dart';

extension ExpressionList on List<Expression> {
  Set<String> joinProperties() {
    final accumulator = <String>{};
    for (final expression in this) {
      accumulator.addAll(expression.properties());
    }
    return accumulator;
  }
}

import 'expression.dart';

class CoalesceExpression extends Expression {
  final List<Expression> _values;

  CoalesceExpression(this._values)
      : super("coalesce(${_values.map((e) => e.cacheKey).join(',')})");

  @override
  evaluate(EvaluationContext context) {
    for (final expression in _values) {
      final v = expression.evaluate(context);
      if (v != null) {
        return v;
      }
    }
    return null;
  }

  @override
  Set<String> properties() {
    final accumulator = <String>{};
    for (final expression in _values) {
      accumulator.addAll(expression.properties());
    }
    return accumulator;
  }
}

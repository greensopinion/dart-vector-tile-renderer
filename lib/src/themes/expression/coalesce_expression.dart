import 'expression.dart';
import 'property_accumulator.dart';

class CoalesceExpression extends Expression {
  final List<Expression> _values;

  CoalesceExpression(this._values)
      : super("coalesce(${_values.map((e) => e.cacheKey).join(',')})",
            _values.joinProperties());

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
  bool get isConstant => false;
}

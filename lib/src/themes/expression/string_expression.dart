import 'expression.dart';
import 'property_accumulator.dart';

class StringExpression extends Expression<String> {
  final List<Expression> _values;

  StringExpression(this._values)
      : super("string(${_values.map((e) => e.cacheKey).join(',')})",
            _values.joinProperties());

  @override
  String evaluate(EvaluationContext context) {
    for (final expression in _values) {
      final v = expression.evaluate(context);
      if (v != null) {
        return v.toString();
      }
    }
    return '';
  }

  @override
  bool get isConstant => false;
}

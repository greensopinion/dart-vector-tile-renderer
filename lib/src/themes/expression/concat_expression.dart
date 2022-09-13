import 'expression.dart';
import 'property_accumulator.dart';

class ConcatExpression extends Expression {
  final List<Expression> _values;

  ConcatExpression(this._values)
      : super("concat(${_values.map((e) => e.cacheKey).join(',')})",
            _values.joinProperties());

  @override
  evaluate(EvaluationContext context) => _values
      .map((e) => e.evaluate(context))
      .where((e) => e != null)
      .map((e) => e.toString())
      .join();

  @override
  bool get isConstant => !_values.any((e) => !e.isConstant);
}

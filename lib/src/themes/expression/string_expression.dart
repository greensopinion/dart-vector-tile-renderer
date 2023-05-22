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

extension StringExpressionExtension on Expression {
  Expression<String?> asOptionalStringExpression() =>
      _OptionalStringExpression(this);
}

class _OptionalStringExpression extends Expression<String?> {
  final Expression delegate;

  _OptionalStringExpression(this.delegate)
      : super(delegate.cacheKey, delegate.properties());

  @override
  String? evaluate(EvaluationContext context) {
    final v = delegate.evaluate(context);
    if (v != null) {
      return v.toString();
    }
    return null;
  }

  @override
  bool get isConstant => delegate.isConstant;
}

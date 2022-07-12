import 'expression.dart';

class DoubleExpression extends Expression<double> {
  final Expression _delegate;

  DoubleExpression(this._delegate)
      : super('double(${_delegate.cacheKey})', _delegate.properties());

  @override
  double? evaluate(EvaluationContext context) {
    final result = _delegate.evaluate(context);
    if (result is num) {
      return result.toDouble();
    } else if (result != null) {
      context.logger.warn(() => 'expected double but got $result');
    }
    return null;
  }

  @override
  bool get isConstant => _delegate.isConstant;
}

extension NumericExpressionExtension on Expression {
  Expression<double> asDoubleExpression() => DoubleExpression(this);
}

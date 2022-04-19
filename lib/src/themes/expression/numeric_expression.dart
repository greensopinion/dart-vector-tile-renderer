import 'expression.dart';

class DoubleExpression extends Expression {
  final Expression _delegate;

  DoubleExpression(this._delegate) : super('double(${_delegate.cacheKey})');

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
  Set<String> properties() => _delegate.properties();
}

extension NumericExpressionExtension on Expression {
  DoubleExpression asDoubleExpression() => DoubleExpression(this);
}

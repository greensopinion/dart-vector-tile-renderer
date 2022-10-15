import 'expression.dart';
import 'property_accumulator.dart';

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

class ToNumberExpression extends Expression<num> {
  final List<Expression> _delegates;

  ToNumberExpression(this._delegates)
      : super('toNumber(${_delegates.map((e) => e.cacheKey).join(',')})',
            _delegates.joinProperties());

  @override
  num? evaluate(EvaluationContext context) {
    for (final delegate in _delegates) {
      final n = _toNumber(delegate.evaluate(context));
      if (n != null) {
        return n;
      }
    }
    return 0;
  }

  num? _toNumber(result) {
    if (result is num) {
      return result;
    } else if (result == true || result == "true") {
      return 1;
    } else if (result == false || result == "false") {
      return 0;
    } else if (result != null) {
      final s = result.toString();
      return int.tryParse(s) ?? double.tryParse(s);
    }
    return null;
  }

  @override
  bool get isConstant => _delegates.every((e) => e.isConstant);
}

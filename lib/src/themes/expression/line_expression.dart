import '../style.dart';
import 'expression.dart';

class LineCapExpression extends Expression {
  final Expression _delegate;

  LineCapExpression(this._delegate) : super('lineCap(${_delegate.cacheKey})');

  LineCap evaluate(EvaluationContext context) {
    final result = _delegate.evaluate(context);
    if (result is String) {
      return LineCap.fromName(result);
    } else if (result != null) {
      context.logger.warn(() => 'expected string but got $result');
    }
    return LineCap.DEFAULT;
  }

  @override
  Set<String> properties() => _delegate.properties();
}

class LineJoinExpression extends Expression {
  final Expression _delegate;

  LineJoinExpression(this._delegate) : super('lineJoin(${_delegate.cacheKey})');

  LineJoin evaluate(EvaluationContext context) {
    final result = _delegate.evaluate(context);
    if (result is String) {
      return LineJoin.fromName(result);
    } else if (result != null) {
      context.logger.warn(() => 'expected string but got $result');
    }
    return LineJoin.DEFAULT;
  }

  @override
  Set<String> properties() => _delegate.properties();
}

extension LineCapExpressionExtension on Expression {
  LineCapExpression asLineCapExpression() => LineCapExpression(this);
  LineJoinExpression asLineJoinExpression() => LineJoinExpression(this);
}

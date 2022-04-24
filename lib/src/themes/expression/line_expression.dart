import '../style.dart';
import 'expression.dart';

class LineCapExpression extends Expression {
  final Expression _delegate;

  LineCapExpression(this._delegate)
      : super('lineCap(${_delegate.cacheKey})', _delegate.properties());

  LineCap evaluate(EvaluationContext context) {
    final result = _delegate.evaluate(context);
    if (result is String) {
      return LineCap.fromName(result);
    } else if (result != null) {
      context.logger.warn(() => 'expected string but got $result');
    }
    return LineCap.DEFAULT;
  }
}

class LineJoinExpression extends Expression {
  final Expression _delegate;

  LineJoinExpression(this._delegate)
      : super('lineJoin(${_delegate.cacheKey})', _delegate.properties());

  LineJoin evaluate(EvaluationContext context) {
    final result = _delegate.evaluate(context);
    if (result is String) {
      return LineJoin.fromName(result);
    } else if (result != null) {
      context.logger.warn(() => 'expected string but got $result');
    }
    return LineJoin.DEFAULT;
  }
}

extension LineCapExpressionExtension on Expression {
  LineCapExpression asLineCapExpression() => LineCapExpression(this);
  LineJoinExpression asLineJoinExpression() => LineJoinExpression(this);
}

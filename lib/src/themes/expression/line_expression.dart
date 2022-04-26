import '../style.dart';
import 'caching_expression.dart';
import 'expression.dart';

class LineCapExpression extends Expression<LineCap> {
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

  @override
  bool get isConstant => _delegate.isConstant;
}

class LineJoinExpression extends Expression<LineJoin> {
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

  @override
  bool get isConstant => _delegate.isConstant;
}

extension LineCapExpressionExtension on Expression {
  Expression<LineCap> asLineCapExpression() =>
      wrapConstant(LineCapExpression(this));
  Expression<LineJoin> asLineJoinExpression() =>
      wrapConstant(LineJoinExpression(this));
}

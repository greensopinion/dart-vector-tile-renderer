import '../style.dart';
import 'expression.dart';

class LayoutAnchorExpression extends Expression {
  final Expression _delegate;

  LayoutAnchorExpression(this._delegate)
      : super('layoutAnchor(${_delegate.cacheKey})', _delegate.properties());

  LayoutAnchor evaluate(EvaluationContext context) {
    final result = _delegate.evaluate(context);
    if (result is String) {
      return LayoutAnchor.fromName(result);
    } else if (result != null) {
      context.logger.warn(() => 'expected string but got $result');
    }
    return LayoutAnchor.DEFAULT;
  }
}

class LayoutPlacementExpression extends Expression {
  final Expression _delegate;

  LayoutPlacementExpression(this._delegate)
      : super('layoutPlacement(${_delegate.cacheKey})', _delegate.properties());

  LayoutPlacement evaluate(EvaluationContext context) {
    final result = _delegate.evaluate(context);
    if (result is String) {
      return LayoutPlacement.fromName(result);
    } else if (result != null) {
      context.logger.warn(() => 'expected string but got $result');
    }
    return LayoutPlacement.DEFAULT;
  }
}

class LayoutJustifyExpression extends Expression {
  final Expression _delegate;

  LayoutJustifyExpression(this._delegate)
      : super('justify(${_delegate.cacheKey})', _delegate.properties());

  LayoutJustify evaluate(EvaluationContext context) {
    final result = _delegate.evaluate(context);
    if (result is String) {
      return LayoutJustify.fromName(result);
    } else if (result != null) {
      context.logger.warn(() => 'expected string but got $result');
    }
    return LayoutJustify.DEFAULT;
  }
}

extension TextExpressionExtension on Expression {
  LayoutAnchorExpression asLayoutAnchorExpression() =>
      LayoutAnchorExpression(this);

  LayoutPlacementExpression asLayoutPlacementExpression() =>
      LayoutPlacementExpression(this);

  LayoutJustifyExpression asLayoutJustifyExpression() =>
      LayoutJustifyExpression(this);
}

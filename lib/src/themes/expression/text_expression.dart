import '../style.dart';
import 'expression.dart';

class LayoutAnchorExpression extends Expression {
  final Expression _delegate;

  LayoutAnchorExpression(this._delegate)
      : super('layoutAnchor(${_delegate.cacheKey})');

  LayoutAnchor evaluate(EvaluationContext context) {
    final result = _delegate.evaluate(context);
    if (result is String) {
      return LayoutAnchor.fromName(result);
    } else if (result != null) {
      context.logger.warn(() => 'expected string but got $result');
    }
    return LayoutAnchor.DEFAULT;
  }

  @override
  Set<String> properties() => _delegate.properties();
}

class LayoutPlacementExpression extends Expression {
  final Expression _delegate;

  LayoutPlacementExpression(this._delegate)
      : super('layoutPlacement(${_delegate.cacheKey})');

  LayoutPlacement evaluate(EvaluationContext context) {
    final result = _delegate.evaluate(context);
    if (result is String) {
      return LayoutPlacement.fromName(result);
    } else if (result != null) {
      context.logger.warn(() => 'expected string but got $result');
    }
    return LayoutPlacement.DEFAULT;
  }

  @override
  Set<String> properties() => _delegate.properties();
}

extension TextExpressionExtension on Expression {
  LayoutAnchorExpression asLayoutAnchorExpression() =>
      LayoutAnchorExpression(this);

  LayoutPlacementExpression asLayoutPlacementExpression() =>
      LayoutPlacementExpression(this);
}

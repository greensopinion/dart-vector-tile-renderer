import '../style.dart';
import 'expression.dart';

class LayoutAnchorExpression extends Expression<LayoutAnchor> {
  final Expression _delegate;

  LayoutAnchorExpression(this._delegate)
      : super('layoutAnchor(${_delegate.cacheKey})', _delegate.properties());

  @override
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
  bool get isConstant => _delegate.isConstant;
}

class LayoutPlacementExpression extends Expression<LayoutPlacement> {
  final Expression _delegate;

  LayoutPlacementExpression(this._delegate)
      : super('layoutPlacement(${_delegate.cacheKey})', _delegate.properties());

  @override
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
  bool get isConstant => _delegate.isConstant;
}

class LayoutJustifyExpression extends Expression<LayoutJustify> {
  final Expression _delegate;

  LayoutJustifyExpression(this._delegate)
      : super('justify(${_delegate.cacheKey})', _delegate.properties());

  @override
  LayoutJustify evaluate(EvaluationContext context) {
    final result = _delegate.evaluate(context);
    if (result is String) {
      return LayoutJustify.fromName(result);
    } else if (result != null) {
      context.logger.warn(() => 'expected string but got $result');
    }
    return LayoutJustify.DEFAULT;
  }

  @override
  bool get isConstant => _delegate.isConstant;
}

extension TextExpressionExtension on Expression {
  Expression<LayoutAnchor> asLayoutAnchorExpression() =>
      LayoutAnchorExpression(this);

  Expression<LayoutPlacement> asLayoutPlacementExpression() =>
      LayoutPlacementExpression(this);

  Expression<LayoutJustify> asLayoutJustifyExpression() =>
      LayoutJustifyExpression(this);
}

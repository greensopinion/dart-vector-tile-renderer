import 'package:flutter/widgets.dart';

import 'expression.dart';

class IsSupportedScriptExpression extends Expression {
  final Expression _expression;

  IsSupportedScriptExpression(this._expression)
      : super('isSupportedScript(${_expression.cacheKey})', _expression.properties());

  @override
  evaluate(EvaluationContext context) {
    final operand = _expression.evaluate(context);
    if (operand is String) {
      // At the moment, known rendering frontends utilizing this library make use of advanced
      // text rendering stacks rather than SDF (per the historical approach of
      // Mapbox and MapLibre), so complex shaping support is not an issue.
      return true;
    }
    context.logger.warn(() => 'IsSupportedScriptExpression expected string but got $operand');
    return null;
  }

  @override
  bool get isConstant => _expression.isConstant;
}
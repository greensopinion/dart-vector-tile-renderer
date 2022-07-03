import 'dart:ui';

import '../color_parser.dart';
import 'caching_expression.dart';
import 'expression.dart';

class ColorExpression extends Expression<Color> {
  final Expression _delegate;

  ColorExpression(this._delegate)
      : super('color(${_delegate.cacheKey})', _delegate.properties());

  Color? evaluate(EvaluationContext context) {
    final result = _delegate.evaluate(context);
    if (result is String) {
      return ColorParser.toColor(result);
    } else if (result != null) {
      context.logger.warn(() => 'expected string but got $result');
    }
    return null;
  }

  @override
  bool get isConstant => _delegate.isConstant;
}

extension ColorExpressionExtension on Expression {
  Expression<Color> asColorExpression() => cache(ColorExpression(this));
}

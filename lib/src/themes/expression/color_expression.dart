import 'dart:ui';

import 'package:vector_tile_renderer/src/themes/color_parser.dart';

import 'expression.dart';

class ColorExpression extends Expression {
  final Expression _delegate;

  ColorExpression(this._delegate) : super('color(${_delegate.cacheKey})');

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
  Set<String> properties() => _delegate.properties();
}

extension ColorExpressionExtension on Expression {
  ColorExpression asColorExpression() => ColorExpression(this);
}

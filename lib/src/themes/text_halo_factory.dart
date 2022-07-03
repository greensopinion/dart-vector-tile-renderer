import 'dart:ui';

import 'expression/caching_expression.dart';
import 'expression/expression.dart';

class TextHaloFactory {
  static Expression<List<Shadow>>? toHaloFunction(
      Expression<Color> colorExpression, Expression<double>? haloWidth) {
    return cache(TextHaloExpression(colorExpression, haloWidth));
  }
}

class TextHaloExpression extends Expression<List<Shadow>> {
  final Expression<Color> colorExpression;
  final Expression<double>? haloWidth;

  TextHaloExpression(this.colorExpression, this.haloWidth)
      : super('textHalo(${colorExpression.cacheKey},${haloWidth?.cacheKey})', {
          ...colorExpression.properties(),
          ...(haloWidth?.properties() ?? {})
        });

  @override
  List<Shadow>? evaluate(EvaluationContext context) {
    final color = colorExpression.evaluate(context);
    if (color == null) {
      return null;
    }
    final width = haloWidth?.evaluate(context);
    if (width == null) {
      return null;
    }
    double offset = width / context.zoom;
    double radius = width;
    return [
      Shadow(
        offset: Offset(-offset, -offset),
        blurRadius: radius,
        color: color,
      ),
      Shadow(
        offset: Offset(offset, offset),
        blurRadius: radius,
        color: color,
      ),
      Shadow(
        offset: Offset(offset, -offset),
        blurRadius: radius,
        color: color,
      ),
      Shadow(
        offset: Offset(-offset, offset),
        blurRadius: radius,
        color: color,
      ),
    ];
  }

  @override
  bool get isConstant =>
      colorExpression.isConstant && (haloWidth?.isConstant ?? true);
}

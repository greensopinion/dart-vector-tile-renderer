import 'dart:ui';

import '../logger.dart';
import 'expression/color_expression.dart';
import 'expression/expression.dart';
import 'expression/literal_expression.dart';
import 'expression/numeric_expression.dart';

class PaintStyle {
  final String id;
  final PaintingStyle paintingStyle;
  final Expression<double> opacity;
  final Expression<double> strokeWidth;
  final Expression<Color> color;
  final List<double> strokeDashPattern;

  PaintStyle(
      {required this.id,
      required this.paintingStyle,
      required this.opacity,
      required this.strokeWidth,
      required this.color,
      required this.strokeDashPattern});

  Paint? paint(EvaluationContext context) {
    final color = this.color.evaluate(context);
    if (color == null) {
      return null;
    }
    final opacity = this.opacity.evaluate(context);
    if (opacity != null && opacity <= 0) {
      return null;
    }
    final paint = Paint()
      ..style = paintingStyle
      ..color = color;
    if (opacity != null) {
      paint.color = color.withOpacity(opacity);
    }
    if (paintingStyle == PaintingStyle.stroke) {
      final strokeWidth = this.strokeWidth.evaluate(context);
      if (strokeWidth == null) {
        return null;
      }
      paint.strokeWidth = strokeWidth;
    }
    return paint;
  }
}

class PaintFactory {
  final Logger logger;
  final ExpressionParser expressionParser;
  PaintFactory(this.logger) : expressionParser = ExpressionParser(logger);

  PaintStyle? create(String id, PaintingStyle style, String prefix, paint,
      {double? defaultStrokeWidth = 1.0}) {
    if (paint == null) {
      return null;
    }
    final color = expressionParser.parseOptional(paint['$prefix-color']);
    if (color == null) {
      return null;
    }
    final opacity = expressionParser.parse(paint['$prefix-opacity'],
        whenNull: () => LiteralExpression(1.0));
    final strokeWidth = expressionParser.parse(paint['$prefix-width'],
        whenNull: () => LiteralExpression(defaultStrokeWidth));

    List<double> dashArray = [];
    final dashJson = paint['$prefix-dasharray'];
    if (dashJson != null && dashJson is List<num>) {
      // check if at least 2 values are specified (otherwise dashing useless)
      if (dashJson.length >= 2) {
        // due to spec vals must be >= 0
        if (dashJson.any((element) => element < .0)) {
          logger.warn(() => '$prefix-dasharray contains value < 0');
        } else {
          dashArray = dashJson.map((e) => e.toDouble()).toList(growable: false);
        }
      }
    }

    return PaintStyle(
        id: id,
        paintingStyle: style,
        opacity: opacity.asDoubleExpression(),
        strokeWidth: strokeWidth.asDoubleExpression(),
        color: color.asColorExpression(),
        strokeDashPattern: dashArray);
  }
}

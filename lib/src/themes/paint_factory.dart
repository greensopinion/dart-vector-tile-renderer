import 'dart:ui';

import '../logger.dart';
import 'expression/color_expression.dart';
import 'expression/expression.dart';
import 'expression/literal_expression.dart';
import 'expression/numeric_expression.dart';

class PaintExpression extends Expression<Paint> {
  final PaintStyle _delegate;

  PaintExpression(this._delegate)
      : super(_cacheKey(_delegate), _properties(_delegate));

  @override
  Paint? evaluate(EvaluationContext context) => _delegate.paint(context);

  @override
  bool get isConstant => false;

  static String _cacheKey(PaintStyle delegate) =>
      "paint(${delegate.id},${delegate.paintingStyle},opacity(${delegate.opacity.cacheKey}),strokeWidth(${delegate.strokeWidth.cacheKey}),color(${delegate.color.cacheKey}))";

  static Set<String> _properties(PaintStyle delegate) => {
        ...delegate.color.properties(),
        ...delegate.strokeWidth.properties(),
        ...delegate.opacity.properties()
      };
}

final _paintStrokeDashExpando = Expando<List<double>>();

extension PaintExtension on Paint {
  List<double>? get strokeDashPattern => _paintStrokeDashExpando[this];
  set strokeDashPattern(List<double>? value) =>
      _paintStrokeDashExpando[this] = value;
}

class PaintStyle {
  final String id;
  final PaintingStyle paintingStyle;
  final Expression<double> opacity;
  final Expression<double> strokeWidth;
  final Expression<Color> color;
  final List<double>? strokeDashPattern;

  PaintStyle(
      {required this.id,
      required this.paintingStyle,
      required this.opacity,
      required this.strokeWidth,
      required this.color,
      required this.strokeDashPattern});

  Paint? paint(EvaluationContext context) {
    final opacity = this.opacity.evaluate(context);
    if (opacity != null && opacity <= 0) {
      return null;
    }
    final color = this.color.evaluate(context);
    if (color == null) {
      return null;
    }
    final paint = Paint()
      ..style = paintingStyle
      ..strokeDashPattern = strokeDashPattern;
    if (opacity != null && opacity < 1.0) {
      paint.color = color.withOpacity(opacity);
    } else {
      paint.color = color;
    }
    if (paintingStyle == PaintingStyle.stroke) {
      final strokeWidth = this.strokeWidth.evaluate(context);
      if (strokeWidth == null || strokeWidth <= 0) {
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

  Expression<Paint>? create(
      String id, PaintingStyle style, String prefix, paint,
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

    List<double>? dashArray;
    final dashJson = paint['$prefix-dasharray'];
    if (dashJson != null && dashJson is List<num> && dashJson.length >= 2) {
      if (dashJson.any((element) => element < .0)) {
        logger.warn(() => '$prefix-dasharray contains value < 0');
      } else {
        dashArray = dashJson.map((e) => e.toDouble()).toList(growable: false);
      }
    }

    return PaintExpression(PaintStyle(
        id: id,
        paintingStyle: style,
        opacity: opacity.asDoubleExpression(),
        strokeWidth: strokeWidth.asDoubleExpression(),
        color: color.asColorExpression(),
        strokeDashPattern: dashArray));
  }
}

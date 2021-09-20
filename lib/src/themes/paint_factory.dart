import 'dart:ui';

import 'package:vector_tile_renderer/src/expressions/expression.dart';
import 'package:vector_tile_renderer/src/expressions/function_expression.dart';
import 'package:vector_tile_renderer/src/expressions/value_expression.dart';
import 'package:vector_tile_renderer/src/parsers/parsers.dart';

import '../logger.dart';

class PaintStyle {
  final String id;
  final PaintingStyle paintingStyle;
  final Expression<double>? opacity;
  final Expression<double>? strokeWidth;
  final Expression<Color> color;

  PaintStyle(
      {required this.id,
      required this.paintingStyle,
      required this.opacity,
      required this.strokeWidth,
      required this.color});

  Paint? paint(Map<String, dynamic> args) {
    final color = this.color.evaluate(args);
    if (color == null) {
      return null;
    }
    final opacity = this.opacity?.evaluate(args);
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
      final strokeWidth = this.strokeWidth?.evaluate(args);
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
  PaintFactory(this.logger);

  PaintStyle? create(String id, PaintingStyle style, String prefix, paint,
      {double? defaultStrokeWidth = 1.0}) {
    if (paint == null) {
      return null;
    }
    final color = parse<Color>(paint['$prefix-color']);

    if (color == null) {
      return null;
    }
    final opacity = parse<double>(paint['$prefix-opacity']);
    final strokeWidth = parse<double>(paint['$prefix-width']) ??
        ValueExpression(defaultStrokeWidth);

    return PaintStyle(
      id: id,
      paintingStyle: style,
      opacity: opacity,
      strokeWidth: FunctionExpression(
        (args) => strokeWidth.evaluate(args) ?? defaultStrokeWidth,
      ),
      color: color,
    );
  }
}

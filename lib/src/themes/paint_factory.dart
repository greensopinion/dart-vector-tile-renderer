import 'dart:ui';

import 'package:vector_tile_renderer/src/themes/style.dart';
import 'package:vector_tile_renderer/src/themes/theme_function.dart';
import 'package:vector_tile_renderer/src/themes/theme_function_model.dart';

import 'color_parser.dart';

import '../logger.dart';

typedef DoubleZoomFunction = double? Function(double zoom);
typedef ColorZoomFunction = Color? Function(double zoom);

class PaintStyle {
  final String id;
  final PaintingStyle paintingStyle;
  final DoubleZoomFunction opacity;
  final DoubleZoomFunction strokeWidth;
  final ColorZoomFunction color;

  PaintStyle(
      {required this.id,
      required this.paintingStyle,
      required this.opacity,
      required this.strokeWidth,
      required this.color});

  Paint? paint({required double zoom}) {
    final color = this.color(zoom);
    if (color == null) {
      return null;
    }
    final opacity = this.opacity(zoom);
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
      final strokeWidth = this.strokeWidth(zoom);
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
    final color = _toColor(paint['$prefix-color']);
    if (color == null) {
      return null;
    }
    final opacity = _toDouble(paint['$prefix-opacity']);
    final strokeWidth = _toDouble(paint['$prefix-width']);
    return PaintStyle(
        id: id,
        paintingStyle: style,
        opacity: opacity,
        strokeWidth: (zoom) => strokeWidth(zoom) ?? defaultStrokeWidth,
        color: color);
  }

  DoubleZoomFunction _toDouble(doubleSpec) {
    if (doubleSpec is num) {
      final value = doubleSpec.toDouble();
      return (zoom) => value;
    }
    if (doubleSpec is Map) {
      final model = DoubleFunctionModelFactory().create(doubleSpec);
      if (model != null) {
        return (zoom) => DoubleThemeFunction().exponential(model, zoom);
      }
    }
    return (_) => null;
  }

  ColorZoomFunction? _toColor(colorSpec) {
    if (colorSpec is String) {
      Color? color = ColorParser.parse(colorSpec);
      if (color == null) {
        logger.warn(() => 'expected color');
        return null;
      }
      return (zoom) => color;
    } else if (colorSpec is Map) {
      final model = ColorFunctionModelFactory().create(colorSpec);
      if (model != null) {
        return (zoom) => ColorThemeFunction().exponential(model, zoom);
      }
    }
  }
}

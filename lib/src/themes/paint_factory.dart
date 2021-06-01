import 'dart:ui';

import 'color_parser.dart';

import '../logger.dart';

class PaintFactory {
  final Logger logger;
  PaintFactory(this.logger);

  Paint? create(String prefix, json) {
    if (json == null) {
      return null;
    }
    final colorSpec = json['$prefix-color'];
    if (colorSpec is String) {
      Color? color = ColorParser.parse(colorSpec);
      if (color == null) {
        logger.warn(() => 'expected color');
        return null;
      }
      final paint = Paint()..color = color;
      final opacity = json['$prefix-opacity'];
      if (opacity is num) {
        paint.color = color.withOpacity(opacity.toDouble());
      }
      return paint;
    }
  }
}

class LinePaintInterpolator {
  static void interpolate(Paint paint, dynamic jsonPaint,
      {double defaultStrokeWidth = 1.0}) {
    paint.strokeWidth = defaultStrokeWidth;
    final lineWidth = jsonPaint['line-width'];
    if (lineWidth is Map) {
      final base = lineWidth['base'];
      if (base is num) {
        paint.strokeWidth = base.toDouble();
      }
    } else if (lineWidth is num) {
      paint.strokeWidth = lineWidth.toDouble();
    }
  }
}

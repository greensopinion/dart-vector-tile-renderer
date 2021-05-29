import 'dart:ui';

import 'package:dart_vector_tile_renderer/src/themes/color_parser.dart';

import '../logger.dart';

class PaintFactory {
  final Logger logger;
  PaintFactory(this.logger);

  Paint? create(String prefix, json) {
    final colorSpec = json['$prefix-color'];
    if (colorSpec is String) {
      Color? color = ColorParser.parse(colorSpec);
      if (color == null) {
        logger.warn(() => 'expected color');
        return null;
      }
      return Paint()..color = color;
    }
  }
}

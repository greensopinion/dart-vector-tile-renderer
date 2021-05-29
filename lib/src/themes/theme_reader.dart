import 'package:flutter/painting.dart';

import '../logger.dart';
import 'color_parser.dart';
import 'paint_factory.dart';
import 'selector_factory.dart';
import 'style.dart';
import 'theme.dart';
import 'dart:core';

import 'theme_layers.dart';

class ThemeReader {
  final Logger logger;
  late final SelectorFactory selectorFactory;
  late final PaintFactory paintFactory;
  ThemeReader(Logger? logger) : this.logger = logger ?? Logger.noop() {
    selectorFactory = SelectorFactory(this.logger);
    paintFactory = PaintFactory(this.logger);
  }

  Theme read(Map<String, dynamic> json) {
    final layers = json['layers'] as List<dynamic>;
    final themeLayers = layers
        .map((layer) => _toThemeLayer(layer))
        .whereType<ThemeLayer>()
        .toList();
    return Theme(themeLayers);
  }

  ThemeLayer? _toThemeLayer(jsonLayer) {
    final type = jsonLayer['type'];
    if (type == 'background') {
      return _toBackgroundTheme(jsonLayer);
    } else if (type == 'fill') {
      return _toFillTheme(jsonLayer);
    }
    logger.warn(() => 'theme layer type $type not implemented');
    return null;
  }

  ThemeLayer? _toBackgroundTheme(jsonLayer) {
    final backgroundColor =
        ColorParser.parse(jsonLayer['paint']?['background-color']);
    if (backgroundColor != null) {
      return BackgroundLayer(jsonLayer['id'] ?? _unknownId, backgroundColor);
    }
    return null;
  }

  ThemeLayer? _toFillTheme(jsonLayer) {
    final selector = selectorFactory.create(jsonLayer);
    final paint = paintFactory.create('fill', jsonLayer['paint']);
    if (paint != null) {
      paint.style = PaintingStyle.fill;
      return FillLayer(jsonLayer['id'] ?? _unknownId, selector,
          Style(fillPaint: paint, linePaint: null));
    }
  }
}

final _unknownId = '<unknown>';

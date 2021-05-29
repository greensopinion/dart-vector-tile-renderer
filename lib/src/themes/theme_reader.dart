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
    } else if (type == 'line') {
      return _toLineTheme(jsonLayer);
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
    final paintJson = jsonLayer['paint'];
    final paint = paintFactory.create('fill', paintJson);
    final outlinePaint = paintFactory.create('fill-outline', paintJson);
    if (paint != null) {
      paint.style = PaintingStyle.fill;
      outlinePaint?.style = PaintingStyle.stroke;
      outlinePaint?.strokeWidth = 0.5;
      return DefaultLayer(jsonLayer['id'] ?? _unknownId, selector,
          Style(fillPaint: paint, outlinePaint: outlinePaint));
    }
  }

  ThemeLayer? _toLineTheme(jsonLayer) {
    final selector = selectorFactory.create(jsonLayer);
    final jsonPaint = jsonLayer['paint'];
    final paint = paintFactory.create('line', jsonPaint);
    if (paint != null) {
      paint.style = PaintingStyle.stroke;
      LinePaintInterpolator.interpolate(paint, jsonPaint);
      return DefaultLayer(
          jsonLayer['id'] ?? _unknownId, selector, Style(linePaint: paint));
    }
  }
}

final _unknownId = '<unknown>';

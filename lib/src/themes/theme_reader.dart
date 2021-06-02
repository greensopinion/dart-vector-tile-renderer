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
  ThemeReader({Logger? logger}) : this.logger = logger ?? Logger.noop() {
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
    final visibility = jsonLayer['visibility'];
    if (visibility == 'none') {
      return null;
    }
    final type = jsonLayer['type'];
    if (type == 'background') {
      return _toBackgroundTheme(jsonLayer);
    } else if (type == 'fill') {
      return _toFillTheme(jsonLayer);
    } else if (type == 'line') {
      return _toLineTheme(jsonLayer);
    } else if (type == 'symbol') {
      return _toSymbolTheme(jsonLayer);
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
    final paint = paintFactory.create(
        _layerId(jsonLayer), PaintingStyle.fill, 'fill', paintJson);
    final outlinePaint = paintFactory.create(
        _layerId(jsonLayer), PaintingStyle.stroke, 'fill-outline', paintJson,
        defaultStrokeWidth: 0.5);
    if (paint != null) {
      return DefaultLayer(jsonLayer['id'] ?? _unknownId,
          selector: selector,
          style: Style(fillPaint: paint, outlinePaint: outlinePaint),
          minzoom: _minZoom(jsonLayer),
          maxzoom: _maxZoom(jsonLayer));
    }
  }

  ThemeLayer? _toLineTheme(jsonLayer) {
    final selector = selectorFactory.create(jsonLayer);
    final jsonPaint = jsonLayer['paint'];
    final lineStyle = paintFactory.create(
        _layerId(jsonLayer), PaintingStyle.stroke, 'line', jsonPaint);
    if (lineStyle != null) {
      return DefaultLayer(jsonLayer['id'] ?? _unknownId,
          selector: selector,
          style: Style(linePaint: lineStyle),
          minzoom: _minZoom(jsonLayer),
          maxzoom: _maxZoom(jsonLayer));
    }
  }

  String _layerId(jsonLayer) => jsonLayer['id'] as String? ?? '<none>';

  ThemeLayer? _toSymbolTheme(jsonLayer) {
    final selector = selectorFactory.create(jsonLayer);
    final jsonPaint = jsonLayer['paint'];
    final paint = paintFactory.create(
        _layerId(jsonLayer), PaintingStyle.fill, 'text', jsonPaint);
    if (paint != null) {
      final textSize = _toTextSize(jsonLayer);
      final textLetterSpacing =
          (jsonLayer['layout']?['text-letter-spacing'] as num?)?.toDouble();
      return DefaultLayer(jsonLayer['id'] ?? _unknownId,
          selector: selector,
          style: Style(
              textPaint: paint,
              textSize: textSize,
              textLetterSpacing: textLetterSpacing),
          minzoom: _minZoom(jsonLayer),
          maxzoom: _maxZoom(jsonLayer));
    }
  }

  double? _minZoom(jsonLayer) => (jsonLayer['minzoom'] as num?)?.toDouble();
  double? _maxZoom(jsonLayer) => (jsonLayer['maxzoom'] as num?)?.toDouble();
}

double _toTextSize(jsonLayer) {
  final textSize = jsonLayer['layout']?['text-size'];
  if (textSize is num) {
    return textSize.toDouble();
  }
  return 16;
}

final _unknownId = '<unknown>';

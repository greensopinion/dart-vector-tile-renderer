import 'dart:core';

import 'package:flutter/painting.dart';

import '../logger.dart';
import '../vector_tile_extensions.dart';
import 'color_parser.dart';
import 'paint_factory.dart';
import 'selector_factory.dart';
import 'style.dart';
import 'text_halo_factory.dart';
import 'theme.dart';
import 'theme_function.dart';
import 'theme_function_model.dart';
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
    final id = json['id'] ?? 'default';
    final version = json['version']?.toString() ?? 'none';
    final layers = json['layers'] as List<dynamic>;
    final themeLayers = layers
        .map((layer) => _toThemeLayer(layer))
        .whereType<ThemeLayer>()
        .toList();
    return Theme(id: id, version: version, layers: themeLayers);
  }

  ThemeLayer? _toThemeLayer(jsonLayer) {
    final visibility = jsonLayer['layout']?['visibility'];
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
        ColorParser.toColor(jsonLayer['paint']?['background-color']);
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
        defaultStrokeWidth: 0.1);
    if (paint != null) {
      return DefaultLayer(
          jsonLayer['id'] ?? _unknownId, _toLayerType(jsonLayer),
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
      return DefaultLayer(
          jsonLayer['id'] ?? _unknownId, _toLayerType(jsonLayer),
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
      final layout = _toTextLayout(jsonLayer);
      final textHalo = _toTextHalo(jsonLayer);

      return DefaultLayer(
          jsonLayer['id'] ?? _unknownId, _toLayerType(jsonLayer),
          selector: selector,
          style:
              Style(textPaint: paint, textLayout: layout, textHalo: textHalo),
          minzoom: _minZoom(jsonLayer),
          maxzoom: _maxZoom(jsonLayer));
    }
  }

  double? _minZoom(jsonLayer) => (jsonLayer['minzoom'] as num?)?.toDouble();
  double? _maxZoom(jsonLayer) => (jsonLayer['maxzoom'] as num?)?.toDouble();

  TextLayout _toTextLayout(jsonLayer) {
    final layout = jsonLayer['layout'];
    final textSize = _toTextSize(layout);
    final textLetterSpacing =
        _toDoubleZoomFunction(layout?['text-letter-spacing']);
    final placement =
        LayoutPlacement.fromName(layout?['symbol-placement'] as String?);
    final anchor = LayoutAnchor.fromName(layout?['text-anchor'] as String?);
    final textFunction = _toTextFunction(layout?['text-field']);
    final font = layout?['text-font'];
    String? fontFamily;
    FontStyle? fontStyle;
    if (font is List<dynamic>) {
      fontFamily = font[0];
      if (fontFamily != null && fontFamily.toLowerCase().contains("italic")) {
        fontStyle = FontStyle.italic;
      }
    }
    final transform = layout?['text-transform'];
    TextTransformFunction? textTransform;
    if (transform == 'uppercase') {
      textTransform = (s) => s?.toUpperCase();
    } else if (transform == 'lowercase') {
      textTransform = (s) => s?.toLowerCase();
    }
    return TextLayout(
        placement: placement,
        anchor: anchor,
        text: textFunction,
        textSize: textSize,
        textLetterSpacing: textLetterSpacing,
        fontFamily: fontFamily,
        fontStyle: fontStyle,
        textTransform: textTransform);
  }

  TextHaloFunction? _toTextHalo(jsonLayer) {
    final paint = jsonLayer['paint'];
    if (paint != null) {
      final haloWidth = (paint['text-halo-width'] as num?)?.toDouble();
      final colorFunction = ColorParser.parse(paint['text-halo-color']);
      if (haloWidth != null && colorFunction != null) {
        return TextHaloFactory.toHaloFunction(colorFunction, haloWidth);
      }
    }
  }

  FeatureTextFunction _toTextFunction(String? textField) {
    if (textField != null) {
      final match = RegExp(r'\{(.+?)\}').firstMatch(textField);
      if (match != null) {
        final fieldName = match.group(1);
        if (fieldName != null) {
          return (feature) => feature.stringProperty(fieldName);
        }
      }
    }
    return (feature) => feature.stringProperty('name');
  }
}

DoubleZoomFunction _toTextSize(layout) {
  final function = _toDoubleZoomFunction(layout?['text-size']);

  return (function != null) ? function : (zoom) => 16.0;
}

DoubleZoomFunction? _toDoubleZoomFunction(layoutProperty) {
  if (layoutProperty == null) {
    return null;
  }
  if (layoutProperty is Map) {
    final model = DoubleFunctionModelFactory().create(layoutProperty);
    if (model != null) {
      return (zoom) => DoubleThemeFunction().exponential(model, zoom);
    }
  } else if (layoutProperty is num) {
    final size = layoutProperty.toDouble();
    return (zoom) => size;
  }
  return null;
}

ThemeLayerType _toLayerType(jsonLayer) {
  final type = jsonLayer['type'] ?? '';
  switch (type) {
    case 'background':
      return ThemeLayerType.background;
    case 'fill':
      return ThemeLayerType.fill;
    case 'line':
      return ThemeLayerType.line;
    case 'symbol':
      return ThemeLayerType.symbol;
    default:
      return ThemeLayerType.unsupported;
  }
}

final _unknownId = '<unknown>';

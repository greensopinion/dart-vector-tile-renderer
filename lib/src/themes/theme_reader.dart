import 'dart:core';

import 'package:flutter/painting.dart';
import 'package:vector_tile_renderer/src/themes/expression/string_expression.dart';

import '../logger.dart';
import '../profiling.dart';
import 'expression/color_expression.dart';
import 'expression/expression.dart';
import 'expression/literal_expression.dart';
import 'expression/numeric_expression.dart';
import 'expression/text_expression.dart';
import 'paint_factory.dart';
import 'selector_factory.dart';
import 'style.dart';
import 'text_halo_factory.dart';
import 'theme.dart';
import 'theme_layers.dart';

class ThemeReader {
  final Logger logger;
  late final SelectorFactory selectorFactory;
  late final PaintFactory paintFactory;
  late final ExpressionParser expressionParser;

  ThemeReader({Logger? logger}) : logger = logger ?? const Logger.noop() {
    selectorFactory = SelectorFactory(this.logger);
    paintFactory = PaintFactory(this.logger);
    expressionParser = ExpressionParser(this.logger);
  }

  Theme read(Map<String, dynamic> json) {
    return profileSync('ReadTheme', () {
      final id = json['id'] ?? 'default';
      final version = json['metadata']?['version']?.toString() ?? 'none';
      final layers = json['layers'] as List<dynamic>;
      final themeLayers = layers
          .map((layer) => _toThemeLayer(layer))
          .whereType<ThemeLayer>()
          .toList(growable: false);
      return Theme(id: id, version: version, layers: themeLayers);
    });
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
    } else if (type == 'fill-extrusion') {
      return _toFillExtrusionTheme(jsonLayer);
    } else if (type == 'line') {
      return _toLineTheme(jsonLayer);
    } else if (type == 'symbol') {
      return _toSymbolTheme(jsonLayer);
    }
    logger.warn(() => 'theme layer type $type not implemented');
    return null;
  }

  ThemeLayer? _toBackgroundTheme(jsonLayer) {
    final styleBackgroundColor = jsonLayer['paint']?['background-color'];
    if (styleBackgroundColor != null) {
      final backgroundColor =
          expressionParser.parse(styleBackgroundColor).asColorExpression();
      return BackgroundLayer(
          jsonLayer['id'] ?? _unknownId, backgroundColor, _metadata(jsonLayer));
    }
    return null;
  }

  ThemeLayer? _toFillExtrusionTheme(jsonLayer) {
    final selector = selectorFactory.create(jsonLayer);
    final paintJson = jsonLayer['paint'];
    final paint = paintFactory.create(_layerId(jsonLayer), PaintingStyle.fill,
        'fill-extrusion', paintJson, null);
    if (paint != null) {
      final base = expressionParser
          .parseOptional(paintJson['fill-extrusion-base'])
          ?.asDoubleExpression();
      final height = expressionParser
          .parseOptional(paintJson['fill-extrusion-height'])
          ?.asDoubleExpression();
      return DefaultLayer(
          jsonLayer['id'] ?? _unknownId, ThemeLayerType.fillExtrusion,
          selector: selector,
          style: Style(
              fillPaint: paint,
              fillExtrusion: Extrusion(base: base, height: height)),
          minzoom: _minZoom(jsonLayer),
          maxzoom: _maxZoom(jsonLayer),
          metadata: _metadata(jsonLayer));
    }
    return null;
  }

  ThemeLayer? _toFillTheme(jsonLayer) {
    final selector = selectorFactory.create(jsonLayer);
    final paintJson = jsonLayer['paint'];
    final paint = paintFactory.create(
        _layerId(jsonLayer), PaintingStyle.fill, 'fill', paintJson, null);
    final outlinePaint = paintFactory.create(_layerId(jsonLayer),
        PaintingStyle.stroke, 'fill-outline', paintJson, null,
        defaultStrokeWidth: 0.1);
    if (paint != null) {
      return DefaultLayer(jsonLayer['id'] ?? _unknownId, ThemeLayerType.fill,
          selector: selector,
          style: Style(fillPaint: paint, outlinePaint: outlinePaint),
          minzoom: _minZoom(jsonLayer),
          maxzoom: _maxZoom(jsonLayer),
          metadata: _metadata(jsonLayer));
    }
    return null;
  }

  ThemeLayer? _toLineTheme(jsonLayer) {
    final selector = selectorFactory.create(jsonLayer);
    final jsonPaint = jsonLayer['paint'];
    final jsonLayout = jsonLayer['layout'];
    final lineStyle = paintFactory.create(_layerId(jsonLayer),
        PaintingStyle.stroke, 'line', jsonPaint, jsonLayout);
    if (lineStyle != null) {
      return DefaultLayer(jsonLayer['id'] ?? _unknownId, ThemeLayerType.line,
          selector: selector,
          style: Style(linePaint: lineStyle),
          minzoom: _minZoom(jsonLayer),
          maxzoom: _maxZoom(jsonLayer),
          metadata: _metadata(jsonLayer));
    }
    return null;
  }

  String _layerId(jsonLayer) => jsonLayer['id'] as String? ?? '<none>';

  ThemeLayer? _toSymbolTheme(jsonLayer) {
    final selector = selectorFactory.create(jsonLayer);
    final jsonPaint = jsonLayer['paint'];
    final paint = paintFactory.create(
        _layerId(jsonLayer), PaintingStyle.fill, 'text', jsonPaint, null);
    if (paint != null) {
      final layout = _toTextLayout(jsonLayer);
      final textHalo = _toTextHalo(jsonLayer);

      return DefaultLayer(jsonLayer['id'] ?? _unknownId, ThemeLayerType.symbol,
          selector: selector,
          style:
              Style(textPaint: paint, textLayout: layout, textHalo: textHalo),
          minzoom: _minZoom(jsonLayer),
          maxzoom: _maxZoom(jsonLayer),
          metadata: _metadata(jsonLayer));
    }
    return null;
  }

  double? _minZoom(jsonLayer) => (jsonLayer['minzoom'] as num?)?.toDouble();
  double? _maxZoom(jsonLayer) => (jsonLayer['maxzoom'] as num?)?.toDouble();

  TextLayout _toTextLayout(jsonLayer) {
    final layout = jsonLayer['layout'];
    final textSize = _toTextSize(layout);
    final textLetterSpacing =
        _toDoubleExpression(layout?['text-letter-spacing']);
    final placement = expressionParser
        .parse(layout?['symbol-placement'])
        .asLayoutPlacementExpression();
    final anchor = expressionParser
        .parse(layout?['text-anchor'])
        .asLayoutAnchorExpression();
    final textFunction = expressionParser
        .parse(layout?['text-field'])
        .asOptionalStringExpression();
    final iconFunction = expressionParser.parseOptional(layout?['icon-image']);
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
    final maxWidth = expressionParser
        .parseOptional(layout?['text-max-width'])
        ?.asDoubleExpression();
    final justify = expressionParser
        .parse(layout?['text-justify'])
        .asLayoutJustifyExpression();
    return TextLayout(
        placement: placement,
        anchor: anchor,
        justify: justify,
        text: textFunction,
        icon: iconFunction,
        textSize: textSize,
        textLetterSpacing: textLetterSpacing,
        maxWidth: maxWidth,
        fontFamily: fontFamily,
        fontStyle: fontStyle,
        textTransform: textTransform);
  }

  Expression<List<Shadow>>? _toTextHalo(jsonLayer) {
    final paint = jsonLayer['paint'];
    if (paint != null) {
      final haloWidth = expressionParser
          .parseOptional(paint['text-halo-width'])
          ?.asDoubleExpression();
      final haloColor = expressionParser
          .parseOptional(paint['text-halo-color'])
          ?.asColorExpression();
      if (haloWidth != null && haloColor != null) {
        return TextHaloFactory.toHaloFunction(haloColor, haloWidth);
      }
    }
    return null;
  }

  Expression<double> _toTextSize(layout) {
    return expressionParser
        .parse(layout?['text-size'], whenNull: () => LiteralExpression(16.0))
        .asDoubleExpression();
  }

  Expression<double>? _toDoubleExpression(layoutProperty) {
    if (layoutProperty == null) {
      return null;
    }
    return expressionParser.parse(layoutProperty).asDoubleExpression();
  }
}

Map<String, dynamic> _metadata(jsonLayer) {
  final layerMetadata = jsonLayer['metadata'];
  return (layerMetadata is Map<String, dynamic>) ? layerMetadata : {};
}

const _unknownId = '<unknown>';

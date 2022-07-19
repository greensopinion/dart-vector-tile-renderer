import '../logger.dart';
import 'expression/expression_parser.dart';
import 'selector.dart';

class SelectorFactory {
  final Logger logger;
  SelectorFactory(this.logger);

  TileLayerSelector create(themeLayer) {
    final source = themeLayer['source'];
    if (source != null && source is String) {
      return TileLayerSelector(
          TileSelector(source), _layerSelector(themeLayer));
    }
    return TileLayerSelector(TileSelector.none(), LayerSelector.none());
  }

  LayerSelector _layerSelector(themeLayer) {
    final sourceLayer = themeLayer['source-layer'];
    if (sourceLayer != null && sourceLayer is String) {
      var selector = LayerSelector.named(sourceLayer);
      final selectors = [selector];
      final minzoom = _getZoomChecked(themeLayer, 'minzoom');
      final maxzoom = _getZoomChecked(themeLayer, 'maxzoom');
      if (minzoom != null || maxzoom != null) {
        selectors.add(LayerSelector.withZoomConstraints(minzoom, maxzoom));
      }
      List<dynamic>? filter = themeLayer['filter'] as List<dynamic>?;
      if (filter != null) {
        selectors.add(_createFilter(filter));
      }
      if (selectors.length > 1) {
        return LayerSelector.composite(selectors);
      }
      return selectors.first;
    }
    logger.warn(() => 'theme layer has no source-layer: ${themeLayer["id"]}');
    return LayerSelector.none();
  }

  LayerSelector _createFilter(List filter) {
    if (filter.isEmpty) {
      throw Exception('unexpected filter: $filter');
    }
    final expression = ExpressionParser(logger).parse(filter);
    return LayerSelector.expression(expression);
  }

  num? _getZoomChecked(themeLayer, String property) {
    final zoom = themeLayer[property];
    if (zoom is num) {
      return zoom;
    } else if (zoom != null) {
      logger
          .warn(() => 'expecting theme $property to be a number but got $zoom');
    }
    return null;
  }
}

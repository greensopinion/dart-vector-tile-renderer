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
      final selector = LayerSelector.named(sourceLayer);
      List<dynamic>? filter = themeLayer['filter'] as List<dynamic>?;
      if (filter == null) {
        return selector;
      }
      return LayerSelector.composite([selector, _createFilter(filter)]);
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
}

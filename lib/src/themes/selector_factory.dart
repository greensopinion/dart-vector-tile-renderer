import 'package:dart_vector_tile_renderer/src/themes/selector.dart';

import '../logger.dart';

class SelectorFactory {
  final Logger logger;
  SelectorFactory(this.logger);

  LayerSelector create(themeLayer) {
    final sourceLayer = themeLayer['source-layer'];
    if (sourceLayer != null && sourceLayer is String) {
      final selector = LayerSelector.named(sourceLayer);
      List<dynamic>? filter = themeLayer['filter'] as List<dynamic>?;
      if (filter == null) {
        return selector;
      }
      if (filter.length < 3) {
        if (filter[0] == 'all' && filter[1] is List) {
          filter = filter[1] as List<dynamic>;
        } else {
          throw Exception('unexpected filter: $filter');
        }
      }
      final op = filter[0];
      final LayerSelector filterSelector;
      if (op == '==') {
        filterSelector = _equalsSelector(filter);
      } else if (op == 'in') {
        filterSelector = _inSelector(filter);
      } else if (op == '!in') {
        filterSelector = _inSelector(filter, negated: true);
      } else {
        logger.warn(() => 'unsupported filter operator $op');
        return LayerSelector.none();
      }
      return LayerSelector.composite([selector, filterSelector]);
    }
    logger.warn(() => 'theme layer has no source-layer: ${themeLayer["id"]}');
    return LayerSelector.none();
  }

  LayerSelector _equalsSelector(List<dynamic> filter) {
    if (filter.length > 3) {
      throw Exception('unexpected filter');
    }
    final propertyName = filter[1];
    final propertyValue = filter[2];
    return LayerSelector.withProperty(propertyName,
        values: [propertyValue], negated: false);
  }

  LayerSelector _inSelector(List<dynamic> filter, {bool negated = false}) {
    final propertyName = filter[1];
    final propertyValues = filter.sublist(2).whereType<String>().toList();
    return LayerSelector.withProperty(propertyName,
        values: propertyValues, negated: negated);
  }
}

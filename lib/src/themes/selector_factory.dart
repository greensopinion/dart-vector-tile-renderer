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
      return LayerSelector.composite([selector, _createFilter(filter)]);
    }
    logger.warn(() => 'theme layer has no source-layer: ${themeLayer["id"]}');
    return LayerSelector.none();
  }

  LayerSelector _createFilter(List filter) {
    if (filter.isEmpty) {
      throw Exception('unexpected filter: $filter');
    }
    final op = filter[0];
    if (op == '==') {
      return _equalsSelector(filter);
    } else if (op == '!=') {
      return _equalsSelector(filter, negated: true);
    } else if (op == 'in') {
      return _inSelector(filter);
    } else if (op == '!in') {
      return _inSelector(filter, negated: true);
    } else if (op == 'all') {
      return LayerSelector.composite(filter.sublist(1).map((f) {
        if (f is List) {
          return _createFilter(f);
        }
        throw Exception('unexpected all filter: $f');
      }).toList());
    } else {
      logger.warn(() => 'unsupported filter operator $op');
      return LayerSelector.none();
    }
  }

  LayerSelector _equalsSelector(List<dynamic> filter, {bool negated = false}) {
    if (filter.length != 3) {
      throw Exception('unexpected filter $filter');
    }
    final propertyName = filter[1];
    final propertyValue = filter[2];
    return LayerSelector.withProperty(propertyName,
        values: [propertyValue], negated: negated);
  }

  LayerSelector _inSelector(List<dynamic> filter, {bool negated = false}) {
    final propertyName = filter[1];
    final propertyValues = filter.sublist(2).toList();
    return LayerSelector.withProperty(propertyName,
        values: propertyValues, negated: negated);
  }
}

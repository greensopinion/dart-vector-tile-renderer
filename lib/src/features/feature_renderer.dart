import 'dart:ui';

import 'package:vector_tile/vector_tile.dart';

import 'polygon_renderer.dart';
import 'line_renderer.dart';
import '../logger.dart';
import '../themes/style.dart';

abstract class FeatureRenderer {
  void render(Canvas canvas, Style style, VectorTileLayer layer,
      VectorTileFeature feature);
}

class FeatureDispatcher extends FeatureRenderer {
  final Logger logger;
  final Map<VectorTileGeomType, FeatureRenderer> typeToRenderer;

  FeatureDispatcher(this.logger)
      : typeToRenderer = createDispatchMapping(logger);

  void render(Canvas canvas, Style style, VectorTileLayer layer,
      VectorTileFeature feature) {
    final type = feature.type;
    if (type != null) {
      final delegate = typeToRenderer[type];
      if (delegate == null) {
        logger.warn(() => 'feature $type is not implemented');
      } else {
        delegate.render(canvas, style, layer, feature);
      }
    }
  }

  static Map<VectorTileGeomType, FeatureRenderer> createDispatchMapping(
      Logger logger) {
    return {
      VectorTileGeomType.POLYGON: PolygonRenderer(logger),
      VectorTileGeomType.LINESTRING: LineRenderer(logger)
    };
  }
}

import 'dart:ui';

import 'package:vector_tile/vector_tile.dart';

import 'polygon_renderer.dart';
import '../logger.dart';

abstract class FeatureRenderer {
  void render(Canvas canvas, VectorTileFeature feature);
}

class FeatureRendererDispatcher extends FeatureRenderer {
  final Logger logger;
  final Map<VectorTileGeomType, FeatureRenderer> typeToRenderer;

  FeatureRendererDispatcher(this.logger)
      : typeToRenderer = createDispatchMapping(logger);

  void render(Canvas canvas, VectorTileFeature feature) {
    final type = feature.type;
    if (type != null) {
      final delegate = typeToRenderer[type];
      if (delegate == null) {
        logger.warn(() => 'feature $type is not implemented');
      } else {
        delegate.render(canvas, feature);
      }
    }
  }

  static Map<VectorTileGeomType, FeatureRenderer> createDispatchMapping(
      Logger logger) {
    return {VectorTileGeomType.POLYGON: PolygonRenderer(logger)};
  }
}

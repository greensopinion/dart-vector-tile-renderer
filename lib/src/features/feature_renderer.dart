import 'dart:ui';

import 'package:vector_tile/vector_tile.dart';

import 'polygon_renderer.dart';
import '../logger.dart';
import '../theme.dart';

abstract class FeatureRenderer {
  void render(Canvas canvas, ThemeElement theme, VectorTileLayer layer,
      VectorTileFeature feature);
}

class FeatureDispatcher {
  final Logger logger;
  final Map<VectorTileGeomType, FeatureRenderer> typeToRenderer;

  FeatureDispatcher(this.logger)
      : typeToRenderer = createDispatchMapping(logger);

  void render(Canvas canvas, Theme theme, VectorTileLayer layer,
      VectorTileFeature feature) {
    final type = feature.type;
    if (type != null) {
      final delegate = typeToRenderer[type];
      if (delegate == null) {
        logger.warn(() => 'feature $type is not implemented');
      } else {
        final themeElement = theme.element(name: layer.name);
        if (themeElement == null) {
          logger.warn(() => 'no theme for ${layer.name}, skipping feature');
        } else {
          delegate.render(canvas, themeElement, layer, feature);
        }
      }
    }
  }

  static Map<VectorTileGeomType, FeatureRenderer> createDispatchMapping(
      Logger logger) {
    return {VectorTileGeomType.POLYGON: PolygonRenderer(logger)};
  }
}

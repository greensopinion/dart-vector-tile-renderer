import 'package:vector_tile/vector_tile.dart';
import 'package:vector_tile/vector_tile_feature.dart';

import 'dart:ui';

import '../logger.dart';
import 'feature_renderer.dart';

class PolygonRenderer extends FeatureRenderer {
  final Logger logger;

  PolygonRenderer(this.logger);
  @override
  void render(Canvas canvas, VectorTileFeature feature) {
    final geometry = feature.decodeGeometry();
    if (geometry != null) {
      if (geometry.type == GeometryType.Polygon) {
        logger.log(() => 'rendering polygon');
        final polygon = geometry as GeometryPolygon;
        polygon.coordinates.forEach((e) {
          logger.log(() => '   ${e.length} rings?');
        });
      } else {
        logger.warn(
            () => 'polygon geometryType=${geometry.type} is not implemented');
      }
    }
  }
}

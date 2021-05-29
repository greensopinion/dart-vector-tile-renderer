import 'package:vector_tile/vector_tile.dart';
import 'package:vector_tile/vector_tile_feature.dart';

import 'dart:ui';

import '../logger.dart';
import '../themes/style.dart';
import '../constants.dart';
import 'feature_renderer.dart';

class PolygonRenderer extends FeatureRenderer {
  final Logger logger;

  PolygonRenderer(this.logger);
  @override
  void render(Canvas canvas, Style style, VectorTileLayer layer,
      VectorTileFeature feature) {
    if (style.fillPaint == null) {
      logger.warn(() => 'polygon does not have a fill paint');
    }
    final geometry = feature.decodeGeometry();
    if (geometry != null) {
      if (geometry.type == GeometryType.Polygon) {
        final polygon = geometry as GeometryPolygon;
        logger.log(() => 'rendering polygon');
        final path = Path();
        polygon.coordinates.forEach((ring) {
          ring.asMap().forEach((index, point) {
            if (point.length < 2) {
              throw Exception('invalid point ${point.length}');
            }
            final x = (point[0] / layer.extent) * tileSize;
            final y = (point[1] / layer.extent) * tileSize;
            if (index == 0) {
              path.moveTo(x, y);
            } else {
              path.lineTo(x, y);
            }
            if (index == (ring.length - 1)) {
              path.close();
            }
          });
        });
        canvas.drawPath(path, style.fillPaint!);
        if (style.outlinePaint != null) {
          canvas.drawPath(path, style.outlinePaint!);
        }
      } else {
        logger.warn(
            () => 'polygon geometryType=${geometry.type} is not implemented');
      }
    }
  }
}

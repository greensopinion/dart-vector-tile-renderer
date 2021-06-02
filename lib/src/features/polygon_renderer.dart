import 'package:vector_tile/vector_tile.dart';
import 'package:vector_tile/vector_tile_feature.dart';

import 'dart:ui';

import '../context.dart';
import '../logger.dart';
import '../themes/style.dart';
import '../constants.dart';
import 'feature_renderer.dart';

class PolygonRenderer extends FeatureRenderer {
  final Logger logger;

  PolygonRenderer(this.logger);
  @override
  void render(Context context, Style style, VectorTileLayer layer,
      VectorTileFeature feature) {
    if (style.fillPaint == null && style.outlinePaint == null) {
      logger
          .warn(() => 'polygon does not have a fill paint or an outline paint');
      return;
    }
    final geometry = feature.decodeGeometry();
    if (geometry != null) {
      if (geometry.type == GeometryType.Polygon) {
        final polygon = geometry as GeometryPolygon;
        logger.log(() => 'rendering polygon');
        final coordinates = polygon.coordinates;
        _renderPolygon(context, style, layer, coordinates);
      } else if (geometry.type == GeometryType.MultiPolygon) {
        final multiPolygon = geometry as GeometryMultiPolygon;
        logger.log(() => 'rendering multi-polygon');
        final polygons = multiPolygon.coordinates;
        polygons?.forEach((coordinates) {
          _renderPolygon(context, style, layer, coordinates);
        });
      } else {
        logger.warn(
            () => 'polygon geometryType=${geometry.type} is not implemented');
      }
    }
  }

  void _renderPolygon(Context context, Style style, VectorTileLayer layer,
      List<List<List<double>>> coordinates) {
    final path = Path();
    coordinates.forEach((ring) {
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
    final fillPaint = style.fillPaint == null
        ? null
        : style.fillPaint!.paint(zoom: context.zoom);
    if (fillPaint != null) {
      context.canvas.drawPath(path, fillPaint);
    }
    final outlinePaint = style.outlinePaint == null
        ? null
        : style.outlinePaint!.paint(zoom: context.zoom);
    if (outlinePaint != null) {
      context.canvas.drawPath(path, outlinePaint);
    }
  }
}

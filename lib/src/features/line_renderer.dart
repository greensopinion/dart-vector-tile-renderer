import 'package:dart_vector_tile_renderer/src/constants.dart';
import 'package:vector_tile/vector_tile.dart';
import 'package:vector_tile/vector_tile_feature.dart';

import 'dart:ui';

import '../logger.dart';
import '../themes/style.dart';
import 'feature_renderer.dart';

class LineRenderer extends FeatureRenderer {
  final Logger logger;

  LineRenderer(this.logger);

  @override
  void render(Canvas canvas, Style style, VectorTileLayer layer,
      VectorTileFeature feature) {
    if (style.linePaint == null) {
      logger.warn(() => 'line does not have a line paint');
    }
    final geometry = feature.decodeGeometry();
    if (geometry != null) {
      List<List<List<double>>> lines;
      if (geometry.type == GeometryType.LineString) {
        final linestring = geometry as GeometryLineString;
        lines = [linestring.coordinates];
      } else if (geometry.type == GeometryType.MultiLineString) {
        final linestring = geometry as GeometryMultiLineString;
        lines = linestring.coordinates;
      } else {
        logger.warn(() =>
            'linestring geometryType=${geometry.type} is not implemented');
        return;
      }
      logger.log(() => 'rendering linestring');
      final path = Path();
      lines.forEach((line) {
        line.asMap().forEach((index, point) {
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
        });
      });
      canvas.drawPath(path, style.linePaint!);
    }
  }
}

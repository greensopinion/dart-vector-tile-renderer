import 'package:vector_tile/vector_tile.dart';
import 'package:vector_tile/vector_tile_feature.dart';

import 'dart:ui';

import '../../vector_tile_renderer.dart';
import '../constants.dart';
import '../context.dart';
import '../logger.dart';
import '../themes/style.dart';
import 'feature_renderer.dart';
import 'feature_geometry.dart';

class LineRenderer extends FeatureRenderer {
  final Logger logger;
  final FeatureGeometry geometry;

  LineRenderer(this.logger) : geometry = FeatureGeometry(logger);

  @override
  void render(Context context, ThemeLayerType layerType, Style style,
      VectorTileLayer layer, VectorTileFeature feature) {
    if (style.linePaint == null) {
      logger.warn(() =>
          'line does not have a line paint for vector tile layer ${layer.name}');
      return;
    }
    final lines = geometry.decodeLines(feature);
    if (lines != null) {
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
      var effectivePaint = style.linePaint!.paint(zoom: context.zoom);
      if (effectivePaint != null) {
        if (context.zoomScaleFactor > 1.0) {
          effectivePaint.strokeWidth =
              effectivePaint.strokeWidth / context.zoomScaleFactor;
        }
        context.canvas.drawPath(path, effectivePaint);
      }
    }
  }
}

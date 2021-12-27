import 'dart:ui';

import '../../vector_tile_renderer.dart';
import '../constants.dart';
import '../context.dart';
import '../themes/style.dart';
import 'feature_geometry.dart';
import 'feature_renderer.dart';
import 'points_extension.dart';

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
        path.addPolygon(line.toPoints(layer.extent, tileSize), false);
      });
      if (!_isWithinClip(context, path)) {
        return;
      }
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

  bool _isWithinClip(Context context, Path path) =>
      context.tileClip.overlaps(path.getBounds());
}

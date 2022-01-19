import 'dart:ui';

import '../../vector_tile_renderer.dart';
import '../constants.dart';
import '../context.dart';
import '../themes/expression/expression.dart';
import '../themes/style.dart';
import 'points_extension.dart';
import 'feature_renderer.dart';

class PolygonRenderer extends FeatureRenderer {
  final Logger logger;
  PolygonRenderer(this.logger);

  @override
  void render(Context context, ThemeLayerType layerType, Style style,
      TileLayer layer, TileFeature feature) {
    if (style.fillPaint == null && style.outlinePaint == null) {
      logger
          .warn(() => 'polygon does not have a fill paint or an outline paint');
      return;
    }

    final polygons = feature.polygons;
    final evaluationContext = EvaluationContext(
      () => feature.properties,
      feature.type,
      context.zoom,
      logger,
    );

    if (polygons.length == 1) {
      logger.log(() => 'rendering polygon');
    } else if (polygons.length > 1) {
      logger.log(() => 'rendering multi-polygon');
    }

    for (final polygon in feature.polygons) {
      final path = Path();
      for (final ring in polygon) {
        path.addPolygon(ring.toPoints(layer.extent, tileSize), true);
      }
      if (!_isWithinClip(context, path)) {
        continue;
      }
      final fillPaint = style.fillPaint?.paint(evaluationContext);
      if (fillPaint != null) {
        context.canvas.drawPath(path, fillPaint);
      }
      final outlinePaint = style.outlinePaint?.paint(evaluationContext);
      if (outlinePaint != null) {
        context.canvas.drawPath(path, outlinePaint);
      }
    }
  }

  bool _isWithinClip(Context context, Path path) =>
      context.tileClip.overlaps(path.getBounds());
}

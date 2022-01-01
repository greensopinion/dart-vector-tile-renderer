import 'dart:ui';

import '../../vector_tile_renderer.dart';
import '../constants.dart';
import '../context.dart';
import '../themes/expression/expression.dart';
import '../themes/style.dart';
import 'feature_geometry.dart';
import 'feature_renderer.dart';
import 'points_extension.dart';

class PolygonRenderer extends FeatureRenderer {
  final Logger logger;
  final FeatureGeometry geometry;

  PolygonRenderer(this.logger) : geometry = FeatureGeometry(logger);

  @override
  void render(Context context, ThemeLayerType layerType, Style style,
      VectorTileLayer layer, VectorTileFeature feature) {
    if (style.fillPaint == null && style.outlinePaint == null) {
      logger
          .warn(() => 'polygon does not have a fill paint or an outline paint');
      return;
    }

    final polygons = geometry.decodePolygons(feature);
    if (polygons != null) {
      final evaluationContext = EvaluationContext(
        () => feature.decodeProperties(),
        feature.type,
        context.zoom,
        logger,
      );

      if (polygons.length == 1) {
        logger.log(() => 'rendering polygon');
      } else if (polygons.length > 1) {
        logger.log(() => 'rendering multi-polygon');
      }

      for (final coordinates in polygons) {
        _renderPolygon(context, evaluationContext, style, layer, coordinates);
      }
    }
  }

  void _renderPolygon(
    Context context,
    EvaluationContext evaluationContext,
    Style style,
    VectorTileLayer layer,
    List<List<List<double>>> coordinates,
  ) {
    final path = Path();
    coordinates.forEach((ring) {
      path.addPolygon(ring.toPoints(layer.extent, tileSize), true);
    });
    if (!_isWithinClip(context, path)) {
      return;
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

  bool _isWithinClip(Context context, Path path) =>
      context.tileClip.overlaps(path.getBounds());
}

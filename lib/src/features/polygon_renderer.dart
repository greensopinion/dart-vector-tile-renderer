import '../../vector_tile_renderer.dart';
import '../themes/expression/expression.dart';
import '../themes/style.dart';
import 'feature_renderer.dart';

class PolygonRenderer extends FeatureRenderer {
  final Logger logger;
  PolygonRenderer(this.logger);

  @override
  void render(
    FeatureRendererContext context,
    ThemeLayerType layerType,
    Style style,
    TileLayer layer,
    TileFeature feature,
  ) {
    if (style.fillPaint == null && style.outlinePaint == null) {
      logger
          .warn(() => 'polygon does not have a fill paint or an outline paint');
      return;
    }

    final evaluationContext = EvaluationContext(
      () => feature.properties,
      feature.type,
      context.zoom,
      logger,
    );
    final fillPaint = style.fillPaint?.paint(evaluationContext);
    final outlinePaint = style.outlinePaint?.paint(evaluationContext);

    final polygons = feature.paths;

    if (polygons.length == 1) {
      logger.log(() => 'rendering polygon');
    } else if (polygons.length > 1) {
      logger.log(() => 'rendering multi-polygon');
    }

    for (final polygon in polygons) {
      if (!context.isPathWithinTileClip(polygon)) {
        continue;
      }

      if (fillPaint != null) {
        context.canvas.drawPath(polygon, fillPaint);
      }

      if (outlinePaint != null) {
        context.canvas.drawPath(polygon, outlinePaint);
      }
    }
  }
}

import '../../vector_tile_renderer.dart';
import '../context.dart';
import '../themes/expression/expression.dart';
import '../themes/style.dart';
import 'feature_renderer.dart';

class FillRenderer extends FeatureRenderer {
  final Logger logger;
  FillRenderer(this.logger);

  @override
  void render(
    Context context,
    ThemeLayerType layerType,
    Style style,
    TileLayer layer,
    TileFeature feature,
  ) {
    if (!feature.hasPaths) {
      return;
    }
    if (style.fillPaint == null && style.outlinePaint == null) {
      logger
          .warn(() => 'polygon does not have a fill paint or an outline paint');
      return;
    }

    final evaluationContext = EvaluationContext(
        () => feature.properties, feature.type, logger,
        zoom: context.zoom, zoomScaleFactor: context.zoomScaleFactor);
    final fillPaint = style.fillPaint?.evaluate(evaluationContext);
    final outlinePaint = style.outlinePaint?.evaluate(evaluationContext);

    final polygons = feature.paths;

    for (final polygon in polygons) {
      if (!context.optimizations.skipInBoundsChecks &&
          !context.tileSpaceMapper.isPathWithinTileClip(polygon)) {
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

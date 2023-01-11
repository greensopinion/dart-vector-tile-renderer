import '../../vector_tile_renderer.dart';
import '../context.dart';
import '../themes/expression/expression.dart';
import '../themes/style.dart';
import 'feature_renderer.dart';

class CircleRenderer extends FeatureRenderer {
  final Logger logger;

  CircleRenderer(this.logger);

  @override
  void render(Context context,
      ThemeLayerType layerType,
      Style style,
      TileLayer layer,
      TileFeature feature,) {
    if (style.fillPaint == null) {
      logger
          .warn(() => 'circle does not have a fill paint or an outline paint');
      return;
    }

    final evaluationContext = EvaluationContext(
          () => feature.properties,
      feature.type,
      logger,
      zoom: context.zoom,
      zoomScaleFactor: context.zoomScaleFactor,
    );
    final fillPaint = style.fillPaint?.evaluate(evaluationContext);
    final points = feature.points;

    for (final point in points) {
      context.canvas.drawCircle(point, 5, fillPaint!.paint());
    }
  }
}

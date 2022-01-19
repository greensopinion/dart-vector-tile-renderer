import 'dart:ui';

import '../themes/expression/expression.dart';

import '../../vector_tile_renderer.dart';
import '../constants.dart';
import '../context.dart';
import '../themes/style.dart';
import 'feature_renderer.dart';
import 'points_extension.dart';

class LineRenderer extends FeatureRenderer {
  final Logger logger;

  LineRenderer(this.logger);

  @override
  void render(Context context, ThemeLayerType layerType, Style style,
      TileLayer layer, TileFeature feature) {
    if (style.linePaint == null) {
      logger.warn(() =>
          'line does not have a line paint for vector tile layer ${layer.name}');
      return;
    }
    logger.log(() => 'rendering linestring');
    final path = Path();
    for (final line in feature.lines) {
      path.addPolygon(line.toPoints(layer.extent, tileSize), false);
    }
    if (!_isWithinClip(context, path)) {
      return;
    }
    var effectivePaint = style.linePaint!.paint(EvaluationContext(
        () => feature.properties, feature.type, context.zoom, logger));
    if (effectivePaint != null) {
      if (context.zoomScaleFactor > 1.0) {
        effectivePaint.strokeWidth =
            effectivePaint.strokeWidth / context.zoomScaleFactor;
      }
      context.canvas.drawPath(path, effectivePaint);
    }
  }

  bool _isWithinClip(Context context, Path path) =>
      context.tileClip.overlaps(path.getBounds());
}

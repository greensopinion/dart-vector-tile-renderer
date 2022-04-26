import '../../vector_tile_renderer.dart';
import '../context.dart';
import '../themes/expression/expression.dart';
import '../themes/style.dart';
import 'feature_renderer.dart';
import 'line_styler.dart';

class LineRenderer extends FeatureRenderer {
  final Logger logger;

  LineRenderer(this.logger);

  @override
  void render(
    Context context,
    ThemeLayerType layerType,
    Style style,
    TileLayer layer,
    TileFeature feature,
  ) {
    if (style.linePaint == null) {
      logger.warn(() =>
          'line does not have a line paint for vector tile layer ${layer.name}');
      return;
    }

    final evaluationContext = EvaluationContext(
      () => feature.properties,
      feature.type,
      context.zoom,
      logger,
    );

    final effectivePaint = style.linePaint?.paint(evaluationContext);
    if (effectivePaint == null) {
      return;
    }

    var strokeWidth = effectivePaint.strokeWidth;
    if (context.zoomScaleFactor > 1.0) {
      strokeWidth = effectivePaint.strokeWidth / context.zoomScaleFactor;
    }
    LineStyler(style, evaluationContext).apply(effectivePaint);

    // Since we are rendering in tile space, we need to render lines with
    // a stroke width in tile space.
    effectivePaint.strokeWidth =
        context.tileSpaceMapper.widthFromPixelToTile(strokeWidth);

    final lines = feature.paths;

    if (lines.length == 1) {
      logger.log(() => 'rendering linestring');
    } else if (lines.length > 1) {
      logger.log(() => 'rendering multi-linestring');
    }

    for (final line in lines) {
      if (!context.optimizations.skipInBoundsChecks &&
          !context.tileSpaceMapper.isPathWithinTileClip(line)) {
        continue;
      }

      context.canvas.drawPath(line, effectivePaint);
    }
  }
}

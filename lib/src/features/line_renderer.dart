import '../../vector_tile_renderer.dart';
import '../context.dart';
import '../path/path_transform.dart';
import '../path/ring_number_provider.dart';
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
    if (!feature.hasPaths) {
      return;
    }
    if (style.linePaint == null) {
      logger.warn(() =>
          'line does not have a line paint for vector tile layer ${layer.name}');
      return;
    }

    final evaluationContext = EvaluationContext(
        () => feature.properties, feature.type, logger,
        zoom: context.zoom, zoomScaleFactor: context.zoomScaleFactor);

    final effectivePaint = style.linePaint?.evaluate(evaluationContext);
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

    final dashLengths = effectivePaint.strokeDashPattern
        ?.map((e) => context.tileSpaceMapper.widthFromPixelToTile(e))
        .toList(growable: false);

    final lines = feature.paths;
    for (var line in lines) {
      if (!context.optimizations.skipInBoundsChecks &&
          !context.tileSpaceMapper.isPathWithinTileClip(line)) {
        continue;
      }
      if (dashLengths != null) {
        line = line.dashPath(RingNumberProvider(dashLengths));
      }
      context.canvas.drawPath(line, effectivePaint);
    }
  }
}

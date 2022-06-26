import 'dart:ui';

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

    var dashlengths = style.lineLayout!.dashArray;
    // map dash lengths to correct tile unit
    dashlengths = dashlengths.map((e) =>
        context.tileSpaceMapper.widthFromPixelToTile(e.toDouble())
    ).toList(growable: false);

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

      // do we need a dashed line?
      if (style.lineLayout!.dashArray.length >= 2) {
        final dashedline = dashPath(
            line, dashArray: CircularIntervalList(dashlengths));
        context.canvas.drawPath(dashedline, effectivePaint);
      } else {
        context.canvas.drawPath(line, effectivePaint);
      }
    }
  }
}

// convert a path into a dashed path with given intervals
Path dashPath(Path source, {required CircularIntervalList<num> dashArray}) {
  final Path dest = Path();
  for (final PathMetric metric in source.computeMetrics()) {
    // start point of dashing
    double distance = .0;
    bool draw = true;
    while (distance < metric.length) {
      final num len = dashArray.next;
      if (draw) {
        dest.addPath(metric.extractPath(distance, distance + len), Offset.zero);
      }
      distance += len;
      draw = !draw;
    }
  }

  return dest;
}

// Fixed list always rotating through elements
class CircularIntervalList<T> {
  CircularIntervalList(this._vals);

  final List<T> _vals;
  int _idx = 0;

  T get next {
    if (_idx >= _vals.length) {
      _idx = 0;
    }
    return _vals[_idx++];
  }
}

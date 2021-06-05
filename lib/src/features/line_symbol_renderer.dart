import 'package:vector_tile/vector_tile.dart';
import 'package:vector_tile/vector_tile_feature.dart';
import 'package:vector_tile_renderer/src/features/text_renderer.dart';

import 'dart:ui';

import '../../vector_tile_renderer.dart';
import '../constants.dart';
import '../context.dart';
import '../logger.dart';
import '../themes/style.dart';
import 'feature_renderer.dart';
import 'feature_geometry.dart';

class LineSymbolRenderer extends FeatureRenderer {
  final Logger logger;
  final FeatureGeometry geometry;

  LineSymbolRenderer(this.logger) : geometry = FeatureGeometry(logger);

  @override
  void render(Context context, ThemeLayerType layerType, Style style,
      VectorTileLayer layer, VectorTileFeature feature) {
    final textPaint = style.textPaint;
    final textLayout = style.textLayout;
    if (textPaint == null || textLayout == null) {
      logger.warn(() => 'line symbol does not have a text paint or layout');
      return;
    }

    final lines = geometry.decodeLines(feature);
    if (lines != null) {
      logger.log(() => 'rendering linestring symbol');
      final text = textLayout.text(feature);
      if (text != null) {
        final path = Path();
        lines.forEach((line) {
          line.asMap().forEach((index, point) {
            if (point.length < 2) {
              throw Exception('invalid point ${point.length}');
            }
            final x = (point[0] / layer.extent) * tileSize;
            final y = (point[1] / layer.extent) * tileSize;
            if (index == 0) {
              path.moveTo(x, y);
            } else {
              path.lineTo(x, y);
            }
          });
        });
        final metrics = path.computeMetrics().toList();
        if (metrics.length > 0) {
          final middleMetric = _findMiddleMetric(metrics);
          final tangent =
              middleMetric.getTangentForOffset(middleMetric.length / 2);
          if (tangent != null) {
            final renderer = TextRenderer(context, style, text);
            final rotate = (tangent.angle >= 0.01 || tangent.angle <= -0.01);
            if (rotate) {
              context.canvas.save();
              context.canvas
                  .translate(tangent.position.dx, tangent.position.dy);
              context.canvas.rotate(-tangent.angle);
              context.canvas
                  .translate(-tangent.position.dx, -tangent.position.dy);
            }
            renderer.render(tangent.position);
            if (rotate) {
              context.canvas.restore();
            }
          }
        }
      }
    }
  }

  PathMetric _findMiddleMetric(List<PathMetric> metrics) {
    final midpoint = metrics.length ~/ 2;
    for (int x = 0; x <= (midpoint + 1); ++x) {
      int lower = midpoint - x;
      if (lower >= 0 && metrics[lower].length > _minPathMetricSize) {
        return metrics[lower];
      }
      int upper = midpoint + x;
      if (upper < metrics.length &&
          metrics[upper].length > _minPathMetricSize) {
        return metrics[upper];
      }
    }
    return metrics[midpoint];
  }
}

final _minPathMetricSize = 100.0;

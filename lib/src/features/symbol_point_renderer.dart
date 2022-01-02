import 'dart:ui';

import 'package:flutter/rendering.dart';

import '../../vector_tile_renderer.dart';
import '../constants.dart';
import '../context.dart';
import '../themes/expression/expression.dart';
import '../themes/style.dart';
import 'feature_geometry.dart';
import 'feature_renderer.dart';
import 'text_abbreviator.dart';
import 'text_renderer.dart';

class SymbolPointRenderer extends FeatureRenderer {
  final Logger logger;
  final FeatureGeometry geometry;
  SymbolPointRenderer(this.logger) : geometry = FeatureGeometry(logger);

  @override
  void render(Context context, ThemeLayerType layerType, Style style,
      VectorTileLayer layer, VectorTileFeature feature) {
    final textPaint = style.textPaint;
    final textLayout = style.textLayout;
    if (textPaint == null || textLayout == null) {
      logger.warn(() => 'point does not have a text paint or layout');
      return;
    }
    final points = geometry.decodePoints(feature);
    if (points != null) {
      logger.log(() => 'rendering points');
      final evaluationContext = EvaluationContext(
          () => feature.decodeProperties(), feature.type, context.zoom, logger);
      final text = textLayout.text.evaluate(evaluationContext);
      final abbreviated =
          text == null ? null : TextAbbreviator().abbreviate(text);
      if (text != null &&
          context.labelSpace.canAccept(abbreviated) &&
          abbreviated != null) {
        final text =
            TextApproximation(context, evaluationContext, style, abbreviated);
        points.forEach((point) {
          if (point.length < 2) {
            throw Exception('invalid point ${point.length}');
          }
          final x = (point[0] / layer.extent) * tileSize;
          final y = (point[1] / layer.extent) * tileSize;
          final offset = Offset(x, y);
          var box = text.labelBox(offset, translated: true);
          if (box != null && context.labelSpace.canOccupy(text.text, box)) {
            box = text.renderer.labelBox(offset, translated: true);
            if (box != null && context.labelSpace.canOccupy(text.text, box)) {
              context.labelSpace.occupy(text.text, box);
              text.renderer.render(Offset(x, y));
            }
          }
        });
      } else {
        logger.warn(() => 'point with no text');
      }
    }
  }
}

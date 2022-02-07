import 'dart:ui';

import '../../vector_tile_renderer.dart';
import '../themes/expression/expression.dart';
import '../themes/style.dart';
import 'feature_renderer.dart';
import 'text_abbreviator.dart';
import 'text_renderer.dart';

class SymbolPointRenderer extends FeatureRenderer {
  final Logger logger;
  SymbolPointRenderer(this.logger);

  @override
  void render(
    FeatureRendererContext context,
    ThemeLayerType layerType,
    Style style,
    TileLayer layer,
    TileFeature feature,
  ) {
    final textPaint = style.textPaint;
    final textLayout = style.textLayout;
    if (textPaint == null || textLayout == null) {
      logger.warn(() => 'point does not have a text paint or layout');
      return;
    }

    final evaluationContext = EvaluationContext(
      () => feature.properties,
      feature.type,
      context.zoom,
      logger,
    );

    final text = textLayout.text.evaluate(evaluationContext);
    if (text == null) {
      logger.warn(() => 'point with no text');
      return;
    }

    final textAbbr = TextAbbreviator().abbreviate(text);
    if (!context.labelSpace.canAccept(textAbbr)) {
      return;
    }

    logger.log(() => 'rendering symbol points');

    final textApprox =
        TextApproximation(context, evaluationContext, style, textAbbr);

    for (final point in feature.points) {
      final offset = context.pointFromTileToPixels(point);

      if (!_occupyLabelSpaceAtOffset(context, textApprox, offset)) {
        continue;
      }

      context.drawInPixelSpace(() {
        textApprox.renderer.render(offset);
      });
    }
  }

  bool _occupyLabelSpaceAtOffset(
    FeatureRendererContext context,
    TextApproximation text,
    Offset offset,
  ) {
    final box = text.labelBox(offset, translated: true);
    if (box == null) {
      return false;
    }

    if (!context.labelSpace.canOccupy(text.text, box)) {
      return false;
    }

    return _preciselyOccupyLabelSpaceAtOffset(context, text, offset);
  }

  bool _preciselyOccupyLabelSpaceAtOffset(
    FeatureRendererContext context,
    TextApproximation text,
    Offset offset,
  ) {
    final box = text.renderer.labelBox(offset, translated: true);
    if (box == null) {
      return false;
    }

    if (!context.labelSpace.canOccupy(text.text, box)) {
      return false;
    }

    context.labelSpace.occupy(text.text, box);

    return true;
  }
}

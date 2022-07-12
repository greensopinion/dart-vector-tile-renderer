import 'dart:ui';

import '../../vector_tile_renderer.dart';
import '../context.dart';
import '../themes/expression/expression.dart';
import '../themes/style.dart';
import 'feature_renderer.dart';
import 'text_abbreviator.dart';
import 'text_renderer.dart';
import 'text_wrapper.dart';

class SymbolPointRenderer extends FeatureRenderer {
  final Logger logger;
  SymbolPointRenderer(this.logger);

  @override
  void render(
    Context context,
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
        () => feature.properties, feature.type, logger,
        zoom: context.zoom, zoomScaleFactor: context.zoomScaleFactor);

    final text = textLayout.text.evaluate(evaluationContext);
    if (text == null) {
      logger.warn(() => 'point with no text');
      return;
    }

    final textAbbreviation = TextAbbreviator().abbreviate(text);
    if (!context.labelSpace.canAccept(textAbbreviation)) {
      return;
    }

    logger.log(() => 'rendering symbol points');

    final lines = TextWrapper(textLayout).wrap(evaluationContext, text);

    final textApproximation =
        TextApproximation(context, evaluationContext, style, lines);

    for (final point in feature.points) {
      final offset = context.tileSpaceMapper.pointFromTileToPixels(point);

      if (!_occupyLabelSpaceAtOffset(context, textApproximation, offset)) {
        continue;
      }

      context.tileSpaceMapper.drawInPixelSpace(() {
        textApproximation.renderer.render(offset);
      });
    }
  }

  bool _occupyLabelSpaceAtOffset(
    Context context,
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

    return _preciselyOccupyLabelSpaceAtOffset(box, context, text, offset);
  }

  bool _preciselyOccupyLabelSpaceAtOffset(
    Rect approximateBox,
    Context context,
    TextApproximation text,
    Offset offset,
  ) {
    final box = text.renderer.labelBox(offset, translated: true);
    if (box == null) {
      if (text.styledSymbol != null) {
        context.labelSpace.occupy(text.text, approximateBox);
        return true;
      }
      return false;
    }

    if (!context.labelSpace.canOccupy(text.text, box)) {
      return false;
    }

    context.labelSpace.occupy(text.text, box);

    return true;
  }
}

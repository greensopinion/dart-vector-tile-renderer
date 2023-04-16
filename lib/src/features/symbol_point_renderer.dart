import 'dart:ui';

import 'package:vector_tile_renderer/src/features/context_extension.dart';
import 'package:vector_tile_renderer/src/features/icon_renderer.dart';
import 'package:vector_tile_renderer/src/features/symbol_layout_extension.dart';

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
    final symbolLayout = style.symbolLayout;
    if (symbolLayout == null) {
      logger.warn(() => 'point does layout');
      return;
    }

    final evaluationContext = EvaluationContext(
        () => feature.properties, feature.type, logger,
        zoom: context.zoom,
        zoomScaleFactor: context.zoomScaleFactor,
        hasImage: context.hasImage);

    final text = symbolLayout.text?.text.evaluate(evaluationContext);
    final icon = symbolLayout.getIcon(context, evaluationContext);
    if (text == null && icon == null) {
      logger.warn(() => 'point with no text or icon');
      return;
    }
    final textAbbreviation =
        text == null ? null : TextAbbreviator().abbreviate(text);
    if (textAbbreviation != null &&
        !context.labelSpace.canAccept(textAbbreviation)) {
      return;
    }
    final lines = text == null
        ? null
        : TextWrapper(symbolLayout.text!).wrap(evaluationContext, text);

    final textApproximation = lines == null
        ? null
        : TextApproximation(context, evaluationContext, style, lines);

    logger.log(() => 'rendering symbol points');

    for (final point in feature.points) {
      final offset = context.tileSpaceMapper.pointFromTileToPixels(point);

      if (textApproximation != null &&
          (!_occupyLabelSpaceAtOffset(context, textApproximation, offset) ||
              !textApproximation.renderer.canPaint)) {
        continue;
      }

      context.tileSpaceMapper.drawInPixelSpace(() {
        if (icon != null) {
          icon.render(offset,
              contentSize: textApproximation?.renderer.size ?? Size.zero);
        }
        if (textApproximation != null) {
          textApproximation.renderer.render(offset);
        }
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

    if (!context.labelSpace.canOccupy(text.text, box) ||
        text.styledSymbol == null) {
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

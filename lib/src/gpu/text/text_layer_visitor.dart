import 'dart:math';
import 'dart:ui';

import 'package:vector_tile_renderer/src/features/text_abbreviator.dart';
import 'package:vector_tile_renderer/src/gpu/text/sdf/glyph_atlas_data.dart';
import 'package:vector_tile_renderer/src/gpu/tile_render_data.dart';

import '../../../vector_tile_renderer.dart';
import '../../features/symbol_rotation.dart';
import '../../themes/expression/expression.dart';
import '../../themes/feature_resolver.dart';
import '../../themes/style.dart';
import '../color_extension.dart';
import 'ndc_label_space.dart';
import 'text_builder.dart';

class TextLayerVisitor {
  final TileRenderData renderData;
  final VisitorContext context;
  final AtlasSet atlasSet;

  final Set<String> alreadyAdded = <String>{};

  TextLayerVisitor(this.renderData, this.context, this.atlasSet);

  void addFeatures(Style style, Iterable<LayerFeature> features, Map<double, NdcLabelSpace> labelSpaces) {
    final symbolLayout = style.symbolLayout;
    if (symbolLayout == null || atlasSet.isEmpty) {
      return;
    }
    final textBuilder = TextBuilder(atlasSet);
    for (var feature in features) {
      final evaluationContext = EvaluationContext(
          () => feature.feature.properties,
          TileFeatureType.none,
          context.logger,
          zoom: context.zoom,
          zoomScaleFactor: 1.0,
          hasImage: (_) => false);

      final text = symbolLayout.text?.text.evaluate(evaluationContext);

      double? textSize =
          style.symbolLayout?.text?.textSize.evaluate(evaluationContext);

      final paint = style.textPaint?.evaluate(evaluationContext);

      final textHalo =
          (style.textHalo?.evaluate(evaluationContext) ?? []).firstOrNull;

      var layoutPlacement =
          style.symbolLayout?.placement.evaluate(evaluationContext) ??
              LayoutPlacement.DEFAULT;


      final anchor = style.symbolLayout?.text?.anchor.evaluate(evaluationContext) ?? LayoutAnchor.DEFAULT;

      final rotationAlignment = style.symbolLayout?.textRotationAlignment(
              evaluationContext,
              layoutPlacement: layoutPlacement) ??
          RotationAlignment.map;

      if (text == null ||
          text.isEmpty ||
          textSize == null ||
          alreadyAdded.contains(text) ||
          paint == null) {
        continue;
      }
      final fontFamily = style.symbolLayout?.text?.fontFamily ?? AtlasID.defaultFont;
      final line = feature.feature.modelLines.firstOrNull;
      final point = feature.feature.modelPoints.firstOrNull;

      alreadyAdded.add(text);

      final isLineString = line != null;

      final maxWidth = (symbolLayout.text?.maxWidth?.evaluate(evaluationContext) ?? 10.0).ceil();

      final fontStyle = symbolLayout.text?.fontStyle ?? FontStyle.normal;

      textBuilder.addText(
          text: TextAbbreviator().abbreviate(text),
          fontSize: textSize.toInt(),
          fontFamily: "$fontFamily%${fontStyle.name}",
          line: line,
          point: point,
          canvasSize: 4096,
          rotationAlignment: rotationAlignment,
          labelSpaces: labelSpaces,
          color: paint.color.vector4,
          haloColor: textHalo?.color.vector4,
          maxWidth: maxWidth,
          isLineString: isLineString,
          displayScaleFactor: context.pixelRatio,
          anchor: anchor
      );
    }

    renderData.addMeshes(textBuilder.getMeshes());
  }

}
import 'dart:math';

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
      final fontFamily = style.symbolLayout?.text?.fontFamily;
      final line = feature.feature.modelLines.firstOrNull;

      final point = feature.feature.modelPoints.firstOrNull ??
          () {
            if (line == null) return null;
            return line.points[line.points.length ~/ 2];
          }.call();

      if (point == null ||
          point.x < 0 ||
          point.x > 4096 ||
          point.y < 0 ||
          point.y > 4096) {
        continue;
      }

      var rotation = 0.0;

      if (rotationAlignment == RotationAlignment.map && line != null) {
        rotation = _getLineAngle(line.points);
      }

      alreadyAdded.add(text);


      textBuilder.addText(
          text: TextAbbreviator().abbreviate(text),
          fontSize: textSize.toInt() * 16,
          fontFamily: fontFamily,
          x: point.x,
          y: point.y,
          canvasSize: 4096,
          rotation: rotation,
          rotationAlignment: rotationAlignment,
          labelSpaces: labelSpaces,
          color: paint.color.vector4,
          haloColor: textHalo?.color.vector4,
      );
    }

    renderData.addMeshes(textBuilder.getMeshes());
  }

  double _getLineAngle(List<Point<double>> points) {
    double rotation = 0.0;
    if (points.length >= 3) {
      final middleIndex = points.length ~/ 2;

      final beforePoint = points[middleIndex - 1];
      final afterPoint = points[middleIndex + 1];

      final newRot = atan2(afterPoint.y - beforePoint.y,
          afterPoint.x - beforePoint.x);

      if (newRot.isFinite) {
        rotation = newRot;
      }
    } else if (points.length >= 2) {
      final newRot = atan2(points.last.y - points.first.y,
          points.last.x - points.first.x);
      if (newRot.isFinite) {
        rotation = newRot;
      }
    }
    return rotation;
  }
}
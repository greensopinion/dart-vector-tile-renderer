import 'dart:math';

import 'package:flutter_scene/scene.dart';
import 'package:vector_tile_renderer/src/gpu/text/gpu_label_space.dart';

import '../../../vector_tile_renderer.dart';
import '../../features/symbol_rotation.dart';
import '../../themes/expression/expression.dart';
import '../../themes/feature_resolver.dart';
import '../../themes/style.dart';
import '../color_extension.dart';
import 'sdf/sdf_atlas_provider.dart';
import 'text_builder.dart';

class TextLayerVisitor {
  final SceneGraph graph;
  final SdfAtlasProvider atlasProvider;
  final VisitorContext context;
  final Set<String> alreadyAdded = <String>{};

  TextLayerVisitor(this.atlasProvider, this.graph, this.context);

  void addFeatures(Style style, Iterable<LayerFeature> features, GpuLabelSpace labelSpace) {
    final symbolLayout = style.symbolLayout;
    if (symbolLayout == null) {
      return;
    }
    final textBuilder = TextBuilder(atlasProvider);
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

      if (rotationAlignment == RotationAlignment.map &&
          line != null &&
          line.points.length > 1) {
        final newRot = atan2(line.points.last.y - line.points.first.y,
            line.points.last.x - line.points.first.x);
        if (newRot.isFinite) {
          rotation = newRot;
        }
      }

      alreadyAdded.add(text);

      if (textHalo != null) {
        // textBuilder.addText(
        //     text,
        //     textHalo.color.vector4,
        //     textSize.toInt() * 16,
        //     fontFamily,
        //     1.5,
        //     point.x,
        //     point.y,
        //     4096,
        //     graph,
        //     rotation,
        //     rotationAlignment);
      }

      textBuilder.addText(
          text,
          paint.color.vector4,
          textSize.toInt() * 16,
          fontFamily,
          1.0,
          point.x,
          point.y,
          4096,
          graph,
          rotation,
          rotationAlignment,
          labelSpace
      );
    }
  }
}

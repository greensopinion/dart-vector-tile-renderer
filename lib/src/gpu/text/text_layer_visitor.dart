import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:vector_math/vector_math.dart';
import 'package:vector_tile_renderer/src/gpu/bucket_unpacker.dart';
import 'package:vector_tile_renderer/src/gpu/text/sdf/atlas_provider.dart';
import 'package:vector_tile_renderer/src/gpu/text/sdf/glyph_atlas_data.dart';
import 'package:vector_tile_renderer/src/gpu/tile_render_data.dart';
import 'package:vector_tile_renderer/src/gpu/utils.dart';

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
  final AtlasProvider atlasProvider;

  final Set<String> alreadyAdded = <String>{};

  TextLayerVisitor(this.renderData, this.context, this.atlasProvider);

  void addFeatures(Style style, Iterable<LayerFeature> features, NdcLabelSpace labelSpace) {
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



      final geom = textBuilder.addText(
          text: text,
          fontSize: textSize.toInt() * 16,
          fontFamily: fontFamily,
          x: point.x,
          y: point.y,
          canvasSize: 4096,
          rotation: rotation,
          rotationAlignment: rotationAlignment,
          labelSpace: labelSpace
      );

      final textureID = _createPlaceholderId(fontFamily).hashCode;
      final textureIDBytes = intToByteData(textureID).buffer.asUint8List();

      if (geom == null) continue;



      if (textHalo != null) {
        final mesh = _createTextMesh(geom, textureIDBytes, textHalo.color.vector4, true);
        renderData.addMesh(mesh);
      }
      final mesh = _createTextMesh(geom, textureIDBytes, paint.color.vector4, false);
      renderData.addMesh(mesh);
    }
  }

  PackedMesh _createTextMesh(PackedGeometry geom, Uint8List textureIDBytes, Vector4 color, bool isHalo) {
    final softnessAndThreshold = isHalo ? [0.06, 0.85] : [0.02, 0.975];
    
    final uniform = (
        BytesBuilder(copy: true)
          ..add(textureIDBytes)
          ..add(Float32List.fromList([
            color.r, color.g, color.b, color.a, 1.0, ...softnessAndThreshold,
          ]).buffer.asUint8List())
    ).toBytes().buffer.asByteData();

    final material = PackedMaterial(type: MaterialType.text, uniform: uniform);
    
    return PackedMesh(geom, material);
  }
}

//FIXME: need to provide atlasses for character ranges beyond 256
AtlasID _createPlaceholderId(String? fontFamily) =>
    AtlasID(font: fontFamily ?? 'Roboto Regular', charStart: 0, charCount: 256);
import 'dart:math';
import 'dart:typed_data';

import 'package:dart_earcut/dart_earcut.dart';
import 'package:flutter_gpu/gpu.dart' as gpu;
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart';
import 'package:vector_tile_renderer/src/gpu/color_extension.dart';
import 'package:vector_tile_renderer/src/gpu/colored_material.dart';
import 'package:vector_tile_renderer/src/gpu/shaders.dart';
import 'package:vector_tile_renderer/src/themes/expression/expression.dart';
import 'package:vector_tile_renderer/src/themes/feature_resolver.dart';
import 'package:vector_tile_renderer/src/themes/style.dart';

import '../../vector_tile_renderer.dart';

class ScenePolygonBuilder {
  final Scene scene;
  final VisitorContext context;

  ScenePolygonBuilder(this.scene, this.context);

  void addPolygons(Style style, Iterable<LayerFeature> features) {
    for (final feature in features) {
      addPolygon(style, feature);
    }
  }

  void addPolygon(Style style, LayerFeature feature) {
    EvaluationContext evaluationContext = EvaluationContext(
        () => {}, TileFeatureType.none, context.logger,
        zoom: context.zoom, zoomScaleFactor: 1.0, hasImage: (_) => false);

    final polygons = feature.feature.modelPolygons;
    final fillPaint =
        style.fillPaint?.evaluate(evaluationContext)?.color.vector4 ??
            Vector4(1, 0, 0, 1);


    for (final polygon in polygons) {
      final flat = polygon.rings
          .expand((ring) => ring.points)
          .map((point) => <double>[point.x.toDouble(), point.y.toDouble()])
          .expand((e) => e)
          .toList();



      final indices = Earcut.triangulateRaw(flat);

      final normalized = <double>[];
      for (var i = 0; i < flat.length; i += 2) {
        final x = flat[i], y = flat[i + 1];
        normalized.addAll([
          x / 2048.0 - 1,
          1 - y / 2048.0,
          0.0,
        ]);
      }

      final fixedIndices = <int>[];
      for (int i = 0; i < indices.length; i += 3) {
        fixedIndices.addAll([
          indices[i],
          indices[i + 2],
          indices[i + 1],
        ]);
      }


      scene.addMesh(
        Mesh(
          UnskinnedGeometry()
              ..setVertexShader(shaderLibrary["SimpleVertex"]!)
              ..uploadVertexData(
                ByteData.sublistView(Float32List.fromList(normalized)),
                  normalized.length ~/ 3,
                ByteData.sublistView(Uint16List.fromList(fixedIndices)),
                indexType: gpu.IndexType.int16,
              ),
            ColoredMaterial(fillPaint)
        )
      );
    }
  }
}

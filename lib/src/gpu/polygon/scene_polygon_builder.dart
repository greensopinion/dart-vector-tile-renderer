import 'dart:typed_data';

import 'package:flutter_scene/scene.dart';
import 'package:vector_tile_renderer/src/gpu/color_extension.dart';
import 'package:vector_tile_renderer/src/gpu/colored_material.dart';
import 'package:vector_tile_renderer/src/gpu/line/scene_line_builder.dart';
import 'package:vector_tile_renderer/src/gpu/polygon/polygon_geometry.dart';
import 'package:vector_tile_renderer/src/themes/expression/expression.dart';
import 'package:vector_tile_renderer/src/themes/feature_resolver.dart';
import 'package:vector_tile_renderer/src/themes/style.dart';

import '../../../vector_tile_renderer.dart';
import '../../themes/paint_model.dart';

class ScenePolygonBuilder {
  final SceneGraph graph;
  final VisitorContext context;

  ScenePolygonBuilder(this.graph, this.context);

  void addPolygons(Style style, Iterable<LayerFeature> features) {
    Map<PaintModel, List<TriangulatedPolygon>> featureGroups = {};

    for (final feature in features) {
      EvaluationContext evaluationContext = EvaluationContext(
          () => feature.feature.properties,
          TileFeatureType.none,
          context.logger,
          zoom: context.zoom,
          zoomScaleFactor: 1.0,
          hasImage: (_) => false);

      final paint = style.fillPaint?.evaluate(evaluationContext);

      if (paint == null) {
        continue;
      }

      if (!featureGroups.containsKey(paint)) {
        featureGroups[paint] = [];
      }
      final group = featureGroups[paint]!;

      if (group.isEmpty) {
        group.add(TriangulatedPolygon(normalizedVertices: [], indices: []));
      }

      if (group.last.normalizedVertices.length > 200000) {
        group.add(feature.feature.earcutPolygons);
      } else {
        group.last.combine(feature.feature.earcutPolygons);
      }
    }

    featureGroups.forEach((paint, polygons) {
      for (var polygon in polygons) {
        graph.addMesh(Mesh(
            PolygonGeometry(ByteData.sublistView(Float32List.fromList(polygon.normalizedVertices)), ByteData.sublistView(Uint16List.fromList(polygon.indices))),
            ColoredMaterial(paint.color.vector4, antialiasingEnabled: true)));
      }
    });
  }
}

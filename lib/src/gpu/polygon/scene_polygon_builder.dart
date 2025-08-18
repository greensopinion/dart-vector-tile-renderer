import 'package:flutter_scene/scene.dart';

import '../../../vector_tile_renderer.dart';
import '../../model/geometry_model.dart';
import '../../themes/expression/expression.dart';
import '../../themes/feature_resolver.dart';
import '../../themes/paint_model.dart';
import '../../themes/style.dart';
import '../color_extension.dart';
import '../colored_material.dart';
import '../concurrent/main/geometry_workers.dart';

class FeatureGroup {
  final List<TilePolygon> polygons = [];
  int size = 0;
}

class ScenePolygonBuilder {
  final SceneGraph graph;
  final VisitorContext context;
  final GeometryWorkers geometryWorkers;

  ScenePolygonBuilder(this.graph, this.context, this.geometryWorkers);

  Future<void> addPolygons(Style style, Iterable<LayerFeature> features) async {
    Map<PaintModel, List<FeatureGroup>> featureGroups = {};

    for (final feature in features) {
      EvaluationContext evaluationContext = EvaluationContext(
          () => feature.feature.properties,
          TileFeatureType.none,
          context.logger,
          zoom: context.zoom,
          zoomScaleFactor: 1.0,
          hasImage: (_) => false);

      final paint = style.fillPaint?.evaluate(evaluationContext);
      final polygons = feature.feature.modelPolygons;

      if (paint == null || polygons.isEmpty) {
        continue;
      }

      if (!featureGroups.containsKey(paint)) {
        featureGroups[paint] = [FeatureGroup()];
      }

      if (featureGroups[paint]!.last.size > 4096) {
        featureGroups[paint]!.add(FeatureGroup());
      }

      final group = featureGroups[paint]!.last;

      group.size += getPointCount(polygons);

      group.polygons.addAll(polygons);
    }

    final polygonFutures = <Future<void>>[];

    featureGroups.forEach((paint, polygonGroup) {
      for (var polygons in polygonGroup) {
        polygonFutures.add(
          addMesh(polygons.polygons, paint),
        );
      }
    });

    await Future.wait(polygonFutures);
  }

  Future<void> addMesh(List<TilePolygon> polygons, PaintModel paint) async {
    final geometry = await geometryWorkers.submitPolygons(polygons);

    graph.addMesh(Mesh(geometry,
        ColoredMaterial(paint.color.vector4, antialiasingEnabled: true)));
  }

  int getPointCount(List<TilePolygon> polygons) => polygons.fold(
      0,
      (sum, value) =>
          sum += value.rings.fold(0, (a, b) => a + b.points.length));
}

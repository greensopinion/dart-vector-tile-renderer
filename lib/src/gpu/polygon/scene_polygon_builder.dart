import 'dart:typed_data';

import 'package:vector_tile_renderer/src/gpu/polygon/polygon_geometry_builder.dart';
import 'package:vector_tile_renderer/src/gpu/tile_render_data.dart';

import '../../../vector_tile_renderer.dart';
import '../../model/geometry_model.dart';
import '../../themes/expression/expression.dart';
import '../../themes/feature_resolver.dart';
import '../../themes/paint_model.dart';
import '../../themes/style.dart';
import '../bucket_unpacker.dart';
import '../color_extension.dart';

class FeatureGroup {
  final List<TilePolygon> polygons = [];
  int size = 0;
}

class ScenePolygonBuilder {
  final TileRenderData renderData;
  final VisitorContext context;

  ScenePolygonBuilder(this.renderData, this.context);

  void addPolygons(Style style, Iterable<LayerFeature> features) {
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

    featureGroups.forEach((paint, polygonGroup) {
      for (var polygons in polygonGroup) {
        addMesh(polygons.polygons, paint);
      }
    });
  }

  void addMesh(List<TilePolygon> polygons, PaintModel paint) {
    final (vertices, indices) = PolygonGeometryBuilder().build(polygons);

    final color = paint.color.vector4;

    final ByteData uniform = Float32List.fromList([color.x, color.y, color.z, color.w]).buffer.asByteData();

    renderData.addMesh(PackedMesh(
        PackedGeometry(vertices: vertices, indices: indices, type: GeometryType.polygon),
        PackedMaterial(uniform: uniform, type: MaterialType.colored)
    ));
  }

  int getPointCount(List<TilePolygon> polygons) => polygons.fold(
      0,
      (sum, value) =>
          sum += value.rings.fold(0, (a, b) => a + b.points.length));
}

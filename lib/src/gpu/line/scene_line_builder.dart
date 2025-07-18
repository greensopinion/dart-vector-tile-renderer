import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_tile_renderer/src/gpu/line/line_geometry_builder.dart';
import 'package:vector_tile_renderer/src/gpu/line/line_material.dart';

import '../../../vector_tile_renderer.dart';
import '../../model/geometry_model.dart';
import '../../themes/expression/expression.dart';
import '../../themes/feature_resolver.dart';
import '../../themes/paint_model.dart';
import '../../themes/style.dart';
import '../color_extension.dart';

class SceneLineBuilder {
  final Scene scene;
  final VisitorContext context;

  SceneLineBuilder(this.scene, this.context);

  void addFeatures(Style style, Iterable<LayerFeature> features) {
    Map<PaintModel, List<TileLine>> featureGroups = {};
    for (final feature in features) {
      final result = getLines(style, feature);
      if (result != null) {
        final (paint, lines) = result;

        if (!featureGroups.containsKey(paint)) {
          featureGroups[paint] = [];
        }

        featureGroups[paint]!.addAll(lines);
      }
    }
    featureGroups.forEach((paint, lines) {
      addMesh(lines, paint.strokeWidth!, features.first.layer.extent, paint, paint.strokeDashPattern);
    });
  }

  (PaintModel, Iterable<TileLine>)? getLines(Style style, LayerFeature feature) {
    EvaluationContext evaluationContext = EvaluationContext(
        () => feature.feature.properties, TileFeatureType.none, context.logger,
        zoom: context.zoom, zoomScaleFactor: 1.0, hasImage: (_) => false);

    final paint = style.linePaint?.evaluate(evaluationContext);

    if (paint != null && paint.strokeWidth != null && paint.strokeWidth! > 0) {
      if (feature.feature.modelLines.isNotEmpty) {
        return (paint, feature.feature.modelLines);
      } else if (
      feature.feature.modelPolygons.isNotEmpty) {

        var outlines = feature.feature.modelPolygons
            .expand((poly) => {poly.rings.map((ring) => TileLine(List.of(ring.points)..add(ring.points.first)))})
            .flattened
            .toList();

        return (paint, outlines);
      }
    }
    return null;
  }

  void addMesh(List<TileLine> lines, double lineWidth, int extent, PaintModel paint, List<double>? dashLengths) {
    Geometry mainGeometry = LineGeometryBuilder().build(
        lines, paint.lineCap ?? LineCap.DEFAULT, paint.lineJoin ?? LineJoin.DEFAULT, lineWidth, extent, dashLengths);

    scene.addMesh(Mesh(mainGeometry, LineMaterial(paint.color.vector4, dashLengths)));
  }
}

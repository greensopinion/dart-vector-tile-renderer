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
    for (final feature in features) {
      addLines(style, feature);
    }
  }

  void addLines(Style style, LayerFeature feature) {
    EvaluationContext evaluationContext = EvaluationContext(
        () => feature.feature.properties, TileFeatureType.none, context.logger,
        zoom: context.zoom, zoomScaleFactor: 1.0, hasImage: (_) => false);

    final paint = style.linePaint?.evaluate(evaluationContext);
    final outlinePaint = style.outlinePaint?.evaluate(evaluationContext);

    final lineWidth = paint?.strokeWidth ?? outlinePaint?.strokeWidth;
    final dashLengths = paint?.strokeDashPattern;

    if (lineWidth == null || paint == null || lineWidth <= 0) {
      return;
    }
    if (feature.feature.modelLines.isNotEmpty) {
      addMesh(feature.feature.modelLines, lineWidth, feature.layer.extent, paint, dashLengths);
    }

    if (feature.feature.modelPolygons.isNotEmpty) {
      var outlines = feature.feature.modelPolygons
          .expand((poly) => {poly.rings.map((ring) => TileLine(List.of(ring.points)..add(ring.points.first)))})
          .flattened
          .toList();
      addMesh(outlines, lineWidth, feature.layer.extent, paint, dashLengths);
    }
  }

  void addMesh(List<TileLine> lines, double lineWidth, int extent, PaintModel paint, List<double>? dashLengths) {
    Geometry mainGeometry = LineGeometryBuilder().build(
        lines, paint.lineCap ?? LineCap.DEFAULT, paint.lineJoin ?? LineJoin.DEFAULT, lineWidth, extent, dashLengths);

    scene.addMesh(Mesh(mainGeometry, LineMaterial(paint.color.vector4, dashLengths)));
  }
}

import 'dart:math';

import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart';
import 'package:vector_tile_renderer/src/gpu/line/line_end_geometry.dart';
import 'package:vector_tile_renderer/src/gpu/line/line_end_material.dart';

import '../../../vector_tile_renderer.dart';
import '../../themes/expression/expression.dart';
import '../../themes/feature_resolver.dart';
import '../../themes/style.dart';
import '../color_extension.dart';
import '../colored_material.dart';
import 'line_geometry.dart';

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
    final lineWidth = paint?.strokeWidth;
    final color = paint?.color.vector4;
    if (lineWidth == null || color == null || lineWidth <= 0) {
      return;
    }
    for (var line in feature.feature.modelLines) {
      final linePoints = line.points;
      if (linePoints.length > 1 && lineWidth > 0) {
        addLine(linePoints, lineWidth, feature, color);
      }
    }

    for (final polygon in feature.feature.modelPolygons) {
      for (int i = 0; i < polygon.rings.length; i++) {
        final ring = polygon.rings[i];
        final points = List.of(ring.points)..add(ring.points.first);
        addLine(points, lineWidth, feature, color);
      }
    }
  }

  void addLine(List<Point<double>> linePoints, double lineWidth,
      LayerFeature feature, Vector4 color) {
    Geometry mainGeometry = LineGeometry(
        points: linePoints, lineWidth: lineWidth, extent: feature.layer.extent);

    scene.addMesh(Mesh(mainGeometry, ColoredMaterial(color)));

    Geometry endGeometry = LineEndGeometry(
        points: linePoints, lineWidth: lineWidth, extent: feature.layer.extent);

    scene.addMesh(Mesh(endGeometry, LineEndMaterial(color)));
  }
}

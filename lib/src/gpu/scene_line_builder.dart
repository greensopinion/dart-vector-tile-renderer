import 'dart:math';

import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart';
import 'package:vector_tile_renderer/src/gpu/color_extension.dart';
import 'package:vector_tile_renderer/src/gpu/line_geometry.dart';
import 'package:vector_tile_renderer/src/gpu/colored_material.dart';
import 'package:vector_tile_renderer/src/themes/expression/expression.dart';
import 'package:vector_tile_renderer/src/themes/feature_resolver.dart';
import 'package:vector_tile_renderer/src/themes/style.dart';

import '../../vector_tile_renderer.dart';

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
        () => {}, TileFeatureType.none, context.logger,
        zoom: context.zoom, zoomScaleFactor: 1.0, hasImage: (_) => false);

    final double lineWidth =
        style.linePaint?.evaluate(evaluationContext)?.strokeWidth ?? 0;
    final Vector4 color =
        style.linePaint?.evaluate(evaluationContext)?.color.vector4 ??
            Vector4(0, 0, 0, 0);

    for (var line in feature.feature.modelLines) {
      final linePoints = line.points;
      if (linePoints.isNotEmpty && lineWidth > 0) {
        addLine(linePoints, lineWidth, feature, color);
      }
    }
  }

  void addLine(List<Point<double>> linePoints, double lineWidth,
      LayerFeature feature, Vector4 color) {
    Geometry geometry = LineGeometry(
        points: linePoints, lineWidth: lineWidth, extent: feature.layer.extent);

    scene.addMesh(Mesh(geometry, ColoredMaterial(color)));
  }
}

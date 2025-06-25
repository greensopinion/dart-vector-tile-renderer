import 'package:collection/collection.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_tile_renderer/src/gpu/line_geometry.dart';
import 'package:vector_tile_renderer/src/gpu/line_material.dart';
import 'package:vector_tile_renderer/src/themes/expression/expression.dart';
import 'package:vector_tile_renderer/src/themes/feature_resolver.dart';
import 'package:vector_tile_renderer/src/themes/style.dart';

import '../../vector_tile_renderer.dart';

class SceneLineBuilder {
  final Scene scene;
  final VisitorContext context;

  SceneLineBuilder(this.scene, this.context);

  void addLines(Style style, Iterable<LayerFeature> features) {
    for (final feature in features) {
      addLine(style, feature);
    }
  }

  void addLine(Style style, LayerFeature feature) {

    EvaluationContext evaluationContext = EvaluationContext(
            () => {}, TileFeatureType.none, context.logger,
        zoom: context.zoom, zoomScaleFactor: 1.0, hasImage: (_) => false);

    final double lineWidth = style.linePaint?.evaluate(evaluationContext)?.strokeWidth ?? 0;
    final linePoints = feature.feature.modelLines.expand((it) => {it.points}).flattened;

    if (linePoints.isNotEmpty && lineWidth > 0) {
      scene.addMesh(Mesh(LineGeometry(linePoints, lineWidth), LineMaterial()));
    }
  }
}

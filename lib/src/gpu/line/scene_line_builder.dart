import 'dart:math';

import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart';
import 'package:vector_tile_renderer/src/gpu/line/line_end_geometry.dart';
import 'package:vector_tile_renderer/src/gpu/line/line_material.dart';

import '../../../vector_tile_renderer.dart';
import '../../themes/expression/expression.dart';
import '../../themes/feature_resolver.dart';
import '../../themes/paint_model.dart';
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

    if (lineWidth == null || paint == null || lineWidth <= 0) {
      return;
    }

    for (var line in feature.feature.modelLines) {
      final linePoints = line.points;
      if (linePoints.length > 1 && lineWidth > 0) {
        addLine(linePoints, lineWidth, feature.layer.extent, paint);
      }
    }
  }

  void addLine(
      List<Point<double>> linePoints,
      double lineWidth,
      int extent,
      PaintModel paint
  ) {
    Geometry mainGeometry = LineGeometry(
        points: linePoints,
        lineWidth: lineWidth,
        extent: extent
    );

    scene.addMesh(Mesh(mainGeometry, LineMaterial(paint.color.vector4)));
  }
}

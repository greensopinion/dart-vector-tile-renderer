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

    if (lineWidth == null || paint == null || lineWidth <= 0) {
      return;
    }

    final color = paint.color.vector4;
    final joinType = paint.lineJoin;
    final capType = paint.lineCap;

    for (var line in feature.feature.modelLines) {
      final linePoints = line.points;
      if (linePoints.length > 1 && lineWidth > 0) {
        addLine(linePoints, lineWidth, feature.layer.extent, color, joinType, capType);
      }
    }
  }

  void addLine(
      List<Point<double>> linePoints,
      double lineWidth,
      int extent,
      Vector4 color,
      LineJoin? joinType,
      LineCap? capType
  ) {
    Geometry mainGeometry = LineGeometry(
        points: linePoints,
        lineWidth: lineWidth,
        extent: extent
    );

    scene.addMesh(Mesh(mainGeometry, ColoredMaterial(color)));

    if (capType != null && capType != LineCap.butt) {
      Geometry endGeometry = LineEndGeometry(
        points: linePoints,
        lineWidth: lineWidth,
        extent: extent,
      );

      scene.addMesh(Mesh(endGeometry, LineEndMaterial(color, capType)));
    }
  }
}

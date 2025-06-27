import 'dart:ui';

import 'package:flutter_scene/scene.dart';

import '../../../vector_tile_renderer.dart';
import '../../themes/expression/expression.dart';
import '../../themes/feature_resolver.dart';
import '../../themes/style.dart';
import '../color_extension.dart';
import '../colored_material.dart';
import 'polygon_geometry.dart';

class ScenePolygonBuilder {
  final Scene scene;
  final VisitorContext context;

  ScenePolygonBuilder(this.scene, this.context);

  void addPolygons(Style style, Iterable<LayerFeature> features) {
    for (final feature in features) {
      addPolygon(style, feature);
    }
  }

  void addPolygon(Style style, LayerFeature feature) {
    final polygons = feature.feature.modelPolygons;

    EvaluationContext evaluationContext = EvaluationContext(
        () => feature.feature.properties, TileFeatureType.none, context.logger,
        zoom: context.zoom, zoomScaleFactor: 1.0, hasImage: (_) => false);

    final fillPaint = style.fillPaint?.evaluate(evaluationContext)?.color;
    if (fillPaint == null) {
      return;
    }
    final color = fillPaint.vector4;
    for (final polygon in polygons) {
      scene.addMesh(Mesh(PolygonGeometry(polygon), ColoredMaterial(color)));
    }
  }
}

import 'dart:typed_data';

import 'package:flutter_scene/scene.dart';
import 'package:vector_tile_renderer/src/gpu/color_extension.dart';
import 'package:vector_tile_renderer/src/gpu/colored_material.dart';
import 'package:vector_tile_renderer/src/gpu/polygon/polygon_geometry.dart';
import 'package:vector_tile_renderer/src/themes/expression/expression.dart';
import 'package:vector_tile_renderer/src/themes/feature_resolver.dart';
import 'package:vector_tile_renderer/src/themes/style.dart';

import '../../../vector_tile_renderer.dart';

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

    for (final polygon in polygons) {
      EvaluationContext evaluationContext = EvaluationContext(
          () => {}, TileFeatureType.none, context.logger,
          zoom: context.zoom, zoomScaleFactor: 1.0, hasImage: (_) => false);

      final fillPaint =
          style.fillPaint?.evaluate(evaluationContext)?.color.vector4;
      if (fillPaint == null) {
        return;
      }

      scene.addMesh(Mesh(PolygonGeometry(polygon), ColoredMaterial(fillPaint)));
    }
  }
}

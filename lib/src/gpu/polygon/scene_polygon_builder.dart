import 'dart:typed_data';

import 'package:flutter_scene/scene.dart';
import 'package:vector_tile_renderer/src/gpu/color_extension.dart';
import 'package:vector_tile_renderer/src/gpu/colored_material.dart';
import 'package:vector_tile_renderer/src/gpu/line/scene_line_builder.dart';
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

    EvaluationContext evaluationContext = EvaluationContext(
        () => feature.feature.properties, TileFeatureType.none, context.logger,
        zoom: context.zoom, zoomScaleFactor: 1.0, hasImage: (_) => false);

    final outlinePaint = style.outlinePaint?.evaluate(evaluationContext);
    if (outlinePaint != null) {
      final lines = SceneLineBuilder(scene, context);

      final outlineColor = outlinePaint.color.vector4;
      final outlineWidth = outlinePaint.strokeWidth;
      final outlineJoin = outlinePaint.lineJoin;
      final outlineCap = outlinePaint.lineCap;

      if (outlineWidth != null) {
        for (final polygon in polygons) {
          for (int i = 0; i < polygon.rings.length; i++) {
            final points = polygon.rings[i].points;
            lines.addLine(points, outlineWidth, feature.layer.extent, outlinePaint);
          }
        }
      }
    }

    final fillPaint = style.fillPaint?.evaluate(evaluationContext);

    if (fillPaint == null) {
      return;
    }
    final fillColor = fillPaint.color.vector4;

    for (final polygon in polygons) {
      scene.addMesh(Mesh(PolygonGeometry(polygon), ColoredMaterial(fillColor)));
    }
  }
}

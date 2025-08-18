import 'dart:ui';

import 'package:flutter/rendering.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart';
import 'package:vector_tile_renderer/src/gpu/concurrent/main/geometry_workers.dart';
import 'package:vector_tile_renderer/src/gpu/line/scene_line_builder.dart';
import 'package:vector_tile_renderer/src/gpu/raster/raster_layer_builder.dart';
import 'package:vector_tile_renderer/src/gpu/text/text_layer_visitor.dart';
import 'package:vector_tile_renderer/src/tileset_raster.dart';

import '../themes/feature_resolver.dart';
import '../themes/style.dart';
import '../themes/theme.dart';
import '../themes/theme_layer_raster.dart';
import 'background/scene_background_builder.dart';
import 'color_extension.dart';
import 'polygon/scene_polygon_builder.dart';

class SceneBuildingVisitor extends LayerVisitor {
  final SceneGraph graph;
  final VisitorContext context;
  static final GeometryWorkers geometryWorkers = GeometryWorkers();

  SceneBuildingVisitor(this.graph, this.context);

  Future<void> visitAllFeatures(Theme theme) async {

    final futures = theme.layers.map((layer) => layer.accept(context, this));

    await Future.wait(futures);
  }

  @override
  Future<void> visitFeatures(VisitorContext context, ThemeLayerType layerType,
      Style style, Iterable<LayerFeature> features) async {
    switch (layerType) {
      case ThemeLayerType.line:
        return SceneLineBuilder(graph, context, geometryWorkers).addFeatures(style, features);
      case ThemeLayerType.fill:
        return ScenePolygonBuilder(graph, context, geometryWorkers).addPolygons(style, features);
      case ThemeLayerType.fillExtrusion:
        return;
      case ThemeLayerType.symbol:
        return TextLayerVisitor(graph, context, geometryWorkers).addFeatures(style, features);
      case ThemeLayerType.background:
      case ThemeLayerType.raster:
      case ThemeLayerType.unsupported:
        return;
    }
  }

  @override
  void visitBackground(VisitorContext context, Vector4 color) {
    SceneBackgroundBuilder(graph, context).addBackground(color);
  }

  @override
  void visitRasterLayer(VisitorContext context, RasterTile image, RasterPaintModel paintModel) {
    RasterLayerBuilder(graph, context).build(image, paintModel);
  }
}

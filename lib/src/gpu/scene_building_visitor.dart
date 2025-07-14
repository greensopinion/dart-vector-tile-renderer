import 'package:flutter/rendering.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_tile_renderer/src/gpu/line/scene_line_builder.dart';
import 'package:vector_tile_renderer/src/gpu/symbol/scene_symbol_builder.dart';

import '../themes/feature_resolver.dart';
import '../themes/style.dart';
import '../themes/theme.dart';
import 'background/scene_background_builder.dart';
import 'color_extension.dart';
import 'polygon/scene_polygon_builder.dart';

class SceneBuildingVisitor extends LayerVisitor {
  final Scene scene;
  final VisitorContext context;

  SceneBuildingVisitor(this.scene, this.context);

  @override
  void visitFeatures(VisitorContext context, ThemeLayerType layerType,
      Style style, Iterable<LayerFeature> features) {
    switch (layerType) {
      case ThemeLayerType.line:
        SceneLineBuilder(scene, context).addFeatures(style, features);
        break;
      case ThemeLayerType.fill:
        ScenePolygonBuilder(scene, context).addPolygons(style, features);
        break;
      case ThemeLayerType.fillExtrusion:
      case ThemeLayerType.symbol:
        SceneSymbolBuilder(scene, context).addSymbols(style, features);
      case ThemeLayerType.background:
      case ThemeLayerType.raster:
      case ThemeLayerType.unsupported:
        return;
    }
  }

  @override
  void visitBackground(VisitorContext context, Color color) {
    SceneBackgroundBuilder(scene, context).addBackground(color.vector4);
  }
}

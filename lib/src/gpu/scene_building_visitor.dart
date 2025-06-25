import 'package:flutter/rendering.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_tile_renderer/src/gpu/color_extension.dart';
import 'package:vector_tile_renderer/src/gpu/scene_background_builder.dart';
import 'package:vector_tile_renderer/src/gpu/scene_line_builder.dart';
import 'package:vector_tile_renderer/src/themes/feature_resolver.dart';
import 'package:vector_tile_renderer/src/themes/style.dart';
import 'package:vector_tile_renderer/src/themes/theme.dart';

class SceneBuildingVisitor extends LayerVisitor {
  final Scene scene;
  final VisitorContext context;

  SceneBuildingVisitor(this.scene, this.context);

  @override
  void visitFeatures(VisitorContext context, ThemeLayerType layerType,
      Style style, Iterable<LayerFeature> features) {
    switch (layerType) {
      case ThemeLayerType.line:
        SceneLineBuilder(scene, context).addLines(style, features);
        break;
      case ThemeLayerType.fill:
      case ThemeLayerType.fillExtrusion:
      case ThemeLayerType.symbol:
      case ThemeLayerType.background:
      case ThemeLayerType.raster:
      case ThemeLayerType.unsupported:
        return;
    }
  }

  @override
  void visitBackground(VisitorContext context, Color color) {
    SceneBackgroundBuilder(scene, context)
        .addBackground(color.vector4);
  }
}

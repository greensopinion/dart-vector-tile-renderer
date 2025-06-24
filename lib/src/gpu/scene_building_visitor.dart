import 'package:flutter/rendering.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_tile_renderer/src/gpu/scene_line_builder.dart';
import 'package:vector_tile_renderer/src/model/tile_model.dart';
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
        context.logger.warn(
            () => 'Unsupported layer type $layerType for features: $features');
    }
  }

  @override
  void visitBackgound(VisitorContext context, Color color) {
    //TODO
  }
}

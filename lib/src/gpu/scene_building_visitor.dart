import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart';

import '../themes/feature_resolver.dart';
import '../themes/style.dart';
import '../themes/theme.dart';
import '../themes/theme_layer_raster.dart';
import '../tileset_raster.dart';
import 'text/text_layer_visitor.dart';

class SceneBuildingVisitor extends LayerVisitor {
  final SceneGraph graph;
  final VisitorContext context;

  SceneBuildingVisitor(this.graph, this.context);

  Future<void> visitAllFeatures(Theme theme) async {
    for (var layer in theme.layers) {
      await layer.accept(context, this);
    }
  }

  @override
  void visitFeatures(VisitorContext context, ThemeLayerType layerType,
      Style style, Iterable<LayerFeature> features) {
    if (layerType == ThemeLayerType.symbol) {
      TextLayerVisitor(graph, context).addFeatures(style, features);
    }
  }

  @override
  void visitBackground(VisitorContext context, Vector4 color) {}

  @override
  void visitRasterLayer(
      VisitorContext context, RasterTile image, RasterPaintModel paintModel) {}
}

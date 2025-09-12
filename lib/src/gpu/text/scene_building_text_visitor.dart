import 'package:flutter_scene/scene.dart';
import 'package:vector_tile_renderer/src/gpu/text/sdf/atlas_provider.dart';
import 'package:vector_tile_renderer/src/gpu/texture_provider.dart';

import '../../themes/feature_resolver.dart';
import '../../themes/style.dart';
import '../../themes/theme.dart';
import 'ndc_label_space.dart';
import 'text_layer_visitor.dart';

class SceneBuildingTextVisitor extends LayerVisitor {
  final AtlasProvider atlasProvider;
  final TextureProvider textureProvider;
  final SceneGraph graph;
  final VisitorContext context;

  final labelSpace = NdcLabelSpace();

  SceneBuildingTextVisitor(this.atlasProvider, this.graph, this.context, this.textureProvider);

  void visitAllFeatures(Theme theme) {
    for (var layer in theme.layers) {
      layer.accept(context, this);
    }
  }

  @override
  void visitFeatures(VisitorContext context, ThemeLayerType layerType,
      Style style, Iterable<LayerFeature> features) {
    if (layerType == ThemeLayerType.symbol) {
      TextLayerVisitor(atlasProvider, graph, context, textureProvider)
          .addFeatures(style, features, labelSpace);
    }
  }
}

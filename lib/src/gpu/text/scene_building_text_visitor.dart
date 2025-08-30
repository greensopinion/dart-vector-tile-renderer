import 'package:flutter_scene/scene.dart';

import '../../themes/feature_resolver.dart';
import '../../themes/style.dart';
import '../../themes/theme.dart';
import 'sdf/sdf_atlas_provider.dart';
import 'text_layer_visitor.dart';

class SceneBuildingTextVisitor extends LayerVisitor {
  final SdfAtlasProvider atlasProvider;
  final SceneGraph graph;
  final VisitorContext context;

  SceneBuildingTextVisitor(this.atlasProvider, this.graph, this.context);

  void visitAllFeatures(Theme theme) {
    for (var layer in theme.layers) {
      layer.accept(context, this);
    }
  }

  @override
  void visitFeatures(VisitorContext context, ThemeLayerType layerType,
      Style style, Iterable<LayerFeature> features) {
    if (layerType == ThemeLayerType.symbol) {
      TextLayerVisitor(atlasProvider, graph, context)
          .addFeatures(style, features);
    }
  }
}

import 'package:vector_tile_renderer/src/gpu/text/sdf/atlas_generator.dart';
import 'package:vector_tile_renderer/src/gpu/text/sdf/atlas_provider.dart';

import '../../../vector_tile_renderer.dart';
import '../../themes/expression/expression.dart';
import '../../themes/feature_resolver.dart';
import '../../themes/style.dart';

class AtlasCreatingTextVisitor extends LayerVisitorAsync {
  final AtlasGenerator atlasGenerator;
  final Theme theme;

  AtlasCreatingTextVisitor(this.atlasGenerator, this.theme);

  Future visitAllFeatures(VisitorContext context) async {
    for (var layer in theme.layers) {
      await layer.acceptAsync(context, this);
    }
  }

  @override
  Future<dynamic> visitFeatures(
      VisitorContext context,
      ThemeLayerType layerType,
      Style style,
      Iterable<LayerFeature> features) async {
    final symbolLayout = style.symbolLayout;
    if (symbolLayout == null) {
      return;
    }
    if (layerType == ThemeLayerType.symbol) {
      for (var feature in features) {
        final evaluationContext = EvaluationContext(
            () => feature.feature.properties,
            TileFeatureType.none,
            context.logger,
            zoom: context.zoom,
            zoomScaleFactor: 1.0,
            hasImage: (_) => false);

        final text = symbolLayout.text?.text.evaluate(evaluationContext);
        if (text == null || text.isEmpty) {
          continue;
        }
        final fontFamily = symbolLayout.text?.fontFamily ?? 'Roboto Regular';
        await atlasGenerator.loadAtlas(text, fontFamily);
      }
    }
  }
}

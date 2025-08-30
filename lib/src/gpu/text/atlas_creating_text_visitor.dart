import '../../../vector_tile_renderer.dart';
import '../../themes/expression/expression.dart';
import '../../themes/feature_resolver.dart';
import '../../themes/style.dart';
import 'sdf/sdf_atlas_manager.dart';

class AtlasCreatingTextVisitor extends LayerVisitorAsync {
  final SdfAtlasManager atlasManager;
  final Theme theme;

  AtlasCreatingTextVisitor(this.atlasManager, this.theme);

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
        await atlasManager.loadAtlas(text, fontFamily);
      }
    }
  }
}

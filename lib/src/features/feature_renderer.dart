import '../context.dart';
import '../logger.dart';
import '../model/tile_model.dart';
import '../themes/style.dart';
import '../themes/theme.dart';
import 'line_renderer.dart';
import 'polygon_renderer.dart';
import 'symbol_line_renderer.dart';
import 'symbol_point_renderer.dart';

abstract class FeatureRenderer {
  void render(Context context, ThemeLayerType layerType, Style style,
      TileLayer layer, TileFeature feature);
}

class FeatureDispatcher extends FeatureRenderer {
  final Logger logger;
  final Map<TileFeatureType, FeatureRenderer> typeToRenderer;
  final Map<TileFeatureType, FeatureRenderer> symbolTypeToRenderer;

  FeatureDispatcher(this.logger)
      : typeToRenderer = createDispatchMapping(logger),
        symbolTypeToRenderer = createSymbolDispatchMapping(logger);

  void render(Context context, ThemeLayerType layerType, Style style,
      TileLayer layer, TileFeature feature) {
    final rendererMapping = layerType == ThemeLayerType.symbol
        ? symbolTypeToRenderer
        : typeToRenderer;
    final delegate = rendererMapping[feature.type];
    if (delegate == null) {
      logger.warn(() =>
          'layer type $layerType feature ${feature.type} is not implemented');
    } else {
      delegate.render(context, layerType, style, layer, feature);
    }
  }

  static Map<TileFeatureType, FeatureRenderer> createDispatchMapping(
      Logger logger) {
    return {
      TileFeatureType.polygon: PolygonRenderer(logger),
      TileFeatureType.linestring: LineRenderer(logger),
    };
  }

  static Map<TileFeatureType, FeatureRenderer> createSymbolDispatchMapping(
      Logger logger) {
    return {
      TileFeatureType.point: SymbolPointRenderer(logger),
      TileFeatureType.linestring: SymbolLineRenderer(logger)
    };
  }
}

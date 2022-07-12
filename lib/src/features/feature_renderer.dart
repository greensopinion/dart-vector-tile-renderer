import '../context.dart';
import '../logger.dart';
import '../model/tile_model.dart';
import '../themes/style.dart';
import '../themes/theme.dart';
import 'fill_renderer.dart';
import 'line_renderer.dart';
import 'symbol_line_renderer.dart';
import 'symbol_point_renderer.dart';

abstract class FeatureRenderer {
  void render(
    Context context,
    ThemeLayerType layerType,
    Style style,
    TileLayer layer,
    TileFeature feature,
  );
}

class FeatureDispatcher extends FeatureRenderer {
  final Logger logger;
  final Map<ThemeLayerType, FeatureRenderer> typeToRenderer;
  final Map<TileFeatureType, FeatureRenderer> symbolTypeToRenderer;

  FeatureDispatcher(this.logger)
      : typeToRenderer = createDispatchMapping(logger),
        symbolTypeToRenderer = createSymbolDispatchMapping(logger);

  @override
  void render(
    Context context,
    ThemeLayerType layerType,
    Style style,
    TileLayer layer,
    TileFeature feature,
  ) {
    FeatureRenderer? delegate;
    if (layerType == ThemeLayerType.symbol) {
      delegate = symbolTypeToRenderer[feature.type];
    } else {
      delegate = typeToRenderer[layerType];
    }

    if (delegate == null) {
      logger.warn(() =>
          'layer type $layerType feature ${feature.type} is not implemented');
    } else {
      delegate.render(context, layerType, style, layer, feature);
    }
  }

  static Map<ThemeLayerType, FeatureRenderer> createDispatchMapping(
      Logger logger) {
    return {
      ThemeLayerType.fill: FillRenderer(logger),
      ThemeLayerType.fill_extrusion: FillRenderer(logger),
      ThemeLayerType.line: LineRenderer(logger),
    };
  }

  static Map<TileFeatureType, FeatureRenderer> createSymbolDispatchMapping(
      Logger logger) {
    return {
      TileFeatureType.point: SymbolPointRenderer(logger),
      TileFeatureType.linestring: SymbolLineRenderer(logger),
    };
  }
}

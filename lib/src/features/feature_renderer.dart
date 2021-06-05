import 'package:vector_tile/vector_tile.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../context.dart';
import 'symbol_line_renderer.dart';
import 'symbol_point_renderer.dart';
import 'polygon_renderer.dart';
import 'line_renderer.dart';
import '../logger.dart';
import '../themes/style.dart';

abstract class FeatureRenderer {
  void render(Context context, ThemeLayerType layerType, Style style,
      VectorTileLayer layer, VectorTileFeature feature);
}

class FeatureDispatcher extends FeatureRenderer {
  final Logger logger;
  final Map<VectorTileGeomType, FeatureRenderer> typeToRenderer;
  final Map<VectorTileGeomType, FeatureRenderer> symbolTypeToRenderer;

  FeatureDispatcher(this.logger)
      : typeToRenderer = createDispatchMapping(logger),
        symbolTypeToRenderer = createSymbolDispatchMapping(logger);

  void render(Context context, ThemeLayerType layerType, Style style,
      VectorTileLayer layer, VectorTileFeature feature) {
    final type = feature.type;
    if (type != null) {
      final rendererMapping = layerType == ThemeLayerType.symbol
          ? symbolTypeToRenderer
          : typeToRenderer;
      final delegate = rendererMapping[type];
      if (delegate == null) {
        logger.warn(
            () => 'layer type $layerType feature $type is not implemented');
      } else {
        delegate.render(context, layerType, style, layer, feature);
      }
    }
  }

  static Map<VectorTileGeomType, FeatureRenderer> createDispatchMapping(
      Logger logger) {
    return {
      VectorTileGeomType.POLYGON: PolygonRenderer(logger),
      VectorTileGeomType.LINESTRING: LineRenderer(logger),
    };
  }

  static Map<VectorTileGeomType, FeatureRenderer> createSymbolDispatchMapping(
      Logger logger) {
    return {
      VectorTileGeomType.POINT: SymbolPointRenderer(logger),
      VectorTileGeomType.LINESTRING: SymbolLineRenderer(logger)
    };
  }
}

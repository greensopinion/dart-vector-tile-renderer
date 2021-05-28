import 'dart:ui';

import 'package:tile_inator/tile_inator.dart';

import 'package:vector_tile/vector_tile.dart';

import 'logger.dart';

class Renderer {
  final LayerFilter layerFilter;
  final Logger logger;

  Renderer({required this.layerFilter, Logger? logger})
      : this.logger = logger ?? Logger.noop();

  void render(Canvas canvas, VectorTile tile) {
    _filteredLayers(tile).forEach((layer) {
      _renderLayer(canvas, layer);
    });
  }

  void _renderLayer(Canvas canvas, VectorTileLayer layer) {
    logger.log(() => 'rendering layer ${layer.name}');
  }

  Iterable<VectorTileLayer> _filteredLayers(VectorTile tile) =>
      tile.layers.where((layer) {
        final matches = layerFilter.matches(layer);
        if (!matches) {
          logger.log(() => 'skipping layer ${layer.name}');
        }
        return matches;
      });
}

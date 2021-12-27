import 'package:vector_tile/vector_tile.dart';

import 'themes/theme.dart';
import 'themes/theme_layers.dart';

/// A tileset is a collection of vector tiles by `'source'` ID,
/// as defined by the theme
class Tileset {
  final bool preprocessed;
  final Map<String, VectorTile> tiles;

  Tileset(this.tiles) : this.preprocessed = false;

  Tileset._preprocessed(Tileset original)
      : this.tiles = original.tiles,
        this.preprocessed = true;

  VectorTile? tile(String sourceId) => tiles[sourceId];
}

/// A pre-processor for [Tileset]s. A pre-processing is an optional step
/// that can reduce CPU overhead during rendering at the cost of higher memory
/// usage.
class TilesetPreprocessor {
  final Theme theme;

  TilesetPreprocessor(this.theme);

  /// Pre-processes a tileset to eliminate some expensive processing from
  /// the rendering stage.
  ///
  /// returns a pre-processed tileset
  Tileset preprocess(Tileset tileset) {
    theme.layers.whereType<DefaultLayer>().forEach((themeLayer) {
      themeLayer.selector.select(tileset).forEach((layer) {
        themeLayer.selector.layerSelector
            .features(layer.features)
            .forEach((feature) {
          feature.decodeGeometry();
        });
      });
    });
    return Tileset._preprocessed(tileset);
  }
}

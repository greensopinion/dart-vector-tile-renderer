import 'model/tile_model.dart';
import 'profiling.dart';
import 'themes/feature_resolver.dart';
import 'themes/theme.dart';
import 'themes/theme_layers.dart';

/// A tileset is a collection of vector tiles by `'source'` ID,
/// as defined by the theme
class Tileset {
  final bool preprocessed;
  final Map<String, Tile> tiles;
  late final LayerFeatureResolver _resolver;

  Tileset(this.tiles) : this.preprocessed = false {
    _resolver = DefaultLayerFeatureResolver(this);
  }

  Tileset._preprocessed(Tileset original, this._resolver)
      : this.tiles = original.tiles,
        this.preprocessed = true;

  Tile? tile(String sourceId) => tiles[sourceId];
}

extension InternalTileset on Tileset {
  LayerFeatureResolver get resolver => _resolver;
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
  /// [zoom] the zoom level at which the tileset should be preprocessed. The
  ///        zoom level may be referenced by expressions in the theme, for example
  ///        as a layer filter.
  ///
  /// Returns a pre-processed tileset.
  Tileset preprocess(Tileset tileset, {required double zoom}) {
    return profileSync('PreprocessTileset', () {
      final featureResolver = tileset.resolver is CachingLayerFeatureResolver
          ? tileset.resolver
          : CachingLayerFeatureResolver(tileset.resolver);

      for (final themeLayer in theme.layers.whereType<DefaultLayer>()) {
        featureResolver.resolveFeatures(themeLayer.selector, zoom.truncate());
      }
      return Tileset._preprocessed(tileset, featureResolver);
    });
  }
}

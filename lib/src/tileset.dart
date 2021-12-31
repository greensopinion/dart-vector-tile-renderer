import 'package:vector_tile/vector_tile.dart';

import 'themes/feature_resolver.dart';
import 'themes/theme.dart';
import 'themes/theme_layers.dart';

/// A tileset is a collection of vector tiles by `'source'` ID,
/// as defined by the theme
class Tileset {
  final bool preprocessed;
  final Map<String, VectorTile> tiles;
  late final ThemeLayerFeatureResolver themeLayerFeatureResolver;

  Tileset(this.tiles) : this.preprocessed = false {
    themeLayerFeatureResolver = DefaultThemeLayerFeatureResolver(this);
  }

  Tileset._preprocessed(
    Tileset original,
    ThemeLayerFeatureResolver themeLayerFeatureResolver,
  )   : this.tiles = original.tiles,
        this.themeLayerFeatureResolver = themeLayerFeatureResolver,
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
  /// The [themeLayerFeatures] options controls whether for each theme layer,
  /// the features it will render are pre-processed.
  ///
  /// Returns a pre-processed tileset.
  Tileset preprocess(Tileset tileset, {bool themeLayerFeatures = true}) {
    final themeLayerFeatureResolver = themeLayerFeatures
        ? CachingThemeLayerFeatureResolver(tileset.themeLayerFeatureResolver)
        : tileset.themeLayerFeatureResolver;

    for (final themeLayer in theme.layers.whereType<DefaultLayer>()) {
      for (final feature
          in themeLayerFeatureResolver.resolveFeatures(themeLayer)) {
        feature.feature.decodeGeometry();
      }
    }

    return Tileset._preprocessed(tileset, themeLayerFeatureResolver);
  }
}

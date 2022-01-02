import 'dart:developer';

import 'package:vector_tile/vector_tile.dart';

import 'profiling.dart';
import 'themes/feature_resolver.dart';
import 'themes/theme.dart';
import 'themes/theme_layers.dart';

/// A tileset is a collection of vector tiles by `'source'` ID,
/// as defined by the theme
class Tileset {
  final bool preprocessed;
  final Map<String, VectorTile> tiles;
  late final LayerFeatureResolver _resolver;

  Tileset(this.tiles) : this.preprocessed = false {
    _resolver = DefaultLayerFeatureResolver(this);
  }

  Tileset._preprocessed(Tileset original, this._resolver)
      : this.tiles = original.tiles,
        this.preprocessed = true;

  VectorTile? tile(String sourceId) => tiles[sourceId];
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
  /// Returns a pre-processed tileset.
  Tileset preprocess(Tileset tileset) {
    return Timeline.timeSync('$timelinePrefix::PreprocessTileset', () {
      final featureResolver = tileset.resolver is CachingLayerFeatureResolver
          ? tileset.resolver
          : CachingLayerFeatureResolver(tileset.resolver);

      for (final themeLayer in theme.layers.whereType<DefaultLayer>()) {
        for (final feature
            in featureResolver.resolveFeatures(themeLayer.selector)) {
          feature.feature.decodeGeometry();
        }
      }

      return Tileset._preprocessed(tileset, featureResolver);
    });
  }
}

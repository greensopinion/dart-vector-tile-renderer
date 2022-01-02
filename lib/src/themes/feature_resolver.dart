import 'package:vector_tile_renderer/src/themes/selector.dart';

import '../../vector_tile_renderer.dart';

/// Resolver for resolving the features, that are selected by a
/// [TileLayerSelector].
abstract class LayerFeatureResolver {
  /// Resolves and returns the features that the given [selector] selects.
  Iterable<LayerFeature> resolveFeatures(TileLayerSelector selector);
}

/// Default implementation of [LayerFeatureResolver] that resolves
/// features from a [tileset].
class DefaultThemeLayerFeatureResolver implements LayerFeatureResolver {
  DefaultThemeLayerFeatureResolver(this.tileset);

  /// The [Tileset] from which to resolves features.
  final Tileset tileset;

  @override
  Iterable<LayerFeature> resolveFeatures(TileLayerSelector selector) sync* {
    for (final layer in selector.select(tileset)) {
      for (final feature in selector.layerSelector.features(layer.features)) {
        yield LayerFeature(layer, feature);
      }
    }
  }
}

/// A [LayerFeatureResolver] that uses another resolver and caches its results.
class CachingThemeLayerFeatureResolver implements LayerFeatureResolver {
  CachingThemeLayerFeatureResolver(this._resolver);

  final LayerFeatureResolver _resolver;

  final _cache = <TileLayerSelector, List<LayerFeature>>{};

  @override
  Iterable<LayerFeature> resolveFeatures(TileLayerSelector selector) {
    return _cache.putIfAbsent(
      selector,
      () => _resolver.resolveFeatures(selector).toList(),
    );
  }
}

class LayerFeature {
  LayerFeature(this.layer, this.feature);

  final VectorTileLayer layer;
  final VectorTileFeature feature;
}

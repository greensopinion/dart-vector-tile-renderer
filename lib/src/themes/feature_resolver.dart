import 'package:vector_tile_renderer/src/themes/selector.dart';

import '../../vector_tile_renderer.dart';

/// Resolver for resolving the features, that are selected by a
/// [TileLayerSelector].
abstract class LayerFeatureResolver {
  /// Provides the features resolved using the given [selector].
  Iterable<LayerFeature> resolveFeatures(TileLayerSelector selector);
}

/// Default implementation of [LayerFeatureResolver] that resolves
/// features from a [tileset].
class DefaultLayerFeatureResolver implements LayerFeatureResolver {
  DefaultLayerFeatureResolver(this._tileset);

  final Tileset _tileset;

  @override
  Iterable<LayerFeature> resolveFeatures(TileLayerSelector selector) sync* {
    for (final layer in selector.select(_tileset)) {
      for (final feature in selector.layerSelector.features(layer.features)) {
        yield LayerFeature(layer, feature);
      }
    }
  }
}

/// A [LayerFeatureResolver] that uses another resolver and caches its results.
class CachingLayerFeatureResolver implements LayerFeatureResolver {
  CachingLayerFeatureResolver(this._delegate);

  final LayerFeatureResolver _delegate;

  final _cache = <TileLayerSelector, List<LayerFeature>>{};

  @override
  Iterable<LayerFeature> resolveFeatures(TileLayerSelector selector) {
    return _cache.putIfAbsent(
      selector,
      () => _delegate.resolveFeatures(selector).toList(),
    );
  }
}

class LayerFeature {
  LayerFeature(this.layer, this.feature);

  final VectorTileLayer layer;
  final VectorTileFeature feature;
}

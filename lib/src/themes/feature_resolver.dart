import '../model/tile_model.dart';
import '../tileset.dart';
import 'selector.dart';

/// Resolver for resolving the features, that are selected by a
/// [TileLayerSelector].
abstract class LayerFeatureResolver {
  /// Provides the features resolved using the given [selector].
  Iterable<LayerFeature> resolveFeatures(TileLayerSelector selector, int zoom);
}

/// Default implementation of [LayerFeatureResolver] that resolves
/// features from a [tileset].
class DefaultLayerFeatureResolver implements LayerFeatureResolver {
  DefaultLayerFeatureResolver(this._tileset);

  final Tileset _tileset;

  @override
  Iterable<LayerFeature> resolveFeatures(
      TileLayerSelector selector, int zoom) sync* {
    for (final layer in selector.select(_tileset, zoom)) {
      for (final feature
          in selector.layerSelector.features(layer.features, zoom)) {
        yield LayerFeature(layer, feature);
      }
    }
  }
}

/// A [LayerFeatureResolver] that uses another resolver and caches its results.
class CachingLayerFeatureResolver implements LayerFeatureResolver {
  CachingLayerFeatureResolver(this._delegate);

  final LayerFeatureResolver _delegate;

  final _cache = <String, List<LayerFeature>>{};

  @override
  Iterable<LayerFeature> resolveFeatures(TileLayerSelector selector, int zoom) {
    return _cache.putIfAbsent(
      "$zoom:${selector.cacheKey}",
      () => _delegate.resolveFeatures(selector, zoom).toList(growable: false),
    );
  }
}

class LayerFeature {
  LayerFeature(this.layer, this.feature);

  final TileLayer layer;
  final TileFeature feature;
}

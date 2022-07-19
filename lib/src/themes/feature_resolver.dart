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
  final LayerFeatureResolver _delegate;
  final _cacheByZoom = <Map<String, List<LayerFeature>>?>[];

  CachingLayerFeatureResolver(this._delegate) {
    for (int x = 0; x <= _maximumConceivableZoom; ++x) {
      _cacheByZoom.add(null);
    }
  }

  @override
  Iterable<LayerFeature> resolveFeatures(TileLayerSelector selector, int zoom) {
    final cache = _cache(zoom);
    return cache.putIfAbsent(
      selector.cacheKey,
      () {
        final minZoom = selector.layerSelector.minZoom();
        final maxZoom = selector.layerSelector.maxZoom();
        final checkZoom = minZoom ?? maxZoom ?? 0;
        if (checkZoom != zoom) {
          return resolveFeatures(selector, checkZoom).toList(growable: false);
        }
        return _delegate
            .resolveFeatures(selector, zoom)
            .toList(growable: false);
      },
    );
  }

  Map<String, List<LayerFeature>> _cache(int zoom) {
    var cache = _cacheByZoom[zoom];
    if (cache == null) {
      cache = {};
      _cacheByZoom[zoom] = cache;
    }
    return cache;
  }
}

class LayerFeature {
  LayerFeature(this.layer, this.feature);

  final TileLayer layer;
  final TileFeature feature;
}

const _maximumConceivableZoom = 25;

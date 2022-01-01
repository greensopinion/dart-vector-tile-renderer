import 'package:vector_tile_renderer/src/themes/selector.dart';

import '../../vector_tile_renderer.dart';

/// Resolver for resolving the [LayerFeature]s, that a [ThemeLayer] should
/// render.
abstract class ThemeLayerFeatureResolver {
  /// Resolves and returns the [LayerFeature]s that the given [selector]
  /// selects for a [ThemeLayer].
  Iterable<LayerFeature> resolveFeatures(TileLayerSelector selector);
}

/// Default implementation of [ThemeLayerFeatureResolver] that resolves the
/// features contained in a specific [tileset] for a [ThemeLayer].
class DefaultThemeLayerFeatureResolver implements ThemeLayerFeatureResolver {
  DefaultThemeLayerFeatureResolver(this.tileset);

  /// The [Tileset] from which to resolves [LayerFeature]s.
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

/// A [ThemeLayerFeatureResolver] that uses another [resolver] and caches
/// its results.
class CachingThemeLayerFeatureResolver implements ThemeLayerFeatureResolver {
  CachingThemeLayerFeatureResolver(this.resolver);

  /// The resolver whose results will be cached.
  final ThemeLayerFeatureResolver resolver;

  final _cache = <TileLayerSelector, List<LayerFeature>>{};

  @override
  Iterable<LayerFeature> resolveFeatures(TileLayerSelector selector) {
    return _cache.putIfAbsent(
      selector,
      () => resolver.resolveFeatures(selector).toList(),
    );
  }
}

/// A feature that is rendered by a [ThemeLayer].
class LayerFeature {
  LayerFeature(this.layer, this.feature);

  final VectorTileLayer layer;
  final VectorTileFeature feature;
}

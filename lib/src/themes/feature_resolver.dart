import '../../vector_tile_renderer.dart';
import 'theme_layers.dart';

/// Resolver for resolving the [VectorTileFeature]s a [ThemeLayer] should
/// render.
abstract class ThemeLayerFeatureResolver {
  /// Resolves and returns the [VectorTileFeature]s that the given [themeLayer]
  /// should render.
  Iterable<ResolvedThemeLayerFeature> resolveFeatures(DefaultLayer themeLayer);
}

/// Default implementation of [ThemeLayerFeatureResolver] that resolves the
/// features contained in a specific [tileset] for a [ThemeLayer].
class DefaultThemeLayerFeatureResolver implements ThemeLayerFeatureResolver {
  DefaultThemeLayerFeatureResolver(this.tileset);

  /// The [Tileset] from which to resolves [VectorTileFeature]s.
  final Tileset tileset;

  @override
  Iterable<ResolvedThemeLayerFeature> resolveFeatures(
    DefaultLayer themeLayer,
  ) sync* {
    for (final layer in themeLayer.selector.select(tileset)) {
      for (final feature
          in themeLayer.selector.layerSelector.features(layer.features)) {
        yield ResolvedThemeLayerFeature(layer, feature);
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

  final _cache = <DefaultLayer, List<ResolvedThemeLayerFeature>>{};

  @override
  Iterable<ResolvedThemeLayerFeature> resolveFeatures(DefaultLayer themeLayer) {
    return _cache.putIfAbsent(
      themeLayer,
      () => resolver.resolveFeatures(themeLayer).toList(),
    );
  }
}

/// Wrapper around [VectorTileFeature] that includes the containing
/// [VectorTileLayer].
class ResolvedThemeLayerFeature {
  ResolvedThemeLayerFeature(this.layer, this.feature);

  final VectorTileLayer layer;
  final VectorTileFeature feature;
}

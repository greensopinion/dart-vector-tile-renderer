import '../logger.dart';
import '../model/tile_model.dart';
import '../tileset.dart';
import 'expression/expression.dart';

class TileLayerSelector {
  final TileSelector tileSelector;
  final LayerSelector layerSelector;
  late final String cacheKey;

  TileLayerSelector(this.tileSelector, this.layerSelector) {
    cacheKey = '${tileSelector.cacheKey}/${layerSelector.cacheKey}';
  }

  Iterable<TileLayer> select(Tileset tileset, int zoom) {
    final tile = tileSelector.select(tileset);
    return tile == null ? [] : layerSelector.select(tile.layers, zoom);
  }
}

class TileSelector {
  final String source;

  String get cacheKey => source;
  TileSelector(this.source);

  factory TileSelector.none() = _NoneTileSelector;

  Tile? select(Tileset tileset) => tileset.tile(source);
}

abstract class LayerSelector {
  final String cacheKey;
  LayerSelector._(this.cacheKey);

  factory LayerSelector.none() = _NoneLayerSelector;
  factory LayerSelector.composite(List<LayerSelector> selectors) =
      _CompositeSelector;
  factory LayerSelector.named(String name) = _NamedLayerSelector;

  factory LayerSelector.expression(Expression expression) =>
      _ExpressionLayerSelector(expression);

  Iterable<TileLayer> select(Iterable<TileLayer> tileLayers, int zoom);

  Iterable<TileFeature> features(Iterable<TileFeature> features, int zoom);

  Set<String> propertyNames();
  Set<String> layerNames();
}

class _CompositeSelector extends LayerSelector {
  final List<LayerSelector> delegates;

  _CompositeSelector(this.delegates)
      : super._(delegates.map((e) => e.cacheKey).join(','));

  @override
  Iterable<TileLayer> select(Iterable<TileLayer> tileLayers, int zoom) {
    Iterable<TileLayer> result = tileLayers;
    delegates.forEach((delegate) {
      result = delegate.select(result, zoom);
    });
    return result;
  }

  @override
  Iterable<TileFeature> features(Iterable<TileFeature> features, int zoom) {
    Iterable<TileFeature> result = features;
    delegates.forEach((delegate) {
      result = delegate.features(result, zoom);
    });
    return result;
  }

  @override
  Set<String> propertyNames() {
    final names = <String>{};
    for (final delegate in delegates) {
      names.addAll(delegate.propertyNames());
    }
    return names;
  }

  @override
  Set<String> layerNames() {
    final names = <String>{};
    for (final delegate in delegates) {
      names.addAll(delegate.layerNames());
    }
    return names;
  }
}

class _NamedLayerSelector extends LayerSelector {
  final String name;
  _NamedLayerSelector(this.name) : super._('named($name)');

  @override
  Iterable<TileLayer> select(Iterable<TileLayer> tileLayers, int zoom) =>
      tileLayers.where((layer) => layer.name == name);

  @override
  Iterable<TileFeature> features(Iterable<TileFeature> features, int zoom) =>
      features;

  @override
  Set<String> propertyNames() => {};

  @override
  Set<String> layerNames() => {name};
}

class _ExpressionLayerSelector extends LayerSelector {
  final Expression _expression;

  _ExpressionLayerSelector(this._expression)
      : super._('matching(${_expression.cacheKey})');

  @override
  Iterable<TileFeature> features(Iterable<TileFeature> features, int zoom) {
    return features.where((feature) {
      final context = EvaluationContext(() => feature.properties, feature.type,
          zoom.toDouble(), Logger.noop());
      final result = _expression.evaluate(context);
      return result is bool && result;
    });
  }

  @override
  Iterable<TileLayer> select(Iterable<TileLayer> tileLayers, int zoom) =>
      tileLayers;

  @override
  Set<String> propertyNames() => _expression.properties();

  @override
  Set<String> layerNames() => {};
}

class _NoneLayerSelector extends LayerSelector {
  _NoneLayerSelector() : super._('none');

  @override
  Iterable<TileFeature> features(Iterable<TileFeature> features, int zoom) =>
      [];

  @override
  Iterable<TileLayer> select(Iterable<TileLayer> tileLayers, int zoom) => [];

  @override
  Set<String> propertyNames() => {};

  @override
  Set<String> layerNames() => {};
}

class _NoneTileSelector extends TileSelector {
  _NoneTileSelector() : super('none');
}

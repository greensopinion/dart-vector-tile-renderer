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

  Iterable<TileLayer> select(Tileset tileset) {
    final tile = tileSelector.select(tileset);
    return tile == null ? [] : layerSelector.select(tile.layers);
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

  Iterable<TileLayer> select(Iterable<TileLayer> tileLayers);

  Iterable<TileFeature> features(Iterable<TileFeature> features);

  Set<String> propertyNames();
  Set<String> layerNames();
}

class _CompositeSelector extends LayerSelector {
  final List<LayerSelector> delegates;

  _CompositeSelector(this.delegates)
      : super._(delegates.map((e) => e.cacheKey).join(','));

  @override
  Iterable<TileLayer> select(Iterable<TileLayer> tileLayers) {
    Iterable<TileLayer> result = tileLayers;
    delegates.forEach((delegate) {
      result = delegate.select(result);
    });
    return result;
  }

  Iterable<TileFeature> features(Iterable<TileFeature> features) {
    Iterable<TileFeature> result = features;
    delegates.forEach((delegate) {
      result = delegate.features(result);
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
  Iterable<TileLayer> select(Iterable<TileLayer> tileLayers) =>
      tileLayers.where((layer) => layer.name == name);

  Iterable<TileFeature> features(Iterable<TileFeature> features) => features;

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
  Iterable<TileFeature> features(Iterable<TileFeature> features) {
    return features.where((feature) {
      final context = EvaluationContext(
          () => feature.properties, feature.type, 1.0, Logger.noop());
      final result = _expression.evaluate(context);
      return result is bool && result;
    });
  }

  @override
  Iterable<TileLayer> select(Iterable<TileLayer> tileLayers) => tileLayers;

  @override
  Set<String> propertyNames() => _expression.properties();

  @override
  Set<String> layerNames() => {};
}

class _NoneLayerSelector extends LayerSelector {
  _NoneLayerSelector() : super._('none');

  @override
  Iterable<TileFeature> features(Iterable<TileFeature> features) => [];

  @override
  Iterable<TileLayer> select(Iterable<TileLayer> tileLayers) => [];

  @override
  Set<String> propertyNames() => {};

  @override
  Set<String> layerNames() => {};
}

class _NoneTileSelector extends TileSelector {
  _NoneTileSelector() : super('none');
}

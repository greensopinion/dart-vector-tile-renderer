import 'package:vector_tile_renderer/src/themes/expression/expression.dart';

import '../../vector_tile_renderer.dart';

class TileLayerSelector {
  final TileSelector tileSelector;
  final LayerSelector layerSelector;

  TileLayerSelector(this.tileSelector, this.layerSelector);

  Iterable<VectorTileLayer> select(Tileset tileset) {
    final tile = tileSelector.select(tileset);
    return tile == null ? [] : layerSelector.select(tile.layers);
  }
}

class TileSelector {
  final String source;

  TileSelector(this.source);

  factory TileSelector.none() = _NoneTileSelector;

  VectorTile? select(Tileset tileset) => tileset.tile(source);
}

abstract class LayerSelector {
  LayerSelector._();

  factory LayerSelector.none() = _NoneLayerSelector;
  factory LayerSelector.composite(List<LayerSelector> selectors) =
      _CompositeSelector;
  factory LayerSelector.named(String name) = _NamedLayerSelector;

  factory LayerSelector.expression(Expression expression) =>
      _ExpressionLayerSelector(expression);

  Iterable<VectorTileLayer> select(Iterable<VectorTileLayer> tileLayers);

  Iterable<VectorTileFeature> features(Iterable<VectorTileFeature> features);
}

class _CompositeSelector extends LayerSelector {
  final List<LayerSelector> delegates;
  _CompositeSelector(this.delegates) : super._();

  @override
  Iterable<VectorTileLayer> select(Iterable<VectorTileLayer> tileLayers) {
    Iterable<VectorTileLayer> result = tileLayers;
    delegates.forEach((delegate) {
      result = delegate.select(result);
    });
    return result;
  }

  Iterable<VectorTileFeature> features(Iterable<VectorTileFeature> features) {
    Iterable<VectorTileFeature> result = features;
    delegates.forEach((delegate) {
      result = delegate.features(result);
    });
    return result;
  }
}

class _NamedLayerSelector extends LayerSelector {
  final String name;
  _NamedLayerSelector(this.name) : super._();

  @override
  Iterable<VectorTileLayer> select(Iterable<VectorTileLayer> tileLayers) =>
      tileLayers.where((layer) => layer.name == name);

  Iterable<VectorTileFeature> features(Iterable<VectorTileFeature> features) =>
      features;
}

class _ExpressionLayerSelector extends LayerSelector {
  final Expression _expression;

  _ExpressionLayerSelector(this._expression) : super._();

  @override
  Iterable<VectorTileFeature> features(Iterable<VectorTileFeature> features) {
    return features.where((feature) {
      final context = EvaluationContext(
          () => feature.decodeProperties(), () => feature.type, Logger.noop());
      final result = _expression.evaluate(context);
      return result is bool && result;
    });
  }

  @override
  Iterable<VectorTileLayer> select(Iterable<VectorTileLayer> tileLayers) =>
      tileLayers;
}

class _NoneLayerSelector extends LayerSelector {
  _NoneLayerSelector() : super._();

  @override
  Iterable<VectorTileFeature> features(Iterable<VectorTileFeature> features) =>
      [];

  @override
  Iterable<VectorTileLayer> select(Iterable<VectorTileLayer> tileLayers) => [];
}

class _NoneTileSelector extends TileSelector {
  _NoneTileSelector() : super('none');
}

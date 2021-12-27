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
  factory LayerSelector.any(List<LayerSelector> selectors) =
      _AnyCompositeSelector;
  factory LayerSelector.named(String name) = _NamedLayerSelector;
  factory LayerSelector.withProperty(String name,
      {required List<dynamic> values,
      required bool negated}) = _PropertyLayerSelector;
  factory LayerSelector.hasProperty(String name, {required bool negated}) =
      _HasPropertyLayerSelector;
  factory LayerSelector.comparingProperty(
          String name, ComparisonOperator op, num value) =
      _NumericComparisonLayerSelector;

  Iterable<VectorTileLayer> select(Iterable<VectorTileLayer> tileLayers);

  Iterable<VectorTileFeature> features(Iterable<VectorTileFeature> features);
}

enum ComparisonOperator {
  GREATER_THAN_OR_EQUAL_TO,
  LESS_THAN_OR_EQUAL_TO,
  GREATER_THAN,
  LESS_THAN
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

class _AnyCompositeSelector extends LayerSelector {
  final List<LayerSelector> delegates;
  _AnyCompositeSelector(this.delegates) : super._();

  @override
  Iterable<VectorTileLayer> select(Iterable<VectorTileLayer> tileLayers) {
    final Set<VectorTileLayer> selected = Set();
    for (final delegate in delegates) {
      selected.addAll(delegate.select(tileLayers));
    }
    return tileLayers.where((layer) => selected.contains(layer));
  }

  Iterable<VectorTileFeature> features(Iterable<VectorTileFeature> features) {
    final Set<VectorTileFeature> selected = Set();
    for (final delegate in delegates) {
      selected.addAll(delegate.features(features));
    }
    return features.where((layer) => selected.contains(layer));
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

class _HasPropertyLayerSelector extends LayerSelector {
  final String name;
  final bool negated;
  _HasPropertyLayerSelector(this.name, {required this.negated}) : super._();

  @override
  Iterable<VectorTileLayer> select(Iterable<VectorTileLayer> tileLayers) =>
      tileLayers;

  @override
  Iterable<VectorTileFeature> features(Iterable<VectorTileFeature> features) {
    return features.where((feature) {
      final properties = feature.decodeProperties();
      final hasProperty = properties.any((map) => map.keys.contains(name));
      return negated ? !hasProperty : hasProperty;
    });
  }
}

class _NumericComparisonLayerSelector extends LayerSelector {
  final String name;
  final ComparisonOperator op;
  final num value;
  _NumericComparisonLayerSelector(this.name, this.op, this.value) : super._() {
    if (name.startsWith('\$')) {
      throw Exception('Unsupported comparison property $name');
    }
  }

  @override
  Iterable<VectorTileFeature> features(Iterable<VectorTileFeature> features) {
    return features.where((feature) {
      final properties = feature.decodeProperties();
      return properties.any((map) => _matches(map[name]));
    });
  }

  @override
  Iterable<VectorTileLayer> select(Iterable<VectorTileLayer> tileLayers) =>
      tileLayers;

  _matches(VectorTileValue? value) {
    final v = value?.dartIntValue?.toInt() ?? value?.dartDoubleValue;
    if (v == null) {
      return false;
    }
    switch (op) {
      case ComparisonOperator.GREATER_THAN_OR_EQUAL_TO:
        return v >= this.value;
      case ComparisonOperator.LESS_THAN_OR_EQUAL_TO:
        return v >= this.value;
      case ComparisonOperator.LESS_THAN:
        return v < this.value;
      case ComparisonOperator.GREATER_THAN:
        return v > this.value;
    }
  }
}

class _PropertyLayerSelector extends LayerSelector {
  final String name;
  final List<dynamic> values;
  final bool negated;
  _PropertyLayerSelector(this.name,
      {required this.values, required this.negated})
      : super._();

  @override
  Iterable<VectorTileLayer> select(Iterable<VectorTileLayer> tileLayers) =>
      tileLayers;

  @override
  Iterable<VectorTileFeature> features(Iterable<VectorTileFeature> features) {
    return features.where((feature) {
      if (name == '\$type') {
        return _matchesType(feature);
      }
      final properties = feature.decodeProperties();
      final positiveMatch = properties.any((map) => _positiveMatch(map[name]));
      return negated ? !positiveMatch : positiveMatch;
    });
  }

  bool _matchesType(VectorTileFeature feature) {
    final typeName = _typeName(feature.type);
    return values.contains(typeName);
  }

  String _typeName(VectorTileGeomType? geometryType) {
    if (geometryType == null) {
      return '<none>';
    }
    switch (geometryType) {
      case VectorTileGeomType.POINT:
        return 'Point';
      case VectorTileGeomType.LINESTRING:
        return 'LineString';
      case VectorTileGeomType.POLYGON:
        return 'Polygon';
      case VectorTileGeomType.UNKNOWN:
        return '<unknown>';
    }
  }

  bool _positiveMatch(VectorTileValue? value) {
    if (value != null) {
      final v = value.dartStringValue ??
          value.dartIntValue?.toInt() ??
          value.dartDoubleValue ??
          value.dartBoolValue;
      return v == null ? false : values.contains(v);
    }
    return false;
  }
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

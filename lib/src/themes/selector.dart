import 'package:dart_vector_tile_renderer/renderer.dart';

abstract class LayerSelector {
  LayerSelector._();

  factory LayerSelector.none() = _NoneLayerSelector;
  factory LayerSelector.composite(List<LayerSelector> selectors) =
      _CompositeSelector;
  factory LayerSelector.named(String name) = _NamedLayerSelector;
  factory LayerSelector.withProperty(String name,
      {required List<dynamic> values,
      required bool negated}) = _PropertyLayerSelector;
  factory LayerSelector.hasProperty(String name, {required bool negated}) =
      _HasPropertyLayerSelector;

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
      return properties.any((map) => _matches(map[name]));
    });
  }

  bool _matchesType(VectorTileFeature feature) {
    final typeName = _typeName(feature.geometryType);
    return values.contains(typeName);
  }

  String _typeName(GeometryType? geometryType) {
    if (geometryType == null) {
      return '<none>';
    }
    switch (geometryType) {
      case GeometryType.Point:
        return 'Point';
      case GeometryType.LineString:
        return 'LineString';
      case GeometryType.Polygon:
        return 'Polygon';
      case GeometryType.MultiPoint:
        return 'MultiPoint';
      case GeometryType.MultiLineString:
        return 'MultiLineString';
      case GeometryType.MultiPolygon:
        return 'MultiPolygon';
    }
  }

  bool _matches(VectorTileValue? value) {
    if (value == null) {
      return negated ? true : false;
    }
    final v = value.dartStringValue ??
        value.dartIntValue?.toInt() ??
        value.dartDoubleValue ??
        value.dartBoolValue;
    final match = v == null ? false : values.contains(v);
    return negated ? !match : match;
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

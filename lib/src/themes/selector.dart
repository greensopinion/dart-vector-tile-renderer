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
      final properties = feature.decodeProperties();
      return properties.any((map) => _matches(map[name]));
    });
  }

  bool _matches(VectorTileValue? value) {
    if (value == null) {
      return false;
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

import 'package:tile_inator/tile_inator.dart';

abstract class LayerFilter {
  factory LayerFilter.named({required List<String> names}) =>
      _NamedLayerFilter(names.toSet());

  LayerFilter._();

  bool matches(VectorTileLayer layer);
}

class _NamedLayerFilter extends LayerFilter {
  final Set<String> _layerNames;

  _NamedLayerFilter(this._layerNames) : super._();

  @override
  bool matches(VectorTileLayer layer) =>
      _layerNames.any((name) => name == layer.name);
}

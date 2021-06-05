import '../context.dart';

class Theme {
  final List<ThemeLayer> layers;
  Theme(this.layers);

  Theme atZoom(double zoom) {
    return Theme(
        this.layers.where((layer) => _matchesZoom(zoom, layer)).toList());
  }

  bool _matchesZoom(double zoom, ThemeLayer layer) =>
      (zoom >= (layer.minzoom ?? -1)) && (zoom <= (layer.maxzoom ?? 100));
}

enum ThemeLayerType { fill, line, symbol, background, unsupported }

abstract class ThemeLayer {
  final String id;
  final ThemeLayerType type;
  final double? minzoom;
  final double? maxzoom;
  ThemeLayer(this.id, this.type,
      {required this.minzoom, required this.maxzoom});

  void render(Context context);
}

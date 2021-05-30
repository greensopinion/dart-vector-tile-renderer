import '../context.dart';

class Theme {
  final List<ThemeLayer> layers;
  Theme(this.layers);

  Theme atZoom(int zoom) {
    return Theme(
        this.layers.where((layer) => _matchesZoom(zoom, layer)).toList());
  }

  bool _matchesZoom(int zoom, ThemeLayer layer) =>
      (zoom >= (layer.minzoom ?? 0)) && (zoom <= (layer.maxzoom ?? 24));
}

abstract class ThemeLayer {
  final String id;
  final int? minzoom;
  final int? maxzoom;
  ThemeLayer(this.id, {required this.minzoom, required this.maxzoom});

  void render(Context context);
}

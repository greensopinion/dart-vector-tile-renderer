import '../context.dart';

class Theme {
  final List<ThemeLayer> layers;
  Theme(this.layers);

  Theme atZoom(double zoom) {
    return Theme(
        this.layers.where((layer) => _matchesZoom(zoom, layer)).toList());
  }

  bool _matchesZoom(double zoom, ThemeLayer layer) =>
      (zoom >= (layer.minzoom ?? double.negativeInfinity)) &&
      (zoom <= (layer.maxzoom ?? double.infinity));
}

abstract class ThemeLayer {
  final String id;
  final double? minzoom;
  final double? maxzoom;
  ThemeLayer(this.id, {required this.minzoom, required this.maxzoom});

  void render(Context context);
}

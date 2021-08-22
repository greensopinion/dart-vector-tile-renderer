import '../context.dart';

class Theme {
  /// the ID of the theme, which is used to identify the theme
  final String id;

  /// the version of the theme
  final String version;
  final List<ThemeLayer> layers;
  Theme({required this.id, required this.version, required this.layers});

  Theme atZoom(double zoom) {
    return Theme(
        id: this.id,
        version: this.version,
        layers:
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

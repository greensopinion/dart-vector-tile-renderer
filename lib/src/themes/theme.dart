import 'package:vector_math/vector_math.dart';

import '../../vector_tile_renderer.dart';
import '../context.dart';
import 'feature_resolver.dart';
import 'style.dart';
import 'theme_layer_raster.dart';

class Theme {
  /// the ID of the theme, which is used to identify the theme
  final String id;

  /// the version of the theme
  final String version;
  final List<ThemeLayer> layers;
  Theme({required this.id, required this.version, required this.layers});

  /// Provides a copy of this theme that only has layers that match
  /// the given [zoom].
  Theme atZoom(double zoom) => copyWith(atZoom: zoom);

  /// Creates a copy of this theme with the specified properties.
  /// If specified, the returned theme only includes layers of the given [types].
  /// If specified, the returned theme has the given [id].
  /// If specified, the returned theme has only layers matching the given [atZoom].
  Theme copyWith({Set<ThemeLayerType>? types, String? id, double? atZoom}) {
    return Theme(
        id: id ?? this.id,
        version: version,
        layers: layers
            .where((layer) => types?.contains(layer.type) ?? true)
            .where((layer) => atZoom == null || _matchesZoom(atZoom, layer))
            .toList(growable: false));
  }

  bool _matchesZoom(double zoom, ThemeLayer layer) =>
      (zoom >= (layer.minzoom ?? -1)) && (zoom <= (layer.maxzoom ?? 100));

  /// Provides the sources of all layers of this theme.
  Set<String> get tileSources =>
      layers.map((e) => e.tileSource).whereType<String>().toSet();
}

/// The type of theme layer
enum ThemeLayerType {
  fill,
  fillExtrusion,
  line,
  symbol,
  background,
  raster,
  unsupported
}

class VisitorContext {
  final Logger logger;
  final TileSource tileSource;
  final double zoom;
  final double pixelRatio;

  VisitorContext(
      {required this.logger,
      required this.tileSource,
      required this.zoom,
      required this.pixelRatio});
}

abstract class LayerVisitor {
  void visitFeatures(VisitorContext context, ThemeLayerType layerType,
      Style style, Iterable<LayerFeature> features) {}

  void visitBackground(VisitorContext context, Vector4 color) {}

  void visitRasterLayer(String key, RasterPaintModel paintModel) {}
}

/// Represents a layer in the theme. Can [render] to a [Context], and specifies
/// its [type].
abstract class ThemeLayer {
  final String id;
  final ThemeLayerType type;
  final double? minzoom;
  final double? maxzoom;
  final Map<String, dynamic> metadata;
  ThemeLayer(this.id, this.type,
      {required this.minzoom, required this.maxzoom, required this.metadata});

  String? get tileSource;

  void render(Context context);

  void accept(VisitorContext context, LayerVisitor visitor);
}

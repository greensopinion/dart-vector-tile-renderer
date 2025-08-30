import 'dart:typed_data';

import 'package:vector_math/vector_math.dart';

import '../../vector_tile_renderer.dart';
import '../themes/feature_resolver.dart';
import '../themes/style.dart';
import 'bucket_unpacker.dart';
import 'line/scene_line_builder.dart';
import 'polygon/scene_polygon_builder.dart';
import 'tile_render_data.dart';

class TilePreRenderer {
  Uint8List preRender(Theme theme, double zoom, Tileset tileset) {
    final data = TileRenderData();

    _PreRendererLayerVisitor(data, tileset, zoom).visitAllFeatures(theme);

    return data.pack();
  }
}

class _PreRendererLayerVisitor extends LayerVisitor {
  final TileRenderData tileRenderData;
  late final VisitorContext context;

  _PreRendererLayerVisitor(this.tileRenderData, Tileset tileset, double zoom) {
    context = VisitorContext(
        logger: const Logger.noop(),
        tileSource: TileSource(tileset: tileset),
        zoom: zoom);
  }

  void visitAllFeatures(Theme theme) {
    for (var layer in theme.layers) {
      layer.accept(context, this);
    }
  }

  @override
  void visitFeatures(VisitorContext context, ThemeLayerType layerType,
      Style style, Iterable<LayerFeature> features) {
    switch (layerType) {
      case ThemeLayerType.line:
        return SceneLineBuilder(tileRenderData, context)
            .addFeatures(style, features);
      case ThemeLayerType.fill:
      case ThemeLayerType.fillExtrusion:
        return ScenePolygonBuilder(tileRenderData, context)
            .addPolygons(style, features);
      case ThemeLayerType.symbol:
        return;
      case ThemeLayerType.background:
      case ThemeLayerType.raster:
      case ThemeLayerType.unsupported:
        return;
    }
  }

  @override
  void visitBackground(VisitorContext context, Vector4 color) {
    final uniform = Float32List.fromList([color.x, color.y, color.z, color.w])
        .buffer
        .asByteData();

    tileRenderData.addMesh(PackedMesh(
        PackedGeometry(
            vertices: ByteData(0),
            indices: ByteData(0),
            type: GeometryType.background),
        PackedMaterial(uniform: uniform, type: MaterialType.colored)));
  }
}

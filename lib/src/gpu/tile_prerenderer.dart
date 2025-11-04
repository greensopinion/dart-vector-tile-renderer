import 'dart:typed_data';

import 'package:vector_math/vector_math.dart';

import '../../vector_tile_renderer.dart';
import '../themes/expression/expression.dart';
import '../themes/feature_resolver.dart';
import '../themes/style.dart';
import '../themes/theme_layer_raster.dart';
import 'bucket_unpacker.dart';
import 'debug/debug_render_layer.dart';
import 'line/scene_line_builder.dart';
import 'polygon/scene_polygon_builder.dart';
import 'text/prerender/ndc_label_space.dart';
import 'text/sdf/glyph_atlas_data.dart';
import 'text/prerender/text_layer_visitor.dart';
import 'tile_render_data.dart';

class TilePreRenderer {
  Uint8List preRender(Theme theme, double zoom, Tileset tileset,
      AtlasSet atlasSet, double pixelRatio) {
    final data = TileRenderData();

    final visitor =
        _PreRendererLayerVisitor(data, tileset, zoom, atlasSet, pixelRatio);
    visitor.visitAllFeatures(theme);

    // addDebugRenderLayer(data);

    // renderLabelSpaceBoxes(data, visitor.labelSpaces[0.95]!);

    return data.pack();
  }
}

class _PreRendererLayerVisitor extends LayerVisitor {
  final TileRenderData tileRenderData;
  late final VisitorContext context;
  final labelSpaces = <double, NdcLabelSpace>{
    1.5: NdcLabelSpace(),
    1.25: NdcLabelSpace(),
    1.0: NdcLabelSpace(),
    0.75: NdcLabelSpace(),
    0.5: NdcLabelSpace(),
    0.25: NdcLabelSpace()
  };
  final AtlasSet atlasSet;

  _PreRendererLayerVisitor(this.tileRenderData, Tileset tileset, double zoom,
      this.atlasSet, double pixelRatio) {
    context = VisitorContext(
        logger: const Logger.noop(),
        tileSource: TileSource(tileset: tileset),
        zoom: zoom,
        pixelRatio: pixelRatio);
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
        return TextLayerVisitor(tileRenderData, context, atlasSet)
            .addFeatures(style, features, labelSpaces);
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

  @override
  void visitRasterLayer(String key, RasterPaintModel paintModel) {
    final tileKey = Uint16List.fromList(key.codeUnits).buffer.asByteData();

    final evaluationContext = EvaluationContext(
        () => {}, TileFeatureType.none, context.logger,
        zoom: context.zoom, zoomScaleFactor: 1.0, hasImage: (a) => true);

    final opacity = paintModel.opacity.evaluate(evaluationContext) ?? 1.0;

    if (opacity > 0) {
      final resampling =
          paintModel.rasterResampling.evaluate(evaluationContext);
      final resamplingDouble = resampling == "nearest" ? 0.0 : 1.0;
      final uniform =
          Float64List.fromList([opacity, resamplingDouble]).buffer.asByteData();

      tileRenderData.addMesh(PackedMesh(
          PackedGeometry(
              vertices: ByteData(0),
              indices: ByteData(0),
              uniform: tileKey,
              type: GeometryType.raster),
          PackedMaterial(uniform: uniform, type: MaterialType.raster)));
    }
  }
}

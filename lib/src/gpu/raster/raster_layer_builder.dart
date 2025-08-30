import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart';
import 'raster_material.dart';
import 'raster_geometry.dart';
import '../../themes/theme_layer_raster.dart';

import '../../../vector_tile_renderer.dart';
import '../../themes/expression/expression.dart';

class RasterLayerBuilder {
  final SceneGraph graph;
  final VisitorContext context;

  RasterLayerBuilder(this.graph, this.context);

  void build(RasterTile tile, RasterPaintModel paintModel) {
    final evaluationContext = EvaluationContext(
        () => {}, TileFeatureType.none, context.logger,
        zoom: context.zoom, zoomScaleFactor: 1.0, hasImage: (a) => true);
    final opacity = paintModel.opacity.evaluate(evaluationContext) ?? 1.0;
    if (opacity > 0.0) {
      final texture = tile.texture;
      if (texture != null) {
        final resampling =
            paintModel.rasterResampling.evaluate(evaluationContext);

        RasterMaterial material =
            RasterMaterial(colorTexture: texture, resampling: resampling);
        material.baseColorFactor = Vector4(1.0, 1.0, 1.0, opacity);

        graph.addMesh(Mesh(RasterGeometry(tile), material));
      }
    }
  }
}

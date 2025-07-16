

import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart';
import 'package:vector_tile_renderer/src/gpu/raster/blurred_unlit_material.dart';
import 'package:vector_tile_renderer/src/themes/theme_layer_raster.dart';

import '../../../vector_tile_renderer.dart';
import '../../themes/expression/expression.dart';
import '../background/background_geometry.dart';

class RasterLayerBuilder {
  final Scene scene;
  final VisitorContext context;

  RasterLayerBuilder(this.scene, this.context);

  void build(RasterTile tile, RasterPaintModel paintModel) {

    final evaluationContext = EvaluationContext(
            () => {}, TileFeatureType.none, context.logger,
        zoom: context.zoom,
        zoomScaleFactor: 1.0,
        hasImage: (a) => true);
    final opacity = paintModel.opacity.evaluate(evaluationContext) ?? 1.0;
    if (opacity > 0.0) {
      final texture = tile.texture;
      if (texture != null) {
        UnlitMaterial material = BlurredUnlitMaterial(colorTexture: texture);
        material.baseColorFactor = Vector4(1.0, 1.0, 1.0, opacity);

        scene.addMesh(Mesh(BackgroundGeometry(), material));
      }
    }
  }
}
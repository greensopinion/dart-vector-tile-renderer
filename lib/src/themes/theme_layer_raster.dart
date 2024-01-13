import 'package:flutter/painting.dart';

import '../../vector_tile_renderer.dart';
import '../context.dart';
import '../features/extensions.dart';
import 'expression/expression.dart';
import 'selector.dart';

class RasterPaintModel {
  final Expression<double> opacity;

  RasterPaintModel({required this.opacity});
}

class ThemeLayerRaster extends ThemeLayer {
  final TileLayerSelector selector;
  final RasterPaintModel paintModel;
  ThemeLayerRaster(super.id, super.type,
      {required this.selector,
      required this.paintModel,
      required super.minzoom,
      required super.maxzoom,
      required super.metadata});

  @override
  void render(Context context) {
    final image = context.tileSource.rasterTileset.tiles[tileSource];
    if (image != null) {
      renderImage(context, image);
    }
  }

  void renderImage(Context context, RasterTile image) {
    final evaluationContext = EvaluationContext(
        () => {}, TileFeatureType.none, context.logger,
        zoom: context.zoom,
        zoomScaleFactor: context.zoomScaleFactor,
        hasImage: context.hasImage);
    final opacity = paintModel.opacity.evaluate(evaluationContext) ?? 1.0;
    if (opacity > 0.0) {
      final paint = Paint()
        ..color = Color.fromARGB((opacity * 255).round().clamp(0, 255), 0, 0, 0)
        ..isAntiAlias = true;
      if (image.scope == context.tileSpace) {
        context.canvas
            .drawImageRect(image.image, image.scope, context.tileSpace, paint);
      } else {
        final scale = context.tileClip.width / image.scope.width;
        context.canvas.drawAtlas(
            image.image,
            [
              RSTransform.fromComponents(
                  rotation: 0.0,
                  scale: scale,
                  anchorX: 0.0,
                  anchorY: 0.0,
                  translateX: context.tileClip.left,
                  translateY: context.tileClip.top),
            ],
            [image.scope],
            null,
            null,
            null,
            paint);
      }
    }
  }

  @override
  String? get tileSource => selector.tileSelector.source;
}

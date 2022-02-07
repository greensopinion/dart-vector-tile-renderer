import 'dart:ui';

import 'package:vector_tile_renderer/src/constants.dart';
import 'package:vector_tile_renderer/src/features/feature_renderer.dart';

import '../context.dart';
import '../tileset.dart';
import 'selector.dart';
import 'style.dart';
import 'theme.dart';

class DefaultLayer extends ThemeLayer {
  final TileLayerSelector selector;
  final Style style;

  DefaultLayer(
    String id,
    ThemeLayerType type, {
    required this.selector,
    required this.style,
    required double? minzoom,
    required double? maxzoom,
  }) : super(id, type, minzoom: minzoom, maxzoom: maxzoom);

  @override
  void render(Context context) {
    final layers = selector.select(context.tileset).toList(growable: false);
    assert(layers.length <= 1);

    if (layers.isEmpty) {
      return;
    }

    final features = context.tileset.resolver
        .resolveFeatures(this.selector)
        .toList(growable: false);

    if (features.isEmpty) {
      return;
    }

    final layer = layers.first;
    final extent = layer.extent;
    final pixelsPerTileUnit = 1 / extent * tileSize;

    final featureRendererContext =
        FeatureRendererContext(context, pixelsPerTileUnit);

    featureRendererContext.drawInTileSpace(() {
      for (final feature in features) {
        context.featureRenderer.render(
          featureRendererContext,
          type,
          style,
          feature.layer,
          feature.feature,
        );
      }
    });
  }
}

class BackgroundLayer extends ThemeLayer {
  final Color fillColor;

  BackgroundLayer(String id, this.fillColor)
      : super(id, ThemeLayerType.background, minzoom: 0, maxzoom: 24);

  @override
  void render(Context context) {
    context.logger.log(() => 'rendering $id');
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = fillColor;
    context.canvas.drawRect(context.tileClip, paint);
  }
}

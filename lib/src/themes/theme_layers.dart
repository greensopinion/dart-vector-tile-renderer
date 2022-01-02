import 'dart:ui';

import 'package:vector_tile/vector_tile_feature.dart';

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
    for (final feature
        in context.tileset.resolver.resolveFeatures(this.selector)) {
      context.featureRenderer
          .render(context, type, style, feature.layer, feature.feature);
      if (!context.tileset.preprocessed) {
        _releaseMemory(feature.feature);
      }
    }
  }

  void _releaseMemory(VectorTileFeature feature) {
    feature.properties = null;
    feature.geometry = null;
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

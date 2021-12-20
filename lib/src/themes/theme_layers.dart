import 'dart:ui';

import 'package:vector_tile/vector_tile_feature.dart';

import '../constants.dart';
import '../context.dart';
import 'selector.dart';
import 'style.dart';
import 'theme.dart';

class DefaultLayer extends ThemeLayer {
  final TileLayerSelector selector;
  final Style style;

  DefaultLayer(String id, ThemeLayerType type,
      {required this.selector,
      required this.style,
      required double? minzoom,
      required double? maxzoom})
      : super(id, type, minzoom: minzoom, maxzoom: maxzoom);

  @override
  void render(Context context) {
    selector.select(context).forEach((layer) {
      selector.layerSelector.features(layer.features).forEach((feature) {
        context.featureRenderer.render(context, type, style, layer, feature);
        _releaseMemory(feature);
      });
    });
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

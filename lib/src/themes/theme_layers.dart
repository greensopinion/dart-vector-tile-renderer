import 'dart:ui';

import 'package:vector_tile/vector_tile_feature.dart';
import 'package:vector_tile_renderer/src/expressions/expression.dart';

import '../constants.dart';
import '../context.dart';
import 'selector.dart';
import 'style.dart';
import 'theme.dart';

class DefaultLayer extends ThemeLayer {
  final LayerSelector selector;
  final Style style;

  DefaultLayer(String id, ThemeLayerType type,
      {required this.selector,
      required this.style,
      required double? minzoom,
      required double? maxzoom})
      : super(id, type, minzoom: minzoom, maxzoom: maxzoom);

  @override
  void render(Context context) {
    selector.select(context.tile.layers).forEach((layer) {
      selector.features(layer.features).forEach((feature) {
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
  final Expression<Color> fillColor;

  BackgroundLayer(String id, this.fillColor)
      : super(id, ThemeLayerType.background, minzoom: 0, maxzoom: 24);

  @override
  void render(Context context) {
    context.logger.log(() => 'rendering $id');
    final effectiveColor =
        fillColor.evaluate({'zoom': context.zoom}) ?? Color(0x00000000);

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = effectiveColor;
    context.canvas.drawRect(
        Rect.fromLTRB(0, 0, tileSize.toDouble(), tileSize.toDouble()), paint);
  }
}

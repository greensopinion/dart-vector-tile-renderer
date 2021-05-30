import 'dart:ui';

import 'selector.dart';

import '../constants.dart';
import '../context.dart';
import 'style.dart';
import 'theme.dart';

class DefaultLayer extends ThemeLayer {
  final LayerSelector selector;
  final Style style;

  DefaultLayer(String id,
      {required this.selector,
      required this.style,
      required int? minzoom,
      required int? maxzoom})
      : super(id, minzoom: minzoom, maxzoom: maxzoom);

  @override
  void render(Context context) {
    selector.select(context.tile.layers).forEach((layer) {
      selector.features(layer.features).forEach((feature) {
        context.featureRenderer.render(context.canvas, style, layer, feature);
      });
    });
  }
}

class BackgroundLayer extends ThemeLayer {
  final Color fillColor;

  BackgroundLayer(String id, this.fillColor)
      : super(id, minzoom: 0, maxzoom: 24);

  @override
  void render(Context context) {
    context.logger.log(() => 'rendering $id');
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = fillColor;
    context.canvas.drawRect(
        Rect.fromLTRB(0, 0, tileSize.toDouble(), tileSize.toDouble()), paint);
  }
}

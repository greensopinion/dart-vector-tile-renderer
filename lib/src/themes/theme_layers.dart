import 'dart:ui';

import '../constants.dart';
import '../context.dart';
import '../features/tile_space_mapper.dart';
import '../model/tile_model.dart';
import '../tileset.dart';
import 'expression/expression.dart';
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
      required double? maxzoom,
      required Map<String, dynamic> metadata})
      : super(id, type, minzoom: minzoom, maxzoom: maxzoom, metadata: metadata);

  @override
  void render(Context context) {
    final layers =
        selector.select(context.tileSource.tileset, context.zoom.truncate());
    if (layers.isEmpty) {
      return;
    }

    final features = context.tileSource.tileset.resolver
        .resolveFeatures(selector, context.zoom.truncate());

    if (features.isEmpty) {
      return;
    }

    for (final layer in layers) {
      context.tileSpaceMapper = TileSpaceMapper(
        context.canvas,
        context.tileClip,
        tileSize,
        layer.extent,
      );

      context.tileSpaceMapper.drawInTileSpace(() {
        for (final feature in features) {
          context.featureRenderer.render(
            context,
            type,
            style,
            feature.layer,
            feature.feature,
          );
        }
      });
    }
  }

  @override
  String? get tileSource => selector.tileSelector.source;
}

class BackgroundLayer extends ThemeLayer {
  final Expression<Color> fillColor;

  BackgroundLayer(String id, this.fillColor, Map<String, dynamic> metadata)
      : super(id, ThemeLayerType.background,
            minzoom: 0, maxzoom: 24, metadata: metadata);

  @override
  void render(Context context) {
    context.logger.log(() => 'rendering $id');
    final color = fillColor.evaluate(EvaluationContext(
        () => {}, TileFeatureType.background, context.logger,
        zoom: context.zoom, zoomScaleFactor: 1.0, hasImage: (_) => false));
    if (color != null) {
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = color;
      context.canvas.drawRect(context.tileClip, paint);
    }
  }

  @override
  String? get tileSource => null;
}

import 'dart:ui';

import 'package:vector_tile_renderer/src/constants.dart';
import 'package:vector_tile_renderer/src/model/tile_model.dart';
import 'package:vector_tile_renderer/src/themes/expression/color_expression.dart';
import 'package:vector_tile_renderer/src/themes/expression/expression.dart';

import '../context.dart';
import '../features/tile_space_mapper.dart';
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

class BackgroundLayer extends ThemeLayer {
  final ColorExpression fillColor;

  BackgroundLayer(String id, this.fillColor)
      : super(id, ThemeLayerType.background, minzoom: 0, maxzoom: 24);

  @override
  void render(Context context) {
    context.logger.log(() => 'rendering $id');
    final color = fillColor.evaluate(EvaluationContext(
        () => {}, TileFeatureType.background, context.zoom, context.logger));
    if (color != null) {
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = color;
      context.canvas.drawRect(context.tileClip, paint);
    }
  }
}

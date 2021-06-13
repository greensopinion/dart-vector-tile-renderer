import 'dart:ui';

import 'package:vector_tile/vector_tile.dart';
import 'package:vector_tile_renderer/src/constants.dart';

import 'context.dart';
import 'features/feature_renderer.dart';
import 'themes/theme.dart';
import 'logger.dart';

class Renderer {
  final Theme theme;
  final Logger logger;
  final FeatureDispatcher featureRenderer;

  Renderer({required this.theme, Logger? logger})
      : this.logger = logger ?? Logger.noop(),
        featureRenderer = FeatureDispatcher(logger ?? Logger.noop());

  /// renders the given tile to the canvas
  ///
  /// [zoomScaleFactor] the 1-dimensional scale at which the tile is being
  ///        rendered. If the tile is being rendered at twice it's normal size
  ///        along the x-axis, the zoomScaleFactor would be 2. 1.0 indicates that
  ///        no scaling is being applied.
  /// [zoom] the current zoom level, which is used to filter theme layers
  ///        via `minzoom` and `maxzoom`. Value must be >= 0 and <= 24
  void render(Canvas canvas, VectorTile tile,
      {Rect? clip, required double zoomScaleFactor, required double zoom}) {
    canvas.save();
    canvas.clipRect(
        Rect.fromLTRB(0, 0, tileSize.toDouble(), tileSize.toDouble()));
    final tileClip =
        clip ?? Rect.fromLTWH(0, 0, tileSize.toDouble(), tileSize.toDouble());
    final context = Context(
        logger, canvas, featureRenderer, tile, zoomScaleFactor, zoom, tileClip);
    final effectiveTheme = theme.atZoom(zoom);
    effectiveTheme.layers.forEach((themeLayer) {
      logger.log(() => 'rendering theme layer ${themeLayer.id}');
      themeLayer.render(context);
    });
    canvas.restore();
  }
}

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
  /// [zoom] the current zoom level, which is used to filter theme layers
  ///        via `minzoom` and `maxzoom`. Value if provided must be >= 0 and <= 24
  ///        When absent all layers are applied as if `minzoom` and `maxzoom` were
  ///        not specified in the theme.
  void render(Canvas canvas, VectorTile tile, {required int? zoom}) {
    canvas.save();
    canvas.clipRect(
        Rect.fromLTRB(0, 0, tileSize.toDouble(), tileSize.toDouble()));
    final context = Context(logger, canvas, featureRenderer, tile);
    final effectiveTheme = (zoom == null) ? theme : theme.atZoom(zoom);
    effectiveTheme.layers.forEach((themeLayer) {
      logger.log(() => 'rendering theme layer ${themeLayer.id}');
      themeLayer.render(context);
    });
    canvas.restore();
  }
}

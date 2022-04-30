import 'dart:ui';

import 'symbols/text_painter.dart';

import 'constants.dart';
import 'context.dart';
import 'features/feature_renderer.dart';
import 'logger.dart';
import 'optimizations.dart';
import 'profiling.dart';
import 'themes/theme.dart';
import 'tileset.dart';

class Renderer {
  final Theme theme;
  final Logger logger;
  final FeatureDispatcher featureRenderer;
  final TextPainterProvider painterProvider;
  Renderer(
      {required this.theme,
      this.painterProvider = const DefaultTextPainterProvider(),
      Logger? logger})
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
  /// [tileset] the tileset having tiles by source id
  /// [clip] the optional clip to constrain tile rendering, used to limit drawing
  ///        so that a portion of a tile can be rendered to a canvas
  void render(Canvas canvas, Tileset tileset,
      {Rect? clip, required double zoomScaleFactor, required double zoom}) {
    profileSync('Render', () {
      final tileSpace =
          Rect.fromLTWH(0, 0, tileSize.toDouble(), tileSize.toDouble());
      canvas.save();
      canvas.clipRect(tileSpace);
      final tileClip = clip ?? tileSpace;
      final optimizations = Optimizations(
          skipInBoundsChecks: clip == null || tileClip == tileSpace);
      final context = Context(
          logger: logger,
          canvas: canvas,
          featureRenderer: featureRenderer,
          tileset: tileset,
          zoomScaleFactor: zoomScaleFactor,
          zoom: zoom,
          tileSpace: tileSpace,
          tileClip: tileClip,
          optimizations: optimizations,
          textPainterProvider: painterProvider);
      final effectiveTheme = theme.atZoom(zoom);
      effectiveTheme.layers.forEach((themeLayer) {
        logger.log(() => 'rendering theme layer ${themeLayer.id}');
        themeLayer.render(context);
      });
      canvas.restore();
    });
  }
}

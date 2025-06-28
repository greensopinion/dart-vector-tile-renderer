import 'dart:ui';

import 'constants.dart';
import 'features/feature_renderer.dart';
import 'gpu/tile_renderer_composite.dart';
import 'logger.dart';
import 'profiling.dart';
import 'symbols/text_painter.dart';
import 'themes/theme.dart';
import 'tile_source.dart';

class Renderer {
  final Theme theme;
  final Logger logger;
  final FeatureDispatcher featureRenderer;
  final TextPainterProvider painterProvider;
  final bool experimentalGpuRendering;
  Renderer(
      {required this.theme,
      this.painterProvider = const DefaultTextPainterProvider(),
      this.experimentalGpuRendering = false,
      Logger? logger})
      : logger = logger ?? const Logger.noop(),
        featureRenderer = FeatureDispatcher(logger ?? const Logger.noop());

  /// renders the given tile to the canvas
  ///
  /// [zoomScaleFactor] the 1-dimensional scale at which the tile is being
  ///        rendered. If the tile is being rendered at twice it's normal size
  ///        along the x-axis, the zoomScaleFactor would be 2. 1.0 indicates that
  ///        no scaling is being applied.
  /// [zoom] the current zoom level, which is used to filter theme layers
  ///        via `minzoom` and `maxzoom`. Value must be >= 0 and <= 24
  /// [tile] the tile to render
  /// [clip] the optional clip to constrain tile rendering, used to limit drawing
  ///        so that a portion of a tile can be rendered to a canvas
  void render(Canvas canvas, TileSource tile,
      {Rect? clip,
      required double zoomScaleFactor,
      required double zoom,
      required double rotation}) {
    profileSync('Render', () {
      TileRendererComposite renderer = TileRendererComposite(
        theme: theme,
        tile: tile,
        gpuRenderingEnabled: experimentalGpuRendering,
        zoom: zoom,
        painterProvider: painterProvider,
        logger: logger,
      );
      renderer.render(
        canvas,
        Size(tileSize.toDouble(), tileSize.toDouble()),
        clip: clip,
        zoomScaleFactor: zoomScaleFactor,
        rotation: rotation,
      );
    });
  }
}

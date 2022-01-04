import 'dart:ui';

import 'constants.dart';
import 'logger.dart';
import 'profiling.dart';
import 'renderer.dart';
import 'themes/theme.dart';
import 'tileset.dart';

class ImageRenderer {
  final Logger logger;
  final Theme theme;
  final double scale;

  ImageRenderer({required this.theme, required this.scale, Logger? logger})
      : this.logger = logger ?? Logger.noop() {
    assert(scale >= 1 && scale <= 4);
  }

  /// renders the given tile to an image
  ///
  ///
  /// [zoomScaleFactor] the 1-dimensional scale at which the tile is being
  ///        rendered. If the tile is being rendered at twice it's normal size
  ///        along the x-axis, the zoomScaleFactor would be 2. 1.0 indicates that
  ///        no scaling is being applied.
  /// [zoom] the current zoom level, which is used to filter theme layers
  ///        via `minzoom` and `maxzoom`. Value if provided must be >= 0 and <= 24
  /// [tileset] the tileset, having vector tiles by `'source'` ID as defined by the theme
  Future<Image> render(Tileset tileset,
      {double zoomScaleFactor = 1.0, required double zoom}) {
    return profileAsync('RenderImage', () {
      final recorder = PictureRecorder();
      double size = scale * tileSize;
      final rect = Rect.fromLTRB(0, 0, size, size);
      final canvas = Canvas(recorder, rect);
      canvas.clipRect(rect);
      canvas.scale(scale.toDouble(), scale.toDouble());
      Renderer(theme: theme, logger: logger).render(canvas, tileset,
          zoomScaleFactor: zoomScaleFactor, zoom: zoom);
      return recorder.endRecording().toImage(size.floor(), size.floor());
    });
  }
}

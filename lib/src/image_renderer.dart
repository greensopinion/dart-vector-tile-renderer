import 'dart:ui';
import 'package:vector_tile/vector_tile.dart';

import 'constants.dart';
import 'logger.dart';
import 'renderer.dart';
import 'themes/theme.dart';

class ImageRenderer {
  final Logger logger;
  final Theme theme;
  final int scale;

  ImageRenderer({required this.theme, required this.scale, Logger? logger})
      : this.logger = logger ?? Logger.noop() {
    assert(scale >= 1 && scale <= 4);
  }

  Future<Image> render(VectorTile tile) {
    final recorder = PictureRecorder();
    int size = scale * tileSize;
    final canvas =
        Canvas(recorder, Rect.fromLTRB(0, 0, size.toDouble(), size.toDouble()));
    canvas.scale(scale.toDouble(), scale.toDouble());
    Renderer(theme: theme, logger: logger).render(canvas, tile);
    return recorder.endRecording().toImage(size, size);
  }
}

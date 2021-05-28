import 'dart:ui';
import 'package:vector_tile/vector_tile.dart';

import 'constants.dart';
import 'layer_filter.dart';
import 'logger.dart';
import 'renderer.dart';

class ImageRenderer {
  final Logger logger;
  final int scale;
  final LayerFilter layerFilter;

  ImageRenderer(
      {required this.scale, required this.layerFilter, Logger? logger})
      : this.logger = logger ?? Logger.noop() {
    assert(scale >= 1 && scale <= 4);
  }

  Future<Image> render(VectorTile tile) {
    final recorder = PictureRecorder();
    int size = scale * tileSize;
    final canvas =
        Canvas(recorder, Rect.fromLTRB(0, 0, size.toDouble(), size.toDouble()));
    canvas.scale(scale.toDouble(), scale.toDouble());

    Renderer(layerFilter: layerFilter, logger: logger).render(canvas, tile);

    return recorder.endRecording().toImage(size, size);
  }
}

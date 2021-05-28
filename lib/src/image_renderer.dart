import 'dart:ui';

import 'package:vector_tile/vector_tile.dart';

class ImageRenderer {
  final int size;

  ImageRenderer({required this.size});

  Future<Image> render(VectorTile tile) {
    final recorder = PictureRecorder();
    final canvas =
        Canvas(recorder, Rect.fromLTRB(0, 0, size.toDouble(), size.toDouble()));

    return recorder.endRecording().toImage(size, size);
  }
}

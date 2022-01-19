import 'dart:ui';

import '../model/tile_model.dart';

extension PointsExtension on List<Point> {
  List<Offset> toPoints(int extent, int tileSize) => map((point) {
        final x = (point.x / extent) * tileSize;
        final y = (point.y / extent) * tileSize;
        return Offset(x, y);
      }).toList(growable: false);
}

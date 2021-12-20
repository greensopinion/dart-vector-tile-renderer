import 'dart:ui';

extension PointsExtension on List<List<double>> {
  List<Offset> toPoints(int extent, int tileSize) => map((point) {
        final x = (point[0] / extent) * tileSize;
        final y = (point[1] / extent) * tileSize;
        return Offset(x, y);
      }).toList();
}

import 'dart:ui';

import 'geometry_model.dart';

final _uiGeometry = UiGeometry._();

class UiGeometry {
  UiGeometry._();
  factory UiGeometry() => _uiGeometry;

  Offset createPoint(TilePoint point) => Offset(point.x, point.y);

  Path createLine(TileLine line) =>
      Path()..addPolygon(_line(line.points), false);

  Path createPolygon(TilePolygon polygon) {
    final path = Path()..fillType = PathFillType.evenOdd;
    for (final ring in polygon.rings) {
      path.addPolygon(_line(ring.points), true);
    }
    return path;
  }

  List<Offset> _line(List<TilePoint> points) =>
      points.map((e) => createPoint(e)).toList(growable: false);
}

import 'dart:math';
import 'dart:ui';

typedef TilePoint = Point<double>;

class TileLine {
  final List<TilePoint> points;

  TileLine(this.points);
}

class TilePolygon {
  final List<TileLine> rings;

  TilePolygon(this.rings);
}

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

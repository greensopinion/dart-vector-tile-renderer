import 'dart:math';

import 'package:collection/collection.dart';

typedef TilePoint = Point<double>;
typedef Bounds = Rectangle<double>;

class TileLine {
  final List<TilePoint> points;

  TileLine(this.points);

  Bounds bounds() {
    var minX = double.infinity;
    var maxX = double.negativeInfinity;
    var minY = double.infinity;
    var maxY = double.negativeInfinity;
    for (final point in points) {
      minX = min(minX, point.x);
      maxX = max(maxX, point.x);
      minY = min(minY, point.y);
      maxY = max(maxY, point.y);
    }
    return Bounds.fromPoints(TilePoint(minX, minY), TilePoint(maxX, maxY));
  }

  @override
  bool operator ==(Object other) =>
      other is TileLine && _equality.equals(points, other.points);

  @override
  int get hashCode => _equality.hash(points);

  @override
  String toString() => "TileLine($points)";
}

class TilePolygon {
  final List<TileLine> rings;

  TilePolygon(this.rings);

  Bounds bounds() => rings.first.bounds();

  @override
  bool operator ==(Object other) =>
      other is TilePolygon && _equality.equals(rings, other.rings);

  @override
  int get hashCode => _equality.hash(rings);

  @override
  String toString() => "TilePolygon($rings)";
}

final _equality = ListEquality();

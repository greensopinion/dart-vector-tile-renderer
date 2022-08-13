import 'dart:math';

import 'package:fixnum/fixnum.dart';

import '../geometry_model.dart';
import 'geometry_clip.dart';

// Sutherland–Hodgman algorithm
// https://en.wikipedia.org/wiki/Sutherland%E2%80%93Hodgman_algorithm
//
class PolygonClip {
  final ClipArea bounds;

  PolygonClip(this.bounds);

  TilePolygon? clip(TilePolygon polygon) {
    final rings = <TileLine>[];
    for (final ring in polygon.rings) {
      final clipped = _clipRing(ring);
      if (clipped != null) {
        rings.add(clipped);
      } else if (rings.isEmpty) {
        // only skip the inner ring
        return null;
      }
    }
    return rings.isEmpty ? null : TilePolygon(rings);
  }

  TileLine? _clipRing(TileLine ring) {
    var outputList = ring.points;
    for (final edge in _Edge.values) {
      final inputList = outputList;
      outputList = <TilePoint>[];

      final pointCount = inputList.length;
      for (int index = 0; index < pointCount; ++index) {
        final currentPoint = inputList[index];
        final previousPoint = inputList[(index - 1) % pointCount];
        if (_isInside(currentPoint, edge)) {
          if (!_isInside(previousPoint, edge)) {
            outputList
                .add(_intersectingPoint(previousPoint, currentPoint, edge));
          }
          outputList.add(currentPoint);
        } else if (_isInside(previousPoint, edge)) {
          outputList.add(_intersectingPoint(previousPoint, currentPoint, edge));
        }
      }
    }
    if (outputList.isEmpty) {
      return null;
    }
    return TileLine(outputList);
  }

  bool _isInside(TilePoint point, _Edge edge) {
    switch (edge) {
      case _Edge.left:
        return point.x >= bounds.left;
      case _Edge.top:
        return point.y >= bounds.top;
      case _Edge.right:
        return point.x <= bounds.right;
      case _Edge.bottom:
        return point.y <= bounds.bottom;
    }
  }

  TilePoint _intersectingPoint(
      TilePoint firstPoint, TilePoint secondPoint, _Edge edge) {
    // based on https://github.com/mdabdk/sutherland-hodgman/blob/main/SH.py
    final shift = TilePoint(min(firstPoint.x, secondPoint.x).abs() + 1,
        min(firstPoint.y, secondPoint.y).abs() + 1);
    final l0p0 = firstPoint + shift;
    final l0p1 = secondPoint + shift;
    final second = _line(edge, shift);
    final l1p0 = second[0];
    final l1p1 = second[1];
    if (_vertical([l0p0, l0p1])) {
      final x = l0p0.x;
      final m2 = (l1p1.y - l1p0.y) / (l1p1.x - l1p0.x);
      final b2 = l1p0.y - m2 * l1p0.y;
      final y = m2 * x + b2;
      return TilePoint(x, y) - shift;
    } else if (_vertical(second)) {
      final x = l1p0.x;
      final m1 = (l0p1.y - l0p0.y) / (l0p1.x - l0p0.x);
      final b1 = l0p0.y - m1 * l0p0.x;
      final y = m1 * x + b1;
      return TilePoint(x, y) - shift;
    }
    final m1 = (l0p1.y - l0p0.y) / (l0p1.x - l0p0.x);
    final b1 = l0p0.y - m1 * l0p0.x;
    final m2 = (l1p1.y - l1p0.y) / (l1p1.x - l1p0.x);
    final b2 = l1p0.y - m2 * l1p0.x;
    final x = (b2 - b1) / (m1 - m2);
    final y = m1 * x + b1;
    return TilePoint(x, y) - shift;
  }

  List<TilePoint> _line(_Edge edge, TilePoint shift) {
    switch (edge) {
      case _Edge.left:
        return [
          TilePoint(bounds.left + shift.x, 0),
          TilePoint(bounds.left + shift.x, maxCoordinate)
        ];
      case _Edge.top:
        return [
          TilePoint(0, bounds.top + shift.y),
          TilePoint(maxCoordinate, bounds.top + shift.y)
        ];
      case _Edge.right:
        return [
          TilePoint(bounds.right + shift.x, 0),
          TilePoint(bounds.right + shift.x, maxCoordinate)
        ];
      case _Edge.bottom:
        return [
          TilePoint(0, bounds.bottom + shift.y),
          TilePoint(maxCoordinate, bounds.bottom + shift.y)
        ];
    }
  }

  bool _vertical(List<TilePoint> line) => line[0].x == line[1].x;
}

enum _Edge { left, top, right, bottom }

final double maxCoordinate = (Int32.MAX_VALUE.toInt() / 2).floorToDouble();

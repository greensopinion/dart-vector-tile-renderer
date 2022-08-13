import 'dart:math';

import '../geometry_model.dart';
import 'polygon_clip.dart';

typedef ClipArea = Rectangle<double>;

List<TileLine> clipLine(TileLine line, ClipArea clip) {
  final bounds = line.bounds();
  if (!bounds.intersects(clip)) {
    return [];
  }
  final state = _PointsState();
  TilePoint? previous;
  for (final point in line.points) {
    _addPoint(state, clip, point, previous);
    previous = point;
  }
  state.lines.addLine(state.points);
  return state.lines;
}

void _addPoint(
    _PointsState state, ClipArea clip, TilePoint point, TilePoint? previous) {
  if (clip.containsPoint(point)) {
    if (previous != null && !clip.containsPoint(previous)) {
      state.points.add(_intersectingPoint(point, previous, clip));
    }
    state.points.add(point);
  } else if (previous != null && clip.containsPoint(previous)) {
    state.points.add(_intersectingPoint(previous, point, clip));
    state.lines.addLine(state.points);
    state.points = [];
  } else if (previous != null) {
    TilePoint? segmentPointInside =
        _findSegmentPointInside(clip, previous, point);
    if (segmentPointInside != null) {
      _addPoint(state, clip, segmentPointInside, previous);
      _addPoint(state, clip, point, segmentPointInside);
    }
  }
}

class _PointsState {
  final lines = <TileLine>[];
  var points = <TilePoint>[];
}

// A rough approximation, does a binary search for a point contained on the
// line segment by splitting the line by its midpoint and checking whether
// the midpoint is within the clip area. Short-circuits for segments that don't
// have overlapping bounding boxes.
// Precision can be increased by increasing the depth. Complexity is O(2^depth)
TilePoint? _findSegmentPointInside(ClipArea clip, TilePoint a, TilePoint b,
    {int depth = 6}) {
  TilePoint midpoint = TilePoint((a.x + b.x) / 2, (a.y + b.y) / 2);
  if (clip.containsPoint(midpoint)) {
    return midpoint;
  }
  if (depth > 0 && clip.intersects(Rectangle.fromPoints(a, b))) {
    return _findSegmentPointInside(clip, a, midpoint, depth: depth - 1) ??
        _findSegmentPointInside(clip, midpoint, b, depth: depth - 1);
  }
  return null;
}

TilePolygon? clipPolygon(TilePolygon polygon, ClipArea clip) {
  return PolygonClip(clip).clip(polygon);
}

TilePoint _intersectingPoint(
    TilePoint inside, TilePoint outside, ClipArea clip) {
  if (inside.x == outside.x) {
    return TilePoint(inside.x, max(clip.top, min(clip.bottom, outside.y)));
  } else if (inside.y == outside.y) {
    return TilePoint(max(clip.left, min(clip.right, outside.x)), inside.y);
  }
  var point = outside;
  final dx = _delta(inside.x, outside.x);
  final dy = _delta(inside.y, outside.y);
  final alpha = atan(dy / dx);

  if (point.x < clip.left || point.x > clip.right) {
    point = _intersectingClipX(clip, alpha, inside, point);
  }
  if (point.y < clip.top || point.y > clip.bottom) {
    point = _intersectingClipY(clip, alpha, inside, point);
    if (point.x < clip.left || point.x > clip.right) {
      point = _intersectingClipX(clip, alpha, inside, point);
    }
  }

  return point;
}

TilePoint _intersectingClipX(
    ClipArea clip, double alpha, TilePoint inside, TilePoint point) {
  var x = (point.x < clip.left) ? clip.left : clip.right;
  var y = point.y;
  final lengthB = _delta(x, inside.x);
  final lengthA = lengthB * tan(alpha);
  if (y > inside.y) {
    y = inside.y + lengthA;
  } else {
    y = inside.y - lengthA;
  }
  return TilePoint(x, y);
}

TilePoint _intersectingClipY(
    ClipArea clip, double alpha, TilePoint inside, TilePoint point) {
  var x = point.x;
  var y = (point.y < clip.top) ? clip.top : clip.bottom;
  final beta = _nineteDegrees - alpha;
  final lengthA = _delta(y, inside.y);
  final lengthB = lengthA * tan(beta);
  if (point.x > inside.x) {
    x = inside.x + lengthB;
  } else {
    x = inside.x - lengthB;
  }
  return TilePoint(x, y);
}

double _delta(double a, double b) => ((a < b) ? (b - a) : (a - b)).abs();

const _nineteDegrees = (90 * pi / 180);

extension _TileLineList on List<TileLine> {
  void addLine(List<TilePoint> points) {
    if (points.length > 1) {
      add(TileLine(points.toList(growable: false)));
    }
  }
}

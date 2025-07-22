import 'dart:math';

import 'package:vector_math/vector_math.dart';
import 'package:vector_tile_renderer/src/gpu/line/line_geometry.dart';

import '../../model/geometry_model.dart';
import '../../themes/style.dart';

class LineGeometryBuilder {
  int indexOffset = 0;
  List<double> vertices = List.empty(growable: true);
  List<int> indices = List.empty(growable: true);

  int startIndex = 0;

  LineGeometry build(List<TileLine> lines, LineCap lineCaps, LineJoin lineJoins,
      double lineWidth, int extent, List<double>? dashLengths) {
    double totalCumulativeLength = 0.0;

    for (var line in lines) {
      startIndex = 0;
      var points = line.points;

      setupLine(points, lineCaps, lineJoins, totalCumulativeLength);

      if (cumulativeLengths.isNotEmpty) {
        totalCumulativeLength = cumulativeLengths.last;
      }

      indexOffset += startIndex;
    }

    return LineGeometry(
        points: lines.expand((it) => it.points).toList(),
        vertices: vertices,
        indices: indices,
        lineWidth: lineWidth,
        extent: extent,
        dashLengths: dashLengths);
  }

  setupLine(
    List<Point<double>> points,
    LineCap lineCaps,
    LineJoin lineJoins,
    double startingCumulativeLength,
  ) {
    final segmentCount = points.length - 1;

    computeCumulativeDistances(points, segmentCount, startingCumulativeLength);
    setupSegments(points, segmentCount);
    setupEnds(points, segmentCount, lineCaps);
    setupJoins(points, lineJoins);
  }

  void setupSegments(List<Point<double>> points, int segmentCount) {
    for (int i = 0; i < segmentCount; i++) {
      Point<double> p0 = points[i];
      Point<double> p1 = points[i + 1];

      double cumulativeLength0 =
          i < cumulativeLengths.length ? cumulativeLengths[i] : 0.0;
      double cumulativeLength1 =
          (i + 1) < cumulativeLengths.length ? cumulativeLengths[i + 1] : 0.0;

      vertices.addAll([
        p1.x,
        p1.y,
        p0.x,
        p0.y,
        1,
        0,
        0,
        cumulativeLength1,
        p0.x,
        p0.y,
        p1.x,
        p1.y,
        -1,
        0,
        0,
        cumulativeLength0,
        p0.x,
        p0.y,
        p1.x,
        p1.y,
        1,
        0,
        0,
        cumulativeLength0,
        p1.x,
        p1.y,
        p0.x,
        p0.y,
        -1,
        0,
        0,
        cumulativeLength1,
      ]);

      indices
          .addAll([0, 1, 2, 2, 3, 0].map((it) => it + (4 * i) + indexOffset));
    }
    startIndex += max(segmentCount * 4, 0);
  }

  void setupEnds(List<Point<double>> points, int segmentCount, LineCap type) {
    if (type == LineCap.butt) return;
    final round = type == LineCap.round ? 1.0 : 0.0;

    Point<double> a = points[0];
    Point<double> b = points[1];
    Point<double> c = points[segmentCount - 1];
    Point<double> d = points[segmentCount];

    // Get cumulative lengths for start and end points
    double startCumulativeLength =
        cumulativeLengths.isNotEmpty ? cumulativeLengths.first : 0.0;
    double endCumulativeLength =
        cumulativeLengths.isNotEmpty ? cumulativeLengths.last : 0.0;

    vertices.addAll([
      a.x,
      a.y,
      b.x,
      b.y,
      -1,
      -1,
      round,
      startCumulativeLength,
      a.x,
      a.y,
      b.x,
      b.y,
      1,
      -1,
      round,
      startCumulativeLength,
      d.x,
      d.y,
      c.x,
      c.y,
      -1,
      -1,
      round,
      endCumulativeLength,
      d.x,
      d.y,
      c.x,
      c.y,
      1,
      -1,
      round,
      endCumulativeLength,
    ]);

    indices.addAll([
      startIndex,
      startIndex + 1,
      1,
      startIndex + 1,
      2,
      1,
      startIndex + 3,
      startIndex - 4,
      startIndex - 1,
      startIndex + 2,
      startIndex + 3,
      startIndex - 1,
    ].map((it) => it + indexOffset));
    startIndex += 4;
  }

  void setupJoins(List<Point<double>> points, LineJoin type) {
    if (type == LineJoin.bevel) {
      setupJoinsBevel(points);
    } else if (type == LineJoin.round) {
      setupJoinsRound(points);
    } else {
      setupJoinsBevel(points);
      setupJoinsMiter(points);
    }
  }

  void setupJoinsRound(List<Point<double>> points) {
    final joinCount = points.length - 2;

    for (int i = 0; i < joinCount; i++) {
      Point<double> p0 = points[i];
      Point<double> p1 = points[i + 1];

      double joinCumulativeLength =
          (i + 1) < cumulativeLengths.length ? cumulativeLengths[i + 1] : 0.0;

      vertices
          .addAll([p1.x, p1.y, p0.x, p0.y, -1, -1, 1, joinCumulativeLength]);
      vertices.addAll([p1.x, p1.y, p0.x, p0.y, 1, -1, 1, joinCumulativeLength]);

      int offset = i * 4;

      int a = startIndex + (2 * i);
      int b = startIndex + (2 * i) + 1;
      int c = offset + 0;
      int d = offset + 3;

      indices.addAll([c, d, b, b, d, a].map((it) => it + indexOffset));
    }
    startIndex += max(2 * joinCount, 0);
  }

  void setupJoinsBevel(List<Point<double>> points) {
    final joinCount = points.length - 2;

    for (int i = 0; i < joinCount; i++) {
      Point<double> p = points[i + 1];

      double joinCumulativeLength =
          (i + 1) < cumulativeLengths.length ? cumulativeLengths[i + 1] : 0.0;

      vertices.addAll([p.x, p.y, 0, 0, 0, 0, 0, joinCumulativeLength]);

      int offset = i * 4;

      indices.addAll([
        offset + 5,
        offset,
        startIndex + i,
        offset + 3,
        offset + 6,
        startIndex + i,
      ].map((it) => it + indexOffset));
    }
    startIndex += max(joinCount, 0);
  }

  void setupJoinsMiter(List<Point<double>> points) {
    final joinCount = points.length - 2;

    Vector2 perp(Vector2 v, int flip) => Vector2(v.y * flip, -v.x * flip);

    for (int i = 0; i < joinCount; i++) {
      final p0 = Vector2(points[i].x, points[i].y);
      final p1 = Vector2(points[i + 2].x, points[i + 2].y);

      final origin = Vector2(points[i + 1].x, points[i + 1].y);
      final a = perp((p0 - origin).normalized(), -1);
      final b = perp((p1 - origin).normalized(), 1);

      final j = a.dot(b);
      if (j > 0.9999 || j < -0.9999) {
        startIndex -= 2;
        continue;
      }

      a.add(origin);
      b.add(origin);

      final c = (a + b).scaled(0.5);

      final vec = (c - origin);
      final resultLength = (c - a).length2 / vec.length2;

      final out = vec.scaled(1 + resultLength);

      double joinCumulativeLength =
          (i + 1) < cumulativeLengths.length ? cumulativeLengths[i + 1] : 0.0;

      vertices.addAll(
          [c.x, c.y, c.x, c.y + 1, out.x, -out.y, 0, joinCumulativeLength]);

      vertices.addAll([
        origin.x,
        origin.y,
        origin.x,
        origin.y + 1,
        -out.x,
        out.y,
        0,
        joinCumulativeLength
      ]);

      int offset = i * 4;

      indices.addAll([
        offset + 6,
        offset + 3,
        startIndex + (2 * i),
        offset,
        offset + 5,
        startIndex + (2 * i) + 1,
      ].map((it) => it + indexOffset));
    }
    startIndex += max(2 * joinCount, 0);
  }

  void computeCumulativeDistances(List<Point<double>> points, int segmentCount,
      double startingCumulativeLength) {
    cumulativeLengths.clear();
    cumulativeLengths.add(startingCumulativeLength);

    double sum = startingCumulativeLength;
    for (int i = 1; i < points.length; i++) {
      final dx = points[i].x - points[i - 1].x;
      final dy = points[i].y - points[i - 1].y;
      final segmentLength = sqrt(dx * dx + dy * dy);
      sum += segmentLength;
      cumulativeLengths.add(sum);
    }
  }
}

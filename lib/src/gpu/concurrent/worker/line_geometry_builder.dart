import 'dart:math';
import 'dart:typed_data';

import 'package:vector_math/vector_math.dart';

import '../../../model/geometry_model.dart';
import '../shared/keys.dart';

class LineGeometryBuilder {
  int indexOffset = 0;
  List<double> vertices = List.empty(growable: true);
  List<int> indices = List.empty(growable: true);
  List<double> cumulativeLengths = List.empty(growable: true);

  int startIndex = 0;

  void _addVertex(
      double point_a1,
      double point_a2,
      double point_b1,
      double point_b2,
      double offset1,
      double offset2,
      double roundness,
      double cumulativeLength) {
    vertices.addAll([
      point_a1,
      point_a2,
      point_b1,
      point_b2,
      offset1,
      offset2,
      roundness,
      cumulativeLength
    ]);
  }

  (ByteData, ByteData) build(
      List<List<TilePoint>> lines, LineEnd lineCaps, LineJoin lineJoins) {
    double totalCumulativeLength = 0.0;

    for (var line in lines) {
      startIndex = 0;

      setupLine(line, lineCaps, lineJoins, totalCumulativeLength);

      if (cumulativeLengths.isNotEmpty) {
        totalCumulativeLength = cumulativeLengths.last;
      }

      indexOffset += startIndex;
    }

    return (
      ByteData.sublistView(Float32List.fromList(vertices)),
      ByteData.sublistView(Uint16List.fromList(indices))
    );
  }

  setupLine(
    List<TilePoint> points,
    LineEnd lineCaps,
    LineJoin lineJoins,
    double startingCumulativeLength,
  ) {
    final segmentCount = points.length - 1;

    computeCumulativeDistances(points, segmentCount, startingCumulativeLength);
    setupSegments(points, segmentCount);
    setupEnds(points, segmentCount, lineCaps);
    setupJoins(points, lineJoins);
  }

  void setupSegments(List<TilePoint> points, int segmentCount) {
    for (int i = 0; i < segmentCount; i++) {
      TilePoint p0 = points[i];
      TilePoint p1 = points[i + 1];

      double cumulativeLength0 =
          i < cumulativeLengths.length ? cumulativeLengths[i] : 0.0;
      double cumulativeLength1 =
          (i + 1) < cumulativeLengths.length ? cumulativeLengths[i + 1] : 0.0;

      _addVertex(p1.x, p1.y, p0.x, p0.y, 1, 0, 0, cumulativeLength1);
      _addVertex(p0.x, p0.y, p1.x, p1.y, -1, 0, 0, cumulativeLength0);
      _addVertex(p0.x, p0.y, p1.x, p1.y, 1, 0, 0, cumulativeLength0);
      _addVertex(p1.x, p1.y, p0.x, p0.y, -1, 0, 0, cumulativeLength1);

      indices
          .addAll([0, 1, 2, 2, 3, 0].map((it) => it + (4 * i) + indexOffset));
    }
    startIndex += max(segmentCount * 4, 0);
  }

  void setupEnds(List<TilePoint> points, int segmentCount, LineEnd type) {
    if (type == LineEnd.butt) return;
    final round = type == LineEnd.round ? 1.0 : 0.0;

    TilePoint a = points[0];
    TilePoint b = points[1];
    TilePoint c = points[segmentCount - 1];
    TilePoint d = points[segmentCount];

    double startCumulativeLength =
        cumulativeLengths.isNotEmpty ? cumulativeLengths.first : 0.0;
    double endCumulativeLength =
        cumulativeLengths.isNotEmpty ? cumulativeLengths.last : 0.0;

    _addVertex(a.x, a.y, b.x, b.y, -1, -1, round, startCumulativeLength);
    _addVertex(a.x, a.y, b.x, b.y, 1, -1, round, startCumulativeLength);
    _addVertex(d.x, d.y, c.x, c.y, -1, -1, round, endCumulativeLength);
    _addVertex(d.x, d.y, c.x, c.y, 1, -1, round, endCumulativeLength);

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

  void setupJoins(List<TilePoint> points, LineJoin type) {
    if (type == LineJoin.bevel) {
      setupJoinsBevel(points);
    } else if (type == LineJoin.round) {
      setupJoinsRound(points);
    } else {
      setupJoinsBevel(points);
      setupJoinsMiter(points);
    }
  }

  void setupJoinsRound(List<TilePoint> points) {
    final joinCount = points.length - 2;

    for (int i = 0; i < joinCount; i++) {
      TilePoint p0 = points[i];
      TilePoint p1 = points[i + 1];

      double joinCumulativeLength =
          (i + 1) < cumulativeLengths.length ? cumulativeLengths[i + 1] : 0.0;

      _addVertex(p1.x, p1.y, p0.x, p0.y, -1, -1, 1, joinCumulativeLength);
      _addVertex(p1.x, p1.y, p0.x, p0.y, 1, -1, 1, joinCumulativeLength);

      int offset = i * 4;

      int a = startIndex + (2 * i);
      int b = startIndex + (2 * i) + 1;
      int c = offset + 0;
      int d = offset + 3;

      indices.addAll([c, d, b, b, d, a].map((it) => it + indexOffset));
    }
    startIndex += max(2 * joinCount, 0);
  }

  void setupJoinsBevel(List<TilePoint> points) {
    final joinCount = points.length - 2;

    for (int i = 0; i < joinCount; i++) {
      TilePoint p = points[i + 1];

      double joinCumulativeLength =
          (i + 1) < cumulativeLengths.length ? cumulativeLengths[i + 1] : 0.0;

      _addVertex(p.x, p.y, 0, 0, 0, 0, 0, joinCumulativeLength);

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

  void setupJoinsMiter(List<TilePoint> points) {
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

      _addVertex(
          c.x, c.y, c.x, c.y + 1, out.x, -out.y, 0, joinCumulativeLength);
      _addVertex(origin.x, origin.y, origin.x, origin.y + 1, -out.x, out.y, 0,
          joinCumulativeLength);

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

  void computeCumulativeDistances(List<TilePoint> points, int segmentCount,
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

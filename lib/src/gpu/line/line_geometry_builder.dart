

import 'dart:math';

import 'package:vector_tile_renderer/src/gpu/line/line_geometry.dart';

import '../../model/geometry_model.dart';
import '../../themes/style.dart';

class LineGeometryBuilder {
  int vertexOffset = 0;
  int indexOffset = 0;
  List<double> vertices = List.empty(growable: true);
  List<int> indices = List.empty(growable: true);

  int startIndex = 0;

  LineGeometry build(
      List<TileLine> lines,
      LineCap lineCaps,
      LineJoin lineJoins,
      double lineWidth,
      int extent,
      List<double>? dashLengths
      ) {
    for (var line in lines) {
      startIndex = 0;
      var points = line.points;
      var pointCount = points.length;

      setupLine(pointCount, lineCaps, lineJoins);

      vertexOffset += pointCount;
      indexOffset += startIndex;
    }

    return LineGeometry(points: lines.expand((it) => it.points), vertices: vertices, indices: indices, lineWidth: lineWidth, extent: extent, dashLengths: dashLengths);
  }

  setupLine(
      int pointCount,
      LineCap lineCaps,
      LineJoin lineJoins,
      ) {
    final segmentCount = pointCount - 1;

    setupSegments(segmentCount);
    setupEnds(segmentCount, lineCaps);
    setupJoins(segmentCount, lineJoins);
  }

  void setupSegments(int segmentCount) {
    for (int i = 0; i < segmentCount; i++) {
      double p0 = i + vertexOffset + 0;
      double p1 = i + vertexOffset + 1;

      vertices.addAll([
        p1, p0, 0, 1, 0, 0,
        p0, p1, 0,-1, 0, 0,
        p0, p1, 0, 1, 0, 0,
        p1, p0, 0,-1, 0, 0,
      ]);

      indices.addAll([0, 1, 2, 2, 3, 0].map((it) => it + (4 * i) + indexOffset));
    }
    startIndex += max(segmentCount * 4, 0);
  }

  void setupEnds(int segmentCount, LineCap type) {
    if (type == LineCap.butt) return;
    final round = type == LineCap.round ? 1.0 : 0.0;

    double a = vertexOffset + 0;
    double b = vertexOffset + 1;
    double c = vertexOffset + segmentCount - 1;
    double d = vertexOffset + segmentCount - 0;

    vertices.addAll([
      a, b, 0,-1,-1, round,
      a, b, 0, 1,-1, round,
      d, c, 0,-1,-1, round,
      d, c, 0, 1,-1, round,
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

  void setupJoins(int segmentCount, LineJoin type) {
    if (type == LineJoin.bevel) {
      setupJoinsBevel(segmentCount);
    } else if (type == LineJoin.round) {
      setupJoinsRound(segmentCount);
    } else {
      setupJoinsBevel(segmentCount);
      setupJoinsMiter(segmentCount);
    }
  }

  void setupJoinsBevel(int segmentCount) {
    final joinCount = segmentCount - 1;

    for (int i = 0; i < joinCount; i++) {
      vertices.addAll([i + vertexOffset + 1, 0, 0, 0, 0, 0]);

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

  void setupJoinsMiter(int segmentCount) {
    final joinCount = segmentCount - 1;

    for (int i = 0; i < joinCount; i++) {
      vertices.addAll([i + vertexOffset + 0, i + vertexOffset + 1, i + vertexOffset + 2, -1, 0, 0]);
      vertices.addAll([i + vertexOffset + 0, i + vertexOffset + 1, i + vertexOffset + 2, 1, 0, 0]);

      int offset = i * 4;

      indices.addAll([
        offset,
        offset + 5,
        startIndex + (2 * i) + 1,
        offset + 6,
        offset + 3,
        startIndex + (2 * i),
      ].map((it) => it + indexOffset));
    }
    startIndex += max(2 * joinCount, 0);
  }

  void setupJoinsRound(int segmentCount) {
    final joinCount = segmentCount - 1;

    for (int i = 0; i < joinCount; i++) {
      vertices.addAll([i + vertexOffset + 1, i + vertexOffset + 0, 0, -1, -1, 1]);
      vertices.addAll([i + vertexOffset + 1, i + vertexOffset + 0, 0, 1, -1, 1]);

      int offset = i * 4;

      int a = startIndex + (2 * i);
      int b = startIndex + (2 * i) + 1;
      int c = offset + 0;
      int d = offset + 3;

      indices.addAll([c, d, b, b, d, a].map((it) => it + indexOffset));
    }
    startIndex += max(2 * joinCount, 0);
  }
}
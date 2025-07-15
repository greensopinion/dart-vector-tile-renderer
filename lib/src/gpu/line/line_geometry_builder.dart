

import 'dart:math';

import 'package:vector_tile_renderer/src/gpu/line/line_geometry.dart';

import '../../model/geometry_model.dart';
import '../../themes/style.dart';

class LineGeometryBuilder {
  int vertexOffset = 0;
  int indexOffset = 0;
  List<double> finalVertices = List.empty(growable: true);
  List<int> finalIndices = List.empty(growable: true);
  List<Point<double>> finalPoints = List.empty(growable: true);

  LineGeometry build(
      List<TileLine> lines,
      LineCap lineCaps,
      LineJoin lineJoins,
      double lineWidth,
      int extent,
      List<double>? dashLengths
      ) {
    for (var line in lines) {
      var points = line.points;
      var pointCount = points.length;

      final (vertices, indices) = setupLine(pointCount, lineCaps, lineJoins);

      finalVertices.addAll(vertices);
      finalIndices.addAll(indices.map((it) => it + indexOffset));
      finalPoints.addAll(points);

      vertexOffset += pointCount;
      indexOffset += (vertices.length / 6).truncate();
    }

    return LineGeometry(points: finalPoints, vertices: finalVertices, indices: finalIndices, lineWidth: lineWidth, extent: extent, dashLengths: dashLengths);
  }

  (List<double> vertices, List<int> indices) setupLine(
      int pointCount,
      LineCap lineCaps,
      LineJoin lineJoins,
      ) {
    final vertices = <double>[];
    final indices = <int>[];

    final segmentCount = pointCount - 1;

    setupSegments(segmentCount, vertices, indices);
    setupEnds(segmentCount, vertices, indices, lineCaps);
    setupJoins(segmentCount, vertices, indices, lineJoins);

    return (vertices, indices);
  }

  void setupSegments(
      int segmentCount, List<double> vertices, List<int> indices) {
    for (int i = 0; i < segmentCount; i++) {
      double p0 = i + vertexOffset + 0;
      double p1 = i + vertexOffset + 1;

      vertices.addAll([
        p1, p0, 0, 1, 0, 0,
        p0, p1, 0,-1, 0, 0,
        p0, p1, 0, 1, 0, 0,
        p1, p0, 0,-1, 0, 0,
      ]);

      indices.addAll([0, 1, 2, 2, 3, 0].map((it) => it + (4 * i)));
    }
  }

  void setupEnds(int segmentCount, List<double> vertices, List<int> indices,
      LineCap type) {
    if (type == LineCap.butt) return;
    final round = type == LineCap.round ? 1.0 : 0.0;
    final startIndex = (vertices.length / 6).truncate();

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
    ]);
  }

  void setupJoins(int segmentCount, List<double> vertices, List<int> indices,
      LineJoin type) {
    if (type == LineJoin.bevel) {
      setupJoinsBevel(vertices, segmentCount, indices);
    } else if (type == LineJoin.round) {
      setupJoinsRound(vertices, segmentCount, indices);
    } else {
      setupJoinsBevel(vertices, segmentCount, indices);
      setupJoinsMiter(vertices, segmentCount, indices);
    }
  }

  void setupJoinsBevel(
      List<double> vertices, int segmentCount, List<int> indices) {
    final startIndex = (vertices.length / 6).truncate();
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
      ]);
    }
  }

  void setupJoinsMiter(
      List<double> vertices, int segmentCount, List<int> indices) {
    final startIndex = (vertices.length / 6).truncate();
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
      ]);
    }
  }

  void setupJoinsRound(
      List<double> vertices, int segmentCount, List<int> indices) {
    final startIndex = (vertices.length / 6).truncate();
    final joinCount = segmentCount - 1;

    for (int i = 0; i < joinCount; i++) {
      vertices.addAll([i + vertexOffset + 1, i + vertexOffset + 0, 0, -1, -1, 1]);
      vertices.addAll([i + vertexOffset + 1, i + vertexOffset + 0, 0, 1, -1, 1]);

      int offset = i * 4;

      int a = startIndex + (2 * i);
      int b = startIndex + (2 * i) + 1;
      int c = offset + 0;
      int d = offset + 3;

      indices.addAll([c, d, b, b, d, a]);
    }
  }
}
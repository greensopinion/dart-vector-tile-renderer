

import 'dart:math';

import 'package:vector_tile_renderer/src/gpu/line/line_geometry.dart';

import '../../model/geometry_model.dart';
import '../../themes/style.dart';

class LineGeometryBuilder {
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

      setupLine(points, lineCaps, lineJoins);

      indexOffset += startIndex;
    }

    return LineGeometry(points: lines.expand((it) => it.points).toList(), vertices: vertices, indices: indices, lineWidth: lineWidth, extent: extent, dashLengths: dashLengths);
  }

  setupLine(
      List<Point<double>> points,
      LineCap lineCaps,
      LineJoin lineJoins,
      ) {
    final segmentCount = points.length - 1;

    setupSegments(points, segmentCount);
    setupEnds(points, segmentCount, lineCaps);
    // setupJoins(points, segmentCount, lineJoins);
  }

  void setupSegments(List<Point<double>> points, int segmentCount) {
    for (int i = 0; i < segmentCount; i++) {
      Point<double> p0 = points[i + 0];
      Point<double> p1 = points[i + 1];

      vertices.addAll([
        p1.x, p1.y, p0.x, p0.y, 1, 0, 0,
        p0.x, p0.y, p1.x, p1.y,-1, 0, 0,
        p0.x, p0.y, p1.x, p1.y, 1, 0, 0,
        p1.x, p1.y, p0.x, p0.y,-1, 0, 0,
      ]);

      indices.addAll([0, 1, 2, 2, 3, 0].map((it) => it + (4 * i) + indexOffset));
    }
    startIndex += max(segmentCount * 4, 0);
  }

  void setupEnds(List<Point<double>> points, int segmentCount, LineCap type) {
    if (type == LineCap.butt) return;
    final round = type == LineCap.round ? 1.0 : 0.0;

    Point<double> a = points[0];
    Point<double> b = points[1];
    Point<double> c = points[segmentCount - 1];
    Point<double> d = points[segmentCount - 0];

    vertices.addAll([
      a.x, a.y, b.x, b.y,-1,-1, round,
      a.x, a.y, b.x, b.y, 1,-1, round,
      d.x, d.y, c.x, c.y,-1,-1, round,
      d.x, d.y, c.x, c.y, 1,-1, round,
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

  //
  // void setupJoins(List<Point<double>> points, int segmentCount, LineJoin type) {
  //   if (type == LineJoin.bevel) {
  //     setupJoinsBevel(segmentCount);
  //   } else if (type == LineJoin.round) {
  //     setupJoinsRound(segmentCount);
  //   } else {
  //     setupJoinsBevel(segmentCount);
  //     setupJoinsMiter(segmentCount);
  //   }
  // }
  //
  // void setupJoinsBevel(int segmentCount) {
  //   final joinCount = segmentCount - 1;
  //
  //   for (int i = 0; i < joinCount; i++) {
  //     vertices.addAll([i + vertexOffset + 1, 0, 0, 0, 0, 0]);
  //
  //     int offset = i * 4;
  //
  //     indices.addAll([
  //       offset + 5,
  //       offset,
  //       startIndex + i,
  //       offset + 3,
  //       offset + 6,
  //       startIndex + i,
  //     ].map((it) => it + indexOffset));
  //   }
  //   startIndex += max(joinCount, 0);
  // }
  //
  // void setupJoinsMiter(int segmentCount) {
  //   final joinCount = segmentCount - 1;
  //
  //   for (int i = 0; i < joinCount; i++) {
  //     vertices.addAll([i + vertexOffset + 0, i + vertexOffset + 1, i + vertexOffset + 2, -1, 0, 0]);
  //     vertices.addAll([i + vertexOffset + 0, i + vertexOffset + 1, i + vertexOffset + 2, 1, 0, 0]);
  //
  //     int offset = i * 4;
  //
  //     indices.addAll([
  //       offset,
  //       offset + 5,
  //       startIndex + (2 * i) + 1,
  //       offset + 6,
  //       offset + 3,
  //       startIndex + (2 * i),
  //     ].map((it) => it + indexOffset));
  //   }
  //   startIndex += max(2 * joinCount, 0);
  // }
  //
  // void setupJoinsRound(int segmentCount) {
  //   final joinCount = segmentCount - 1;
  //
  //   for (int i = 0; i < joinCount; i++) {
  //     vertices.addAll([i + vertexOffset + 1, i + vertexOffset + 0, 0, -1, -1, 1]);
  //     vertices.addAll([i + vertexOffset + 1, i + vertexOffset + 0, 0, 1, -1, 1]);
  //
  //     int offset = i * 4;
  //
  //     int a = startIndex + (2 * i);
  //     int b = startIndex + (2 * i) + 1;
  //     int c = offset + 0;
  //     int d = offset + 3;
  //
  //     indices.addAll([c, d, b, b, d, a].map((it) => it + indexOffset));
  //   }
  //   startIndex += max(2 * joinCount, 0);
  // }
}
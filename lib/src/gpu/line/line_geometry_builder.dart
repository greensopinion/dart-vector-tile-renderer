import 'dart:math';
import 'dart:typed_data';

import 'package:vector_math/vector_math.dart';

import '../../model/geometry_model.dart';
import '../../themes/style.dart';

class LineGeometryBuilder {
  int indexOffset = 0;
  final BytesBuilder _vertexBytesBuilder = BytesBuilder(copy: false);
  final BytesBuilder _indexBytesBuilder = BytesBuilder(copy: false);
  Float32List _cumulativeLengths = Float32List(0);

  int startIndex = 0;

  // Reusable list for building indices to avoid .map().toList() allocations
  final List<int> _tempIndices = <int>[];

  // Reusable Vector2 objects for setupJoinsMiter to avoid allocations
  final Vector2 _v2Temp1 = Vector2.zero();
  final Vector2 _v2Temp2 = Vector2.zero();
  final Vector2 _v2Temp3 = Vector2.zero();
  final Vector2 _v2Temp4 = Vector2.zero();

  _addVertices(Float32List vertices) {
    _vertexBytesBuilder.add(vertices.buffer.asUint8List());
  }

  void _addIndices(List<int> indexList) {
    final indexData = Uint16List.fromList(indexList);
    _indexBytesBuilder.add(indexData.buffer.asUint8List());
  }

  (ByteData, ByteData) build(
      List<List<TilePoint>> lines, LineCap lineCaps, LineJoin lineJoins) {
    double totalCumulativeLength = 0.0;

    for (var line in lines) {
      startIndex = 0;

      setupLine(line, lineCaps, lineJoins, totalCumulativeLength);

      if (_cumulativeLengths.isNotEmpty) {
        totalCumulativeLength = _cumulativeLengths.last;
      }

      indexOffset += startIndex;
    }

    return (
      ByteData.sublistView(_vertexBytesBuilder.takeBytes()),
      ByteData.sublistView(_indexBytesBuilder.takeBytes())
    );
  }

  setupLine(
    List<TilePoint> points,
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

  void setupSegments(List<TilePoint> points, int segmentCount) {
    for (int i = 0; i < segmentCount; i++) {
      TilePoint p0 = points[i];
      TilePoint p1 = points[i + 1];

      double cumulativeLength0 = (i < _cumulativeLengths.length ? _cumulativeLengths[i] : 0.0) / 32.0;
      double cumulativeLength1 = ((i + 1) < _cumulativeLengths.length ? _cumulativeLengths[i + 1] : 0.0) / 32.0;

      final vertices = Float32List(32);
      vertices[0] = p1.x;
      vertices[1] = p1.y;
      vertices[2] = p0.x;
      vertices[3] = p0.y;
      vertices[4] = 1;
      vertices[5] = 0;
      vertices[6] = 0;
      vertices[7] = cumulativeLength1;
      vertices[8] = p0.x;
      vertices[9] = p0.y;
      vertices[10] = p1.x;
      vertices[11] = p1.y;
      vertices[12] = -1;
      vertices[13] = 0;
      vertices[14] = 0;
      vertices[15] = cumulativeLength0;
      vertices[16] = p0.x;
      vertices[17] = p0.y;
      vertices[18] = p1.x;
      vertices[19] = p1.y;
      vertices[20] = 1;
      vertices[21] = 0;
      vertices[22] = 0;
      vertices[23] = cumulativeLength0;
      vertices[24] = p1.x;
      vertices[25] = p1.y;
      vertices[26] = p0.x;
      vertices[27] = p0.y;
      vertices[28] = -1;
      vertices[29] = 0;
      vertices[30] = 0;
      vertices[31] = cumulativeLength1;
      _addVertices(vertices);

      // Use reusable list to avoid .map().toList() allocation
      _tempIndices.clear();
      final base = (4 * i) + indexOffset;
      _tempIndices.addAll([base, base + 1, base + 2, base + 2, base + 3, base]);
      _addIndices(_tempIndices);
    }
    startIndex += max(segmentCount * 4, 0);
  }

  void setupEnds(List<TilePoint> points, int segmentCount, LineCap type) {
    if (type == LineCap.butt) return;
    final round = type == LineCap.round ? 1.0 : 0.0;

    TilePoint a = points[0];
    TilePoint b = points[1];
    TilePoint c = points[segmentCount - 1];
    TilePoint d = points[segmentCount];

    double startCumulativeLength = (_cumulativeLengths.isNotEmpty ? _cumulativeLengths.first : 0.0) / 32.0;
    double endCumulativeLength = (_cumulativeLengths.isNotEmpty ? _cumulativeLengths.last : 0.0) / 32.0;

    final vertices = Float32List(32);
    vertices[0] = a.x;
    vertices[1] = a.y;
    vertices[2] = b.x;
    vertices[3] = b.y;
    vertices[4] = -1;
    vertices[5] = -1;
    vertices[6] = round;
    vertices[7] = startCumulativeLength;
    vertices[8] = a.x;
    vertices[9] = a.y;
    vertices[10] = b.x;
    vertices[11] = b.y;
    vertices[12] = 1;
    vertices[13] = -1;
    vertices[14] = round;
    vertices[15] = startCumulativeLength;
    vertices[16] = d.x;
    vertices[17] = d.y;
    vertices[18] = c.x;
    vertices[19] = c.y;
    vertices[20] = -1;
    vertices[21] = -1;
    vertices[22] = round;
    vertices[23] = endCumulativeLength;
    vertices[24] = d.x;
    vertices[25] = d.y;
    vertices[26] = c.x;
    vertices[27] = c.y;
    vertices[28] = 1;
    vertices[29] = -1;
    vertices[30] = round;
    vertices[31] = endCumulativeLength;
    _addVertices(vertices);

    _tempIndices.clear();
    _tempIndices.addAll([
      startIndex + indexOffset,
      startIndex + 1 + indexOffset,
      1 + indexOffset,
      startIndex + 1 + indexOffset,
      2 + indexOffset,
      1 + indexOffset,
      startIndex + 3 + indexOffset,
      startIndex - 4 + indexOffset,
      startIndex - 1 + indexOffset,
      startIndex + 2 + indexOffset,
      startIndex + 3 + indexOffset,
      startIndex - 1 + indexOffset,
    ]);
    _addIndices(_tempIndices);
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

      double joinCumulativeLength = ((i + 1) < _cumulativeLengths.length ? _cumulativeLengths[i + 1] : 0.0) / 32.0;

      final vertices = Float32List(16);
      vertices[0] = p1.x;
      vertices[1] = p1.y;
      vertices[2] = p0.x;
      vertices[3] = p0.y;
      vertices[4] = -1;
      vertices[5] = -1;
      vertices[6] = 1;
      vertices[7] = joinCumulativeLength;
      vertices[8] = p1.x;
      vertices[9] = p1.y;
      vertices[10] = p0.x;
      vertices[11] = p0.y;
      vertices[12] = 1;
      vertices[13] = -1;
      vertices[14] = 1;
      vertices[15] = joinCumulativeLength;
      _addVertices(vertices);

      int offset = i * 4;

      int a = startIndex + (2 * i);
      int b = startIndex + (2 * i) + 1;
      int c = offset + 0;
      int d = offset + 3;

      // Use reusable list to avoid .map().toList() allocation
      _tempIndices.clear();
      _tempIndices.addAll([c + indexOffset, d + indexOffset, b + indexOffset,
                          b + indexOffset, d + indexOffset, a + indexOffset]);
      _addIndices(_tempIndices);
    }
    startIndex += max(2 * joinCount, 0);
  }

  void setupJoinsBevel(List<TilePoint> points) {
    final joinCount = points.length - 2;

    for (int i = 0; i < joinCount; i++) {
      TilePoint p = points[i + 1];

      double joinCumulativeLength = ((i + 1) < _cumulativeLengths.length ? _cumulativeLengths[i + 1] : 0.0) / 32.0;

      final vertices = Float32List(8);
      vertices[0] = p.x;
      vertices[1] = p.y;
      vertices[2] = 0;
      vertices[3] = 0;
      vertices[4] = 0;
      vertices[5] = 0;
      vertices[6] = 0;
      vertices[7] = joinCumulativeLength;
      _addVertices(vertices);

      int offset = i * 4;

      // Use reusable list to avoid .map().toList() allocation
      _tempIndices.clear();
      _tempIndices.addAll([
        offset + 5 + indexOffset,
        offset + indexOffset,
        startIndex + i + indexOffset,
        offset + 3 + indexOffset,
        offset + 6 + indexOffset,
        startIndex + i + indexOffset,
      ]);
      _addIndices(_tempIndices);
    }
    startIndex += max(joinCount, 0);
  }

  void setupJoinsMiter(List<TilePoint> points) {
    final joinCount = points.length - 2;

    for (int i = 0; i < joinCount; i++) {
      // Reuse Vector2 objects instead of creating new ones
      _v2Temp1.setValues(points[i].x, points[i].y); // p0
      _v2Temp2.setValues(points[i + 2].x, points[i + 2].y); // p1
      _v2Temp3.setValues(points[i + 1].x, points[i + 1].y); // origin

      // Calculate a = perp((p0 - origin).normalized(), -1)
      _v2Temp4.setFrom(_v2Temp1); // p0
      _v2Temp4.sub(_v2Temp3); // p0 - origin
      _v2Temp4.normalize();
      // perp with flip = -1: (v.y * -1, -v.x * -1) = (-v.y, v.x)
      final aX = -_v2Temp4.y;
      final aY = _v2Temp4.x;

      // Reuse _v2Temp4 for b = perp((p1 - origin).normalized(), 1)
      _v2Temp4.setFrom(_v2Temp2); // p1
      _v2Temp4.sub(_v2Temp3); // p1 - origin
      _v2Temp4.normalize();
      // perp with flip = 1: (v.y * 1, -v.x * 1) = (v.y, -v.x)
      final bX = _v2Temp4.y;
      final bY = -_v2Temp4.x;

      // Check dot product j = a.dot(b)
      final j = aX * bX + aY * bY;
      if (j > 0.9999 || j < -0.9999) {
        startIndex -= 2;
        continue;
      }

      // a = a + origin, b = b + origin
      final finalAX = aX + _v2Temp3.x;
      final finalAY = aY + _v2Temp3.y;
      final finalBX = bX + _v2Temp3.x;
      final finalBY = bY + _v2Temp3.y;

      // c = (a + b) * 0.5
      final cX = (finalAX + finalBX) * 0.5;
      final cY = (finalAY + finalBY) * 0.5;

      // vec = c - origin
      final vecX = cX - _v2Temp3.x;
      final vecY = cY - _v2Temp3.y;

      // resultLength = (c - a).length2 / vec.length2
      final diffX = cX - finalAX;
      final diffY = cY - finalAY;
      final vecLength2 = vecX * vecX + vecY * vecY;
      final resultLength = (diffX * diffX + diffY * diffY) / vecLength2;

      // out = vec * (1 + resultLength)
      final scale = 1 + resultLength;
      final outX = vecX * scale;
      final outY = vecY * scale;

      double joinCumulativeLength = ((i + 1) < _cumulativeLengths.length ? _cumulativeLengths[i + 1] : 0.0) / 32.0;

      final vertices = Float32List(16);
      vertices[0] = cX;
      vertices[1] = cY;
      vertices[2] = cX;
      vertices[3] = cY + 1;
      vertices[4] = outX;
      vertices[5] = -outY;
      vertices[6] = 0;
      vertices[7] = joinCumulativeLength;
      vertices[8] = _v2Temp3.x;
      vertices[9] = _v2Temp3.y;
      vertices[10] = _v2Temp3.x;
      vertices[11] = _v2Temp3.y + 1;
      vertices[12] = -outX;
      vertices[13] = outY;
      vertices[14] = 0;
      vertices[15] = joinCumulativeLength;
      _addVertices(vertices);

      int offset = i * 4;

      // Use reusable list to avoid .map().toList() allocation
      _tempIndices.clear();
      _tempIndices.addAll([
        offset + 6 + indexOffset,
        offset + 3 + indexOffset,
        startIndex + (2 * i) + indexOffset,
        offset + indexOffset,
        offset + 5 + indexOffset,
        startIndex + (2 * i) + 1 + indexOffset,
      ]);
      _addIndices(_tempIndices);
    }
    startIndex += max(2 * joinCount, 0);
  }

  void computeCumulativeDistances(List<TilePoint> points, int segmentCount,
      double startingCumulativeLength) {
    // Reuse existing buffer if possible to avoid allocation
    if (_cumulativeLengths.length != points.length) {
      _cumulativeLengths = Float32List(points.length);
    }
    _cumulativeLengths[0] = startingCumulativeLength;

    double sum = startingCumulativeLength;
    for (int i = 1; i < points.length; i++) {
      final dx = points[i].x - points[i - 1].x;
      final dy = points[i].y - points[i - 1].y;
      final segmentLength = sqrt(dx * dx + dy * dy);
      sum += segmentLength;
      _cumulativeLengths[i] = sum;
    }
  }
}

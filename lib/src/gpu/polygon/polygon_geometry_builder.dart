import 'dart:typed_data';
import 'package:dart_earcut/dart_earcut.dart';
import '../../model/geometry_model.dart';

class PolygonGeometryBuilder {
  (ByteData, ByteData) build(List<TilePolygon> polygons) {
    final vertexBytesBuilder = BytesBuilder(copy: false);
    final indexBytesBuilder = BytesBuilder(copy: false);

    int offset = 0;

    for (var polygon in polygons) {
      final (vtx, idx) = _triangulate(polygon, offset);

      offset += vtx.length ~/ 3;

      vertexBytesBuilder.add(vtx.buffer.asUint8List());
      indexBytesBuilder.add(idx.buffer.asUint8List());
    }

    return (
      ByteData.sublistView(vertexBytesBuilder.takeBytes()),
      ByteData.sublistView(indexBytesBuilder.takeBytes())
    );
  }

  (Float32List, Uint16List) _triangulate(TilePolygon polygon, int offset) {
    final flat = <double>[];
    final holeIndices = <int>[];

    for (int i = 0; i < polygon.rings.length; i++) {
      final ring = polygon.rings[i];

      if (i > 0) {
        holeIndices.add(flat.length ~/ 2);
      }

      for (final point in ring.points) {
        flat.add(point.x.toDouble());
        flat.add(point.y.toDouble());
      }
    }

    final indices = Earcut.triangulateRaw(flat, holeIndices: holeIndices);
    final vertices = Float32List((flat.length * 1.5).truncate());

    int ptr = 0;

    for (var i = 0; i < flat.length; i += 2) {
      final x = flat[i];
      final y = flat[i + 1];

      vertices[ptr] = x / 2048.0 - 1;
      vertices[ptr + 1] = 1 - y / 2048.0;
      vertices[ptr + 2] = 0.0;

      ptr += 3;
    }

    return (
      vertices,
      Uint16List.fromList(
          indices.map((it) => it + offset).toList(growable: false))
    );
  }
}

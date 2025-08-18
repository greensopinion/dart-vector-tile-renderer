
import 'dart:typed_data';

import 'bucket_unpacker.dart';

class TileRenderData {
  final List<PackedMesh> data = [];

  void addMesh(PackedMesh mesh) {
    data.add(mesh);
  }

}

class PackedMesh {
  final PackedGeometry geometry;
  final PackedMaterial material;

  PackedMesh(this.geometry, this.material);
}

class PackedGeometry {
  final ByteData vertices;
  final ByteData indices;
  final ByteData? uniform;
  final GeometryType type;

  PackedGeometry({
    required this.vertices,
    required this.indices,
    this.uniform,
    required this.type
  });
}

class PackedMaterial {
  final ByteData? uniform;
  final MaterialType type;

  PackedMaterial({this.uniform, required this.type});
}
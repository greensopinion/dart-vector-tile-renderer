
import 'dart:typed_data';

class TileRenderData {
  final List<PackedMesh> data = [];

}

class PackedMesh {
  final PackedGeometry geometry;
  final PackedMaterial material;

  PackedMesh(this.geometry, this.material);
}

abstract class PackedGeometry {
  final ByteData vertices;
  final ByteData indices;
  final ByteData? uniform;

  PackedGeometry({
    required this.vertices,
    required this.indices,
    this.uniform
  });
}
abstract class PackedMaterial {
  final ByteData? uniform;

  PackedMaterial({this.uniform});
}
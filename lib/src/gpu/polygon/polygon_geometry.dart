import 'package:flutter_gpu/gpu.dart';

import '../shaders.dart';
import '../tile_geometry.dart';
import '../tile_render_data.dart';

class PolygonGeometry extends TileGeometry {
  PolygonGeometry(PackedGeometry packed) {
    setVertexShader(shaderLibrary["SimpleVertex"]!);

    final vertexCount = packed.vertices.lengthInBytes ~/ 12;

    uploadVertexData(packed.vertices, vertexCount, packed.indices,
        indexType: IndexType.int32);
  }
}

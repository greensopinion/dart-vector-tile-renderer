import 'package:flutter_scene/scene.dart';

import '../shaders.dart';
import '../tile_render_data.dart';

class TextGeometry extends UnskinnedGeometry {
  static const vertexSize = 16;

  TextGeometry(PackedGeometry packed) {
    setVertexShader(shaderLibrary["CurvedTextVertex"]!);

    final vertexCount = packed.vertices.lengthInBytes ~/ (vertexSize * 4);

    uploadVertexData(packed.vertices, vertexCount, packed.indices);
  }
}

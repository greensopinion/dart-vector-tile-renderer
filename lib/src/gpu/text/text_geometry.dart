import 'dart:typed_data';
import 'package:flutter_scene/scene.dart';
import 'package:vector_tile_renderer/src/gpu/shaders.dart';

class TextGeometry extends UnskinnedGeometry {
  TextGeometry(ByteData vertices, ByteData indices, int floatsPerVertex) {
    setVertexShader(shaderLibrary["TextVertex"]!);

    final vertexCount = vertices.lengthInBytes ~/ (4 * floatsPerVertex);

    uploadVertexData(
        vertices, vertexCount, indices
    );
  }
}

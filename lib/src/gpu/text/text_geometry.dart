import 'dart:typed_data';
import 'package:flutter_scene/scene.dart';
import 'package:vector_tile_renderer/src/gpu/shaders.dart';

class TextGeometry extends UnskinnedGeometry {
  TextGeometry(ByteData vertices, ByteData indices) {
    setVertexShader(shaderLibrary["TextVertex"]!);

    final vertexCount = vertices.lengthInBytes ~/ 20;

    uploadVertexData(
        vertices, vertexCount, indices
    );
  }
}

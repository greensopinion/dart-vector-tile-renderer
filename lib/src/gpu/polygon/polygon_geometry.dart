import 'dart:typed_data';
import 'package:flutter_scene/scene.dart';
import 'package:vector_tile_renderer/src/gpu/shaders.dart';

class PolygonGeometry extends UnskinnedGeometry {
  PolygonGeometry(ByteData vertices, ByteData indices) {
    setVertexShader(shaderLibrary["SimpleVertex"]!);

    final vertexCount = vertices.lengthInBytes ~/ 12;

    uploadVertexData(
      vertices, vertexCount, indices
    );
  }
}

import 'dart:typed_data';
import 'package:flutter_scene/scene.dart';
import 'package:vector_tile_renderer/src/gpu/shaders.dart';
import 'package:vector_tile_renderer/src/gpu/tile_render_data.dart';

class PolygonGeometry extends UnskinnedGeometry {
  PolygonGeometry(PackedGeometry packed) {
    setVertexShader(shaderLibrary["SimpleVertex"]!);

    final vertexCount = packed.vertices.lengthInBytes ~/ 12;

    uploadVertexData(
        packed.vertices,
        vertexCount,
        packed.indices
    );
  }
}

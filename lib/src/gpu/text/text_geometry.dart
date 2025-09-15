import 'dart:typed_data';
import 'package:flutter_gpu/gpu.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart';
import 'package:vector_tile_renderer/src/gpu/tile_render_data.dart';
import '../shaders.dart';

class TextGeometry extends UnskinnedGeometry {

  static const VERTEX_SIZE = 8;

  TextGeometry(PackedGeometry packed) {
    setVertexShader(shaderLibrary["TextVertex"]!);

    final vertexCount = packed.vertices.lengthInBytes ~/ (VERTEX_SIZE * 4);

    uploadVertexData(packed.vertices, vertexCount, packed.indices);
  }
}
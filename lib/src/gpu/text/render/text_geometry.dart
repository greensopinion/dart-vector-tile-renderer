import 'dart:typed_data';

import 'package:flutter_gpu/gpu.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart';

import '../../shaders.dart';
import '../../tile_render_data.dart';

class TextGeometry extends UnskinnedGeometry {
  static const vertexSize = 10;
  late final ByteData _uniform;

  TextGeometry(PackedGeometry packed) {
    setVertexShader(shaderLibrary["TextVertex"]!);
    _uniform = packed.uniform!;

    final vertexCount = packed.vertices.lengthInBytes ~/ (vertexSize * 4);

    uploadVertexData(packed.vertices, vertexCount, packed.indices);
  }

  @override
  void bind(RenderPass pass, HostBuffer transientsBuffer,
      Matrix4 modelTransform, Matrix4 cameraTransform, Vector3 cameraPosition) {
    super.bind(pass, transientsBuffer, modelTransform, cameraTransform,
        cameraPosition);

    final uniformSlot = vertexShader.getUniformSlot('TileOffset');
    final uniformView = transientsBuffer.emplace(_uniform);
    pass.bindUniform(uniformSlot, uniformView);
  }
}

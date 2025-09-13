import 'dart:typed_data';
import 'package:flutter_gpu/gpu.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart';
import 'package:vector_tile_renderer/src/gpu/tile_render_data.dart';
import '../shaders.dart';

class TextGeometry extends UnskinnedGeometry {
  late final ByteData _uniform;

  TextGeometry(PackedGeometry packed) {
    setVertexShader(shaderLibrary["TextVertex"]!);

    final uniform = packed.uniform;
    if (uniform != null) {
      _uniform = uniform;
    }

    final vertexCount = packed.vertices.lengthInBytes ~/ 32;

    uploadVertexData(packed.vertices, vertexCount, packed.indices);
  }

  @override
  void bind(RenderPass pass, HostBuffer transientsBuffer,
      Matrix4 modelTransform, Matrix4 cameraTransform, Vector3 cameraPosition) {
    super.bind(pass, transientsBuffer, modelTransform, cameraTransform,
        cameraPosition);

    final lineGeometrySlot = vertexShader.getUniformSlot('TextGeometry');
    final lineGeometryView = transientsBuffer.emplace(_uniform);
    pass.bindUniform(lineGeometrySlot, lineGeometryView);
  }
}

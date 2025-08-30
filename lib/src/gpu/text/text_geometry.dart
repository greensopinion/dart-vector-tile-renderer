import 'dart:typed_data';
import 'package:flutter_gpu/gpu.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart';
import '../shaders.dart';

class TextGeometry extends UnskinnedGeometry {
  final ByteData _uniform;

  TextGeometry(ByteData vertices, ByteData indices, this._uniform) {
    setVertexShader(shaderLibrary["TextVertex"]!);

    final vertexCount = vertices.lengthInBytes ~/ 32;

    uploadVertexData(vertices, vertexCount, indices);
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

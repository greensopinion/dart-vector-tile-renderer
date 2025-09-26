import 'dart:typed_data';

import 'package:flutter_gpu/gpu.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart';

import '../shaders.dart';
import '../tile_render_data.dart';

class LineGeometry extends UnskinnedGeometry {
  late double lineWidth;
  late int extent;
  late List<double>? dashLengths;
  late final ByteData _uniform;

  LineGeometry(PackedGeometry packed) {
    setVertexShader(shaderLibrary["LineVertex"]!);

    _uniform = packed.uniform!;

    final vertexCount = packed.vertices.lengthInBytes ~/ 32;
    uploadVertexData(packed.vertices, vertexCount, packed.indices, indexType: IndexType.int32);
  }

  @override
  void bind(RenderPass pass, HostBuffer transientsBuffer,
      Matrix4 modelTransform, Matrix4 cameraTransform, Vector3 cameraPosition) {
    super.bind(pass, transientsBuffer, modelTransform, cameraTransform,
        cameraPosition);

    final lineGeometrySlot = vertexShader.getUniformSlot('LineGeometry');
    final lineGeometryView = transientsBuffer.emplace(_uniform);
    pass.bindUniform(lineGeometrySlot, lineGeometryView);
  }
}

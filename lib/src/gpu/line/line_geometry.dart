import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_gpu/gpu.dart';
import 'package:flutter_gpu/gpu.dart' as gpu;
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart';
import 'package:vector_tile_renderer/src/gpu/shaders.dart';

class LineGeometry extends UnskinnedGeometry {
  late double lineWidth;
  late int extent;
  late List<double>? dashLengths;

  LineGeometry(ByteData vertices, ByteData indices) {
    setVertexShader(shaderLibrary["LineVertex"]!);

    final vertexCount = vertices.lengthInBytes ~/ 32;

    uploadVertexData(vertices, vertexCount, indices);
  }

  @override
  void bind(RenderPass pass, HostBuffer transientsBuffer,
      Matrix4 modelTransform, Matrix4 cameraTransform, Vector3 cameraPosition) {
    super.bind(pass, transientsBuffer, modelTransform, cameraTransform,
        cameraPosition);

    bindLineConfig(transientsBuffer, pass);

    pass.setPrimitiveType(gpu.PrimitiveType.triangle);
  }

  void bindLineConfig(HostBuffer transientsBuffer, RenderPass pass) {
    final double extentScale = extent / 2;
    
    final lineGeometrySlot = vertexShader.getUniformSlot('LineGeometry');
    final lineGeometryView = transientsBuffer.emplace(
        Float32List.fromList([
          lineWidth / 256,  // width
          extentScale,      // extentScale
        ]).buffer.asByteData());
    pass.bindUniform(lineGeometrySlot, lineGeometryView);
  }
}

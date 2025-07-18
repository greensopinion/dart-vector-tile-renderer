import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_gpu/gpu.dart';
import 'package:flutter_gpu/gpu.dart' as gpu;
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart';
import 'package:vector_tile_renderer/src/gpu/shaders.dart';

class LineGeometry extends UnskinnedGeometry {
  final List<Point<double>> points;
  final List<double> vertices;
  final List<int> indices;
  final double lineWidth;
  final int extent;
  final List<double>? dashLengths;

  LineGeometry(
      {required this.points,
      required this.vertices,
      required this.indices,
      required this.lineWidth,
      required this.extent,
      this.dashLengths}) {
    setVertexShader(shaderLibrary["LineVertex"]!);

    uploadVertexData(
      ByteData.sublistView(Float32List.fromList(vertices)),
      (vertices.length / 7).truncate(),
      ByteData.sublistView(Uint16List.fromList(indices)),
      indexType: gpu.IndexType.int16,
    );
  }

  @override
  void bind(RenderPass pass, HostBuffer transientsBuffer, Matrix4 modelTransform, Matrix4 cameraTransform,
      Vector3 cameraPosition) {
    super.bind(pass, transientsBuffer, modelTransform, cameraTransform, cameraPosition);

    bindLineStyle(transientsBuffer, pass);

    pass.setPrimitiveType(gpu.PrimitiveType.triangle);

    final double extentScale = extent / 2;
    final extentScalingSlot = vertexShader.getUniformSlot('extentScalings');
    final extentScalingView = transientsBuffer.emplace(Float32List.fromList([extentScale]).buffer.asByteData());
    pass.bindUniform(extentScalingSlot, extentScalingView);
  }

  void bindLineStyle(HostBuffer transientsBuffer, RenderPass pass) {
    final lineStyleSlot = vertexShader.getUniformSlot('LineStyle');
    final lineStyleView = transientsBuffer.emplace(Float32List.fromList([lineWidth / 256]).buffer.asByteData());
    pass.bindUniform(lineStyleSlot, lineStyleView);
  }
}

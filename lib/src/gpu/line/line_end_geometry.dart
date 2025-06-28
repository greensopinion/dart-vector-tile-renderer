
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_gpu/gpu.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart';

import '../shaders.dart';

class LineEndGeometry extends UnskinnedGeometry {
  late final List<Point<double>> points;
  final double lineWidth;
  final int extent;

  LineEndGeometry(
      {required Iterable<Point<double>> points,
      required this.lineWidth,
      required this.extent}) {
    final p = points.toList();
    this.points = [p[0], p[1], p[p.length - 2], p[p.length - 1]];
    setVertexShader(shaderLibrary["LineEndVertex"]!);

    List<double> vertices = getVertices();

    uploadVertexData(
      ByteData.sublistView(Float32List.fromList(vertices)),
      (vertices.length / 5).truncate(),
      ByteData.sublistView(Uint16List.fromList(getIndices())),
      indexType: IndexType.int16,
    );
  }

  List<double> getVertices() {
    return [
      0, 1, 0, -1, 0,
      0, 1, 0, -1, 1,
      0, 1, 0,  1, 1,
      0, 1, 0,  1, 0,
      3, 2, 0, -1, 0,
      3, 2, 0, -1, 1,
      3, 2, 0,  1, 1,
      3, 2, 0,  1, 0
    ];
  }

  List<int> getIndices() {
    return [
      0, 2, 1,
      2, 0, 3,
      4, 6, 5,
      6, 4, 7
    ];
  }

  @override
  void bind(RenderPass pass, HostBuffer transientsBuffer,
      Matrix4 modelTransform, Matrix4 cameraTransform, Vector3 cameraPosition) {
    super.bind(pass, transientsBuffer, modelTransform, cameraTransform,
        cameraPosition);

    bindPositions(transientsBuffer, pass);
    bindLineStyle(transientsBuffer, pass);

    pass.setPrimitiveType(PrimitiveType.triangle);
  }

  void bindPositions(HostBuffer transientsBuffer, RenderPass pass) {
    final double extentScale = 2 / extent;
    final linePositions = Float32List.fromList(points
        .expand((it) =>
            [(it.x * extentScale) - 1, 1 - (it.y * extentScale), 0.0, 0.0])
        .toList());
    final linePositionsSlot = vertexShader.getUniformSlot('LinePositions');

    final linePositionsView = transientsBuffer.emplace(
      linePositions.buffer.asByteData(),
    );

    pass.bindUniform(linePositionsSlot, linePositionsView);
  }

  void bindLineStyle(HostBuffer transientsBuffer, RenderPass pass) {
    final lineStyleSlot = vertexShader.getUniformSlot('LineStyle');
    final lineStyleView = transientsBuffer
        .emplace(Float32List.fromList([lineWidth / 256]).buffer.asByteData());
    pass.bindUniform(lineStyleSlot, lineStyleView);
  }
}

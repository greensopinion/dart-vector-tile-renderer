
import 'dart:math';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:flutter_gpu/gpu.dart';
import 'package:flutter_gpu/gpu.dart' as gpu;
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart';
import 'package:vector_tile_renderer/src/gpu/shaders.dart';

class LineGeometry extends UnskinnedGeometry {
  final Iterable<Point<double>> points;
  double lineWidth;

  LineGeometry(this.points, this.lineWidth) {
    setVertexShader(shaderLibrary["LineVertex"]!);

    final pointCount = points.length;
    if (pointCount > 1) {
      List<double> vertices = List.empty(growable: true);
      List<int> indices = List.empty(growable: true);

      const double above = 1;
      const double below = -1;

      final segmentCount = pointCount - 1;

      for (int i = 0; i < segmentCount; i++) {
        double p0 = i + 0;
        double p1 = i + 1;

        vertices.addAll([p1, above, p0]);
        vertices.addAll([p0, above, p1]);
        vertices.addAll([p0, below, p1]);
        vertices.addAll([p1, below, p0]);

        indices.addAll([
          0, 1, 2, 2, 3, 0
        ].map((it) => it + (4 * i)));
      }

      uploadVertexData(
        ByteData.sublistView(Float32List.fromList(vertices)),
        8,
        ByteData.sublistView(Uint16List.fromList(indices)),
        indexType: gpu.IndexType.int16,
      );
    }
  }


  @override
  void bind(RenderPass pass, HostBuffer transientsBuffer, Matrix4 modelTransform, Matrix4 cameraTransform, Vector3 cameraPosition) {
    super.bind(pass, transientsBuffer, modelTransform, cameraTransform, cameraPosition);

    bindPositions(transientsBuffer, pass);
    bindLineStyle(transientsBuffer, pass);
  }

  void bindPositions(HostBuffer transientsBuffer, RenderPass pass) {
    final linePositions = Float32List.fromList(points.map((it) => [it.x, it.y]).flattened.toList());
    final linePositionsSlot = vertexShader.getUniformSlot('LinePositions');

    final linePositionsView = transientsBuffer.emplace(
      linePositions.buffer.asByteData(0, 4096),
    );

    pass.bindUniform(linePositionsSlot, linePositionsView);
  }

  void bindLineStyle(HostBuffer transientsBuffer, RenderPass pass) {
    final lineStyleSlot = vertexShader.getUniformSlot('LineStyle');
    final lineStyleView = transientsBuffer.emplace(Float32List.fromList([lineWidth]).buffer.asByteData());
    pass.bindUniform(lineStyleSlot, lineStyleView);
  }
}

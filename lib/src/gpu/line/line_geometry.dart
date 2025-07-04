
import 'dart:math';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:flutter_gpu/gpu.dart';
import 'package:flutter_gpu/gpu.dart' as gpu;
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart';
import 'package:vector_tile_renderer/src/gpu/shaders.dart';
import 'package:vector_tile_renderer/src/themes/style.dart';

class LineGeometry extends UnskinnedGeometry {
  final Iterable<Point<double>> points;
  final double lineWidth;
  final int extent;

  LineGeometry({required this.points, required this.lineWidth, required this.extent}) {
    setVertexShader(shaderLibrary["LineVertex"]!);

    final pointCount = points.length;
    if (pointCount > 1) {
      List<double> vertices = List.empty(growable: true);
      List<int> indices = List.empty(growable: true);

      final segmentCount = pointCount - 1;

      setupSegments(segmentCount, vertices, indices);
      setupEnds(segmentCount, vertices, indices, LineCap.round);
      setupJoins(segmentCount, vertices, indices, LineJoin.miter);

      uploadVertexData(
        ByteData.sublistView(Float32List.fromList(vertices)),
        (vertices.length / 6).truncate(),
        ByteData.sublistView(Uint16List.fromList(indices)),
        indexType: gpu.IndexType.int16,
      );
    }
  }

  void setupSegments(int segmentCount, List<double> vertices, List<int> indices) {
    for (int i = 0; i < segmentCount; i++) {
      double p0 = i + 0;
      double p1 = i + 1;

      vertices.addAll([
        p1, p0, 0, 1, 0, 0,
        p0, p1, 0,-1, 0, 0,
        p0, p1, 0, 1, 0, 0,
        p1, p0, 0,-1, 0, 0,
      ]);

      indices.addAll([
        0, 1, 2, 2, 3, 0
      ].map((it) => it + (4 * i)));
    }
  }

  void setupEnds(int segmentCount, List<double> vertices, List<int> indices, LineCap type) {
    if (type == LineCap.butt) return;
    final round = type == LineCap.round ? 1.0 : 0.0;
    final startIndex = (vertices.length / 6).truncate();

    double a = segmentCount - 1;
    double b = segmentCount - 0;

    vertices.addAll([
        0, 1, 0, -1, -1, round,
        0, 1, 0,  1, -1, round,
        b, a, 0, -1, -1, round,
        b, a, 0,  1, -1, round,
    ]);

    indices.addAll([
      startIndex, startIndex + 1, 1,
      startIndex + 1, 2, 1,
      startIndex + 3, startIndex - 4, startIndex - 1,
      startIndex + 2, startIndex + 3, startIndex - 1,
    ]);
  }

  void setupJoins(int segmentCount, List<double> vertices, List<int> indices, LineJoin type) {
    if (type == LineJoin.bevel) {
      setupJoinsBevel(vertices, segmentCount, indices);
    } else if (type == LineJoin.round) {
      setupJoinsRound(vertices, segmentCount, indices);
    } else {
      setupJoinsBevel(vertices, segmentCount, indices);
      setupJoinsMiter(vertices, segmentCount, indices);
    }
  }

  void setupJoinsBevel(List<double> vertices, int segmentCount, List<int> indices) {
    final startIndex = (vertices.length / 6).truncate();
    final joinCount = segmentCount - 1;

    for (int i = 0; i < joinCount; i++) {
      vertices.addAll([i + 1, 0, 0, 0, 0, 0]);

      int offset = i * 4;

      indices.addAll([
        offset + 5,
        offset,
        startIndex + i,
        offset + 3,
        offset + 6,
        startIndex + i,
      ]);
    }
  }

  void setupJoinsMiter(List<double> vertices, int segmentCount, List<int> indices) {
    final startIndex = (vertices.length / 6).truncate();
    final joinCount = segmentCount - 1;

    for (int i = 0; i < joinCount; i++) {
      vertices.addAll([i + 0, i + 1, i + 2, -1, 0, 0]);
      vertices.addAll([i + 0, i + 1, i + 2, 1, 0, 0]);


      int offset = i * 4;

      indices.addAll([
        offset,
        offset + 5,
        startIndex + (2 * i) + 1,
        offset + 6,
        offset + 3,
        startIndex + (2 * i),
      ]);
    }
  }

  void setupJoinsRound(List<double> vertices, int segmentCount, List<int> indices) {
    final startIndex = (vertices.length / 6).truncate();
    final joinCount = segmentCount - 1;

    for (int i = 0; i < joinCount; i++) {
      vertices.addAll([i + 1, i + 0, 0,-1, -1, 1]);
      vertices.addAll([i + 1, i + 0, 0, 1, -1, 1]);

      int offset = i * 4;

      int a = startIndex + (2 * i);
      int b = startIndex + (2 * i) + 1;
      int c = offset + 0;
      int d = offset + 3;

      indices.addAll([
        c, d, b,
        b, d, a
      ]);
    }
  }

  @override
  void bind(RenderPass pass, HostBuffer transientsBuffer, Matrix4 modelTransform, Matrix4 cameraTransform, Vector3 cameraPosition) {
    super.bind(pass, transientsBuffer, modelTransform, cameraTransform, cameraPosition);

    bindPositions(transientsBuffer, pass);
    bindLineStyle(transientsBuffer, pass);

    pass.setPrimitiveType(gpu.PrimitiveType.triangle);
  }

  void bindPositions(HostBuffer transientsBuffer, RenderPass pass) {
    final double extentScale = 2 / extent;
    final linePositions = Float32List.fromList(points.expand((it) => [(it.x * extentScale) - 1, 1 - (it.y * extentScale), 0.0, 0.0]).toList());
    final linePositionsSlot = vertexShader.getUniformSlot('LinePositions');

    final linePositionsView = transientsBuffer.emplace(
      linePositions.buffer.asByteData(),
    );

    pass.bindUniform(linePositionsSlot, linePositionsView);
  }

  void bindLineStyle(HostBuffer transientsBuffer, RenderPass pass) {
    final lineStyleSlot = vertexShader.getUniformSlot('LineStyle');
    final lineStyleView = transientsBuffer.emplace(Float32List.fromList([lineWidth / 256]).buffer.asByteData());
    pass.bindUniform(lineStyleSlot, lineStyleView);
  }
}

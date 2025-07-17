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

  late Texture texture = createTexture();

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
      (vertices.length / 6).truncate(),
      ByteData.sublistView(Uint16List.fromList(indices)),
      indexType: gpu.IndexType.int16,
    );
  }

  @override
  void bind(RenderPass pass, HostBuffer transientsBuffer, Matrix4 modelTransform, Matrix4 cameraTransform,
      Vector3 cameraPosition) {
    super.bind(pass, transientsBuffer, modelTransform, cameraTransform, cameraPosition);

    bindPositions(transientsBuffer, pass);
    bindLineStyle(transientsBuffer, pass);

    pass.setPrimitiveType(gpu.PrimitiveType.triangle);

    final double extentScale = extent / 2;
    final extentScalingSlot = vertexShader.getUniformSlot('extentScalings');
    final extentScalingView = transientsBuffer.emplace(Float32List.fromList([extentScale]).buffer.asByteData());
    pass.bindUniform(extentScalingSlot, extentScalingView);
  }

  void bindPositions(HostBuffer transientsBuffer, RenderPass pass) {
    final textureSlot = vertexShader.getUniformSlot("points");

    pass.bindTexture(textureSlot, texture);

    final slot = vertexShader.getUniformSlot('Meta');
    final buffer = Float32List.fromList([texture.width.toDouble(), texture.height.toDouble()]);
    pass.bindUniform(slot, transientsBuffer.emplace(buffer.buffer.asByteData()));
  }

  void bindLineStyle(HostBuffer transientsBuffer, RenderPass pass) {
    final lineStyleSlot = vertexShader.getUniformSlot('LineStyle');
    final lineStyleView = transientsBuffer.emplace(Float32List.fromList([lineWidth / 256]).buffer.asByteData());
    pass.bindUniform(lineStyleSlot, lineStyleView);
  }

  Texture createTexture() {
    final int totalPoints = points.length;

    final int width = totalPoints < _maxWidth ? totalPoints : _maxWidth;
    final int height = (totalPoints / width).ceil();

    final texture =  gpu.gpuContext
        .createTexture(gpu.StorageMode.hostVisible, width, height, format: gpu.PixelFormat.r32g32b32a32Float);


    final Float32List flatFloats = Float32List(width * height * 4);
    for (int i = 0; i < points.length; i++) {
      flatFloats[i * 4 + 0] = points[i].x;
      flatFloats[i * 4 + 1] = points[i].y;
    }

    final ByteData pointsEncoded = flatFloats.buffer.asByteData();

    texture.overwrite(pointsEncoded);

    return texture;
  }

  static const int _maxWidth = 8192;
}

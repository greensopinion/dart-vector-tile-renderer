import 'dart:typed_data';
import 'package:flutter_gpu/gpu.dart' as gpu;
import 'package:flutter_scene/scene.dart';
import 'package:vector_tile_renderer/src/gpu/shaders.dart';
import 'package:vector_tile_renderer/src/model/tile_model.dart';

class PolygonGeometry extends UnskinnedGeometry {
  PolygonGeometry(List<double> vertices, List<int> indices) {
    setVertexShader(shaderLibrary["SimpleVertex"]!);

    uploadVertexData(
      ByteData.sublistView(Float32List.fromList(vertices)),
      vertices.length ~/ 3,
      ByteData.sublistView(Uint16List.fromList(indices)),
      indexType: gpu.IndexType.int16,
    );
  }
}

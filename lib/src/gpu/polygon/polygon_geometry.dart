import 'dart:typed_data';
import 'package:flutter_gpu/gpu.dart' as gpu;
import 'package:flutter_scene/scene.dart';
import 'package:vector_tile_renderer/src/gpu/shaders.dart';
import 'package:vector_tile_renderer/src/model/tile_model.dart';

class PolygonGeometry extends UnskinnedGeometry {
  PolygonGeometry(TriangulatedPolygon earcutPolygon) {
    setVertexShader(shaderLibrary["SimpleVertex"]!);

    final normalized = earcutPolygon.normalizedVertices;
    final fixedIndices = earcutPolygon.indices;

    uploadVertexData(
      ByteData.sublistView(Float32List.fromList(normalized)),
      normalized.length ~/ 3,
      ByteData.sublistView(Uint16List.fromList(fixedIndices)),
      indexType: gpu.IndexType.int16,
    );
  }
}

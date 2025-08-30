import 'dart:typed_data';

import 'package:flutter_gpu/gpu.dart' as gpu;
import 'package:flutter_scene/scene.dart';

import '../../../vector_tile_renderer.dart';
import '../shaders.dart';

class RasterGeometry extends UnskinnedGeometry {
  RasterGeometry(RasterTile tile) {
    setVertexShader(shaderLibrary["RasterVertex"]!);

    final texture = tile.texture;
    if (texture != null && texture.isValid) {
      final top = tile.scope.top / texture.height;
      final bottom = tile.scope.bottom / texture.height;
      final left = tile.scope.left / texture.width;
      final right = tile.scope.right / texture.width;

      List<double> vertices = [
        -1, -1, 0, left, bottom,
        1, -1, 0, right, bottom,
        1, 1, 0, right, top,
        -1, 1, 0, left, top,
      ];

      uploadVertexData(
        ByteData.sublistView(Float32List.fromList(vertices)),
        4,
        ByteData.sublistView(Uint16List.fromList([0, 1, 2, 2, 3, 0])),
        indexType: gpu.IndexType.int16,
      );
    }
  }
}

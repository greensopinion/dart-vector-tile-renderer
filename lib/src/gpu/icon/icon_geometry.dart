import 'dart:typed_data';

import 'package:flutter_gpu/gpu.dart' as gpu;
import 'package:flutter_scene/scene.dart';

import '../shaders.dart';

class IconGeometry extends UnskinnedGeometry {
  Float32List vertices;

  IconGeometry(this.vertices) {
    setVertexShader(shaderLibrary["IconVertex"]!);

    final vertexCount = vertices.length ~/ 6;

    final List<int> indices = [];

    for (int i = 0; i < vertexCount; i += 4) {
      indices.addAll([i, i+ 1, i+ 2, i+ 2, i+ 3, i]);
    }

    uploadVertexData(
      ByteData.sublistView(vertices),
      vertexCount,
      ByteData.sublistView(Uint16List.fromList(indices)),
      indexType: gpu.IndexType.int16,
    );
  }
}

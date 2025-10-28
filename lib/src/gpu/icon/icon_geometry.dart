import 'dart:typed_data';

import 'package:flutter_gpu/gpu.dart' as gpu;
import 'package:flutter_scene/scene.dart';

import '../shaders.dart';

class IconGeometry extends UnskinnedGeometry {
  Float32List vertices;

  IconGeometry(this.vertices) {
    setVertexShader(shaderLibrary["IconVertex"]!);

    uploadVertexData(
      ByteData.sublistView(vertices),
      4,
      ByteData.sublistView(Uint16List.fromList([0, 1, 2, 2, 3, 0])),
      indexType: gpu.IndexType.int16,
    );
  }
}

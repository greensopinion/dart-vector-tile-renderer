import 'dart:typed_data';

import 'package:flutter_scene/scene.dart';

import '../shaders.dart';

class BackgroundGeometry extends UnskinnedGeometry {
  static final _vertices = ByteData.sublistView(Float32List.fromList([
    -1, -1, 0, // maintain formatting
    1, -1, 0,
    1, 1, 0,
    -1, 1, 0,
  ]));

  static final _indices = ByteData.sublistView(Uint16List.fromList([
    0, 2, 1, // maintain formatting
    2, 0, 3,
  ]));

  BackgroundGeometry() {
    setVertexShader(shaderLibrary["SimpleVertex"]!);

    uploadVertexData(_vertices, 4, _indices);
  }
}

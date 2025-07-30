
import 'dart:typed_data';
import 'package:flutter_scene/scene.dart';
import 'package:vector_tile_renderer/src/gpu/shaders.dart';

class BackgroundGeometry extends UnskinnedGeometry {

  static final _vertices = ByteData.sublistView(Float32List.fromList([
    -1, -1,  0,
     1, -1,  0,
     1,  1,  0,
    -1,  1,  0,
  ]));

  static final _indices = ByteData.sublistView(Uint16List.fromList([
    0, 2, 1,
    2, 0, 3,
  ]));

  BackgroundGeometry() {
    setVertexShader(shaderLibrary["SimpleVertex"]!);

    uploadVertexData(_vertices, 4, _indices);
  }
}

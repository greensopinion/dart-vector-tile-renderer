
import 'dart:typed_data';
import 'package:flutter_gpu/gpu.dart' as gpu;
import 'package:flutter_scene/scene.dart';
import 'package:vector_tile_renderer/src/gpu/shaders.dart';

class BackgroundGeometry extends UnskinnedGeometry {

  BackgroundGeometry() {
    setVertexShader(shaderLibrary["SimpleVertex"]!);

    List<double> vertices = [
      -1, -1,  0,
       1, -1,  0,
       1,  1,  0,
      -1,  1,  0
    ];

    uploadVertexData(
      ByteData.sublistView(Float32List.fromList(vertices)),
      4,
      ByteData.sublistView(Uint16List.fromList([0,1,2,2,3,0])),
      indexType: gpu.IndexType.int16,
    );
  }
}

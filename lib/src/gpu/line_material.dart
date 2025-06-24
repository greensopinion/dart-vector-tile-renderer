
import 'package:flutter_scene/scene.dart';
import 'package:vector_tile_renderer/src/gpu/shaders.dart';

class LineMaterial extends Material {
  LineMaterial() {
    setFragmentShader(shaderLibrary["SimpleFragment"]!);
  }
}

import 'dart:typed_data';

import 'package:flutter_gpu/gpu.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart';
import 'package:vector_tile_renderer/src/gpu/utils.dart';

import '../shaders.dart';

class LineEndMaterial extends Material {
  Vector4 color;

  LineEndMaterial(this.color) {
    setFragmentShader(shaderLibrary["LineEndFragment"]!);
  }

  @override
  void bind(
      RenderPass pass, HostBuffer transientsBuffer, Environment environment) {
    super.bind(pass, transientsBuffer, environment);

    final colorBytes =
    Float32List.fromList([color.x, color.y, color.z, color.w])
        .buffer
        .asByteData();

    pass.bindUniform(
      fragmentShader.getUniformSlot("Paint"),
      transientsBuffer.emplace(colorBytes),
    );

    configureRenderPass(pass);
  }
}

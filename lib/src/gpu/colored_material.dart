import 'dart:typed_data';

import 'package:flutter_gpu/gpu.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart';

import 'shaders.dart';

class ColoredMaterial extends Material {
  Vector4 color;

  ColoredMaterial(this.color) {
    setFragmentShader(shaderLibrary["SimpleFragment"]!);
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
  }
}

import 'dart:typed_data';

import 'package:flutter_gpu/gpu.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart';
import 'package:vector_tile_renderer/src/gpu/utils.dart';

import 'shaders.dart';

class ColoredMaterial extends Material {
  Vector4 color;
  bool antialiasingEnabled;
  double edgeWidth;

  ColoredMaterial(this.color,
      {this.antialiasingEnabled = true, this.edgeWidth = 0.5}) {
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

    configureRenderPass(pass);
    pass.setWindingOrder(WindingOrder.clockwise);
  }
}

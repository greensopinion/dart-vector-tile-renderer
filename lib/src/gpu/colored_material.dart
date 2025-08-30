import 'dart:typed_data';

import 'package:flutter_gpu/gpu.dart';
import 'package:flutter_scene/scene.dart';

import 'shaders.dart';
import 'tile_render_data.dart';
import 'utils.dart';

class ColoredMaterial extends Material {
  late final ByteData _uniform;

  ColoredMaterial(PackedMaterial packed) {
    setFragmentShader(shaderLibrary["SimpleFragment"]!);
    _uniform = packed.uniform!;
  }

  @override
  void bind(
      RenderPass pass, HostBuffer transientsBuffer, Environment environment) {
    super.bind(pass, transientsBuffer, environment);

    pass.bindUniform(
      fragmentShader.getUniformSlot("Paint"),
      transientsBuffer.emplace(_uniform),
    );

    configureRenderPass(pass);
    pass.setWindingOrder(WindingOrder.clockwise);
  }
}

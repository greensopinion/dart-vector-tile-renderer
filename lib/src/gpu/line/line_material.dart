import 'dart:typed_data';

import 'package:flutter_gpu/gpu.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart';
import 'package:vector_tile_renderer/src/gpu/tile_render_data.dart';
import 'package:vector_tile_renderer/src/gpu/utils.dart';

import '../shaders.dart';

class LineMaterial extends Material {
  late final ByteData _uniform;

  LineMaterial(PackedMaterial packed) {
    setFragmentShader(shaderLibrary["LineFragment"]!);

    _uniform = packed.uniform!;
  }

  @override
  void bind(
      RenderPass pass, HostBuffer transientsBuffer, Environment environment) {
    super.bind(pass, transientsBuffer, environment);

    final lineMaterialSlot = fragmentShader.getUniformSlot('LineMaterial');
    final lineMaterialView = transientsBuffer.emplace(_uniform);
    pass.bindUniform(lineMaterialSlot, lineMaterialView);

    configureRenderPass(pass);
  }
}

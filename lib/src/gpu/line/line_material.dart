import 'dart:typed_data';

import 'package:flutter_gpu/gpu.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart';
import 'package:vector_tile_renderer/src/gpu/utils.dart';
import 'package:vector_tile_renderer/src/themes/style.dart';

import '../shaders.dart';

class LineMaterial extends Material {
  Vector4 color;
  List<double>? dashLengths;

  LineMaterial(this.color, this.dashLengths) {
    setFragmentShader(shaderLibrary["LineFragment"]!);
  }

  @override
  void bind(
      RenderPass pass, HostBuffer transientsBuffer, Environment environment) {
    super.bind(pass, transientsBuffer, environment);

    dashLengths ??= [64.0, 0];

    final lineMaterialSlot = fragmentShader.getUniformSlot('LineMaterial');
    final lineMaterialView = transientsBuffer.emplace(
        Float32List.fromList([
          color.x, color.y, color.z, color.w,  // color
          dashLengths![0],  // drawLength
          dashLengths![1],  // spaceLength
        ]).buffer.asByteData());
    pass.bindUniform(lineMaterialSlot, lineMaterialView);

    configureRenderPass(pass);
  }
}

import 'dart:typed_data';

import 'package:flutter_gpu/gpu.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart';
import 'package:vector_tile_renderer/src/gpu/utils.dart';

import '../shaders.dart';

class LineMaterial extends Material {
  Vector4 color;
  List<double>? dashLengths;
  bool antialiasingEnabled;
  double edgeWidth;

  LineMaterial(this.color, this.dashLengths,
      {this.antialiasingEnabled = true, this.edgeWidth = 0.5}) {
    setFragmentShader(shaderLibrary["LineFragment"]!);
  }

  @override
  void bind(
      RenderPass pass, HostBuffer transientsBuffer, Environment environment) {
    super.bind(pass, transientsBuffer, environment);

    dashLengths ??= [64.0, 0];

    final lineMaterialSlot = fragmentShader.getUniformSlot('LineMaterial');
    final lineMaterialView = transientsBuffer.emplace(Float32List.fromList([
      color.x,
      color.y,
      color.z,
      color.w,
      dashLengths![0],
      dashLengths![1],
    ]).buffer.asByteData());
    pass.bindUniform(lineMaterialSlot, lineMaterialView);

    configureRenderPass(pass);
  }
}

import 'dart:typed_data';

import 'package:flutter_gpu/gpu.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart';
import 'package:vector_tile_renderer/src/gpu/utils.dart';

import 'shaders.dart';

class DashedMaterial extends Material {
  Vector4 color;
  final List<double> dashLengths = [40.0, 40.0];

  DashedMaterial(
      this.color,
      List<double>?
          dashLengths) /*
      : dashLengths = dashLengths ?? [40.0, 40.0] */
  {
    setFragmentShader(shaderLibrary["DashedLineFragment"]!);
  }

  @override
  void bind(
      RenderPass pass, HostBuffer transientsBuffer, Environment environment) {
    super.bind(pass, transientsBuffer, environment);

    final dashMeasurementsSlot =
        fragmentShader.getUniformSlot('dashMeasurements');
    final dashMeasurementsView = transientsBuffer
        .emplace(Float32List.fromList(dashLengths!).buffer.asByteData());
    pass.bindUniform(dashMeasurementsSlot, dashMeasurementsView);

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

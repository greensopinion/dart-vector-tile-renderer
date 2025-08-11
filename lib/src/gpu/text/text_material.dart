import 'dart:typed_data';
import 'package:flutter_gpu/gpu.dart' as gpu;
import 'package:flutter_scene/scene.dart';

import '../shaders.dart';
import '../utils.dart';

class TextMaterial extends UnlitMaterial {
  late gpu.SamplerOptions sampler;
  final double smoothness;
  final double threshold;

  TextMaterial(gpu.Texture sdf, this.smoothness, this.threshold) {
    setFragmentShader(shaderLibrary['TextFragment']!);
    baseColorTexture = sdf;

    sampler = gpu.SamplerOptions(
      minFilter: gpu.MinMagFilter.linear,
      magFilter: gpu.MinMagFilter.linear,
      mipFilter: gpu.MipFilter.linear,
      widthAddressMode: gpu.SamplerAddressMode.clampToEdge,
      heightAddressMode: gpu.SamplerAddressMode.clampToEdge,
    );
  }

  @override
  void bind(
      gpu.RenderPass pass,
      gpu.HostBuffer transientsBuffer,
      Environment environment,
      ) {

    configureRenderPass(pass);

    var fragInfo = Float32List.fromList([
      baseColorFactor.r, baseColorFactor.g,
      baseColorFactor.b, baseColorFactor.a,
      vertexColorWeight,
      smoothness,
      threshold
    ]);
    pass.bindUniform(
      fragmentShader.getUniformSlot("FragInfo"),
      transientsBuffer.emplace(ByteData.sublistView(fragInfo)),
    );

    pass.bindTexture(
        fragmentShader.getUniformSlot('sdf'),
        baseColorTexture,
        sampler: sampler
    );
  }
}
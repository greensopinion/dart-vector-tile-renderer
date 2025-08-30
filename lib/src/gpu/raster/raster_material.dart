import 'dart:typed_data';
import 'package:flutter_gpu/gpu.dart' as gpu;
import 'package:flutter_scene/scene.dart';
import '../shaders.dart';
import '../utils.dart';

class RasterMaterial extends UnlitMaterial {
  late gpu.SamplerOptions sampler;

  RasterMaterial({required gpu.Texture colorTexture, String? resampling}) {
    setFragmentShader(shaderLibrary['RasterFragment']!);
    baseColorTexture = Material.whitePlaceholder(colorTexture);

    if (resampling == "nearest") {
      sampler = gpu.SamplerOptions();
    } else {
      sampler = gpu.SamplerOptions(
        minFilter: gpu.MinMagFilter.linear,
        magFilter: gpu.MinMagFilter.linear,
        mipFilter: gpu.MipFilter.linear,
        widthAddressMode: gpu.SamplerAddressMode.clampToEdge,
        heightAddressMode: gpu.SamplerAddressMode.clampToEdge,
      );
    }
  }

  @override
  void bind(
    gpu.RenderPass pass,
    gpu.HostBuffer transientsBuffer,
    Environment environment,
  ) {
    pass.setCullMode(gpu.CullMode.backFace);
    pass.setWindingOrder(gpu.WindingOrder.counterClockwise);

    configureRenderPass(pass);

    var fragInfo = Float32List.fromList([
      baseColorFactor.r,
      baseColorFactor.g,
      baseColorFactor.b,
      baseColorFactor.a,
      vertexColorWeight,
    ]);
    pass.bindUniform(
      fragmentShader.getUniformSlot("FragInfo"),
      transientsBuffer.emplace(ByteData.sublistView(fragInfo)),
    );

    pass.bindTexture(
        fragmentShader.getUniformSlot('base_color_texture'), baseColorTexture,
        sampler: sampler);
  }
}

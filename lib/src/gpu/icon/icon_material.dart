import 'package:flutter_gpu/gpu.dart' as gpu;
import 'package:flutter_scene/scene.dart';
import '../shaders.dart';
import '../utils.dart';

class IconMaterial extends UnlitMaterial {
  late gpu.SamplerOptions sampler;

  IconMaterial(
      {required gpu.Texture colorTexture, required double resampling}) {
    setFragmentShader(shaderLibrary['IconFragment']!);
    baseColorTexture = Material.whitePlaceholder(colorTexture);

    if (resampling == 0.0) {
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

    pass.bindTexture(
        fragmentShader.getUniformSlot('base_color_texture'), baseColorTexture,
        sampler: sampler);
  }
}

import 'dart:typed_data';
import 'package:flutter_gpu/gpu.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_tile_renderer/src/gpu/texture_provider.dart';

import '../shaders.dart';
import '../tile_render_data.dart';
import '../utils.dart';

class TextMaterial extends UnlitMaterial {
  late SamplerOptions sampler;
  late final ByteData uniform;

  TextMaterial(PackedMaterial packed, TextureProvider textureProvider) {
    setFragmentShader(shaderLibrary['TextFragment']!);


    final uniform = packed.uniform;
    if (uniform != null) {
      this.uniform = ByteData.sublistView(uniform, 8);
      final textureID = byteDataToInt(ByteData.sublistView(uniform, 0, 8));
      final texture = textureProvider.get(textureID);

      if (texture != null) {
        baseColorTexture = texture;
      }
    }


    sampler = SamplerOptions(
      minFilter: MinMagFilter.linear,
      magFilter: MinMagFilter.linear,
      mipFilter: MipFilter.linear,
      widthAddressMode: SamplerAddressMode.clampToEdge,
      heightAddressMode: SamplerAddressMode.clampToEdge,
    );
  }

  @override
  void bind(
      RenderPass pass,
      HostBuffer transientsBuffer,
      Environment environment,
      ) {

    configureRenderPass(pass);
    pass.setWindingOrder(WindingOrder.clockwise);
    pass.setDepthCompareOperation(CompareFunction.always);

    pass.bindUniform(
      fragmentShader.getUniformSlot("FragInfo"),
      transientsBuffer.emplace(uniform),
    );

    pass.bindTexture(
        fragmentShader.getUniformSlot('sdf'),
        baseColorTexture,
        sampler: sampler
    );
  }

  @override
  bool isOpaque() => false;
}
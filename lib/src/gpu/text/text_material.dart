import 'dart:typed_data';
import 'package:flutter_gpu/gpu.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart';

import '../shaders.dart';
import '../utils.dart';

class TextMaterial extends UnlitMaterial {
  late SamplerOptions sampler;
  final double smoothness;
  final double threshold;

  TextMaterial(Texture sdf, this.smoothness, this.threshold, Vector4 color) {
    setFragmentShader(shaderLibrary['TextFragment']!);
    baseColorTexture = sdf;
    baseColorFactor = color;

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

  @override
  bool isOpaque() => false;
}
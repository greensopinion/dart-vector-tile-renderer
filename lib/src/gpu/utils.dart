
import 'package:flutter_gpu/gpu.dart';

void configureRenderPass(RenderPass pass) {
  pass.setDepthWriteEnable(true);
  pass.setDepthCompareOperation(CompareFunction.lessEqual);
  pass.setColorBlendEnable(true);

  final blendEquation = ColorBlendEquation(
    colorBlendOperation: BlendOperation.add,
    sourceColorBlendFactor: BlendFactor.sourceAlpha,
    destinationColorBlendFactor: BlendFactor.oneMinusSourceAlpha,
    alphaBlendOperation: BlendOperation.add,
    sourceAlphaBlendFactor: BlendFactor.one,
    destinationAlphaBlendFactor: BlendFactor.oneMinusSourceAlpha,
  );

  pass.setColorBlendEquation(blendEquation);
}
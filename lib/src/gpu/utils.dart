
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

String formatBytes(int size) {
  if (size < 1000) {
    return "$size B";
  } else if (size < 1000000) {
    return "${(size / 100).truncate() / 10} KB";
  } else if (size < 1000000000) {
    return "${(size / 100000).truncate() / 10} MB";
  } else {
    return "${(size / 100000000).truncate() / 10} GB";
  }
}
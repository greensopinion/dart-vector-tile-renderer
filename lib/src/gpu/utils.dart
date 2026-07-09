import 'dart:typed_data';

import 'package:flutter_gpu/gpu.dart';
import 'package:vector_math/vector_math.dart';

void configureRenderPass(RenderPass pass) {
  // The map is 2D and drawn on the fast opaque path. Two adjustments make that
  // correct under flutter_scene 0.18.1:
  //
  // - Never cull: map geometry has no meaningful front/back face and layers
  //   wind inconsistently (earcut fills vs. the fixed background quad); the
  //   default back-face culling would drop the "wrong-facing" ones (e.g. the
  //   background quad, leaving a transparent -> black tile).
  // - Write + test depth: each tile layer gets a distinct z (see
  //   BucketUnpacker), background farthest and labels nearest. The depth buffer
  //   then keeps the nearest (topmost) layer per pixel no matter which order
  //   flutter_scene draws pipelines in — so the flat layers stack correctly
  //   while staying on the cheap early-Z opaque path instead of the slow
  //   blended translucent pass.
  pass.setCullMode(CullMode.none);
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

double getScaleFactor(Matrix4 cameraTransform, Matrix4 modelTransform) {
  final matrix = Matrix4.identity()
    ..transposeMultiply(modelTransform)
    ..transposeMultiply(cameraTransform);

  return Vector2(matrix.row0.x, matrix.row1.x).length / _tileSize;
}

const _tileSize = 256;

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

ByteData intToByteData(int value) {
  final byteData = ByteData(8);
  byteData.setInt64(0, value, Endian.little);
  return byteData;
}

int byteDataToInt(ByteData byteData) {
  return byteData.getInt64(0, Endian.little);
}

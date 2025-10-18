import 'dart:math';
import 'dart:ui';

import 'package:vector_math/vector_math.dart' as vm;

vm.Matrix4 tileTransformMatrix(
    Rect position, Size canvasSize, double rotation) {
  final center = position.center;

  // Convert pixel center to NDC
  final ndcX = (center.dx / canvasSize.width) * 2.0 - 1.0;
  final ndcY = 1.0 - (center.dy / canvasSize.height) * 2.0;

  final xScale = position.width / canvasSize.width;
  final yScale = position.height / canvasSize.height;

  return vm.Matrix4.identity()
    ..scaleByDouble(xScale, yScale, 1.0, 1.0)
    ..rotateZ(pi * -rotation / 180)
    ..translateByDouble(ndcX / xScale, ndcY / yScale, 0.0, 1.0);
}

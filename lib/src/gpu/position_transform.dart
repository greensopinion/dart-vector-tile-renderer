import 'dart:ui';

import 'package:vector_math/vector_math.dart' as vm;

vm.Matrix4 tileTransformMatrix(Rect position, Size canvasSize) {
  final center = position.center;

  // Convert pixel center to NDC
  final ndcX = (center.dx / canvasSize.width) * 2.0 - 1.0;
  final ndcY = 1.0 - (center.dy / canvasSize.height) * 2.0;

  return vm.Matrix4.identity()
    ..translate(ndcX, ndcY, 0.0)
    ..scale(position.width, position.height, 1.0);
}

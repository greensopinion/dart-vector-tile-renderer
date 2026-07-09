import 'dart:math';
import 'dart:ui';

import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart';

class OrthographicCamera extends Camera {
  static final _sortPosition = Vector3(0, 0, -1000000);

  final double scaleFactor;
  final double rotation;

  OrthographicCamera(this.scaleFactor, this.rotation);

  // This camera bakes the whole view-projection into [getViewTransform]; the
  // members below satisfy the [Camera] contract but are unused by that path
  // (they only feed raycasting / frustum culling, which the tile renderer
  // does not use).
  @override
  Vector3 get position => _sortPosition;

  @override
  Vector3 get forward => Vector3(0, 0, 1);

  @override
  Vector3 get up => Vector3(0, 1, 0);

  @override
  CameraProjection get projection => PerspectiveProjection();

  @override
  Matrix4 getViewMatrix() => Matrix4.identity();

  @override
  Matrix4 getViewTransform(Size dimensions) => Matrix4.identity()
    ..scaleByDouble(dimensions.width / scaleFactor,
        dimensions.height / scaleFactor, 1.0, 1.0)
    ..rotateZ(rotation * pi / 180);
}

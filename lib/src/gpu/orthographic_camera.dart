import 'dart:math';
import 'dart:ui';

import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart';

class OrthographicCamera extends Camera {

  final double scaleFactor;
  final double rotation;

  OrthographicCamera(this.scaleFactor, this.rotation);

  @override
  Matrix4 getViewTransform(Size dimensions) => Matrix4.identity()
    ..rotateZ(rotation * pi / 180);

  @override
  Vector3 get position => Vector3(0, 0, -5);
}
import 'dart:ui';

import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart';

class OrthographicCamera extends Camera {

  final double scaleFactor;

  OrthographicCamera(this.scaleFactor);

  @override
  Matrix4 getViewTransform(Size dimensions) => Matrix4.identity()
    ..scale(scaleFactor / dimensions.width, scaleFactor / dimensions.height, 1.0);

  @override
  Vector3 get position => Vector3(0, 0, -5);
}
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart';
import 'package:vector_tile_renderer/src/gpu/background_geometry.dart';
import 'package:vector_tile_renderer/src/gpu/colored_material.dart';

import '../../vector_tile_renderer.dart';

class SceneBackgroundBuilder {
  final Scene scene;
  final VisitorContext context;

  SceneBackgroundBuilder(this.scene, this.context);

  void addBackground(Vector4 color) {
    scene.addMesh(Mesh(BackgroundGeometry(), ColoredMaterial(color)));
  }
}
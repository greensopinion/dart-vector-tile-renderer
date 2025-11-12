import 'dart:typed_data';

import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart';
import 'background_geometry.dart';
import '../geometry_unpacker.dart';
import '../colored_material.dart';
import '../tile_render_data.dart';

import '../../../vector_tile_renderer.dart';

class SceneBackgroundBuilder {
  final SceneGraph graph;
  final VisitorContext context;

  SceneBackgroundBuilder(this.graph, this.context);

  void addBackground(Vector4 color) {
    final colorBytes =
        Float32List.fromList([color.x, color.y, color.z, color.w])
            .buffer
            .asByteData();

    graph.addMesh(Mesh(
        BackgroundGeometry(),
        ColoredMaterial(
            PackedMaterial(uniform: colorBytes, type: MaterialType.colored))));
  }
}

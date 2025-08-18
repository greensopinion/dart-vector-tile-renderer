import 'dart:typed_data';

import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart';
import 'package:vector_tile_renderer/src/gpu/background/background_geometry.dart';
import 'package:vector_tile_renderer/src/gpu/bucket_unpacker.dart';
import 'package:vector_tile_renderer/src/gpu/colored_material.dart';
import 'package:vector_tile_renderer/src/gpu/tile_render_data.dart';

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
        ColoredMaterial(PackedMaterial(uniform: colorBytes, type: MaterialType.colored))
    ));
  }
}
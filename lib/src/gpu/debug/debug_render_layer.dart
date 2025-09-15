import 'dart:typed_data';

import 'package:flutter_scene/scene.dart';
import 'package:vector_tile_renderer/src/gpu/bucket_unpacker.dart';
import 'package:vector_tile_renderer/src/gpu/colored_material.dart';
import 'package:vector_tile_renderer/src/gpu/polygon/polygon_geometry.dart';
import 'package:vector_tile_renderer/src/gpu/tile_render_data.dart';

void addDebugRenderLayer(SceneGraph graph) {
  graph.addMesh(Mesh(PolygonGeometry(_debugGeometry), ColoredMaterial(_debugMaterial)));
}

final _debugGeometry = PackedGeometry(vertices: _vertices, indices: _indices, type: GeometryType.polygon);
final _debugMaterial = PackedMaterial(uniform: _uniform, type: MaterialType.colored);

final _uniform = Float32List.fromList([0.0, 0.5, 0.5, 1.0]).buffer.asByteData();

final _vertices = ByteData.sublistView(Float32List.fromList([
  -1.0, -1.0,  0,
  1.0, -1.0,  0,
  0.975,  -0.975,  0,
  -0.975,  -0.975,  0,
  -0.975,  0.975,  0,
  0.975,  0.975,  0,
  1.0,  1.0,  0,
  -1.0,  1.0,  0,
]));

final _indices = ByteData.sublistView(Uint16List.fromList([
  0, 2, 1,
  2, 0, 3,

  2, 6, 1,
  6, 2, 5,

  4, 6, 5,
  6, 4, 7,

  0, 4, 3,
  4, 0, 7,
]));
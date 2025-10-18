import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:vector_tile_renderer/src/gpu/bucket_unpacker.dart';
import 'package:vector_tile_renderer/src/gpu/text/ndc_label_space.dart';
import 'package:vector_tile_renderer/src/gpu/tile_render_data.dart';

void addDebugRenderLayer(TileRenderData renderData) {
  renderData.addMesh(PackedMesh(_debugGeometry, _debugMaterial));
}

void renderLabelSpaceBoxes(
    TileRenderData renderData, NdcLabelSpace labelSpace) {
  final boxes = labelSpace.getAll().toList();

  if (boxes.isEmpty) {
    return;
  }

  final vertices = boxes
      .map((it) => it.points.expand((it) => [it.x, it.y, 0.0]))
      .flattenedToList;

  final indices = boxes.mapIndexed((i, _) {
    final base = i * 4;
    return [base, base + 2, base + 1, base + 2, base, base + 3];
  }).flattenedToList;

  final geom = PackedGeometry(
      vertices: ByteData.sublistView(Float32List.fromList(vertices)),
      indices: ByteData.sublistView(Uint32List.fromList(indices)),
      type: GeometryType.polygon);

  renderData.addMesh(PackedMesh(geom, _debugMaterial));
}

final _debugGeometry = PackedGeometry(
    vertices: _vertices, indices: _indices, type: GeometryType.polygon);
final _debugMaterial =
    PackedMaterial(uniform: _uniform, type: MaterialType.colored);

final _uniform = Float32List.fromList([0.0, 0.5, 0.5, 0.3]).buffer.asByteData();

final _vertices = ByteData.sublistView(Float32List.fromList([
  -1.0, -1.0, 0, // maintain formatting
  1.0, -1.0, 0,
  0.975, -0.975, 0,
  -0.975, -0.975, 0,
  -0.975, 0.975, 0,
  0.975, 0.975, 0,
  1.0, 1.0, 0,
  -1.0, 1.0, 0,
]));

final _indices = ByteData.sublistView(Uint32List.fromList([
  0, 2, 1, // maintain formatting
  2, 0, 3,

  2, 6, 1,
  6, 2, 5,

  4, 6, 5,
  6, 4, 7,

  0, 4, 3,
  4, 0, 7,
]));

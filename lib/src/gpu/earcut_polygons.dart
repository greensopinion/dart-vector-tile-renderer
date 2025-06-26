import 'dart:math';
import 'package:dart_earcut/dart_earcut.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../model/geometry_model.dart';

void triangulatePolygonToBuffers(
    TilePolygon polygon,
    List<double> outNormalized,
    List<int> outIndices,
    ) {
  final flat = polygon.rings
      .expand((ring) => ring.points)
      .map((point) => [point.x.toDouble(), point.y.toDouble()])
      .expand((e) => e)
      .toList();

  final indices = Earcut.triangulateRaw(flat);

  for (var i = 0; i < flat.length; i += 2) {
    final x = flat[i], y = flat[i + 1];
    outNormalized.addAll([
      x / 2048.0 - 1,
      1 - y / 2048.0,
      0.0,
    ]);
  }

  for (int i = 0; i < indices.length; i += 3) {
    outIndices.addAll([
      indices[i],
      indices[i + 2],
      indices[i + 1],
    ]);
  }
}

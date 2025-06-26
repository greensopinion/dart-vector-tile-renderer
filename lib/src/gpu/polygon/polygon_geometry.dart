
import 'dart:typed_data';
import 'package:flutter_gpu/gpu.dart' as gpu;
import 'package:flutter_scene/scene.dart';
import 'package:vector_tile_renderer/src/gpu/shaders.dart';
import 'package:vector_tile_renderer/src/model/geometry_model.dart';
import 'package:dart_earcut/dart_earcut.dart';

class PolygonGeometry extends UnskinnedGeometry {

  PolygonGeometry(TilePolygon polygon) {
    setVertexShader(shaderLibrary["SimpleVertex"]!);

    final normalized = <double>[];
    final fixedIndices = <int>[];

    triangulatePolygonToBuffers(polygon, normalized, fixedIndices);


    uploadVertexData(
      ByteData.sublistView(Float32List.fromList(normalized)),
      normalized.length ~/ 3,
      ByteData.sublistView(Uint16List.fromList(fixedIndices)),
      indexType: gpu.IndexType.int16,
    );
  }

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

}

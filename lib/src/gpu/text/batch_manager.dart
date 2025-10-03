import 'dart:typed_data';
import 'package:vector_math/vector_math.dart';
import 'package:vector_tile_renderer/src/gpu/bucket_unpacker.dart';
import 'package:vector_tile_renderer/src/gpu/text/text_geometry.dart';
import 'package:vector_tile_renderer/src/gpu/tile_render_data.dart';
import 'package:vector_tile_renderer/src/gpu/utils.dart';
import 'text_geometry_generator.dart';

class BatchManager {
  final List<GeometryBatch> _batches = [];

  void addBatches(Map<int, GeometryBatch> newBatches) {
    for (final newBatch in newBatches.values) {
      GeometryBatch? existingBatch;
      for (final batch in _batches) {
        if (batch.matches(newBatch)) {
          existingBatch = batch;
          break;
        }
      }

      if (existingBatch == null) {
        existingBatch = GeometryBatch(
          newBatch.textureID,
          newBatch.color,
          newBatch.haloColor,
        );
        _batches.add(existingBatch);
      }

      final adjustedIndices = newBatch.indices
          .map((i) => i + existingBatch!.vertexOffset)
          .toList();

      existingBatch.vertices.addAll(newBatch.vertices);
      existingBatch.indices.addAll(adjustedIndices);
      existingBatch.vertexOffset += newBatch.vertices.length ~/ TextGeometry.VERTEX_SIZE;
    }
  }

  List<PackedMesh> getMeshes() {
    final meshes = <PackedMesh>[];

    for (final batch in _batches) {
      if (batch.vertices.isEmpty) continue;

      final textureIDBytes = intToByteData(batch.textureID).buffer.asUint8List();
      final hColor = batch.haloColor ?? Vector4(0.0, 0.0, 0.0, 0.0);

      final materialUniform = (
          BytesBuilder(copy: true)
            ..add(textureIDBytes)
            ..add(Float32List.fromList([
              batch.color.r, batch.color.g, batch.color.b, batch.color.a,
              hColor.r, hColor.g, hColor.b, hColor.a,
            ]).buffer.asUint8List())
      ).toBytes().buffer.asByteData();

      final geometry = PackedGeometry(
        vertices: ByteData.sublistView(Float32List.fromList(batch.vertices)),
        indices: ByteData.sublistView(Uint16List.fromList(batch.indices)),
        type: GeometryType.text
      );

      final material = PackedMaterial(
        type: MaterialType.text,
        uniform: materialUniform
      );

      meshes.add(PackedMesh(geometry, material));
    }

    _batches.clear();

    return meshes;
  }

  void clear() {
    _batches.clear();
  }
}

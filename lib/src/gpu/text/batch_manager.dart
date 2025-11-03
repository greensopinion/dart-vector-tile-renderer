import 'dart:typed_data';

import 'package:vector_math/vector_math.dart';
import '../bucket_unpacker.dart';
import '../tile_render_data.dart';
import '../utils.dart';

class TextGeometryBatch {
  final int textureID;
  final Vector4 color;
  final Vector4? haloColor;
  final List<double> vertices = [];
  final List<int> indices = [];
  int vertexOffset = 0;

  TextGeometryBatch(this.textureID, this.color, this.haloColor);

  bool matches(TextGeometryBatch other) => (textureID == other.textureID &&
      color == other.color &&
      haloColor == other.haloColor);
}

class BatchManager {
  final List<TextGeometryBatch> _batches = [];

  final GeometryType geometryType;
  final int vertexSize;

  BatchManager(this.geometryType, this.vertexSize);

  void addBatches(Map<int, TextGeometryBatch> newBatches) {
    for (final newBatch in newBatches.values) {
      TextGeometryBatch? existingBatch;
      for (final batch in _batches) {
        if (batch.matches(newBatch)) {
          existingBatch = batch;
          break;
        }
      }

      if (existingBatch == null) {
        existingBatch = TextGeometryBatch(
          newBatch.textureID,
          newBatch.color,
          newBatch.haloColor,
        );
        _batches.add(existingBatch);
      }

      final adjustedIndices =
          newBatch.indices.map((i) => i + existingBatch!.vertexOffset).toList();

      existingBatch.vertices.addAll(newBatch.vertices);
      existingBatch.indices.addAll(adjustedIndices);
      existingBatch.vertexOffset +=
          newBatch.vertices.length ~/ vertexSize;
    }
  }

  List<PackedMesh> getMeshes() {
    final meshes = <PackedMesh>[];

    for (final batch in _batches) {
      if (batch.vertices.isEmpty) continue;

      final textureIDBytes =
          intToByteData(batch.textureID).buffer.asUint8List();
      final hColor = batch.haloColor ?? Vector4(0.0, 0.0, 0.0, 0.0);

      final materialUniform = (BytesBuilder(copy: true)
            ..add(textureIDBytes)
            ..add(Float32List.fromList([
              batch.color.r,
              batch.color.g,
              batch.color.b,
              batch.color.a,
              hColor.r,
              hColor.g,
              hColor.b,
              hColor.a,
            ]).buffer.asUint8List()))
          .toBytes()
          .buffer
          .asByteData();

      final geometry = PackedGeometry(
          vertices: ByteData.sublistView(Float32List.fromList(batch.vertices)),
          indices: ByteData.sublistView(Uint16List.fromList(batch.indices)),
          type: geometryType);

      final material =
          PackedMaterial(type: MaterialType.text, uniform: materialUniform);

      meshes.add(PackedMesh(geometry, material));
    }

    _batches.clear();

    return meshes;
  }

  void clear() {
    _batches.clear();
  }
}

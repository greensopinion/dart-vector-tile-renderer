import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:vector_math/vector_math.dart';
import 'package:vector_tile_renderer/src/gpu/bucket_unpacker.dart';
import 'package:vector_tile_renderer/src/gpu/text/sdf/atlas_provider.dart';
import 'package:vector_tile_renderer/src/gpu/tile_render_data.dart';
import 'package:vector_tile_renderer/src/gpu/utils.dart';

import '../../themes/style.dart';
import 'ndc_label_space.dart';

class BoundingBox {
  double minX = double.infinity;
  double maxX = double.negativeInfinity;
  double minY = double.infinity;
  double maxY = double.negativeInfinity;

  void updateBounds(
      double charMinX, double charMaxX, double charMinY, double charMaxY) {
    minX = minX < charMinX ? minX : charMinX;
    maxX = maxX > charMaxX ? maxX : charMaxX;
    minY = minY < charMinY ? minY : charMinY;
    maxY = maxY > charMaxY ? maxY : charMaxY;
  }

  double get centerOffsetX => -(minX + maxX) / 2;

  double get centerOffsetY => -(minY + maxY) / 2;

  double get sizeX => maxX - minX;
  double get sizeY => maxY - minY;
}

class _GeometryBatch {
  final int textureID;
  final Vector4 color;
  final Vector4? haloColor;
  final List<double> vertices = [];
  final List<int> indices = [];
  int vertexOffset = 0;

  final double dynamicRotationScale;
  final double baseRotation;

  _GeometryBatch(this.textureID, this.color, this.haloColor, this.dynamicRotationScale, this.baseRotation);

  bool matches(int textureID, Vector4 color, Vector4? haloColor, double dynamicRotationScale, double baseRotation) => (
      this.textureID == textureID &&
      this.color == color &&
      this.haloColor == haloColor &&
      this.dynamicRotationScale == dynamicRotationScale &&
      this.baseRotation == baseRotation
  );
}

class TextBuilder {
  final AtlasProvider atlasProvider;
  final List<_GeometryBatch> _batches = [];

  TextBuilder(this.atlasProvider);

  void addText({
    required String text,
    required int fontSize,
    required String? fontFamily,
    required double x,
    required double y,
    required int canvasSize,
    required double rotation,
    required RotationAlignment rotationAlignment,
    required NdcLabelSpace labelSpace,
    required int textureID,
    required Vector4 color,
    Vector4? haloColor,
  }) {
    final atlas = atlasProvider.getAtlasForString(text, fontFamily);
    if (atlas == null) {
      return;
    }

    final tempVertices = <double>[];
    final indices = <int>[];
    final boundingBox = BoundingBox();

    final fontScale = fontSize / atlas.fontSize;
    final canvasScale = 2 / canvasSize;
    final scaling = fontScale * canvasScale;

    double offsetX = 0.0; // Horizontal offset for character positioning
    int vertexIndex = 0; // Track current vertex index for indices

    // Convert world position to anchor position
    final anchorX = (x - canvasSize / 2) * canvasScale;
    final anchorY = (y - canvasSize / 2) * canvasScale;

    // Process each character in the text
    for (final charCode in text.codeUnits) {
      if (charCode > 255) {
        continue;
      }

      final glyphMetrics = atlas.getGlyphMetrics(charCode)!;

      offsetX -= glyphMetrics.glyphLeft * scaling;

      final uv = atlas.getCharacterUV(charCode);

      final double top = uv.v1;
      final double bottom = uv.v2;
      final double left = uv.u1;
      final double right = uv.u2;

      final halfHeight = scaling * atlas.cellHeight / 2;
      final halfWidth = scaling * atlas.cellWidth / 2;

      // Calculate character bounds (relative to text origin)
      final charMinX = offsetX - halfWidth;
      final charMaxX = offsetX + halfWidth;
      final charMinY = -halfHeight;
      final charMaxY = halfHeight;

      // Update bounding box
      boundingBox.updateBounds(charMinX, charMaxX, charMinY, charMaxY);

      // Add vertices for this character with relative offsets
      tempVertices.addAll([
        charMinX,
        charMinY,
        0,
        left,
        bottom,
        charMaxX,
        charMinY,
        0,
        right,
        bottom,
        charMaxX,
        charMaxY,
        0,
        right,
        top,
        charMinX,
        charMaxY,
        0,
        left,
        top,
      ]);

      // Add indices for this character's quad (two triangles)
      indices.addAll([
        vertexIndex + 0, vertexIndex + 2, vertexIndex + 1, // first triangle
        vertexIndex + 2, vertexIndex + 0, vertexIndex + 3, // second triangle
      ]);
      final advance = scaling * glyphMetrics.glyphAdvance;

      offsetX += advance;
      offsetX += glyphMetrics.glyphLeft * scaling;

      // Update vertex index for next character
      vertexIndex += 4;
    }

    if (tempVertices.isEmpty) return;

    final centerOffsetX = boundingBox.centerOffsetX;
    final centerOffsetY = boundingBox.centerOffsetY;

    final aabb = Rect.fromLTRB(
        anchorX - (boundingBox.sizeX / 2),
        -anchorY - (boundingBox.sizeY / 2),
        anchorX + (boundingBox.sizeX / 2),
        -anchorY + (boundingBox.sizeY / 2)
    );

    final double baseRotation = -normalizeToPi(rotation);

    if (!labelSpace.tryOccupy(LabelSpaceBox.create(aabb, baseRotation, Point(aabb.center.dx, aabb.center.dy)))) {
      return;
    }

    final vertices = <double>[];
    for (int i = 0; i < tempVertices.length; i += 5) {
      vertices.addAll([
        tempVertices[i] + centerOffsetX, // offset_x (relative to anchor)
        tempVertices[i + 1] + centerOffsetY, // offset_y (relative to anchor)
        tempVertices[i + 3], // u
        tempVertices[i + 4], // v
        aabb.left,
        aabb.top,
        aabb.right,
        aabb.bottom
      ]);
    }

    final double dynamicRotationScale;
    if (rotationAlignment == RotationAlignment.viewport) {
      dynamicRotationScale = 1.0;
    } else {
      dynamicRotationScale = 0.0;
    }

    _GeometryBatch? batch;
    for (final b in _batches) {
      if (b.matches(textureID, color, haloColor, dynamicRotationScale, baseRotation)) {
        batch = b;
        break;
      }
    }

    if (batch == null) {
      batch = _GeometryBatch(textureID, color, haloColor, dynamicRotationScale, baseRotation);
      _batches.add(batch);
    }

    // Adjust indices to account for existing vertices in the batch
    final adjustedIndices = indices.map((i) => i + batch!.vertexOffset).toList();

    // Add vertices and indices to the batch
    batch.vertices.addAll(vertices);
    batch.indices.addAll(adjustedIndices);
    batch.vertexOffset += vertices.length ~/ 8; // 8 values per vertex
  }

  List<PackedMesh> getMeshes() {
    final meshes = <PackedMesh>[];

    for (final batch in _batches) {
      if (batch.vertices.isEmpty) continue;

      // Create combined uniform data for this batch
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

      // Since we only batch geometries with identical uniforms, use the stored uniform
      final geometryUniform = ByteData.sublistView(Float32List.fromList([batch.dynamicRotationScale, batch.baseRotation]));

      // Create the packed geometry
      final geometry = PackedGeometry(
        vertices: ByteData.sublistView(Float32List.fromList(batch.vertices)),
        indices: ByteData.sublistView(Uint16List.fromList(batch.indices)),
        uniform: geometryUniform,
        type: GeometryType.text
      );

      // Create the packed material
      final material = PackedMaterial(
        type: MaterialType.text,
        uniform: materialUniform
      );

      // Create and add the mesh
      meshes.add(PackedMesh(geometry, material));
    }

    // Clear batches after creating meshes
    _batches.clear();

    return meshes;
  }

  static double normalizeToPi(double angle) {
    // bring into [-π, π)
    angle = angle % (2 * pi);
    if (angle >= pi) {
      angle -= 2 * pi;
    }

    // now fold into [-π/2, π/2)
    if (angle < -pi / 2) {
      angle += pi;
    } else if (angle >= pi / 2) {
      angle -= pi;
    }

    return angle;
  }
}

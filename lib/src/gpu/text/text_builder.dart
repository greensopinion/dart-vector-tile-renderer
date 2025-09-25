import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:vector_math/vector_math.dart';
import 'package:vector_tile_renderer/src/gpu/bucket_unpacker.dart';
import 'package:vector_tile_renderer/src/gpu/text/sdf/glyph_atlas_data.dart';
import 'package:vector_tile_renderer/src/gpu/text/text_geometry.dart';
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

  _GeometryBatch(this.textureID, this.color, this.haloColor);

  bool matches(_GeometryBatch other) => (
      textureID == other.textureID &&
      color == other.color &&
      haloColor == other.haloColor
  );
}

class TextBuilder {
  final AtlasSet atlasSet;
  final List<_GeometryBatch> _batches = [];

  TextBuilder(this.atlasSet);

  void addText({
    required String text,
    required int fontSize,
    required String? fontFamily,
    required double x,
    required double y,
    required int canvasSize,
    required double rotation,
    required RotationAlignment rotationAlignment,
    required Map<double, NdcLabelSpace> labelSpaces,
    required Vector4 color,
    Vector4? haloColor,
  }) {

    final tempBatches = <int, _GeometryBatch>{};

    final boundingBox = BoundingBox();

    final fontScale = fontSize / atlasSet.fontSize;
    final canvasScale = 2 / canvasSize;
    final scaling = fontScale * canvasScale;

    double offsetX = 0.0; // Horizontal offset for character positioning

    // Convert world position to anchor position
    final anchorX = (x - canvasSize / 2) * canvasScale;
    final anchorY = (y - canvasSize / 2) * canvasScale;

    // Process each character in the text
    for (final charCode in text.codeUnits) {
      final atlas = atlasSet.getAtlasForChar(charCode, fontFamily);
      if (atlas == null) {
        return;
      }
      final textureID = atlas.atlasID.hashCode;

      final tempBatch = tempBatches.putIfAbsent(textureID, () => _GeometryBatch(textureID, color, haloColor));

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
      tempBatch.vertices.addAll([
        charMinX,
        charMinY,
        left,
        bottom,
        charMaxX,
        charMinY,
        right,
        bottom,
        charMaxX,
        charMaxY,
        right,
        top,
        charMinX,
        charMaxY,
        left,
        top,
      ]);

      // Add indices for this character's quad (two triangles)
      tempBatch.indices.addAll([
        tempBatch.vertexOffset + 0, tempBatch.vertexOffset + 2, tempBatch.vertexOffset + 1, // first triangle
        tempBatch.vertexOffset + 2, tempBatch.vertexOffset + 0, tempBatch.vertexOffset + 3, // second triangle
      ]);
      final advance = scaling * glyphMetrics.glyphAdvance;

      offsetX += advance;
      offsetX += glyphMetrics.glyphLeft * scaling;

      // Update vertex index for next character
      tempBatch.vertexOffset += 4;
    }

    if (tempBatches.isEmpty) return;

    final centerOffsetX = boundingBox.centerOffsetX;
    final centerOffsetY = boundingBox.centerOffsetY;


    final double baseRotation = -normalizeToPi(rotation);

    Offset center = const Offset(0, 0);
    double minScaleFactor = 99.0;

    for (var entry in labelSpaces.entries) {
      final zoomScaleFactor = entry.key;
      final labelSpace = entry.value;

      final halfSizeX = (boundingBox.sizeX / (2 * zoomScaleFactor));
      final halfSizeY = (boundingBox.sizeY / (2 * zoomScaleFactor));

      final aabb = Rect.fromLTRB(anchorX - halfSizeX,
          -anchorY - halfSizeY,
          anchorX + halfSizeX,
          -anchorY + halfSizeY
      );

      center = aabb.center;

      if (!labelSpace.tryOccupy(
        LabelSpaceBox.create(aabb, baseRotation, Point(center.dx, center.dy)),
        canExceedTileBounds: rotationAlignment == RotationAlignment.viewport
      )
      ) {
        break;
      } else {
        minScaleFactor = zoomScaleFactor;
      }
    }

    if (minScaleFactor > 10.0) {
      return;
    }

    final double dynamicRotationScale;
    if (rotationAlignment == RotationAlignment.viewport) {
      dynamicRotationScale = 1.0;
    } else {
      dynamicRotationScale = 0.0;
    }

    for (final tempBatch in tempBatches.values) {

      final tempVertices = tempBatch.vertices;

      final vertices = <double>[];
      for (int i = 0; i < tempVertices.length; i += 4) {
        vertices.addAll([
          tempVertices[i] + centerOffsetX, // offset_x (relative to anchor)
          tempVertices[i + 1] + centerOffsetY, // offset_y (relative to anchor)
          tempVertices[i + 2], // u
          tempVertices[i + 3], // v
          center.dx,
          center.dy,
          baseRotation,
          dynamicRotationScale,
          minScaleFactor
        ]);
      }

      _GeometryBatch? batch;
      for (final b in _batches) {
        if (b.matches(tempBatch)) {
          batch = b;
          break;
        }
      }

      if (batch == null) {
        batch = _GeometryBatch(tempBatch.textureID, tempBatch.color, tempBatch.haloColor);
        _batches.add(batch);
      }
      // Adjust indices to account for existing vertices in the batch
      final adjustedIndices = tempBatch.indices.map((i) => i + batch!.vertexOffset).toList();

      // Add vertices and indices to the batch
      batch.vertices.addAll(vertices);
      batch.indices.addAll(adjustedIndices);
      batch.vertexOffset += vertices.length ~/ TextGeometry.VERTEX_SIZE;
    }
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

      // Create the packed geometry
      final geometry = PackedGeometry(
        vertices: ByteData.sublistView(Float32List.fromList(batch.vertices)),
        indices: ByteData.sublistView(Uint16List.fromList(batch.indices)),
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

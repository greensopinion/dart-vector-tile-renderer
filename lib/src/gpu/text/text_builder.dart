import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart';
import 'package:vector_tile_renderer/src/gpu/text/sdf/sdf_atlas_manager.dart';
import 'package:vector_tile_renderer/src/gpu/text/text_geometry.dart';
import 'package:vector_tile_renderer/src/gpu/text/text_material.dart';
import 'package:vector_tile_renderer/src/themes/style.dart';

class BoundingBox {
  double minX = double.infinity;
  double maxX = double.negativeInfinity;
  double minY = double.infinity;
  double maxY = double.negativeInfinity;

  void updateBounds(double charMinX, double charMaxX, double charMinY, double charMaxY) {
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

class TextBuilder {
  final SdfAtlasManager atlasManager;

  TextBuilder(this.atlasManager);

  Future<void> addText(String text, Vector4 color, int fontSize, double expand, double x, double y, int canvasSize, SceneGraph scene, double rotation, RotationAlignment rotationAlignment) async {
    final atlas = await atlasManager.getAtlasForString(text, "Roboto Regular");

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
        charMinX, charMinY, 0, left, bottom,
        charMaxX, charMinY, 0, right, bottom,
        charMaxX, charMaxY, 0, right, top,
        charMinX, charMaxY, 0, left, top,
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

    final centerOffsetX = boundingBox.centerOffsetX;
    final centerOffsetY = boundingBox.centerOffsetY;

    final vertices = <double>[];
    for (int i = 0; i < tempVertices.length; i += 5) {
      vertices.addAll([
        tempVertices[i] + centerOffsetX,     // offset_x (relative to anchor)
        tempVertices[i + 1] + centerOffsetY, // offset_y (relative to anchor)
        tempVertices[i + 3],                 // u
        tempVertices[i + 4],                 // v
        anchorX - (boundingBox.sizeX / 2),
        -anchorY - (boundingBox.sizeY / 2),
        anchorX + (boundingBox.sizeX / 2),
        -anchorY + (boundingBox.sizeY / 2),
      ]);
    }

    final double dynamicRotationScale;
    if (rotationAlignment == RotationAlignment.viewport) {
      dynamicRotationScale = 1.0;
    } else {
      dynamicRotationScale = 0.0;
    }

    final geom = TextGeometry(
        ByteData.sublistView(Float32List.fromList(vertices)),
        ByteData.sublistView(Uint16List.fromList(indices)),
        ByteData.sublistView(Float32List.fromList([dynamicRotationScale, -rotation]))
    );

    final mat = TextMaterial(atlas.texture, 0.08, 0.75 / expand, color);

    final node = Node();

    node.addMesh(Mesh(geom, mat));

    /// force symbols in front of other layers. We do it this way to ensure that text does not get drawn underneath
    /// layers from a neighboring tile. TODO: instead, group layers from all tiles together and draw the groups in order
    node.localTransform = node.localTransform..translate(0.0, 0.0, 0.00001 * expand);

    scene.add(node);
  }
}

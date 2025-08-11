

import 'dart:typed_data';

import 'package:flutter_gpu/gpu.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_tile_renderer/src/gpu/text/sdf/sdf_atlas_manager.dart';
import 'package:vector_tile_renderer/src/gpu/text/text_material.dart';

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
}

class TextBuilder {
  late Texture spritesheet;
  final SdfAtlasManager atlasManager;

  TextBuilder(this.atlasManager);

  Future<void> addText(String text, int fontSize, double x, double y, int canvasSize, SceneGraph scene) {
    return () async {
      final atlas = await atlasManager.getAtlasForString(text, "Roboto Regular");
      spritesheet = gpuContext.createTexture(
          StorageMode.hostVisible,
          atlas.atlasWidth,
          atlas.atlasHeight,
          format: PixelFormat.r8UNormInt
      );
      spritesheet.overwrite(atlas.bitmapData.buffer.asByteData());

      final tempVertices = <double>[];
      final indices = <int>[];
      final boundingBox = BoundingBox();

      final fontScale = fontSize / atlas.fontSize;
      final canvasScale = 2 / canvasSize;

      final scaling = fontScale * canvasScale;

      double offsetX = 0.0; // Horizontal offset for character positioning
      int vertexIndex = 0; // Track current vertex index for indices

      double xPos = (x - canvasSize / 2) * canvasScale;
      double yPos = (y - canvasSize / 2) * canvasScale;

      // Process each character in the text
      for (final charCode in text.codeUnits) {

        final glyphMetrics = atlas.getGlyphMetrics(charCode)!;

        offsetX -= glyphMetrics.glyphLeft * scaling;

        final uv = atlas.getCharacterUV(charCode);

        final double top = uv.v1;
        final double bottom = uv.v2;
        final double left = uv.u1;
        final double right = uv.u2;

        final halfHeight = scaling * atlas.cellHeight / 2;
        final halfWidth = scaling * atlas.cellWidth / 2;

        // Calculate character bounds
        final charMinX = offsetX - halfWidth;
        final charMaxX = offsetX + halfWidth;
        final charMinY = -halfHeight;
        final charMaxY = halfHeight;

        // Update bounding box
        boundingBox.updateBounds(charMinX, charMaxX, charMinY, charMaxY);

        // Add vertices for this character (offset by current position)
        tempVertices.addAll([
          charMinX, charMinY, 0, 0, 0, -1, left, bottom, 0, 0, 0, 1, // bottom-left
          charMaxX, charMinY, 0, 0, 0, -1, right, bottom, 0, 0, 0, 1, // bottom-right
          charMaxX, charMaxY, 0, 0, 0, -1, right, top, 0, 0, 0, 1,    // top-right
          charMinX, charMaxY, 0, 0, 0, -1, left, top, 0, 0, 0, 1,     // top-left
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

      // Calculate centering offset
      final centerOffsetX = boundingBox.centerOffsetX;
      final centerOffsetY = boundingBox.centerOffsetY;

      // Apply centering offset to all vertices
      final vertices = <double>[];
      for (int i = 0; i < tempVertices.length; i += 12) { // 12 values per vertex (pos + normal + uv + color)
        vertices.addAll([
          tempVertices[i] + centerOffsetX + xPos,
          tempVertices[i + 1] + centerOffsetY - yPos,
          tempVertices[i + 2],  // z
          tempVertices[i + 3],  // normal x
          tempVertices[i + 4],  // normal y
          tempVertices[i + 5],  // normal z
          tempVertices[i + 6],  // u
          tempVertices[i + 7],  // v
          tempVertices[i + 8],  // color r
          tempVertices[i + 9],  // color g
          tempVertices[i + 10], // color b
          tempVertices[i + 11], // color a
        ]);
      }

      // Create geometry and upload all vertex data at once
      final geom = UnskinnedGeometry();
      geom.uploadVertexData(
        ByteData.sublistView(Float32List.fromList(vertices)),
        vertexIndex, // total number of vertices
        ByteData.sublistView(Uint16List.fromList(indices)),
        indexType: IndexType.int16,
      );

      final mat = TextMaterial(spritesheet, 0.05, 0.8);
      mat.baseColorTexture = spritesheet;

      scene.addMesh(Mesh(geom, mat));

    }.call();
  }
}
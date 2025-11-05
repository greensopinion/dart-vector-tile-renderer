import 'package:vector_math/vector_math.dart';
import '../batch_manager.dart';
import '../../sdf/glyph_atlas_data.dart';
import '../text_layout_calculator.dart';

class TextGeometryGenerator {
  final AtlasSet atlasSet;

  TextGeometryGenerator(this.atlasSet);

  BoundingBox? calculateBoundingBox({
    required List<String> lines,
    required List<double> lineWidths,
    required String fontFamily,
    required double scaling,
    required double lineHeight,
  }) {
    final boundingBox = BoundingBox();

    for (int lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      final lineText = lines[lineIndex];
      final lineWidth = lineWidths[lineIndex];

      final lineCenterOffsetX = lines.length > 1 ? -lineWidth / 2 : 0.0;
      double offsetX = lineCenterOffsetX;
      final baseY = ((lines.length - 1) / 2 - lineIndex) * lineHeight;

      for (final charCode in lineText.codeUnits) {
        final atlas = atlasSet.getAtlasForChar(charCode, fontFamily);
        if (atlas == null) {
          return null;
        }

        final glyphMetrics = atlas.getGlyphMetrics(charCode)!;
        offsetX -= glyphMetrics.glyphLeft * scaling;

        final offsetDist = scaling * atlas.cellSize / 2;

        final charMinX = offsetX - offsetDist;
        final charMaxX = offsetX + offsetDist;
        final charMinY = baseY - offsetDist;
        final charMaxY = baseY + offsetDist;

        boundingBox.updateBounds(charMinX, charMaxX, charMinY, charMaxY);

        final advance = scaling * glyphMetrics.glyphAdvance;
        offsetX += advance;
        offsetX += glyphMetrics.glyphLeft * scaling;
      }
    }

    return boundingBox;
  }

  ({Map<int, TextGeometryBatch> batches, BoundingBox boundingBox})?
      generateGeometry({
    required List<String> lines,
    required List<double> lineWidths,
    required String fontFamily,
    required double scaling,
    required double lineHeight,
    required Vector4 color,
    Vector4? haloColor,
  }) {
    final tempBatches = <int, TextGeometryBatch>{};
    final boundingBox = BoundingBox();

    for (int lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      final lineText = lines[lineIndex];
      final lineWidth = lineWidths[lineIndex];

      final lineCenterOffsetX = lines.length > 1 ? -lineWidth / 2 : 0.0;
      double offsetX = lineCenterOffsetX;
      final baseY = ((lines.length - 1) / 2 - lineIndex) * lineHeight;

      for (final charCode in lineText.codeUnits) {
        final atlas = atlasSet.getAtlasForChar(charCode, fontFamily);
        if (atlas == null) {
          return null;
        }
        final textureID = atlas.atlasID.hashCode;

        final tempBatch = tempBatches.putIfAbsent(
            textureID, () => TextGeometryBatch(textureID, color, haloColor));

        final glyphMetrics = atlas.getGlyphMetrics(charCode)!;
        offsetX -= glyphMetrics.glyphLeft * scaling;

        final uv = atlas.getCharacterUV(charCode);

        final double top = uv.v1;
        final double bottom = uv.v2;
        final double left = uv.u1;
        final double right = uv.u2;

        final offsetDist = scaling * atlas.cellSize / 2;

        final charMinX = offsetX - offsetDist;
        final charMaxX = offsetX + offsetDist;
        final charMinY = baseY - offsetDist;
        final charMaxY = baseY + offsetDist;

        boundingBox.updateBounds(charMinX, charMaxX, charMinY, charMaxY);

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

        tempBatch.indices.addAll([
          tempBatch.vertexOffset + 0,
          tempBatch.vertexOffset + 2,
          tempBatch.vertexOffset + 1,
          tempBatch.vertexOffset + 2,
          tempBatch.vertexOffset + 0,
          tempBatch.vertexOffset + 3,
        ]);

        final advance = scaling * glyphMetrics.glyphAdvance;
        offsetX += advance;
        offsetX += glyphMetrics.glyphLeft * scaling;

        tempBatch.vertexOffset += 4;
      }
    }

    if (tempBatches.isEmpty) return null;

    return (batches: tempBatches, boundingBox: boundingBox);
  }

  Map<int, TextGeometryBatch> transformGeometry({
    required Map<int, TextGeometryBatch> sourceBatches,
    required double centerOffsetX,
    required double centerOffsetY,
    required double centerX,
    required double centerY,
    required double baseRotation,
    required double dynamicRotationScale,
    required double minScaleFactor,
    required double fontSize,
  }) {
    final transformedBatches = <int, TextGeometryBatch>{};

    for (final sourceBatch in sourceBatches.values) {
      final tempVertices = sourceBatch.vertices;
      final vertices = <double>[];

      for (int i = 0; i < tempVertices.length; i += 4) {
        vertices.addAll([
          tempVertices[i] + centerOffsetX,
          tempVertices[i + 1] + centerOffsetY,
          tempVertices[i + 2], // u
          tempVertices[i + 3], // v
          centerX,
          centerY,
          baseRotation,
          dynamicRotationScale,
          minScaleFactor,
          fontSize,
        ]);
      }

      final newBatch = TextGeometryBatch(
        sourceBatch.textureID,
        sourceBatch.color,
        sourceBatch.haloColor,
      );
      newBatch.vertices.addAll(vertices);
      newBatch.indices.addAll(sourceBatch.indices);
      newBatch.vertexOffset = sourceBatch.vertexOffset;

      transformedBatches[sourceBatch.textureID] = newBatch;
    }

    return transformedBatches;
  }
}

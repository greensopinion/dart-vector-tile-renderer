import 'package:vector_math/vector_math.dart';
import 'package:vector_tile_renderer/src/gpu/text/math/parametric_spline.dart';
import 'package:vector_tile_renderer/src/model/geometry_model.dart';
import 'sdf/glyph_atlas_data.dart';
import 'text_layout_calculator.dart';

class GeometryBatch {
  final int textureID;
  final Vector4 color;
  final Vector4? haloColor;
  final List<double> vertices = [];
  final List<int> indices = [];
  int vertexOffset = 0;

  GeometryBatch(this.textureID, this.color, this.haloColor);

  bool matches(GeometryBatch other) => (textureID == other.textureID &&
      color == other.color &&
      haloColor == other.haloColor);
}

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

        final halfHeight = scaling * atlas.cellHeight / 2;
        final halfWidth = scaling * atlas.cellWidth / 2;

        final charMinX = offsetX - halfWidth;
        final charMaxX = offsetX + halfWidth;
        final charMinY = baseY - halfHeight;
        final charMaxY = baseY + halfHeight;

        boundingBox.updateBounds(charMinX, charMaxX, charMinY, charMaxY);

        final advance = scaling * glyphMetrics.glyphAdvance;
        offsetX += advance;
        offsetX += glyphMetrics.glyphLeft * scaling;
      }
    }

    return boundingBox;
  }

  ({Map<int, GeometryBatch> batches, BoundingBox boundingBox})?
      generateGeometry({
    required List<String> lines,
    required List<double> lineWidths,
    required String fontFamily,
    required double scaling,
    required double lineHeight,
    required Vector4 color,
    Vector4? haloColor,
  }) {
    final tempBatches = <int, GeometryBatch>{};
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
            textureID, () => GeometryBatch(textureID, color, haloColor));

        final glyphMetrics = atlas.getGlyphMetrics(charCode)!;
        offsetX -= glyphMetrics.glyphLeft * scaling;

        final uv = atlas.getCharacterUV(charCode);

        final double top = uv.v1;
        final double bottom = uv.v2;
        final double left = uv.u1;
        final double right = uv.u2;

        final halfHeight = scaling * atlas.cellHeight / 2;
        final halfWidth = scaling * atlas.cellWidth / 2;

        final charMinX = offsetX - halfWidth;
        final charMaxX = offsetX + halfWidth;
        final charMinY = baseY - halfHeight;
        final charMaxY = baseY + halfHeight;

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

  Map<int, GeometryBatch> transformGeometry({
    required Map<int, GeometryBatch> sourceBatches,
    required double centerOffsetX,
    required double centerOffsetY,
    required double centerX,
    required double centerY,
    required double baseRotation,
    required double dynamicRotationScale,
    required double minScaleFactor,
    required double fontSize,
  }) {
    final transformedBatches = <int, GeometryBatch>{};

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

      final newBatch = GeometryBatch(
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

  ({Map<int, GeometryBatch> batches, BoundingBox boundingBox})? generateCurvedGeometry({
      required TileLine line,
      required int bestIndex,
      required List<String> lines,
      required List<double> lineWidths,
      required String fontFamily,
      required double scaling,
      required double lineHeight,
      required Vector4 color,
      Vector4? haloColor,
      required int fontSize}) {
    print("generateCurvedGeometry: line has ${line.points.length} points, bestIndex: $bestIndex");
    final spline = ParametricUniformSpline.linear(line.points);

    final tempBatches = <int, GeometryBatch>{};
    final boundingBox = BoundingBox();

    final lineText = lines.first;
    final lineWidth = lineWidths.first;

    print("Text: '$lineText', lineWidth: $lineWidth, scaling: $scaling");

    double currentDistance = -lineWidth / 2.0;
    print("Starting currentDistance: $currentDistance");

    for (final charCode in lineText.codeUnits) {
      final atlas = atlasSet.getAtlasForChar(charCode, fontFamily);
      if (atlas == null) {
        return null;
      }

      final textureID = atlas.atlasID.hashCode;

      final tempBatch = tempBatches.putIfAbsent(
          textureID, () => GeometryBatch(textureID, color, haloColor));

      final glyphMetrics = atlas.getGlyphMetrics(charCode)!;

      final distanceToTravel = (currentDistance - glyphMetrics.glyphLeft * scaling) * 2048;
      double t = spline.indexFromSignedDistance(bestIndex.toDouble(), distanceToTravel);
      TilePoint localOffset = spline.valueAt(t);
      double x = (localOffset.x / 2048) - 1;
      double y = 1 - (localOffset.y / 2048);
      double rotation = - spline.rotationAt(t);

      if (tempBatch.vertexOffset < 12) { // Log first 3 chars
        print("Char #${tempBatch.vertexOffset ~/ 4}: '${String.fromCharCode(charCode)}' distanceToTravel: $distanceToTravel, t: $t, position: (${localOffset.x}, ${localOffset.y})");
      }


      final uv = atlas.getCharacterUV(charCode);

      final double top = uv.v1;
      final double bottom = uv.v2;
      final double left = uv.u1;
      final double right = uv.u2;

      final halfHeight = scaling * atlas.cellHeight / 2;
      final halfWidth = scaling * atlas.cellWidth / 2;

      final charMinX = - halfWidth;
      final charMaxX = halfWidth;
      final charMinY = - halfHeight;
      final charMaxY = halfHeight;


      boundingBox.updateBounds(charMinX, charMaxX, charMinY, charMaxY);

      tempBatch.vertices.addAll([
        charMinX,
        charMinY,
        left,
        bottom,
        x,
        y,
        rotation,
        0.0, 0.5, fontSize.toDouble(),

        charMaxX,
        charMinY,
        right,
        bottom,
        x,
        y,
        rotation,
        0.0, 0.5, fontSize.toDouble(),

        charMaxX,
        charMaxY,
        right,
        top,
        x,
        y,
        rotation,
        0.0, 0.5, fontSize.toDouble(),

        charMinX,
        charMaxY,
        left,
        top,
        x,
        y,
        rotation,
        0.0, 0.5, fontSize.toDouble(),

      ]);

      tempBatch.indices.addAll([
        tempBatch.vertexOffset + 0,
        tempBatch.vertexOffset + 2,
        tempBatch.vertexOffset + 1,
        tempBatch.vertexOffset + 2,
        tempBatch.vertexOffset + 0,
        tempBatch.vertexOffset + 3,
      ]);

      currentDistance += scaling * glyphMetrics.glyphAdvance;

      tempBatch.vertexOffset += 4;
    }

    if (tempBatches.isEmpty) return null;

    return (batches: tempBatches, boundingBox: boundingBox);
  }
}

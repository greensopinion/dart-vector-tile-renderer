

import 'dart:math';

import 'package:vector_math/vector_math.dart';

import '../../../../model/geometry_model.dart';
import '../../math/parametric_spline.dart';
import '../../sdf/glyph_atlas_data.dart';
import '../batch_manager.dart';
import '../text_layout_calculator.dart';

class CurvedTextGeometryGenerator {

  final AtlasSet atlasSet;

  CurvedTextGeometryGenerator(this.atlasSet);

  ({Map<int, TextGeometryBatch> batches, BoundingBox boundingBox, double rotation, TilePoint point})? generateCurvedGeometry({
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
    final spline = ParametricUniformSpline.linear(line.points);

    final tempBatches = <int, TextGeometryBatch>{};
    final boundingBox = BoundingBox();

    final lineText = lines.first;
    final lineWidth = lineWidths.first;

    double currentDistance = -lineWidth / 2.0;

    final firstChar = lineText.codeUnits.firstOrNull;
    if (firstChar == null) return null;

    final atlas = atlasSet.getAtlasForChar(firstChar, fontFamily);
    if (atlas == null) {
      return null;
    }
    final glyphMetrics = atlas.getGlyphMetrics(firstChar)!;

    final padding = (glyphMetrics.glyphLeft * scaling - currentDistance) * 2048;

    final minCenter = spline.indexFromSignedDistance(0, padding);
    final maxCenter = spline.indexFromSignedDistance(99999999, -padding);

    if (maxCenter < minCenter) return null;

    double centerIndex = bestIndex.toDouble().clamp(minCenter, maxCenter);

    TilePoint center = spline.valueAt(centerIndex); //fixme: used for bounding box offset, but should use the center of the bounding box instead

    double dx = spline.splineX.interpolate(centerIndex + padding) - spline.splineX.interpolate(centerIndex - padding);
    double dy = spline.splineY.interpolate(centerIndex + padding) - spline.splineY.interpolate(centerIndex - padding);


    double flip = (spline.splineX.interpolate(centerIndex + padding) - spline.splineX.interpolate(centerIndex - padding)).sign;
    double flipRadians = pi;
    if (flip != -1) {
      flip = 1;
      flipRadians = 0;
    }

    double avgRotation = atan2(dy, dx) + flipRadians;


    for (final charCode in lineText.codeUnits) {
      final atlas = atlasSet.getAtlasForChar(charCode, fontFamily);
      if (atlas == null) {
        return null;
      }

      final textureID = atlas.atlasID.hashCode;

      final tempBatch = tempBatches.putIfAbsent(
          textureID, () => TextGeometryBatch(textureID, color, haloColor));

      final glyphMetrics = atlas.getGlyphMetrics(charCode)!;

      final distanceToTravel = (currentDistance - glyphMetrics.glyphLeft * scaling) * 2048 * flip;

      final zoomScaleFactors = [1.0, 1.5, 2.0, 2.5];

      final poses = [];
      final rots = [];

      for (var zoom in zoomScaleFactors) {
        double t = spline.indexFromSignedDistance(centerIndex, distanceToTravel / zoom);
        rots.add(_normalizeRadians(flipRadians - spline.rotationAt(t)));
        TilePoint localOffset = spline.valueAt(t);
        poses.add((localOffset.x / 2048) - 1);
        poses.add(1 - (localOffset.y / 2048));
      }


      final x = poses[0];
      final y = poses[1];

      final uv = atlas.getCharacterUV(charCode);

      final double top = uv.v1;
      final double bottom = uv.v2;
      final double left = uv.u1;
      final double right = uv.u2;

      final offsetDist = scaling * atlas.cellSize / 2;

      // Rotate the bounding box corners by -avgRotation
      final cosRot = cos(avgRotation);
      final sinRot = sin(avgRotation);

      // Rotate all four corners
      final corners = [
        (x - offsetDist, y - offsetDist),
        (x + offsetDist, y - offsetDist),
        (x - offsetDist, y + offsetDist),
        (x + offsetDist, y + offsetDist),
      ];

      double minRotatedX = double.infinity;
      double maxRotatedX = double.negativeInfinity;
      double minRotatedY = double.infinity;
      double maxRotatedY = double.negativeInfinity;

      for (final (cornerX, cornerY) in corners) {
        final rotatedX = cornerX * cosRot - cornerY * sinRot;
        final rotatedY = cornerX * sinRot + cornerY * cosRot;

        minRotatedX = min(minRotatedX, rotatedX);
        maxRotatedX = max(maxRotatedX, rotatedX);
        minRotatedY = min(minRotatedY, rotatedY);
        maxRotatedY = max(maxRotatedY, rotatedY);
      }

      boundingBox.updateBounds(minRotatedX, maxRotatedX, minRotatedY, maxRotatedY);

      tempBatch.vertices.addAll([

        left,
        bottom,
        ...poses,
        ...rots,
        fontSize.toDouble(),
        offsetDist,

        right,
        bottom,
        ...poses,
        ...rots,
        fontSize.toDouble(),
        offsetDist,

        right,
        top,
        ...poses,
        ...rots,
        fontSize.toDouble(),
        offsetDist,

        left,
        top,
        ...poses,
        ...rots,
        fontSize.toDouble(),
        offsetDist,

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

    return (batches: tempBatches, boundingBox: boundingBox, rotation: avgRotation, point: center);
  }

  double _normalizeRadians(double angle) {
    const twoPi = 2 * pi;
    angle = angle % twoPi; // Wraps into -2π..2π
    if (angle < 0) {
      angle += twoPi; // Shift negative values to 0..2π
    }
    return angle;
  }
}
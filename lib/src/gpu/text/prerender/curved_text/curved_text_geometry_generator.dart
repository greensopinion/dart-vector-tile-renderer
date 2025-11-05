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

  ({
    Map<int, TextGeometryBatch> batches,
    BoundingBox boundingBox,
    double rotation,
    TilePoint point
  })? generateCurvedGeometry(
      {required TileLine line,
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

    // Calculate center bounds and validate
    final centerBounds = _calculateCenterBounds(
      lineText: lineText,
      fontFamily: fontFamily,
      scaling: scaling,
      currentDistance: currentDistance,
      spline: spline,
      bestIndex: bestIndex,
    );
    if (centerBounds == null) return null;

    final centerIndex = centerBounds.centerIndex;
    final padding = centerBounds.padding;

    // Calculate flip direction and rotation
    final rotation = _calculateFlipAndRotation(
      spline: spline,
      centerIndex: centerIndex,
      padding: padding,
    );
    final flip = rotation.flip;
    final flipRadians = rotation.flipRadians;
    final avgRotation = rotation.avgRotation;

    final center = spline.valueAt(centerIndex);

    // Track previous glyph rotations for angle difference checking
    List<double>? previousRots;

    // Process each character
    for (final charCode in lineText.codeUnits) {
      final atlas = atlasSet.getAtlasForChar(charCode, fontFamily);
      if (atlas == null) return null;

      final textureID = atlas.atlasID.hashCode;
      final tempBatch = tempBatches.putIfAbsent(
          textureID, () => TextGeometryBatch(textureID, color, haloColor));

      final glyphMetrics = atlas.getGlyphMetrics(charCode)!;
      final distanceToTravel =
          (currentDistance - glyphMetrics.glyphLeft * scaling) * 2048 * flip;

      // Calculate character positions and rotations for different zoom levels
      final posRot = _calculateCharacterPositionsAndRotations(
        spline: spline,
        centerIndex: centerIndex,
        distanceToTravel: distanceToTravel,
        flipRadians: flipRadians,
      );

      // Check if rotation difference exceeds pi/4 at any zoom level
      if (previousRots != null) {
        const maxRotationDiff = pi / 4;
        for (int i = 0; i < posRot.rots.length; i++) {
          final angleDiff =
              _shortestAngularDifference(previousRots[i], posRot.rots[i]);
          if (angleDiff.abs() > maxRotationDiff) {
            return null;
          }
        }
      }
      previousRots = posRot.rots;

      final x = posRot.poses[0];
      final y = posRot.poses[1];

      final uv = atlas.getCharacterUV(charCode);
      final offsetDist = scaling * atlas.cellSize / 2;

      // Update bounding box for this character
      _updateBoundingBoxForCharacter(
        x: x,
        y: y,
        offsetDist: offsetDist,
        avgRotation: avgRotation,
        boundingBox: boundingBox,
      );

      // Add vertices for this character
      _addVertices(tempBatch, uv.u1, uv.v2, posRot.poses, posRot.rots, fontSize,
          offsetDist, uv.u2, uv.v1);

      currentDistance += scaling * glyphMetrics.glyphAdvance;
      tempBatch.vertexOffset += 4;
    }

    if (tempBatches.isEmpty) return null;

    return (
      batches: tempBatches,
      boundingBox: boundingBox,
      rotation: avgRotation,
      point: center
    );
  }

  ({double minCenter, double maxCenter, double centerIndex, double padding})?
      _calculateCenterBounds({
    required String lineText,
    required String fontFamily,
    required double scaling,
    required double currentDistance,
    required ParametricUniformSpline spline,
    required int bestIndex,
  }) {
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

    final centerIndex = bestIndex.toDouble().clamp(minCenter, maxCenter);

    return (
      minCenter: minCenter,
      maxCenter: maxCenter,
      centerIndex: centerIndex,
      padding: padding
    );
  }

  ({double flip, double flipRadians, double avgRotation})
      _calculateFlipAndRotation({
    required ParametricUniformSpline spline,
    required double centerIndex,
    required double padding,
  }) {
    final dx = spline.splineX.interpolate(centerIndex + padding) -
        spline.splineX.interpolate(centerIndex - padding);
    final dy = spline.splineY.interpolate(centerIndex + padding) -
        spline.splineY.interpolate(centerIndex - padding);

    double flip = dx.sign;
    double flipRadians = pi;
    if (flip != -1) {
      flip = 1;
      flipRadians = 0;
    }

    final avgRotation = atan2(dy, dx) + flipRadians;

    return (flip: flip, flipRadians: flipRadians, avgRotation: avgRotation);
  }

  ({List<double> poses, List<double> rots})
      _calculateCharacterPositionsAndRotations({
    required ParametricUniformSpline spline,
    required double centerIndex,
    required double distanceToTravel,
    required double flipRadians,
  }) {
    const zoomScaleFactors = [1.0, 1.5, 2.0, 2.5];

    final poses = <double>[];
    final rots = <double>[];

    for (final zoom in zoomScaleFactors) {
      final t =
          spline.indexFromSignedDistance(centerIndex, distanceToTravel / zoom);
      rots.add(_normalizeRadians(flipRadians - spline.rotationAt(t)));
      final localOffset = spline.valueAt(t);
      poses.add((localOffset.x / 2048) - 1);
      poses.add(1 - (localOffset.y / 2048));
    }

    return (poses: poses, rots: rots);
  }

  void _updateBoundingBoxForCharacter({
    required double x,
    required double y,
    required double offsetDist,
    required double avgRotation,
    required BoundingBox boundingBox,
  }) {
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

    boundingBox.updateBounds(
        minRotatedX, maxRotatedX, minRotatedY, maxRotatedY);
  }

  void _addVertices(
      TextGeometryBatch tempBatch,
      double left,
      double bottom,
      List<dynamic> poses,
      List<dynamic> rots,
      int fontSize,
      double offsetDist,
      double right,
      double top) {
    tempBatch.vertices.addAll([
      // maintain formatting
      left, bottom, ...poses, ...rots, fontSize.toDouble(), offsetDist, 0.0,
      right, bottom, ...poses, ...rots, fontSize.toDouble(), offsetDist, 0.0,
      right, top, ...poses, ...rots, fontSize.toDouble(), offsetDist, 0.0,
      left, top, ...poses, ...rots, fontSize.toDouble(), offsetDist, 0.0,
    ]);

    tempBatch.indices.addAll([
      tempBatch.vertexOffset + 0,
      tempBatch.vertexOffset + 2,
      tempBatch.vertexOffset + 1,
      tempBatch.vertexOffset + 2,
      tempBatch.vertexOffset + 0,
      tempBatch.vertexOffset + 3,
    ]);
  }

  double _normalizeRadians(double angle) {
    const twoPi = 2 * pi;
    angle = angle % twoPi; // Wraps into -2π..2π
    if (angle < 0) {
      angle += twoPi; // Shift negative values to 0..2π
    }
    return angle;
  }

  /// Calculates the shortest angular difference between two angles.
  /// Handles wrapping correctly (e.g., difference between 0.1 and 6.2 is ~0.183, not ~6.1)
  double _shortestAngularDifference(double angle1, double angle2) {
    double diff = angle2 - angle1;
    // Normalize difference to [-pi, pi]
    while (diff > pi) {
      diff -= 2 * pi;
    }
    while (diff < -pi) {
      diff += 2 * pi;
    }
    return diff;
  }
}

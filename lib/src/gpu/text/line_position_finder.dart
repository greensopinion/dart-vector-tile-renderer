import 'dart:math';
import 'package:vector_tile_renderer/src/model/geometry_model.dart';
import '../../themes/style.dart';
import 'ndc_label_space.dart';
import 'text_layout_calculator.dart';

class LinePositionFinder {
  final TextLayoutCalculator layoutCalculator;

  LinePositionFinder(this.layoutCalculator);

  ({TilePoint point, double rotation})? findBestPosition(
    TileLine line,
    BoundingBox boundingBox,
    Map<double, NdcLabelSpace> labelSpaces,
    int canvasSize,
    RotationAlignment rotationAlignment,
  ) {
    final points = line.points;
    if (points.length < 2) return null;

    final textWidth = boundingBox.sizeX;
    final textHeight = boundingBox.sizeY;

    final midpoint = points.length ~/ 2;
    ({TilePoint point, double rotation})? bestPosition;
    int maxPassingChecks = 0;

    for (int offset = 0; offset <= midpoint + 1; offset++) {
      final lowerIndex = midpoint - offset;
      if (lowerIndex >= 0 && lowerIndex < points.length - 1) {
        final result = _tryLinePosition(
          points,
          lowerIndex,
          textWidth,
          textHeight,
          labelSpaces,
          canvasSize,
          rotationAlignment,
        );
        if (result != null && result.passingChecks > maxPassingChecks) {
          maxPassingChecks = result.passingChecks;
          bestPosition = (point: result.point, rotation: result.rotation);
        }
      }

      final upperIndex = midpoint + offset;
      if (upperIndex != lowerIndex && upperIndex >= 0 && upperIndex < points.length - 1) {
        final result = _tryLinePosition(
          points,
          upperIndex,
          textWidth,
          textHeight,
          labelSpaces,
          canvasSize,
          rotationAlignment,
        );
        if (result != null && result.passingChecks > maxPassingChecks) {
          maxPassingChecks = result.passingChecks;
          bestPosition = (point: result.point, rotation: result.rotation);
        }
      }
    }

    if (bestPosition != null) {
      return bestPosition;
    }

    // Fallback to midpoint
    if (midpoint < points.length) {
      final midPoint = points[midpoint];
      final rotation = (rotationAlignment == RotationAlignment.map && midpoint < points.length - 1)
          ? _getLineAngle(points, midpoint)
          : 0.0;
      return (point: midPoint, rotation: rotation);
    }

    return null;
  }

  ({TilePoint point, double rotation, int passingChecks})? _tryLinePosition(
    List<TilePoint> points,
    int index,
    double textWidth,
    double textHeight,
    Map<double, NdcLabelSpace> labelSpaces,
    int canvasSize,
    RotationAlignment rotationAlignment,
  ) {
    if (index >= points.length - 1) return null;

    final point = points[index];
    final rotation = rotationAlignment == RotationAlignment.map
        ? _getLineAngle(points, index)
        : 0.0;

    final anchor = layoutCalculator.calculateAnchor(point.x, point.y, canvasSize);
    int passingChecks = 0;

    for (var entry in labelSpaces.entries) {
      final zoomScaleFactor = entry.key;
      final labelSpace = entry.value;

      final halfSizeX = (textWidth / (2 * zoomScaleFactor));
      final halfSizeY = (textHeight / (2 * zoomScaleFactor));

      final aabb = layoutCalculator.createBoundingRect(
        anchor,
        BoundingBox()
          ..minX = -halfSizeX
          ..maxX = halfSizeX
          ..minY = -halfSizeY
          ..maxY = halfSizeY,
        1.0, // Use 1.0 as zoom factor since we already scaled halfSize
      );

      final center = aabb.center;
      final baseRotation = -_normalizeToPi(rotation);

      if (!labelSpace.tryOccupy(
        LabelSpaceBox.create(aabb, baseRotation, Point(center.dx, center.dy)),
        simulate: true,
        canExceedTileBounds: false,
      )) {
        if (passingChecks == 0) {
          return null;
        }
        break;
      }
      passingChecks++;
    }

    return (point: point, rotation: rotation, passingChecks: passingChecks);
  }

  double _getLineAngle(List<TilePoint> points, int index) {
    if (index >= points.length - 1) return 0.0;

    final p1 = points[index];
    final p2 = points[index + 1];

    final dx = p2.x - p1.x;
    final dy = p2.y - p1.y;

    return atan2(dy, dx);
  }

  static double _normalizeToPi(double angle) {
    angle = angle % (2 * pi);
    if (angle >= pi) {
      angle -= 2 * pi;
    }

    if (angle < -pi / 2) {
      angle += pi;
    } else if (angle >= pi / 2) {
      angle -= pi;
    }

    return angle;
  }
}

import 'dart:math';
import 'dart:ui';
import 'ndc_label_space.dart';
import 'text_layout_calculator.dart';

class LabelSpaceValidator {
  final TextLayoutCalculator layoutCalculator;

  LabelSpaceValidator(this.layoutCalculator);

  ({double minScaleFactor, Offset center})? validateAndOccupySpace({
    required Map<double, NdcLabelSpace> labelSpaces,
    required BoundingBox boundingBox,
    required Offset anchor,
    required double baseRotation,
    required bool canExceedTileBounds,
  }) {
    Offset center = const Offset(0, 0);
    double minScaleFactor = 99.0;

    for (var entry in labelSpaces.entries) {
      final zoomScaleFactor = entry.key;
      final labelSpace = entry.value;

      final aabb = layoutCalculator.createBoundingRect(
        anchor,
        boundingBox,
        zoomScaleFactor,
      );

      center = aabb.center;

      if (!labelSpace.tryOccupy(
        LabelSpaceBox.create(aabb, baseRotation, Point(center.dx, center.dy)),
        canExceedTileBounds: canExceedTileBounds,
      )) {
        break;
      } else {
        minScaleFactor = zoomScaleFactor;
      }
    }

    if (minScaleFactor > 10.0) {
      return null;
    }

    return (minScaleFactor: minScaleFactor, center: center);
  }

  static double normalizeToPi(double angle) {
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

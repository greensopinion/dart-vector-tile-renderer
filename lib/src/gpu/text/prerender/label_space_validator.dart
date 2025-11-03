import 'dart:math';
import 'dart:ui';
import '../../../themes/style.dart';

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
    required LayoutAnchor anchorType,
  }) {
    double minScaleFactor = 99.0;

    for (var entry in labelSpaces.entries) {
      final zoomScaleFactor = entry.key;
      final labelSpace = entry.value;

      final aabb = layoutCalculator.createBoundingRect(
        anchor,
        anchorType,
        boundingBox,
        zoomScaleFactor,
      );

      if (!labelSpace.tryOccupy(
        LabelSpaceBox.create(aabb, baseRotation, Point(anchor.dx, -anchor.dy)),
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

    return (minScaleFactor: minScaleFactor, center: anchor.scale(1, -1));
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

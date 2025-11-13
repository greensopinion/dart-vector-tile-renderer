import 'dart:math';
import 'dart:ui';
import '../sdf/glyph_atlas_data.dart';
import '../../../themes/style.dart';
import '../../../features/text_wrapper.dart';

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

class TextLayoutCalculator {
  final AtlasSet atlasSet;

  TextLayoutCalculator(this.atlasSet);

  List<String> wrapTextLines(String text, int fontSize, int? maxWidth) {
    if (maxWidth != null && maxWidth > 0 && fontSize > 0) {
      return wrapText(text, fontSize.toDouble(), maxWidth)
          .map((line) => line.trim())
          .toList(growable: false);
    }
    return [text];
  }

  List<double> calculateLineWidths(
    List<String> lines,
    String fontFamily,
    double scaling,
  ) {
    final lineWidths = <double>[];

    for (final lineText in lines) {
      double lineWidth = 0.0;
      for (final charCode in lineText.codeUnits) {
        final atlas = atlasSet.getAtlasForChar(charCode, fontFamily);
        if (atlas == null) {
          return [];
        }
        final glyphMetrics = atlas.getGlyphMetrics(charCode)!;
        lineWidth += scaling * glyphMetrics.glyphAdvance;
      }
      lineWidths.add(lineWidth);
    }

    return lineWidths;
  }

  ({double fontScale, double canvasScale, double scaling, double lineHeight})
      calculateScaling(int fontSize, int canvasSize, int zoomOffset) {
    final fontScale = 15 * fontSize / atlasSet.fontSize;
    final canvasScale = 2 / canvasSize;
    final scaling = fontScale * canvasScale * pow(2, zoomOffset);
    final lineHeight = scaling * atlasSet.fontSize * 1.2;

    return (
      fontScale: fontScale,
      canvasScale: canvasScale,
      scaling: scaling,
      lineHeight: lineHeight,
    );
  }

  Offset calculateAnchor(double x, double y, int canvasSize) {
    final canvasScale = 2 / canvasSize;
    final anchorX = (x - canvasSize / 2) * canvasScale;
    final anchorY = (y - canvasSize / 2) * canvasScale;
    return Offset(anchorX, anchorY);
  }

  Rect createBoundingRect(
    Offset anchor,
    LayoutAnchor anchorType,
    BoundingBox boundingBox,
    double zoomScaleFactor,
  ) {
    final halfSizeX = (boundingBox.sizeX / (2 * zoomScaleFactor));
    final halfSizeY = (boundingBox.sizeY / (2 * zoomScaleFactor));

    if (anchorType == LayoutAnchor.top) {
      return Rect.fromLTRB(anchor.dx - halfSizeX, -anchor.dy,
          anchor.dx + halfSizeX, -anchor.dy + boundingBox.sizeY);
    } else {
      return Rect.fromLTRB(anchor.dx - halfSizeX, -anchor.dy - halfSizeY,
          anchor.dx + halfSizeX, -anchor.dy + halfSizeY);
    }
  }
}

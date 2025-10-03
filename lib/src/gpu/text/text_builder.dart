import 'dart:ui';

import 'package:vector_math/vector_math.dart';
import 'package:vector_tile_renderer/src/gpu/text/sdf/glyph_atlas_data.dart';
import 'package:vector_tile_renderer/src/gpu/tile_render_data.dart';
import 'package:vector_tile_renderer/src/model/geometry_model.dart';

import '../../themes/style.dart';
import 'ndc_label_space.dart';
import 'text_layout_calculator.dart';
import 'text_geometry_generator.dart';
import 'line_position_finder.dart';
import 'label_space_validator.dart';
import 'batch_manager.dart';

class _LayoutResult {
  final List<String> lines;
  final List<double> lineWidths;
  final ({double fontScale, double canvasScale, double scaling, double lineHeight}) scalingData;

  _LayoutResult({
    required this.lines,
    required this.lineWidths,
    required this.scalingData,
  });
}

class TextBuilder {
  final AtlasSet atlasSet;
  final TextLayoutCalculator _layoutCalculator;
  final TextGeometryGenerator _geometryGenerator;
  final LinePositionFinder _positionFinder;
  final LabelSpaceValidator _spaceValidator;
  final BatchManager _batchManager;

  TextBuilder(this.atlasSet)
      : _layoutCalculator = TextLayoutCalculator(atlasSet),
        _geometryGenerator = TextGeometryGenerator(atlasSet),
        _positionFinder = LinePositionFinder(TextLayoutCalculator(atlasSet)),
        _spaceValidator = LabelSpaceValidator(TextLayoutCalculator(atlasSet)),
        _batchManager = BatchManager();

  void addText({
    required String text,
    required int fontSize,
    required String fontFamily,
    TileLine? line,
    TilePoint? point,
    required int canvasSize,
    required RotationAlignment rotationAlignment,
    required Map<double, NdcLabelSpace> labelSpaces,
    required Vector4 color,
    Vector4? haloColor,
    int? maxWidth,
    required bool isLineString,
  }) {
    final layoutResult = _calculateLayout(text, fontSize, fontFamily, maxWidth, canvasSize);
    if (layoutResult == null) return;

    final geometryResult = _generateTextGeometry(layoutResult, fontFamily, color, haloColor);
    if (geometryResult == null) return;

    final position = _determineTextPosition(
      line,
      point,
      geometryResult.boundingBox,
      labelSpaces,
      canvasSize,
      rotationAlignment,
    );
    if (position == null) return;

    final validation = _validateLabelSpace(
      position,
      geometryResult.boundingBox,
      labelSpaces,
      canvasSize,
      isLineString,
    );
    if (validation == null) return;

    final transformedBatches = _transformAndFinalize(
      geometryResult,
      layoutResult,
      position,
      validation,
      rotationAlignment,
      fontSize,
    );

    _batchManager.addBatches(transformedBatches);
  }

  _LayoutResult? _calculateLayout(
    String text,
    int fontSize,
    String fontFamily,
    int? maxWidth,
    int canvasSize,
  ) {
    final lines = _layoutCalculator.wrapTextLines(text, fontSize, maxWidth);
    final scalingData = _layoutCalculator.calculateScaling(fontSize, canvasSize);
    final lineWidths = _layoutCalculator.calculateLineWidths(
      lines,
      fontFamily,
      scalingData.scaling,
    );

    if (lineWidths.isEmpty) return null;

    return _LayoutResult(
      lines: lines,
      lineWidths: lineWidths,
      scalingData: scalingData,
    );
  }

  ({Map<int, GeometryBatch> batches, BoundingBox boundingBox})? _generateTextGeometry(
    _LayoutResult layout,
    String fontFamily,
    Vector4 color,
    Vector4? haloColor,
  ) {
    return _geometryGenerator.generateGeometry(
      lines: layout.lines,
      lineWidths: layout.lineWidths,
      fontFamily: fontFamily,
      scaling: layout.scalingData.scaling,
      lineHeight: layout.scalingData.lineHeight,
      color: color,
      haloColor: haloColor,
    );
  }

  ({double x, double y, double rotation})? _determineTextPosition(
    TileLine? line,
    TilePoint? point,
    BoundingBox boundingBox,
    Map<double, NdcLabelSpace> labelSpaces,
    int canvasSize,
    RotationAlignment rotationAlignment,
  ) {
    if (line != null && line.points.isNotEmpty) {
      final bestPosition = _positionFinder.findBestPosition(
        line,
        boundingBox,
        labelSpaces,
        canvasSize,
        rotationAlignment,
      );
      if (bestPosition == null) return null;

      return (
        x: bestPosition.point.x,
        y: bestPosition.point.y,
        rotation: bestPosition.rotation,
      );
    }

    if (point != null) {
      if (point.x < 0 || point.x > 4096 || point.y < 0 || point.y > 4096) {
        return null;
      }
      return (x: point.x, y: point.y, rotation: 0.0);
    }

    return null;
  }

  ({double minScaleFactor, Offset center})? _validateLabelSpace(
    ({double x, double y, double rotation}) position,
    BoundingBox boundingBox,
    Map<double, NdcLabelSpace> labelSpaces,
    int canvasSize,
    bool isLineString,
  ) {
    final anchor = _layoutCalculator.calculateAnchor(
      position.x,
      position.y,
      canvasSize,
    );
    final baseRotation = -LabelSpaceValidator.normalizeToPi(position.rotation);

    return _spaceValidator.validateAndOccupySpace(
      labelSpaces: labelSpaces,
      boundingBox: boundingBox,
      anchor: anchor,
      baseRotation: baseRotation,
      canExceedTileBounds: !isLineString,
    );
  }

  Map<int, GeometryBatch> _transformAndFinalize(
    ({Map<int, GeometryBatch> batches, BoundingBox boundingBox}) geometry,
    _LayoutResult layout,
    ({double x, double y, double rotation}) position,
    ({double minScaleFactor, Offset center}) validation,
    RotationAlignment rotationAlignment,
    int fontSize,
  ) {
    final isMultiLine = layout.lines.length > 1;
    final centerOffsetX = isMultiLine ? 0.0 : geometry.boundingBox.centerOffsetX;
    final centerOffsetY = isMultiLine ? 0.0 : geometry.boundingBox.centerOffsetY;
    final dynamicRotationScale = rotationAlignment == RotationAlignment.viewport ? 1.0 : 0.0;
    final baseRotation = -LabelSpaceValidator.normalizeToPi(position.rotation);

    return _geometryGenerator.transformGeometry(
      sourceBatches: geometry.batches,
      centerOffsetX: centerOffsetX,
      centerOffsetY: centerOffsetY,
      centerX: validation.center.dx,
      centerY: validation.center.dy,
      baseRotation: baseRotation,
      dynamicRotationScale: dynamicRotationScale,
      minScaleFactor: validation.minScaleFactor,
      fontSize: fontSize.toDouble(),
    );
  }

  List<PackedMesh> getMeshes() {
    return _batchManager.getMeshes();
  }
}

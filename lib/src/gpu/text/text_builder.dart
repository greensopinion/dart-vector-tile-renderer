import 'dart:ui';

import 'package:vector_math/vector_math.dart';
import 'package:vector_tile_renderer/src/gpu/text/sdf/glyph_atlas_data.dart';
import 'package:vector_tile_renderer/src/gpu/tile_render_data.dart';
import 'package:vector_tile_renderer/src/model/geometry_model.dart';

import '../../features/extensions.dart';
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

  bool addText({
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
    required double displayScaleFactor,
    required LayoutAnchor anchorType,
  }) {
    final layoutResult = _calculateLayout(text, fontSize, fontFamily, maxWidth, canvasSize);
    if (layoutResult == null) return false;

    final shouldCurveText = line != null &&
        line.points.length > 2 &&
        layoutResult.lines.length == 1 &&
        isLineString &&
        rotationAlignment == RotationAlignment.map;

    print("shouldCurveText: $shouldCurveText, line: ${line?.points.length} points, layoutLines: ${layoutResult.lines.length}, isLineString: $isLineString, rotationAlignment: $rotationAlignment");

    if (shouldCurveText) {
      final boundingBox = _geometryGenerator.calculateBoundingBox(
          lines: layoutResult.lines,
          lineWidths: layoutResult.lineWidths,
          fontFamily: fontFamily,
          scaling: layoutResult.scalingData.scaling,
          lineHeight: layoutResult.scalingData.lineHeight
      );
      print("boundingBox: $boundingBox");
      if (boundingBox == null) {
        print("boundingBox is null, returning false");
        return false;
      }

      final positionResult = _positionFinder
          .findBestPosition(
        line,
        anchorType,
        boundingBox,
        labelSpaces,
        canvasSize,
        RotationAlignment.map,
      );
      if (positionResult == null) {
        return false;
      }

      final res = _geometryGenerator.generateCurvedGeometry(
        line: line,
        bestIndex: positionResult.index,
        lines: layoutResult.lines,
        lineWidths: layoutResult.lineWidths,
        fontFamily: fontFamily,
        scaling: layoutResult.scalingData.scaling,
        lineHeight: layoutResult.scalingData.lineHeight,
        color: color,
        haloColor: haloColor,
        fontSize: fontSize
      );

      print("res: $res, batches: ${res?.batches.length}");
      if (res == null) {
        print("res is null, returning false");
        return false;
      }

      final validation = _validateLabelSpace(
          (rotation: positionResult.rotation, x: positionResult.point.x, y: positionResult.point.y),
          res.boundingBox,
          labelSpaces,
          canvasSize,
          isLineString,
          anchorType
      );
      if (validation == null) return false;

      _batchManager.addBatches(res.batches);
      print("added line text");

      return true;
    }
    return false; //fixme only draw new style for easier testing

    final geometryResult = _generateTextGeometry(layoutResult, fontFamily, color, haloColor);
    if (geometryResult == null) return false;

    final position = _determineTextPosition(
      line,
      point,
      anchorType,
      geometryResult.boundingBox,
      labelSpaces,
      canvasSize,
      rotationAlignment,
    );
    if (position == null) return false;

    final validation = _validateLabelSpace(
      position,
      geometryResult.boundingBox,
      labelSpaces,
      canvasSize,
      isLineString,
        anchorType
    );
    if (validation == null) return false;

    final transformedBatches = _transformAndFinalize(
      geometryResult,
      layoutResult,
      position,
      validation,
      rotationAlignment,
      fontSize * displayScaleFactor,
      anchorType,
    );

    _batchManager.addBatches(transformedBatches);
    return true;
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
    LayoutAnchor anchorType,
    BoundingBox boundingBox,
    Map<double, NdcLabelSpace> labelSpaces,
    int canvasSize,
    RotationAlignment rotationAlignment,
  ) {
    if (line != null && line.points.isNotEmpty) {
      final bestPosition = _positionFinder.findBestPosition(
        line,
        anchorType,
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
    LayoutAnchor anchorType,
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
      anchorType: anchorType,
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
    double fontSize,
    LayoutAnchor anchor,
  ) {
    final isMultiLine = layout.lines.length > 1;

    double centerOffsetY;
    if (anchor == LayoutAnchor.top) {
      centerOffsetY = -geometry.boundingBox.minY;
    } else {
      centerOffsetY = isMultiLine ? 0.0 : geometry.boundingBox.centerOffsetY;
    }

    final dynamicRotationScale = rotationAlignment == RotationAlignment.viewport ? 1.0 : 0.0;
    final baseRotation = -LabelSpaceValidator.normalizeToPi(position.rotation);

    return _geometryGenerator.transformGeometry(
      sourceBatches: geometry.batches,
      centerOffsetX: geometry.boundingBox.centerOffsetX,
      centerOffsetY: centerOffsetY,
      centerX: validation.center.dx,
      centerY: validation.center.dy,
      baseRotation: baseRotation,
      dynamicRotationScale: dynamicRotationScale,
      minScaleFactor: validation.minScaleFactor,
      fontSize: fontSize,
    );
  }

  List<PackedMesh> getMeshes() {
    return _batchManager.getMeshes();
  }
}

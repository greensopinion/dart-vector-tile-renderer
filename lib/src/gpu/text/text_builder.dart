import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:vector_math/vector_math.dart';
import 'package:vector_tile_renderer/src/gpu/bucket_unpacker.dart';
import 'package:vector_tile_renderer/src/gpu/text/sdf/glyph_atlas_data.dart';
import 'package:vector_tile_renderer/src/gpu/text/text_geometry.dart';
import 'package:vector_tile_renderer/src/gpu/tile_render_data.dart';
import 'package:vector_tile_renderer/src/gpu/utils.dart';
import 'package:vector_tile_renderer/src/model/geometry_model.dart';

import '../../themes/style.dart';
import '../../features/text_wrapper.dart';
import 'ndc_label_space.dart';

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

class _GeometryBatch {
  final int textureID;
  final Vector4 color;
  final Vector4? haloColor;
  final List<double> vertices = [];
  final List<int> indices = [];
  int vertexOffset = 0;

  _GeometryBatch(this.textureID, this.color, this.haloColor);

  bool matches(_GeometryBatch other) => (
      textureID == other.textureID &&
      color == other.color &&
      haloColor == other.haloColor
  );
}

class TextBuilder {
  final AtlasSet atlasSet;
  final List<_GeometryBatch> _batches = [];

  TextBuilder(this.atlasSet);

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
    
    final lines = maxWidth != null && maxWidth > 0 && fontSize > 0 ?
        wrapText(text, fontSize.toDouble(), maxWidth).map((line) => line.trim()).toList(growable: false) :
        [text];

    final tempBatches = <int, _GeometryBatch>{};
    final boundingBox = BoundingBox();

    final fontScale = 15 * fontSize / atlasSet.fontSize;
    final canvasScale = 2 / canvasSize;
    final scaling = fontScale * canvasScale;

    final lineHeight = scaling * atlasSet.fontSize * 1.2; 

    
    final lineWidths = <double>[];

    for (final lineText in lines) {
      double lineWidth = 0.0;
      for (final charCode in lineText.codeUnits) {
        final atlas = atlasSet.getAtlasForChar(charCode, fontFamily);
        if (atlas == null) {
          return;
        }
        final glyphMetrics = atlas.getGlyphMetrics(charCode)!;
        lineWidth += scaling * glyphMetrics.glyphAdvance;
      }
      lineWidths.add(lineWidth);
    }

    
    for (int lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      final lineText = lines[lineIndex];
      final lineWidth = lineWidths[lineIndex];

      
      final lineCenterOffsetX = lines.length > 1 ? -lineWidth / 2 : 0.0;

      double offsetX = lineCenterOffsetX; 
      final baseY = ((lines.length - 1) / 2 - lineIndex) * lineHeight; 

      
      for (final charCode in lineText.codeUnits) {
        final atlas = atlasSet.getAtlasForChar(charCode, fontFamily);
        if (atlas == null) {
          return;
        }
        final textureID = atlas.atlasID.hashCode;

        final tempBatch = tempBatches.putIfAbsent(textureID, () => _GeometryBatch(textureID, color, haloColor));

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
          tempBatch.vertexOffset + 0, tempBatch.vertexOffset + 2, tempBatch.vertexOffset + 1, 
          tempBatch.vertexOffset + 2, tempBatch.vertexOffset + 0, tempBatch.vertexOffset + 3, 
        ]);

        final advance = scaling * glyphMetrics.glyphAdvance;
        offsetX += advance;
        offsetX += glyphMetrics.glyphLeft * scaling;

        
        tempBatch.vertexOffset += 4;
      }
    }

    if (tempBatches.isEmpty) return;

    
    final isMultiLine = lines.length > 1;
    final centerOffsetX = isMultiLine ? 0.0 : boundingBox.centerOffsetX;
    final centerOffsetY = isMultiLine ? 0.0 : boundingBox.centerOffsetY;

    
    final double x;
    final double y;
    final double rotation;

    if (line != null && line.points.isNotEmpty) {
      
      final bestPosition = _findBestLinePosition(
        line,
        boundingBox,
        labelSpaces,
        canvasSize,
        rotationAlignment,
      );

      if (bestPosition == null) {
        return; 
      }

      x = bestPosition.point.x;
      y = bestPosition.point.y;
      rotation = bestPosition.rotation;
    } else if (point != null) {
      
      if (point.x < 0 || point.x > 4096 || point.y < 0 || point.y > 4096) {
        return;
      }
      x = point.x;
      y = point.y;
      rotation = 0.0;
    } else {
      
      return;
    }

    
    final anchorX = (x - canvasSize / 2) * canvasScale;
    final anchorY = (y - canvasSize / 2) * canvasScale;

    final double baseRotation = -normalizeToPi(rotation);

    Offset center = const Offset(0, 0);
    double minScaleFactor = 99.0;

    for (var entry in labelSpaces.entries) {
      final zoomScaleFactor = entry.key;
      final labelSpace = entry.value;

      final halfSizeX = (boundingBox.sizeX / (2 * zoomScaleFactor));
      final halfSizeY = (boundingBox.sizeY / (2 * zoomScaleFactor));

      final aabb = Rect.fromLTRB(anchorX - halfSizeX,
          -anchorY - halfSizeY,
          anchorX + halfSizeX,
          -anchorY + halfSizeY
      );

      center = aabb.center;

      if (!labelSpace.tryOccupy(
        LabelSpaceBox.create(aabb, baseRotation, Point(center.dx, center.dy)),
        canExceedTileBounds: !isLineString
      )
      ) {
        break;
      } else {
        minScaleFactor = zoomScaleFactor;
      }
    }

    if (minScaleFactor > 10.0) {
      return;
    }

    final double dynamicRotationScale;
    if (rotationAlignment == RotationAlignment.viewport) {
      dynamicRotationScale = 1.0;
    } else {
      dynamicRotationScale = 0.0;
    }

    for (final tempBatch in tempBatches.values) {

      final tempVertices = tempBatch.vertices;

      final vertices = <double>[];
      for (int i = 0; i < tempVertices.length; i += 4) {
        vertices.addAll([
          tempVertices[i] + centerOffsetX, 
          tempVertices[i + 1] + centerOffsetY, 
          tempVertices[i + 2], // u
          tempVertices[i + 3], // v
          center.dx,
          center.dy,
          baseRotation,
          dynamicRotationScale,
          minScaleFactor,
          fontSize.toDouble()
        ]);
      }

      _GeometryBatch? batch;
      for (final b in _batches) {
        if (b.matches(tempBatch)) {
          batch = b;
          break;
        }
      }

      if (batch == null) {
        batch = _GeometryBatch(tempBatch.textureID, tempBatch.color, tempBatch.haloColor);
        _batches.add(batch);
      }
      
      final adjustedIndices = tempBatch.indices.map((i) => i + batch!.vertexOffset).toList();

      
      batch.vertices.addAll(vertices);
      batch.indices.addAll(adjustedIndices);
      batch.vertexOffset += vertices.length ~/ TextGeometry.VERTEX_SIZE;
    }
  }

  List<PackedMesh> getMeshes() {
    final meshes = <PackedMesh>[];

    for (final batch in _batches) {
      if (batch.vertices.isEmpty) continue;

      
      final textureIDBytes = intToByteData(batch.textureID).buffer.asUint8List();
      final hColor = batch.haloColor ?? Vector4(0.0, 0.0, 0.0, 0.0);

      final materialUniform = (
          BytesBuilder(copy: true)
            ..add(textureIDBytes)
            ..add(Float32List.fromList([
              batch.color.r, batch.color.g, batch.color.b, batch.color.a,
              hColor.r, hColor.g, hColor.b, hColor.a,
            ]).buffer.asUint8List())
      ).toBytes().buffer.asByteData();

      
      final geometry = PackedGeometry(
        vertices: ByteData.sublistView(Float32List.fromList(batch.vertices)),
        indices: ByteData.sublistView(Uint16List.fromList(batch.indices)),
        type: GeometryType.text
      );

      
      final material = PackedMaterial(
        type: MaterialType.text,
        uniform: materialUniform
      );

      
      meshes.add(PackedMesh(geometry, material));
    }

    
    _batches.clear();

    return meshes;
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

  ({TilePoint point, double rotation})? _findBestLinePosition(
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

    
    final canvasScale = 2 / canvasSize;
    final anchorX = (point.x - canvasSize / 2) * canvasScale;
    final anchorY = (point.y - canvasSize / 2) * canvasScale;

    int passingChecks = 0;

    
    for (var entry in labelSpaces.entries) {
      final zoomScaleFactor = entry.key;
      final labelSpace = entry.value;

      final halfSizeX = (textWidth / (2 * zoomScaleFactor));
      final halfSizeY = (textHeight / (2 * zoomScaleFactor));

      final aabb = Rect.fromLTRB(
        anchorX - halfSizeX,
        -anchorY - halfSizeY,
        anchorX + halfSizeX,
        -anchorY + halfSizeY
      );

      final center = aabb.center;
      final baseRotation = -normalizeToPi(rotation);

      
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
}

import 'package:flutter/rendering.dart';
import 'package:vector_tile/vector_tile.dart';
import 'package:vector_tile/vector_tile_feature.dart';

import 'dart:ui';

import '../logger.dart';
import '../extensions.dart';
import '../constants.dart';
import '../themes/style.dart';
import 'feature_renderer.dart';

class PointRenderer extends FeatureRenderer {
  final Logger logger;
  PointRenderer(this.logger);

  @override
  void render(Canvas canvas, Style style, VectorTileLayer layer,
      VectorTileFeature feature) {
    if (style.textPaint == null || style.textSize == null) {
      logger.warn(() => 'point does not have a text paint or size');
      return;
    }
    final geometry = feature.decodeGeometry();
    if (geometry != null) {
      List<List<double>> points;
      if (geometry.type == GeometryType.Point) {
        final point = geometry as GeometryPoint;
        points = [point.coordinates];
      } else if (geometry.type == GeometryType.MultiPoint) {
        final multiPoint = geometry as GeometryMultiPoint;
        points = multiPoint.coordinates;
      } else {
        logger.warn(
            () => 'point geometryType=${geometry.type} is not implemented');
        return;
      }
      logger.log(() => 'rendering points');
      final properties = feature.decodeProperties();
      final name = properties
          .map((e) => e['name'])
          .whereType<VectorTileValue>()
          .firstOrNull()
          ?.stringValue;
      if (name != null) {
        final textPainter = _createTextPainter(style, name);
        points.forEach((point) {
          points.forEach((point) {
            if (point.length < 2) {
              throw Exception('invalid point ${point.length}');
            }
            final x = (point[0] / layer.extent) * tileSize;
            final y = (point[1] / layer.extent) * tileSize;
            textPainter.paint(canvas, Offset(x, y));
          });
        });
      } else {
        logger.warn(() => 'point with no name?');
      }
    }
  }

  _createTextPainter(Style style, String name) {
    final textStyle = TextStyle(
        foreground: style.textPaint,
        fontSize: style.textSize,
        letterSpacing: style.textLetterSpacing);
    return TextPainter(
        text: TextSpan(style: textStyle, text: name),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr)
      ..layout();
  }
}

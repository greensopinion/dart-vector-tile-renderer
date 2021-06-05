import 'package:flutter/rendering.dart';
import 'package:vector_tile/vector_tile.dart';
import 'package:vector_tile/vector_tile_feature.dart';

import 'dart:ui';

import '../../vector_tile_renderer.dart';
import '../context.dart';
import '../logger.dart';
import '../extensions.dart';
import '../constants.dart';
import '../themes/style.dart';
import 'feature_renderer.dart';

class PointRenderer extends FeatureRenderer {
  final Logger logger;
  PointRenderer(this.logger);

  @override
  void render(Context context, ThemeLayerType layerType, Style style,
      VectorTileLayer layer, VectorTileFeature feature) {
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
        final textPainter =
            _createTextPainter(context, style, name, zoom: context.zoom);
        if (textPainter != null) {
          points.forEach((point) {
            points.forEach((point) {
              if (point.length < 2) {
                throw Exception('invalid point ${point.length}');
              }
              final x = (point[0] / layer.extent) * tileSize;
              final y = (point[1] / layer.extent) * tileSize;
              textPainter.paint(context.canvas, Offset(x, y));
            });
          });
        }
      } else {
        logger.warn(() => 'point with no name?');
      }
    }
  }

  TextPainter? _createTextPainter(Context context, Style style, String name,
      {required double zoom}) {
    final foreground = style.textPaint!.paint(zoom: zoom);
    if (foreground == null) {
      return null;
    }
    double textSize = style.textSize ?? 16;
    if (context.zoomScaleFactor > 1.0) {
      textSize = textSize / context.zoomScaleFactor;
    }
    final textStyle = TextStyle(
        foreground: foreground,
        fontSize: textSize,
        letterSpacing: style.textLetterSpacing);
    return TextPainter(
        text: TextSpan(style: textStyle, text: name),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr)
      ..layout();
  }
}

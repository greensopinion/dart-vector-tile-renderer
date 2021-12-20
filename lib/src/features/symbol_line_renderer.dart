import 'dart:math';
import 'dart:ui';

import 'package:vector_tile/vector_tile.dart';
import 'package:vector_tile/vector_tile_feature.dart';

import '../../vector_tile_renderer.dart';
import '../constants.dart';
import '../context.dart';
import '../logger.dart';
import '../themes/style.dart';
import 'feature_geometry.dart';
import 'feature_renderer.dart';
import 'points_extension.dart';
import 'text_abbreviator.dart';
import 'text_renderer.dart';

class SymbolLineRenderer extends FeatureRenderer {
  final Logger logger;
  final FeatureGeometry geometry;

  SymbolLineRenderer(this.logger) : geometry = FeatureGeometry(logger);

  @override
  void render(Context context, ThemeLayerType layerType, Style style,
      VectorTileLayer layer, VectorTileFeature feature) {
    final textPaint = style.textPaint;
    final textLayout = style.textLayout;
    if (textPaint == null || textLayout == null) {
      logger.warn(() => 'line symbol does not have a text paint or layout');
      return;
    }

    final lines = geometry.decodeLines(feature);
    if (lines != null) {
      logger.log(() => 'rendering linestring symbol');
      final text = textLayout.text(feature);
      if (text != null) {
        final path = Path();
        lines.forEach((line) {
          path.addPolygon(line.toPoints(layer.extent, tileSize), false);
        });
        final metrics = path.computeMetrics().toList();
        if (metrics.length > 0) {
          final abbreviated = TextAbbreviator().abbreviate(text);
          final renderer = TextRenderer(context, style, abbreviated);
          final renderBox = _findMiddleMetric(context, metrics, renderer);
          if (renderBox != null) {
            final tangent = renderBox.tangent;
            final rotate = (tangent.angle >= 0.01 || tangent.angle <= -0.01);
            if (rotate) {
              context.canvas.save();
              context.canvas
                  .translate(tangent.position.dx, tangent.position.dy);
              context.canvas.rotate(-_rightSideUpAngle(tangent.angle));
              context.canvas
                  .translate(-tangent.position.dx, -tangent.position.dy);
            }
            renderer.render(tangent.position);
            if (rotate) {
              context.canvas.restore();
            }
          }
        }
      }
    }
  }

  _RenderBox? _findMiddleMetric(
      Context context, List<PathMetric> metrics, TextRenderer renderer) {
    final midpoint = metrics.length ~/ 2;
    for (int x = 0; x <= (midpoint + 1); ++x) {
      int lower = midpoint - x;
      if (lower >= 0 && metrics[lower].length > _minPathMetricSize) {
        final renderBox = _occupyLabelSpace(context, renderer, metrics[lower]);
        if (renderBox != null) {
          return renderBox;
        }
      }
      int upper = midpoint + x;
      if (upper != lower &&
          upper < metrics.length &&
          metrics[upper].length > _minPathMetricSize) {
        final renderBox = _occupyLabelSpace(context, renderer, metrics[upper]);
        if (renderBox != null) {
          return renderBox;
        }
      }
    }
    return _occupyLabelSpace(context, renderer, metrics[midpoint]);
  }

  _RenderBox? _occupyLabelSpace(
      Context context, TextRenderer renderer, PathMetric metric) {
    Tangent? tangent = metric.getTangentForOffset(metric.length / 2);
    _RenderBox? renderBox;
    if (tangent != null) {
      renderBox = _occupyLabelSpaceAtTangent(context, renderer, tangent);
      if (renderBox == null) {
        tangent = metric.getTangentForOffset(metric.length / 4);
        if (tangent != null) {
          renderBox = _occupyLabelSpaceAtTangent(context, renderer, tangent);
          if (renderBox == null) {
            tangent = metric.getTangentForOffset(metric.length * 3 / 4);
            if (tangent != null) {
              renderBox =
                  _occupyLabelSpaceAtTangent(context, renderer, tangent);
            }
          }
        }
      }
    }
    return renderBox;
  }

  _RenderBox? _occupyLabelSpaceAtTangent(
      Context context, TextRenderer renderer, Tangent tangent) {
    Rect? box = renderer.labelBox(tangent.position, translated: false);
    if (box != null) {
      final angle = _rightSideUpAngle(tangent.angle);
      final hWidth = (box.height * cos(angle + _ninetyDegrees)).abs();
      final width = hWidth + (box.width * cos(angle)).abs();
      final wHeight = (box.width * sin(angle)).abs();
      final height = (box.height * sin(angle + _ninetyDegrees)).abs() + wHeight;
      var xOffset = 0.0;
      var yOffset = 0.0;
      final translation = renderer.translation;
      if (translation != null) {
        xOffset = translation.dx * cos(angle) -
            (translation.dy * cos(angle + _ninetyDegrees)).abs();
        yOffset = (translation.dy * sin(angle + _ninetyDegrees)) -
            (translation.dx * sin(angle)).abs();
      }
      Rect textSpace =
          Rect.fromLTWH(box.left + xOffset, box.top + yOffset, width, height);
      if (context.labelSpace.canOccupy(renderer.text, textSpace)) {
        context.labelSpace.occupy(renderer.text, textSpace);
        return _RenderBox(textSpace, tangent);
      }
    }
    return null;
  }

  double _rightSideUpAngle(double radians) {
    if (radians > _rotationShiftUpper || radians < _rotationShiftLower) {
      return radians + _rotationShift;
    }
    return radians;
  }
}

class _RenderBox {
  final Rect box;
  final Tangent tangent;

  _RenderBox(this.box, this.tangent);
}

final _minPathMetricSize = 100.0;

final _degToRad = pi / 180.0;
final _rotationOfershot = 3;
final _rotationShiftUpper = (90 + _rotationOfershot) * _degToRad;
final _rotationShiftLower = -(90 + _rotationOfershot) * _degToRad;
final _rotationShift = (180 * _degToRad);
final _ninetyDegrees = 90 * _degToRad;

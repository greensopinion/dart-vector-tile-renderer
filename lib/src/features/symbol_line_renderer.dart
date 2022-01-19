import 'dart:math';
import 'dart:ui';

import '../../vector_tile_renderer.dart';
import '../constants.dart';
import '../context.dart';
import '../themes/expression/expression.dart';
import '../themes/style.dart';
import 'feature_renderer.dart';
import 'points_extension.dart';
import 'text_abbreviator.dart';
import 'text_renderer.dart';

class SymbolLineRenderer extends FeatureRenderer {
  final Logger logger;

  SymbolLineRenderer(this.logger);

  @override
  void render(Context context, ThemeLayerType layerType, Style style,
      TileLayer layer, TileFeature feature) {
    final textPaint = style.textPaint;
    final textLayout = style.textLayout;
    if (textPaint == null || textLayout == null) {
      logger.warn(() => 'line symbol does not have a text paint or layout');
      return;
    }

    final lines = feature.lines;
    logger.log(() => 'rendering linestring symbol');
    final evaluationContext = EvaluationContext(
        () => feature.properties, feature.type, context.zoom, logger);
    final text = textLayout.text.evaluate(evaluationContext);
    if (text != null) {
      final path = Path();
      for (final line in lines) {
        path.addPolygon(line.toPoints(layer.extent, tileSize), false);
      }
      if (!_isWithinClip(context, path)) {
        return;
      }
      final metrics = path.computeMetrics().toList();
      final abbreviated = TextAbbreviator().abbreviate(text);
      if (metrics.length > 0 && context.labelSpace.canAccept(abbreviated)) {
        final text =
            TextApproximation(context, evaluationContext, style, abbreviated);
        final renderBox = _findMiddleMetric(context, metrics, text);
        if (renderBox != null) {
          final tangent = renderBox.tangent;
          final rotate = (tangent.angle >= 0.01 || tangent.angle <= -0.01);
          if (rotate) {
            context.canvas.save();
            context.canvas.translate(tangent.position.dx, tangent.position.dy);
            context.canvas.rotate(-_rightSideUpAngle(tangent.angle));
            context.canvas
                .translate(-tangent.position.dx, -tangent.position.dy);
          }
          text.renderer.render(tangent.position);
          if (rotate) {
            context.canvas.restore();
          }
        }
      }
    }
  }

  _RenderBox? _findMiddleMetric(
      Context context, List<PathMetric> metrics, TextApproximation text) {
    final midpoint = metrics.length ~/ 2;
    for (int x = 0; x <= (midpoint + 1); ++x) {
      int lower = midpoint - x;
      if (lower >= 0 && metrics[lower].length > _minPathMetricSize) {
        final renderBox = _occupyLabelSpace(context, text, metrics[lower]);
        if (renderBox != null) {
          return renderBox;
        }
      }
      int upper = midpoint + x;
      if (upper != lower &&
          upper < metrics.length &&
          metrics[upper].length > _minPathMetricSize) {
        final renderBox = _occupyLabelSpace(context, text, metrics[upper]);
        if (renderBox != null) {
          return renderBox;
        }
      }
    }
    return _occupyLabelSpace(context, text, metrics[midpoint]);
  }

  _RenderBox? _occupyLabelSpace(
      Context context, TextApproximation text, PathMetric metric) {
    Tangent? tangent = metric.getTangentForOffset(metric.length / 2);
    _RenderBox? renderBox;
    if (tangent != null) {
      renderBox = _occupyLabelSpaceAtTangent(context, text, tangent);
      if (renderBox == null) {
        tangent = metric.getTangentForOffset(metric.length / 4);
        if (tangent != null) {
          renderBox = _occupyLabelSpaceAtTangent(context, text, tangent);
          if (renderBox == null) {
            tangent = metric.getTangentForOffset(metric.length * 3 / 4);
            if (tangent != null) {
              renderBox = _occupyLabelSpaceAtTangent(context, text, tangent);
            }
          }
        }
      }
    }
    return renderBox;
  }

  _RenderBox? _occupyLabelSpaceAtTangent(
      Context context, TextApproximation text, Tangent tangent) {
    final box = text.labelBox(tangent.position, translated: false);
    if (box != null) {
      final textSpace = _textSpace(box, text.translation, tangent);
      if (context.labelSpace.canOccupy(text.text, textSpace)) {
        return _preciselyOccupyLabelSpaceAtTangent(
            context, text.renderer, tangent);
      }
    }
    return null;
  }

  _RenderBox? _preciselyOccupyLabelSpaceAtTangent(
      Context context, TextRenderer renderer, Tangent tangent) {
    final box = renderer.labelBox(tangent.position, translated: false);
    if (box != null) {
      final textSpace = _textSpace(box, renderer.translation, tangent);
      if (context.labelSpace.canOccupy(renderer.text, textSpace)) {
        context.labelSpace.occupy(renderer.text, textSpace);
        return _RenderBox(textSpace, tangent);
      }
    }
  }

  double _rightSideUpAngle(double radians) {
    if (radians > _rotationShiftUpper || radians < _rotationShiftLower) {
      return radians + _rotationShift;
    }
    return radians;
  }

  Rect _textSpace(Rect box, Offset? translation, Tangent tangent) {
    final angle = _rightSideUpAngle(tangent.angle);
    final hWidth = (box.height * cos(angle + _ninetyDegrees)).abs();
    final width = hWidth + (box.width * cos(angle)).abs();
    final wHeight = (box.width * sin(angle)).abs();
    final height = (box.height * sin(angle + _ninetyDegrees)).abs() + wHeight;
    var xOffset = 0.0;
    var yOffset = 0.0;
    if (translation != null) {
      xOffset = translation.dx * cos(angle) -
          (translation.dy * cos(angle + _ninetyDegrees)).abs();
      yOffset = (translation.dy * sin(angle + _ninetyDegrees)) -
          (translation.dx * sin(angle)).abs();
    }
    return Rect.fromLTWH(box.left + xOffset, box.top + yOffset, width, height);
  }

  bool _isWithinClip(Context context, Path path) =>
      context.tileClip.overlaps(path.getBounds());
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

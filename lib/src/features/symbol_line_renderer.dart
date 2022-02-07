import 'dart:math';
import 'dart:ui';

import '../../vector_tile_renderer.dart';
import '../themes/expression/expression.dart';
import '../themes/style.dart';
import 'feature_renderer.dart';
import 'text_abbreviator.dart';
import 'text_renderer.dart';

class SymbolLineRenderer extends FeatureRenderer {
  final Logger logger;

  SymbolLineRenderer(this.logger);

  @override
  void render(
    FeatureRendererContext context,
    ThemeLayerType layerType,
    Style style,
    TileLayer layer,
    TileFeature feature,
  ) {
    final textPaint = style.textPaint;
    final textLayout = style.textLayout;
    if (textPaint == null || textLayout == null) {
      logger.warn(() => 'line symbol does not have a text paint or layout');
      return;
    }

    // What if the feature has multiple paths?
    final path = feature.paths.first;
    if (!context.isPathWithinTileClip(path)) {
      return;
    }

    final metrics = path.computeMetrics().toList();
    if (metrics.length == 0) {
      return;
    }

    final evaluationContext = EvaluationContext(
      () => feature.properties,
      feature.type,
      context.zoom,
      logger,
    );

    final text = textLayout.text.evaluate(evaluationContext);
    if (text == null) {
      return;
    }

    final textAbbr = TextAbbreviator().abbreviate(text);
    if (!context.labelSpace.canAccept(textAbbr)) {
      return;
    }

    final textApprox =
        TextApproximation(context, evaluationContext, style, textAbbr);

    final renderBox = _findMiddleMetric(context, metrics, textApprox);
    if (renderBox == null) {
      return;
    }

    logger.log(() => 'rendering symbol linestring');

    context.drawInPixelSpace(() {
      final tangentPosition = renderBox.tangent.position;
      final tangentAngle = renderBox.tangent.angle;
      final rotate = (tangentAngle >= 0.01 || tangentAngle <= -0.01);
      if (rotate) {
        context.canvas.save();
        context.canvas.translate(tangentPosition.dx, tangentPosition.dy);
        context.canvas.rotate(-_rightSideUpAngle(tangentAngle));
        context.canvas.translate(-tangentPosition.dx, -tangentPosition.dy);
      }
      textApprox.renderer.render(tangentPosition);
      if (rotate) {
        context.canvas.restore();
      }
    });
  }

  _RenderBox? _findMiddleMetric(
    FeatureRendererContext context,
    List<PathMetric> metrics,
    TextApproximation text,
  ) {
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
    FeatureRendererContext context,
    TextApproximation text,
    PathMetric metric,
  ) {
    Tangent? _getTangentForOffsetInPixels(double distance) {
      final tangent = metric.getTangentForOffset(distance);
      if (tangent != null) {
        return Tangent.fromAngle(
          context.pointFromTileToPixels(tangent.position),
          -tangent.angle,
        );
      }
      return null;
    }

    Tangent? tangent = _getTangentForOffsetInPixels(metric.length / 2);
    _RenderBox? renderBox;
    if (tangent != null) {
      renderBox = _occupyLabelSpaceAtTangent(context, text, tangent);
      if (renderBox == null) {
        tangent = _getTangentForOffsetInPixels(metric.length / 4);
        if (tangent != null) {
          renderBox = _occupyLabelSpaceAtTangent(context, text, tangent);
          if (renderBox == null) {
            tangent = _getTangentForOffsetInPixels(metric.length * 3 / 4);
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
    FeatureRendererContext context,
    TextApproximation text,
    Tangent tangent,
  ) {
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
    FeatureRendererContext context,
    TextRenderer renderer,
    Tangent tangent,
  ) {
    final box = renderer.labelBox(tangent.position, translated: false);
    if (box != null) {
      final textSpace = _textSpace(box, renderer.translation, tangent);
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
}

class _RenderBox {
  final Rect box;
  final Tangent tangent;

  _RenderBox(this.box, this.tangent);
}

final _minPathMetricSize = 100.0;

final _degToRad = pi / 180.0;
final _rotationOvershot = 3;
final _rotationShiftUpper = (90 + _rotationOvershot) * _degToRad;
final _rotationShiftLower = -(90 + _rotationOvershot) * _degToRad;
final _rotationShift = (180 * _degToRad);
final _ninetyDegrees = 90 * _degToRad;

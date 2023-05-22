import 'dart:math';
import 'dart:ui';

import '../../vector_tile_renderer.dart';
import '../context.dart';
import '../themes/expression/expression.dart';
import '../themes/style.dart';
import 'extensions.dart';
import 'feature_renderer.dart';
import 'symbol_layout_extension.dart';
import 'text_abbreviator.dart';
import 'text_renderer.dart';

class SymbolLineRenderer extends FeatureRenderer {
  final Logger logger;

  SymbolLineRenderer(this.logger);

  @override
  void render(
    Context context,
    ThemeLayerType layerType,
    Style style,
    TileLayer layer,
    TileFeature feature,
  ) {
    final symbolLayout = style.symbolLayout;
    if (symbolLayout == null) {
      logger.warn(() => 'line symbol does not have a layout');
      return;
    }

    final lines = feature.paths;
    if (lines.isEmpty) {
      return;
    }

    final BoundedPath path = feature.compoundPath;
    if (!context.optimizations.skipInBoundsChecks &&
        !context.tileSpaceMapper.isPathWithinTileClip(path)) {
      return;
    }

    final evaluationContext = EvaluationContext(
        () => feature.properties, feature.type, logger,
        zoom: context.zoom,
        zoomScaleFactor: context.zoomScaleFactor,
        hasImage: context.hasImage);

    final text = symbolLayout.text?.text.evaluate(evaluationContext);
    final icon = symbolLayout.getIcon(context, evaluationContext);
    if (text == null) {
      logger.warn(() => 'line with no text');
      return;
    }
    bool rotate = _shouldRotate(symbolLayout, evaluationContext);
    final textAbbreviation = TextAbbreviator().abbreviate(text);
    if (!context.labelSpace.canAccept(textAbbreviation)) {
      return;
    }

    final textAnchor = symbolLayout.text?.anchor.evaluate(evaluationContext) ??
        LayoutAnchor.center;
    final textApproximation = TextApproximation(
        context, evaluationContext, style, [textAbbreviation]);

    final metrics = path.pathMetrics;
    final renderBox =
        _findMiddleMetric(context, metrics, textApproximation, rotate);
    if (renderBox == null || !textApproximation.renderer.canPaint) {
      return;
    }

    context.tileSpaceMapper.drawInPixelSpace(() {
      final tangentPosition = renderBox.tangent.position;
      final tangentAngle = renderBox.tangent.angle;
      final rotate = (tangentAngle >= 0.01 || tangentAngle <= -0.01);
      final saveState = rotate;
      if (saveState) {
        context.canvas.save();
        context.canvas.translate(tangentPosition.dx, tangentPosition.dy);
        context.canvas.rotate(-_rightSideUpAngle(tangentAngle));
        context.canvas.translate(-tangentPosition.dx, -tangentPosition.dy);
      }
      final occupied = icon?.render(tangentPosition,
          contentSize: textApproximation.renderer.size);
      var textPosition = tangentPosition;
      if (occupied != null &&
          occupied.overlapsText &&
          textAnchor == LayoutAnchor.center) {
        textPosition = textPosition.translate(
            0,
            (occupied.contentArea.top - occupied.area.top).abs() -
                (occupied.contentArea.bottom - occupied.area.bottom).abs());
      }
      textApproximation.renderer.render(textPosition);
      if (saveState) {
        context.canvas.restore();
      }
    });
  }

  bool _shouldRotate(
      SymbolLayout symbolLayout, EvaluationContext evaluationContext) {
    var textRotationAlignment =
        symbolLayout.text?.rotationAlignment?.evaluate(evaluationContext) ??
            RotationAlignment.auto;
    var rotate = true;
    if (textRotationAlignment == RotationAlignment.auto) {
      final placement = symbolLayout.placement.evaluate(evaluationContext) ??
          LayoutPlacement.point;
      if (placement == LayoutPlacement.point) {
        textRotationAlignment = RotationAlignment.viewport;
      } else {
        textRotationAlignment = RotationAlignment.map;
      }
    }
    if (textRotationAlignment == RotationAlignment.viewport) {
      rotate = false;
    }
    return rotate;
  }

  _RenderBox? _findMiddleMetric(Context context, List<PathMetric> metrics,
      TextApproximation text, bool rotate) {
    if (metrics.isEmpty) {
      return null;
    }
    final midpoint = metrics.length ~/ 2;
    for (int x = 0; x <= (midpoint + 1); ++x) {
      int lower = midpoint - x;
      if (lower >= 0 && metrics[lower].length > _minPathMetricSize) {
        final renderBox =
            _occupyLabelSpace(context, text, metrics[lower], rotate);
        if (renderBox != null) {
          return renderBox;
        }
      }
      int upper = midpoint + x;
      if (upper != lower &&
          upper < metrics.length &&
          metrics[upper].length > _minPathMetricSize) {
        final renderBox =
            _occupyLabelSpace(context, text, metrics[upper], rotate);
        if (renderBox != null) {
          return renderBox;
        }
      }
    }
    return _occupyLabelSpace(context, text, metrics[midpoint], rotate);
  }

  _RenderBox? _occupyLabelSpace(
    Context context,
    TextApproximation text,
    PathMetric metric,
    bool rotate,
  ) {
    Tangent? getTangentForOffsetInPixels(double distance) {
      final tangent = metric.getTangentForOffset(distance);
      if (tangent != null) {
        final angle = rotate ? -tangent.angle : 0.0;
        return Tangent.fromAngle(
          context.tileSpaceMapper.pointFromTileToPixels(tangent.position),
          angle,
        );
      }
      return null;
    }

    Tangent? tangent = getTangentForOffsetInPixels(metric.length / 2);
    _RenderBox? renderBox;
    if (tangent != null) {
      renderBox = _occupyLabelSpaceAtTangent(context, text, tangent);
      if (renderBox == null) {
        tangent = getTangentForOffsetInPixels(metric.length / 4);
        if (tangent != null) {
          renderBox = _occupyLabelSpaceAtTangent(context, text, tangent);
          if (renderBox == null) {
            tangent = getTangentForOffsetInPixels(metric.length * 3 / 4);
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
      if (context.labelSpace.canOccupy(text.text, textSpace) &&
          text.styledSymbol != null) {
        var preciseBox = _preciselyOccupyLabelSpaceAtTangent(
            context, text.renderer, tangent);
        preciseBox ??= _RenderBox(box, tangent);
        return preciseBox;
      }
    }
    return null;
  }

  _RenderBox? _preciselyOccupyLabelSpaceAtTangent(
      Context context, TextRenderer renderer, Tangent tangent) {
    final box = renderer.labelBox(tangent.position, translated: false);
    if (box != null) {
      final textSpace = _textSpace(box, renderer.translation, tangent);
      if (context.labelSpace.canOccupy(renderer.symbol.text, textSpace)) {
        context.labelSpace.occupy(renderer.symbol.text, textSpace);
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

const _minPathMetricSize = 100.0;

const _degToRad = pi / 180.0;
const _rotationOvershot = 3;
const _rotationShiftUpper = (90 + _rotationOvershot) * _degToRad;
const _rotationShiftLower = -(90 + _rotationOvershot) * _degToRad;
const _rotationShift = (180 * _degToRad);
const _ninetyDegrees = 90 * _degToRad;

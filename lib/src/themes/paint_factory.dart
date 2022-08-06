import 'dart:ui';

import 'package:collection/collection.dart';

import '../logger.dart';
import 'expression/caching_expression.dart';
import 'expression/color_expression.dart';
import 'expression/expression.dart';
import 'expression/line_expression.dart';
import 'expression/literal_expression.dart';
import 'expression/numeric_expression.dart';
import 'paint_model.dart';
import 'style.dart';

class PaintExpression extends Expression<PaintModel> {
  final PaintStyle _delegate;

  PaintExpression(this._delegate)
      : super(_cacheKey(_delegate), _properties(_delegate));

  @override
  PaintModel? evaluate(EvaluationContext context) => _delegate.paint(context);

  @override
  bool get isConstant => false;

  static String _cacheKey(PaintStyle delegate) =>
      "paint(${delegate.id},${delegate.paintingStyle},opacity(${delegate.opacity.cacheKey}),strokeWidth(${delegate.strokeWidth.cacheKey}),color(${delegate.color.cacheKey}))";

  static Set<String> _properties(PaintStyle delegate) => {
        ...delegate.color.properties(),
        ...delegate.strokeWidth.properties(),
        ...delegate.opacity.properties()
      };
}

class PaintStyle {
  final String id;
  final PaintingStyle paintingStyle;
  final Expression<Color> color;
  final Expression<double> opacity;
  final Expression<double> strokeWidth;
  final Expression<LineCap>? lineCap;
  final Expression<LineJoin>? lineJoin;
  final List<double>? strokeDashPattern;

  PaintStyle(
      {required this.id,
      required this.paintingStyle,
      required this.color,
      required this.opacity,
      required this.strokeWidth,
      required this.lineCap,
      required this.lineJoin,
      required this.strokeDashPattern});

  PaintModel? paint(EvaluationContext context) {
    final opacity = this.opacity.evaluate(context);
    if (opacity != null && opacity <= 0) {
      return null;
    }
    var color = this.color.evaluate(context);
    if (color == null) {
      return null;
    }
    if (opacity != null && opacity < 1.0) {
      color = color.withOpacity(opacity);
    }
    double? strokeWidth;
    if (paintingStyle == PaintingStyle.stroke) {
      strokeWidth = this.strokeWidth.evaluate(context);
      if (strokeWidth == null || strokeWidth <= 0) {
        return null;
      }
    }
    final lineJoin = this.lineJoin?.evaluate(context);
    final lineCap = this.lineCap?.evaluate(context);
    return PaintModel(
        paintingStyle: paintingStyle,
        color: color,
        strokeWidth: strokeWidth,
        lineCap: lineCap,
        lineJoin: lineJoin,
        strokeDashPattern: strokeDashPattern);
  }
}

class PaintFactory {
  final Logger logger;
  final ExpressionParser expressionParser;
  PaintFactory(this.logger) : expressionParser = ExpressionParser(logger);

  Expression<PaintModel>? create(
      String id, PaintingStyle style, String prefix, paint, layout,
      {double? defaultStrokeWidth = 1.0}) {
    if (paint == null) {
      return null;
    }
    final color = expressionParser.parseOptional(paint['$prefix-color']);
    if (color == null) {
      return null;
    }
    final opacity = expressionParser.parse(paint['$prefix-opacity'],
        whenNull: () => LiteralExpression(1.0));
    final strokeWidth = expressionParser.parse(paint['$prefix-width'],
        whenNull: () => LiteralExpression(defaultStrokeWidth));
    final lineCap = layout == null
        ? null
        : expressionParser.parse(layout['$prefix-cap']).asLineCapExpression();
    final lineJoin = layout == null
        ? null
        : expressionParser.parse(layout['$prefix-join']).asLineJoinExpression();
    List<double>? dashArray;
    final dashJson = paint['$prefix-dasharray'];
    if (dashJson != null && dashJson is List<num> && dashJson.length >= 2) {
      if (dashJson.any((element) => element < .0)) {
        logger.warn(() => '$prefix-dasharray contains value < 0');
      } else {
        dashArray = dashJson.map((e) => e.toDouble()).toList(growable: false);
      }
    }

    return cache(PaintExpression(PaintStyle(
        id: id,
        paintingStyle: style,
        opacity: opacity.asDoubleExpression(),
        strokeWidth: strokeWidth.asDoubleExpression(),
        color: color.asColorExpression(),
        lineCap: lineCap,
        lineJoin: lineJoin,
        strokeDashPattern: dashArray)));
  }
}

class CachingPaintProvider {
  final Map<_PaintCacheKey, PaintModel?> _paintByKey = {};

  PaintModel? provide(EvaluationContext context,
      {required Expression<PaintModel> paint,
      required double Function(double) strokeWidthModifier,
      required double Function(double) widthModifier}) {
    final p = paint.evaluate(context);
    if (p == null) {
      return null;
    }
    var strokeWidth = p.strokeWidth;
    if (strokeWidth != null) {
      strokeWidth = widthModifier.call(strokeWidthModifier.call(strokeWidth));
    }

    final key = _PaintCacheKey(p, strokeWidth);
    return _paintByKey.putIfAbsent(
        key,
        () => PaintModel(
            paintingStyle: p.paintingStyle,
            color: p.color,
            strokeWidth: strokeWidth,
            lineCap: p.lineCap,
            lineJoin: p.lineJoin,
            strokeDashPattern: p.strokeDashPattern
                ?.map(widthModifier)
                .toList(growable: false)));
  }
}

class _PaintCacheKey {
  static const _equality = ListEquality();

  final PaintModel paint;
  final double? strokeWidth;
  late final int _hashCode;

  _PaintCacheKey(this.paint, this.strokeWidth) {
    _hashCode = _equality.hash([paint, strokeWidth]);
  }

  @override
  bool operator ==(other) =>
      other is _PaintCacheKey &&
      other._hashCode == _hashCode &&
      other.paint == paint &&
      other.strokeWidth == strokeWidth;

  @override
  int get hashCode => _hashCode;
}

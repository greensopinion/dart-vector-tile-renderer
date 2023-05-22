// ignore_for_file: constant_identifier_names

import 'dart:math';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:vector_tile_renderer/src/themes/paint_model.dart';

import '../extensions.dart';
import 'expression/expression.dart';

typedef ColorZoomFunction = Color? Function(double zoom);
typedef TextTransformFunction = String? Function(String? text);

class Style {
  final Expression<PaintModel>? fillPaint;
  final Extrusion? fillExtrusion;
  final Expression<PaintModel>? linePaint;
  final Expression<PaintModel>? textPaint;
  final SymbolLayout? symbolLayout;
  final Expression<List<Shadow>>? textHalo;
  final Expression<PaintModel>? outlinePaint;

  Style(
      {this.fillPaint,
      this.fillExtrusion,
      this.outlinePaint,
      this.linePaint,
      this.textPaint,
      this.symbolLayout,
      this.textHalo});
}

class LayoutPlacement {
  final String name;
  const LayoutPlacement._(this.name);
  static const point = LayoutPlacement._('point');
  static const line = LayoutPlacement._('line');
  static const lineCenter = LayoutPlacement._('line-center');
  static const DEFAULT = point;

  static List<LayoutPlacement> values() => [point, line, lineCenter];
  static LayoutPlacement fromName(String? name) =>
      values().where((v) => v.name == name).firstOrNull() ?? DEFAULT;
}

class LayoutAnchor {
  final String name;
  const LayoutAnchor._(this.name);
  static const center = LayoutAnchor._('center');
  static const top = LayoutAnchor._('top');
  static const DEFAULT = center;

  static List<LayoutAnchor> values() => [center, top];
  static LayoutAnchor fromName(String? name) =>
      values().where((v) => v.name == name).firstOrNull() ?? DEFAULT;
}

class LayoutJustify {
  final String name;
  const LayoutJustify._(this.name);
  static const center = LayoutJustify._('center');
  static const left = LayoutJustify._('left');
  static const right = LayoutJustify._('right');
  static const auto = LayoutJustify._('auto');
  static const DEFAULT = center;

  static List<LayoutJustify> values() => [center, left, right, auto];
  static LayoutJustify fromName(String? name) =>
      values().where((v) => v.name == name).firstOrNull() ?? DEFAULT;
}

class RotationAlignment {
  final String name;
  const RotationAlignment._(this.name);
  static const map = RotationAlignment._('map');
  static const viewport = RotationAlignment._('viewport');
  static const auto = RotationAlignment._('auto');
  static const DEFAULT = auto;

  static List<RotationAlignment> values() => [map, viewport, auto];
  static RotationAlignment fromName(String? name) =>
      values().where((v) => v.name == name).firstOrNull() ?? DEFAULT;
}

class SymbolLayout {
  final Expression<LayoutPlacement> placement;
  final TextLayout? text;
  final IconLayout? icon;

  SymbolLayout({
    required this.placement,
    this.text,
    this.icon,
  });
}

class IconLayout {
  final Expression<String?> icon;
  final Expression<LayoutAnchor> anchor;
  final Expression<double>? opacity;
  final Expression<double>? size;
  final Expression<RotationAlignment>? rotationAlignment;
  final Expression<double>? rotate;

  IconLayout(
      {required this.icon,
      required this.anchor,
      required this.opacity,
      required this.size,
      required this.rotationAlignment,
      required this.rotate});
}

class TextLayout {
  final Expression<LayoutAnchor> anchor;
  final Expression<LayoutJustify> justify;
  final Expression<String?> text;
  final Expression<double> textSize;
  final Expression<double>? textLetterSpacing;
  final Expression<double>? maxWidth;
  final FontStyle? fontStyle;
  final String? fontFamily;
  final TextTransformFunction? textTransform;
  final Expression<RotationAlignment>? rotationAlignment;

  TextLayout(
      {required this.anchor,
      required this.justify,
      required this.text,
      required this.textSize,
      required this.textLetterSpacing,
      required this.maxWidth,
      required this.fontFamily,
      required this.fontStyle,
      required this.textTransform,
      required this.rotationAlignment});
}

class LineCap {
  final String name;
  const LineCap._(this.name);
  static const butt = LineCap._('butt');
  static const round = LineCap._('round');
  static const square = LineCap._('square');
  static const DEFAULT = butt;

  static List<LineCap> values() => [butt, round, square];
  static LineCap fromName(String? name) =>
      values().where((v) => v.name == name).firstOrNull() ?? DEFAULT;
}

class LineJoin {
  final String name;
  const LineJoin._(this.name);
  static const bevel = LineJoin._('bevel');
  static const round = LineJoin._('round');
  static const miter = LineJoin._('miter');
  static const DEFAULT = miter;

  static List<LineJoin> values() => [bevel, round, miter];
  static LineJoin fromName(String? name) =>
      values().where((v) => v.name == name).firstOrNull() ?? DEFAULT;
}

class Extrusion {
  final Expression<double>? base;
  final Expression<double>? height;

  Extrusion({this.base, this.height});

  double calculateHeight(EvaluationContext context) {
    final base = this.base?.evaluate(context) ?? 0;
    final height = this.height?.evaluate(context) ?? 0;
    return max(height, base);
  }
}

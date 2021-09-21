import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:vector_tile_renderer/src/expressions/expression.dart';

import '../../vector_tile_renderer.dart';
import '../extensions.dart';
import 'paint_factory.dart';

typedef TextTransformFunction = String? Function(String? text);

class Style {
  final PaintStyle? fillPaint;
  final PaintStyle? linePaint;
  final PaintStyle? textPaint;
  final TextLayout? textLayout;
  final Expression<List<Shadow>>? textHalo;
  final PaintStyle? outlinePaint;

  Style(
      {this.fillPaint,
      this.outlinePaint,
      this.linePaint,
      this.textPaint,
      this.textLayout,
      this.textHalo});
}

class LayoutPlacement {
  final String name;
  const LayoutPlacement._(this.name);
  static const point = LayoutPlacement._('point');
  static const line = LayoutPlacement._('line');
  static const line_center = LayoutPlacement._('line-center');
  static const _DEFAULT = point;

  static List<LayoutPlacement> values() => [point, line, line_center];
  static LayoutPlacement fromName(String? name) =>
      values().where((v) => v.name == name).firstOrNull() ?? _DEFAULT;
}

class LayoutAnchor {
  final String name;
  const LayoutAnchor._(this.name);
  static const center = LayoutAnchor._('center');
  static const top = LayoutAnchor._('top');
  static const _DEFAULT = center;

  static List<LayoutAnchor> values() => [center, top];
  static LayoutAnchor fromName(String? name) =>
      values().where((v) => v.name == name).firstOrNull() ?? _DEFAULT;
}

class TextLayout {
  final LayoutPlacement placement;
  final Expression<String>? anchor;
  final Expression<String> text;
  final Expression<double> textSize;
  final Expression<double>? textLetterSpacing;
  final FontStyle? fontStyle;
  final String? fontFamily;
  final TextTransformFunction? textTransform;

  TextLayout(
      {required this.placement,
      required this.anchor,
      required this.text,
      required this.textSize,
      required this.textLetterSpacing,
      required this.fontFamily,
      required this.fontStyle,
      required this.textTransform});
}

typedef FeatureTextFunction = String? Function(VectorTileFeature);

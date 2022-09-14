// an immutable model representing a paint
import 'dart:ui';

import 'package:collection/collection.dart';

import 'line_styler.dart';
import 'style.dart';

class PaintModel {
  static const _equality = ListEquality();
  final PaintingStyle paintingStyle;
  final Color color;
  final double? strokeWidth;
  final List<double>? strokeDashPattern;
  final LineCap? lineCap;
  final LineJoin? lineJoin;
  final int _hashCode;

  Paint? _paint;

  PaintModel(
      {required this.paintingStyle,
      required this.color,
      required this.strokeWidth,
      required this.lineCap,
      required this.lineJoin,
      required this.strokeDashPattern})
      : _hashCode = Object.hash(paintingStyle, color, strokeWidth, lineCap,
            lineJoin, _equality.hash(strokeDashPattern));

  @override
  bool operator ==(other) =>
      other is PaintModel &&
      other._hashCode == _hashCode &&
      other.paintingStyle == paintingStyle &&
      other.color == color &&
      other.strokeWidth == strokeWidth &&
      other.lineCap == lineCap &&
      other.lineJoin == lineJoin &&
      _equality.equals(other.strokeDashPattern, strokeDashPattern);

  @override
  int get hashCode => _hashCode;

  // Do not mutate the paint!
  Paint paint() {
    var paint = _paint;
    if (paint == null) {
      paint = Paint()
        ..style = paintingStyle
        ..color = color;
      final strokeWidth = this.strokeWidth;
      if (paintingStyle == PaintingStyle.stroke) {
        if (strokeWidth != null) {
          paint.strokeWidth = strokeWidth;
        }
        (lineCap ?? LineCap.DEFAULT).apply(paint);
        (lineJoin ?? LineJoin.DEFAULT).apply(paint);
      }
      _paint = paint;
    }
    return paint;
  }
}

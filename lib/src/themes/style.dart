import 'dart:ui';

typedef LineWidthZoomFunction = double Function(double);

class Style {
  final Paint? fillPaint;
  final Paint? linePaint;
  final LineWidthZoomFunction? lineWidthFunction;
  final Paint? textPaint;
  final double? textSize;
  final double? textLetterSpacing;
  final Paint? outlinePaint;

  Style(
      {this.fillPaint,
      this.outlinePaint,
      this.linePaint,
      this.lineWidthFunction,
      this.textPaint,
      this.textSize,
      this.textLetterSpacing});
}

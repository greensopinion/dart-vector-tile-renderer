import 'dart:ui';

class Style {
  final Paint? fillPaint;
  final Paint? linePaint;
  final Paint? textPaint;
  final double? textSize;
  final double? textLetterSpacing;
  final Paint? outlinePaint;

  Style(
      {this.fillPaint,
      this.outlinePaint,
      this.linePaint,
      this.textPaint,
      this.textSize,
      this.textLetterSpacing});
}

import 'package:vector_tile_renderer/src/themes/paint_factory.dart';

class Style {
  final PaintStyle? fillPaint;
  final PaintStyle? linePaint;
  final PaintStyle? textPaint;
  final double? textSize;
  final double? textLetterSpacing;
  final PaintStyle? outlinePaint;

  Style(
      {this.fillPaint,
      this.outlinePaint,
      this.linePaint,
      this.textPaint,
      this.textSize,
      this.textLetterSpacing});
}

import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../themes/style.dart';
import '../context.dart';

class TextRenderer {
  final Context context;
  final Style style;
  late final TextPainter? _painter;
  TextRenderer(this.context, this.style, String text) {
    _painter = _createTextPainter(context, style, text);
  }

  void render(Offset offset) {
    TextPainter? painter = _painter;
    if (painter == null) {
      return;
    }
    Offset? translation = _layout();
    if (translation != null) {
      context.canvas.save();
      context.canvas.translate(translation.dx, translation.dy);
    }
    painter.paint(context.canvas, offset);
    if (translation != null) {
      context.canvas.restore();
    }
  }

  TextPainter? _createTextPainter(Context context, Style style, String text) {
    final foreground = style.textPaint!.paint(zoom: context.zoom);
    if (foreground == null) {
      return null;
    }
    double? textSize = style.textLayout!.textSize(context.zoom);
    if (textSize != null) {
      if (context.zoomScaleFactor > 1.0) {
        textSize = textSize / context.zoomScaleFactor;
      }
      double? spacing;
      DoubleZoomFunction? spacingFunction = style.textLayout!.textLetterSpacing;
      if (spacingFunction != null) {
        spacing = spacingFunction(context.zoom);
      }
      final textStyle = TextStyle(
          foreground: foreground, fontSize: textSize, letterSpacing: spacing);
      return TextPainter(
          text: TextSpan(style: textStyle, text: text),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr)
        ..layout();
    }
  }

  Offset? _layout() {
    final anchor = style.textLayout!.anchor;
    final size = _painter!.size;
    switch (anchor) {
      case LayoutAnchor.center:
        return Offset(-size.width / 2, -size.height / 2);
      case LayoutAnchor.top:
        return Offset(-size.width / 2, 0);
    }
  }
}

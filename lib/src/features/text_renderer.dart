import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../themes/style.dart';
import '../context.dart';

class TextRenderer {
  final Context context;
  final Style style;
  late final TextPainter? _painter;
  late final Offset? _translation;
  TextRenderer(this.context, this.style, String text) {
    _painter = _createTextPainter(context, style, text);
    _translation = _layout();
  }

  Rect? labelBox(Offset offset) {
    if (_painter == null) {
      return null;
    }
    double x = offset.dx;
    double y = offset.dy;
    if (_translation != null) {
      x += _translation!.dx;
      y += _translation!.dy;
    }
    return Rect.fromLTRB(x, y, x + _painter!.width, y + _painter!.height);
  }

  void render(Offset offset) {
    TextPainter? painter = _painter;
    if (painter == null) {
      return;
    }
    if (_translation != null) {
      context.canvas.save();
      context.canvas.translate(_translation!.dx, _translation!.dy);
    }
    painter.paint(context.canvas, offset);
    if (_translation != null) {
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
    if (_painter == null) {
      return null;
    }
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

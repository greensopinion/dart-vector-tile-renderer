import 'package:flutter/widgets.dart';

import '../context.dart';
import '../themes/expression/expression.dart';
import '../themes/style.dart';

class TextApproximation {
  final Context context;
  final EvaluationContext evaluationContext;
  final Style style;
  final String text;
  Offset? _translation;
  Size? _size;
  TextRenderer? _renderer;

  TextApproximation(
      this.context, this.evaluationContext, this.style, this.text) {
    double? textSize = style.textLayout!.textSize.evaluate(evaluationContext);
    if (textSize != null) {
      if (context.zoomScaleFactor > 1.0) {
        textSize = textSize / context.zoomScaleFactor;
      }
      final approximateWidth =
          (textSize / 1.9 * (text.length + 1)).ceilToDouble();
      final approximateHeight = (textSize * 1.28).ceilToDouble();
      final size = Size(approximateWidth, approximateHeight);
      _size = size;
      _translation = _offset(size, style.textLayout!.anchor);
    }
  }

  Size? get size => _size;
  Offset? get translation => _translation;

  bool get hasRenderer => _renderer != null;

  TextRenderer get renderer {
    var result = _renderer;
    if (result == null) {
      result = TextRenderer(context, evaluationContext, style, text);
      _renderer = result;
    }
    return result;
  }

  Rect? labelBox(Offset offset, {required bool translated}) {
    if (size == null) {
      return null;
    }
    return _labelBox(offset, _translation, size!.width, size!.height,
        translated: translated);
  }
}

class TextRenderer {
  final Context context;
  final Style style;
  final String text;

  late final TextPainter? _painter;
  late final Offset? _translation;
  TextRenderer(this.context, EvaluationContext evaluationContext, this.style,
      this.text) {
    _painter = _createTextPainter(context, evaluationContext, style, text);
    _translation = _layout();
  }

  double get textHeight => _painter!.height;
  Offset? get translation => _translation;

  Rect? labelBox(Offset offset, {required bool translated}) {
    if (_painter == null) {
      return null;
    }
    return _labelBox(offset, _translation, _painter!.width, _painter!.height,
        translated: translated);
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

  TextPainter? _createTextPainter(Context context,
      EvaluationContext evaluationContext, Style style, String text) {
    final foreground = style.textPaint!.paint(evaluationContext);
    if (foreground == null) {
      return null;
    }
    double? textSize = style.textLayout!.textSize.evaluate(evaluationContext);
    if (textSize != null) {
      if (context.zoomScaleFactor > 1.0) {
        textSize = textSize / context.zoomScaleFactor;
      }
      double? spacing =
          style.textLayout!.textLetterSpacing?.evaluate(evaluationContext);
      final shadows = style.textHalo?.call(context.zoom);
      final textStyle = TextStyle(
          foreground: foreground,
          fontSize: textSize,
          letterSpacing: spacing,
          shadows: shadows,
          fontFamily: style.textLayout?.fontFamily,
          fontStyle: style.textLayout?.fontStyle);
      final textTransform = style.textLayout?.textTransform;
      final transformedText =
          textTransform == null ? text : textTransform(text);
      return TextPainter(
          text: TextSpan(style: textStyle, text: transformedText),
          textDirection: TextDirection.ltr)
        ..layout();
    }
  }

  Offset? _layout() {
    if (_painter == null) {
      return null;
    }
    return _offset(_painter!.size, style.textLayout!.anchor);
  }
}

Offset? _offset(Size size, LayoutAnchor anchor) {
  switch (anchor) {
    case LayoutAnchor.center:
      return Offset(-size.width / 2, -size.height / 2);
    case LayoutAnchor.top:
      return Offset(-size.width / 2, 0);
  }
}

Rect? _labelBox(Offset offset, Offset? translation, double width, double height,
    {required bool translated}) {
  double x = offset.dx;
  double y = offset.dy;
  if (translation != null && translated) {
    x += (translation.dx);
    y += (translation.dy);
  }
  return Rect.fromLTWH(x, y, width, height);
}

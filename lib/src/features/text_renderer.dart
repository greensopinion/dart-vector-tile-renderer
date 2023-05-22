import 'dart:math';

import 'package:flutter/widgets.dart';

import '../context.dart';
import '../symbols/symbols.dart';
import '../themes/expression/expression.dart';
import '../themes/style.dart';
import 'extensions.dart';

class TextApproximation {
  final Context context;
  final EvaluationContext evaluationContext;
  final Style style;
  final List<String> textLines;
  late final String text;
  Offset? _translation;
  Size? _size;
  TextRenderer? _renderer;

  StyledSymbol? _symbol;
  bool _symbolCreated = false;

  TextApproximation(
      this.context, this.evaluationContext, this.style, this.textLines) {
    text = textLines.join('\n');
    double? textSize =
        style.symbolLayout!.text!.textSize.evaluate(evaluationContext);
    if (textSize != null) {
      if (context.zoomScaleFactor > 1.0) {
        textSize = textSize / context.zoomScaleFactor;
      }
      final maxLineWidth = textLines.map((e) => e.length).reduce(max);
      final approximateWidth =
          (textSize / 1.9 * (maxLineWidth + 1)).ceilToDouble();
      final approximateLineHeight = (textSize * 1.28).ceilToDouble();
      final approximateHeight = (textLines.length > 1)
          ? (approximateLineHeight * (textSize / 2))
          : approximateLineHeight;
      final size = Size(approximateWidth, approximateHeight);
      _size = size;
      final anchor =
          style.symbolLayout!.text!.anchor.evaluate(evaluationContext) ??
              LayoutAnchor.DEFAULT;
      _translation = anchor.offset(size);
    }
  }

  Size? get size => _size;
  Offset? get translation => _translation;

  bool get hasRenderer => _renderer != null;

  StyledSymbol? get styledSymbol {
    if (!_symbolCreated) {
      _symbol = _createStyledSymbol(context, evaluationContext, style, text);
      _symbolCreated = true;
    }
    return _symbol;
  }

  TextRenderer get renderer {
    var result = _renderer;
    if (result == null) {
      result = TextRenderer(context, evaluationContext, style, styledSymbol!);
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

  StyledSymbol? _createStyledSymbol(Context context,
      EvaluationContext evaluationContext, Style style, String text) {
    final foreground = style.textPaint!.evaluate(evaluationContext);
    if (foreground == null) {
      return null;
    }
    double? textSize =
        style.symbolLayout!.text!.textSize.evaluate(evaluationContext);
    if (textSize != null) {
      if (context.zoomScaleFactor > 1.0) {
        textSize = textSize / context.zoomScaleFactor;
      }
      double? spacing = style.symbolLayout!.text!.textLetterSpacing
          ?.evaluate(evaluationContext);
      final shadows = style.textHalo?.evaluate(evaluationContext);
      final textStyle = TextStyle(
          foreground: foreground.paint(),
          fontSize: textSize,
          letterSpacing: spacing,
          shadows: shadows,
          fontFamily: style.symbolLayout!.text?.fontFamily,
          fontStyle: style.symbolLayout!.text?.fontStyle);
      final textTransform = style.symbolLayout!.text?.textTransform;
      final transformedText =
          textTransform == null ? text : textTransform(text) ?? text;
      final alignment =
          style.symbolLayout!.text?.justify.evaluate(evaluationContext);
      return StyledSymbol(
          style: SymbolStyle(
              textAlign: alignment?.toTextAlign() ?? TextAlign.center,
              textStyle: textStyle),
          text: transformedText);
    }
    return null;
  }
}

class TextRenderer {
  final Context context;
  final Style style;
  final StyledSymbol symbol;
  late final TextPainter? _painter;
  late final Offset? _translation;

  TextRenderer(this.context, EvaluationContext evaluationContext, this.style,
      this.symbol) {
    _painter = context.textPainterProvider.provide(symbol);
    _translation = _layout(evaluationContext);
  }

  double get textHeight => _painter!.height;
  Size get size => Size(_painter!.width, _painter!.height);
  Offset? get translation => _translation;
  bool get canPaint => _painter != null;

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

  Offset? _layout(EvaluationContext context) {
    if (_painter == null) {
      return null;
    }
    final anchor = style.symbolLayout!.text!.anchor.evaluate(context) ??
        LayoutAnchor.DEFAULT;
    return anchor.offset(_painter!.size);
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

extension _LayoutJustifyExtension on LayoutJustify {
  TextAlign toTextAlign() {
    if (this == LayoutJustify.center) {
      return TextAlign.center;
    }
    if (this == LayoutJustify.left) {
      return TextAlign.left;
    }
    if (this == LayoutJustify.right) {
      return TextAlign.left;
    }
    return TextAlign.center;
  }
}

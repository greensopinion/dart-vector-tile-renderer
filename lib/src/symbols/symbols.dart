import 'package:flutter/painting.dart';

class SymbolStyle {
  final TextStyle textStyle;
  final TextAlign textAlign;

  SymbolStyle({required this.textStyle, required this.textAlign});

  @override
  bool operator ==(Object other) => (other is SymbolStyle &&
      textStyle.fontSize == other.textStyle.fontSize &&
      _paintEquals(textStyle.foreground, other.textStyle.foreground) &&
      _paintEquals(textStyle.background, other.textStyle.background) &&
      textStyle.letterSpacing == other.textStyle.letterSpacing &&
      textStyle.fontFamily == other.textStyle.fontFamily &&
      textStyle.fontStyle == other.textStyle.fontStyle &&
      textStyle.fontWeight == other.textStyle.fontWeight &&
      textStyle.height == other.textStyle.height &&
      textStyle.backgroundColor == other.textStyle.backgroundColor &&
      textStyle.color == other.textStyle.color &&
      textStyle.decoration == other.textStyle.decoration &&
      textStyle.decorationColor == other.textStyle.decorationColor &&
      textStyle.decorationStyle == other.textStyle.decorationStyle &&
      textStyle.decorationThickness == other.textStyle.decorationThickness &&
      textAlign == other.textAlign);

  @override
  int get hashCode =>
      Object.hash(textAlign, textStyle.fontSize, textStyle.foreground);
}

class StyledSymbol {
  final SymbolStyle style;
  final String text;

  StyledSymbol({required this.style, required this.text});

  @override
  bool operator ==(Object other) =>
      (other is StyledSymbol && text == other.text && style == other.style);

  @override
  int get hashCode => Object.hash(text, style.textStyle.fontSize);
}

// only bothers comparing paint properties that we use
bool _paintEquals(Paint? first, Paint? second) =>
    (first == null && second == null) ||
    (first != null &&
        second != null &&
        first.style == second.style &&
        first.color == second.color &&
        first.strokeWidth == second.strokeWidth &&
        first.blendMode == second.blendMode &&
        first.isAntiAlias == second.isAntiAlias &&
        first.strokeCap == second.strokeCap &&
        first.strokeJoin == second.strokeJoin);

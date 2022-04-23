import 'dart:ui';

import 'expression/color_expression.dart';
import 'style.dart';

class TextHaloFactory {
  static TextHaloFunction? toHaloFunction(
      ColorExpression colorExpression, double haloWidth) {
    return (context) {
      final color = colorExpression.evaluate(context);
      if (color == null) {
        return null;
      }
      double offset = haloWidth / context.zoom;
      double radius = haloWidth;
      return [
        Shadow(
          offset: Offset(-offset, -offset),
          blurRadius: radius,
          color: color,
        ),
        Shadow(
          offset: Offset(offset, offset),
          blurRadius: radius,
          color: color,
        ),
        Shadow(
          offset: Offset(offset, -offset),
          blurRadius: radius,
          color: color,
        ),
        Shadow(
          offset: Offset(-offset, offset),
          blurRadius: radius,
          color: color,
        ),
      ];
    };
  }
}

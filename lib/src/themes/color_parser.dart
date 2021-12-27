import 'package:flutter/material.dart';

import 'style.dart';
import 'theme_function.dart';
import 'theme_function_model.dart';

class ColorParser {
  static ColorZoomFunction? parse(colorSpec) {
    if (colorSpec is String) {
      Color? color = toColor(colorSpec);
      if (color != null) {
        return (zoom) => color;
      }
    } else if (colorSpec is Map) {
      final model = ColorFunctionModelFactory().create(colorSpec);
      if (model != null) {
        return (zoom) => ColorThemeFunction().exponential(model, zoom);
      }
    }
  }

  static Color? toColor(String? color) {
    if (color == null) {
      return null;
    }
    if (color.startsWith("#") && color.length == 7) {
      return Color.fromARGB(
          0xff,
          int.parse(color.substring(1, 3), radix: 16),
          int.parse(color.substring(3, 5), radix: 16),
          int.parse(color.substring(5, 7), radix: 16));
    }
    if (color.startsWith("#") && color.length == 4) {
      String r = color.substring(1, 2) + color.substring(1, 2);
      String g = color.substring(2, 3) + color.substring(2, 3);
      String b = color.substring(3, 4) + color.substring(3, 4);
      return Color.fromARGB(0xff, int.parse(r, radix: 16),
          int.parse(g, radix: 16), int.parse(b, radix: 16));
    }

    if ((color.startsWith('hsla(') || color.startsWith('hsl(')) &&
        color.endsWith(')')) {
      final components = color
          .replaceAll(RegExp(r"hsla?\("), '')
          .replaceAll(RegExp(r"\)"), '')
          .split(',')
          .map((s) => s.trim().replaceAll(RegExp(r'%'), ''))
          .toList();
      if (components.length == 4 || components.length == 3) {
        //hsla(30, 19%, 90%, 0.4)
        //hsl(248, 7%, 66%)
        final hue = double.tryParse(components[0]);
        final saturation = double.tryParse(components[1]);
        final lightness = double.tryParse(components[2]);
        final alpha =
            components.length == 3 ? 1.0 : double.tryParse(components[3]);
        if (hue != null &&
            saturation != null &&
            lightness != null &&
            alpha != null) {
          return HSLColor.fromAHSL(
                  alpha, hue, saturation / 100, lightness / 100)
              .toColor();
        }
      }
    }
    if ((color.startsWith('rgba(') || color.startsWith('rgb(')) &&
        color.endsWith(')')) {
      final components = color
          .replaceAll(RegExp(r"rgba?\("), '')
          .replaceAll(RegExp(r"\)"), '')
          .split(',')
          .map((s) => s.trim())
          .toList();
      if (components.length == 4 || components.length == 3) {
        final r = int.tryParse(components[0]);
        final g = int.tryParse(components[1]);
        final b = int.tryParse(components[2]);
        final alpha =
            components.length == 3 ? 1.0 : double.tryParse(components[3]);
        if (r != null && g != null && b != null && alpha != null) {
          return Color.fromARGB((0xff * alpha).toInt(), r, g, b);
        }
      }
    }
    throw Exception('unexpected color value $color');
  }
}

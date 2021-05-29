import 'dart:ui';

import 'package:flutter/material.dart';

class ColorParser {
  static Color? parse(String? color) {
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
    throw Exception('unexpected color value $color');
  }
}

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
    return null;
  }

  /// Parses a CSS alpha-value https://developer.mozilla.org/en-US/docs/Web/CSS/alpha-value
  /// and, if successful, standardizes to a double value.
  ///
  /// NOTE: The output value *should* be between zero and one to be useful, but
  /// this function does *not* validate this. The [Color] library constructors
  /// check this.
  static double? alphaValueToDouble(String value) {
    final isPercentage = value.contains('%');
    final raw = double.tryParse(value.replaceAll(RegExp(r'%'), ''));
    return isPercentage && raw != null ? raw / 100.0 : raw;
  }

  static Color? toColor(String? color) {
    if (color == null) {
      return null;
    }
    color = color.trim();

    // Handle #RRGGBB (hexadecimal color with 6 digits)
    if (color.startsWith("#") && color.length == 7) {
      return Color.fromARGB(
        0xff, // Default alpha channel to 255 (opaque)
        int.parse(color.substring(1, 3), radix: 16),
        int.parse(color.substring(3, 5), radix: 16),
        int.parse(color.substring(5, 7), radix: 16),
      );
    }

    // Handle #RRGGBBAA (hexadecimal color with 8 digits)
    if (color.startsWith("#") && color.length == 9) {
      return Color.fromARGB(
        int.parse(color.substring(1, 3), radix: 16), // Alpha
        int.parse(color.substring(3, 5), radix: 16), // Red
        int.parse(color.substring(5, 7), radix: 16), // Green
        int.parse(color.substring(7, 9), radix: 16), // Blue
      );
    }

    // Handle #RGB (short format for #RRGGBB)
    if (color.startsWith("#") && color.length == 4) {
      String r = color.substring(1, 2) + color.substring(1, 2);
      String g = color.substring(2, 3) + color.substring(2, 3);
      String b = color.substring(3, 4) + color.substring(3, 4);
      return Color.fromARGB(
        0xff, // Default alpha channel to 255 (opaque)
        int.parse(r, radix: 16),
        int.parse(g, radix: 16),
        int.parse(b, radix: 16),
      );
    }

    if ((color.startsWith('hsla(') || color.startsWith('hsl(')) && color.endsWith(')')) {
      // Parsing and converting HSL(A) to Color
      final components = color
          .replaceAll(RegExp(r"hsla?\("), '')
          .replaceAll(RegExp(r"\)"), '')
          .split(',')
          .map((s) => s.trim())
          .toList();

      if (components.length == 4 || components.length == 3) {
        final hue = double.tryParse(components[0]);
        final saturation = double.tryParse(components[1].replaceAll(RegExp(r'%'), ''));
        final lightness = double.tryParse(components[2].replaceAll(RegExp(r'%'), ''));
        final alpha = components.length == 3 ? 1.0 : alphaValueToDouble(components[3]);

        if (hue != null && saturation != null && lightness != null && alpha != null) {
          return HSLColor.fromAHSL(
              alpha, hue, saturation / 100, lightness / 100).toColor();
        }
      }
    }

    if ((color.startsWith('rgba(') || color.startsWith('rgb(')) && color.endsWith(')')) {
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
        final alpha = components.length == 3 ? 1.0 : alphaValueToDouble(components[3]);

        if (r != null && g != null && b != null && alpha != null) {
          return Color.fromARGB((0xff * alpha).round().toInt(), r, g, b);
        }
      }
    }

    throw Exception('unexpected color value $color');
  }
}

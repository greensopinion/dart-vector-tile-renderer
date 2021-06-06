import 'dart:ui';

import 'package:vector_tile_renderer/src/themes/style.dart';

class TextHaloFactory {
  static TextHaloFunction? toHaloFunction(
      ColorZoomFunction colorFunction, double haloWidth) {
    return (zoom) {
      final color = colorFunction(zoom);
      if (color == null) {
        return null;
      }
      double offset = haloWidth / zoom;
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

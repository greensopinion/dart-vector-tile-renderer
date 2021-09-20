import 'dart:ui';

import 'package:vector_tile_renderer/src/expressions/expression.dart';

class TextHaloExpression extends Expression<List<Shadow>> {
  final Expression<Color> _color;
  final double _haloWidth;

  TextHaloExpression(this._color, this._haloWidth);

  List<Shadow>? evaluate(Map<String, dynamic> args) {
    final color = _color.evaluate(args);
    if (color == null) {
      return null;
    }

    final zoom = args['zoom'];

    double offset = _haloWidth / zoom;
    double radius = _haloWidth;

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
  }
}
